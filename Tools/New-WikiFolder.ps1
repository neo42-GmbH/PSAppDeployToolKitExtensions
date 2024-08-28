<#
    .SYNOPSIS
        This script creates wiki md files based on the AppDeployToolkitExtensions.ps1
    .DESCRIPTION
        Place this script file in "AppDeployToolkit\"
        and run with powershell. A wiki directory with md files will be created
    .NOTES
        # LICENSE #
        This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
        You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

        # COPYRIGHT #
        Copyright (c) 2024 neo42 GmbH, Germany.
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
[psobject]$ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$null, [ref]$null)

New-Item -Name "wiki" -ItemType Directory -Force -ErrorAction SilentlyContinue

[psobject]$functionDefinitions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
foreach ($functionDefinition in $functionDefinitions) {
    [string]$functionName = $functionDefinition.Name
    [string]$summaryBlockPattern = '(?s)<#(.*?)#>'
    [string]$summaryBlock = ([regex]::Matches($functionDefinition.Extent.Text, $summaryBlockPattern)).Value.Trim()

    if (-not [string]::IsNullOrEmpty($summaryBlock)) {
        [string]$markdownContent = ConvertTo-Markdown -Content $summaryBlock
        Set-Content -Path "wiki\$functionName.md" -Value $markdownContent -Force
    }
}
