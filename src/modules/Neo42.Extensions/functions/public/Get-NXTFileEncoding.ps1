function Get-NXTFileEncoding {
	<#
	.SYNOPSIS
	Gets the estimated encoding of a file based on BOM and other heuristics.
	.DESCRIPTION
	The Get-NxtFileEncoding function returns the estimated encoding of a file based on the presence of a Byte Order Mark (BOM) and other heuristics.
	If the encoding cant be detected, it will default to the provided DefaultEncoding.
	.INPUTS
	System.String - The path to the file to check for encoding.

	System.IO.FileInfo - The file to check for encoding.
	.OUTPUTS
	System.Text.Encoding - The estimated encoding of the file.
	.PARAMETER Path
	The path to the file(s) to check for encoding.
	.PARAMETER LiteralPath
	The literal path to the file(s) to check for encoding.
	.PARAMETER Filter
	A filter to qualify the Path parameter.
	.PARAMETER Exclude
	A filter to exclude items from the Path parameter.
	.PARAMETER Include
	A filter to include items in the Path parameter.
	.PARAMETER Force
	Determines if hidden files should be processed.
	.PARAMETER DefaultEncoding
	The default encoding to use if the file does not exist or if the encoding cannot be detected.
	.EXAMPLE
	Get-NXTFileEncoding -Path 'C:\Temp\test.txt'

	Gets the estimated encoding of the file 'C:\Temp\test.txt'.
	#>
	[OutputType([System.Text.Encoding])]
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
		[SupportsWildcards()]
		[System.String]
		$Filter,
		[SupportsWildcards()]
		[System.String[]]
		$Exclude,
		[SupportsWildcards()]
		[System.String[]]
		$Include,
		[System.Management.Automation.SwitchParameter]
		$Force,
		[ValidateNotNull()]
		[PSDefaultValue(Help = 'Will use the caller''s OutputEncoding.', Value = '$OutputEncoding')]
		[ArgumentCompleter([PSADTNXT.Text.NxtEncodingArgumentCompleter])]
		[PSADTNXT.Attributes.NxtEncodingTransformationAttribute()]
		[System.Text.Encoding]
		$DefaultEncoding = $PSCmdlet.SessionState.PSVariable.GetValue('OutputEncoding')
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			foreach ($file in (Resolve-NXTPath @PSBoundParameters -IncludeNonExistent -ProviderName 'FileSystem' -AsProviderPath -PathType Leaf)) {
				if (-not [System.IO.File]::Exists($file)) {
					Write-ADTLogEntry -Severity Warning -Message "The file [$file] does not exist. Returning the default encoding."
					$PSCmdlet.WriteObject($DefaultEncoding)
					continue
				}
				[System.IO.StreamReader]$reader = [System.IO.StreamReader]::new($file, $DefaultEncoding, $true)
				try {
					$null = $reader.Peek()
					$PSCmdlet.WriteObject($reader.CurrentEncoding)
				}
				finally {
					$reader.Close()
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
