function Remove-NXTEmptyIniFile {
	<#
	.SYNOPSIS
	Removes only empty INI files.
	.DESCRIPTION
	This function is designed to remove INI files if and only if they are empty.
	If the specified INI file contains any key-value pairs, the function continues without taking any action.
	.INPUTS
	System.IO.FileInfo[] - The INI file(s) to remove.
	.PARAMETER Path
	The path to the INI file(s) to remove.
	.PARAMETER LiteralPath
	The literal path to the INI file(s) to remove.
	.PARAMETER Filter
	A filter to qualify the Path parameter.
	.PARAMETER Exclude
	A filter to exclude items from the Path parameter.
	.PARAMETER Include
	A filter to include items in the Path parameter.
	.EXAMPLE
	Remove-NxtEmptyIniFile -Path "SomeEmptyIniFile.ini"

	Removes the INI file "SomeEmptyIniFile.ini" if it is empty.
	#>
	[CmdletBinding(DefaultParameterSetName = 'Path', SupportsShouldProcess)]
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
		[SupportsWildcards()]
		[System.String]
		$Filter,
		[SupportsWildcards()]
		[System.String[]]
		$Exclude,
		[SupportsWildcards()]
		[System.String[]]
		$Include
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			foreach ($file in (Resolve-NXTPath @PSBoundParameters -ProviderName 'FileSystem' -PathType Leaf -AsProviderPath)) {
				[PSADTNXT.Configuration.NxtIniDocument]$ini = Import-NXTIniFile -LiteralPath $file -AsIniDocument
				if (($ini.Count -eq 0) -or (-not ($ini.Values | & { process { if ($_.Count -gt 0) { return $true } } }))) {
					if ($PSCmdlet.ShouldProcess($file, 'Remove empty INI file')) {
						Write-ADTLogEntry -Message "Removing empty INI file [$file]."
						[System.IO.File]::Delete($file)
					}
				}
				else {
					Write-ADTLogEntry -Message "INI file [$file] is not empty. Skipping removal."
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
