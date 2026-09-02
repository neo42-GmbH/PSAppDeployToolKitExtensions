function ConvertTo-NXTEncodedObject {
	<#
	.SYNOPSIS
	Converts a object into a Base64-encoded and compressed json string.
	.DESCRIPTION
	The ConvertTo-NxtEncodedObject function takes an object as input and performs three main operations:
	1. Serializes the object via ConvertTo-Json.
	2. Compresses the string using a deterministic compression algorithm.
	3. Encodes the compressed data into a Base64 string.
	This function is useful for securely and efficiently transmitting objects or using them in parameterized commands.
	.INPUTS
	System.Object - The object to convert.
	.OUTPUTS
	System.String - The Base64-encoded and compressed string representation of the object.
	.PARAMETER InputObject
	The object to convert.
	.PARAMETER Depth
	The maximum depth of the object to serialize.
	.EXAMPLE
	@{ Name = 'Jane'; Details = @{ Age = 25; Occupation = 'Engineer' } } | ConvertTo-NXTEncodedObject

	This example demonstrates how to convert a nested object into a Base64-encoded and compressed string.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSNxtAvoidBaseTypes', '', Justification = 'Any object can be passed to this function, so using System.Object is necessary.')]
	[OutputType([System.String])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipeline)]
		[Alias('Object')]
		[System.Object]
		$InputObject,
		[System.UInt16]
		$Depth = 2
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[System.String]$jsonString = ConvertTo-Json -InputObject $InputObject -Depth $Depth -Compress
			[System.Byte[]]$jsonBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
			[System.IO.MemoryStream]$compressedData = [System.IO.MemoryStream]::new()
			[System.IO.Compression.DeflateStream]$deflateStream = [System.IO.Compression.DeflateStream]::new(
				$compressedData,
				[System.IO.Compression.CompressionLevel]::Optimal
			)
			try {
				$deflateStream.Write($jsonBytes, 0, $jsonBytes.Length)
			}
			finally {
				$deflateStream.Close()
			}
			return [System.Convert]::ToBase64String($compressedData.ToArray())
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
