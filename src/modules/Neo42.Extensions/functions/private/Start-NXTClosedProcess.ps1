function Start-NXTClosedProcess {
	<#
	.SYNOPSIS
	Helper function to reopen closed processes that were previously closed by the Show-NXTInstallationWelcome.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Internal function, no ShouldProcess required')]
	[CmdletBinding()]
	param (
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession)
	)
	try {
		$ADTSession.NXT.ClosedProcesses | & {
			process {
				try {
					[System.Collections.Hashtable]$startParams = @{
						FilePath            = $_.FilePath
						Username            = $_.Username
						UseLinkedAdminToken = $_.AsAdmin
					}
					if (-not [System.String]::IsNullOrWhiteSpace($_.Arguments)) {
						$startParams['SecureArgumentList'] = $_.Arguments
					}
					if ($_.WorkingDirectory) {
						$startParams['WorkingDirectory'] = $_.WorkingDirectory.FullName
					}

					Start-ADTProcessAsUser -NoWait @startParams
				}
				catch {
					Write-ADTLogEntry -Severity Error -Message "Failed to reopen process [$($startParams.FilePath)] for user [$($startParams.UserName)]. Error: $($_.Exception.Message)"
				}
			}
		}
	}
	catch {
		Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
	}
}
