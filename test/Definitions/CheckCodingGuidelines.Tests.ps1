Describe "Codeing Guidelines" -ForEach @(
    @{path = (Resolve-Path -Path "$PSScriptRoot\..\..\Deploy-Application.ps1") },
    @{path = (Resolve-Path -Path "$PSScriptRoot\..\..\AppDeployToolkit\AppDeployToolkitExtensions.ps1") },
    @{path = (Resolve-Path -Path "$PSScriptRoot\..\..\AppDeployToolkit\CustomAppDeployToolkitUi.ps1") }
) {
    Context "$(Split-Path $path -Leaf)" {
        BeforeAll {
            [string[]]$content = Get-Content -Path "$path"
            [System.Management.Automation.Language.Ast]$ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$null)
        }
        It "Should have the correct capaitalization on statements" {
            $statements = $ast.FindAll({ param($ast)
                (
                    $ast -is [System.Management.Automation.Language.FunctionDefinitionAst] -or
                    $ast -is [System.Management.Automation.Language.StatementAst] -or
                    $ast -is [System.Management.Automation.Language.NamedBlockAst]
                ) -and
                $true -ne $ast.Unnamed
            }, $true)
            $spelling = @('function', 'if', 'else', 'elseif', 'foreach', 'for', 'while', 'switch', 'try', 'catch', 'finally', 'return', 'break', 'continue', 'throw', 'exit', 'Process', 'Begin', 'End', 'Param')
            $statements | ForEach-Object {
                $text = $_.Extent.Text -split "`n" | Select-Object -First 1
                $spelling | ForEach-Object {
                    if ($text -imatch "^\s*$_(?!\-)\b") {
                        $text | Should -MatchExactly "^\s*$_" -Because "the statement '$_' is not capitalized correctly (line $currentLine)"
                    }
                }
            }
        }
        It "Parameter variables should be capitalized" {
            $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
            $functions | ForEach-Object {
                $functionAst = $_
                $paramBlockAst = $functionAst.Body.ParamBlock
                if ($null -eq $paramBlockAst) { return }
                $paramBlockAst.Parameters | ForEach-Object {
                    $parameterAst = $_
                    $parameterAst.Name.VariablePath.UserPath | Should -MatchExactly '^[A-Z]' -Because "the parameter variable '$($parameterAst.Name.VariablePath.UserPath)' is not capitalized correctly (line $($parameterAst.Extent.StartLineNumber))"
                }
            }
        }
        It "Parameter variables should be typed" {
            $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
            $functions | ForEach-Object {
                $functionAst = $_
                $paramBlockAst = $functionAst.Body.ParamBlock
                if ($null -eq $paramBlockAst) { return }
                $paramBlockAst.Parameters | ForEach-Object {
                    $parameterAst = $_
                    $parameterAst.StaticType | Should -Not -Be 'System.Object' -Because "the parameter variable '$($parameterAst.Name.VariablePath.UserPath)' is not typed (line $($parameterAst.Extent.StartLineNumber))"
                }
            }
        }
        It "Intendations should be made using tabulator" {
            $currentLine = 1
            $content | ForEach-Object {
                $_ | Should -Match "^(?! +)" -Because "the line is not tab indented (line $currentLine)"
                $currentLine++
            }
        }
        It "At line endings there should not be trailing whitespaces" {
            $currentLine = 1
            $content | ForEach-Object {
                $_ | Should -Not -Match "\s+$" -Because "the line has trailing whitespace (line $currentLine)"
                $currentLine++
            }
        }
        It "There should be exactly one whitespace between parameter and scriptblock" {
            $currentLine = 1
            $content | ForEach-Object {
                if ($_ -imatch "\)\s*\{") {
                    $_ | Should -Match "\)\s\{" -Because "the parentheses spacing is not correct (line $currentLine)"
                }
                $currentLine++
            }
            
        }
        It "Every function should be described properly" {
            $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
            $functions | ForEach-Object {
                $help = $_.GetHelpContent()
                $help | Should -Not -BeNullOrEmpty -Because "the function '$($_.Name)' should have a synopsis (line $($_.Extent.StartLineNumber)))"
                $help.Synopsis | Should -Not -BeNullOrEmpty -Because "the function '$($_.Name)' should have a synopsis (line $($_.Extent.StartLineNumber)))"
                $help.Description | Should -Not -BeNullOrEmpty -Because "the function '$($_.Name)' should have a description (line $($_.Extent.StartLineNumber))"
                $help.Outputs | Should -Not -BeNullOrEmpty -Because "the function '$($_.Name)' should specify its output (line $($_.Extent.StartLineNumber))"
            }
        }
        It "The variable definitions should be seperated by new lines in param block" {
            $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
            $functions | ForEach-Object {
                $functionAst = $_
                $paramBlockAst = $functionAst.Body.ParamBlock
                if ($null -eq $paramBlockAst) { return }
                $paramBlockAst.Parameters | ForEach-Object {
                    $parameterAst = $_
                    $parameterAst.Extent.Text -Split "`n" | ForEach-Object {
                        $_ | Should -Not -Match '^\s*\[[\w\.]+\]\s*\$' -Because "the function '$($functionAst.Name)' does not have the variable definitions seperated by a new line (line $($parameterAst.Extent.StartLineNumber))"
                    }
                }
            }
        }
        It "A scriptblock should have the parentheses in the first line with the statement" {
            $statements = $ast.FindAll({ param($ast)
                    (
                        $ast -is [System.Management.Automation.Language.FunctionDefinitionAst] -or
                        $ast -is [System.Management.Automation.Language.IfStatementAst] -or
                        $ast -is [System.Management.Automation.Language.ThrowStatementAst] -or
                        $ast -is [System.Management.Automation.Language.TrapStatementAst] -or 
                        $ast -is [System.Management.Automation.Language.TryStatementAst] -or
                        $ast -is [System.Management.Automation.Language.NamedBlockAst] -or
                        $ast -is [System.Management.Automation.Language.LoopStatementAst] 
                    ) -and
                    $true -ne $ast.Unnamed -and
                    $null -ne $ast.Find({ $args[0] -is [System.Management.Automation.Language.ScriptBlockAst] }, $true)
                }, $true)
            $statements | ForEach-Object {
				($_.Extent.Text -split "`n") | Select-Object -First 1 | Should -Match '.+(\{|\()\s*$' -Because "the statement does not have parentheses in the first line (line $($_.Extent.StartLineNumber))"
            }
        }
        It "Functions and blocks should have the ending parentheses as sole character" {
            $statements = $ast.FindAll({ param($ast)
                    (
                        $ast -is [System.Management.Automation.Language.FunctionDefinitionAst] -or
                        $ast -is [System.Management.Automation.Language.IfStatementAst] -or
                        $ast -is [System.Management.Automation.Language.ThrowStatementAst] -or
                        $ast -is [System.Management.Automation.Language.TrapStatementAst] -or 
                        $ast -is [System.Management.Automation.Language.TryStatementAst] -or
                        $ast -is [System.Management.Automation.Language.NamedBlockAst] -or
                        $ast -is [System.Management.Automation.Language.LoopStatementAst]
                    ) -and
                    $true -ne $ast.Unnamed -and
                    $null -ne $ast.Find({ $args[0] -is [System.Management.Automation.Language.ScriptBlockAst] }, $true)
                }, $true)
            $statements | ForEach-Object {
                if ($_ -is [System.Management.Automation.Language.DoWhileStatementAst]){
                    ($_.Extent.Text -split "`n") | Select-Object -Last 1 | Should -Not -Match '^\s*\}' -Because "the do while loop should have its conditions as seperate ending line (line $($_.Extent.EndLineNumber))"
                } else {
                    ($_.Extent.Text -split "`n") | Select-Object -Last 1 | Should -Match '\s*\}\s*$' -Because "the statement does not have the ending parentheses as seperate line (line $($_.Extent.EndLineNumber))"
                }
            }
        }
        It "Empty strings should not use `"`"" {
            $emptyStringAssignments = $ast.Find({
                param($ast)
                $ast -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                $ast.Right.Extent.Text -eq '""'
            }, $true)

            $emptyStringAssignments | Should -BeNullOrEmpty -Because "empty strings should be defined by .NET functions such as [string]::Empty"

            $emptyStringExpressions = $ast.Find({
                param($ast)
                $ast -is [System.Management.Automation.Language.BinaryExpressionAst] -and
                (   
                    $ast.Right.Extent.Text -eq '""' -or
                    $ast.Left.Extent.Text -eq '""'
                )
            }, $true)

            $emptyStringExpressions | Should -BeNullOrEmpty -Because "using empty string expressions should be done using .NET functions such as [string]::Empty"
        }
        It "Check condition formatting" {
            $wrongSideOperator = $ast.Find({
                    param($ast)
                    $ast -is [System.Management.Automation.Language.BinaryExpressionAst] -and
                    $ast.Right.Extent.Text -in @('$true', '$false', '$null')
                }, $true) 
            $wrongSideOperator | Should -BeNullOrEmpty -Because "there should be no null or empty on the right side of a comparison (line $($wrongSideOperator.Extent.StartLineNumber))"

            $unaryExpression = $ast.Find({ 
                    param($ast) 
                    $ast -is [System.Management.Automation.Language.UnaryExpressionAst] -and
                    $ast.Extent.Text -notmatch "\$\w+\+\+" -and
                    $ast.Extent.Text -notmatch "\$\w+\-\-"
                }, $true) 
            $unaryExpression | Should -BeNullOrEmpty -Because "there should be no unary expressions (line $($unaryExpression.Extent.StartLineNumber))"
        }
        It "Check if command aliases have been used" {
            $commands = $ast.FindAll({
                    param($ast)
                    $ast -is [System.Management.Automation.Language.CommandAst]
                }, $true)
            $commands | ForEach-Object {
                if ($_.InvocationOperator -ne "Unknown") { return }
                Test-Path "alias:$($_.GetCommandName())" | Should -Be $false -Because "use of command aliases is not recommended $($_.Extent.StartLineNumber)"
            }
        }
    }
}
