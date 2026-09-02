function Update-NXTTextInFile {
	<#
	.SYNOPSIS
	Updates text within a file by replacing specified strings.
	.DESCRIPTION
	This cmdlet allows you to replace specific text in a file. It searches for a given string and replaces it with another string.
	The function can target a specific number of occurrences and use various encoding options.
	.INPUTS
	System.String - The value to replace the query string with.
	.PARAMETER Path
	The path to the file(s) to update.
	.PARAMETER LiteralPath
	The literal path to the file(s) to update.
	.PARAMETER Filter
	A filter to qualify the Path parameter.
	.PARAMETER Exclude
	A filter to exclude items from the Path parameter.
	.PARAMETER Include
	A filter to include items in the Path parameter.
	.PARAMETER Query
	The string to search for in the file(s).
	.PARAMETER Value
	The string to replace the query string with.
	.PARAMETER Regex
	Indicates that the query string is a regular expression.
	.PARAMETER CaseSensitive
	Indicates that the search should be case-sensitive.
	.PARAMETER Count
	The maximum number of occurrences to replace.
	.PARAMETER Encoding
	The encoding to use when reading and writing the file. If not specified, the encoding will be detected from the file.
	.PARAMETER Force
	Determines if hidden files should be processed or if the Read-Only attribute should be ignored when setting the content of the file.
	.EXAMPLE
	`Update-NXTTextInFile -Path 'C:\Temp\test.txt' -Query 'Hello' -Value 'Hi'`

	Updates the text 'Hello' to 'Hi' in the file 'C:\Temp\test.txt'.
	#>
	[CmdletBinding(DefaultParameterSetName = 'Path', SupportsShouldProcess)]
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
		[Parameter(Position = 1, Mandatory)]
		[Alias('SearchString')]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Query,
		[Parameter(Position = 2, Mandatory, ValueFromPipeline)]
		[Alias('ReplaceString')]
		[AllowEmptyString()]
		[System.String]
		$Value,
		[System.Management.Automation.SwitchParameter]
		$Regex,
		[System.Management.Automation.SwitchParameter]
		$CaseSensitive,
		[System.UInt32]
		$Count = [System.Int32]::MaxValue,
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
			[System.Text.RegularExpressions.RegexOptions]$options = if ($CaseSensitive) { [System.Text.RegularExpressions.RegexOptions]::None } else { [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }
			[System.String]$pattern = if ($Regex) { $Query } else { [System.Text.RegularExpressions.Regex]::Escape($Query) }
			foreach ($file in (Resolve-NXTPath @PSBoundParameters -ProviderName 'FileSystem' -PathType Leaf)) {
				Write-ADTLogEntry -Message "Updating text in file [$file]: Replacing [$Query] with [$Value]."
				if ($PSCmdlet.ShouldProcess($file, "Replace [$Query] with [$Value].")) {
					Set-NXTContent -LiteralPath $file @encodingSplat -Force:$Force -Value (
						[System.Text.RegularExpressions.Regex]::new($pattern, $options).Replace(
							(Get-NXTContent -LiteralPath $file @encodingSplat -Force:$Force),
							$(if ($Regex) { $Value } else { $Value.Replace('$', '$$') }),
							$Count
						)
					)
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
