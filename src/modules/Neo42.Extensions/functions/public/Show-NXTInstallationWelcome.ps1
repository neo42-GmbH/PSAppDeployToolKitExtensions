function Show-NXTInstallationWelcome {
	<#
	.SYNOPSIS
	Shows an installation welcome dialog to the user, optionally allowing them to defer the installation if blocking processes are detected.
	.DESCRIPTION
	Shows an installation welcome dialog to the user, optionally allowing them to defer the installation if blocking processes are detected.
	Wraps the Show-ADTInstallationWelcome function to provide NXT-specific functionality.
	Enables support for reading values from the SetupCfg file and passing them to the Show-ADTInstallationWelcome function.
	.PARAMETER Title
	The title of the installation welcome dialog.
	.PARAMETER CloseProcesses
	A list of processes that may block the installation.
	.PARAMETER ContinueType
	The type of action to take if the the dialog times out.
	.PARAMETER MinimizeWindows
	Whether to minimize all windows when the dialog is shown.
	.PARAMETER CustomText
	Whether to show custom text in the dialog. The text is defined in the toolkit configuration.
	.PARAMETER AllowDeferCloseProcesses
	Will allow the user to defer the installation.
	Granular control is available via the DeferTimes, DeferDays, and DeferDeadline parameters.
	.PARAMETER DeferTimes
	The number of times the user can defer the installation.
	.PARAMETER DeferDays
	The number of days the user can defer the installation.
	This option qualifies the DeferTimes option and is only used if DeferTimes is set.
	.PARAMETER DeferDeadline
	The date and time when the installation can no longer be deferred. If DeferDays is set, the earliest date will be used.
	.PARAMETER DeferRunInterval
	A time span before the next interactive deployment is attempted.
	.PARAMETER NotTopMost
	Whether to not show the dialog as a top-most window.
	.PARAMETER PersistPrompt
	Whether to persist the prompt for the user to close blocking processes.
	.PARAMETER HideCloseButton
	Whether to hide the close button on the dialog.
	.PARAMETER AllowMove
	Whether to allow the user to move the dialog.
	.PARAMETER NoBalloonTip
	Whether to suppress the balloon tip after the installation welcome dialog is closed.
	.PARAMETER AllowDoNotDisturb
	Whether to suppress the installation welcome dialog if the user has Do Not Disturb enabled on their session.
	.PARAMETER BlockExecution
	Whether to block the execution of the deployment until the deployment is closed.
	.PARAMETER Timeout
	The time to wait before the dialog times out.
	.PARAMETER DeploymentDefaults
	Whether to use the deployment defaults for the installation welcome dialog.
	Any parameter specified will override the deployment defaults.
	.PARAMETER ADTSession
	The current ADT session. Requires the extension session to be initialized.
	.NOTES
	This function is already built into the Invoke-NXTDeployment function.
	Only use this function if you want to show the installation welcome for custom cases.
	#>
	[CmdletBinding()]
	param (
		[System.String]
		$Title = $ADTSession.InstallTitle,
		[PSADTNXT.ProcessManagement.NxtCloseProcess[]]
		$CloseProcesses,
		[System.Management.Automation.SwitchParameter]
		$MinimizeWindows,
		[System.Management.Automation.SwitchParameter]
		$CustomText,
		[System.Management.Automation.SwitchParameter]
		$AllowDeferCloseProcesses,
		[System.UInt32]
		$DeferTimes,
		[System.UInt32]
		$DeferDays,
		[System.Nullable[System.DateTime]]
		$DeferDeadline,
		[System.TimeSpan]
		$DeferRunInterval,
		[System.Management.Automation.SwitchParameter]
		$NotTopMost,
		[System.Management.Automation.SwitchParameter]
		$PersistPrompt,
		[System.Management.Automation.SwitchParameter]
		$HideCloseButton,
		[System.Management.Automation.SwitchParameter]
		$AllowMove,
		[System.Management.Automation.SwitchParameter]
		$NoBalloonTip,
		[System.Management.Automation.SwitchParameter]
		$AllowDoNotDisturb,
		[System.Management.Automation.SwitchParameter]
		$BlockExecution,
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$Timeout,
		[PSADTNXT.UI.ContinueType]
		$ContinueType = 'Abort',
		[System.Management.Automation.SwitchParameter]
		$DeploymentDefaults,
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession)
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Collections.Hashtable]$adtStrings = Get-ADTStringTable
		[System.Collections.Hashtable]$adtConfig = Get-ADTConfig
		[System.Collections.Generic.IReadOnlyDictionary[System.String, System.Object]]$adtEnvironment = Get-ADTEnvironmentTable
		[System.Boolean]$legacyUi = $adtConfig['NXT']['UI']['UseLegacyUI']
	}
	process {
		try {
			# Apply deployment defaults if specified
			if ($DeploymentDefaults) {
				if (-not $PSBoundParameters.ContainsKey('Title')) { $Title = $ADTSession.InstallTitle }
				if (-not $PSBoundParameters.ContainsKey('CloseProcesses')) { $CloseProcesses = $ADTSession.NXT.CloseProcesses }
				if (-not $PSBoundParameters.ContainsKey('ContinueType')) { $ContinueType = $ADTSession.NXT.SetupCfg['AskKillProcesses']['CONTINUETYPE'] }
				if (-not $PSBoundParameters.ContainsKey('MinimizeWindows')) { $MinimizeWindows = $ADTSession.NXT.SetupCfg['AskKillProcesses']['MINIMIZEALLWINDOWS'] -eq '1' }
				if (-not $PSBoundParameters.ContainsKey('NotTopMost')) { $NotTopMost = $ADTSession.NXT.SetupCfg['AskKillProcesses']['TOPMOSTWINDOW'] -eq '0' }
				if (-not $PSBoundParameters.ContainsKey('PersistPrompt')) { $PersistPrompt = -not $NotTopMost }
				if (-not $PSBoundParameters.ContainsKey('HideCloseButton')) { $HideCloseButton = $ADTSession.NXT.SetupCfg['AskKillProcesses']['USERCANCLOSEALL'] -eq '0' }
				if (-not $PSBoundParameters.ContainsKey('AllowMove')) { $AllowMove = $true }
				if (-not $PSBoundParameters.ContainsKey('AllowDoNotDisturb')) { $AllowDoNotDisturb = $ADTSession.NXT.SetupCfg['AskKillProcesses']['DONOTDISTURB'] -eq '1' }
				if (-not $PSBoundParameters.ContainsKey('BlockExecution')) { $BlockExecution = $adtConfig['NXT']['Toolkit']['BlockExecution'] }
				if (-not $PSBoundParameters.ContainsKey('Timeout')) { $Timeout = [System.TimeSpan]::FromSeconds($ADTSession.NXT.SetupCfg['AskKillProcesses']['TIMEOUT']) }
				if (-not $PSBoundParameters.ContainsKey('CustomText')) { $CustomText = -not [System.String]::IsNullOrWhiteSpace($adtStrings['CloseAppsPrompt']['CustomMessage']) }
				if (-not $PSBoundParameters.ContainsKey('DeferRunInterval') -and $ADTSession.NXT.SetupCfg['AskKillProcesses']['DEFERINTERVAL']) {
					$DeferRunInterval = [System.TimeSpan]::FromMinutes($ADTSession.NXT.SetupCfg['AskKillProcesses']['DEFERINTERVAL'])
				}

				if ($ADTSession.NXT.DeploymentType.IsUninstall) {
					$AllowDeferCloseProcesses = $false
				}
				elseif ($ADTSession.NXT.SetupCfg['AskKillProcesses']['ALLOWABORTBYUSER'] -eq '1') {
					Write-ADTLogEntry -Severity Warning -Message 'Special SetupCfg option [ALLOWABORTBYUSER] was set to [1]. Any further defer option will be ignored and the user is allowed to defer indefinitely.'
					$DeferTimes = 0
					$DeferDays = 0
					$DeferDeadline = $null
					$DeferRunInterval = [System.TimeSpan]::Zero
					$AllowDeferCloseProcesses = $true
				}
				else {
					if (-not $PSBoundParameters.ContainsKey('DeferTimes')) { $DeferTimes = $ADTSession.NXT.SetupCfg['AskKillProcesses']['DEFERTIMES'] }
					if (-not $PSBoundParameters.ContainsKey('DeferDays')) { $DeferDays = $ADTSession.NXT.SetupCfg['AskKillProcesses']['DEFERDAYS'] }

					if (-not $PSBoundParameters.ContainsKey('DeferDeadline') -and -not [System.String]::IsNullOrWhiteSpace($ADTSession.NXT.SetupCfg['AskKillProcesses']['DEFERDEADLINE'])) {
						$DeferDeadline = [System.DateTime]::Parse($ADTSession.NXT.SetupCfg['AskKillProcesses']['DEFERDEADLINE'])
					}
					if (-not $PSBoundParameters.ContainsKey('AllowDeferCloseProcesses')) {
						[System.Boolean]$hasDeferOption = $DeferTimes -or $DeferDays -or $DeferDeadline
						if (-not $hasDeferOption -and $ContinueType -eq [PSADTNXT.UI.ContinueType]::Abort) {
							Write-ADTLogEntry -Severity Warning -Message 'No defer option is specified, but the continue type is set to [Abort]. Assuming defer option was meant to be enabled.'
							$AllowDeferCloseProcesses = $true
						}
						else {
							$AllowDeferCloseProcesses = $hasDeferOption
						}
					}
				}
			}

			# Return if no processes are defined to close
			if (-not $CloseProcesses) {
				Write-ADTLogEntry -Message 'No processes to close defined. Skipping the installation welcome dialog.'
				return
			}

			# Obtain the running processes that match the CloseProcesses filter.
			# Also track processes that should be opened post-deployment separately based on the ReopenMode of the CloseProcesses definition.
			# TODO: Track https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/issues/1072 for native support of this in PSADT.
			[System.Collections.Generic.List[PSADT.ProcessManagement.RunningProcess]]$runningProcesses = [System.Collections.Generic.List[PSADT.ProcessManagement.RunningProcess]]::new()
			[System.Collections.Generic.List[PSADTNXT.ProcessManagement.NxtClosedProcess]]$appsToReopen = [System.Collections.Generic.List[PSADTNXT.ProcessManagement.NxtClosedProcess]]::new()
			foreach ($definition in $CloseProcesses) {
				Get-ADTRunningProcesses -ProcessObjects $definition.ProcessDefinition -InformationAction SilentlyContinue | & {
					process {
						$runningProcesses.Add($_)
						if ($definition.ReopenMode -ne [PSADTNXT.ProcessManagement.ReopenMode]::None) {
							$appsToReopen.Add(
								[PSADTNXT.ProcessManagement.NxtClosedProcess]::new(
									$_.Username,
									$_.FileName,
									$(if ($definition.ReopenMode -eq [PSADTNXT.ProcessManagement.ReopenMode]::Commandline) { $_.Arguments } else { [System.String]::Empty }),
									$(if ($_.Process.StartInfo -and -not [System.String]::IsNullOrWhiteSpace($_.Process.StartInfo.WorkingDirectory)) { $_.Process.StartInfo.WorkingDirectory } else { $null }),
									[PSADTNXT.Extensions.NxtProcessExtensions]::IsElevated($_.Process)
								)
							)
						}
					}
				}
			}

			# If no running processes are found, we can skip showing the installation welcome dialog.
			if ($runningProcesses.Count -eq 0) {
				Write-ADTLogEntry -Message 'No blocking processes are currently running. Skipping the installation welcome dialog.'
				return
			}

			# For non-interactive deployments, we do not show the installation welcome dialog.
			if ($ADTSession.DeployMode -ne [PSADT.Module.DeployMode]::Interactive -or -not $adtEnvironment.LoggedOnUserSessions) {
				Write-ADTLogEntry -Severity Warning -Message 'Either the deployment is not interactive or no user sessions are available. Skipping the installation welcome and closing the blocking processes.'
				$runningProcesses | Stop-NXTProcess
				return
			}

			# Calculate the defer settings based on defer times, if set.
			# Prepare the defer history splat
			[System.Collections.Hashtable]$deferHistorySplat = @{ DeferRunIntervalLastTime = [System.DateTime]::Now }
			if ($DeferRunInterval) { $deferHistorySplat['DeferRunInterval'] = $DeferRunInterval }
			[PSADT.Module.DeferHistory]$deferHistory = Get-ADTDeferHistory -InformationAction SilentlyContinue
			if ($AllowDeferCloseProcesses -and $DeferTimes) {
				$deferHistorySplat['DeferTimesRemaining'] = if ($deferHistory -and $null -ne $deferHistory.DeferTimesRemaining) { [System.Math]::Min($DeferTimes, $deferHistory.DeferTimesRemaining) } else { $DeferTimes }
				if ($deferHistorySplat['DeferTimesRemaining'] -le 0) {
					Write-ADTLogEntry -Message 'The deployment reached the defer times limit. No further deferrals allowed.'
					$AllowDeferCloseProcesses = $false
					$ContinueType = [PSADTNXT.UI.ContinueType]::Continue
				}
				else {
					$deferHistorySplat['DeferTimesRemaining'] = $deferHistorySplat['DeferTimesRemaining'] - 1
				}
			}
			# Calculate the defer settings based on the defer deadline, if set.
			if ($AllowDeferCloseProcesses -and ($DeferDeadline -or $DeferDays)) {
				# Collect all deadline dates from parameters and history and use the nearest future date as the final deadline.
				[System.Collections.Generic.List[System.DateTime]]$deadlines = [System.Collections.Generic.List[System.DateTime]]::new()
				if ($DeferDeadline) { $deadlines.Add($DeferDeadline) }
				if ($DeferDays) { $deadlines.Add([System.DateTime]::Now.AddDays($DeferDays)) }
				if ($deferHistory -and $deferHistory.DeferDeadline) { $deadlines.Add($deferHistory.DeferDeadline) }

				# Apply the new deadline based on the earliest date, and if the deadline has already passed, disable deferral.
				$deferHistorySplat['DeferDeadline'] = [System.Linq.Enumerable]::Min($deadlines)
				if ($deferHistorySplat['DeferDeadline'] -lt [System.DateTime]::Now) {
					Write-ADTLogEntry -Message "The calculated defer deadline [$DeferDeadline] has already passed. No further deferrals allowed."
					$AllowDeferCloseProcesses = $false
					$ContinueType = [PSADTNXT.UI.ContinueType]::Continue
				}
			}

			# Return the defer exit code if the session has not reached the defer interval yet.
			if ($AllowDeferCloseProcesses -and
				$ADTSession.NXT.SetupCfg['AskKillProcesses']['DEFERINTERVAL'] -and
				$ADTSession.DeployMode -eq [PSADT.Module.DeployMode]::Interactive -and
				$deferHistory -and
				$deferHistory.DeferRunIntervalLastTime -and
				$deferHistory.DeferRunIntervalLastTime.Add([System.TimeSpan]::FromMinutes($ADTSession.NXT.SetupCfg['AskKillProcesses']['DEFERINTERVAL'])) -gt [System.DateTime]::Now
			) {
				Write-ADTLogEntry -Severity Warning -Message "The last deployment attempt [$($deferHistory.DeferRunIntervalLastTime)] is less than the configured defer interval [$($ADTSession.NXT.SetupCfg['AskKillProcesses']['DEFERINTERVAL'])min] ago."
				Close-ADTSession -ExitCode $adtConfig['UI']['DeferExitCode']
			}

			# Test if the user has Do Not Disturb enabled and skip the dialog if so, if the option is enabled.
			if ($AllowDeferCloseProcesses -and $AllowDoNotDisturb -and (Test-ADTUserIsBusy)) {
				Write-ADTLogEntry -Message 'A user is in Do Not Disturb mode while deferral is allowed. Respecting user preference and skipping the installation welcome dialog.'
				Set-ADTDeferHistory @deferHistorySplat
				Close-ADTSession -ExitCode $adtConfig['UI']['DeferExitCode']
			}

			# If no Timeout is specified, and no defer is allowed, we do not show the installation welcome dialog and close the processes directly.
			if ((-not $Timeout -or $Timeout -eq [System.TimeSpan]::Zero) -and -not $AllowDeferCloseProcesses) {
				if ($ContinueType -eq [PSADTNXT.UI.ContinueType]::Continue) {
					Write-ADTLogEntry -Message 'No timeout specified and no deferral is allowed. Closing the blocking processes directly.'
					$runningProcesses | Stop-NXTProcess
					return
				}
				else {
					Write-ADTLogEntry -Message 'No timeout specified and continue type is set to defer. Closing the deployment with defer exit code.'
					Close-ADTSession -ExitCode $adtConfig['UI']['DeferExitCode']
				}
			}

			# The continue type is always continue if no deferral is allowed
			if (-not $AllowDeferCloseProcesses) {
				$ContinueType = [PSADTNXT.UI.ContinueType]::Continue
			}

			# Construct the parameters for the installation welcome dialog
			[System.Collections.Hashtable]$showInstallationWelcome = Remove-ADTHashtableNullOrEmptyValues -Hashtable (
				@{
					Title           = $Title
					PersistPrompt   = [System.Boolean]$PersistPrompt
					CustomText      = [System.Boolean]$CustomText
					MinimizeWindows = [System.Boolean]$MinimizeWindows
					NotTopMost      = [System.Boolean]$NotTopMost
					HideCloseButton = [System.Boolean]$HideCloseButton
					AllowMove       = [System.Boolean]$AllowMove
				} + $(
					if ($legacyUi) {
						@{
							CloseProcesses  = $CloseProcesses.ProcessDefinition | & { process { Remove-ADTHashtableNullOrEmptyValues -Hashtable (ConvertTo-NXTHashtable -InputObject $_) } }
							DeploymentType  = $ADTSession.DeploymentType
							ContinueType    = $ContinueType
							ScriptDirectory = $ADTSession.ScriptDirectory | & { process { ($_ -replace "^$([System.Text.RegularExpressions.Regex]::Escape($ADTSession.NXT.DeployAppScript.Directory.FullName))", '.') } }
						}
					}
					else {
						@{
							CloseProcesses = $CloseProcesses.ProcessDefinition
							PromptToSave   = $true
						}
					}
				)
			)

			# Place the defer dependent parameters
			if ($AllowDeferCloseProcesses) {
				$showInstallationWelcome['AllowDeferCloseProcesses'] = $true

				if ($null -ne $deferHistorySplat['DeferTimesRemaining']) {
					Write-ADTLogEntry -Message "The user can defer the deployment [$DeferTimes] more times."
					$showInstallationWelcome['DeferTimes'] = $deferHistorySplat['DeferTimesRemaining'] + 1
				}
				if ($deferHistorySplat['DeferDeadline']) {
					Write-ADTLogEntry -Message "The user can defer the deployment until [$DeferDeadline]."
					$showInstallationWelcome['DeferDeadline'] = $deferHistorySplat['DeferDeadline']
				}
			}

			# Apply the ContinueType to V4 UI by setting the appropriate countdown
			if ($Timeout -and $Timeout -ne [System.TimeSpan]::Zero) {
				if ($legacyUi) {
					$showInstallationWelcome['Timeout'] = $Timeout
				}
				else {
					if ($ContinueType -eq [PSADTNXT.UI.ContinueType]::Continue -or -not $AllowDeferCloseProcesses) {
						$showInstallationWelcome['ForceCloseProcessesCountdown'] = $Timeout.TotalSeconds
					}
					else {
						$showInstallationWelcome['ForceCountdown'] = $Timeout.TotalSeconds
					}
				}
			}

			# Invoke modern UI path if enabled.
			if (-not $legacyUi) {
				Show-ADTInstallationWelcome @showInstallationWelcome
				# If we continue, the apps have been closed. Add them to the reopen list.
				$ADTSession.NXT.ClosedProcesses.AddRange($appsToReopen)
				return
			}

			# If there are no blocking processes, we do not show the installation welcome dialog.
			Write-ADTLogEntry -Message "Showing the legacy welcome dialog for [$([System.String]::Join(', ', ($runningProcesses.Process.ProcessName | Select-Object -Unique)))]."

			# Start the legacy UI.
			[System.String]$argumentList = ConvertTo-NXTPsBinaryArgument -File "$($MyInvocation.MyCommand.Module.ModuleBase)\Scripts\CustomAppDeployToolkitUi.ps1" -Arguments $showInstallationWelcome -UseLastExitCode
			if ($adtEnvironment.SessionZero -or $adtEnvironment.IsServiceAccount -or ($adtEnvironment.IsAdmin -and -not $adtEnvironment.IsProcessUserInteractive)) {
				Write-ADTLogEntry -Message 'Process is running as system, service or non interactive user. Using session helper to spawn in all sessions.' -DebugMessage
				if ([System.Int32[]]$sessionIds = Get-ADTLoggedOnUser | Select-Object -ExpandProperty 'SessionId') {
					[PSADT.ProcessManagement.ProcessResult]$result = [PSADTNXT.ProcessManagement.NxtSessionHelper]::StartProcessInSessions(
						(Get-ADTPowerShellProcessPath),
						$argumentList,
						$sessionIds,
						[System.TimeSpan]::FromSeconds($adtConfig['UI']['DefaultTimeout'])
					)
				}
				else {
					Write-ADTLogEntry -Severity Warning -Message 'No user is logged in. Assuming continue option.'
					[PSADT.ProcessManagement.ProcessResult]$result = [PSADT.ProcessManagement.ProcessResult]::new([PSADTNXT.UI.LegacyWelcomeWindowCodes]::Continue.value__)
				}
			}
			elseif ($adtEnvironment.IsProcessUserInteractive) {
				Write-ADTLogEntry -Message 'Process is not running in session zero, as service or as non interative user. Assuming we run as user.' -DebugMessage
				[PSADT.ProcessManagement.ProcessResult]$result = Start-ADTProcess -FilePath (Get-ADTPowerShellProcessPath) -ArgumentList $argumentList -WindowStyle Hidden -PassThru `
					-SuccessExitCodes ([System.Enum]::GetValues([PSADTNXT.UI.LegacyWelcomeWindowCodes])).value__ `
					-Timeout ([System.TimeSpan]::FromSeconds($adtConfig['UI']['DefaultTimeout']))
			}
			else {
				Write-ADTLogEntry -Severity Error -Message 'Could not find suitable user to display UI to. Assuming continue option.'
				[PSADT.ProcessManagement.ProcessResult]$result = [PSADT.ProcessManagement.ProcessResult]::new([PSADTNXT.UI.LegacyWelcomeWindowCodes]::Continue.value__)
			}

			# Check if the process returned an unknown error and try to log as much as possible
			if ($result.ExitCode -notin [System.Enum]::GetValues([PSADTNXT.UI.LegacyWelcomeWindowCodes])) {
				[System.Collections.Hashtable]$errorParams = @{
					Exception    = [System.Management.Automation.RuntimeException]::new("The installation welcome dialog exited with an unknown exit code [$($result.ExitCode)].")
					Category     = [System.Management.Automation.ErrorCategory]::InvalidResult
					ErrorId      = 'LegacyWelcomeWindowUnknownExitCode'
					TargetObject = $result
				}
				throw (New-ADTErrorRecord @errorParams)
			}

			[PSADTNXT.UI.LegacyWelcomeWindowCodes]$uiReturnValue = $result.ExitCode
			Write-ADTLogEntry -Message "Installation dialog completed with [$uiReturnValue]."

			# Update the defer time, as the ui might have taken some time to show and interact with
			$deferHistorySplat['DeferRunIntervalLastTime'] = [System.DateTime]::Now

			# Map the exit code to the appropriate action
			switch ($uiReturnValue) {
				([PSADTNXT.UI.LegacyWelcomeWindowCodes]::Continue) {
					Write-ADTLogEntry -Message 'The blocking applications were closed. Continuing the deployment.'
					$ADTSession.NXT.ClosedProcesses.AddRange($appsToReopen)
				}
				([PSADTNXT.UI.LegacyWelcomeWindowCodes]::Close) {
					Write-ADTLogEntry -Message 'The user requested to close all blocking applications.'
					Stop-NXTProcess -ProcessDefinition $CloseProcesses.ProcessDefinition
					$ADTSession.NXT.ClosedProcesses.AddRange($appsToReopen)
				}
				([PSADTNXT.UI.LegacyWelcomeWindowCodes]::Timeout) {
					if ($ContinueType -eq [PSADTNXT.UI.ContinueType]::Abort) {
						Write-ADTLogEntry -Severity Warning -Message 'The installation welcome timed but the user had the option to defer the installation and ContinueType is set to [Abort].'
						Set-ADTDeferHistory @deferHistorySplat
						$ADTSession.NXT.ClosedProcesses.AddRange($appsToReopen)
						Close-ADTSession -ExitCode $adtConfig['UI']['DeferExitCode']
					}
					else {
						Write-ADTLogEntry -Severity Warning -Message 'The installation welcome timed out and deployment is set to continue or the user had no option to defer the installation.'
						Stop-NXTProcess -ProcessDefinition $CloseProcesses.ProcessDefinition
						$ADTSession.NXT.ClosedProcesses.AddRange($appsToReopen)
					}
				}
				([PSADTNXT.UI.LegacyWelcomeWindowCodes]::Defer) {
					Write-ADTLogEntry -Message 'The installation was deferred by the user.'
					Set-ADTDeferHistory @deferHistorySplat
					Close-ADTSession -ExitCode $adtConfig['UI']['DeferExitCode']
				}
			}
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		if ($BlockExecution -and $CloseProcesses) {
			Block-ADTAppExecution -Processes $CloseProcesses.ProcessDefinition
		}

		# Show the progress bar if enabled for the duration of the deployment
		if ($ADTSession.NXT.SetupCfg['Options']['SHOWPROGRESS'] -eq '1') {
			Show-ADTInstallationProgress -NotTopMost:($ADTSession.NXT.SetupCfg['AskKillProcesses']['TOPMOSTWINDOW'] -ne '2') -AllowMove
		}
		elseif (-not $NoBalloonTip -and $ADTSession.NXT.SetupCfg['Options']['SHOWBALLOONNOTIFICATIONS'] -in @('1', '2')) {
			Show-ADTBalloonTip -BalloonTipIcon Info -BalloonTipText $adtStrings['BalloonTip']['Start'][$ADTSession.DeploymentType.ToString()]
		}

		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
