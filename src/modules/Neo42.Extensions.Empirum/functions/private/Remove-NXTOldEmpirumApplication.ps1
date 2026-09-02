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
		if ($adtSession.NXT.DeploymentSystem -ne 'Empirum') { return }

		[Microsoft.Win32.RegistryKey]$empirumAppKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
			[Microsoft.Win32.RegistryHive]::LocalMachine,
			[Microsoft.Win32.RegistryView]::Registry64
		).OpenSubKey(
			"$([System.IO.Path]::GetDirectoryName($adtSession.NXT.Package.RegistryKey))\$($adtSession.AppVendor)\$($adtSession.AppName)",
			$true
		)

		if (-not $empirumAppKey) {
			Write-ADTLogEntry -Message 'No Empirum application key was found.' -DebugMessage
			return
		}

		$empirumAppKey.GetSubKeyNames() | & {
			process {
				if ($adtSession.NXT.Package.UninstallOld) {
					Write-ADTLogEntry -Message "Uninstalling old Empirum package [$($empirumAppKey.Name)\$_]."
					[Microsoft.Win32.RegistryKey]$empirumSetupKey = $empirumAppKey.OpenSubKey("$_\Setup", $false)

					if ($empirumSetupKey -and -not ([System.String]::IsNullOrWhiteSpace(([System.String]$uninstallString = $empirumSetupKey.GetValue('UninstallString'))))) {
						[System.Collections.Generic.List[System.String]]$arguments = [System.Collections.Generic.List[System.String]]::new()
						[System.String[]]$uninstallStringParts = ConvertFrom-NXTCommandLine -InputObject $uninstallString
						if ($uninstallStringParts -and $uninstallStringParts.Count -gt 1) {
							[System.String]$uninstallBinary = [PSADTNXT.Shell.NxtCommandLine]::SearchPath($uninstallStringParts[0], [System.EnvironmentVariableTarget]::Machine)
							[System.Boolean]$machineSetup = [System.Byte]$empirumSetupKey.GetValue('MachineSetup', 0)
							[System.String]$logFilePath = [System.IO.Path]::Combine($adtSession.LogPath, "emp_old_uninstall_$($adtEnvironment.DeploymentTimestamp).log")

							$arguments.AddRange([System.String[]]$uninstallStringParts[1..($uninstallStringParts.Length - 1)])
							$arguments.AddRange(([System.String[]]@('/X8', '/S0', '/F', "/E+$logFilePath")))
							if ($machineSetup) { $arguments.Add('/AW') }

							$adtSession.NXT.ProcessResults.Add((Start-ADTProcess -PassThru -ExitOnProcessFailure -FilePath $uninstallBinary -ArgumentList $arguments))
						}
						else {
							Write-ADTLogEntry -Severity Error -Message 'Cannot run uninstallation, as uninstall string is not valid.'
						}
					}
					else {
						Write-ADTLogEntry -Severity Warning -Message "Empirum application version [$_] does not contain uninstall information. Proceeding with unregister."
					}

					if ($empirumSetupKey) {
						$empirumSetupKey.Close()
					}
				}

				Write-ADTLogEntry -Message "Unregistering old Empirum application registration for version [$_]"
				$empirumAppKey.DeleteSubKeyTree($_)
			}
		}

		# Clean up empty Empirum application and vendor keys.
		Remove-NXTEmptyRegistryKey -Key $empirumAppKey
		Remove-NXTEmptyRegistryKey -Key ([PSADTNXT.Extensions.NxtRegistryExtensions]::GetParent($empirumAppKey))
		$empirumAppKey.Close()
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
