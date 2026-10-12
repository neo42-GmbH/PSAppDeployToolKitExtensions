function Remove-NXTOldEmpirumApplication {
	<#
	.SYNOPSIS
	Uninstalls old empirum application versions based on the specified parameters and PackageConfig object settings.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This is an internal function.')]
	[CmdletBinding()]
	param ()
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		[PSADTNXT.Foundation.NxtDeploymentSession]$adtSession = Get-ADTSession
		[System.Collections.Generic.IReadOnlyDictionary[System.String, System.Object]]$adtEnvironment = Get-ADTEnvironmentTable

		[System.Collections.Generic.List[Microsoft.Win32.RegistryKey]]$empirumMachineVersionKeys = [System.Collections.Generic.List[Microsoft.Win32.RegistryKey]]::new()
		[System.String]$regPackageKey = $adtSession.NXT.Package.RegistryKey.Split('\')[1]
		[System.String]$keyRef = "$($regPackageKey)\$($adtSession.AppVendor)\$($adtSession.AppName)\*"

		# These keys were previously used to register empirum packages. Unregister them and use them to lookup the backreference.
		[Microsoft.Win32.RegistryKey[]]$empirumMachineUninstallKeys = [PSADTNXT.Extensions.NxtRegistryExtensions]::GetAllViews() | & {
			process {
				[Microsoft.Win32.RegistryKey]$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $_)
				[Microsoft.Win32.RegistryKey]$uninstallRoot = $baseKey.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')
				$uninstallRoot.GetSubKeyNames() | & {
					process {
						[Microsoft.Win32.RegistryKey]$uninstallKey = $uninstallRoot.OpenSubKey($_)
						[System.String]$machineKeyName = $uninstallKey.GetValue('MachineKeyName')
						if ($machineKeyName -like $keyRef -and
							$machineKeyName -notlike "*\$($adtSession.AppVersion)" -and
							$uninstallKey.GetValue('UninstallString') -like '*\setup.exe*\setup.inf*'
						) {
							if (([Microsoft.Win32.RegistryKey]$machineKey = $baseKey.OpenSubKey('SOFTWARE\' + $machineKeyName))) {
								$empirumMachineVersionKeys.Add($machineKey)
							}
							return $uninstallKey
						}
					}
				}
				$uninstallRoot.Close()
				$baseKey.Close()
			}
		}

		# Track all applications that are registered in the same subkey subkey as this package
		if (([Microsoft.Win32.RegistryKey]$staticEmpirumMachineAppKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
					[Microsoft.Win32.RegistryHive]::LocalMachine,
					[Microsoft.Win32.RegistryView]::Registry64 # Is always the highest registry available.
				).OpenSubKey("SOFTWARE\$regPackageKey\$($adtSession.AppVendor)\$($adtSession.AppName)"))
		) {
			$staticEmpirumMachineAppKey.GetSubKeyNames() | & {
				process {
					if ($_ -eq $adtSession.AppVersion) { return }
					[Microsoft.Win32.RegistryKey]$staticEmpirumMachineVersionKey = $staticEmpirumMachineAppKey.OpenSubKey($_)
					if ($staticEmpirumMachineVersionKey.Name -notin @($empirumMachineVersionKeys | Select-Object -ExpandProperty Name)) {
						$empirumMachineVersionKeys.Add($staticEmpirumMachineVersionKey)
					}
				}
			}
			$staticEmpirumMachineAppKey.Close()
		}

		if ($empirumMachineVersionKeys) {
			Show-NXTInstallationWelcome -ADTSession $adtSession -DeploymentDefaults -NoBalloonTip
		}

		foreach ($empirumMachineVersionKey in $empirumMachineVersionKeys) {
			if ([Microsoft.Win32.RegistryKey]$empirumMachineSetupKey = $empirumMachineVersionKey.OpenSubKey('Setup')) {
				if ($adtSession.NXT.Package.UninstallOld) {
					Write-ADTLogEntry -Message "Uninstalling old Empirum package [$($empirumMachineVersionKey.Name)]."
					[System.Collections.Generic.List[System.String]]$arguments = [System.Collections.Generic.List[System.String]]::new()
					[System.String[]]$uninstallStringParts = ConvertFrom-NXTCommandLine -InputObject ($empirumMachineSetupKey.GetValue('UninstallString'))
					if ($uninstallStringParts -and $uninstallStringParts.Count -gt 1) {
						[System.String]$uninstallBinary = [PSADTNXT.Shell.NxtCommandLine]::SearchPath($uninstallStringParts[0], [System.EnvironmentVariableTarget]::Machine)
						[System.Boolean]$machineSetup = [System.Byte]$empirumMachineSetupKey.GetValue('MachineSetup', 0)
						[System.String]$logFilePath = [System.IO.Path]::Combine($adtSession.LogPath, "emp_old_uninstall_$($adtEnvironment.DeploymentTimestamp).log")

						$arguments.AddRange([System.String[]]$uninstallStringParts[1..($uninstallStringParts.Length - 1)])
						$arguments.AddRange(([System.String[]]@('/X8', '/S0', '/F', "/E+$logFilePath")))
						if ($machineSetup) { $arguments.Add('/AW') }

						$adtSession.NXT.ProcessResults.Add((Start-ADTProcess -PassThru -FilePath $uninstallBinary -ArgumentList $arguments -ExitOnProcessFailure))
					}
					else {
						Write-ADTLogEntry -Severity Error -Message 'Cannot run uninstallation, as uninstall string is not valid.'
					}
				}

				# Clear the old Empirum app path
				if (([System.String]$appPath = $empirumMachineSetupKey.GetValue('AppPath')) -and [System.IO.Directory]::Exists($appPath)) {
					Write-ADTLogEntry -Message "Clearing old Empirum directory [$appPath]."
					[System.IO.Directory]::Delete($appPath, $true)
					Remove-NXTEmptyFolder -Path "$appPath\.." -RootPath "$appPath\..\.."
				}

				$empirumMachineSetupKey.Close()
			}

			Write-ADTLogEntry -Message "Deleting old Empirum registration [$($empirumMachineVersionKey.Name)]."
			[PSADTNXT.Extensions.NxtRegistryExtensions]::DeleteTree($empirumMachineVersionKey)
			[Microsoft.Win32.RegistryKey]$empriumMachineAppKey = [PSADTNXT.Extensions.NxtRegistryExtensions]::GetParent($empirumMachineVersionKey)
			Remove-NXTEmptyRegistryKey -Key $empriumMachineAppKey.Name
			[Microsoft.Win32.RegistryKey]$empirumMachineVendorKey = [PSADTNXT.Extensions.NxtRegistryExtensions]::GetParent($empriumMachineAppKey)
			Remove-NXTEmptyRegistryKey -Key $empirumMachineVendorKey.Name
		}

		$empirumMachineUninstallKeys | & {
			process {
				Write-ADTLogEntry -Message "Deleting old Empirum uninstall key [$($_.Name)]"
				[PSADTNXT.Extensions.NxtRegistryExtensions]::Delete($_)
			}
		}

		Invoke-ADTAllUsersRegistryAction -UserProfiles (Get-ADTUserProfiles -ExcludeDefaultUser -InformationAction SilentlyContinue) -InformationAction SilentlyContinue -ScriptBlock {
			[System.String]$sidValue = $_.SID.Value
			[PSADTNXT.Extensions.NxtRegistryExtensions]::GetAllViews() | & {
				process {
					[Microsoft.Win32.RegistryKey]$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::Users, $_)
					[Microsoft.Win32.RegistryKey]$uninstallRoot = $baseKey.OpenSubKey("$sidValue\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
					$uninstallRoot.GetSubKeyNames() | & {
						process {
							[Microsoft.Win32.RegistryKey]$uninstallKey = $uninstallRoot.OpenSubKey($_)
							[System.String]$machineKeyName = $uninstallKey.GetValue('MachineKeyName')
							if ($machineKeyName -like $keyRef -and
								$machineKeyName -notlike "*\$($adtSession.AppVersion)" -and
								$uninstallKey.GetValue('UninstallString') -like '*\setup.exe*\setup.inf*'
							) {
								if (([Microsoft.Win32.RegistryKey]$empirumUserVersionKey = $baseKey.OpenSubKey('SOFTWARE\' + $machineKeyName))) {
									[PSADTNXT.Extensions.NxtRegistryExtensions]::DeleteTree($empirumUserVersionKey)
									[Microsoft.Win32.RegistryKey]$empriumUserAppKey = [PSADTNXT.Extensions.NxtRegistryExtensions]::GetParent($empriumUserAppKey)
									Remove-NXTEmptyRegistryKey -Key $empriumUserAppKey.Name
									$empriumUserAppKey.Close()
									[Microsoft.Win32.RegistryKey]$empirumUserVendorKey = [PSADTNXT.Extensions.NxtRegistryExtensions]::GetParent($empriumUserAppKey)
									Remove-NXTEmptyRegistryKey -Key $empirumUserVendorKey.Name
									$empirumUserVendorKey.Close()
								}
								[PSADTNXT.Extensions.NxtRegistryExtensions]::Delete($uninstallKey)
							}
						}
					}
					$uninstallRoot.Close()
					$baseKey.Close()
				}
			}
			if (([Microsoft.Win32.RegistryKey]$staticEmpirumUserAppKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
						[Microsoft.Win32.RegistryHive]::Users,
						[Microsoft.Win32.RegistryView]::Registry64 # Is always the highest registry available.
					).OpenSubKey("$sidValue\SOFTWARE\$regPackageKey\$($adtSession.AppVendor)\$($adtSession.AppName)"))
			) {
				$staticEmpirumUserAppKey.GetSubKeyNames() | & {
					process {
						if ($_ -eq $adtSession.AppVersion) { return }
						[PSADTNXT.Extensions.NxtRegistryExtensions]::DeleteTree($staticEmpirumUserAppKey.OpenSubKey($_))
					}
				}
				$staticEmpirumUserAppKey.Close()
			}
		}

		Update-NXTDetectionStatus -ADTSession $adtSession
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
