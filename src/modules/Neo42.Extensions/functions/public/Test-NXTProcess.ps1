function Test-NXTProcess {
	<#
	.SYNOPSIS
	Tests for the existence of a process.
	.DESCRIPTION
	The Test-NxtProcessExists function checks if a specified process is currently running on the system.
	.INPUTS
	System.String - The name of the process to monitor.

	System.UInt32 - The process ID to monitor.

	System.Diagnostics.Process - The process to monitor.

	Microsoft.Management.Infrastructure.CimInstance - The Win32_Process cim instance to monitor.

	PSADT.ProcessManagement.ProcessDefinition - The process definition to monitor.

	PSADTNXT.ProcessManagement.NxtCloseProcess - The process definition to stop.
	.OUTPUTS
	System.Boolean - Returns true if the process starts within the timeout period, otherwise false.
	.PARAMETER Name
	The name(s) of the process to check for. This parameter is mandatory.
	.PARAMETER Id
	The ID(s) of the process to check for. This parameter is optional and can be used instead of the Name parameter.
	.PARAMETER ProcessDefinition
	The process definition to check for.
	.EXAMPLE
	Test-NXTProcess -Name "notepad.exe"

	Tests if any instance of Notepad is running on the system.
	#>
	[OutputType([System.Boolean])]
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
		$ProcessDefinition
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if (Resolve-NXTProcess @PSBoundParameters -InformationAction SilentlyContinue) {
				return $true
			}
			else {
				return $false
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
