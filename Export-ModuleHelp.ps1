<#
.SYNOPSIS
Creates the markdown documentation for the functions in a PowerShell module.
.NOTES
Style is adopted from Microsoft's PowerShell documentation
.LINK
https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core
#>
param (
	[ValidateNotNullOrEmpty()]
	[System.IO.DirectoryInfo]
	$Module = "$($PWD.Path)\build\PSAppDeployToolkit.Neo42.Extensions",
	[System.IO.DirectoryInfo[]]
	$RequiredModules = @("$($PWD.Path)\build\PSAppDeployToolkit"),
	[System.IO.FileInfo]
	$OutputFile = "$PWD\docs\$($Module.BaseName).Functions.md"
)

function Format-TypeName {
	<#
	.SYNOPSIS
	Helper function that outputs a friendly type name for a given type including generic arguments.
	#>
	param (
		[System.Type]
		$Type
	)

	[System.Text.StringBuilder]$sb = [System.Text.StringBuilder]::new()
	$null = $sb.Append($Type.Name.Split('`')[0]) # Remove generic argument count

	if ($Type.IsGenericType) {
		$null = $sb.Append('[')
		[System.Collections.Generic.List[System.String]]$genericArgs = [System.Collections.Generic.List[System.String]]::new()
		foreach ($arg in $Type.GetGenericArguments()) {
			if ($arg.IsGenericParameter) {
				$genericArgs.Add($arg.Name)
			}
			else {
				$genericArgs.Add((Format-TypeName -Type $arg))
			}
		}
		$null = $sb.Append([System.String]::Join(', ', $genericArgs))
		$null = $sb.Append(']')
	}

	return $sb.ToString()
}

if (-not $OutputFile.Directory.Exists) { $null = $OutputFile.Directory.Create() }

# Types are required for parameter type information
if ($RequiredModules) {
	Import-Module -Name $RequiredModules -Force
}
[System.Management.Automation.PSModuleInfo]$moduleInfo = Import-Module -Name $Module.FullName -Force -PassThru

#MARK: Read functions
[System.Management.Automation.FunctionInfo[]]$publicFunctions = $moduleInfo.ExportedFunctions.Values | Sort-Object -Property Name

