function Get-NXTFolderSize {
	<#
	.SYNOPSIS
	Retrieves the size of the specified folder recursively, in the given unit.
	.DESCRIPTION
	The Get-NxtFolderSize function calculates the size of the specified folder, including all of its sub folders and files.
	It supports various units for the output size, such as bytes, kilobytes, megabytes, gigabytes, and terabytes.
	.INPUTS
	System.String[] - The path to the folder(s) to calculate the size of.

	System.IO.DirectoryInfo[] - The folder(s) to calculate the size of.
	.OUTPUTS
	System.UInt64 - The size of the folder(s) in the specified unit.
	.EXAMPLE
	Get-NxtFolderSize "D:\setup\"

	Retrieves the size of the folder located at "D:\setup\" in bytes.
	.EXAMPLE
	Get-NxtFolderSize "C:\Users\User\Documents" -Unit "MB"

	Retrieves the size of the folder located at "C:\Users\User\Documents" in megabytes.
	#>
	[OutputType([System.UInt64])]
	[CmdletBinding(DefaultParameterSetName = 'Path')]
	param (
		[Parameter(Position = 0, ParameterSetName = 'Path', Mandatory)]
		[Alias('FolderPath')]
		[SupportsWildcards()][ValidateNotNullOrEmpty()]
		[System.String[]]
		$Path,
		[Parameter(ParameterSetName = 'LiteralPath', Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('PSPath')]
		[ValidateNotNullOrEmpty()]
		[System.String[]]
		$LiteralPath,
		[SupportsWildcards()]
		[System.String]
		$Filter,
		[SupportsWildcards()]
		[System.String[]]
		$Exclude,
		[SupportsWildcards()]
		[System.String[]]
		$Include,
		[PSADTNXT.IO.DataSizeUnit]
		$Unit = [PSADTNXT.IO.DataSizeUnit]::B
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[System.UInt64]$size = 0
			foreach ($folder in (Resolve-NXTPath @PSBoundParameters -ProviderName 'FileSystem' -AsProviderPath -PathType Container)) {
				[System.IO.DirectoryInfo]::new($folder).EnumerateFiles('*', [System.IO.SearchOption]::AllDirectories) | . { process { $size += $_.Length } }
			}
			return [System.Math]::Round(($size / "$("1$Unit" -replace '1B', '1D')"))
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
