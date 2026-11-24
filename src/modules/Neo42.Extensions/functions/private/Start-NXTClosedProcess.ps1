function Start-NXTClosedProcess {
	<#
	.SYNOPSIS
	Helper function to reopen closed processes that were previously closed by the Show-NXTInstallationWelcome.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Internal function, no ShouldProcess required')]
	[CmdletBinding()]
	param (
		[ValidateNotNull()]
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession)
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			$ADTSession.NXT.ClosedProcesses | & {
				process {
					try {
						[System.Collections.Hashtable]$startParams = @{
							FilePath = $_.FilePath
							Username = $_.Username
						}
						if ($_.AsAdmin) {
							$startParams['UseHighestAvailableToken'] = $true
						}
						if (-not [System.String]::IsNullOrWhiteSpace($_.Arguments)) {
							$startParams['SecureArgumentList'] = $true
							$startParams['ArgumentList'] = $_.Arguments
						}
						if ($_.WorkingDirectory) {
							$startParams['WorkingDirectory'] = $_.WorkingDirectory.FullName
						}

						[PSADT.ProcessManagement.ProcessHandle]$processHandle = Start-ADTProcessAsUser -NoWait -PassThru @startParams

						# UseHighestAvailableToken silently falls back to the user's regular token if no linked admin token is available.
						# Verify the outcome so a relaunch without elevation is traceable in the log.
						if ($_.AsAdmin) {
							try {
								if ([PSADTNXT.Extensions.NxtProcessExtensions]::IsElevated($processHandle.Process)) {
									Write-ADTLogEntry -Message "Reopened process [$($startParams.FilePath)] for user [$($startParams.Username)] with elevated rights." -DebugMessage
								}
								else {
									Write-ADTLogEntry -Severity Warning -Message "Process [$($startParams.FilePath)] was elevated before it was closed, but was reopened without elevation for user [$($startParams.Username)] as no administrative token was available."
								}
							}
							catch {
								Write-ADTLogEntry -Message "Could not verify the elevation state of the reopened process [$($startParams.FilePath)]. It might have exited already. Error: $($_.Exception.Message)" -DebugMessage
							}
						}
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
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
