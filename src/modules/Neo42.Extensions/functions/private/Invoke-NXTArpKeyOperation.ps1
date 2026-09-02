function Invoke-NXTArpKeyOperation {
	<#
	.SYNOPSIS
	Post deployment tasks for NXT deployment sessions.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Purge', Justification = 'Parameter is used in script block.')]
	param (
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession),
		[System.Management.Automation.SwitchParameter]
		$Purge
	)

	try {
		[System.Collections.Generic.List[PSADTNXT.Application.NxtApplicationCriteria]]$criteria = [System.Collections.Generic.List[PSADTNXT.Application.NxtApplicationCriteria]]::new()
		$ADTSession.NXT.ManagedApplications | & { process { if ($_.Store -eq [PSADTNXT.Application.ApplicationStore]::ARP) { $criteria.Add($_) } } }
		if ($ADTSession.NXT.Detection.Criteria -and $ADTSession.NXT.Detection.Criteria.Store -eq [PSADTNXT.Application.ApplicationStore]::ARP) {
			$criteria.Add($ADTSession.NXT.Detection.Criteria)
		}

		$criteria | & {
			process {
				Get-NXTApplication -Criteria $_ | & {
					process {
						if ([Microsoft.Win32.RegistryKey]$key = [PSADTNXT.Shell.NxtPowerShell]::ToRegistryKeyFromPSProviderPath($_.PSPath, $true)) {
							if ($Purge) {
								Write-ADTLogEntry -Message "Unhiding ARP application [$($_.DisplayName)] with key [$($_.PSChildName)]."
								$key.DeleteValue('SystemComponent', $false)
							}
							else {
								Write-ADTLogEntry -Message "Hiding ARP application [$($_.DisplayName)] with key [$($_.PSChildName)]"
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
