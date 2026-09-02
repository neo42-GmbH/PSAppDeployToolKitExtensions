function Add-NXTXmlNode {
	<#
	.SYNOPSIS
	Adds a new node to an existing xml node.
	.DESCRIPTION
	Adds a new node to an existing xml node. The node is added at the specified XPath location.
	The XPath must point to a single node. The new node will be added as a child node of the specified node.
	.INPUTS
	System.Xml.XmlNode[] - The XML node(s) or XML document(s) to add the new node to.

	System.IO.FileInfo[] - The XML file(s) to add the new node to.
	.OUTPUTS
	System.Xml.XmlNode[] - The XML node(s) or document(s) that were modified if the `-PassThru` parameter is specified.
	.PARAMETER Path
	The path to the XML file(s) to add the node to.
	.PARAMETER LiteralPath
	The literal path to the XML file(s) to add the node to.
	.PARAMETER Filter
	A filter to qualify the Path parameter.
	.PARAMETER Exclude
	A filter to exclude items from the Path parameter.
	.PARAMETER Include
	A filter to include items in the Path parameter.
	.PARAMETER Encoding
	The encoding to use when the file is created. If the file exists, the encoding will not be updated.
	.PARAMETER InputObject
	The XML node(s) to add the new node to.
	.PARAMETER XPath
	The XPath to the node to add the new node to.
	.PARAMETER Name
	The name of the new node to add.
	The name can contain a namespace prefix (e.g. 'ns:nodeName') if the node is in a namespace. The namespace prefix must be defined in the XML document.
	.PARAMETER Attributes
	A hashtable of attributes to set on the new node.
	The keys can contain a namespace prefix (e.g. 'ns:attrName') if the attribute is in a namespace. The namespace prefix must be defined in the XML document.
	.PARAMETER InnerText
	The inner text to set on the new node.
	.PARAMETER PassThru
	Returns the XML document if specified.
	.PARAMETER Force
	Determines if the Read-Only attribute should be ignored when setting the content of the file or hidden files should be processed.
	.EXAMPLE
	Add-NXTXmlNode -Path 'C:\Temp\test.xml' -XPath '/root/parent' -Name 'child' -Attributes @{ attr1 = 'value1'; attr2 = 'value2' } -InnerText 'Hello World'

	Adds a new node 'child' to the XML document 'C:\Temp\test.xml' at the XPath location '/root/parent'.
	#>
	[OutputType([System.Xml.XmlNode[]])]
	[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Path')]
	param (
		[Parameter(Position = 0, ParameterSetName = 'Path', Mandatory)]
		[Alias('FilePath')]
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
		[Alias('NodePath')]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$XPath,
		[Parameter(Mandatory)]
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
		[System.Collections.Hashtable]$encodingSplat = if ($Encoding) { @{ Encoding = $Encoding } } else { @{} }
	}
	process {
		try {
			if ($PSCmdlet.ParameterSetName -in @('Path', 'LiteralPath')) {
				[System.String[]]$files = Resolve-NXTPath @PSBoundParameters -ProviderName 'FileSystem' -PathType Leaf
				$InputObject = Import-NXTXmlFile -LiteralPath $files @encodingSplat
			}

			for ([System.Int32]$i = 0; $i -lt $InputObject.Count; $i++) {
				[System.Xml.XmlNode]$xml = $InputObject[$i]
				[System.Xml.XmlNamespaceManager]$nsManager = Get-NXTXMLNamespaceManager -InputObject $xml
				[System.Xml.XmlDocument]$xmlDoc = if ($xml.OwnerDocument) { $xml.OwnerDocument } else { $xml }
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
				[System.String[]]$nameParts = $Name.Split(':', 2)
				[System.String]$localName = $nameParts[-1]
				[System.Xml.XmlElement]$newNode = if ($nameParts.Length -eq 2) {
					$xmlDoc.CreateElement($localName, $nsManager.LookupNamespace($nameParts[0]))
				}
				else {
					$xmlDoc.CreateElement($localName)
				}
				if ($null -ne $Attributes) {
					foreach ($key in $Attributes.Keys) {
						[System.String[]]$attributeParts = $key.Split(':', 2)
						if ($attributeParts.Length -eq 2) {
							$newNode.SetAttribute($attributeParts[1], $nsManager.LookupNamespace($attributeParts[0]), $Attributes[$key])
						}
						else {
							$newNode.SetAttribute($key, $Attributes[$key])
						}
					}
				}
				if ($null -ne $InnerText) { $newNode.InnerText = $InnerText }
				Write-ADTLogEntry -Message "Adding XML node [$Name] to XPath [$XPath]."
				$null = $node.AppendChild($newNode)
				if ($PassThru) { $xml }

				if ($PSCmdlet.ParameterSetName -in @('Path', 'LiteralPath') -and $PSCmdlet.ShouldProcess($files[$i], 'Update XML file')) {
					Set-NXTContent -LiteralPath $files[$i] -Value $xml.OuterXml @encodingSplat -Force:$Force
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
