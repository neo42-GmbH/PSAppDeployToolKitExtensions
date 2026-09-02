function ConvertTo-NXTInstallerProductCode {
	<#
	.SYNOPSIS
	Converts a product GUID into an installer product code.
	.DESCRIPTION
	Converts a product GUID into an installer product code.
	.INPUTS
	System.Guid - The product GUID to convert.
	.OUTPUTS
	System.String - The installer product code.
	.PARAMETER Guid
	The product GUID that you want to convert into an installer product code.
	.EXAMPLE
	"{12345678-1234-1234-1234-123456789012}" | ConvertTo-NxtInstallerProductCode

	Converts the product GUID into an installer product code.
	#>
	[OutputType([System.String])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[ValidateNotNull()]
		[Alias('ProductCode')]
		[System.Guid]
		$Guid
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Byte[]]$charIndex = 7, 6, 5, 4, 3, 2, 1, 0, 11, 10, 9, 8, 15, 14, 13, 12, 17, 16, 19, 18, 21, 20, 23, 22, 25, 24, 27, 26, 29, 28, 31, 30
	}
	process {
		try {
			[System.String]$productGuidChars = $Guid.ToString('N')
			return [System.String]::Join([System.String]::Empty, ($charIndex | & { process { $productGuidChars[$_] } })).ToUpper()
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
