function Get-NXTXMLNamespaceManager {
	<#
	.SYNOPSIS
	Returns an XML namespace manager for the specified XML document.
	#>
	[OutputType([System.Xml.XmlNamespaceManager])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, ValueFromPipeline)]
		[ValidateNotNull()]
		[System.Xml.XmlNode]
		$InputObject
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		[System.Xml.XmlDocument]$xmlDoc = if ($InputObject.OwnerDocument) { $InputObject.OwnerDocument } else { $InputObject }
		[System.Xml.XmlNamespaceManager]$nsManager = [System.Xml.XmlNamespaceManager]::new($xmlDoc.NameTable)
		foreach ($attr in $xmlDoc.DocumentElement.Attributes) {
			if ($attr.Prefix -eq 'xmlns') {
				$nsManager.AddNamespace($attr.LocalName, $attr.Value)
			}
			elseif ($attr.Name -eq 'xmlns') {
				$nsManager.AddNamespace([System.String]::Empty, $attr.Value)
			}
		}
		$PSCmdlet.WriteObject($nsManager, $false)
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