# Generate the function documentation
[System.Text.StringBuilder]$functionMd = [System.Text.StringBuilder]::new("% Functions in $($moduleInfo.Name) module")
$null = $functionMd.AppendLine()
$null = $functionMd.AppendLine()
foreach ($functionInfo in $publicFunctions) {
	[System.Management.Automation.Language.CommentHelpInfo]$helpInfo = $functionInfo.ScriptBlock.Ast.GetHelpContent()

	# MARK: Function Header
	$null = $functionMd.AppendLine("## $($functionInfo.Name)")
	$null = $functionMd.AppendLine()
	$null = $functionMd.AppendLine($helpInfo.Synopsis)

	# MARK: Function Syntax
	$null = $functionMd.AppendLine('### SYNTAX')
	$null = $functionMd.AppendLine()
	$functionInfo.ParameterSets | ForEach-Object {
		if (-not $_) { return }
		$null = $functionMd.AppendLine('```PowerShell')
		if ($_.Name -ne '__AllParameterSets') {
			$null = $functionMd.AppendLine("# ParameterSet $($_.Name)")
		}
		$null = $functionMd.AppendLine($functionInfo.Name) # The first part is the function name
		[System.String[]]$syntaxParts = $_.ToString().Split(' ')
		for ([System.Int32]$setIdx = 0; $setIdx -lt $syntaxParts.Count; $setIdx++) {
			$null = $functionMd.Append("    $($syntaxParts[$setIdx])")
			if ($syntaxParts[$setIdx + 1] -and $syntaxParts[$setIdx + 1] -notmatch '^(-|\[)') {
				$null = $functionMd.AppendLine(" $($syntaxParts[$setIdx + 1])")
				$setIdx++ # Skip the next part since it is a continuation of the current line
			}
			else {
				$null = $functionMd.AppendLine()
			}
		}
		$null = $functionMd.AppendLine('```')
		$null = $functionMd.AppendLine()
	}

	# MARK: Function Description
	$null = $functionMd.AppendLine('### DESCRIPTION')
	$null = $functionMd.AppendLine()
	$null = $functionMd.AppendLine($helpInfo.Description)

	# MARK: Function Notes
	if (-not [System.String]::IsNullOrWhiteSpace($helpInfo.Notes)) {
		$null = $functionMd.AppendLine('> **NOTE**')
		$null = $functionMd.AppendLine('>')
		foreach ($line in $helpInfo.Notes.Split("`n")) {
			$null = $functionMd.AppendLine("> $($line.Trim())")
		}
	}

	# MARK: Function Examples
	if ($helpInfo.Examples.Count -gt 0) {
		$null = $functionMd.AppendLine('### EXAMPLES')
		for ([System.Int32]$exampleIdx = 0; $exampleIdx -lt $helpInfo.Examples.Count; $exampleIdx++) {
			$null = $functionMd.AppendLine()
			$null = $functionMd.AppendLine("#### Example $($exampleIdx + 1)")
			$null = $functionMd.AppendLine()
			[System.String[]]$exampleParts = $helpInfo.Examples[$exampleIdx].Split("`n")
			$null = $functionMd.AppendLine('```PowerShell')
			$null = $functionMd.AppendLine($exampleParts[0])
			$null = $functionMd.AppendLine('```')
			$null = $functionMd.Append([System.String]::Join([System.Environment]::NewLine, $exampleParts[1..($exampleParts.Count - 1)]))
		}
	}

	# MARK: Function Input and Output
	$null = $functionMd.AppendLine('### INPUTS')
	$null = $functionMd.AppendLine()
	if (-not [System.String]::IsNullOrWhiteSpace($helpInfo.Inputs)) {
		$null = $functionMd.AppendLine($helpInfo.Inputs)
	}
	else {
		if (
			$functionInfo.Parameters.Count -eq 0 -or
			$true -notcontains $functionInfo.Parameters.Value.Attributes.ValueFromPipeline
		) {
			$null = $functionMd.AppendLine('**This function does not take any pipeline input.**')
			$null = $functionMd.AppendLine()
		}
		else {
			@($functionInfo.Parameters.GetEnumerator()) | Where-Object { $true -eq $_.Value.Attributes.ValueFromPipeline } | ForEach-Object {
				$null = $functionMd.AppendLine("``[$(Format-TypeName $_.Value.ParameterType)]``")
			}
		}
	}

	$null = $functionMd.AppendLine('### OUTPUTS')
	$null = $functionMd.AppendLine()
	if (-not [System.String]::IsNullOrWhiteSpace($helpInfo.Outputs)) {
		$null = $functionMd.AppendLine($helpInfo.Outputs)
	}
	else {
		if ($functionInfo.OutputType.Count -eq 0) {
			$null = $functionMd.AppendLine('**This function does not return any output.**')
			$null = $functionMd.AppendLine()
		}
		else {
			@($functionInfo.OutputType) | ForEach-Object {
				$null = $functionMd.AppendLine("``[$($_.Name)]``")
			}
		}
	}

	# MARK: Function Parameters
	$null = $functionMd.AppendLine('### PARAMETERS')
	$null = $functionMd.AppendLine()
	if ($null -eq $functionInfo.Parameters -or $helpInfo.Parameters.Count -eq 0) {
		$null = $functionMd.AppendLine('**This function does not have any documented parameters.**')
	}
	else {
		foreach ($parameterHelpInfo in @($helpInfo.Parameters.GetEnumerator())) {
			[System.Management.Automation.ParameterMetadata]$parameterMetadata = $functionInfo.Parameters[$parameterHelpInfo.Key]
			if (-not $parameterMetadata) {
				Write-Error "Parameter '$($parameterHelpInfo.Key)' not found in function '$($functionInfo.Name)'. Skipping."
				continue
			}
			[System.Management.Automation.Language.ParameterAst]$parameterBlockAst = $functionInfo.ScriptBlock.Ast.Body.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq $parameterHelpInfo.Key }
			[System.Management.Automation.PSDefaultValueAttribute]$parameterDefaultValueAttribute = $parameterMetadata.Attributes | Where-Object { $_.TypeId.Name -eq 'PSDefaultValueAttribute' } | Select-Object -First 1
			[System.String[]]$hasPipelineInput = $(
				if ($true -in $parameterMetadata.Attributes.ValueFromPipeline) { 'ByValue' }
				if ($true -in $parameterMetadata.Attributes.ValueFromPipelineByPropertyName) { 'ByPropertyName' }
				if ($true -in $parameterMetadata.Attributes.ValueFromRemainingArguments) { 'ByRemainingArguments' }
			)

			[System.String]$defaultValueString = if ($parameterBlockAst.DefaultValue -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
				$parameterBlockAst.DefaultValue.Value
			}
			else {
				$parameterBlockAst.DefaultValue.Extent.Text
			}

			if ($null -ne $parameterDefaultValueAttribute.Value) { $defaultValueString = $parameterDefaultValueAttribute.Value }
			if ($null -ne $parameterDefaultValueAttribute.Help) { $defaultValueString += " - $($parameterDefaultValueAttribute.Help)" }
			$defaultValueString = $defaultValueString -replace '^\s*$', 'None'

			[System.String]$position = $parameterMetadata.Attributes.Position | Where-Object { $_ -ne -2147483648 } | Sort-Object -Unique | Select-Object -First 1
			if (-not $position) { $position = 'Named' }

			$null = $functionMd.AppendLine("#### -$($parameterMetadata.Name)")
			$null = $functionMd.AppendLine()
			$null = $functionMd.AppendLine($parameterHelpInfo.Value)
			$null = $functionMd.AppendLine('|Property|Value|')
			$null = $functionMd.AppendLine('|:---|:---|')
			$null = $functionMd.AppendLine("|Type:|$(Format-TypeName $parameterMetadata.ParameterType)|")
			[System.Type]$enumType = if ($parameterMetadata.ParameterType.IsEnum) {
				$parameterMetadata.ParameterType
			}
			elseif ($parameterMetadata.ParameterType.IsArray -and $parameterMetadata.ParameterType.GetElementType().IsEnum) {
				$parameterMetadata.ParameterType.GetElementType()
			}
			if ($enumType) {
				$null = $functionMd.AppendLine("|Enum values:|$([System.String]::Join(', ', [System.Enum]::GetNames($enumType)))|")
			}
			$null = $functionMd.AppendLine("|Position:|$position|")
			$null = $functionMd.AppendLine("|Default value:|$defaultValueString|")
			$null = $functionMd.AppendLine("|Required:|$($true -in $parameterMetadata.Attributes.Mandatory)|")
			$null = $functionMd.AppendLine("|Accept pipeline input:|$($hasPipelineInput.Count -gt 0)$(if ($hasPipelineInput.Count -gt 0) { ' (' + ($hasPipelineInput -join ', ') + ')' })|")
			$null = $functionMd.AppendLine("|Accept wildcard characters:|$('SupportsWildcardsAttribute' -in $parameterMetadata.Attributes.TypeId.Name)|")
			$null = $functionMd.AppendLine()
		}
	}

	# MARK: Function Related Links
	if ($null -ne $helpInfo.Links -and $helpInfo.Links.Count -gt 0) {
		$null = $functionMd.AppendLine('### RELATED LINKS')
		$null = $functionMd.AppendLine()
		$helpInfo.Links | ForEach-Object { $null = $functionMd.AppendLine($_) }
	}
}
Set-Content -Path $OutputFile.FullName -Value $functionMd.ToString() -Encoding UTF8
