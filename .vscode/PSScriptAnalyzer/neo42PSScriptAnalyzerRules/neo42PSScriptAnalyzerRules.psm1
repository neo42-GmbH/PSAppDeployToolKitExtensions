function PSNxtUseCorrectTokenCapitalization {
	<#
	.SYNOPSIS
	Checks that tokens are capitalized correctly.
	.DESCRIPTION
	Checks that tokens are capitalized correctly.
	.INPUTS
	[System.Management.Automation.Language.Token[]]
	.OUTPUTS
	[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
	#>
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.Language.Token[]]
		$TestToken,
		[Parameter(Mandatory = $false)]
		[hashtable]
		$Settings = $AnalyzerSettings.Rules[$MyInvocation.MyCommand.Name]
	)
	Begin {
		if ($false -eq $Settings.Enable) {
			return
		}
		[System.Collections.Generic.HashSet[string]]$keywords = [System.Collections.Generic.HashSet[string]]::new(
			[System.Collections.ObjectModel.Collection[string]]$Settings.Keywords,
			[System.StringComparer]::OrdinalIgnoreCase
		)
	}
	Process {
		[System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = @()
		foreach ($token in $TestToken) {
			[string]$spelling = [string]::Empty
			if (
				$false -eq $token.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::Keyword) -or
				$false -eq $keywords.TryGetValue($token.Text, [ref]$spelling) -or
				$token.Text -ceq $spelling
			) {
				continue
			}

			## Create a suggestion object
			$suggestedCorrections = [System.Collections.ObjectModel.Collection[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]]::new()
			$null = $suggestedCorrections.Add(
				[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
					$token.Extent.StartLineNumber,
					$token.Extent.EndLineNumber,
					$token.Extent.StartColumnNumber,
					$token.Extent.EndColumnNumber,
					$spelling,
					$MyInvocation.MyCommand.Definition,
					'Apply the correct capitalization.'
				)
			)
			## Return the diagnostic record
			$null = $results.Add([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
					'Message'              = 'The token is not capitalized correctly.'
					'Extent'               = $token.Extent
					'RuleName'             = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
					'Severity'             = 'Warning'
					'SuggestedCorrections' = $suggestedCorrections
				})
		}
		return ([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results)
	}
}

