function Get-NXTContent {
	<#
	.SYNOPSIS
	Get content of a file.
	.DESCRIPTION
	Replaces Get-Content with neo42 encoding handling for files.
	.INPUTS
	System.IO.FileInfo[] - The file(s) to get content from.
	.OUTPUTS
	System.String - The content of the file(s).
	.PARAMETER Path
	The path to the file(s) to get content from.
	.PARAMETER LiteralPath
	The literal path to the file(s) to get content from.
	.PARAMETER Filter
	A filter to qualify the Path parameter.
	.PARAMETER Exclude
	A filter to exclude items from the Path parameter.
	.PARAMETER Include
	A filter to include items in the Path parameter.
	.PARAMETER Force
	Determines if hidden files should be processed.
	.PARAMETER Encoding
	The encoding to read the file with. If not specified, the encoding will be detected from the file.
	.EXAMPLE
	Get-NXTContent -Path 'C:\Temp\test.txt'

	Gets the content of the file 'C:\Temp\test.txt'.
	.EXAMPLE
	Get-NXTContent -Path 'C:\Temp\test.txt' -Encoding UTF8

	Gets the content of the file 'C:\Temp\test.txt' using the UTF8 encoding.
	#>
	[OutputType([System.String])]
	[CmdletBinding(DefaultParameterSetName = 'Path')]
	param (
		[Parameter(Position = 0, ParameterSetName = 'Path', Mandatory)]
		[SupportsWildcards()][ValidateNotNullOrEmpty()]
		[System.String[]]
		$Path,
		[Parameter(ParameterSetName = 'LiteralPath', Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('PSPath')]
		[ValidateNotNullOrEmpty()]
		[System.String[]]
		$LiteralPath,
		[ValidateNotNullOrEmpty()]
		[SupportsWildcards()]
		[System.String]
		$Filter,
		[ValidateNotNullOrEmpty()]
		[SupportsWildcards()]
		[System.String[]]
		$Exclude,
		[ValidateNotNullOrEmpty()]
		[SupportsWildcards()]
		[System.String[]]
		$Include,
		[System.Management.Automation.SwitchParameter]
		$Force,
		[ValidateNotNull()]
		[ArgumentCompleter([PSADTNXT.Text.NxtEncodingArgumentCompleter])]
		[PSADTNXT.Attributes.NxtEncodingTransformationAttribute()]
		[System.Text.Encoding]
		$Encoding
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			foreach ($file in (Resolve-NXTPath @PSBoundParameters -ProviderName 'FileSystem' -AsProviderPath -PathType Leaf)) {
				if ($Encoding) {
					[System.IO.File]::ReadAllText($file, $Encoding)
				}
				else {
					[System.IO.File]::ReadAllText($file)
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
