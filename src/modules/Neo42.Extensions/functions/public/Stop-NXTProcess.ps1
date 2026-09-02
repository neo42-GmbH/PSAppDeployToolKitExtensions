function Stop-NXTProcess {
	<#
	.SYNOPSIS
	Stops a specified process using the given criteria.
	.DESCRIPTION
	This function stops a process based on its name, ID, or a filter applied to running processes.
	.INPUTS
	System.String - The name of the process to stop.

	System.UInt32 - The process ID to check.

	System.Diagnostics.Process - The process to check.

	Microsoft.Management.Infrastructure.CimInstance - The Win32_Process cim instance to stop.

	PSADT.ProcessManagement.ProcessDefinition - The process definition to stop.

	PSADT.ProcessManagement.RunningProcess - The running process to stop.

	PSADTNXT.ProcessManagement.NxtCloseProcess - The process definition to stop.
	.PARAMETER Name
	The name of the process to stop.
	.PARAMETER Id
	The ID of the process to stop.
	.PARAMETER Process
	The process object to stop.
	.PARAMETER ProcessDefinition
	The process definition to stop.
	.PARAMETER KillProcessTree
	Include all child processes when stopping the specified process.
	.EXAMPLE
	Stop-NXTProcess -Name "notepad.exe"

	This example stops all instances of Notepad running on the system.
	#>
	[CmdletBinding(DefaultParameterSetName = 'Name', SupportsShouldProcess)]
	param (
		[Parameter(Position = 0, ParameterSetName = 'Name', Mandatory)]
		[SupportsWildcards()]
		[ValidateNotNullOrEmpty()]
		[System.String[]]
		$Name,
		[Parameter(ParameterSetName = 'Id', Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('Pid', 'ProcessId')]
		[System.UInt32[]]
		$Id,
		[Parameter(ParameterSetName = 'Process', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[System.Diagnostics.Process[]]
		$Process,
		[Parameter(ParameterSetName = 'ProcessDefinition', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[PSADT.ProcessManagement.ProcessDefinition[]]
		$ProcessDefinition,
		[System.Management.Automation.SwitchParameter]
		$KillProcessTree
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if (-not ([System.Diagnostics.Process[]]$processes = Resolve-NXTProcess @PSBoundParameters)) {
				Write-ADTLogEntry -Severity Warning -Message 'No processes found to stop matching the specified criteria.'
				return
			}
			$processes | & {
				process {
					if ($PSCmdlet.ShouldProcess($_.Name, 'Stop')) {
						Write-ADTLogEntry -Message "Requested to stop process: $($_.Name) (ID: $($_.Id))"
						if ($KillProcessTree) {
							[PSADTNXT.Extensions.NxtProcessExtensions]::KillTree($_)
						}
						else {
							if (-not $_.HasExited) { $_.Kill() }
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
