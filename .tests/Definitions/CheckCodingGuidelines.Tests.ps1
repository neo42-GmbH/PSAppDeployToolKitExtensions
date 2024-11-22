BeforeAll {
	[System.IO.FileInfo]$analyzerRulePath = (Get-Content -Path "$PSScriptRoot\..\.vscode\settings.json" -Raw | ConvertFrom-Json).powershell.scriptAnalysis.settingsPath
}

Describe "Coding Guidelines" -ForEach @(
	@{path = "$global:PSADTPath\Deploy-Application.ps1" },
	@{path = "$global:PSADTPath\AppDeployToolkit\AppDeployToolkitExtensions.ps1" },
	@{path = "$global:PSADTPath\AppDeployToolkit\CustomAppDeployToolkitUi.ps1" }
) {
	Context "$(Split-Path $path -Leaf)" {
		It "Should have a valid syntax" {
			$errors = Invoke-ScriptAnalyzer -Path $path -CustomRulePath $analyzerRulePath -Severity Information
			$errors | Should -BeNullOrEmpty
		}
	}
}