function PSNxtVariablesInParamBlockMustBeCapitalized {
	<#
	.SYNOPSIS
	Checks that parameter variables are capitalized.
	.DESCRIPTION
	Checks that parameter variables are capitalized.
	.INPUTS
	[System.Management.Automation.Language.ScriptBlockAst]
	.OUTPUTS
	[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
	#>
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst,
		[Parameter(Mandatory = $false)]
		[hashtable]
		$Settings = $AnalyzerSettings.Rules[$MyInvocation.MyCommand.Name]
	)
	Begin {
		if ($false -eq $Settings.Enable) {
			return
		}
	}
	Process {
		[System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = @()
		[System.Management.Automation.Language.FunctionDefinitionAst[]]$functions = $TestAst.FindAll({
				$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
			}, $false)
		foreach ($functionAst in $functions) {
			[System.Management.Automation.Language.ParamBlockAst]$paramBlockAst = $functionAst.Body.ParamBlock
			if ($null -eq $paramBlockAst) {
				continue
			}
			foreach ($parameter in $paramBlockAst.Parameters) {
				[System.Management.Automation.Language.VariableExpressionAst]$parameterVariableAst = $parameter.Name
				if ($parameterVariableAst.VariablePath.UserPath[0] -cmatch '[A-Z]') {
					continue
				}
				## Return the diagnostic record
				$null = $results.Add([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
						'Message'  = 'A parameter block variable needs to start with a capital letter'
						'Extent'   = $parameterVariableAst.Extent
						'RuleName' = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
						'Severity' = 'Warning'
					})
			}
		}
		return ([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results)
	}
}

function PSNxtAvoidCapitalizedVarsOutsideParamBlock {
	<#
	.SYNOPSIS
	Checks that variables are capitalized and originate from the param block.
	.DESCRIPTION
	Checks that variables are capitalized and originate from the param block.
	.INPUTS
	[System.Management.Automation.Language.ScriptBlockAst]
	.OUTPUTS
	[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
	#>
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst,
		[Parameter(Mandatory = $false)]
		[hashtable]
		$Settings = $AnalyzerSettings.Rules[$MyInvocation.MyCommand.Name]
	)
	Begin {
		if ($false -eq $Settings.Enable) {
			return
		}
		[string[]]$builtInVariables = @(
			'ConsoleFileName', 'EnabledExperimentalFeatures', 'Error', 'Event', 'EventArgs', 'EventSubscriber', 'ExecutionContext', 'HOME', 'Host', 'IsCoreCLR', 'IsLinux', 'IsMacOS', 'IsWindows', 'LASTEXITCODE', 'Matches', 'NestedPromptLevel', 'PID', 'PROFILE', 'PWD', 'Sender', 'ShellId', 'StackTrace'
		)

		[scriptblock]$getParentParamBlocks = {
			Param (
				[System.Management.Automation.Language.ScriptBlockAst]
				$Ast
			)
			if ($Ast.Parent -is [System.Management.Automation.Language.ScriptBlockAst]) {
				. $getParentParamBlock -Ast $Ast.Parent
			}
			if ($Ast.ParamBlock -is [System.Management.Automation.Language.ParamBlockAst]) {
				return $Ast.ParamBlock
			}
		}
	}
	Process {
		[System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = @()
		[System.Management.Automation.Language.VariableExpressionAst[]]$capitalizedVariables = $TestAst.FindAll({
				$args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and
				$args[0].VariablePath.UserPath -cmatch '^[A-Z]' -and
				$args[0].VariablePath.UserPath -notmatch '.+Preference$|^PS.+|.+Invocation$' -and
				$args[0].VariablePath.UserPath -notin $builtInVariables
			}, $false)

		[System.Management.Automation.Language.ParamBlockAst[]]$parentParamBlocks = . $getParentParamBlocks -Ast $TestAst

		foreach ($variableAst in $capitalizedVariables) {
			if ($variableAst.VariablePath.UserPath -notin $parentParamBlocks.Parameters.Name.VariablePath.UserPath) {
				$null = $results.Add([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
						'Message'  = 'A capatalized variable needs to be defined in the param block'
						'Extent'   = $variableAst.Extent
						'RuleName' = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
						'Severity' = 'Warning'
					})
			}
		}
		return ([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results)
	}
}

function PSNxtParamBlockVariablesShouldBeTyped {
	<#
	.SYNOPSIS
	Checks that parameter variables are typed.
	.DESCRIPTION
	Checks that parameter variables are typed.
	.INPUTS
	[System.Management.Automation.Language.ScriptBlockAst]
	.OUTPUTS
	[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
	#>
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst,
		[Parameter(Mandatory = $false)]
		[hashtable]
		$Settings = $AnalyzerSettings.Rules[$MyInvocation.MyCommand.Name]
	)
	Begin {
		if ($false -eq $Settings.Enable) {
			return
		}
	}
	Process {
		if ($null -eq $TestAst.ParamBlock) {
			return
		}
		[System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = @()
		foreach ($parameterAst in $TestAst.ParamBlock.Parameters) {
			if ($null -eq $parameterAst.Attributes.TypeName) {
				$null = $results.Add([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
						'Message'  = 'A parameter block variable needs to be typed'
						'Extent'   = $parameterAst.Extent
						'RuleName' = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
						'Severity' = 'Warning'
					})
			}
			elseif ($parameterAst.Attributes.TypeName.Extent.StartLineNumber -eq $parameterAst.Name.Extent.StartLineNumber) {
				$null = $results.Add([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
						'Message'  = 'The type definition and variable should be on a seperate lines'
						'Extent'   = $parameterAst.Extent
						'RuleName' = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
						'Severity' = 'Warning'
					})
			}
		}
		return ([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results)
	}
}

function PSNxtDontUseEmptyStringLiteral {
	<#
	.SYNOPSIS
	Checks that empty strings are not used.
	.DESCRIPTION
	Checks that empty strings are not used.
	.INPUTS
	[System.Management.Automation.Language.ScriptBlockAst]
	.OUTPUTS
	[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
	#>
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst,
		[Parameter(Mandatory = $false)]
		[hashtable]
		$Settings = $AnalyzerSettings.Rules[$MyInvocation.MyCommand.Name]
	)
	Begin {
		if ($false -eq $Settings.Enable) {
			return
		}
	}
	Process {
		[System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = @()
		[System.Management.Automation.Language.StringConstantExpressionAst[]]$stringConstants = $TestAst.FindAll({
				$args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
				$args[0].Value -eq [string]::Empty -and
				$args[0].Parent.TypeName.Name -ne 'Diagnostics.CodeAnalysis.SuppressMessageAttribute'
			}, $false)

		foreach ($stringConstant in $stringConstants) {
			$suggestedCorrections = [System.Collections.ObjectModel.Collection[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]]::new()
			[string]$correctionContent = '[string]::Empty'
			if ($stringConstant.Parent -is [System.Management.Automation.Language.CommandAst] -and $stringConstant.Parent.GetCommandName() -eq 'Write-Output') {
				$correctionContent = '([string]::Empty)'
			}
			$null = $suggestedCorrections.Add(
				[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
					$stringConstant.Extent.StartLineNumber,
					$stringConstant.Extent.EndLineNumber,
					$stringConstant.Extent.StartColumnNumber,
					$stringConstant.Extent.EndColumnNumber,
					$correctionContent,
					$MyInvocation.MyCommand.Definition,
					'Use .NET string empty instead of empty string literal.'
				)
			)
			$null = $results.Add([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
					'Message'              = 'Empty strings should not be used'
					'Extent'               = $stringConstant.Extent
					'RuleName'             = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
					'Severity'             = 'Warning'
					'SuggestedCorrections' = $suggestedCorrections
				})
		}
		return ([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results)
	}
}

function PSNxtEnforceConsistantConditionalStatement {
	<#
	.SYNOPSIS
	Checks that conditional statements are consistent.
	.DESCRIPTION
	Checks that conditional statements are consistent.
	.INPUTS
	[System.Management.Automation.Language.ScriptBlockAst]
	.OUTPUTS
	[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
	#>
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst,
		[Parameter(Mandatory = $false)]
		[hashtable]
		$Settings = $AnalyzerSettings.Rules[$MyInvocation.MyCommand.Name]
	)
	Begin {
		if ($false -eq $Settings.Enable) {
			return
		}
	}
	Process {
		[System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = @()
		[System.Management.Automation.Language.BinaryExpressionAst[]]$wrongSideOperators = $TestAst.FindAll({
				$args[0] -is [System.Management.Automation.Language.BinaryExpressionAst] -and
				$args[0].Right.Extent.Text -in @('$true', '$false')
			}, $false)

		foreach ($wrongSideOperator in $wrongSideOperators) {
			$suggestedCorrections = [System.Collections.ObjectModel.Collection[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]]::new()
			$null = $suggestedCorrections.Add(
				[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
					$wrongSideOperator.Extent.StartLineNumber,
					$wrongSideOperator.Extent.EndLineNumber,
					$wrongSideOperator.Extent.StartColumnNumber,
					$wrongSideOperator.Extent.EndColumnNumber,
					$wrongSideOperator.Right.Extent.Text + ' -' + $wrongSideOperator.Operator + ' ' + $wrongSideOperator.Left.Extent.Text,
					$MyInvocation.MyCommand.Definition,
					'Switch the boolean literal to the left side of the comparison.'
				)
			)

			$null = $results.Add([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
					'Message'              = 'Boolean literals should be on the left side of a comparison'
					'Extent'               = $wrongSideOperator.Extent
					'RuleName'             = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
					'Severity'             = 'Warning'
					'SuggestedCorrections' = $suggestedCorrections
				})
		}
		return ([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results)
	}
}

function PSNxtEnforceNewLineAtEndOfFile {
	<#
	.SYNOPSIS
	Checks that there is a new line at the end of the file.
	.DESCRIPTION
	Checks that there is a new line at the end of the file.
	.INPUTS
	[System.Management.Automation.Language.ScriptBlockAst]
	.OUTPUTS
	[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
	#>
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst,
		[Parameter(Mandatory = $false)]
		[hashtable]
		$Settings = $AnalyzerSettings.Rules[$MyInvocation.MyCommand.Name]
	)
	Begin {
		if ($false -eq $Settings.Enable) {
			return
		}
	}
	Process {
		if ($null -ne $TestAst.Parent) {
			return
		}
		[string]$lastLine = ($TestAst.Extent.Text -split [System.Environment]::NewLine)[-1]
		if ($true -eq [string]::IsNullOrWhiteSpace($lastLine)) {
			return
		}
		$suggestedCorrections = [System.Collections.ObjectModel.Collection[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]]::new()
		$null = $suggestedCorrections.Add(
			[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
				$TestAst.Extent.EndLineNumber,
				$TestAst.Extent.EndLineNumber,
				1,
				$TestAst.Extent.EndColumnNumber,
				$lastLine + "`r`n",
				$MyInvocation.MyCommand.Definition,
				'Add a new line at the end of the file.'
			)
		)
		$extent = [System.Management.Automation.Language.ScriptExtent]::new(
			[System.Management.Automation.Language.ScriptPosition]::new(
				$TestAst.Extent.File,
				$TestAst.Extent.EndLineNumber,
				1,
				$lastLine
			),
			[System.Management.Automation.Language.ScriptPosition]::new(
				$TestAst.Extent.File,
				$TestAst.Extent.EndLineNumber,
				$lastLine.Length,
				$lastLine
			)
		)
		return @([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
				'Message'              = 'There should be a new line at the end of the file'
				'Extent'               = $extent
				'RuleName'             = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
				'Severity'             = 'Warning'
				'SuggestedCorrections' = $suggestedCorrections
			})
	}
}

function PSNxtAvoidSpecificFunction {
	<#
	.SYNOPSIS
	Dont allow usage of PSADT functions which are not compatible with our extensions.
	.DESCRIPTION
	Dont allow usage of PSADT functions which are not compatible with our extensions.
	.INPUTS
	[System.Management.Automation.Language.ScriptBlockAst]
	.OUTPUTS
	[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
	#>
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst,
		[Parameter(Mandatory = $false)]
		[hashtable]
		$Settings = $AnalyzerSettings.Rules[$MyInvocation.MyCommand.Name]
	)
	Begin {
		if ($false -eq $Settings.Enable) {
			return
		}
	}
	Process {
		[System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = @()

		[System.Management.Automation.Language.CommandAst[]]$commandAsts = $TestAst.FindAll({
				$args[0] -is [System.Management.Automation.Language.CommandAst] -and
				$args[0].GetCommandName() -in $Settings.Functions.Keys
			}, $false)

		foreach ($commandAst in $commandAsts) {
			$null = $results.Add([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
					'Message'  = $Settings.Functions[$commandAst.GetCommandName()]
					'Extent'   = $commandAst.Extent
					'RuleName' = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
					'Severity' = 'Warning'
				})
		}

		return ([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results)
	}
}

function PSNxtMigrateLegacyFunctionName {
	<#
	.SYNOPSIS
	Checks that functions are named correctly.
	.DESCRIPTION
	Checks that functions are named correctly. With the v4 release the naming convention for functions has changed.
	.INPUTS
	[System.Management.Automation.Language.ScriptBlockAst]
	.OUTPUTS
	[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
	#>
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst,
		[Parameter(Mandatory = $false)]
		[hashtable]
		$Settings = $AnalyzerSettings.Rules[$MyInvocation.MyCommand.Name]
	)
	Begin {
		if ($false -eq $Settings.Enable) {
			return
		}
	}
	Process {
		[System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = @()
		[System.Management.Automation.Language.CommandAst[]]$commandsToMigrate = $TestAst.FindAll({
				$args[0] -is [System.Management.Automation.Language.CommandAst] -and
				$args[0].GetCommandName() -in $Settings.Functions.Keys
			}, $false)

		foreach ($commandAst in $commandsToMigrate) {
			$suggestedCorrections = [System.Collections.ObjectModel.Collection[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]]::new()
			if ($Settings.Functions[$commandAst.GetCommandName()] -is [string] -and $Settings.Functions[$commandAst.GetCommandName()].Length -gt 0) {
				$null = $suggestedCorrections.Add(
					[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
						$commandAst.Extent.StartLineNumber,
						$commandAst.Extent.EndLineNumber,
						$commandAst.Extent.StartColumnNumber,
						$commandAst.Extent.EndColumnNumber,
						($commandAst.Extent.Text -replace ('^' + [Regex]::Escape($commandAst.GetCommandName())), $Settings.Functions[$commandAst.GetCommandName()]),
						$MyInvocation.MyCommand.Definition,
						'Replace the function name with the new function name.'
					)
				)
			}
			$null = $results.Add(
				[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
					'Message'              = 'This function is deprecated and should be replaced with the new function name.'
					'Extent'               = $commandAst.Extent
					'RuleName'             = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
					'Severity'             = 'Error'
					'SuggestedCorrections' = $suggestedCorrections
				}
			)
		}
		return ([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results)
	}
}

function PSNxtEnforceOptionalParameter {
	<#
	.SYNOPSIS
	Checks that functions contain all desired parameters.
	.DESCRIPTION
	Checks that functions contain all desired parameters.
	.INPUTS
	[System.Management.Automation.Language.ScriptBlockAst]
	.OUTPUTS
	[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
	#>
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst,
		[Parameter(Mandatory = $false)]
		[hashtable]
		$Settings = $AnalyzerSettings.Rules[$MyInvocation.MyCommand.Name]
	)
	Begin {
		if ($false -eq $Settings.Enable) {
			return
		}
	}
	Process {
		[System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = @()
		[System.Management.Automation.Language.CommandAst[]]$commands = $TestAst.FindAll({
				$args[0] -is [System.Management.Automation.Language.CommandAst] -and
				$true -notin $args[0].CommandElements.Splatted -and
				$args[0].GetCommandName() -in $Settings.Functions.Keys
			}, $false)

		foreach ($command in $commands) {
			[string[]]$missingParams = $Settings.Functions[$command.GetCommandName()] | Where-Object { $command.CommandElements.ParameterName -notcontains $_ }
			if ($missingParams.Count -gt 0) {
				$null = $results.Add(
					[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
						'Message'  = "The function is missing the following parameters: $($missingParams -join ', ')"
						'Extent'   = $command.Extent
						'RuleName' = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
						'Severity' = 'Error'
					}
				)
			}
		}
		return ([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results)
	}
}

[hashtable]$AnalyzerSettings = Import-PowerShellDataFile -Path "$PSScriptRoot\..\PSScriptAnalyzerSettings.psd1"

Export-ModuleMember -Function 'PSNxt*'
