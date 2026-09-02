function Test-NXTIsSystemProcess {
	<#
	.SYNOPSIS
	Checks if a process is running as the system account.
	.DESCRIPTION
	Checks if a process is running as the system account.
	.INPUTS
	System.UInt32 - The process ID to check.

	System.Diagnostics.Process - The process to check.

	Microsoft.Management.Infrastructure.CimInstance - The Win32_Process cim instance to check.
	.OUTPUTS
	System.Boolean - Returns true if the process is running as the system account, otherwise false.
	.PARAMETER Id
	The process ID to check.
	.EXAMPLE
	Test-NxtIsSystemProcess -Id 1234

	Checks if the process with ID 1234 is running as the system account.
	#>
	[Alias('Get-NXTIsSystemProcess')]
	[OutputType([System.Boolean])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, ValueFromPipelineByPropertyName)]
		[Alias('Pid', 'ProcessId')]
		[System.UInt32]
		$Id = $PID
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if ($Id -in @(0, 4)) {
				return $true
			}
			try {
				[System.Diagnostics.Process]$process = [System.Diagnostics.Process]::GetProcessById($Id)
				return [PSADTNXT.Extensions.NxtProcessExtensions]::GetOwner($process).IsSystem
			}
			catch {
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
