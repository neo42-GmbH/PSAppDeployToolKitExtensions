param (
	[Parameter(Mandatory)]
	[System.IO.FileInfo[]]
	$FilePath
)

Describe 'PSADT Compatibility' {
	Context '<_.Name>' -ForEach $FilePath {
		BeforeAll {
			[System.Management.Automation.Language.ScriptBlockAst]$ast = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$null)
			[System.IO.FileInfo]$currentFile = $_
		}

		It 'Should find all types' {
			$ast.FindAll(
				{
					(
						(
							$args[0] -is [System.Management.Automation.Language.TypeExpressionAst] -or
							$args[0] -is [System.Management.Automation.Language.TypeConstraintAst]
						) -and
						$null -eq $args[0].TypeName.GetReflectionType()
					) -or
					(
						$args[0] -is [System.Management.Automation.Language.AttributeAst] -and
						$null -eq $args[0].TypeName.GetReflectionAttributeType()
					)
				},
				$true
			) | Should -BeNullOrEmpty -Because 'all types must be defined'
		}

		It 'Shound find all type members' {
			$ast.FindAll(
				{
					$args[0] -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -and
					$args[0].Static -and
					$args[0].Expression -is [System.Management.Automation.Language.TypeExpressionAst] -and
					$args[0].Member.Value -ne 'new'
				},
				$true
			) | ForEach-Object {
				[System.Type]$type = $_.Expression.TypeName.GetReflectionType()
				$type.GetMember($_.Member.Value) | Should -Not -BeNullOrEmpty -Because "$($_.Member.Value) must be a member of [$type] $($currentFile.FullName):$($_.Extent.StartLineNumber)"
			}
		}

		It 'Should be able to bind all commands' {
			$ast.FindAll(
				{
					$args[0] -is [System.Management.Automation.Language.CommandAst] -and
					-not [System.String]::IsNullOrWhitespace($args[0].GetCommandName()) -and # We can only resolve non dynamic commands
					$args[0].Parent -isnot [System.Management.Automation.Language.PipelineAst] -and # We cannot resolve pipeline input
					-not ($args[0].Find({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and $args[0].Splatted }, $false)) # We cannot resolve splatting
				},
				$true
			) | ForEach-Object {
				{
					[System.Management.Automation.Language.CommandAst]$ast = $_
					[System.Management.Automation.Language.StaticBindingResult]$binding = [System.Management.Automation.Language.StaticParameterBinder]::BindCommand($ast, $true)
					$binding | Should -Not -BeNullOrEmpty -Because "the command must be bindable/exist ($($currentFile.FullName):$($_.Extent.StartLineNumber))"

					[System.Management.Automation.Language.StaticBindingError[]]$errors = $binding.BindingExceptions.Values
					if ($errors) {
						if (([System.Management.Automation.CommandInfo]$commandInfo = Get-Command -Name $ast.GetCommandName() -ErrorAction Ignore)) {
							[System.String[]]$dynamicParams = $commandInfo.Parameters.GetEnumerator() | Where-Object { $_.Value.IsDynamic } | Select-Object -ExpandProperty 'Key'
							$errors = $errors | Where-Object {
								$_.CommandElement.Extent.Text.TrimStart('-') -notin $dynamicParams
							}
						}
						foreach ($exception in $errors) { Write-Host -ForegroundColor Red "$($exception.CommandElement) - $($exception.BindingException.Message)" }
						$errors | Should -BeNullOrEmpty -Because "all parameters used must exist ($($currentFile.FullName):$($_.Extent.StartLineNumber))"
					}
				} | Should -Not -Throw -Because "the command must be bindable/exist ($($currentFile.FullName):$($_.Extent.StartLineNumber))"
			}
		}

		It 'Should find all commands in the command table' {
			[System.Collections.Generic.IReadOnlyDictionary[System.String, System.Management.Automation.CommandInfo]]$commandTable = Get-NXTCommandTable
			$ast.FindAll(
				{
					$args[0] -is [System.Management.Automation.Language.CommandAst] -and
					-not [System.String]::IsNullOrWhitespace(([System.String]$name = $args[0].GetCommandName())) -and
					$name -notlike '*-NXT*' # Extension module functions are not available in the table
				},
				$true
			) | ForEach-Object {
				[System.String]$name = $_.GetCommandName()
				$commandTable[$name] | Should -Not -BeNullOrEmpty -Because "only commands exported in the command table are allowed ($name - $($currentFile.FullName):$($_.Extent.StartLineNumber))"
			}
		}

		It 'Should match coding guidelines' {
			Invoke-ScriptAnalyzer -Path $currentFile.FullName `
				-Settings "$PSScriptRoot\..\analyzer\guidelines\PSScriptAnalyzerSettings.psd1" `
				-CustomRulePath "$PSScriptRoot\..\analyzer\guidelines\neo42PSScriptAnalyzerRules.psm1" |
				Should -BeNullOrEmpty
		}
	}
}
