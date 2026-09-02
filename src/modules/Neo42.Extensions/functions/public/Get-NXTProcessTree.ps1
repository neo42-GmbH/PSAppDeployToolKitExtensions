function Get-NXTProcessTree {
	<#
	.SYNOPSIS
	Get the process tree for a given process ID
	.DESCRIPTION
	It retrieves the parent process(es) and child process(es) of the specified process ID in order.
	.INPUTS
	System.UInt32 - The process ID to check.

	System.Diagnostics.Process - The process to check.

	Microsoft.Management.Infrastructure.CimInstance - The Win32_Process cim instance to check.
	.OUTPUTS
	System.Diagnostics.Process[] - The process tree for the specified process ID.
	.PARAMETER Id
	The process ID of the process to get the tree for.
	.PARAMETER NoChildren
	When specified, the function will not retrieve child processes.
	.PARAMETER NoParents
	When specified, the function will not retrieve parent processes.
	.PARAMETER Depth
	The maximum number of child processes and parent processes to retrieve.
	The value applies to both child and parent processes separately.
	.EXAMPLE
	`Get-NXTProcessTree -Id 1234`

	Retrieves the process tree for the process with ID 1234.
	.EXAMPLE
	Get-NXTProcessTree -Id 1234 -NoParents -Depth 1

	Retrieves the child processes of the process with ID 1234, without retrieving parent processes.
	#>
	[OutputType([System.Diagnostics.Process[]])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, ValueFromPipelineByPropertyName)]
		[Alias('Pid', 'ProcessId')]
		[System.UInt32]
		$Id = $PID,
		[System.Management.Automation.SwitchParameter]
		$NoChildren,
		[System.Management.Automation.SwitchParameter]
		$NoParents,
		[System.UInt16]
		$Depth = 20
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Management.Automation.ScriptBlock]$getChildren = {
			param ([System.Diagnostics.Process]$Process, [System.UInt16]$Depth)
			if ($Depth -gt 0) {
				[PSADTNXT.Extensions.NxtProcessExtensions]::GetChildProcesses($Process) | & {
					process {
						$_
						& $getChildren -Process $_ -Depth ($Depth - 1)
					}
				}
			}
		}
	}
	process {
		try {
			[System.Diagnostics.Process]$process = Get-Process -Id $Id
			[System.Collections.Generic.List[System.Diagnostics.Process]]$processes = [System.Collections.Generic.List[System.Diagnostics.Process]]::new()
			if ($Depth -eq 0) { return $processes.ToArray() }
			if (-not $NoParents -and $Depth -gt 1) {
				Get-NXTParentProcess -Id $Id -Recurse -Depth ($Depth - 1) | & { process { $processes.Add($_) } }
			}
			$processes.Add($process)
			if (-not $NoChildren -and $Depth -gt 1) {
				& $getChildren -Process $process -Depth ($Depth - 1) | & { process { $processes.Add($_) } }
			}
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
