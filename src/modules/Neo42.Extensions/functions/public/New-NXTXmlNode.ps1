function New-NXTXmlNode {
	<#
	.SYNOPSIS
	Creates a new sub node in an existing XML document.
	.DESCRIPTION
	Creates a new sub node in an existing XML document. The node is created at the specified XPath location.
	The XPath must point to a single node. If the node already has child nodes, the -Force switch must be used to overwrite them.
	.INPUTS
	System.Xml.XmlDocument[] - The XML document(s) to create the new node in.

	System.IO.FileInfo[] - The XML file(s) to create the new node in.
	.PARAMETER Path
	The path to the XML file(s) to create the node in.
	.PARAMETER LiteralPath
	The literal path to the XML file(s) to create the node in.
	.PARAMETER Filter
	A filter to qualify the Path parameter.
	.PARAMETER Exclude
	A filter to exclude items from the Path parameter.
	.PARAMETER Include
	A filter to include items in the Path parameter.
	.PARAMETER Encoding
	The encoding to use when writing and reading the file. If not specified, the encoding will be detected from the file.
	.PARAMETER InputObject
	The XML node(s) to create the new node in.
	.PARAMETER XPath
	The XPath to the node to create the new node in.
	.PARAMETER Name
	The name of the new node to create.
	.PARAMETER Attributes
	A hashtable of attributes to set on the new node.
	.PARAMETER Prefix
	The prefix to set on the new node.
	.PARAMETER InnerText
	The inner text to set on the new node.
	.PARAMETER Force
	Determines if the existing child nodes should be removed before creating the new node.
	.PARAMETER PassThru
	Returns the XML document if specified.
	.EXAMPLE
	New-NXTXmlNode -Path 'C:\Temp\test.xml' -XPath '/root/parent' -Name 'child' -Attributes @{ attr1 = 'value1'; attr2 = 'value2' } -InnerText 'Hello World'

	Creates a new node 'child' in the XML document 'C:\Temp\test.xml' at the XPath location '/root/parent'.
	The new node will have the attributes 'attr1' and 'attr2' set to 'value1' and 'value2', respectively. The inner text of the new node will be set to 'Hello World'.
	#>
	[OutputType([System.Xml.XmlDocument[]])]
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
		[ValidateNotNull()]
		[PSDefaultValue(Value = '$OutputEncoding')]
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
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Name,
		[System.Collections.Hashtable]
		$Attributes,
		[System.String]
		$Prefix,
		[System.String]
		$InnerText,
		[System.Management.Automation.SwitchParameter]
		$Force,
		[System.Management.Automation.SwitchParameter]
		$PassThru
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Collections.Hashtable]$encodingSplat = if ($Encoding) { @{ Encoding = $Encoding } } else { @{} }
	}
	process {
		try {
			if ($PSCmdlet.ParameterSetName -in @('Path', 'LiteralPath')) {
				[System.String[]]$files = Resolve-NXTPath @PSBoundParameters -ProviderName 'FileSystem' -PathType Leaf
				$InputObject = Import-NXTXmlFile -LiteralPath $files @encodingSplat -Force:$Force
			}

			for ([System.Int32]$i = 0; $i -lt $InputObject.Count; $i++) {
				[System.Xml.XmlNode]$xml = $InputObject[$i]
				[System.Xml.XmlDocument]$xmlDoc = if ($xml.OwnerDocument) { $xml.OwnerDocument } else { $xml }
				[System.Xml.XmlNodeList]$nodes = $xml.SelectNodes($XPath)
				if ($nodes.Count -ne 1) {
					[System.Collections.Hashtable]$errorParams = @{
						Exception = [System.InvalidOperationException]::new("The XPath [$XPath] must point to a single node, but found [$($nodes.Count)] nodes.")
						Category  = [System.Management.Automation.ErrorCategory]::InvalidData
						ErrorId   = 'InvalidNodeCount'
					}
					throw (New-ADTErrorRecord @errorParams)
				}
				[System.Xml.XmlNode]$node = $nodes[0]
				if ($node.ChildNodes.Count -gt 0) {
					if ($Force) { $node.RemoveAll() }
					else {
						[System.Collections.Hashtable]$errorParams = @{
							Exception         = [System.InvalidOperationException]::new("The node [$XPath] already has child nodes.")
							Category          = [System.Management.Automation.ErrorCategory]::InvalidData
							ErrorId           = 'InvalidNodeCount'
							RecommendedAction = 'Use the -Force switch to overwrite them.'
							TargetObject      = $node
						}
						throw (New-ADTErrorRecord @errorParams)
					}
				}
				[System.Xml.XmlElement]$newNode = $xmlDoc.CreateElement($Name)
				if ($Attributes) {
					foreach ($key in $Attributes.Keys) {
						$newNode.SetAttribute($key, $Attributes[$key])
					}
				}
				if ($null -ne $InnerText) { $newNode.InnerText = $InnerText }
				if ($null -ne $Prefix) { $newNode.Prefix = $Prefix }
				$null = $node.AppendChild($newNode)
				if ($PassThru) { $xml }

				Write-ADTLogEntry -Message "Creating new XML root node [$Name] at XPath [$XPath]."
				if ($PSCmdlet.ParameterSetName -in @('Path', 'LiteralPath') -and $PSCmdlet.ShouldProcess($files[$i], 'Update XML file')) {
					Set-NXTContent -Path $files[$i]-Value $xml.OuterXml @encodingSplat -Force:$Force
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
