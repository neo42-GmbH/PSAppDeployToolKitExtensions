function Test-NXTFileInUse {
	<#
	.SYNOPSIS
	Test if a file is in use by another process.
	.DESCRIPTION
	Test if a file is in use by another process. It can only successfully test if the process has read/write access to the file.
	.INPUTS
	System.IO.FileInfo - The file to test.
	.OUTPUTS
	System.Boolean - Returns true if the file is in use by another process, otherwise false.
	.PARAMETER Path
	The path to the file to test.
	.EXAMPLE
	Test-NXTFileInUse -Path 'C:\Temp\file.txt'

	Check if the file 'C:\Temp\file.txt' is in use by another process.
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
			try {
				[System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read).Dispose()
			}
			catch [System.IO.IOException] {
				# Check we get a file locked exception
				if ($_.Exception.HResult -band 0xFFFF) {
					return $true
				}
				throw $_ # rethrow the exception
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
