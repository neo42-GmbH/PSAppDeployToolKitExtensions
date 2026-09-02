function Remove-NXTXmlNode {
	<#
	.SYNOPSIS
	Removes a node from an existing XML document.
	.DESCRIPTION
	Removes a node from an existing XML document. The node is removed at the specified XPath location.
	The XPath must point to a single node. If the node has child nodes, the -Force switch must be used to remove them.
	.INPUTS
	System.Xml.XmlNode[] - The XML node(s) or document(s) to remove the node from.

	System.IO.FileInfo[] - The XML file(s) to remove the node from.
	.OUTPUTS
	System.Xml.XmlNode[] - The XML node(s) or document(s) that were modified if the `-PassThru` parameter is specified.
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
	Determines if all matching nodes should be removed if more than one node is found.
	.PARAMETER PassThru
	Returns the XML document if specified.
	.EXAMPLE
	Remove-NXTXmlNode -Path 'C:\Temp\test.xml' -XPath '/root/parent/child'

	Removes the node 'child' from the XML document 'C:\Temp\test.xml' at the XPath location '/root/parent/child'.
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
				[System.Xml.XmlNamespaceManager]$nsManager = Get-NXTXMLNamespaceManager -InputObject $xml
				[System.Xml.XmlNodeList]$nodes = $xml.SelectNodes($XPath, $nsManager)
				if ($nodes.Count -eq 0) {
					[System.Collections.Hashtable]$errorParams = @{
						Exception    = [System.InvalidOperationException]::new("The XPath [$XPath] did not return any nodes.")
						Category     = [System.Management.Automation.ErrorCategory]::InvalidData
						ErrorId      = 'InvalidNodeCount'
						TargetObject = $XPath
					}
					throw (New-ADTErrorRecord @errorParams)
				}
				if ($nodes.Count -gt 1 -and -not $Force) {
					[System.Collections.Hashtable]$errorParams = @{
						Exception         = [System.InvalidOperationException]::new("The XPath [$XPath] did not return any nodes.")
						Category          = [System.Management.Automation.ErrorCategory]::InvalidData
						ErrorId           = 'InvalidNodeCount'
						RecommendedAction = 'Use the -Force switch to remove all matching nodes.'
					}
					throw (New-ADTErrorRecord @errorParams)
				}
				Write-ADTLogEntry -Message "Removing XML node(s) at XPath [$XPath]."
				$nodes | & { process { $null = $_.ParentNode.RemoveChild($_) } }
				if ($PassThru) { $xml }

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
