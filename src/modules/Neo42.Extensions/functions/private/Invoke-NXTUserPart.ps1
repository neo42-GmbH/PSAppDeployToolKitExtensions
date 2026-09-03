function Invoke-NXTUserPart {
	<#
	.SYNOPSIS
	Handles the user part of the NXT deployment.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Internal function, no ShouldProcess required')]
	[OutputType([PSADT.ProcessManagement.ProcessResult])]
	[CmdletBinding()]
	param (
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession)
	)

	try {
		# Determine some variables for the user part.
		[System.Collections.Hashtable]$adtConfig = Get-ADTConfig
		[System.String]$installKeyName = $ADTSession.NXT.Package.GUID
		[System.String]$uninstallKeyName = $installKeyName + '.uninstall'
		[System.String]$currentKeyName = if ($ADTSession.NXT.DeploymentType.IsInstall) { $installKeyName } else { $uninstallKeyName }
		[System.String]$activeSetupSubKey = 'SOFTWARE\Microsoft\Active Setup\Installed Components'
		[Microsoft.Win32.RegistryKey]$localMachineKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
		[Microsoft.Win32.RegistryKey]$usersKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::Users, [Microsoft.Win32.RegistryView]::Registry64)

		# We need to purge old and conflicting active setup keys before registering the new ones.
		[System.Collections.Generic.List[System.String]]$keysToPurge = [System.Collections.Generic.List[System.String]]::new()

		# Check keys for opposite deployment type
		if ($ADTSession.NXT.DeploymentType.IsInstall) {
			if ($localMachineKey.OpenSubKey([System.IO.Path]::Combine($activeSetupSubKey, $uninstallKeyName))) {
				Write-ADTLogEntry -Message "Found conflicting active setup key [$uninstallKeyName] for uninstall user part. Purging previous key."
				$keysToPurge.Add($uninstallKeyName)
			}
			if (-not $ADTSession.NXT.Install.UserPart -and
				$localMachineKey.OpenSubKey([System.IO.Path]::Combine($activeSetupSubKey, $installKeyName))
			) {
				Write-ADTLogEntry -Message "Found previous active setup key [$installKeyName] for install user part, but user part is no longer configured. Purging previous key."
				$keysToPurge.Add($installKeyName)
			}
		}
		else {
			if ($localMachineKey.OpenSubKey([System.IO.Path]::Combine($activeSetupSubKey, $installKeyName))) {
				Write-ADTLogEntry -Message "Found conflicting active setup key [$installKeyName] for install user part. Purging previous key."
				$keysToPurge.Add($installKeyName)
			}
			if (-not $ADTSession.NXT.Uninstall.UserPart -and
				$localMachineKey.OpenSubKey([System.IO.Path]::Combine($activeSetupSubKey, $uninstallKeyName))
			) {
				Write-ADTLogEntry -Message "Found previous active setup key [$uninstallKeyName] for uninstall user part, but user part is no longer configured. Purging previous key."
				$keysToPurge.Add($uninstallKeyName)
			}
		}

		# Remove previous active setup key if version is equal for reinstallation scenarios
		if ($currentKeyName -notin $keysToPurge -and
			([Microsoft.Win32.RegistryKey]$currentkey = $localMachineKey.OpenSubKey([System.IO.Path]::Combine($activeSetupSubKey, $currentKeyName))) -and
			$currentkey.GetValue('Version') -eq $ADTSession.NXT.UserPartRevision
		) {
			Write-ADTLogEntry -Message "Previous active setup key [$currentKeyName] has the same revision as the current user part. Purging previous key for reinstallation."
			$keysToPurge.Add($currentKeyName)
		}

		foreach ($key in $keysToPurge) {
			if ($localMachineKey.OpenSubKey([System.IO.Path]::Combine($activeSetupSubKey, $key))) {
				Set-ADTActiveSetup -PurgeActiveSetupKey -Key $key
			}
		}

		# Test if the user part is configured for the current deployment type.
		if (($ADTSession.NXT.DeploymentType.IsInstall -and -not $ADTSession.NXT.Install.UserPart) -or
			($ADTSession.NXT.DeploymentType.IsUninstall -and -not $ADTSession.NXT.Uninstall.UserPart)
		) {
			Write-ADTLogEntry -Message "User part is not configured for [$($ADTSession.DeploymentType)]. Skipping user part execution." -DebugMessage
			return
		}
		elseif (-not $ADTSession.NXT.Package.Register) {
			Write-ADTLogEntry -Severity Warning -Message 'User part execution is skipped as the package has not been registered.'
			return
		}

		# Check if the terminal server limitation is active
		if ((Get-ADTOperatingSystemInfo).IsTerminalServer -and
			$false -eq $adtConfig['NXT']['Toolkit']['UserPartOnTerminalServer']
		) {
			Write-ADTLogEntry -Severity Warning -Message 'A user part was configured for this package, but the current system is a terminal server and user parts on terminal servers are disabled by configuration.'
			return
		}

		# Register the active setup keys for the user part.
		Write-ADTLogEntry -Message "Registering system active setup key [$currentKeyName]."
		[System.String]$binary, [System.String]$invokeArgs = Resolve-NXTDeployString -Root "$($ADTSession.NXT.Package.Directory.FullName)\neo42-Install" -BinarySeparate -Arguments @{
			DeploymentType   = if ($ADTSession.NXT.DeploymentType.IsInstall) { [PSADTNXT.Deployment.NxtDeploymentType]::TriggerInstallUserPart } else { [PSADTNXT.Deployment.NxtDeploymentType]::TriggerUninstallUserPart }
			DeployMode       = [PSADT.Module.DeployMode]::Silent
			DeploymentSystem = $ADTSession.NXT.DeploymentSystem
		}
		Set-ADTActiveSetup -StubExePath $binary -Key $currentKeyName -Version $ADTSession.NXT.UserPartRevision -NoExecuteForCurrentUser -Arguments $invokeArgs

		# Run the user part for all logged on users.
		Write-ADTLogEntry -Message 'Querying logged on users.' -DebugMessage
		if (-not ([System.Collections.ObjectModel.ReadOnlyCollection[PSADT.TerminalServices.SessionInfo]]$users = Get-ADTLoggedOnUser -InformationAction SilentlyContinue)) {
			Write-ADTLogEntry -Message 'No users are logged on. Skipping user part execution.'
			return
		}

		[System.Collections.Generic.Dictionary[PSADT.TerminalServices.SessionInfo, PSADT.ProcessManagement.ProcessHandle]]$processes = [System.Collections.Generic.Dictionary[PSADT.TerminalServices.SessionInfo, PSADT.ProcessManagement.ProcessHandle]]::new()
		[Microsoft.Win32.RegistryKey]$activeSetupKey = $localMachineKey.OpenSubKey([System.IO.Path]::Combine($activeSetupSubKey, $currentKeyName))
		[System.String]$userPartRevision = $activeSetupKey.GetValue('Version')
		[System.String]$stubPath = $activeSetupKey.GetValue('StubPath')
		$activeSetupKey.Close()

		[System.String]$binary, [System.String]$invokeArgs = Resolve-NXTDeployString -Root "$($ADTSession.NXT.Package.Directory.FullName)\neo42-Install" -BinarySeparate -Arguments @{
			DeploymentType   = if ($ADTSession.NXT.DeploymentType.IsInstall) { [PSADTNXT.Deployment.NxtDeploymentType]::InstallUserPart } else { [PSADTNXT.Deployment.NxtDeploymentType]::UninstallUserPart }
			DeployMode       = [PSADT.Module.DeployMode]::Silent
			DeploymentSystem = $ADTSession.NXT.DeploymentSystem
		}
		foreach ($user in $users) {
			Write-ADTLogEntry -Message "Starting user part for [$($user.NTAccount)]."
			$processes[$user] = Start-ADTProcessAsUser -FilePath $binary -ArgumentList $invokeArgs -Username $user.NTAccount -NoStreamLogging -DenyUserTermination -WindowStyle Hidden -NoWait -PassThru

			Write-ADTLogEntry -Message "Registering active setup status for user [$($user.NTAccount)]." -DebugMessage
			[Microsoft.Win32.RegistryKey]$userKey = $usersKey.CreateSubKey([System.IO.Path]::Combine($user.SID, $activeSetupSubKey, $currentKeyName))
			$userKey.SetValue('Version', $userPartRevision, [Microsoft.Win32.RegistryValueKind]::String)
			$userKey.SetValue('StubPath', $stubPath, [Microsoft.Win32.RegistryValueKind]::String)
			$userKey.Close()
		}

		# Evaluate the user part processes if any were started.
		Write-ADTLogEntry -Message "Waiting for [$($processes.Count)] user part process(es) to finish."
		foreach ($userProcessPair in $processes.GetEnumerator()) {
			[System.String]$userName = $userProcessPair.Key.NTAccount.ToString()
			[PSADT.ProcessManagement.ProcessHandle]$processHandle = $userProcessPair.Value
			if ($processHandle) {
				[PSADT.ProcessManagement.ProcessResult]$result = $processHandle.Task.GetAwaiter().GetResult()
				$ADTSession.NXT.ProcessResults.Add($result)

				[PSADT.Module.DeploymentStatus]$adtSessionStatus = $ADTSession.GetDeploymentStatus()
				[System.Boolean]$isSuccessCode = $ADTSession.AppSuccessExitCodes.Contains($result.ExitCode)
				[System.Boolean]$isRestartCode = $ADTSession.AppRebootExitCodes.Contains($result.ExitCode)
				[System.Boolean]$isFailureCode = -not $isSuccessCode -and -not $isRestartCode
				if ($isFailureCode) {
					Write-ADTLogEntry -Severity Error -Message "User part failed for [$userName] with exit code [$($result.ExitCode)]."
					if ($adtSessionStatus -le [PSADT.Module.DeploymentStatus]::Error) { $ADTSession.SetExitCode($result.ExitCode) }
				}
				elseif ($isRestartCode) {
					Write-ADTLogEntry -Severity Warning -Message "User part requires a reboot for [$userName] with exit code [$($result.ExitCode)]."
					if ($adtSessionStatus -le [PSADT.Module.DeploymentStatus]::RestartRequired) { $ADTSession.SetExitCode($result.ExitCode) }
				}
				else {
					Write-ADTLogEntry -Severity Success -Message "User part completed successfully for [$userName] with exit code [$($result.ExitCode)]."
				}
			}
			else {
				$ADTSession.NXT.ProcessResults.Add([PSADT.ProcessManagement.ProcessResult]::new(1))
				$ADTSession.SetExitCode(1)
				Write-ADTLogEntry -Severity Error -Message "Failed to start user part for [$userName]."
			}
		}

		$localMachineKey.Close()
		$usersKey.Close()

		Write-ADTLogEntry -Severity Success -Message 'User part execution completed.'
	}
	catch {
		Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
	}
}
