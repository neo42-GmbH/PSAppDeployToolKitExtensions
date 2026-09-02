function ConvertFrom-NXTJson {
	<#
	.SYNOPSIS
	Converts a JSON string to a custom object.
	.DESCRIPTION
	The ConvertFrom-NXTJson function converts a JSON string to a custom object.
	It enables the feature set of PowerShell Core's Cmdlet in Windows PowerShell 5.1.
	.INPUTS
	System.String - The JSON string to convert.
	.OUTPUTS
	System.Management.Automation.PSObject - The custom object created from the JSON string.
	System.Collections.Hashtable - The custom object created from the JSON string if the `-AsHashTable` parameter is specified.
	.PARAMETER InputObject
	The JSON string to convert.
	.PARAMETER AsHashTable
	When specified, the function will return a hashtable instead of a custom object.
	.EXAMPLE
	'{"key": "value"}' | ConvertFrom-NXTJson

	This will return a custom object with the key 'key' and the value 'value'.
	#>
	[Alias('ConvertFrom-NXTJsonC')]
	[OutputType([System.Collections.Hashtable[]], [System.Management.Automation.PSObject[]])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipeline)]
		[System.String]
		$InputObject,
		[System.Management.Automation.SwitchParameter]
		$AsHashTable
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Text.RegularExpressions.Regex]$jsonCommentPattern = [System.Text.RegularExpressions.Regex]::new('(?<EscapedString>"(?:\\.|[^\\"])*")|(?:(?:\/\*[\S\s]*?\*\/)|(?:\/\/.*))')
	}
	process {
		try {
			# Use native PowerShell JSON conversion if available (PowerShell 6+)
			if ($PSVersionTable.PSVersion.Major -gt 5) { return (ConvertFrom-Json @PSBoundParameters) }

			$result = ConvertFrom-Json -InputObject ($jsonCommentPattern.Replace($InputObject, '${EscapedString}'))
			if ($AsHashTable -and $result -is [System.Array] -and $result.Count -gt 1) {
				$result = $result | & { process { ConvertTo-NXTHashtable -InputObject $_ -Depth ([System.Int32]::MaxValue) } }
			}
			elseif ($AsHashTable -and $result -isnot [System.Array]) {
				$result = ConvertTo-NXTHashtable -InputObject $result -Depth ([System.Int32]::MaxValue)
			}
			return $result
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
