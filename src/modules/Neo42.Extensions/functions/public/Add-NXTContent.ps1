function Add-NXTContent {
	<#
	.SYNOPSIS
	Replaces `Add-Content` with neo42 encoding handling for files.
	.DESCRIPTION
	It's use is limited to only files and it will determine the encoding of the file and use that if no encoding is specified.
	Should the detection fail, or if the file doesn't exist, it will use the encoding defined in the DefaultEncoding parameter.
	Important note: If the file exists and the encoding is specified, the encoding will not be updated. Only the new content will be written with the specified encoding.
	.INPUTS
	System.String[] - The content to add to the file(s).
	System.IO.FileInfo[] - The file(s) to add content to.
	.OUTPUTS
	System.String[] - The content that was added to the file(s) if the `-PassThru` parameter is specified.
	.PARAMETER Path
	The path to the file(s) to add content to.
	.PARAMETER LiteralPath
	The literal path to the file(s) to add content to.
	.PARAMETER Filter
	A filter to qualify the Path parameter.
	.PARAMETER Exclude
	A filter to exclude items from the Path parameter.
	.PARAMETER Include
	A filter to include items in the Path parameter.
	.PARAMETER Value
	The content to add to the file(s).
	.PARAMETER PassThru
	Returns the content added to the file(s) if specified.
	.PARAMETER NoNewLine
	Do not append a newline character to the content.
	.PARAMETER Force
	Determines if the Read-Only attribute should be ignored when setting the content of the file or hidden files should be processed.
	.PARAMETER Encoding
	The encoding to use when the file is created. If the file exists, the encoding will not be updated.
	.EXAMPLE
	Add-NXTContent -Path 'C:\Temp\test.txt' -Value 'Hello World'

	Adds the content 'Hello World' to the file 'C:\Temp\test.txt'.
	.EXAMPLE
	Add-NXTContent -Path 'C:\Temp\test.txt' -Value 'Hello World' -Encoding UTF8

	Adds the content 'Hello World' to the file 'C:\Temp\test.txt' using the UTF8 encoding. If the file exists, only the new content will be written with the specified encoding.
	#>
	[OutputType([System.String[]])]
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
		$Include,

		[Parameter(Position = 1, Mandatory, ValueFromPipeline)]
		[ValidateNotNull()]
		[System.String[]]
		$Value,
		[System.Management.Automation.SwitchParameter]
		$PassThru,
		[System.Management.Automation.SwitchParameter]
		$NoNewLine,
		[System.Management.Automation.SwitchParameter]
		$Force,
		[ArgumentCompleter([PSADTNXT.Text.NxtEncodingArgumentCompleter])]
		[PSADTNXT.Attributes.NxtEncodingTransformationAttribute()]
		[System.Text.Encoding]
		$Encoding
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if (-not $NoNewLine) { $Value += [System.String]::Empty }
			foreach ($file in (Resolve-NXTPath @PSBoundParameters -IncludeNonExistent -ProviderName 'FileSystem' -AsProviderPath -PathType Leaf)) {
				[System.Text.Encoding]$finalEncoding = if ($Encoding) { $Encoding } else { Get-NXTFileEncoding -Path $file -DefaultEncoding $PSCmdlet.SessionState.PSVariable.GetValue('OutputEncoding') -Force:$Force }
				if ($PSCmdlet.ShouldProcess($file, 'Add content')) {
					Write-ADTLogEntry -Message "Adding content to file [$file] using encoding [$($finalEncoding.EncodingName)]."
					if ($Force) {
						[System.IO.FileAttributes]$attributes = [System.IO.File]::GetAttributes($file)
						[System.IO.File]::SetAttributes($file, $attributes -bxor [System.IO.FileAttributes]::ReadOnly)
					}
					try {
						[System.IO.File]::AppendAllText($file, [System.String]::Join([System.Environment]::NewLine, @($Value)), $finalEncoding)
					}
					finally {
						if ($Force) { [System.IO.File]::SetAttributes($file, $attributes) }
					}
				}
			}
			if ($PassThru) { $PSCmdlet.WriteObject($Value) }
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
