# Check if we are in the Definitions folder. Pester tests via PesterTestsStarter.ps1 are executed from the root folder
$baseDir = Split-Path -Path (Resolve-Path $MyInvocation.MyCommand.Definition) -Parent
if ((Split-Path $baseDir -Leaf) -eq "Definitions"){
    $baseDir = Resolve-Path "$baseDir\..\..\"
}

Describe "Coding Guidelines" -ForEach @(
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
        It "Should have no errors" {
            $errors | Should -BeNullOrEmpty
        }
        It "Should have the correct capaitalization on keywords" {
            $spelling = @('if', 'else', 'elseif', 'function', 'foreach', 'for', 'while', 'do', 'switch', 'try', 'catch', 'finally', 'return', 'break', 'continue', 'throw', 'exit', 'Process', 'Begin', 'End', 'Param')
            $tokens | Where-Object {$_.TokenFlags -contains 'Keyword' -and $_.Text -in $spelling} | ForEach-Object {
                $token = $_
                $matchingSpelling = $spelling | Where-Object {$_ -eq $token.Text}
                $_.Text | Should -BeExactly $matchingSpelling "the keyword $($_.Text) is not capaitalized correctly $($_.Extent.StartLineNumber)"
            }
        }
        It "All commandlets should be capaitalized correctly" {
            $commands = $ast.FindAll({
                param($ast)
                $ast -is [System.Management.Automation.Language.CommandAst]
            }, $true)
            $commands | ForEach-Object {
                if ($_.InvocationOperator -ne "Unknown") { return }
                $usedCommandName = $_.GetCommandName()
                $command = (Get-Command -Name $usedCommandName -CommandType Cmdlet -Module @("CimCmdlets", "Microsoft.PowerShell.Management", "Microsoft.PowerShell.Security", "Microsoft.PowerShell.Utility", "PowerShellEditorServices.Commands", "PSReadLine") -ErrorAction SilentlyContinue).Name
                if ($null -eq $command){ return }

                $usedCommandName | Should -BeExactly $command -Because "the command $usedCommandName is not capaitalized correctly $($_.Extent.StartLineNumber)"
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
                    # Skip when string is required that allows null. Make sure it uses validation attribute
                    if ($parameterAst.Attributes.TypeName.FullName -contains "AllowNull" -and $parameterAst.Attributes.TypeName.FullName -match "Validate.*"){
                        return
                    }
                    # Skip when self defined type is used
                    elseif ($parameterAst.Attributes.TypeName.FullName -match "PSADTNXT.*"){
                        return
                    }
                    $parameterAst.StaticType | Should -Not -Be 'System.Object' -Because "the parameter variable '$($parameterAst.Name.VariablePath.UserPath)' is not typed (line $($parameterAst.Extent.StartLineNumber))"
                }
            }
        }
        It "Capitalized variables should be defined in the param block" {
            $parameterBlocks = $ast.FindAll({
                param($ast) 
                $ast -is [System.Management.Automation.Language.ParamBlockAst]
                $ast.Parameters.Count -gt 0
            }, $true)
            $parameterBlocks | ForEach-Object {
                $paramBlockAst = $_
                @('BeginBlock', 'ProcessBlock', 'EndBlock') | ForEach-Object {
                    $namedBlockAst = $paramBlockAst.Parent | Select-Object -ExpandProperty $_
                    if($null -eq $namedBlockAst){ return }
                    
                    $capitalizedVariables = $namedBlockAst.FindAll({
                        param($ast)
                        $ast -is [System.Management.Automation.Language.VariableExpressionAst] -and
                        $ast.VariablePath.UserPath -cmatch "^[A-Z]"
                    }, $true)
                    $capitalizedVariables | ForEach-Object {
                        $_ | Should -BeIn $paramBlockAst.Parameters.Name.VariablePath.UserPath -Because "the capitalized variable '$($_.VariablePath.UserPath)' is not defined in the param block (line $($_.Extent.StartLineNumber))"
                    }
                    
                }
            }
        }
        It "Indentations should be made using tabulator" {
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
                    $_ | Should -Match "\) \{" -Because "the parentheses spacing is not correct (line $currentLine)"
                }
                $currentLine++
            }
        }
        It "Every function should be described properly" {
            $functionsToExclude = @("Custom*")
            $functions = $ast.FindAll({
                param($ast)
                $ast -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $ast.Name -notmatch $functionsToExclude
            }, $false)
            $functions | ForEach-Object {
                $help = $_.GetHelpContent()
                $help | Should -Not -BeNullOrEmpty -Because "the function '$($_.Name)' should have a synopsis (line $($_.Extent.StartLineNumber))"
                $help.Synopsis | Should -Not -BeNullOrEmpty -Because "the function '$($_.Name)' should have a synopsis (line $($_.Extent.StartLineNumber))"
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
                if (
                    $_ -is [System.Management.Automation.Language.DoWhileStatementAst] -or
                    $_ -is [System.Management.Automation.Language.DoUntilStatementAst]
                ){
                    ($_.Extent.Text -split "`n") | Select-Object -Last 1 | Should -Not -Match '^\s*\}' -Because "the do while loop should have its conditions as seperate ending line (line $($_.Extent.EndLineNumber))"
                }
                else {
                    ($_.Extent.Text -split "`n") | Select-Object -Last 1 | Should -Match '\s*\}\s*$' -Because "the statement does not have the ending parentheses as seperate line (line $($_.Extent.EndLineNumber))"
                }
            }
        }
        It "Empty strings should not use `"`"" {
            $emptyStringAssignments = $ast.Find({
                param($ast)
                $ast -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                $ast.Right.Extent.Text -match "^(`"`"|'')$"
            }, $true)

            $emptyStringAssignments | Should -BeNullOrEmpty -Because "empty strings should be defined by .NET functions such as [string]::Empty (line $($emptyStringAssignments.Extent.StartLineNumber))"

            $emptyStringExpressions = $ast.Find({
                param($ast)
                $ast -is [System.Management.Automation.Language.BinaryExpressionAst] -and
                (
                    $ast.Right.Extent.Text -match "^(`"`"|'')$" -or
                    $ast.Left.Extent.Text -match "^(`"`"|'')$"
                )
            }, $true)

            $emptyStringExpressions | Should -BeNullOrEmpty -Because "using empty string expressions should be done using .NET functions such as [string]::Empty (line $($emptyStringExpressions.Extent.StartLineNumber))"
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

            $noOperator = $ast.Find({
                param($ast)
                (
                    $ast -is [System.Management.Automation.Language.IfStatementAst] -and
                    $ast.Clauses.Item1.Extent.Text -notmatch ("-")
                ) -or
                (
                    (
                        $ast -is [System.Management.Automation.Language.DoUntilStatementAst] -or
                        $ast -is [System.Management.Automation.Language.DoWhileStatementAst] -or
                        $ast -is [System.Management.Automation.Language.WhileStatementAst]
                    ) -and
                    $ast.Condition.Extent.Text -notmatch ("-")
                )
            }, $true)
            $noOperator | Should -BeNullOrEmpty -Because "there should be no condition without and operator (line $($noOperator.Extent.StartLineNumber))"
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
        It "Check spacing between pipelines" {
            $pipelines = $ast.FindAll({
                param($ast)
                $ast -is [System.Management.Automation.Language.PipelineAst] -and
                $ast.PipelineElements.Count -gt 1
            },$true)
            $pipelines | ForEach-Object {
                $_.Extent.Text | Should -Match "(?sm)(?<=\S) \|( (?=\S)|\r?\n)" -Because "there should be a space between pipelines (line $($_.Extent.StartLineNumber))"
            }
        }
        It "Last line should be empty new line" {
            $contentRaw -split "`n" | Select-Object -Last 1 | Should -BeNullOrEmpty
        }
        It "Scriptblocks should not be single line" {
            $scriptblocks = $ast.FindAll({
                param($ast)
                $ast -is [System.Management.Automation.Language.ScriptBlockAst]
            },$true)
            $scriptblocks | ForEach-Object {
                if ($_.Extent.Text -notmatch "^{}$"){
                    $_.Extent.StartLineNumber | Should -Not -Be $_.Extent.EndLineNumber -Because "scriptblocks should not be single line (line $($_.Extent.StartLineNumber))"
                }
            }
        }
        It "Token ; should not be used as a line seperator" {
            $seperatorTokens = $tokens | Where-Object {$_.Kind -eq 'Semi'}
            $seperatorTokens | ForEach-Object {
                $token = $_
                $context = $content[$token.Extent.StartLineNumber - 1]
                # Skip for loops
                if ($context -match "^\s*for\s*\(") { return }
                $token | Should -BeNullOrEmpty -Because "the ';' token should not be used a seperator (line $($token.Extent.StartLineNumber))"
            }
        }
    }
}
