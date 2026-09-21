function Wait-NXTServiceState {
	<#
	.SYNOPSIS
	Monitors the status of a specified service within a set timeout period.
	.DESCRIPTION
	This function checks for the running or stopped status of a service.
	The function continuously checks for the service's status until it changes or the timeout is reached.
	.INPUTS
	System.String - The name of the service to monitor.
	.OUTPUTS
	System.Boolean - Returns true if the service status changes within the timeout period, otherwise false.
	System.ServiceProcess.ServiceController - Returns the service controller if PassThru is specified
	With the -IsNotRunning switch, the test will be inverted.
	.PARAMETER Name
	The name of the service to monitor.
	.PARAMETER Timeout
	The maximum time to wait for the service status to change.
	.PARAMETER TestInterval
	The interval at which to check for the service's status change.
	.PARAMETER PassThru
	Instead of returning a boolean, return the object.
	.PARAMETER IsNotRunning
	Instead of checking for the running status of the service, check for its stopped status.
	.PARAMETER WaitForService
	Instead of throwing an error if the service is not found, wait for it to be available and then check its status.
	.EXAMPLE
	Wait-NXTServiceState -Name "Spooler" -Timeout '00:02:00'

	Monitors for the 'Spooler' service to change its status and waits up to 120 seconds for it to change.
	.EXAMPLE
	Wait-NXTServiceState -Name "Spooler" -Timeout '00:02:00' -IsNotRunning

	This example monitors for the 'Spooler' service and waits up to 120 seconds for it to stop.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleTypes', '', Justification = 'A loaded module imports the required types.')]
	[OutputType([System.Boolean], [System.ServiceProcess.ServiceController])]
	[CmdletBinding(DefaultParameterSetName = 'Name')]
	param (
		[Parameter(Position = 0, ParameterSetName = 'Name', Mandatory)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Name,
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$Timeout = '00:01:00',
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$TestInterval = '00:00:01.000',
		[System.Management.Automation.SwitchParameter]
		$PassThru,
		[System.Management.Automation.SwitchParameter]
		$IsNotRunning,
		[System.Management.Automation.SwitchParameter]
		$WaitForService
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if ($IsNotRunning) {
				[System.Management.Automation.ScriptBlock]$waitWhile = { $service.Status -eq 'Running' }
				[System.String]$successMessage = "The service [$Name] was paused or stopped within the specified timeout of [$Timeout]."
				[System.String]$failureMessage = "The service [$Name] is still running after the specified timeout of [$Timeout]."
			}
			else {
				[System.Management.Automation.ScriptBlock]$waitWhile = { -not ($service.Status -eq 'Running') }
				[System.String]$successMessage = "The service [$Name] was running within the specified timeout of [$Timeout]."
				[System.String]$failureMessage = "The service [$Name] is still not running after the specified timeout of [$Timeout]."
			}
			[System.Boolean]$result = $true
			[System.String]$severity = 'Info'
			[System.String]$message = $successMessage
			[System.DateTime]$endTime = [System.DateTime]::Now.Add($Timeout)
			if ($WaitForService) {
				while (-not $service) {
					if ([System.DateTime]::Now -ge $endTime) {
						$result = $false
						$severity = 'Warning'
						$message = "The service [$Name] was not found within the specified timeout of [$Timeout]."
						break
					}
					Start-Sleep -Milliseconds $TestInterval.TotalMilliseconds
					[System.ServiceProcess.ServiceController]$service = Get-Service -Name $Name -ErrorAction SilentlyContinue
				}
			}
			else {
				[System.ServiceProcess.ServiceController]$service = Get-Service -Name $Name -ErrorAction Stop
			}
			while ($waitWhile.Invoke()) {
				if ([System.DateTime]::Now -ge $endTime) {
					$result = $false
					$severity = 'Warning'
					$message = $failureMessage
					break
				}
				Start-Sleep -Milliseconds $TestInterval.TotalMilliseconds
			}
			Write-ADTLogEntry -Message $message -Severity $severity -DebugMessage
			if ($PassThru) {
				if ($IsNotRunning) {
					return (if ($result) { $null } else { $service })
				}
				else {
					return (if ($result) { $service } else { $null })
				}
			}
			else {
				return $result
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
