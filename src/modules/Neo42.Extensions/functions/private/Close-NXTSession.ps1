function Close-NXTSession {
	<#
	.SYNOPSIS
	This function is invoked at the end of every Close-ADTSession call.
	It will handle all post installation tasks and cleanup operations.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleTypes', '', Justification = 'The offending type is imported by the PSADT module.')]
	[CmdletBinding()]
	param ()

	# Obtain the current deployment session and configuration.
	[PSADT.Module.DeploymentSession]$adtSession = Get-ADTSession
	[System.Collections.Hashtable]$adtStrings = Get-ADTStringTable
	[System.Collections.Hashtable]$adtConfig = Get-ADTConfig

	# Only continue if the current session is a neo42 deployment session
	if ($adtSession -isnot [PSADTNXT.Foundation.NxtDeploymentSession] -or -not $adtConfig.ContainsKey('NXT')) { return }
	Write-ADTLogEntry -Message "Running [Neo42.Extensions] close actions for deployment status [$($adtSession.GetDeploymentStatus())]."

	# Restart apps that were closed during the deployment
	if (-not $adtSession.NXT.DeploymentType.IsUninstall -and
		$adtSession.GetDeploymentStatus() -eq [PSADT.Module.DeploymentStatus]::Complete -and
		$adtSession.NXT.SetupCfg['AskKillProcesses']['OPENCLOSEDAPPS'] -eq '1' -and
		$adtSession.NXT.ClosedProcesses
	) {
		Write-ADTLogEntry -Message 'Reopening previously closed processes as configured in the package.'
		Start-NXTClosedProcess -ADTSession $adtSession
	}

	# Don't run any actions. FastRetry indicates that the deployment has been deferred or should continue at a later time.
	if ($adtSession.GetDeploymentStatus() -eq [PSADT.Module.DeploymentStatus]::FastRetry) {
		Write-ADTLogEntry -Message 'Deployment status is FastRetry. Skipping close actions.'
		return
	}

	# Apply reboot settings (for machine part deployments only, user part deployments should not trigger a reboot)
	if ($adtSession.NXT.DeploymentType.IsMachinePart -and $adtSession.GetDeploymentStatus() -ne [PSADT.Module.DeploymentStatus]::Error) {
		[PSADTNXT.Deployment.RebootAction]$rebootAction = if ($adtSession.NXT.DeploymentType.IsInstall) { $adtSession.NXT.Install.Reboot } else { $adtSession.NXT.Uninstall.Reboot }
		if ($rebootAction -eq [PSADTNXT.Deployment.RebootAction]::Always) {
			Write-ADTLogEntry -Message 'Forcing a reboot exit code as configured in the package.'
			$adtSession.SetExitCode(3010)
		}
		elseif ($rebootAction -eq [PSADTNXT.Deployment.RebootAction]::Never -and
			$adtSession.GetDeploymentStatus() -eq [PSADT.Module.DeploymentStatus]::RestartRequired
		) {
			Write-ADTLogEntry -Message "Ignoring the current reboot exit code [$($adtSession.GetExitCode())] as configured in the package."
			$adtSession.SetExitCode(0)
		}
	}

	# Only explicitly show the progress balloon it will not be shown by Close-ADTInstallationProgress anyway
	if ($adtSession.NXT.SetupCfg['Options']['SHOWPROGRESS'] -ne '1' -and
		$adtSession.NXT.SetupCfg['Options']['SHOWBALLOONNOTIFICATIONS'] -in @('1', '2')
	) {
		[System.Windows.Forms.ToolTipIcon]$icon = switch ($adtSession.GetDeploymentStatus()) {
			([PSADT.Module.DeploymentStatus]::FastRetry) { [System.Windows.Forms.ToolTipIcon]::Warning }
			([PSADT.Module.DeploymentStatus]::Error) { [System.Windows.Forms.ToolTipIcon]::Error }
			default { [System.Windows.Forms.ToolTipIcon]::Info }
		}
		Show-ADTBalloonTip -BalloonTipIcon $icon -BalloonTipText $adtStrings['BalloonTip'][$adtSession.GetDeploymentStatus().ToString()][$adtSession.DeploymentType.ToString()]
	}

	# Show the restart prompt if configured
	if ($adtSession.NXT.SetupCfg['Options']['SHOWRESTARTPROMPT'] -eq '1' -and
		$adtSession.GetDeploymentStatus() -eq [PSADT.Module.DeploymentStatus]::RestartRequired
	) {
		Show-ADTInstallationRestartPrompt -NoCountdown -AllowMove -NotTopMost:($adtSession.NXT.SetupCfg['AskKillProcesses']['TOPMOSTWINDOW'] -ne '2')
	}

	# Show the error message to the user if activated
	if ($adtSession.GetDeploymentStatus() -eq [PSADT.Module.DeploymentStatus]::Error -and
		$adtSession.NXT.SetupCfg['Options']['SHOWPROGRESS'] -eq '1'
	) {
		$null = Show-ADTInstallationPrompt -ButtonRightText OK -NoWait `
			-NotTopMost:($adtSession.NXT.SetupCfg['AskKillProcesses']['TOPMOSTWINDOW'] -ne '2') `
			-Title $adtStrings['BalloonTip']['Error'][$adtSession.DeploymentType.ToString()] `
			-Message $adtStrings['NXT']['ErrorMessage'][$adtSession.DeploymentType.ToString()]
	}
}
