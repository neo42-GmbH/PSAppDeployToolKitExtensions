function Import-NXTIniFile {
	<#
	.SYNOPSIS
	Imports an INI file.
	.DESCRIPTION
	Imports an INI file as a hashtable or as an IniDocument object with comments.
	.INPUTS
	System.String - The path to the INI file(s) to import.

	System.IO.FileInfo - The INI file(s) to import.
	.OUTPUTS
	System.Collections.Hashtable - The INI file as a hashtable if the `-AsIniDocument` parameter is specified.
	PSADTNXT.Configuration.NxtIniDocument - The INI file as an IniDocument object with comments.
	.PARAMETER Path
	The path to the INI file(s) to import.
	.PARAMETER LiteralPath
	The literal path to the INI file(s) to import.
	.PARAMETER Filter
	A filter to qualify the Path parameter.
	.PARAMETER Exclude
	A filter to exclude items from the Path parameter.
	.PARAMETER Include
	A filter to include items in the Path parameter.
	.PARAMETER AsIniDocument
	When specified, the function will return an IniDocument object with comments.
	.PARAMETER Encoding
	The encoding to use when reading the file. If not specified, the encoding will be detected from the file.
	.PARAMETER UnboundArguments
	Unbound arguments that are passed to the function. These will be ignored but are useful for easier invocation of the function.
	.EXAMPLE
	Import-NXTIniFile -Path 'C:\Temp\test.ini'

	Imports the INI file 'C:\Temp\test.ini' as hashtable.
	.EXAMPLE
	Import-NXTIniFile -Path 'C:\Temp\test' -AsIniDocument

	Imports the INI file 'C:\Temp\test.ini' as an IniDocument object with comments.
	#>
	[OutputType([System.Collections.Hashtable], [PSADTNXT.Configuration.NxtIniDocument])]
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
		$AsIniDocument,
		[ArgumentCompleter([PSADTNXT.Text.NxtEncodingArgumentCompleter])]
		[PSADTNXT.Attributes.NxtEncodingTransformationAttribute()]
		[System.Text.Encoding]
		$Encoding,
		[Parameter(DontShow, ValueFromRemainingArguments)]
		[AllowNull()][AllowEmptyCollection()]
		[System.Collections.Generic.List[System.Object]]
		$UnboundArguments
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Collections.Hashtable]$encodingSplat = if ($Encoding) { @{ Encoding = $Encoding } } else { @{} }
		$null = $PSBoundParameters.Remove('UnboundArguments')
	}
	process {
		try {
			foreach ($file in (Resolve-NXTPath @PSBoundParameters -ProviderName 'FileSystem' -PathType Leaf)) {
				[PSADTNXT.Configuration.NxtIniDocument]$iniDocument = [PSADTNXT.Configuration.NxtIniDocument]::new()
				$iniDocument.Parse((Get-NXTContent -LiteralPath $file @encodingSplat))
				if (-not $AsIniDocument) {
					[System.Collections.Hashtable]$iniDocument
				}
				else {
					# We need to output the IniDocument object without unwrapping it
					$PSCmdlet.WriteObject($iniDocument, $false)
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
