function Get-NXTXmlNode {
	<#
	.SYNOPSIS
	Retrieve nodes from an existing XML document.
	.DESCRIPTION
	Retrieves nodes from an existing XML document. The nodes are retrieved at the specified XPath location.
	.INPUTS
	System.Xml.XmlDocument[] - The XML document(s) to add the new node to.

	System.IO.FileInfo[] - The XML file(s) to add the new node to.
	.OUTPUTS
	System.Xml.XmlDocument[] - The XML document(s) that were modified if the `-PassThru` parameter is specified.
	System.String[] - The attribute value(s) of the node(s) that were retrieved.
	.PARAMETER Path
	The path to the XML file(s) to remove the node from.
	.PARAMETER LiteralPath
	The literal path to the XML file(s) to remove the node from.
	.PARAMETER Filter
	A filter to qualify the Path parameter.
	.PARAMETER Exclude
	A filter to exclude items from the Path parameter.
	.PARAMETER Include
	A filter to include items in the Path parameter.
	.PARAMETER Encoding
	The encoding to use when the file is created. If the file exists, the encoding will not be updated.
	.PARAMETER InputObject
	The XML node(s) to remove the node from.
	.PARAMETER XPath
	The XPath to the node to remove.
	.PARAMETER Force
	Determines if hidden files should be processed.
	.EXAMPLE
	Remove-NXTXmlNode -Path 'C:\Temp\test.xml' -XPath '/root/parent/child'

	Removes the node 'child' from the XML document 'C:\Temp\test.xml' at the XPath location '/root/parent/child'.
	#>
	[OutputType([System.Xml.XmlNode[]], [System.String[]])]
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
		[Alias('AttributeName')]
		[System.String]
		$Attribute,
		[System.Management.Automation.SwitchParameter]
		$Single,
		[System.Management.Automation.SwitchParameter]
		$Force
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if ($PSCmdlet.ParameterSetName -in @('Path', 'LiteralPath')) {
				$InputObject = Import-NXTXmlFile @PSBoundParameters
			}

			foreach ($xml in $InputObject) {
				[System.Xml.XmlNamespaceManager]$nsManager = Get-NXTXMLNamespaceManager -InputObject $xml
				[System.Xml.XmlNode[]]$node = if ($Single) { $xml.SelectSingleNode($XPath, $nsManager) } else { $xml.SelectNodes($XPath, $nsManager) }
				if (-not $node -or $node.Count -eq 0) {
					[System.Collections.Hashtable]$errorParams = @{
						Exception         = [System.Management.Automation.ItemNotFoundException]::new("No nodes found at XPath '$XPath' in the provided XML document.")
						Category          = [System.Management.Automation.ErrorCategory]::ObjectNotFound
						ErrorId           = 'NXTXmlNodeNotFound'
						TargetObject      = $xml
						RecommendedAction = 'Check the XPath and ensure the XML document contains the specified nodes.'
					}
					throw (New-ADTErrorRecord @errorParams)
				}
				if ($PSBoundParameters.ContainsKey('Attribute')) {
					if ($Attribute -eq 'InnerText') {
						$PSCmdlet.WriteObject($node.InnerText)
					}
					else {
						[System.String[]]$attributeParts = $Attribute.Split(':', 2)
						$(
							if ($attributeParts.Length -eq 2) {
								$PSCmdlet.WriteObject($node.GetAttribute($attributeParts[1], $nsManager.LookupNamespace($attributeParts[0])))
							}
							else {
								$PSCmdlet.WriteObject($node.GetAttribute($Attribute))
							}
						)
					}
				}
				else {
					$node
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
