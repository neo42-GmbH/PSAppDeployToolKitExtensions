function Test-NXTFileInUse {
	<#
	.SYNOPSIS
	Test if a file is in locked by another process.
	.DESCRIPTION
	Test if a file is locked by another process.
	It can only successfully test if the process has read/write access to the file.
	.INPUTS
	System.IO.FileInfo - The file to test.
	.OUTPUTS
	System.Boolean - Returns true if the file is locked, otherwise false.
	.PARAMETER Path
	The path to the file to test.
	.EXAMPLE
	Test-NXTFileInUse -Path 'C:\Temp\file.txt'

	Check if the file 'C:\Temp\file.txt' is locked another process.
	#>
	[OutputType([System.Boolean])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('LiteralPath', 'PSPath')]
		[ValidateNotNullOrEmpty()]
		[System.String[]]
		$Path
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if (-not [System.IO.File]::Exists($Path)) { return $false }
			try {
				[System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read).Dispose()
			}
			catch [System.IO.IOException] {
				return $true
			}
			return $false
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
