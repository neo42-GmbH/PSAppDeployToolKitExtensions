function Import-NXTXmlFile {
	<#
	.SYNOPSIS
	Imports an XML file.
	.DESCRIPTION
	Imports an XML file.
	.INPUTS
	System.String - The path to the XML file(s) to import.
	.OUTPUTS
	System.Xml.XmlDocument - The XML file as an XmlDocument object.
	.PARAMETER Path
	The path to the XML file(s) to import.
	.PARAMETER LiteralPath
	The literal path to the XML file(s) to import.
	.PARAMETER Filter
	A filter to qualify the Path parameter.
	.PARAMETER Exclude
	A filter to exclude items from the Path parameter.
	.PARAMETER Include
	A filter to include items in the Path parameter.
	.PARAMETER Encoding
	The encoding to use when reading the file. If not specified, the encoding will be detected from the file.
	.PARAMETER Force
	Determines if hidden files should be processed.
	.PARAMETER UnboundArguments
	Unbound arguments that are passed to the function. These will be ignored but are useful for easier invocation of the function.
	.EXAMPLE
	Import-NXTXmlFile -Path 'C:\Temp\test.xml'

	Imports the XML file 'C:\Temp\test.xml' as XmlDocument.
	#>
	[OutputType([System.Xml.XmlDocument])]
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
		[ArgumentCompleter([PSADTNXT.Text.NxtEncodingArgumentCompleter])]
		[PSADTNXT.Attributes.NxtEncodingTransformationAttribute()]
		[System.Text.Encoding]
		$Encoding,
		[System.Management.Automation.SwitchParameter]
		$Force,
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
			foreach ($file in (Resolve-NXTPath @PSBoundParameters -ProviderName 'FileSystem' -PathType Leaf -Force:$Force)) {
				[System.Xml.XmlDocument]$xml = [System.Xml.XmlDocument]::new()
				$xml.XmlResolver = $null
				$xml.LoadXml((Get-NXTContent -LiteralPath $file @encodingSplat))
				$PSCmdlet.WriteObject($xml)
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
