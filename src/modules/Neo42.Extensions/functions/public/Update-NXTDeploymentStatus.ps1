function Update-NXTDeploymentStatus {
	<#
	.SYNOPSIS
	Update the deployment exit code according to parameters.
	.DESCRIPTION
	Update the deployment exit code according to parameters.
	An update is only applied if the provided code will either keep or degrade the deployment status to a higher value.
	Order: Complete > Restart > FastRetry > Error
	If required, the input code will be translated into a maching session exit code.
	.PARAMETER ExitCode
	The exit code to update the session with.
	.PARAMETER SuccessExitCodes
	Codes that would be considered successful.
	.PARAMETER RebootExitCodes
	Codes that would indicate a reboot is required.
	.PARAMETER ADTSession
	The current deployment session to update the status for.
	.NOTES
	This function is born to the missing implementation of PSADT 4.1.8.
	The behaviour of this function is baked into PSADT 4.2+ functions by default.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'The update is non-distructive.')]
	[CmdletBinding()]
	param (
		[ValidateNotNull()]
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession),
		[Parameter(Position = 0, Mandatory)]
		[System.Int32]
		$ExitCode,
		[AllowNull()]
		[System.Int32[]]
		$SuccessExitCodes,
		[AllowNull()]
		[System.Int32[]]
		$RebootExitCodes
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Collections.Hashtable]$adtConfig = Get-ADTConfig
	}
	process {
		try {
			# Upgrade to TrySetExitCode in PSADT 4.2
			[PSADT.Module.DeploymentStatus]$resolvedStatus, [System.Int32]$resolvedExitCode = if ($RebootExitCodes -and $ExitCode -in $RebootExitCodes) {
				[PSADT.Module.DeploymentStatus]::RestartRequired
				if ($ExitCode -in $ADTSession.AppRebootExitCodes) {
					$ExitCode
				}
				elseif (3010 -in $ADTSession.AppRebootExitCodes) {
					Write-ADTLogEntry -Severity Warning -Message "Reboot exit code [$ExitCode] was not a session reboot code so it was translated to [3010]."
					3010
				}
				else {
					Write-ADTLogEntry -Severity Warning -Message "Reboot exit code [$ExitCode] was not a session reboot code so it was translated to [$($ADTSession.AppRebootExitCodes[0])]."
					$ADTSession.AppRebootExitCodes[0]
				}
			}
			elseif (($SuccessExitCodes -and $ExitCode -in $SuccessExitCodes) -or (-not $SuccessExitCodes -and $ExitCode -eq 0)) {
				[PSADT.Module.DeploymentStatus]::Complete
				if ($ExitCode -in $ADTSession.AppSuccessExitCodes) {
					$ExitCode
				}
				elseif (0 -in $ADTSession.AppSuccessExitCodes) {
					Write-ADTLogEntry -Severity Warning -Message "Success exit code [$ExitCode] was not a session success code so it was translated to [0]."
					0
				}
				else {
					Write-ADTLogEntry -Severity Warning -Message "Success exit code [$ExitCode] was not a session success code so it was translated to [$($ADTSession.AppSuccessExitCodes[0])]."
					$ADTSession.AppSuccessExitCodes[0]
				}
			}
			elseif ($ExitCode -eq $adtConfig['UI']['DefaultExitCode']) {
				[PSADT.Module.DeploymentStatus]::FastRetry
				$adtConfig['UI']['DefaultExitCode']
			}
			else {
				[PSADT.Module.DeploymentStatus]::Error
				if ($ExitCode -notin $ADTSession.AppSuccessExitCodes -and $ExitCode -notin $ADTSession.AppRebootExitCodes) {
					$ExitCode
				}
				elseif (1 -notin $ADTSession.AppSuccessExitCodes -and 1 -notin $ADTSession.AppRebootExitCodes) {
					Write-ADTLogEntry -Severity Warning -Message "Error exit code [$ExitCode] was not a session failure code so it was translated to [1]."
					1
				}
				else {
					Write-ADTLogEntry -Severity Warning -Message "Error exit code [$ExitCode] was not a session failure code so it was translated to [$([System.Int32]::MinValue)]."
					[System.Int32]::MinValue
				}
			}

			if ($ADTSession.GetDeploymentStatus() -le $resolvedStatus) {
				if ($ADTSession.GetDeploymentStatus() -ne $resolvedStatus) {
					Write-ADTLogEntry -Message "Deployment status updated from [$($ADTSession.GetDeploymentStatus())] to [$resolvedStatus]."
				}
				$ADTSession.SetExitCode($resolvedExitCode)
			}
			else {
				Write-ADTLogEntry -Message "The exit code was not applied to the session as it would have upgraded the current status [$($ADTSession.GetDeploymentStatus())] to [$resolvedStatus]."
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
