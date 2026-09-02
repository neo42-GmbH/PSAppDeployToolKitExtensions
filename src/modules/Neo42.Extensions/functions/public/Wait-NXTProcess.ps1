function Wait-NXTProcess {
	<#
	.SYNOPSIS
	Monitors the startup of a specified process within a set timeout period.
	.DESCRIPTION
	This function checks for the startup of a process.
	The function continuously checks for the process's presence until it starts or the timeout is reached.
	.INPUTS
	System.String - The name of the process to monitor.

	System.UInt32 - The process ID to monitor.

	System.Diagnostics.Process - The process to monitor.

	Microsoft.Management.Infrastructure.CimInstance - The Win32_Process cim instance to monitor.

	PSADT.ProcessManagement.ProcessDefinition - The process definition to monitor.

	PSADTNXT.ProcessManagement.NxtCloseProcess - The process definition to stop.
	.OUTPUTS
	System.Boolean - Returns true if the process starts within the timeout period, otherwise false.

	System.Diagnostics.Process - Returns the process if PassThru is specified
	.PARAMETER Name
	The name of the process to monitor.
	.PARAMETER Id
	The ID of the process to monitor.
	.PARAMETER ProcessDefinition
	The process definition to monitor.
	.PARAMETER Timeout
	The maximum time to wait for the process to start.
	.PARAMETER PassThru
	Instead of returning a boolean, return the object.
	.EXAMPLE
	Wait-NXTProcess -Name "notepad.exe" -Timeout '00:02:00'

	Monitors for 'notepad.exe' to start and waits up to 120 seconds for it to appear.
	#>
	[OutputType([System.Boolean], [System.Diagnostics.Process])]
	[CmdletBinding(DefaultParameterSetName = 'Name')]
	param (
		[Parameter(Position = 0, ParameterSetName = 'Name', Mandatory)]
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
		$Timeout = '00:01:00',
		[System.Management.Automation.SwitchParameter]
		$PassThru
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		$null = $PSBoundParameters.Remove('Timeout')
	}
	process {
		try {
			[System.DateTime]$endTime = [System.DateTime]::Now.Add($Timeout)
			while (-not ([System.Diagnostics.Process[]]$process = Resolve-NXTProcess @PSBoundParameters)) {
				if ([System.DateTime]::Now -ge $endTime) {
					Write-ADTLogEntry -Severity Warning -Message "The specified process is still not spawned after [$Timeout]." -DebugMessage
					if ($PassThru) {
						return $null
					}
					else {
						return $false
					}
				}
				Start-Sleep -Seconds 1
			}
			Write-ADTLogEntry -Message "The process became available after [$Timeout]." -DebugMessage
			if ($PassThru) {
				return $process
			}
			else {
				return $true
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
