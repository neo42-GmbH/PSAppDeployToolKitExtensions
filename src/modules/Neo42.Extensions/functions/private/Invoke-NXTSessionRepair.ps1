function Invoke-NXTSessionRepair {
	<#
	.SYNOPSIS
	The logic to translate the session object into a repair operation.
	#>
	[OutputType([PSADT.ProcessManagement.ProcessResult])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0)]
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession)
	)
	try {
		[PSADT.ProcessManagement.ProcessResult]$result = $null
		switch ($ADTSession.NXT.Install.Method) {
			([PSADTNXT.Deployment.DeploymentMethod]::MSI) {
				if (-not $ADTSession.NXT.Detection.Application) {
					[System.Collections.Hashtable]$errorParams = @{
						Exception = [System.Management.Automation.ItemNotFoundException]::new('The target application was not found for repair operation.')
						Category  = [System.Management.Automation.ErrorCategory]::InvalidResult
						ErrorId   = 'ApplicationNotFoundForRepair'
					}
					throw (New-ADTErrorRecord @errorParams)
				}
				$result = Start-ADTMsiProcess -Action Repair -RepairMode Repair -RepairFromSource -PassThru -ProductCode $ADTSession.NXT.Detection.Application.PSChildName
			}
			default {
				[System.Collections.Hashtable]$errorParams = @{
					Exception = [System.NotSupportedException]::new("The installation method [$($ADTSession.NXT.Install.Method)] is not supported for repair operations.")
					Category  = [System.Management.Automation.ErrorCategory]::NotImplemented
					ErrorId   = 'RepairMethodNotSupported'
				}
				throw (New-ADTErrorRecord @errorParams)
			}
		}
		Wait-NXTDeploymentAwaiter -Awaiter $ADTSession.NXT.Install.Awaiters
		return $result
	}
	catch {
		Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
	}
}
