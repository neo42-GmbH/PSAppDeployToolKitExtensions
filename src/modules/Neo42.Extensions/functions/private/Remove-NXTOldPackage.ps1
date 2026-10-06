function Remove-NXTOldPackage {
	<#
	.SYNOPSIS
	Uninstalls old package versions based on the specified parameters and PackageConfig object settings.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This is an internal function.')]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			# A collection of easy access variables for the current scope.
			[System.Collections.Generic.List[Microsoft.Win32.RegistryKey]]$rootKeys = [System.Collections.Generic.List[Microsoft.Win32.RegistryKey]]::new()
			$rootKeys.Add(([Microsoft.Win32.RegistryKey]$localMachineKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)))
			if ([System.Environment]::Is64BitOperatingSystem) {
				$rootKeys.Add([Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry32))
			}

			[System.Collections.Generic.List[Microsoft.Win32.RegistryKey]]$neo42PackageKeys = $rootKeys | & {
				process {
					# Track down all neo42 package keys that are registered in the system for potential removal.
					if (([Microsoft.Win32.RegistryKey]$packageKey = $_.OpenSubKey($ADTSession.NXT.Package.RegistryKey))) { $packageKey }
					# Remove any error keys that might have been left behind by previous installations or uninstallations.
					$_.DeleteSubKeyTree($ADTSession.NXT.Package.RegistryKey + '_Error', $false)
					# Remove any uninstall keys that might have been left behind by previous installations or uninstallations.
					$_.DeleteSubKeyTree("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($ADTSession.NXT.Package.GUID)", $false)
					# Close the root key to ensure that we do not have any open handles to the registry.
					$_.Close()
				}
			}

			# Remove all old package keys and uninstall the packages if configured to do so.
			foreach ($packageKey in $neo42PackageKeys) {
				[System.String]$appPath = $packageKey.GetValue('AppPath', [System.String]::Empty)
				# If the package is configured to uninstall old packages, we will attempt to uninstall it using the uninstall string. If not, we will simply remove the package directory if it exists.
				if ($ADTSession.NXT.Package.UninstallOld) {
					Write-ADTLogEntry -Message "Uninstalling old neo42 package [$($packageKey.Name)]."
					[System.String[]]$uninstallStringParts = ConvertFrom-NXTCommandLine -InputObject ($packageKey.GetValue('UninstallString', [System.String]::Empty))
					if (-not $uninstallStringParts -or $uninstallStringParts.Count -lt 2) {
						[System.Collections.Hashtable]$errorParams = @{
							Exception    = [System.InvalidOperationException]::new('The given package has an invalid uninstall string.')
							Category     = [System.Management.Automation.ErrorCategory]::InvalidOperation
							ErrorId      = 'UninstallStringInvalid'
							TargetObject = $uninstallStringParts
						}
						throw (New-ADTErrorRecord @errorParams)
					}
					[System.String]$uninstallBinary = [PSADTNXT.Shell.NxtCommandLine]::SearchPath($uninstallStringParts[0], [System.EnvironmentVariableTarget]::Machine)
					[System.String]$argumentString = if ($uninstallStringParts.Count -gt 1) {
						[PSADT.ProcessManagement.CommandLineUtilities]::ArgumentListToCommandLine([System.String[]]$uninstallStringParts[1..($uninstallStringParts.Length - 1)])
					}
					else {
						[System.String]::Empty
					}
					$ADTSession.NXT.ProcessResults.Add((Start-ADTProcess -PassThru -WindowStyle Hidden -FilePath $uninstallBinary -ArgumentList $argumentString -ExitOnProcessFailure))
				}
				elseif ([System.IO.Directory]::Exists($appPath)) {
					Write-ADTLogEntry -Message "Removing old neo42 package directory [$appPath]."
					[System.IO.Directory]::Delete($appPath, $true)
				}

				Write-ADTLogEntry -Message "Removing old neo42 package key [$($packageKey.Name)]."
				[PSADTNXT.Extensions.NxtRegistryExtensions]::DeleteTree($packageKey)

				# Update the detection status to reflect the removal of the old package.
				Update-NXTDetectionStatus -ADTSession $ADTSession
			}

			# We need to purge old active setup keys.
			[System.String]$activeSetupSubKey = 'SOFTWARE\Microsoft\Active Setup\Installed Components'

			[System.String]$installKeyName = $ADTSession.NXT.Package.GUID
			if ($localMachineKey.OpenSubKey([System.IO.Path]::Combine($activeSetupSubKey, $installKeyName))) {
				Write-ADTLogEntry -Message "Found previous active setup key [$installKeyName] for install user part. Purging previous key."
				Set-ADTActiveSetup -PurgeActiveSetupKey -Key $installKeyName
			}

			[System.String]$uninstallKeyName = $installKeyName + '.uninstall'
			if ($localMachineKey.OpenSubKey([System.IO.Path]::Combine($activeSetupSubKey, $uninstallKeyName))) {
				Write-ADTLogEntry -Message "Found previous active setup key [$uninstallKeyName] for uninstall user part. Purging previous key."
				Set-ADTActiveSetup -PurgeActiveSetupKey -Key $uninstallKeyName
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
