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
	<#
		.SYNOPSIS
			Converts a comment-based help content to markdown
	#>
	Param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.Language.CommentHelpInfo]
		$HelpContent
	)

	[string]$markdownContent = [string]::Empty

	foreach ($section in $HelpContent.PSObject.Properties | Where-Object { $false -eq [string]::IsNullOrWhiteSpace($_.Value) }) {
		switch -Regex ($section.TypeNameOfValue) {
			'System.Collections.ObjectModel.ReadOnlyCollection' {
				$markdownContent += "## " + $section.Name + "`n"
				if ($section.Value.Count -eq 1) {
					$markdownContent += $section.Value[0] + "`n"
					break
				}
				[int]$index = 1
				foreach ($entry in $section.Value) {
					$markdownContent += "$index. $entry`n"
					$index++
				}
				break
			}
			'System.Collections.Generic.IDictionary' {
				$markdownContent += "## " + $section.Name + "`n"
				foreach ($entry in $section.Value.GetEnumerator()) {
					$markdownContent += "- **" + $entry.Key + "**: " + $entry.Value + "`n"
				}
				break
			}
			default {
				$markdownContent += '## ' + $section.Name + "`n" + $section.Value + "`n"
				break
			}
		}
	}

	return $markdownContent
}

try {
	[System.IO.FileInfo]$extensionFile = Get-ChildItem -Filter 'AppDeployToolkit\AppDeployToolkitExtensions.ps1' -Recurse -Depth 1 -Path "$PSScriptRoot\..\" -ErrorAction SilentlyContinue
	[System.Management.Automation.Language.ScriptBlockAst]$ast = [System.Management.Automation.Language.Parser]::ParseFile($extensionFile.FullName, [ref]$null, [ref]$null)
}
catch {
	Write-Warning 'AppDeployToolkitExtensions.ps1 not found, please place this script in the package directory'
	Read-Host -Prompt 'Press Enter to continue, CTRL+C to abort'
}

New-Item -Name 'wiki' -ItemType Directory -Force -ErrorAction SilentlyContinue

[System.Management.Automation.Language.FunctionDefinitionAst[]]$functionDefinitions = $ast.FindAll(
	{
		$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
	},
	$false
)

foreach ($functionDefinition in $functionDefinitions) {
	if ($null -ne $functionDefinition.GetHelpContent()) {
		Set-Content -Path "wiki\$($functionDefinition.Name).md" -Value (ConvertTo-Markdown -HelpContent $functionDefinition.GetHelpContent()) -Force
	}
}
