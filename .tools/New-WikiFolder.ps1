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
function ConvertTo-CommentHelpToMarkdown {
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
	[string[]]$exportedSectionsInOrder = @(
		'SYNOPSIS',
		'DESCRIPTION',
		'PARAMETERS',
		'INPUTS',
		'OUTPUTS',
		'NOTES',
		'EXAMPLES',
		'LINKS'
	)
	[object[]]$sections = @($HelpContent.PSObject.Properties.GetEnumerator()) | Where-Object {
		$null -ne $_.Value -and
		$true -eq $exportedSectionsInOrder.Contains($_.Name.ToUpper())
	} | Sort-Object {
		$exportedSectionsInOrder.IndexOf($_.Name.ToUpper())
	}

	foreach ($section in $sections) {
		$markdownContent += '## ' + $section.Name + "`n"

		switch -Regex ($section.TypeNameOfValue) {
			# Case for multiple entries without key (e.g. EXAMPLE)
			'System.Collections.ObjectModel.ReadOnlyCollection' {
				# Let the default case handle single entries
				if ($section.Value.Count -eq 1) {
					continue
				}
				for ($index = 1; $index -le $section.Value.Count; $index++) {
					[int]$indentation = $index.ToString().Length + 2
					[string[]]$contentLines = $section.Value[$index - 1].Split("`n") | Select-Object -SkipLast 1
					[string]$content = $contentLines[0] + "`n"
					$contentLines | Select-Object -Skip 1 | ForEach-Object {
						if ($true -eq [string]::IsNullOrWhiteSpace($_)) {
							$content += "`n"
						}
						else {
							$content += (' ' * $indentation) + $_ + "`n"
						}
					}
					$markdownContent += "$index. $content`n`n"
				}
				break
			}
			# Case for named entries (e.g. PARAMETER)
			'System.Collections.Generic.IDictionary' {
				foreach ($entry in $section.Value.GetEnumerator()) {
					[string[]]$contentLines = $entry.Value.Split("`n") | Select-Object -SkipLast 1
					[string]$content = [string]::Empty
					$contentLines | ForEach-Object {
						if ($true -eq [string]::IsNullOrWhiteSpace($_)) {
							$content += "`n"
						}
						else {
							$content += '  ' + $_ + "`n"
						}
					}
					$markdownContent += "- **$($entry.Key)**`n`n$content`n`n"
				}
				break
			}
			# Default case for single entries
			default {
				$markdownContent += $section.Value + "`n"
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
