function Resolve-NXTProcess {
	<#
	.SYNOPSIS
	Helper function to retrieve processes from different parameter sets.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Filter is used within scriptblock')]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '', Justification = 'Error is to be expected')]
	[OutputType([System.Diagnostics.Process[]])]
	[CmdletBinding(DefaultParameterSetName = 'Name')]
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
		[Parameter(DontShow, ValueFromRemainingArguments)]
		[AllowNull()]
		[System.Collections.Generic.List[System.Object]]
		$UnboundArguments
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		[System.Collections.Generic.List[System.Diagnostics.Process]]$processes = [System.Collections.Generic.List[System.Diagnostics.Process]]::new()
		switch ($PSCmdlet.ParameterSetName) {
			'Id' {
				$Id | & { process { try { $processes.Add([System.Diagnostics.Process]::GetProcessById($_)) } catch {} } }
			}
			'Name' {
				$Name | & {
					process {
						Get-ADTRunningProcesses -ProcessObjects ([PSADT.ProcessManagement.ProcessDefinition]::new([PSADTNXT.IO.NxtPath]::GetExecutableName($_))) -InformationAction SilentlyContinue | & { process { $processes.Add($_.Process) } }
					}
				}
			}
			'ProcessDefinition' {
				Get-ADTRunningProcesses -ProcessObjects $ProcessDefinition -InformationAction SilentlyContinue | & { process { $processes.Add($_.Process) } }
			}
			'Process' {
				$Process | & { process { if ($_ -and -not $_.HasExited) { $processes.Add($_) } } }
			}
		}

		return $processes.ToArray()
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
