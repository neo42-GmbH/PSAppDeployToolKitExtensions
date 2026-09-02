function ConvertFrom-NXTEncodedObject {
	<#
	.SYNOPSIS
	Converts a Base64-encoded and compressed object string into a PowerShell object.
	.DESCRIPTION
	Deserializes a given Base64-encoded and compressed string back into its original type.
	.INPUTS
	System.String - The Base64-encoded and compressed string to decode.
	.OUTPUTS
	System.Object - The deserialized object.
	.PARAMETER InputObject
	The Base64-encoded and compressed string to decode.
	.PARAMETER AsHashTable
	When specified, the output object will be converted to a hashtable instead of a PSCustomObject.
	.EXAMPLE
	"eJyzVnLPLEvN80vMTVWyUvLKz8hT0lEKLi2CCrjkpyrV6qAq8k2sQFHjW1pcklqUm5iXp1QbCwCmtj3M" | ConvertFrom-NXTEncodedObject

	This example demonstrates how to decode a Base64-encoded and compressed string into a object.
	#>
	[CmdletBinding()]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipeline)]
		[Alias('EncodedObject')]
		[System.String]
		$InputObject,
		[System.Management.Automation.SwitchParameter]
		$AsHashTable
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			# Convert the Base64 string back to a byte array
			[System.Byte[]]$compressedBytes = [System.Convert]::FromBase64String($InputObject)

			# Create a memory stream from the compressed bytes
			[System.IO.MemoryStream]$compressedStream = [System.IO.MemoryStream]::new($compressedBytes)

			# Create a Deflate stream for decompression
			[System.IO.Compression.DeflateStream]$deflateStream = [System.IO.Compression.DeflateStream]::new(
				$compressedStream,
				[System.IO.Compression.CompressionMode]::Decompress
			)

			# Read the decompressed data into a memory stream
			[System.IO.MemoryStream]$decompressedStream = [System.IO.MemoryStream]::new()
			[System.Byte[]]$buffer = [System.Byte[]]::new(4096)

			[System.Int32]$bytesRead = 0
			do {
				$bytesRead = $deflateStream.Read($buffer, 0, $buffer.Length)
				if ($bytesRead -gt 0) {
					$decompressedStream.Write($buffer, 0, $bytesRead)
				}
			} while ($bytesRead -gt 0)

			# Convert the decompressed data back to a string
			$decompressedStream.Position = 0
			[System.Byte[]]$decompressedBytes = $decompressedStream.ToArray()
			[System.String]$jsonString = [System.Text.Encoding]::UTF8.GetString($decompressedBytes)

			# Close and dispose of streams
			$deflateStream.Close()
			$decompressedStream.Close()
			$compressedStream.Close()

			$PSCmdlet.WriteObject((ConvertFrom-NXTJson -InputObject $jsonString -AsHashTable:$AsHashTable), $false)
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
