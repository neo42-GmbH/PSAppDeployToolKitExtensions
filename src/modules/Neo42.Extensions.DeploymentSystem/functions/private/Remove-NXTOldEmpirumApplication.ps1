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
		[System.String]$keyRef = "*\$($adtSession.AppVendor)\$($adtSession.AppName)\*"


		# These keys were previously used to register empirum packages. Unregister them and use them to lookup the backreference.
		[Microsoft.Win32.RegistryKey[]]$empirumMachineUninstallKeys = [PSADTNXT.Extensions.NxtRegistryExtensions]::GetAllViews() | & {
			process {
				[Microsoft.Win32.RegistryKey]$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $_)
				[Microsoft.Win32.RegistryKey]$uninstallRoot = $baseKey.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')
				$uninstallRoot.GetSubKeyNames() | & {
					process {
						[Microsoft.Win32.RegistryKey]$uninstallKey = $uninstallRoot.OpenSubKey($_)
						if ($uninstallKey.GetValue('MachineKeyName') -like $keyRef -and
							$uninstallKey.GetValue('DisplayVersion') -ne $adtSession.AppVersion -and
							$uninstallKey.GetValue('UninstallString') -like '*\Setup.exe' -and
							([Microsoft.Win32.RegistryKey]$machineKey = $baseKey.OpenSubKey('SOFTWARE\' + $uninstallKey.GetValue('MachineKeyName')))
						) {
							$empirumMachineVersionKeys.Add($machineKey)
							return $uninstallKey
						}
					}
				}
			}
		}

		# Track all applications that are registered in the same subkey subkey as this package
		if (([Microsoft.Win32.RegistryKey]$staticEmpirumMachineAppKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
					[Microsoft.Win32.RegistryHive]::LocalMachine,
					[Microsoft.Win32.RegistryView]::Registry64 # Is always the highest registry available.
				).OpenSubKey("SOFTWARE\$($adtSession.NXT.Package.RegistryKey.Split('\')[1])\$($adtSession.AppVendor)\$($adtSession.AppName)"))
		) {
			$staticEmpirumMachineAppKey.GetSubKeyNames() | & {
				process {
					if ($_ -eq $adtSession.AppVersion) { return }
					[Microsoft.Win32.RegistryKey]$staticEmpirumMachineVersionKey = $staticEmpirumMachineAppKey.OpenSubKey($_)
					if ($staticEmpirumMachineVersionKey.Name -notin @($empirumVersionKeys | Select-Object -ExpandProperty Name)) {
						$empirumMachineVersionKeys.Add($staticEmpirumMachineVersionKey)
					}
				}
			}
		}

		foreach ($empirumMachineVersionKey in $empirumMachineVersionKeys) {
			if ([Microsoft.Win32.RegistryKey]$empirumMachineSetupKey = $empirumMachineVersionKey.OpenSubKey('Setup')) {
				if ($adtSession.NXT.Package.UninstallOld) {
					Write-ADTLogEntry -Message "Uninstalling old Empirum package [$($empirumMachineVersionKey.Name)]."

					if (-not ([System.String]::IsNullOrWhiteSpace(([System.String]$uninstallString = $empirumMachineSetupKey.GetValue('UninstallString'))))) {
						[System.Collections.Generic.List[System.String]]$arguments = [System.Collections.Generic.List[System.String]]::new()
						[System.String[]]$uninstallStringParts = ConvertFrom-NXTCommandLine -InputObject $uninstallString
						if ($uninstallStringParts -and $uninstallStringParts.Count -gt 1) {
							[System.String]$uninstallBinary = [PSADTNXT.Shell.NxtCommandLine]::SearchPath($uninstallStringParts[0], [System.EnvironmentVariableTarget]::Machine)
							[System.Boolean]$machineSetup = [System.Byte]$empirumMachineSetupKey.GetValue('MachineSetup', 0)
							[System.String]$logFilePath = [System.IO.Path]::Combine($adtSession.LogPath, "emp_old_uninstall_$($adtEnvironment.DeploymentTimestamp).log")

							$arguments.AddRange([System.String[]]$uninstallStringParts[1..($uninstallStringParts.Length - 1)])
							$arguments.AddRange(([System.String[]]@('/X8', '/S0', '/F', "/E+$logFilePath")))
							if ($machineSetup) { $arguments.Add('/AW') }

							$adtSession.NXT.ProcessResults.Add((Start-ADTProcess -PassThru -FilePath $uninstallBinary -ArgumentList $arguments -IgnoreExitCodes '*'))
						}
						else {
							Write-ADTLogEntry -Severity Error -Message 'Cannot run uninstallation, as uninstall string is not valid.'
						}
					}
					else {
						Write-ADTLogEntry -Severity Warning -Message "Empirum application version [$_] does not contain uninstall information. Proceeding with unregister."
					}
				}

				# Clear the old Empirum app path
				if (([System.String]$appPath = $empirumSetupKey.GetValue('AppPath')) -and [System.IO.Directory]::Exists($appPath)) {
					Write-ADTLogEntry -Message "Clearing old Empirum directory [$appPath]."
					[System.IO.Directory]::Delete($appPath, $true)
					Remove-NXTEmptyFolder -Path "$appPath\.." -RootPath "$appPath\..\.."
				}

				$empirumSetupKey.Close()
			}
			$empirumMachineVersionKey.Close()

			Write-ADTLogEntry -Message "Deleting old Empirum registration [$($empirumMachineVersionKey.Name)]."
			[PSADTNXT.Extensions.NxtRegistryExtensions]::DeleteTree($empirumMachineVersionKey)
			[Microsoft.Win32.RegistryKey]$empriumAppKey = [PSADTNXT.Extensions.NxtRegistryExtensions]::GetParent($empirumMachineVersionKey)
			$empriumAppKey.Close()
			Remove-NXTEmptyRegistryKey -Key $empriumAppKey
			[Microsoft.Win32.RegistryKey]$empirumVendorKey = [PSADTNXT.Extensions.NxtRegistryExtensions]::GetParent($empriumAppKey)
			$empirumVendorKey.Close()
			Remove-NXTEmptyRegistryKey -Key $empirumVendorKey
		}

		$empirumMachineUninstallKeys | & {
			process {
				Write-ADTLogEntry -Message "Deleting old Empirum uninstall key [$($_.Name)]"
				[PSADTNXT.Extensions.NxtRegistryExtensions]::Delete($_)
			}
		}

		Invoke-ADTAllUsersRegistryAction -UserProfiles (Get-ADTUserProfiles -ExcludeDefaultUser) -ScriptBlock {
			[System.String]$sidValue = $_.SID.Value
			[PSADTNXT.Extensions.NxtRegistryExtensions]::GetAllViews() | & {
				process {
					[Microsoft.Win32.RegistryKey]$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::Users, $_)
					[Microsoft.Win32.RegistryKey]$uninstallRoot = $baseKey.OpenSubKey("$sidValue\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
					$uninstallRoot.GetSubKeyNames() | & {
						process {
							[Microsoft.Win32.RegistryKey]$uninstallKey = $uninstallRoot.OpenSubKey($_)
							if ($uninstallKey.GetValue('MachineKeyName') -like $keyRef -and
								$uninstallKey.GetValue('DisplayVersion') -ne $adtSession.AppVersion -and
								$uninstallKey.GetValue('UninstallString') -like '*\Setup.exe' -and
								([Microsoft.Win32.RegistryKey]$machineKey = $baseKey.OpenSubKey('SOFTWARE\' + $uninstallKey.GetValue('MachineKeyName')))
							) {
								[PSADTNXT.Extensions.NxtRegistryExtensions]::Delete($uninstallKey)
								[PSADTNXT.Extensions.NxtRegistryExtensions]::DeleteTree($machineKey)
								[Microsoft.Win32.RegistryKey]$empriumAppKey = [PSADTNXT.Extensions.NxtRegistryExtensions]::GetParent($machineKey)
								$empriumAppKey.Close()
								Remove-NXTEmptyRegistryKey -Key $empriumAppKey
								[Microsoft.Win32.RegistryKey]$empirumVendorKey = [PSADTNXT.Extensions.NxtRegistryExtensions]::GetParent($empriumAppKey)
								$empirumVendorKey.Close()
								Remove-NXTEmptyRegistryKey -Key $empirumVendorKey
							}
						}
					}
				}
			}
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
