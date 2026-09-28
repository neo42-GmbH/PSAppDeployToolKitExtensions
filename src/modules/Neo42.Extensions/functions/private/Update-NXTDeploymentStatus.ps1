function Update-NXTDeploymentStatus {
	<#
	.SYNOPSIS
	Update the deployment exit code according to code parameters.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This is a private function')]
	[OutputType([System.Boolean])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory)]
		[System.Int32]
		$ExitCode,
		[AllowNull()]
		[System.Int32[]]
		$SuccessExitCodes,
		[AllowNull()]
		[System.Int32[]]
		$RebootExitCodes,
		[System.Management.Automation.SwitchParameter]
		$IgnoreExitCodes,
		[ValidateNotNull()]
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession)
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Collections.Hashtable]$adtConfig = Get-ADTConfig
	}
	process {
		try {
			if ($IgnoreExitCodes) { return }

			# Upgrade to TrySetExitCode in PSADT 4.2
			[PSADT.Module.DeploymentStatus]$resolvedStatus = if ($RebootExitCodes -and $ExitCode -in $RebootExitCodes) {
				[PSADT.Module.DeploymentStatus]::RestartRequired
			}
			elseif (($SuccessExitCodes -and $ExitCode -in $SuccessExitCodes) -or (-not $SuccessExitCodes -and $ExitCode -eq 0)) {
				[PSADT.Module.DeploymentStatus]::Complete
			}
			elseif ($ExitCode -eq $adtConfig['UI']['DefaultExitCode']) {
				[PSADT.Module.DeploymentStatus]::FastRetry
			}
			else {
				[PSADT.Module.DeploymentStatus]::Error
			}

			if ($ADTSession.GetDeploymentStatus() -lt $resolvedStatus) {
				Write-ADTLogEntry -Message "Deployment status updated from [$($ADTSession.GetDeploymentStatus())] to [$resolvedStatus]."
				$ADTSession.SetExitCode($ExitCode)
			}
			else {
				Write-ADTLogEntry -Message 'Deployment status not updated, as it has not changed.'
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
