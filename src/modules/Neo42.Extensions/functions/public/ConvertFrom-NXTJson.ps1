function ConvertFrom-NXTJson {
	<#
	.SYNOPSIS
	Converts a JSON string to a custom object.
	.DESCRIPTION
	The ConvertFrom-NXTJson function converts a JSON string to a custom object.
	It enables the feature set of PowerShell Core's Cmdlet in Windows PowerShell 5.1 (json with comments and -AsHashtable parameter).
	.INPUTS
	System.String - The JSON string to convert.
	.OUTPUTS
	System.Management.Automation.PSObject - The custom object created from the JSON string.

	System.Collections.Hashtable - The custom object created from the JSON string if the -AsHashtable parameter is specified.
	.PARAMETER InputObject
	The JSON string to convert.
	.PARAMETER AsHashtable
	When specified, the function will return a hashtable instead of a custom object.
	The keys of the hashtable are case-sensitive, so JSON objects containing keys that only differ in casing (e.g. 'key' and 'Key') can be converted.
	.EXAMPLE
	'{"key": "value"}' | ConvertFrom-NXTJson

	This will return a custom object with the key 'key' and the value 'value'.
	.EXAMPLE
	'{"key": "lower", "Key": "upper"}' | ConvertFrom-NXTJson -AsHashtable

	This will return a case-sensitive hashtable with the keys 'key' and 'Key'.
	.NOTES
	Custom objects cannot hold properties that only differ in casing, so the -AsHashtable parameter is required for such JSON strings.
	Arrays nested in a hashtable are returned as System.Collections.ArrayList.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseLiteralInitializerForHashtable', '', Justification = 'We need a case sensitive hashtable.')]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleCommands', '', Justification = 'There is a code gate before it.')]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSNxtAvoidBaseTypes', '', Justification = 'There is a code gate before it.')]
	[Alias('ConvertFrom-NXTJsonC')]
	[OutputType([System.Collections.Hashtable[]], [System.Management.Automation.PSObject[]])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipeline)]
		[AllowEmptyString()]
		[System.String]
		$InputObject,
		[System.Management.Automation.SwitchParameter]
		$AsHashtable
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Text.RegularExpressions.Regex]$jsonCommentPattern = [System.Text.RegularExpressions.Regex]::new('(?<EscapedString>"(?:\\.|[^\\"])*")|(?:(?:\/\*[\S\s]*?\*\/)|(?:\/\/.*))')
		if ($AsHashtable -and $PSVersionTable.PSEdition -ne 'Core') {
			# ConvertFrom-Json of Windows PowerShell treats keys case-insensitive, so we parse with the underlying serializer which keeps the keys case-sensitive
			[System.Web.Script.Serialization.JavaScriptSerializer]$jsonSerializer = [System.Web.Script.Serialization.JavaScriptSerializer]::new()
			# Align limits with ConvertFrom-Json of Windows PowerShell
			$jsonSerializer.MaxJsonLength = [System.Int32]::MaxValue
			$jsonSerializer.RecursionLimit = 1020
			[System.Management.Automation.ScriptBlock]$convertToCaseSensitiveHashtable = {
				param (
					[System.Object]
					$JsonNode
				)
				if ($JsonNode -is [System.Collections.Generic.IDictionary[System.String, System.Object]]) {
					[System.Collections.Hashtable]$hashtable = [System.Collections.Hashtable]::new([System.StringComparer]::Ordinal)
					foreach ($key in $JsonNode.Keys) {
						$hashtable[$key] = & $convertToCaseSensitiveHashtable -JsonNode $JsonNode[$key]
					}
					return $hashtable
				}
				if ($JsonNode -is [System.Object[]]) {
					[System.Collections.IList]$list = [System.Collections.ArrayList]::new($JsonNode.Count)
					foreach ($item in $JsonNode) {
						$null = $list.Add((& $convertToCaseSensitiveHashtable -JsonNode $item))
					}
					return , $list
				}
				return $JsonNode
			}
		}
	}
	process {
		try {
			# Route to the native function in core. It supports our case.
			if ($PSVersionTable.PSEdition -eq 'Core') { return (ConvertFrom-Json -InputObject $InputObject -AsHashtable:$AsHashtable) }

			# Drop unsupported comments in .NET Framework
			[System.String]$json = $jsonCommentPattern.Replace($InputObject, '${EscapedString}')

			# For non hashtable we can use the native function
			if (-not $AsHashtable) { return (ConvertFrom-Json -InputObject $json) }

			$result = & $convertToCaseSensitiveHashtable -JsonNode $jsonSerializer.DeserializeObject($json)
			if ($null -ne $result) {
				# Unroll top level arrays like ConvertFrom-Json does
				$PSCmdlet.WriteObject($result, $result -is [System.Collections.IList])
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
