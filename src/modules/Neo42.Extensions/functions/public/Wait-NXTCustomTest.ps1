function Wait-NXTCustomTest {
	<#
	.SYNOPSIS
	Checks for the success of a custom test within a specified timeout and consistency period.
	.DESCRIPTION
	This function checks for the success of a custom test defined in a script block.
	It waits for the test to pass within a specified timeout and then checks for consistency over a defined period to ensure that the desired state remains stable.
	.INPUTS
	System.Management.Automation.ScriptBlock - The script block containing the custom test to be executed.
	.OUTPUTS
	System.Boolean - Returns true if the custom test passes within the specified timeout, otherwise returns false.
	.PARAMETER ScriptBlock
	A script block that contains the custom test to be executed.
	.PARAMETER Timeout
	The maximum time to wait for the test result to be successful.
	.PARAMETER Interval
	The interval at which to check for the test result.
	.PARAMETER ConsistencyTestTime
	The time to wait after the test succeeds to ensure that the desired state remains consistent.
	.EXAMPLE
	Wait-NXTCustomTest ScriptBlock { Get-ADTWindowTitle -WindowTitle 'Microsoft Word' } -Timeout '00:05:00' -Interval '00:00:05' -consistencyTestTime '00:00:10.000'

	Monitors whether the Microsoft Word window is open and waits up to 5 minutes with checks every 5 seconds.
	Once the test passes, it will then check for 10 seconds to ensure that the window remains open to ensure that no other process closes it.
	.EXAMPLE
	Wait-NXTCustomTest ScriptBlock { Test-ADTNetworkConnection -InterfaceType 'eth0.10' } -Timeout '00:10:00' -Interval '00:00:05' -consistencyTestTime '00:01:00.000'

	Monitors whether the network adapter 'eth0.10' is up and waits up to 10 minutes with checks every 5 seconds.
	Once the test passes, it will then check for 60 seconds to ensure that the network adapter remains up to ensure that no other process brings it down.
	.EXAMPLE
	Wait-NXTCustomTest ScriptBlock { -not Test-ADTUserIsBusy } -Timeout '00:30:00' -Interval '00:00:05' -consistencyTestTime '00:01:00.000'

	Monitors whether the user is busy and waits up to 30 minutes with checks every 5 seconds until the user is not busy.
	Once the test passes, it will then check for 60 seconds to ensure that the user remains not busy to get a timespan to start actions without disturbing the user.
	.NOTE
	Similar to Invoke-ADTCommandWithRetries from the PowerShell App Deployment Toolkit, but with a more generic approach to allow for any custom test to be executed and monitored.
	#>
	[OutputType([System.Boolean])]
	[CmdletBinding(DefaultParameterSetName = 'ScriptBlock')]
	param (
		[Parameter(Position = 0, ParameterSetName = 'ScriptBlock', Mandatory)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.ScriptBlock]
		$ScriptBlock,
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$Timeout = '00:01:00',
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$Interval = '00:00:01.000',
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$ConsistencyTestTime = '00:00:00'
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[System.String]$successMessage = "The specified custom test passed within the specified timeout of [$Timeout]."
			[System.String]$failureMessage = "The specified custom test failed within the specified timeout of [$Timeout]."
			[System.String]$consistencySuccessMessage = "The specified custom test remained stable for the specified consistency timeout of [$ConsistencyTestTime]."
			[System.String]$consistencyFailureMessage = "The specified custom test did not remain stable for the specified consistency timeout of [$ConsistencyTestTime]."
			[System.Boolean]$result = $true
			[System.String]$severity = 'Info'
			[System.String]$message = $successMessage
			[System.DateTime]$endTime = [System.DateTime]::Now.Add($Timeout)
			while (-not $ScriptBlock.Invoke()) {
				if ([System.DateTime]::Now -ge $endTime) {
					$result = $false
					$message = $failureMessage
					$severity = 'Warning'
					break
				}
				Start-Sleep -Milliseconds $Interval.TotalMilliseconds
			}
			Write-ADTLogEntry -Message $message -Severity $severity -DebugMessage
			if ($result -and ($ConsistencyTestTime -gt [System.TimeSpan]::Zero)) {
				[System.String]$severity = 'Info'
				[System.String]$message = $consistencySuccessMessage
				[System.DateTime]$consistencyEndTime = [System.DateTime]::Now.Add($ConsistencyTestTime)
				while ([System.DateTime]::Now -lt $consistencyEndTime) {
					if (-not $ScriptBlock.Invoke()) {
						$result = $false
						$severity = 'Warning'
						$message = $consistencyFailureMessage
						break
					}
					Start-Sleep -Milliseconds $Interval.TotalMilliseconds
				}
				Write-ADTLogEntry -Message $message -Severity $severity -DebugMessage
			}
			return $result
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
