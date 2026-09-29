function Register-NXTPackage {
	<#
	.SYNOPSIS
	This function writes the status to the registry and closes the session.
	.DESCRIPTION
	This function will invoke the Close-ADTSession function and its hooks to close the session and write the error message to the registry.
	This requires the use of the extended NxtDeploymentSession object.
	#>
	[CmdletBinding()]
	param ()
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[PSADT.Module.DeploymentSession]$adtSession = Get-ADTSession
			if ($adtSession -isnot [PSADTNXT.Foundation.NxtDeploymentSession] -or
				-not $adtSession.NXT.DeploymentType.IsMachinePart -or
				-not $adtSession.NXT.DeploymentType.IsInstall
			) { return }

			if (-not $adtSession.NXT.DeploymentInvoked) {
				Write-ADTLogEntry -Message 'Skipping package registration as the deployment has not been invoked.'
			}

			if (-not $adtSession.NXT.Package.Register) {
				Write-ADTLogEntry -Severity Warning -Message 'Package registration is skipped due to session configuration.'
				return
			}

			[System.Collections.Generic.IReadOnlyDictionary[System.String, System.Object]]$adtEnvironment = Get-ADTEnvironmentTable
			[Microsoft.Win32.RegistryKey]$rootKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine , [Microsoft.Win32.RegistryView]::Registry64)
			[System.Boolean]$asError = $adtSession.GetDeploymentStatus() -eq [PSADT.Module.DeploymentStatus]::Error

			Write-ADTLogEntry -Message 'Registering current package to the package registry.'

			# Determine the registry destinations
			[System.String]$regPackagesKeyPath = $adtSession.NXT.Package.RegistryKey
			Write-ADTLogEntry -Message "The package will be registered to neo42 registry path [$regPackagesKeyPath]." -DebugMessage

			[System.String]$appRegistryKeyPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($adtSession.NXT.Package.GUID)"
			Write-ADTLogEntry -Message "The package will be registered to the application registry path [$appRegistryKeyPath]." -DebugMessage

			[System.String]$uninstallString = Resolve-NXTDeployString -PreferExecutable -Root ([System.IO.Path]::Combine($adtSession.NXT.Package.Directory.FullName, 'neo42-Install')) -Arguments @{
				DeploymentType   = [PSADTNXT.Deployment.NxtDeploymentType]::Install
				DeployMode       = [PSADT.Module.DeployMode]::Silent
				DeploymentSystem = $adtSession.NXT.DeploymentSystem
			}
			Write-ADTLogEntry -Message "The calculated uninstall string is [$uninstallString]." -DebugMessage

			# If the session is no error, clear potential error keys, otherwise append _Error to the key path
			if (-not $asError) {
				$rootKey.DeleteSubKey($regPackagesKeyPath + '_Error', $false)
			}
			else {
				$regPackagesKeyPath = $regPackagesKeyPath + '_Error'
			}

			# The splat objects to write to the neo registry
			[System.Collections.Hashtable[]]$neoRegistryEntries = @(
				@{ Name = 'PackageStatus'; Value = $adtSession.GetDeploymentStatus() },
				@{ Name = 'DeveloperName'; Value = $adtSession.AppVendor },
				@{ Name = 'ProductName'; Value = $adtSession.AppName },
				@{ Name = 'LastExitCode'; Value = $adtSession.GetExitCode(); Type = [Microsoft.Win32.RegistryValueKind]::String },
				@{ Name = 'DeploymentSystem'; Value = $adtSession.NXT.DeploymentSystem },
				@{ Name = 'PackageArchitecture'; Value = $adtSession.AppArch },
				@{ Name = 'Version'; Value = $adtSession.AppVersion },
				@{ Name = 'Revision'; Value = $adtSession.AppRevision },
				@{ Name = 'Date'; Value = $adtSession.CurrentDateTime.ToString([System.Globalization.DateTimeFormatInfo]::InvariantInfo.UniversalSortableDateTimePattern) },
				@{ Name = 'SrcPath'; Value = $adtSession.NXT.DeployAppScript.Directory.FullName },
				@{ Name = 'StartupProcessor_Architecture'; Value = $adtEnvironment.envArchitecture },
				@{ Name = 'StartupProcessOwner'; Value = "$($adtEnvironment.envUserDomain)\$($adtEnvironment.envUserName)" },
				@{ Name = 'StartupProcessOwnerSID'; Value = $adtEnvironment.CurrentProcessSID },
				@{ Name = 'DebugLogFile'; Value = [System.IO.Path]::Combine($adtSession.LogPath, $adtSession.LogName) },
				@{ Name = 'DebugLogPath'; Value = $adtSession.LogPath },
				@{ Name = 'AppPath'; Value = $adtSession.NXT.Package.Directory.FullName },
				@{ Name = 'UninstallOld'; Value = $adtSession.NXT.Package.UninstallOld; Type = [Microsoft.Win32.RegistryValueKind]::DWord },
				@{ Name = 'UserPartOnInstallation'; Value = $adtSession.NXT.Install.UserPart; Type = [Microsoft.Win32.RegistryValueKind]::DWord },
				@{ Name = 'UserPartOnUninstallation'; Value = $adtSession.NXT.Uninstall.UserPart; Type = [Microsoft.Win32.RegistryValueKind]::DWord },
				@{ Name = 'UserPartRevision'; Value = $adtSession.NXT.UserPartRevision }
				@{ Name = 'SoftMigrationOccurred'; Value = ([System.Boolean]$adtSession.NXT.SoftMigration.Result).ToString().ToLower(); Type = [Microsoft.Win32.RegistryValueKind]::String }

				if ($asError) {
					@{ Name = 'ErrorTimeStamp'; Value = [System.DateTime]::Now.ToString([System.Globalization.DateTimeFormatInfo]::InvariantInfo.UniversalSortableDateTimePattern) },
					@{ Name = 'ErrorMessage'; Value = if ($adtSession.NXT.ErrorMessage) { $adtSession.NXT.ErrorMessage } else { 'No error message provided.' } }
					@{ Name = 'ErrorPhase'; Value = $adtSession.NXT.ErrorPhase }
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
			if ($asError) { return }

			# Determine size property
			[System.UInt32]$size = 0
			if ($adtSession.NXT.Detection.Application) {
				$size = $adtSession.NXT.Detection.Application.EstimatedSize
			}
			elseif ($adtSession.NXT.InstallLocation -and $adtSession.NXT.InstallLocation.Exists) {
				$size = Get-NXTFolderSize -Path $adtSession.NXT.InstallLocation.FullName -Unit KB
			}

			# The splat objects to write to the app registry if the session is not an error
			[System.Collections.Hashtable[]]$appRegistryEntries = @(
				@{ Name = 'DisplayName'; Value = $adtSession.NXT.Package.DisplayName },
				@{ Name = 'DisplayVersion'; Value = $adtSession.AppVersion },
				@{ Name = 'neoRegPackagesKeyRef'; Value = $adtSession.NXT.Package.RegistryKey },
				@{ Name = 'NoModify'; Value = 1; Type = [Microsoft.Win32.RegistryValueKind]::DWord },
				@{ Name = 'NoRepair'; Value = 1; Type = [Microsoft.Win32.RegistryValueKind]::DWord },
				@{ Name = 'Publisher'; Value = $adtSession.AppVendor },
				@{ Name = 'InstallDate'; Value = $adtSession.CurrentDateTime.ToString('yyyyMMdd') },
				@{ Name = 'InstallLocation'; Value = if ($adtSession.NXT.InstallLocation) { $adtSession.NXT.InstallLocation.FullName } else { [System.String]::Empty } },
				@{ Name = 'NoRemove'; Value = ($adtSession.NXT.Package.ApplicationEntry -ne [PSADTNXT.Deployment.ArpRegistrationType]::Uninstallable); Type = [Microsoft.Win32.RegistryValueKind]::DWord },
				@{ Name = 'SystemComponent'; Value = ($adtSession.NXT.Package.ApplicationEntry -eq [PSADTNXT.Deployment.ArpRegistrationType]::Hidden); Type = [Microsoft.Win32.RegistryValueKind]::DWord },
				@{ Name = 'PackageApplicationDir'; Value = $adtSession.NXT.Package.Directory.FullName },
				@{ Name = 'PackageProductName'; Value = $adtSession.AppName },
				@{ Name = 'PackageRevision'; Value = $adtSession.AppRevision },
				@{ Name = 'PackageVersion'; Value = $adtSession.AppVersion }
				@{ Name = 'DisplayIcon'; Value = [System.IO.Path]::Combine($adtSession.NXT.Package.Directory.FullName, 'neo42-install', 'Setup.ico') }
				@{ Name = 'UninstallString'; Value = $uninstallString }
				@{ Name = 'SoftMigrationOccurred'; Value = ([System.Boolean]$adtSession.NXT.SoftMigration.Result).ToString().ToLower(); Type = [Microsoft.Win32.RegistryValueKind]::String }
				@{ Name = 'EstimatedSize'; Value = $size; Type = [Microsoft.Win32.RegistryValueKind]::DWord }
				@{ Name = 'InstallSource'; Value = $adtSession.NXT.DeployAppScript.Directory.FullName }
				@{ Name = 'VersionMajor'; Value = $adtSession.AppVersion.Split('.')[0]; Type = [Microsoft.Win32.RegistryValueKind]::DWord }
				@{ Name = 'VersionMinor'; Value = $adtSession.AppVersion.Split('.')[1]; Type = [Microsoft.Win32.RegistryValueKind]::DWord }
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
