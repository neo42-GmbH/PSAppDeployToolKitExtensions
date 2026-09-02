function Set-NXTXmlNode {
	<#
	.SYNOPSIS
	Updates an existing XML node in an XML document.
	.DESCRIPTION
	Updates an existing XML node in an XML document. The node is updated at the specified XPath location.
	The XPath must point to a single node. Values of the specified node will be updated.
	.INPUTS
	System.Xml.XmlNode[] - A node of an XML document(s) or the document(s) to update the node in.

	System.IO.FileInfo[] - The XML file(s) to update the node in.
	.OUTPUTS
	System.Xml.XmlNode[] - The XML nodes or document(s) that were modified if the `-PassThru` parameter is specified.
	.PARAMETER Path
	The path to the XML file(s) to update the node in.
	.PARAMETER LiteralPath
	The literal path to the XML file(s) to update the node in.
	.PARAMETER Filter
	A filter to qualify the Path parameter.
	.PARAMETER Exclude
	A filter to exclude items from the Path parameter.
	.PARAMETER Include
	A filter to include items in the Path parameter.
	.PARAMETER Encoding
	The encoding to use when reading the file. If not specified, the encoding will be detected from the file.
	.PARAMETER InputObject
	The XML node(s) to update.
	.PARAMETER XPath
	The XPath to the node to update.
	.PARAMETER Name
	The name of the node to update.
	.PARAMETER Attributes
	A hashtable of attributes to set on the node.
	.PARAMETER InnerText
	The inner text to set on the node.
	.PARAMETER PassThru
	Returns the XML document if specified.
	.PARAMETER Force
	Determines if the Read-Only attribute should be ignored when setting the content of the file or hidden files should be processed.
	.EXAMPLE
	Set-NXTXmlNode -Path 'C:\Temp\test.xml' -XPath '/root/parent/child' -Attributes @{ attr1 = 'newValue1'; attr2 = 'newValue2' } -InnerText 'New Inner Text'

	Updates the existing node 'child' in the XML document 'C:\Temp\test.xml' at the XPath location '/root/parent/child'.
	#>
	[OutputType([System.Xml.XmlNode[]])]
	[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Path')]
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
		[Parameter(ParameterSetName = 'Path')]
		[Parameter(ParameterSetName = 'LiteralPath')]
		[System.String]
		$Filter,
		[Parameter(ParameterSetName = 'Path')]
		[Parameter(ParameterSetName = 'LiteralPath')]
		[System.String[]]
		$Exclude,
		[Parameter(ParameterSetName = 'Path')]
		[Parameter(ParameterSetName = 'LiteralPath')]
		[System.String[]]
		$Include,
		[Parameter(ParameterSetName = 'Path')]
		[Parameter(ParameterSetName = 'LiteralPath')]
		[ArgumentCompleter([PSADTNXT.Text.NxtEncodingArgumentCompleter])]
		[PSADTNXT.Attributes.NxtEncodingTransformationAttribute()]
		[System.Text.Encoding]
		$Encoding,

		[Parameter(ParameterSetName = 'Xml', ValueFromPipeline)]
		[ValidateNotNull()]
		[System.Xml.XmlNode[]]
		$InputObject,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$XPath,
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Name,
		[System.Collections.Hashtable]
		$Attributes,
		[System.String]
		$InnerText,
		[System.Management.Automation.SwitchParameter]
		$PassThru,
		[System.Management.Automation.SwitchParameter]
		$Force
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if ($PSCmdlet.ParameterSetName -in @('Path', 'LiteralPath')) {
				[System.Collections.Hashtable]$encodingSplat = if ($Encoding) { @{ Encoding = $Encoding } } else { @{} }
				[System.String[]]$files = Resolve-NXTPath @PSBoundParameters -ProviderName 'FileSystem' -PathType Leaf
				$InputObject = Import-NXTXmlFile -LiteralPath $files @encodingSplat -Force:$Force
			}

			for ([System.Int32]$i = 0; $i -lt $InputObject.Count; $i++) {
				[System.Xml.XmlNode]$xml = $InputObject[$i]
				[System.Xml.XmlNamespaceManager]$nsManager = Get-NXTXMLNamespaceManager -InputObject $xml
				[System.Xml.XmlNodeList]$nodes = $xml.SelectNodes($XPath, $nsManager)
				if ($nodes.Count -ne 1) {
					[System.Collections.Hashtable]$errorParams = @{
						Exception = [System.InvalidOperationException]::new("The XPath [$XPath] must point to a single node, but found [$($nodes.Count)] nodes.")
						Category  = [System.Management.Automation.ErrorCategory]::InvalidData
						ErrorId   = 'InvalidNodeCount'
					}
					throw (New-ADTErrorRecord @errorParams)
				}
				[System.Xml.XmlNode]$node = $nodes[0]
				if ($Attributes) {
					$node.Attributes.RemoveAll()
					foreach ($key in $Attributes.Keys) {
						[System.String[]]$attributeParts = $key.Split(':', 2)
						if ($attributeParts.Length -eq 2) {
							$node.SetAttribute($attributeParts[1], $nsManager.LookupNamespace($attributeParts[0]), $Attributes[$key])
						}
						else {
							$node.SetAttribute($key, $Attributes[$key])
						}
					}
				}
				if ($null -ne $InnerText) { $node.InnerText = $InnerText }
				if ($PassThru) { $xml }

				Write-ADTLogEntry -Message "Updating XML node at XPath [$XPath]."
				if ($PSCmdlet.ParameterSetName -in @('Path', 'LiteralPath') -and $PSCmdlet.ShouldProcess($files[$i], 'Update XML file')) {
					Set-NXTContent -Path $files[$i] -Value $xml.OuterXml @encodingSplat -Force:$Force
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
