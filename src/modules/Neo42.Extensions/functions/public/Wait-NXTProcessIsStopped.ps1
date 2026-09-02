function Wait-NXTProcessIsStopped {
	<#
	.SYNOPSIS
	Monitors the termination of a specified process within a set timeout.
	.DESCRIPTION
	This function checks for the termination of a process within a specified time frame.
	The function continuously monitors the process's presence until it stops or the timeout is reached.
	.INPUTS
	System.String - The name of the process to monitor.

	System.UInt32 - The process ID to monitor.

	System.Diagnostics.Process - The process to monitor.

	Microsoft.Management.Infrastructure.CimInstance - The Win32_Process cim instance to monitor.

	PSADT.ProcessManagement.ProcessDefinition - The process definition to monitor.

	PSADT.ProcessManagement.RunningProcess - The running process to monitor.

	PSADTNXT.ProcessManagement.NxtCloseProcess - The process definition to stop.
	.OUTPUTS
	System.Boolean - Returns true if the process is terminated within the timeout period, otherwise false.
	.PARAMETER Name
	The name of the process to monitor.
	.PARAMETER Id
	The process ID to monitor. Can be a single ID or an array of IDs.
	.PARAMETER ProcessDefinition
	The process definition object to monitor.
	.PARAMETER Timeout
	The maximum time to wait for the process to stop.
	.EXAMPLE
	Wait-NXTProcessIsStopped -Name "notepad.exe" -Timeout '00:02:00'

	This example monitors for 'notepad.exe' and waits up to 120 seconds for it to stop.
	#>
	[OutputType([System.Boolean])]
	[CmdletBinding(DefaultParameterSetName = 'Name')]
	param (
		[Parameter(Position = 0, ParameterSetName = 'Name', Mandatory)]
		[SupportsWildcards()]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Name,
		[Parameter(ParameterSetName = 'Id', Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('Pid', 'ProcessId')]
		[System.UInt32]
		$Id,
		[Parameter(ParameterSetName = 'ProcessDefinition', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[ValidateNotNull()]
		[PSADT.ProcessManagement.ProcessDefinition]
		$ProcessDefinition,
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$Timeout = '00:01:00'
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		$null = $PSBoundParameters.Remove('Timeout')
	}
	process {
		try {
			[System.DateTime]$endTime = [System.DateTime]::Now.Add($Timeout)
			while (Test-NXTProcess @PSBoundParameters) {
				if ([System.DateTime]::Now -ge $endTime) {
					Write-ADTLogEntry -Severity Warning -Message "The specified process is still running after [$Timeout]." -DebugMessage
					return $false
				}
				Start-Sleep -Seconds 1
			}
			Write-ADTLogEntry -Message "The process was closed after [$Timeout]." -DebugMessage
			return $true
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
