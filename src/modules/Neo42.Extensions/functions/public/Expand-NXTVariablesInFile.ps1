function Expand-NXTVariablesInFile {
	<#
	.SYNOPSIS
	Expands different variable types in a given text file.
	.DESCRIPTION
	Designed to expand a variety of variable types present in a text file.
	The function is equipped to handle Windows style environment variables, PowerShell variables and PowerShell subexpression operators.
	Upon execution, the function will update the target file by replacing all variable references with their actual values.
	The file does not need to be a PowerShell script, but the function will only expand variables that are valid in PowerShell.
	.INPUTS
	System.String[] - The path to the file(s) to expand variables in.
	.PARAMETER Path
	The path to the file(s) to expand variables in.
	.PARAMETER LiteralPath
	The literal path to the file(s) to expand variables in.
	.PARAMETER Filter
	A filter to qualify the Path parameter.
	.PARAMETER Exclude
	A filter to exclude items from the Path parameter.
	.PARAMETER Include
	A filter to include items in the Path parameter.
	.PARAMETER Encoding
	The encoding to use when the file is created.
	.PARAMETER Force
	Determines if the Read-Only attribute should be ignored when setting the content of the file or hidden files should be processed.
	.EXAMPLE
	Expand-NXTVariablesInFile -Path 'C:\Temp\test.txt' -Variables @(Get-Variable 'MyVar1', 'MyVar2')

	Expands the variables in the file 'C:\Temp\test.txt' using the values of the PowerShell variables 'MyVar1' and 'MyVar2'.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Sub-calls handle ShouldProcess internally.')]
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

		[ArgumentCompleter([PSADTNXT.Text.NxtEncodingArgumentCompleter])]
		[PSADTNXT.Attributes.NxtEncodingTransformationAttribute()]
		[System.Text.Encoding]
		$Encoding,
		[System.Management.Automation.SwitchParameter]
		$Force
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Collections.Hashtable]$encodingSplat = if ($Encoding) { @{ Encoding = $Encoding } } else { @{} }
	}
	process {
		try {
			foreach ($file in (Resolve-NXTPath @PSBoundParameters -ProviderName 'FileSystem' -PathType Leaf)) {
				Write-ADTLogEntry -Message "Expanding PowerShell and environment variables in file [$file]."
				[System.String]$content = Get-NXTContent -LiteralPath $file @encodingSplat
				$content = [System.Environment]::ExpandEnvironmentVariables($content)

				[System.Management.Automation.ScriptBlock]$sb = [System.Management.Automation.ScriptBlock]::Create("`"$($content.Replace('`', '``').Replace('"', '`"'))`"")
				$sb.CheckRestrictedLanguage([System.String[]]@(), [System.String[]]@('*'), $true)

				$content = $ExecutionContext.InvokeCommand.InvokeScript(
					$PSCmdlet.SessionState,
					$sb.Ast.GetScriptBlock()
				)

				Set-NXTContent -LiteralPath $file -Value $content -Force:$Force @encodingSplat -NoNewLine
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
