param (
	[Parameter(Mandatory)]
	[System.IO.DirectoryInfo[]]
	$Source,
	[Parameter()]
	[System.IO.DirectoryInfo]
	$Output = "$($PWD.Path)\build"
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 3.0
$OutputEncoding = [System.Text.Encoding]::UTF8

foreach($sourceItem in $Source) {
	# Files
	[System.IO.FileInfo]$manifest = Join-Path -Path $Output.FullName -ChildPath "PSAppDeployToolkit.$($sourceItem.Name)\PSAppDeployToolkit.$($sourceItem.Name).psd1"
	[System.IO.FileInfo]$manifestSource = Join-Path -Path $sourceItem.FullName -ChildPath "PSAppDeployToolkit.$($sourceItem.Name).psd1"
	[System.IO.FileInfo]$module = Join-Path -Path $Output.FullName -ChildPath "PSAppDeployToolkit.$($sourceItem.Name)\PSAppDeployToolkit.$($sourceItem.Name).psm1"
	[System.IO.FileInfo]$typesFile = Join-Path -Path $sourceItem.FullName -ChildPath "PSAppDeployToolkit.$($sourceItem.Name).Types.ps1xml"
	[System.IO.DirectoryInfo]$privateFunctionDirectory = Join-Path -Path $sourceItem.FullName -ChildPath 'functions/private'
	[System.IO.DirectoryInfo]$publicFunctionDirectory = Join-Path -Path $sourceItem.FullName -ChildPath 'functions/public'
	[System.IO.FileInfo[]]$privateFunctions = if ($privateFunctionDirectory.Exists) { $privateFunctionDirectory.GetFiles('*.ps1') } else { @() }
	[System.IO.FileInfo[]]$publicFunctions = if ($publicFunctionDirectory.Exists) { $publicFunctionDirectory.GetFiles('*.ps1') } else { @() }
	[System.IO.FileInfo]$header = Join-Path -Path $sourceItem.FullName -ChildPath 'ModuleHeader.ps1'
	[System.IO.FileInfo]$footer = Join-Path -Path $sourceItem.FullName -ChildPath 'ModuleFooter.ps1'
	[System.IO.DirectoryInfo]$extraFiles = Join-Path -Path $sourceItem.FullName -ChildPath 'files'

	$null = New-Item -Path $manifest.Directory.FullName -ItemType Directory -Force

	if ($privateFunctions) {
		$privateFunctionAsts = $privateFunctions | ForEach-Object {
			[System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$null).FindAll({
					$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
				}, $false)
		} | Sort-Object -Property Name
	}
	if ($publicFunctions) {
		$publicFunctionAsts = $publicFunctions | ForEach-Object {
			[System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$null).FindAll({
					$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
				}, $false)
		} | Sort-Object -Property Name
		$publicFunctionAliases = $publicFunctionAsts | Where-Object { $_.Body.ParamBlock } | ForEach-Object {
			$_.Body.ParamBlock.Attributes | Where-Object { $_.TypeName.Name -eq 'Alias' } | ForEach-Object {
				$_.PositionalArguments.Value
			}
		} | Sort-Object
	}


	# PSM1 File
	[System.Text.StringBuilder]$moduleContent = [System.Text.StringBuilder]::new([System.String]::Empty)
	$null = $moduleContent.AppendLine((Get-Content -Raw -Path $header.FullName))
	if ($publicFunctions) {
		$null = $moduleContent.AppendLine('#region Function Definitions
##########################
# MARK: Public Functions #
##########################
')
		$publicFunctionAsts | ForEach-Object {
			$null = $moduleContent.AppendLine("#region $($_.Name)")
			$null = $moduleContent.AppendLine($_.Extent.Text)
			$null = $moduleContent.AppendLine("#endregion $($_.Name)")
		}
	}
	if ($privateFunctions) {
		$null = $moduleContent.AppendLine('
###########################
# MARK: Private Functions #
###########################
')
		$privateFunctionAsts | ForEach-Object {
			$null = $moduleContent.AppendLine("#region $($_.Name)")
			$null = $moduleContent.AppendLine($_.Extent.Text)
			$null = $moduleContent.AppendLine("#endregion $($_.Name)")
		}
		$null = $moduleContent.AppendLine("#endregion Function Definitions`r`n")
	}
	$null = $moduleContent.Append((Get-Content -Raw -Path $footer.FullName))

	# Search all command invocations and replace them with command table entries
	$moduleAst = [System.Management.Automation.Language.Parser]::ParseInput($moduleContent.ToString(), [ref]$null, [ref]$null)
	$commandAsts = $moduleAst.FindAll({
			$args[0] -is [System.Management.Automation.Language.CommandAst] -and
			$args[0].InvocationOperator.Equals([System.Management.Automation.Language.TokenKind]::Unknown)
		},
		$true
	)

	# Replace all command invocations with command table entries
	$commandAsts |
		ForEach-Object {
			$_.CommandElements[0].Extent
		} |
		Sort-Object -Property EndOffset -Descending |
		ForEach-Object {
			$null = $moduleContent.Remove($_.StartOffset, $_.EndOffset - $_.StartOffset)
			$null = $moduleContent.Insert($_.StartOffset, "& `$script:CommandTable.'$($_.Text)'")
		}

	# Export module
	Set-Content -Path $module.FullName -Value $moduleContent.ToString() -NoNewline

	#Test the module
	$parserErrors = @()
	$null = [System.Management.Automation.Language.Parser]::ParseFile($module.FullName, [ref]$null, [ref]$parserErrors)
	if ($parserErrors.Count -gt 0) {
		foreach ($parserError in $parserErrors) {
			Write-Error "L.$($parserError.Extent.StartLineNumber): $($parserError.Message)"
		}
		throw "There are parser errors in module $($module.Name)"
	}

	# PSD1 File
	$manifestAst = [System.Management.Automation.Language.Parser]::ParseFile($manifestSource.FullName, [ref]$null, [ref]$null)
	[System.String]$manifestContent = $manifestAst.Extent.Text

	if ($publicFunctions) {
		$aliasArrayText = "@($([System.Environment]::NewLine)`t`t'" + ($publicFunctionAliases -join "',$([System.Environment]::NewLine)`t`t'") + "'$([System.Environment]::NewLine)`t)"
		$aliasesToExportAst = $manifestAst.EndBlock.Statements.PipelineElements.Expression.KeyValuePairs | Where-Object { $_.Item1.Value -eq 'AliasesToExport' }
		$manifestContent = $manifestContent.Remove($aliasesToExportAst.Item2.Extent.StartOffset, $aliasesToExportAst.Item2.Extent.EndOffset - $aliasesToExportAst.Item2.Extent.StartOffset)
		$manifestContent = $manifestContent.Insert($aliasesToExportAst.Item2.Extent.StartOffset, $aliasArrayText)

		$functionArrayText = "@($([System.Environment]::NewLine)`t`t'" + ($publicFunctionAsts.Name -join "',$([System.Environment]::NewLine)`t`t'") + "'$([System.Environment]::NewLine)`t)"
		$functionsToExportAst = $manifestAst.EndBlock.Statements.PipelineElements.Expression.KeyValuePairs | Where-Object { $_.Item1.Value -eq 'FunctionsToExport' }
		$manifestContent = $manifestContent.Remove($functionsToExportAst.Item2.Extent.StartOffset, $functionsToExportAst.Item2.Extent.EndOffset - $functionsToExportAst.Item2.Extent.StartOffset)
		$manifestContent = $manifestContent.Insert($functionsToExportAst.Item2.Extent.StartOffset, $functionArrayText)
	}

	# Export module
	Set-Content -Path $manifest.FullName -Value $manifestContent -NoNewline

	#Test the module
	$null = [System.Management.Automation.Language.Parser]::ParseFile($manifest.FullName, [ref]$null, [ref]$parserErrors)
	if ($parserErrors.Count -gt 0) {
		foreach ($parserError in $parserErrors) {
			Write-Error ($parserError | ConvertTo-Json -Depth 1 -Compress)
		}
		throw 'There are parser errors in the module.'
	}

	# Copy extra files
	if ($extraFiles.Exists) {
		Copy-Item -Path "$($extraFiles.FullName)/*" -Destination $manifest.Directory.FullName -Recurse -Force
	}
	if ($typesFile.Exists) {
		Copy-Item -Path $typesFile.FullName -Destination $manifest.Directory.FullName -Force
	}
}
