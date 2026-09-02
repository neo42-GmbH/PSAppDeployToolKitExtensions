function Register-NXTPackage {
	<#
	.SYNOPSIS
	This function writes the status to the registry and closes the session.
	.DESCRIPTION
	This function will invoke the Close-ADTSession function and its hooks to close the session and write the error message to the registry.
	This requires the use of the extended NxtDeploymentSession object.
	#>
	[CmdletBinding()]
	param (
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession),
		[System.Management.Automation.SwitchParameter]
		$AsError,
		[System.String]
		$ErrorMessage
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if (-not $ADTSession.NXT.Package.Register) {
				Write-ADTLogEntry -Severity Warning -Message 'Package registration is skipped due to session configuration.'
				return
			}

			[System.Collections.Generic.IReadOnlyDictionary[System.String, System.Object]]$adtEnvironment = Get-ADTEnvironmentTable
			[Microsoft.Win32.RegistryKey]$rootKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine , [Microsoft.Win32.RegistryView]::Registry64)

			Write-ADTLogEntry -Message 'Registering current package to the package registry.'

			# Determine the registry destinations
			[System.String]$regPackagesKeyPath = $ADTSession.NXT.Package.RegistryKey
			Write-ADTLogEntry -Message "The package will be registered to neo42 registry path [$regPackagesKeyPath]." -DebugMessage

			[System.String]$appRegistryKeyPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($ADTSession.NXT.Package.GUID)"
			Write-ADTLogEntry -Message "The package will be registered to the application registry path [$appRegistryKeyPath]." -DebugMessage

			[System.String]$uninstallString = Resolve-NXTDeployString -PreferExecutable -Root ([System.IO.Path]::Combine($ADTSession.NXT.Package.Directory.FullName, 'neo42-Install')) -Arguments @{
				DeploymentType   = 'Uninstall'
				DeployMode       = 'Silent'
				DeploymentSystem = $ADTSession.NXT.DeploymentSystem
			}
			Write-ADTLogEntry -Message "The calculated uninstall string is [$uninstallString]." -DebugMessage

			# If the session is no error, clear potential error keys, otherwise append _Error to the key path
			if (-not $AsError) {
				$rootKey.DeleteSubKey($regPackagesKeyPath + '_Error', $false)
			}
			else {
				$regPackagesKeyPath = $regPackagesKeyPath + '_Error'
			}

			# The splat objects to write to the neo registry
			[System.Collections.Hashtable[]]$neoRegistryEntries = @(
				@{ Name = 'PackageStatus'; Value = $ADTSession.GetDeploymentStatus() },
				@{ Name = 'DeveloperName'; Value = $ADTSession.AppVendor },
				@{ Name = 'ProductName'; Value = $ADTSession.AppName },
				@{ Name = 'LastExitCode'; Value = $ADTSession.GetExitCode(); Type = [Microsoft.Win32.RegistryValueKind]::String },
				@{ Name = 'DeploymentSystem'; Value = $ADTSession.NXT.DeploymentSystem },
				@{ Name = 'PackageArchitecture'; Value = $ADTSession.AppArch },
				@{ Name = 'Version'; Value = $ADTSession.AppVersion },
				@{ Name = 'Revision'; Value = $ADTSession.AppRevision },
				@{ Name = 'Date'; Value = $ADTSession.CurrentDateTime.ToString([System.Globalization.DateTimeFormatInfo]::InvariantInfo.UniversalSortableDateTimePattern) },
				@{ Name = 'SrcPath'; Value = $ADTSession.NXT.DeployAppScript.Directory.FullName },
				@{ Name = 'StartupProcessor_Architecture'; Value = $adtEnvironment.envArchitecture },
				@{ Name = 'StartupProcessOwner'; Value = "$($adtEnvironment.envUserDomain)\$($adtEnvironment.envUserName)" },
				@{ Name = 'StartupProcessOwnerSID'; Value = $adtEnvironment.CurrentProcessSID },
				@{ Name = 'DebugLogFile'; Value = [System.IO.Path]::Combine($ADTSession.LogPath, $ADTSession.LogName) },
				@{ Name = 'AppPath'; Value = $ADTSession.NXT.Package.Directory.FullName },
				@{ Name = 'UninstallOld'; Value = $ADTSession.NXT.Package.UninstallOld; Type = [Microsoft.Win32.RegistryValueKind]::DWord },
				@{ Name = 'UserPartOnInstallation'; Value = $ADTSession.NXT.Install.UserPart; Type = [Microsoft.Win32.RegistryValueKind]::DWord },
				@{ Name = 'UserPartOnUninstallation'; Value = $ADTSession.NXT.Uninstall.UserPart; Type = [Microsoft.Win32.RegistryValueKind]::DWord }
				@{ Name = 'SoftMigrationOccurred'; Value = [System.Boolean]$ADTSession.NXT.SoftMigration.Result; Type = [Microsoft.Win32.RegistryValueKind]::String }

				if ($AsError) {
					@{ Name = 'ErrorTimeStamp'; Value = [System.DateTime]::Now.ToString([System.Globalization.DateTimeFormatInfo]::InvariantInfo.UniversalSortableDateTimePattern) },
					@{ Name = 'ErrorMessage'; Value = $ErrorMessage }
				}
				else {
					@{ Name = 'UninstallString'; Value = $uninstallString }
				}
			)
			# Write the registry entries
			$rootKey.DeleteSubKey($regPackagesKeyPath, $false)
			[Microsoft.Win32.RegistryKey]$regPackagesKey = $rootKey.CreateSubKey($regPackagesKeyPath, $true)
			foreach ($entry in $neoRegistryEntries) {
				if ($entry.ContainsKey('Type')) {
					$regPackagesKey.SetValue($entry.Name, $entry.Value, $entry.Type)
				}
				else {
					$regPackagesKey.SetValue($entry.Name, $entry.Value)
				}
			}
			$regPackagesKey.Close()

			# Do not register the ARP entry if the session is an error
			if ($AsError) { return }

			# Determine size property
			[System.UInt32]$size = 0
			if ($ADTSession.NXT.Detection.Application) {
				$size = $ADTSession.NXT.Detection.Application.EstimatedSize
			}
			elseif ($ADTSession.NXT.InstallLocation -and $ADTSession.NXT.InstallLocation.Exists) {
				$size = Get-NXTFolderSize -Path $ADTSession.NXT.InstallLocation.FullName -Unit KB
			}

			# The splat objects to write to the app registry if the session is not an error
			[System.Collections.Hashtable[]]$appRegistryEntries = @(
				@{ Name = 'DisplayName'; Value = $ADTSession.NXT.Package.DisplayName },
				@{ Name = 'DisplayVersion'; Value = $ADTSession.AppVersion },
				@{ Name = 'neoRegPackagesKeyRef'; Value = $ADTSession.NXT.Package.RegistryKey },
				@{ Name = 'NoModify'; Value = 1; Type = [Microsoft.Win32.RegistryValueKind]::DWord },
				@{ Name = 'NoRepair'; Value = 1; Type = [Microsoft.Win32.RegistryValueKind]::DWord },
				@{ Name = 'Publisher'; Value = $ADTSession.AppVendor },
				@{ Name = 'InstallDate'; Value = $ADTSession.CurrentDateTime.ToString('yyyyMMdd') },
				@{ Name = 'InstallLocation'; Value = if ($ADTSession.NXT.InstallLocation) { $ADTSession.NXT.InstallLocation.FullName } else { [System.String]::Empty } },
				@{ Name = 'NoRemove'; Value = ($ADTSession.NXT.Package.ApplicationEntry -ne [PSADTNXT.Deployment.ArpRegistrationType]::Uninstallable); Type = [Microsoft.Win32.RegistryValueKind]::DWord },
				@{ Name = 'SystemComponent'; Value = ($ADTSession.NXT.Package.ApplicationEntry -eq [PSADTNXT.Deployment.ArpRegistrationType]::Hidden); Type = [Microsoft.Win32.RegistryValueKind]::DWord },
				@{ Name = 'PackageApplicationDir'; Value = $ADTSession.NXT.Package.Directory.FullName },
				@{ Name = 'PackageProductName'; Value = $ADTSession.AppName },
				@{ Name = 'PackageRevision'; Value = $ADTSession.AppRevision },
				@{ Name = 'PackageVersion'; Value = $ADTSession.AppVersion }
				@{ Name = 'DisplayIcon'; Value = [System.IO.Path]::Combine($ADTSession.NXT.Package.Directory.FullName, 'neo42-install', 'Setup.ico') }
				@{ Name = 'UninstallString'; Value = $uninstallString }
				@{ Name = 'SoftMigrationOccurred'; Value = [System.Boolean]$ADTSession.NXT.SoftMigration.Result; Type = [Microsoft.Win32.RegistryValueKind]::String }
				@{ Name = 'EstimatedSize'; Value = $size; Type = [Microsoft.Win32.RegistryValueKind]::DWord }
				@{ Name = 'InstallSource'; Value = $ADTSession.NXT.DeployAppScript.Directory.FullName }
				@{ Name = 'VersionMajor'; Value = $ADTSession.AppVersion.Split('.')[0]; Type = [Microsoft.Win32.RegistryValueKind]::DWord }
				@{ Name = 'VersionMinor'; Value = $ADTSession.AppVersion.Split('.')[1]; Type = [Microsoft.Win32.RegistryValueKind]::DWord }
			)

			# Register to windows control panel
			$rootKey.DeleteSubKey($appRegistryKeyPath, $false)
			[Microsoft.Win32.RegistryKey]$appRegistryKey = $rootKey.CreateSubKey($appRegistryKeyPath, $true)
			foreach ($entry in $appRegistryEntries) {
				if ($entry.ContainsKey('Type')) {
					$appRegistryKey.SetValue($entry.Name, $entry.Value, $entry.Type)
				}
				else {
					$appRegistryKey.SetValue($entry.Name, $entry.Value)
				}
			}
			$appRegistryKey.Close()
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
