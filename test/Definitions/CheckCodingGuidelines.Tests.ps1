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
            $statements = @('function', 'if', 'else', 'elseif', 'foreach', 'for', 'while', 'switch', 'try', 'catch', 'finally', 'return', 'break', 'continue', 'throw', 'exit', 'Process', 'Begin', 'End', 'Param')
            $statements | ForEach-Object {
                $currentLine = 1
                $statement = $_
                $content | ForEach-Object {
                    $currentLine++
                    if ($_ -imatch "^\s*$statement\b") {
                        $_ | Should -MatchExactly "^\s*$statement" -Because "the statement '$statement' is not capitalized correctly (line $currentLine)"
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
                    Write-Host $parameterAst.StaticType
                    $parameterAst.StaticType | Should -Not -Be 'System.Object' -Because "the parameter variable '$($parameterAst.Name.VariablePath.UserPath)' is not typed (line $($parameterAst.Extent.StartLineNumber))"
                }
            }
        }
        It "Intendations should be made using tabulator" {
            $currentLine = 1
            $content | ForEach-Object {
                $currentLine++
                $_ | Should -Match "^(?! +)" -Because "the line is not tab indented (line $currentLine)"
            }
        }
        It "At lineendings there should not be trailing whitespaces" {
            $currentLine = 1
            $content | ForEach-Object {
                $currentLine++
                $_ | Should -Not -Match "\s+$" -Because "the line has trailing whitespace (line $currentLine)"
            }
        }
        It "Every function should be described properly" {
            $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
            $functions | ForEach-Object {
                $help = $_.Body.GetHelpContent()
                $help | Should -Not -BeNullOrEmpty -Because "the function '$($_.Name)' does not have a description at all"
                $help.Synopsis | Should -Not -BeNullOrEmpty -Because "the function '$($_.Name)' does not have a synopsis"
                $help.Description | Should -Not -BeNullOrEmpty -Because "the function '$($_.Name)' does not have a description"
                $help.Example | Should -Not -BeNullOrEmpty -Because "the function '$($_.Name)' does not have an example"
                $help.Output | Should -Not -BeNullOrEmpty -Because "the function '$($_.Name)' does not specify its output"
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
                        $_ | Should -Not -Match '\]\s*\$(?!(true|false|global))' -Because "the function '$($functionAst.Name)' does not have the variable definitions seperated by a new line (line $($parameterAst.Extent.StartLineNumber))"
                    }
                }
            }
        }
        It "A ScriptBlock should have the parentheses in the first line with the statement" {
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
                    $null -ne $ast.Find({ $args[0] -is [System.Management.Automation.Language.ScriptBlockAst] }, $true)
                }, $true)
            $statements | ForEach-Object {
                if ($true -eq $_.Unnamed -and $_ -is [System.Management.Automation.Language.NamedBlockAst]) { return } # This is required to skip the unnamed "NamedBlockAst"
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
                    $null -ne $ast.Find({ $args[0] -is [System.Management.Automation.Language.ScriptBlockAst] }, $true)
                }, $true)
            $statements | ForEach-Object {
                if ($true -eq $_.Unnamed -and $_ -is [System.Management.Automation.Language.NamedBlockAst]) { return } # This is required to skip the unnamed "NamedBlockAst"
				($_.Extent.Text -split "`n") | Select-Object -Last 1 | Should -Match '\s*\}\s*$' -Because "the statement does not have the ending parentheses as seperate line (line $($_.Extent.EndLineNumber))"
            }
        }
        It "Empty strings should not use `"`"" {
            $currentLine = 1
            $content | ForEach-Object {
                $currentLine++
                $_ | Should -Not -MatchExactly '([\s\b]+|^)""([\b\s]+|$)' -Because "the line uses `"`" for an empty string (line $currentLine)"
            }
        }
        It "Check condition formatting" {
            $ifStatements = $ast.FindAll({
                    param($ast)
                    $ast -is [System.Management.Automation.Language.IfStatementAst]
                }, $true)

            $ifStatements | ForEach-Object {
                $conditions = $_.Clauses.Item1
                $conditions | ForEach-Object {
                    # Check if bool/null is at start
                    $expressions = $_.FindAll({ 
                        param($ast) 
                        $ast -is [System.Management.Automation.Language.BinaryExpressionAst] -and
                        $ast.Operator -in @('Ieq', 'Ine') -and
                        $ast.Extent.Text -match '\$(true|false|null)'
                    }, $true)
                    $expressions | ForEach-Object {
                        $_ | Should -Match '(?!-).*\$(true|false|null)\s*-' -Because "the bool/null value is not at the start of the comparison (line $($_.Extent.StartLineNumber))"
                    }

                    # We should not use unary operators
                    $unaryOperator = $_.Find({ 
                        param($ast) 
                        $ast -is [System.Management.Automation.Language.UnaryExpressionAst]
                    }, $true)
                    $unaryOperator | Should -BeNullOrEmpty -Because "the operator is not specified (line $($unaryOperator.Extent.StartLineNumber))"
                }
            }
        }
        It "Check if command aliases have been used" {
            $commands = $ast.FindAll({
                param($ast)
                $ast -is [System.Management.Automation.Language.CommandAst]
            }, $true)
            $commands | ForEach-Object {
                if ($_.InvocationOperator -ne "Unknown"){ return }
                Test-Path "alias:$($_.GetCommandName())" | Should -Be $false -Because "use of command aliases is not recommended $($_.Extent.StartLineNumber)"
            }
        }
    }
}
