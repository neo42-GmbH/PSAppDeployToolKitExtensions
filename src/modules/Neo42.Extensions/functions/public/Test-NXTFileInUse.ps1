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
	.PARAMETER Force
	Determines if hidden files should be processed.
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
		[System.String]
		$Path,
		[System.Management.Automation.SwitchParameter]
		$Force
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[System.String]$providerPath = Resolve-NXTPath -LiteralPath $Path -AsProviderPath -ProviderName 'FileSystem' -PathType Leaf -Force:$Force -IncludeNonExistent
			if (-not [System.IO.File]::Exists($providerPath)) { return $false }
			try {
				[System.IO.File]::Open($providerPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read).Dispose()
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
