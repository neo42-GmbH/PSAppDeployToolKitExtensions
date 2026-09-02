function Test-NXTXmlNode {
	<#
	.SYNOPSIS
	Tests for the existence of a node in an XML document.
	.DESCRIPTION
	Tests for the existence of a node in an XML document. The node is located at the specified XPath location.
	.INPUTS
	System.Xml.XmlDocument[] - The XML document(s) to test the node in.

	System.IO.FileInfo[] - The XML file(s) to test the node in.
	.PARAMETER Path
	The path to the XML file(s) to test the node in.
	.PARAMETER Encoding
	The encoding to use when writing and reading the file. If not specified, the encoding will be detected from the file.
	.PARAMETER InputObject
	The XML node(s) to test the node in.
	.PARAMETER XPath
	The XPath to the node to test the node in.
	.PARAMETER Force
	Determines if hidden files should be included when resolving the Path parameter.
	.EXAMPLE
	Test-NXTXmlNode -Path 'C:\Temp\test.xml' -XPath '/root/parent[@attribute="value"]/child'

	Tests if the specified node exists in the XML file at the specified path.
	#>
	[OutputType([System.Boolean])]
	[CmdletBinding(DefaultParameterSetName = 'Path')]
	param (
		[Parameter(Position = 0, ParameterSetName = 'Path', Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('LiteralPath', 'PSPath')]
		[ValidateNotNullOrEmpty()]
		[System.String[]]
		$Path,
		[Parameter(ParameterSetName = 'Path')]
		[ValidateNotNull()]
		[PSDefaultValue(Value = '$OutputEncoding')]
		[ArgumentCompleter([PSADTNXT.Text.NxtEncodingArgumentCompleter])]
		[PSADTNXT.Attributes.NxtEncodingTransformationAttribute()]
		[System.Text.Encoding]
		$Encoding,

		[Parameter(ParameterSetName = 'Xml', ValueFromPipeline)]
		[ValidateNotNull()]
		[System.Xml.XmlNode]
		$InputObject,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$XPath,

		[System.Management.Automation.SwitchParameter]
		$Force
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Collections.Hashtable]$encodingSplat = if ($Encoding) { @{ Encoding = $Encoding } } else { @{} }
	}
	process {
		try {
			if ($PSCmdlet.ParameterSetName -eq 'Path') {
				$InputObject = Import-NXTXmlFile -LiteralPath $Path @encodingSplat -Force:$Force
			}

			return $null -ne ($InputObject.SelectSingleNode($XPath, (Get-NXTXMLNamespaceManager -InputObject $InputObject)))
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
