function Invoke-NXTArpKeyOperation {
	<#
	.SYNOPSIS
	Post deployment tasks for NXT deployment sessions.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Purge', Justification = 'Parameter is used in script block.')]
	param (
		[ValidateNotNull()]
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession),
		[System.Management.Automation.SwitchParameter]
		$Purge
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Management.Automation.ScriptBlock]$isArp = { $args[0] -in @([PSADTNXT.Application.ApplicationStore]::ARP, [PSADTNXT.Application.ApplicationStore]::ARP32, [PSADTNXT.Application.ApplicationStore]::ARP64) }
	}
	process {
		try {
			[System.Collections.Generic.List[PSADTNXT.Application.NxtApplicationCriteria]]$criteria = [System.Collections.Generic.List[PSADTNXT.Application.NxtApplicationCriteria]]::new()
			$ADTSession.NXT.ManagedApplications | & { process { if ($isArp.Invoke($_.Store)) { $criteria.Add($_) } } }
			if ($ADTSession.NXT.Detection.Enabled -and
				$ADTSession.NXT.Detection.Hide -and
				$ADTSession.NXT.Detection.Criteria -and
				($isArp.Invoke($ADTSession.NXT.Detection.Criteria.Store) )
			) {
				$criteria.Add($ADTSession.NXT.Detection.Criteria)
			}

			$criteria | & {
				process {
					Get-NXTApplication -Criteria $_ | & {
						process {
							if ([Microsoft.Win32.RegistryKey]$key = [PSADTNXT.Shell.NxtPowerShell]::ToRegistryKeyFromPSProviderPath($_.PSPath, $true)) {
								if ($Purge) {
									Write-ADTLogEntry -Message "Unhiding [$_]."
									$key.DeleteValue('SystemComponent', $false)
								}
								else {
									Write-ADTLogEntry -Message "Hiding [$_]."
									$key.SetValue('SystemComponent', 1, [Microsoft.Win32.RegistryValueKind]::DWord)
								}
								$key.Close()
							}
						}
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
