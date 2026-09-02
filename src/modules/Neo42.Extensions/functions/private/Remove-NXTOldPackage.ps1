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

	# A collection of easy access variables for the current scope.
	[System.Collections.Generic.List[Microsoft.Win32.RegistryKey]]$rootKeys = [PSADTNXT.Extensions.NxtRegistryExtensions]::GetAllViews() | & {
		process { [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $_) }
	}

	[System.Collections.Generic.List[Microsoft.Win32.RegistryKey]]$neo42PackageKeys = foreach ($key in $rootKeys) {
		if ([Microsoft.Win32.RegistryKey]$result = $key.OpenSubKey($ADTSession.NXT.Package.RegistryKey)) { $result }
	}

	foreach ($packageKey in $neo42PackageKeys) {
		if ((Compare-NXTVersion -Version $packageKey.GetValue('Version') -Target $ADTSession.AppVersion) -eq [PSADTNXT.Application.VersionCompareResult]::Update) {
			Show-NXTInstallationWelcome -ADTSession $ADTSession -DeploymentDefaults -NoBalloonTip
			[System.String]$appPath = $packageKey.GetValue('AppPath', [System.String]::Empty)

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
				$ADTSession.NXT.ProcessResults.Add((Start-ADTProcess -PassThru -WindowStyle Hidden -ExitOnProcessFailure -FilePath $uninstallBinary -ArgumentList $argumentString))
			}
			elseif ([System.IO.Directory]::Exists($appPath)) {
				Write-ADTLogEntry -Message "Removing old neo42 package directory [$appPath]."
				[System.IO.Directory]::Delete($appPath, $true)
			}

			Write-ADTLogEntry -Message "Removing old neo42 package key [$($packageKey.Name)]."
			[PSADTNXT.Extensions.NxtRegistryExtensions]::DeleteTree($packageKey)

			Update-NXTDetectionStatus -ADTSession $ADTSession
		}
	}

	foreach ($key in $rootKeys) {
		$key.DeleteSubKeyTree("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($ADTSession.NXT.Package.GUID)", $false)
		$key.Close()
	}
}
