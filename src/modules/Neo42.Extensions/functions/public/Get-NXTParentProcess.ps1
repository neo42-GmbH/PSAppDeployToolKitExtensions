function Get-NXTParentProcess {
	<#
	.SYNOPSIS
	Retrieves the parent process of a given process ID.
	.DESCRIPTION
	Retrieves the parent process(es) of a given process ID in order.
	It can optionally retrieve the entire parent hierarchy by using the `-Recurse` switch.
	.INPUTS
	System.UInt32 - The process ID to check.

	System.Diagnostics.Process - The process to check.

	Microsoft.Management.Infrastructure.CimInstance - The Win32_Process cim instance to check.
	.OUTPUTS
	System.Diagnostics.Process[] - The parent process(es) of the specified process ID.
	.PARAMETER Id
	The process ID of the child process.
	.PARAMETER Recurse
	Recursively retrieves the parent process hierarchy.
	.PARAMETER Depth
	The maximum number of parent processes to retrieve.
	.EXAMPLE
	Get-NXTParentProcess -Id 1234

	Retrieves the parent process of the process with ID 1234.
	.EXAMPLE
	Get-NXTParentProcess -Id 1234 -Recurse -Depth 5

	Retrieves the parent process hierarchy of the process with ID 1234, up to a depth of 5.
	#>
	[OutputType([System.Diagnostics.Process[]])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, ValueFromPipelineByPropertyName = $true)]
		[Alias('Pid', 'ProcessId')]
		[System.UInt32]
		$Id = $PID,
		[System.Management.Automation.SwitchParameter]
		$Recurse,
		[System.UInt16]
		$Depth = 20
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if ($Depth -eq 0) { return }
			[System.Diagnostics.Process]$current = [System.Diagnostics.Process]::GetProcessById($Id)
			[System.Collections.Generic.List[System.Diagnostics.Process]]$processes = [System.Collections.Generic.List[System.Diagnostics.Process]]::new()
			do {
				try {
					[System.Diagnostics.Process]$parent = [PSADT.ProcessManagement.ProcessUtilities]::GetParentProcess($current)
				}
				catch {
					break
				}
				$processes.Insert(0, $parent)
				$current = $parent
			} while ($Recurse -and $Depth-- -gt 1 -and $parent)
			return $processes.ToArray()
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
