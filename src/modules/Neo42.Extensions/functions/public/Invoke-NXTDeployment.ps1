function Invoke-NXTDeployment {
	<#
	.SYNOPSIS
	This is the main function to deploy software packages.
	.DESCRIPTION
	This function is the main function to deploy software packages.
	It handles all the necessary steps to deploy a software package based on the configuration file.
	Custom hook points are available to extend the deployment logic.
	.PARAMETER ADTSession
	The ADT session for which the deployment is performed. This parameter is optional and will be set to the current ADT session if not specified.
	.EXAMPLE
	Invoke-NXTDeployment -ADTSession $adtSession

	Invokes the deployment logic for the specified ADT session.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'SessionState', Justification = 'The parameter is used in a script block.')]
	[CmdletBinding()]
	param (
		[ValidateNotNull()]
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession)
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

		#region Invoke-NXTDeployment Helpers
		[System.Management.Automation.ScriptBlock]$callHook = {
			param (
				[Parameter(Position = 0, Mandatory)]
				[ValidateNotNullOrEmpty()]
				[PSADTNXT.Deployment.DeploymentHookPoint]
				$HookPoint
			)
			if (([System.Collections.Generic.List[System.Management.Automation.CommandInfo]]$callbacks = $script:DeploymentCallBacks[$HookPoint])) {
				[System.String]$currentPhase = $ADTSession.InstallPhase
				foreach ($callback in $callbacks) {
					Write-ADTLogEntry -Message "Invoking callback [$($callback.Name)] for hook point [$HookPoint]."
					$ADTSession.InstallPhase = $HookPoint
					$ExecutionContext.InvokeCommand.InvokeScript($ADTSession.NXT.DeployAppScriptSessionState, { & $args[0] }.Ast.GetScriptBlock(), $callBack)
					$ADTSession.InstallPhase = $currentPhase
				}
			}
			else {
				Write-ADTLogEntry -Message "No callbacks registered for trigger [$HookPoint]."
			}
		}

		[System.Management.Automation.ScriptBlock]$processResult = {
			param (
				[Parameter(Mandatory, ValueFromPipeline)]
				[PSADT.ProcessManagement.ProcessResult]
				[ValidateNotNull()]
				$Result,
				[System.String]
				$FailHook
			)
			process {
				$ADTSession.NXT.ProcessResults.Add($Result)
				if ($ADTSession.GetDeploymentStatus() -eq [PSADT.Module.DeploymentStatus]::Error) {
					if (-not [System.String]::IsNullOrWhiteSpace($FailHook)) { . $callHook $FailHook }
					[System.Collections.Hashtable]$errorParams = @{
						Exception    = [System.ApplicationException]::new($ADTSession.NXT.DeploymentType.ToString() + ' failed.')
						Category     = [System.Management.Automation.ErrorCategory]::InvalidResult
						ErrorId      = "$($ADTSession.NXT.DeploymentType)Failed"
						TargetObject = $Result
					}
					throw (New-ADTErrorRecord @errorParams)
				}
			}
		}
		#endregion Invoke-NXTDeployment Helpers
	}
	process {
		try {
			try {
				[System.String]$errorMessage = [System.String]::Empty
				$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Preparation"
				Write-ADTLogEntry -Message "Starting Neo42.Extension's [$($ADTSession.NXT.DeploymentType)] deployment logic for [$($ADTSession.InstallTitle)]."

				# Set the initial detection status at the beginning of the deployment
				Update-NXTDetectionStatus -ADTSession $ADTSession

				. $callHook 'CustomBegin'

				switch ($ADTSession.NXT.DeploymentType) {
					{ $_.IsUserPart } {
						$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Deployment"
						try {
							. $callHook "Custom$($ADTSession.NXT.DeploymentType)Begin"
							. $callHook "Custom$($ADTSession.NXT.DeploymentType)End"
						}
						# Do not handle deployment cancel exceptions, as they are used to break out of the deployment flow without marking the deployment as failed.
						catch [PSADTNXT.Deployment.NxtDeploymentCancelException] {
							Write-ADTLogEntry -Message 'The deployment was intentionally cancelled.' -DebugMessage
						}
						catch {
							if ($ADTSession.GetDeploymentStatus() -ne [PSADT.Module.DeploymentStatus]::Error) {
								$ADTSession.SetExitCode(60001)
							}
						}
						finally {
							# Update the active setup registry key to indicate the package was successfully installed
							Write-ADTLogEntry -Message 'Updating the active setup registry key to reflect the package installation status.'
							[System.String]$keyName = $ADTSession.NXT.Package.GUID
							if ($ADTSession.NXT.DeploymentType.IsUninstall) { $keyName += '.uninstall' }
							[Microsoft.Win32.RegistryKey]$activeSetupKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
								[Microsoft.Win32.RegistryHive]::CurrentUser,
								[Microsoft.Win32.RegistryView]::Registry64
							).CreateSubKey(
								"SOFTWARE\Microsoft\Active Setup\Installed Components\$keyName",
								$true
							)
							$activeSetupKey.SetValue(
								$(if ($ADTSession.NXT.DeploymentType.IsInstall) { 'UserPartInstallSuccess' } else { 'UserPartUninstallSuccess' }),
								$ADTSession.GetDeploymentStatus() -ne [PSADT.Module.DeploymentStatus]::Error,
								[Microsoft.Win32.RegistryValueKind]::String
							)
							$activeSetupKey.Close()
						}
						break
					}
					{ $_.IsInstall } {
						. $callHook 'CustomInstallAndReinstallAndSoftMigrationBegin'

						# Uninstall old versions if configured
						Write-ADTLogEntry -Message 'Checking for previously registered packages.'
						Remove-NXTOldPackage -ADTSession $ADTSession

						# Resolve dependent packages
						Write-ADTLogEntry -Message 'Resolving package requirements.'
						Resolve-NXTRequirement -ADTSession $ADTSession

						# Check for soft migration
						if ($ADTSession.NXT.SoftMigration.Enabled -and
							$ADTSession.NXT.SetupCfg['Options']['SOFTMIGRATION'] -ne '0' -and
							(
								-not ([PSADTNXT.Package.NxtRegisteredPackage]$package = $ADTSession.NXT.Package.GetRegisteredPackage()) -or
								(Compare-NXTVersion -Version $package.Version -Target $ADTSession.AppVersion) -eq [PSADTNXT.Application.VersionCompareResult]::Update
							)
						) {
							Write-ADTLogEntry -Message 'The current state of the system indicates that Soft Migration might be applicable. Starting Soft Migration checks...'
							. $callHook 'CustomSoftMigrationBegin'
							if ($ADTSession.NXT.SoftMigration.Result = Test-NXTSoftMigration -ADTSession $ADTSession) {
								Write-ADTLogEntry -Severity Success -Message 'Soft Migration is applicable. Proceeding with migration logic.'
								if ($ADTSession.NXT.Install.Reboot -eq [PSADTNXT.Deployment.RebootAction]::Always) {
									Write-ADTLogEntry -Severity Warning -Message 'The package was configured to always reboot, due to Soft Migration being applicable, the setting was lowered to [IfRequired] to prevent unnecessary reboots.'
									$ADTSession.NXT.Install.Reboot = [PSADTNXT.Deployment.RebootAction]::IfRequired
								}
								. $callHook 'CustomInstallAndReinstallAndSoftMigrationEnd'
								Exit-NXTDeployment -ADTSession $ADTSession -Message 'Soft Migration checks passed successfully. Migration will be performed instead of a regular installation.'
							}
						}
						else {
							Write-ADTLogEntry -Message 'Soft Migration is not applicable for this deployment either because it is not enabled, or no eligible version was found.'
						}

						# If we reach this point, we must show the welcome message if we haven't done so already
						Show-NXTInstallationWelcome -ADTSession $ADTSession -DeploymentDefaults

						#region Invoke-NXTDeployment PreInstall/Reinstall
						Write-ADTLogEntry -Message 'Unhiding all managed applications in case the deployment fails.' -DebugMessage
						Invoke-NXTArpKeyOperation -ADTSession $ADTSession -Purge

						. $callHook 'CustomInstallAndReinstallPreInstallAndReinstall'

						# A package is configured if it is considered installed and the version is equal (if applicable)
						Update-NXTDetectionStatus -ADTSession $ADTSession
						if ($ADTSession.NXT.Detection.Enabled -and $ADTSession.NXT.Detection.IsInstalled) {
							[System.Boolean]$installerRan = $false
							if ($ADTSession.NXT.Detection.VersionStatus -eq [PSADTNXT.Application.VersionCompareResult]::Equal) {
								Write-ADTLogEntry -Message "Application is installed in the same version. Running reinstallation logic based on ReinstallMode [$($ADTSession.NXT.Install.ReinstallMode)]."
								switch ($ADTSession.NXT.Install.ReinstallMode) {
									{ $_ -eq [PSADTNXT.Deployment.ReinstallMode]::None } {
										Write-ADTLogEntry -Message 'Reinstallation is disabled. Skipping installation logic.'
										break
									}
									{ $_ -eq [PSADTNXT.Deployment.ReinstallMode]::Repair } {
										$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Repair"
										# Only process repair supporting installation methods
										if ($ADTSession.NXT.Install.Method -in @([PSADTNXT.Deployment.DeploymentMethod]::MSI) ) {
											Write-ADTLogEntry -Message 'Deployment is set to perform a repair operation. Starting repair.'
											. $callHook 'CustomReinstallPreInstall'
											. $processResult -Result (Invoke-NXTSessionRepair -ADTSession $ADTSession)
											$installerRan = $true
											break
										}
										else {
											Write-ADTLogEntry -Severity Error -Message 'Deployment is set to perform a repair, but the installation method does not support it. Falling back to installation.'
										}
									}
									([PSADTNXT.Deployment.ReinstallMode]::Reinstall) {
										$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Uninstallation"
										. $callHook 'CustomReinstallPreUninstall'

										Write-ADTLogEntry -Message 'Deployment is configured to reinstall the application. Uninstalling current application prior to reinstallation.'
										. $processResult -Result (Invoke-NXTSessionUninstallation -ADTSession $ADTSession) -FailHook 'CustomReinstallPostUninstallOnError'

										. $callHook 'CustomReinstallPostUninstall'
									}
									{ $true } {
										$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Installation"
										. $callHook 'CustomReinstallPreInstall'

										Write-ADTLogEntry -Message 'Starting reinstallation.'
										. $processResult -Result (Invoke-NXTSessionInstallation -ADTSession $ADTSession) -FailHook 'CustomReinstallPostInstallOnError'
										$installerRan = $true
										break
									}
								}
							}
							else {
								Write-ADTLogEntry -Message "Application is installed, but version resolved as [$($ADTSession.NXT.Detection.VersionStatus)]. Performing upgrade logic based on UpgradeMode [$($ADTSession.NXT.Install.UpgradeMode)]."
								switch ($ADTSession.NXT.Install.UpgradeMode) {
									([PSADTNXT.Deployment.UpgradeMode]::Reinstall) {
										$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Uninstallation"
										. $callHook 'CustomReinstallPreUninstall'

										Write-ADTLogEntry -Message 'Deployment is configured to perform a reinstallation on upgrade. Uninstalling current application prior to reinstallation.'
										. $processResult -Result (Invoke-NXTSessionUninstallation -ADTSession $ADTSession) -FailHook 'CustomUpgradePostUninstallOnError'

										. $callHook 'CustomReinstallPostUninstall'
									}
									{ $true } {
										$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Installation"
										Write-ADTLogEntry -Message 'Starting the installation.'
										. $callHook 'CustomReinstallPreInstall'

										. $processResult -Result (Invoke-NXTSessionInstallation -ADTSession $ADTSession) -FailHook 'CustomUpgradePostInstallOnError'
										$installerRan = $true
										break
									}
								}
							}
							if ($installerRan) {
								. $callHook 'CustomReinstallPostInstall'
							}
						}
						else {
							$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Installation"
							Write-ADTLogEntry -Message 'Application is not considered installed. Performing fresh installation.'
							. $callHook 'CustomInstallBegin'

							Write-ADTLogEntry -Message 'Starting installation.'
							. $processResult -Result (Invoke-NXTSessionInstallation -ADTSession $ADTSession) -FailHook 'CustomInstallEndOnError'

							. $callHook 'CustomInstallEnd'
						}
						#endregion Invoke-NXTDeployment PreInstall/Reinstall

						#region Invoke-NXTDeployment PostInstall
						$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Completion"
						Write-ADTLogEntry -Message 'Starting post installation logic.'
						Update-NXTDetectionStatus -ADTSession $ADTSession
						. $callHook 'CustomInstallAndReinstallEnd'
						. $callHook 'CustomInstallAndReinstallAndSoftMigrationEnd'

						# Only verify the state if the property if it can actually be determined
						if ($ADTSession.NXT.Detection.Enabled) {
							Write-ADTLogEntry -Message 'Verifying the installation result based on detection logic.'
							if (-not $ADTSession.NXT.Detection.IsInstalled -or $ADTSession.NXT.Detection.VersionStatus -eq [PSADTNXT.Application.VersionCompareResult]::Update) {
								[System.Collections.Hashtable]$errorParams = @{
									Exception = [System.Management.Automation.ItemNotFoundException]::new('The target application was not considered installed or the version was incorrect after installation.')
									Category  = [System.Management.Automation.ErrorCategory]::InvalidResult
									ErrorId   = 'ApplicationNotFound'
								}
								throw (New-ADTErrorRecord @errorParams)
							}
							Write-ADTLogEntry -Severity Success -Message 'Package was found and is considered installed.'
						}
						else {
							Write-ADTLogEntry -Message 'Detection is not enabled, skipping verification of the installation result.'
						}
						break
					}
					{ $_.IsUninstall } {
						Update-NXTDetectionStatus -ADTSession $ADTSession
						if (-not $ADTSession.NXT.Detection.Enabled -or $ADTSession.NXT.Detection.IsInstalled) {
							$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Uninstallation"
							Show-NXTInstallationWelcome -ADTSession $ADTSession -DeploymentDefaults
							. $callHook 'CustomUninstallBegin'

							Write-ADTLogEntry -Message 'Unhiding managed applications, if there are any.' -DebugMessage
							Invoke-NXTArpKeyOperation -ADTSession $ADTSession -Purge

							Write-ADTLogEntry -Message 'Starting uninstallation.'
							. $processResult -Result (Invoke-NXTSessionUninstallation -ADTSession $ADTSession) -FailHook 'CustomUninstallEndOnError'
						}
						else {
							Write-ADTLogEntry -Message 'Application is not installed. Skipping uninstallation.'
						}

						$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Completion"
						Write-ADTLogEntry -Message 'Starting post uninstallation logic.'
						Update-NXTDetectionStatus -ADTSession $ADTSession
						. $callHook 'CustomUninstallEnd'

						if ($ADTSession.NXT.Detection.Enabled) {
							Write-ADTLogEntry -Message 'Verifying the uninstallation result based on detection logic.'
							if ($ADTSession.NXT.Detection.IsInstalled) {
								[System.Collections.Hashtable]$errorParams = @{
									Exception    = [System.Management.Automation.ItemNotFoundException]::new('The target application was still found after uninstallation.')
									Category     = [System.Management.Automation.ErrorCategory]::InvalidResult
									ErrorId      = 'ApplicationFound'
									TargetObject = $ADTSession.NXT.Detection
								}
								throw (New-ADTErrorRecord @errorParams)
							}
							Write-ADTLogEntry -Severity Success -Message 'Application was not found and is considered uninstalled.'
						}
						else {
							Write-ADTLogEntry -Message 'Detection is not enabled, skipping verification of the uninstallation result.'
						}
						break
					}
				}
			}
			catch [PSADTNXT.Deployment.NxtDeploymentCancelException] {
				Write-ADTLogEntry -Message 'The deployment was intentionally cancelled.' -DebugMessage
			}
			catch {
				Write-ADTLogEntry -Severity Error -Message (Resolve-ADTErrorRecord -ErrorRecord $_ -IncludeErrorInnerException)
				if ($ADTSession.GetDeploymentStatus() -ne [PSADT.Module.DeploymentStatus]::Error) { $ADTSession.SetExitCode(69000) }
				$errorMessage = $_.Exception.Message
			}

			if ($ADTSession.NXT.DeploymentType.IsMachinePart) {
				try {
					Complete-NXTDeployment -ADTSession $ADTSession -ErrorMessage $errorMessage
				}
				catch {
					Write-ADTLogEntry -Severity Error -Message (Resolve-ADTErrorRecord -ErrorRecord $_ -IncludeErrorInnerException)
					if ($ADTSession.GetDeploymentStatus() -ne [PSADT.Module.DeploymentStatus]::Error) { $ADTSession.SetExitCode(69000) }
				}
			}

			if ($ADTSession.GetDeploymentStatus() -eq [PSADT.Module.DeploymentStatus]::Error) {
				. $callHook 'CustomEndOnError'
			}
			else {
				. $callHook 'CustomEnd'
			}
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
