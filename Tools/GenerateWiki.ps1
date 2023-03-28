<#
.SYNOPSIS
	This script creates wiki md files based on the AppDeployToolkitExtensions.ps1
.DESCRIPTION
    Place this script file in "..\Toolkit\AppDeployToolkit\"
    and run with powershell. A wiki directory with md files will be created
.LINK
	https://neo42.de/psappdeploytoolkit
#>


function ConvertTo-Markdown {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    [string]$markdownContent = $Content
    [int]$firstParameterIndex = $markdownContent.IndexOf('.PARAMETER')
    if ($firstParameterIndex -ge 0) {
        $markdownContent = $markdownContent.Insert($firstParameterIndex, "## Parameters`n")
    }

    [int]$firstExampleIndex = $markdownContent.IndexOf('.EXAMPLE')
    if ($firstExampleIndex -ge 0) {
        $markdownContent = $markdownContent.Insert($firstExampleIndex, "## Examples`n")
    }

    [array]$markdownLines = $markdownContent -split "`n"
    [array]$markdownOutput = @()
    [int]$exampleCounter = 1

    foreach ($line in $markdownLines) {
        $line = $line.Trim()
        if ($line -match '\.DESCRIPTION') {
            $markdownOutput += '## Description'
        } elseif ($line -match '\.SYNOPSIS') {
            $markdownOutput += '## Synopsis'
        } elseif ($line -match '\.OUTPUTS') {
            $markdownOutput += '## Outputs'
        } elseif ($line -match '\.LINK') {
            $markdownOutput += '## Link'
        } elseif ($line -match '\.PARAMETER') {
            $markdownOutput += '### ' + ($line -replace '\.PARAMETER', '')
        } elseif ($line -match '\.EXAMPLE') {
            $markdownOutput += "### Example $exampleCounter"
            $exampleCounter++
        } else {
            $markdownOutput += $line -replace '<#', '' -replace '#>', ''
        }
    }

    return ($markdownOutput -join "`n").Trim()
}

[string]$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

if ($false -eq (Test-Path "$scriptDirectory\AppDeployToolkitExtensions.ps1")) {
    Write-Warning "AppDeployToolkitExtensions.ps1 not found, please place this script next to AppDeployToolkitExtensions.ps1"
    Read-Host -Prompt "Press Enter to continue, CTRL+C to abort"
}

[string]$scriptContent = Get-Content -Path "$scriptDirectory\AppDeployToolkitExtensions.ps1" -Raw
[System.Collections.Generic.List`1[System.Management.Automation.Language.Ast]]$ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$null, [ref]$null)

New-Item -Name "wiki" -ItemType Directory -Force -ErrorAction SilentlyContinue

[System.Management.Automation.Language.FunctionDefinitionAst]$functionDefinitions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
foreach ($functionDefinition in $functionDefinitions) {
    [string]$functionName = $functionDefinition.Name
    [string]$summaryBlockPattern = '(?s)<#(.*?)#>'
    [string]$summaryBlock = ([regex]::Matches($functionDefinition.Extent.Text, $summaryBlockPattern)).Value.Trim()

    if (-not [string]::IsNullOrEmpty($summaryBlock)) {
        [string]$markdownContent = ConvertTo-Markdown -Content $summaryBlock
        Set-Content -Path "wiki\$functionName.md" -Value $markdownContent -Force
    }
}
