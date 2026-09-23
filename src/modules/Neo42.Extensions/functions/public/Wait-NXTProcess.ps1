function Wait-NXTProcess {
	<#
	.SYNOPSIS
	Monitors the startup of a specified process within a set timeout period.
	.DESCRIPTION
	This function checks for the startup of a process.
	The function continuously checks for the process's presence until it starts or stops or the timeout is reached.
	.INPUTS
	System.String - The name of the process to monitor.

	System.Int32 - The process ID to monitor.

	System.Diagnostics.Process - The process to monitor.

	Microsoft.Management.Infrastructure.CimInstance - The Win32_Process cim instance to monitor.

	PSADT.ProcessManagement.ProcessDefinition - The process definition to monitor.

	PSADTNXT.ProcessManagement.NxtCloseProcess - The process definition to stop.
	.OUTPUTS
	System.Boolean - Returns $true if the process starts within the timeout period; otherwise, returns $false.
	System.Diagnostics.Process - Returns the process when -PassThru is specified.
	With the -IsStopped switch, the test will be inverted.
	.PARAMETER Name
	The name of the process to monitor.
	.PARAMETER Id
	The ID of the process to monitor.
	.PARAMETER ProcessDefinition
	The process definition to monitor.
	.PARAMETER Timeout
	The maximum time to wait for the process to start or stop.
	.PARAMETER Interval
	The interval at which to check for the process's presence or disappearance.
	.PARAMETER PassThru
	Instead of returning a boolean, return the object.
	.PARAMETER IsStopped
	Instead of checking for the presence of the process, check for its disappearance.
	.EXAMPLE
	Wait-NXTProcess -Name "notepad.exe" -Timeout '00:02:00'

	Monitors for 'notepad.exe' to start and waits up to 120 seconds for it to appear.
	.EXAMPLE
	Wait-NXTProcess -Name "notepad.exe" -Timeout '00:02:00' -IsStopped

	This example monitors for 'notepad.exe' and waits up to 120 seconds for it to stop.
	#>
	[OutputType([System.Boolean], [System.Diagnostics.Process])]
	[CmdletBinding(DefaultParameterSetName = 'Name')]
	param (
		[Parameter(Position = 0, ParameterSetName = 'Name', Mandatory)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Name,
		[Parameter(ParameterSetName = 'Id', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[ValidateRange(0, [System.Int32]::MaxValue)]
		[Alias('Pid', 'ProcessId')]
		[System.Int32]
		$Id,
		[Parameter(ParameterSetName = 'ProcessDefinition', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[ValidateNotNull()]
		[PSADT.ProcessManagement.ProcessDefinition]
		$ProcessDefinition,
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$Timeout = '00:01:00',
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$Interval = '00:00:01.000',
		[System.Management.Automation.SwitchParameter]
		$PassThru,
		[System.Management.Automation.SwitchParameter]
		$IsStopped
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		$null = $PSBoundParameters.Remove('Timeout')
		$null = $PSBoundParameters.Remove('Interval')
		$null = $PSBoundParameters.Remove('PassThru')
		$null = $PSBoundParameters.Remove('IsStopped')
	}
	process {
		try {
			if ($IsStopped) {
				[System.Management.Automation.ScriptBlock]$waitWhile = { Test-NXTProcess @PSBoundParameters }
				[System.String]$successMessage = "The specified process was stopped within the specified timeout of [$Timeout]."
				[System.String]$failureMessage = "The specified process is still running after the specified timeout of [$Timeout]."
			}
			else {
				[System.Management.Automation.ScriptBlock]$waitWhile = { -not (Resolve-NXTProcess @PSBoundParameters) }
				[System.String]$successMessage = "The specified process became available within the specified timeout of [$Timeout]."
				[System.String]$failureMessage = "The specified process is still not available after the specified timeout of [$Timeout]."
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
			if ($PassThru) {
				if ($IsStopped) {
					return (if ($result) { $null } else { Resolve-NXTProcess @PSBoundParameters })
				}
				else {
					return (if ($result) { Resolve-NXTProcess @PSBoundParameters } else { $null })
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
