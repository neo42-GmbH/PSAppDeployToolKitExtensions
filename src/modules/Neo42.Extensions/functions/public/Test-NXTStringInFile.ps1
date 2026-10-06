function Test-NXTStringInFile {
	<#
	.SYNOPSIS
	Searches for a specified string or regex pattern within a file.
	.DESCRIPTION
	The Test-NxtStringInFile function searches for a specified string or regex pattern within a file and returns a Boolean result.
	It supports regular expression searches, case-insensitive searches, and can handle different file encodings.
	.INPUTS
	System.IO.FileInfo - The file to search in.
	.OUTPUTS
	System.Boolean - Returns true if the string or pattern is found in the file, otherwise false.
	.PARAMETER Path
	The path to the file to search in.
	.PARAMETER Query
	The query string to search for in the file.
	.PARAMETER PatternType
	The type of pattern to use for the search.
	.PARAMETER CaseSensitive
	Specifies whether the search should be case-sensitive.
	.PARAMETER Encoding
	The encoding to use when reading the file. If not specified, the encoding will be detected from the file.
	.PARAMETER Force
	Determines if hidden files should be processed.
	.EXAMPLE
	Test-NXTStringInFile -Path 'C:\Temp\test.txt' -Query 'Hello World' -PatternType 'Equals'

	Searches for the exact string 'Hello World' in the file 'C:\Temp\test.txt'.
	#>
	[OutputType([System.Boolean])]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('LiteralPath', 'PSPath')]
		[ValidateNotNullOrEmpty()]
		[System.String[]]
		$Path,
		[Parameter(Position = 1, Mandatory)]
		[Alias('SearchString')]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Query,
		[PSADTNXT.Text.StringCompareOperator]
		$PatternType = 'Contains',
		[System.Management.Automation.SwitchParameter]
		$CaseSensitive,
		[ArgumentCompleter([PSADTNXT.Text.NxtEncodingArgumentCompleter])]
		[PSADTNXT.Attributes.NxtEncodingTransformationAttribute()]
		[System.Text.Encoding]
		$Encoding,
		[System.Management.Automation.SwitchParameter]
		$Force
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Collections.Hashtable]$encodingSplat = if ($Encoding) { @{ Encoding = $Encoding } } else { @{} }
	}
	process {
		try {
			return [PSADTNXT.Extensions.NxtStringExtensions]::IsMatch(
				(Get-NXTContent -LiteralPath $Path @encodingSplat -Force:$Force),
				$Query,
				$PatternType,
				-not $CaseSensitive.ToBool()
			)
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
