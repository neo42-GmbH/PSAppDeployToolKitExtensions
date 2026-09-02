function ConvertFrom-NXTProductCode {
	<#
	.SYNOPSIS
	Converts an installer product code into a product GUID.
	.DESCRIPTION
	Converts an installer product code into a product GUID.
	.INPUTS
	System.String - The installer product code to convert.
	.OUTPUTS
	System.Guid - The product GUID.
	.PARAMETER ProductCode
	The installer product code that you want to convert into a product GUID.
	.EXAMPLE
	"74A40E43AE252A33DA9C28656E1F4E10" | ConvertFrom-NXTProductCode

	Converts the installer product code into a product GUID.
	#>
	[OutputType([System.Guid])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipeline)]
		[ValidateNotNull()]
		[System.String]
		$ProductCode
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Byte[]]$charIndex = 7, 6, 5, 4, 3, 2, 1, 0, 11, 10, 9, 8, 15, 14, 13, 12, 17, 16, 19, 18, 21, 20, 23, 22, 25, 24, 27, 26, 29, 28, 31, 30
	}
	process {
		try {
			return [System.Guid]::Parse([System.String]::Join([System.String]::Empty, ($charIndex | & { process { $ProductCode[$_] } })))
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
