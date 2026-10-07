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
			$ADTSession.NXT.LastRunHookPoint = $HookPoint
			if (([System.Collections.Generic.List[System.Management.Automation.CommandInfo]]$callbacks = $script:DeploymentCallBacks[$HookPoint])) {
				[System.String]$currentPhase = $ADTSession.InstallPhase
				$ADTSession.InstallPhase = $HookPoint
				foreach ($callback in $callbacks) {
					[System.String]$source = if ($callBack.Module) {
						$callBack.Module.Name
					}
					elseif ($callBack -is [System.Management.Automation.FunctionInfo] -and -not [System.String]::IsNullOrWhiteSpace($callBack.ScriptBlock.File)) {
						[System.IO.Path]::GetFileNameWithoutExtension($callBack.ScriptBlock.File)
					}
					else {
						[System.String]::Empty
					}
					if ([System.String]::IsNullOrWhiteSpace($source)) {
						Write-ADTLogEntry -Message "Invoking callback [$($callback.Name)]."
					}
					else {
						Write-ADTLogEntry -Message "Invoking [$source] callback [$($callback.Name)]."
					}
					try {
						$ExecutionContext.InvokeCommand.InvokeScript($ADTSession.NXT.DeployAppScriptSessionState, { & $args[0] }.Ast.GetScriptBlock(), $callBack)
					}
					catch {
						# Always announce the exception from the actual script
						throw $_.Exception.InnerException
					}
					if ($HookPoint.ToString() -notlike '*OnError' -and
						$HookPoint -ne [PSADTNXT.Deployment.DeploymentHookPoint]::CustomEnd -and
						$ADTSession.GetDeploymentStatus() -eq [PSADT.Module.DeploymentStatus]::Error
					) {
						[System.String]$errorMessage = "[$($ADTSession.InstallPhase)] changed the deployment exit code to [$($ADTSession.GetExitCode())] which indicated a failure. Aborting further processing."
						Write-ADTLogEntry -Severity Error -Message $errorMessage
						throw [PSADTNXT.Deployment.NxtDeploymentCancelException]::new($errorMessage)
					}
				}
				$ADTSession.InstallPhase = $currentPhase
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
				[PSADTNXT.Deployment.DeploymentHookPoint]
				$FailHook
			)
			process {
				$ADTSession.NXT.ProcessResults.Add($Result)
				if ($ADTSession.GetDeploymentStatus() -eq [PSADT.Module.DeploymentStatus]::Error) {
					if ($FailHook) { . $callHook $FailHook }
					[System.Collections.Hashtable]$errorParams = @{
						Exception    = [System.ApplicationException]::new('Session [' + $ADTSession.NXT.DeploymentType.ToString() + '] failed.')
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
				$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Preparation"
				Write-ADTLogEntry -Message "Starting Neo42.Extension's [$($ADTSession.NXT.DeploymentType)] deployment logic for [$($ADTSession.InstallTitle)]."
				$ADTSession.NXT.DeploymentInvoked = $true

				# Set the initial detection status at the beginning of the deployment
				Update-NXTDetectionStatus -ADTSession $ADTSession

				. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomBegin)

				switch ($ADTSession.NXT.DeploymentType) {
					{ $_.IsUserPart } {
						$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Deployment"
						try {
							. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::"Custom$($ADTSession.NXT.DeploymentType)Begin")
							. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::"Custom$($ADTSession.NXT.DeploymentType)End")
						}
						# Do not handle deployment cancel exceptions, as they are used to break out of the deployment flow without marking the deployment as failed.
						catch [PSADTNXT.Deployment.NxtDeploymentCancelException] {
							Write-ADTLogEntry -Message 'The deployment was intentionally cancelled.' -DebugMessage
						}
						catch {
							if ($ADTSession.GetDeploymentStatus() -ne [PSADT.Module.DeploymentStatus]::Error) {
								$ADTSession.SetExitCode(60001)
							}
							$ADTSession.NXT.ErrorMessage = $_.Exception.Message
							$ADTSession.NXT.ErrorPhase = $ADTSession.InstallPhase
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
						. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomInstallAndReinstallAndSoftMigrationBegin)

						# Resolve requirements before starting the installation
						Write-ADTLogEntry -Message 'Resolving package requirements.'
						Resolve-NXTRequirement -ADTSession $ADTSession

						# Check for soft migration with a dual stage test. First, check if the config and package allow it
						if (Test-NXTSoftMigration -ADTSession $ADTSession -Scope @('Package', 'Configuration', 'Deployment')) {
							Write-ADTLogEntry -Message 'The current state of the package indicates that Soft Migration might be applicable. Starting further Soft Migration checks...'
							. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomSoftMigrationBegin)

							# Now validate if the soft migration is actually applicable based on the current system state and if the custom hook intervened.
							if ($ADTSession.NXT.SoftMigration.Result = Test-NXTSoftMigration -ADTSession $ADTSession -Scope @('Detection', 'Configuration', 'Deployment')) {
								Write-ADTLogEntry -Severity Success -Message 'Soft Migration is applicable. Proceeding with migration logic.'
								if ($ADTSession.NXT.Install.Reboot -eq [PSADTNXT.Deployment.RebootAction]::Always) {
									Write-ADTLogEntry -Severity Warning -Message 'The package was configured to always reboot, due to Soft Migration being applicable, the setting was lowered to [IfRequired] to prevent unnecessary reboots.'
									$ADTSession.NXT.Install.Reboot = [PSADTNXT.Deployment.RebootAction]::IfRequired
								}

								# Unregister the old packages only and disable the uninstall for downstream hooks, as the migration will be performed instead of a regular installation.
								Write-ADTLogEntry -Message 'Removing old package versions as they are no longer required.'
								$ADTSession.NXT.Package.UninstallOld = $false
								Remove-NXTOldPackage -ADTSession $ADTSession

								# Invoke the custom hook point to allow for any additional logic before the migration is performed.
								. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomSoftMigrationEnd)
								. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomInstallAndReinstallAndSoftMigrationEnd)
								Exit-NXTDeployment -ADTSession $ADTSession -Message 'Soft Migration checks passed successfully. Migration will be performed instead of a regular installation.'
							}
						}
						$ADTSession.NXT.SoftMigration.Result = $false

						# If we reach this point, we must show the welcome message (if we haven't done so already) as all further actions are state changing
						Show-NXTInstallationWelcome -ADTSession $ADTSession -DeploymentDefaults

						Write-ADTLogEntry -Message 'Unhiding all managed applications in case the deployment fails.' -DebugMessage
						Invoke-NXTArpKeyOperation -ADTSession $ADTSession -Purge

						# Uninstall old versions if configured
						Write-ADTLogEntry -Message 'Checking for previously registered packages and cleaning them up.'
						Remove-NXTOldPackage -ADTSession $ADTSession

						#region Invoke-NXTDeployment PreInstall/Reinstall
						. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomInstallAndReinstallPreInstallAndReinstall)
						Update-NXTDetectionStatus -ADTSession $ADTSession

						# A package is configured if it is considered installed and the version is equal (if applicable)
						if ($ADTSession.NXT.Detection.Enabled -and $ADTSession.NXT.Detection.IsInstalled) {
							if ($ADTSession.NXT.Detection.VersionStatus -eq [PSADTNXT.Application.VersionCompareResult]::Equal) {
								Write-ADTLogEntry -Message "Application is installed in the same version. Running reinstallation logic based on ReinstallMode [$($ADTSession.NXT.Install.ReinstallMode)]."
								switch ($ADTSession.NXT.Install.ReinstallMode) {
									{ $_ -eq [PSADTNXT.Deployment.ReinstallMode]::None } {
										Write-ADTLogEntry -Message 'Reinstallation is disabled. Skipping reinstallation logic.'
										break
									}
									{ $_ -eq [PSADTNXT.Deployment.ReinstallMode]::Repair } {
										$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Repair"
										# Only process repair supporting installation methods
										if ($ADTSession.NXT.Install.Method -in @([PSADTNXT.Deployment.DeploymentMethod]::MSI) ) {
											Write-ADTLogEntry -Message 'Deployment is set to perform a repair operation. Starting repair.'
											. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomReinstallPreInstall)
											. $processResult -Result (Invoke-NXTSessionRepair -ADTSession $ADTSession)
											break
										}
										else {
											Write-ADTLogEntry -Severity Error -Message 'Deployment is set to perform a repair, but the installation method does not support it. Falling back to installation.'
										}
									}
									([PSADTNXT.Deployment.ReinstallMode]::Reinstall) {
										$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Uninstallation"
										. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomReinstallPreUninstall)

										Write-ADTLogEntry -Message 'Deployment is configured to reinstall the application. Uninstalling current application prior to reinstallation.'
										. $processResult -Result (Invoke-NXTSessionUninstallation -ADTSession $ADTSession) -FailHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomReinstallPostUninstallOnError)

										. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomReinstallPostUninstall)
									}
									{ $true } {
										$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Installation"
										. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomReinstallPreInstall)

										Write-ADTLogEntry -Message 'Starting reinstallation.'
										. $processResult -Result (Invoke-NXTSessionInstallation -ADTSession $ADTSession) -FailHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomReinstallPostInstallOnError)
										break
									}
								}
							}
							else {
								Write-ADTLogEntry -Message "Application is installed, but version resolved as [$($ADTSession.NXT.Detection.VersionStatus)]. Performing upgrade logic based on UpgradeMode [$($ADTSession.NXT.Install.UpgradeMode)]."
								switch ($ADTSession.NXT.Install.UpgradeMode) {
									([PSADTNXT.Deployment.UpgradeMode]::None) {
										Write-ADTLogEntry -Message 'Upgrade is disabled. Skipping upgrade logic.'
										break
									}
									([PSADTNXT.Deployment.UpgradeMode]::Reinstall) {
										$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Uninstallation"
										. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomReinstallPreUninstall)

										Write-ADTLogEntry -Message 'Deployment is configured to perform a reinstallation on upgrade. Uninstalling current application prior to reinstallation.'
										. $processResult -Result (Invoke-NXTSessionUninstallation -ADTSession $ADTSession) -FailHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomReinstallPostUninstallOnError)

										. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomReinstallPostUninstall)
									}
									{ $true } {
										$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Installation"
										Write-ADTLogEntry -Message 'Starting the installation.'
										. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomReinstallPreInstall)

										. $processResult -Result (Invoke-NXTSessionInstallation -ADTSession $ADTSession) -FailHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomReinstallPostInstallOnError)
										break
									}
								}
							}
							. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomReinstallPostInstall)
						}
						else {
							$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Installation"
							Write-ADTLogEntry -Message 'Application is not considered installed. Performing fresh installation.'
							. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomInstallBegin)

							Write-ADTLogEntry -Message 'Starting installation.'
							. $processResult -Result (Invoke-NXTSessionInstallation -ADTSession $ADTSession) -FailHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomInstallEndOnError)

							. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomInstallEnd)
						}
						#endregion Invoke-NXTDeployment PreInstall/Reinstall

						#region Invoke-NXTDeployment PostInstall
						$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Completion"
						Write-ADTLogEntry -Message 'Starting post installation logic.'
						Update-NXTDetectionStatus -ADTSession $ADTSession
						. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomInstallAndReinstallEnd)
						. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomInstallAndReinstallAndSoftMigrationEnd)

						# Only verify the state if the property if it can actually be determined
						if ($ADTSession.NXT.Detection.Enabled) {
							Write-ADTLogEntry -Message 'Verifying the installation result based on detection logic.'
							Update-NXTDetectionStatus -ADTSession $ADTSession
							if (-not $ADTSession.NXT.Detection.IsInstalled -or $ADTSession.NXT.Detection.VersionStatus -ne [PSADTNXT.Application.VersionCompareResult]::Equal) {
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
							. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomUninstallBegin)

							Write-ADTLogEntry -Message 'Unhiding managed applications, if there are any.' -DebugMessage
							Invoke-NXTArpKeyOperation -ADTSession $ADTSession -Purge

							Write-ADTLogEntry -Message 'Starting uninstallation.'
							. $processResult -Result (Invoke-NXTSessionUninstallation -ADTSession $ADTSession) -FailHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomUninstallEndOnError)

							Update-NXTDetectionStatus -ADTSession $ADTSession
						}
						else {
							Write-ADTLogEntry -Message 'Application is not installed. Skipping uninstallation.'
						}

						$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Completion"
						Write-ADTLogEntry -Message 'Starting post uninstallation logic.'
						. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomUninstallEnd)


						if ($ADTSession.NXT.Detection.Enabled) {
							Write-ADTLogEntry -Message 'Verifying the uninstallation result based on detection logic.'
							Update-NXTDetectionStatus -ADTSession $ADTSession
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
				$ADTSession.NXT.ErrorMessage = $_.Exception.Message
				$ADTSession.NXT.ErrorPhase = $ADTSession.InstallPhase
			}
			catch {
				Write-ADTLogEntry -Severity Error -Message (Resolve-ADTErrorRecord -ErrorRecord $_ -IncludeErrorInnerException)
				if ($ADTSession.GetDeploymentStatus() -ne [PSADT.Module.DeploymentStatus]::Error) { $ADTSession.SetExitCode(69000) }
				$ADTSession.NXT.ErrorMessage = $_.Exception.Message
				$ADTSession.NXT.ErrorPhase = $ADTSession.InstallPhase
			}

			if ($ADTSession.NXT.DeploymentType.IsMachinePart -and $ADTSession.GetDeploymentStatus() -ne [PSADT.Module.DeploymentStatus]::Error) {
				try {
					Complete-NXTDeployment -ADTSession $ADTSession
				}
				catch {
					Write-ADTLogEntry -Severity Error -Message (Resolve-ADTErrorRecord -ErrorRecord $_ -IncludeErrorInnerException)
					if ($ADTSession.GetDeploymentStatus() -ne [PSADT.Module.DeploymentStatus]::Error) { $ADTSession.SetExitCode(69000) }
				}
			}

			if ($ADTSession.GetDeploymentStatus() -eq [PSADT.Module.DeploymentStatus]::Error) {
				. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomEndOnError)
			}
			else {
				. $callHook ([PSADTNXT.Deployment.DeploymentHookPoint]::CustomEnd)
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
