function Wait-NXTSystemLoadIsLow {
	<#
	.SYNOPSIS
	Monitors the system load and waits for it to be low within a specified timeout.
	.DESCRIPTION
	This function checks for a low system load condition.
	The function continuously checks the system load until it meets the criteria or the timeout is reached.
	.INPUTS
	None
	.OUTPUTS
	System.Boolean - Returns $true if the system load condition is met within the timeout period; otherwise, returns $false.
	With the -IsHigh switch, the test will be inverted.
	.PARAMETER CpuThreshold
	The CPU usage threshold to consider the load as high.
	.PARAMETER RamThreshold
	The RAM usage threshold to consider the load as high.
	.PARAMETER Timeout
	The maximum time to wait for the system load condition to be as desired.
	.PARAMETER Interval
	The interval at which to check for the system load condition.
	.PARAMETER IsHigh
	Instead of checking for the system load to be low, check for it to be high.
	.EXAMPLE
	Wait-NXTSystemLoadIsLow -Timeout '00:05:00'

	Monitors for the system load and waits up to 5 minutes for it to be low.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'The values are used in the script block.')]
	[OutputType([System.Boolean])]
	[CmdletBinding()]
	param (
		[Alias('Cpu')]
		[ValidateRange(0, 100)]
		[System.Int32]
		$CpuThreshold = 85,
		[Alias('Ram')]
		[ValidateRange(0, 100)]
		[System.Int32]
		$RamThreshold = 85,
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$Timeout = '00:05:00',
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$Interval = '00:00:01.000',
		[System.Management.Automation.SwitchParameter]
		$IsHigh
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[System.Management.Automation.ScriptBlock]$checkSystemLoad = {
				[System.Int32]$samples = 3
				[System.Int32]$interval = 10
				[System.Collections.Generic.List[System.Double]]$cpu = @()
				[System.Collections.Generic.List[System.Double]]$ram = @()
				for ($i = 0; $i -lt $samples; $i++) {
					$processor = Get-CimInstance Win32_Processor -Property LoadPercentage
					$cpu.Add($processor.LoadPercentage)
					$os = Get-CimInstance Win32_OperatingSystem -Property FreePhysicalMemory, TotalVisibleMemorySize
					$ram.Add(100 * (1 - $os.FreePhysicalMemory / $os.TotalVisibleMemorySize))
					if ($i -lt ($samples - 1)) { Start-Sleep -Seconds $interval }
				}
				[System.Boolean]$cpuResult = (($cpu | Measure-Object -Average).Average -ge $CpuThreshold)
				[System.Boolean]$ramResult = (($ram | Measure-Object -Average).Average -ge $RamThreshold)
				[pscustomobject]@{
					HighCPU  = $cpuResult
					HighRAM  = $ramResult
					HighLoad = $cpuResult -or $ramResult
				}
			}
			if ($IsHigh) {
				[System.Management.Automation.ScriptBlock]$waitWhile = { -not ($checkSystemLoad.Invoke().HighLoad) }
				[System.String]$successMessage = "The system load is high within the specified timeout of [$Timeout]."
				[System.String]$failureMessage = "The system load is not high after the specified timeout of [$Timeout]."
			}
			else {
				[System.Management.Automation.ScriptBlock]$waitWhile = { $checkSystemLoad.Invoke().HighLoad }
				[System.String]$successMessage = "The system load is low within the specified timeout of [$Timeout]."
				[System.String]$failureMessage = "The system load is not low after the specified timeout of [$Timeout]."
			}
			[System.Boolean]$result = $true
			[System.String]$severity = 'Info'
			[System.String]$message = $successMessage
			[System.DateTime]$endTime = [System.DateTime]::Now.Add($Timeout)
			while ($waitWhile.Invoke()) {
				if ([System.DateTime]::Now -ge $endTime) {
					$result = $false
					$severity = 'Warning'
					$message = $failureMessage
					break
				}
				Start-Sleep -Milliseconds $Interval.TotalMilliseconds
			}
			Write-ADTLogEntry -Message $message -Severity $severity -DebugMessage
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
