# Check if we are in the Definitions folder. Pester tests via PesterTestsStarter.ps1 are executed from the root folder
$baseDir = Split-Path -Path (Resolve-Path $MyInvocation.MyCommand.Definition) -Parent
if ((Split-Path $baseDir -Leaf) -eq 'Definitions') {
	$baseDir = Resolve-Path "$baseDir\..\..\"
}

Describe 'Coding Guidelines' -ForEach @(
	@{path = "$baseDir\Deploy-Application.ps1" },
	@{path = "$baseDir\AppDeployToolkit\AppDeployToolkitExtensions.ps1" },
	@{path = "$baseDir\AppDeployToolkit\CustomAppDeployToolkitUi.ps1" }
) {
	Context "$(Split-Path $path -Leaf)" {
		BeforeAll {
			$tokens = $errors = $null
			[string[]]$content = Get-Content -Path "$path"
			[string]$contentRaw = Get-Content -Path "$path" -Raw
			[System.Management.Automation.Language.Ast]$ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
		}
		It 'AST should have no errors' {
			$errors | Should -BeNullOrEmpty
		}
		It 'Calls of functions should have params with package config defaults set explicitly' -Skip {
			if ($(Split-Path $path -Leaf) -ne 'AppDeployToolkitExtensions.ps1') {
				Set-ItResult -Skipped -Because "the file '$($path)' is excluded from this test"
				return
			}
			[System.Management.Automation.Language.FunctionDefinitionAst[]]$extensionFunctions = $ast.FindAll({
					$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
				}, $true)
			[System.Management.Automation.Language.CommandAst[]]$commandCallsAsts = $ast.FindAll({
					Param($ast)
					$ast -is [System.Management.Automation.Language.CommandAst] -and
					$ast.GetCommandName() -in $extensionFunctions.Name -and
					$ast.GetCommandName() -notin @('Write-Log', 'Exit-NxtScriptWithError', 'Set-NxtPackageArchitecture', 'Expand-NxtPackageConfig', 'Show-NxtWelcomePrompt')
				}, $true)
			foreach ($commandAst in $commandCallsAsts) {
				[System.Management.Automation.Language.FunctionDefinitionAst]$calledFunction = $extensionFunctions | Where-Object { $_.Name -eq $commandAst.GetCommandName() }
				[System.Management.Automation.Language.ParameterAst[]]$calledFunctionRequiredParameters = $calledFunction.Body.ParamBlock.Parameters | Where-Object {
					$null -ne $_.DefaultValue -and
					$_.DefaultValue.ToString().Contains('PackageConfig') -and
					$_.Name.VariablePath.UserPath -notin @('DisableLogging')
				}
				foreach ($parameterAst in $calledFunctionRequiredParameters) {
					if ($true -in $commandAst.CommandElements.Splatted) {
						#TODO resolve splatting
						Write-Warning "function '$($calledFunction.Name)' is called with splatting. Cannot check if it contains all required parameters. (line $($commandAst.Extent.StartLineNumber))"
					}
					else {
						$commandAst.CommandElements.ParameterName | Should -Contain $parameterAst.Name.VariablePath.UserPath -Because "the parameter '$($parameterAst.Name.VariablePath.UserPath)' of function '$($calledFunction.Name)' has default value but is not set explicitly (line $($commandAst.Extent.StartLineNumber))"
					}
				}
			}
		}
		It 'Write-Log should be used with the Source parameter' -Skip {
			$writeLogCommands = $ast.FindAll({
					Param($ast)
					$ast -is [System.Management.Automation.Language.CommandAst] -and
					$ast.GetCommandName() -eq 'Write-Log'
				}, $true)
			$writeLogCommands | ForEach-Object {
				$command = $_
				$command.CommandElements | Where-Object { $_.ParameterName -eq 'Source' } | Should -Not -BeNullOrEmpty -Because "Write-Log should be used with the Source parameter (line $($command.Extent.StartLineNumber))"
			}
		}
		It 'Should have no detected issues by PSScriptAnalyzer' {
			Invoke-ScriptAnalyzer -Path $path -Settings "$baseDir\.vscode\PSScriptAnalyzerSettings.psd1" | Should -BeNullOrEmpty
		}
	}
}


