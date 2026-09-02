function Wait-NXTDeploymentAwaiter {
	<#
	.SYNOPSIS
	Waits for specified process and registry key conditions during installation or uninstallation.
	.DESCRIPTION
	This is a helper function for the (Un)Install-NXTApplication cmdlets.
	It monitors and waits for specified process and registry key conditions to be met.
	The cmdlet supports setting a timeout and defining conditions with operators.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory)]
		[AllowEmptyCollection()]
		[AllowNull()]
		[PSADTNXT.Deployment.INxtAwaiter[]]
		$Awaiter
	)

	try {
		[System.DateTime]$startTime = [System.DateTime]::Now

		if ($Awaiter) {
			Write-ADTLogEntry -Message "Waiting for [$($Awaiter.Count)] awaiter(s) to complete..."
		}
		else {
			Write-ADTLogEntry -Message 'No awaiters specified. Skipping wait operation.' -DebugMessage
			return
		}

		while ($Awaiter.Count -gt 0) {
			[System.Collections.Generic.List[PSADTNXT.Deployment.INxtAwaiter]]$stillRunning = [System.Collections.Generic.List[PSADTNXT.Deployment.INxtAwaiter]]::new()
			foreach ($item in $Awaiter) {
				if ($startTime.Add($item.Timeout) -le [System.DateTime]::Now) {
					Write-ADTLogEntry -Severity Warning -Message "An awaiter timeout [$($item.Timeout)] was reached for [$($item.GetType().Name)]."
				}
				elseif ($item.Evaluate()) {
					Write-ADTLogEntry -Message "Awaiter [$($item.GetType().Name)] condition met." -DebugMessage
				}
				else {
					$stillRunning.Add($item)
				}
			}
			$Awaiter = $stillRunning
			Start-Sleep -Milliseconds 250
		}

		Write-ADTLogEntry -Severity Success -Message 'All awaiter conditions have been met.'
	}
	catch {
		Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
	}
}
