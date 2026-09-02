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
	The type of pattern to use for the search. Can be 'Exact', 'Wildcard', or 'Regex'.
	.PARAMETER CaseSensitive
	Specifies whether the search should be case-sensitive.
	.PARAMETER Encoding
	The encoding to use when reading the file. If not specified, the encoding will be detected from the file.
	.PARAMETER Force
	Determines if hidden files should be processed.
	.EXAMPLE
	Test-NXTStringInFile -Path 'C:\Temp\test.txt' -Query 'Hello World' -PatternType 'Exact'

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
		$PatternType = 'Wildcard',
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
			[System.String]$content = Get-NXTContent -LiteralPath $Path @encodingSplat -Force:$Force
			[System.StringComparison]$comparison = if ($CaseSensitive) { [System.StringComparison]::Ordinal } else { [System.StringComparison]::OrdinalIgnoreCase }
			switch ($PatternType) {
				([PSADTNXT.Text.StringCompareOperator]::Equals) {
					return $content.Equals($Query, $comparison)
				}
				([PSADTNXT.Text.StringCompareOperator]::Contains) {
					return $content.IndexOf($Query, $comparison) -ge 0
				}
				([PSADTNXT.Text.StringCompareOperator]::StartsWith) {
					return $content.StartsWith($Query, $comparison)
				}
				([PSADTNXT.Text.StringCompareOperator]::EndsWith) {
					return $content.EndsWith($Query, $comparison)
				}
				([PSADTNXT.Text.StringCompareOperator]::Wildcard) {
					[System.Management.Automation.WildcardOptions]$options = if (-not $CaseSensitive) { [System.Management.Automation.WildcardOptions]::IgnoreCase } else { [System.Management.Automation.WildcardOptions]::None }
					return [System.Management.Automation.WildcardPattern]::new($Query, $options).IsMatch($content)
				}
				([PSADTNXT.Text.StringCompareOperator]::Regex) {
					[System.Text.RegularExpressions.RegexOptions]$options = if (-not $CaseSensitive) { [System.Text.RegularExpressions.RegexOptions]::IgnoreCase } else { [System.Text.RegularExpressions.RegexOptions]::None }
					return [System.Text.RegularExpressions.Regex]::IsMatch($content, $Query, $options)
				}
				default {
					[System.Collections.Hashtable]$errorParams = @{
						Exception    = [System.NotImplementedException]::new("Pattern type [$PatternType] is not implemented.")
						Category     = [System.Management.Automation.ErrorCategory]::NotImplemented
						ErrorId      = 'PatternTypeNotImplemented'
						TargetObject = $PatternType
					}
					throw (New-ADTErrorRecord @errorParams)
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
