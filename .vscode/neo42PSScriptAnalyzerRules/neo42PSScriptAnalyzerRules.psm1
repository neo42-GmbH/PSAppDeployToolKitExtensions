function neo42PSUseCorrectTokenCapitalization {
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
	[CmdletBinding()]
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.Language.Token[]]
		$TestToken
	)
	Begin {
		[string[]]$keywordList = @('if', 'else', 'elseif', 'function', 'foreach', 'for', 'while', 'do', 'in', 'switch', 'default', 'try', 'catch', 'finally', 'return', 'break', 'continue', 'throw', 'exit', 'Process', 'Begin', 'End', 'Param')
	}
	Process {
		$results = @()
		foreach ($token in $TestToken) {
			## Check if the token is a keyword and if it is already in the correct case
			if ($false -eq $token.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::Keyword)) {
				continue
			}
			## Get the correct spelling of the token
			[string]$spelling = $keywordList | Where-Object { $_ -ieq $token.Text } | Select-Object -First 1
			## Check if we have a suggestion, otherwise return nothing
			if ($true -eq [string]::IsNullOrWhiteSpace($spelling) -or $spelling -ceq $token.Text) {
				continue
			}
			## Create a suggestion object
			$suggestedCorrections = New-Object System.Collections.ObjectModel.Collection["Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent"]
			$suggestedCorrections.add(
				[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
					$token.Extent.StartLineNumber,
					$token.Extent.EndLineNumber,
					$token.Extent.StartColumnNumber,
					$token.Extent.EndColumnNumber,
					$spelling,
					$MyInvocation.MyCommand.Definition,
					'Apply the correct capitalization.'
				)
			) | Out-Null
			## Return the diagnostic record
			$results += [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
				'Message'              = 'The token is not capitalized correctly.'
				'Extent'               = $token.Extent
				'RuleName'             = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
				'Severity'             = 'Warning'
				'SuggestedCorrections' = $suggestedCorrections
			}
		}
		return $results
	}
}

function neo42PSVariablesInParamBlockShouldBeCapitalized {
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
	[CmdletBinding()]
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst
	)
	Process {
		[System.Management.Automation.Language.FunctionDefinitionAst[]]$functions = $TestAst.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)
		$results = @()
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
				$results += [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
					'Message'  = 'A parameter block variable needs to start with a capital letter'
					'Extent'   = $parameterVariableAst.Extent
					'RuleName' = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
					'Severity' = 'Warning'
				}
			}
		}
		return $results
	}
}

function neo42PSCapatalizedVariablesNeedToOriginateFromParamBlock {
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
	[CmdletBinding()]
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst
	)
	Process {
		[System.Management.Automation.Language.ParamBlockAst[]]$parameterBlocks = $TestAst.FindAll({
				$args[0] -is [System.Management.Automation.Language.ParamBlockAst] -and
				$args[0].Parameters.Count -gt 0
			}, $false)

		$results = @()
		foreach ($paramBlockAst in $parameterBlocks) {
			foreach ($block in @('BeginBlock', 'ProcessBlock', 'EndBlock')) {
				[System.Management.Automation.Language.NamedBlockAst]$namedBlockAst = $paramBlockAst.Parent | Select-Object -ExpandProperty $block -ErrorAction SilentlyContinue
				if ($null -eq $namedBlockAst) {
					continue
    }
				# Get All capitalized variables that are not automatically defined
				[System.Management.Automation.Language.VariableExpressionAst[]]$capitalizedVariables = $namedBlockAst.FindAll({
						$args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and
						$args[0].VariablePath.UserPath -cmatch '^[A-Z]' -and
						$args[0].VariablePath.UserPath -notin @('ConsoleFileName', 'EnabledExperimentalFeatures', 'Error', 'Event', 'EventArgs', 'EventSubscriber', 'ExecutionContext', 'false', 'foreach', 'HOME', 'Host', 'input', 'IsCoreCLR', 'IsLinux', 'IsMacOS', 'IsWindows', 'LASTEXITCODE', 'Matches', 'MyInvocation', 'HostInvocation', 'NestedPromptLevel', 'null', 'PID', 'PROFILE', 'PSBoundParameters', 'PSCmdlet', 'PSCommandPath', 'PSCulture', 'PSDebugContext', 'PSEdition', 'PSHOME', 'PSItem', 'PSScriptRoot', 'PSSenderInfo', 'PSUICulture', 'PSVersionTable', 'PWD', 'Sender', 'ShellId', 'StackTrace', 'switch', 'this', 'true')
					}, $false)

				foreach ($variableAst in $capitalizedVariables) {
					if ($variableAst.VariablePath.UserPath -in $paramBlockAst.Parameters.Name.VariablePath.UserPath) {
						continue
					}
					$results += [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
						'Message'  = 'A capatalized variable needs to be defined in the param block'
						'Extent'   = $variableAst.Extent
						'RuleName' = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
						'Severity' = 'Warning'
					}
				}
			}
		}
		return $results
	}
}

function neo42PSParamBlockVariablesShouldBeTyped {
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
	[CmdletBinding()]
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst
	)
	Process {
		[System.Management.Automation.Language.ParamBlockAst]$parameterBlock = $TestAst.ParamBlock
		if ($null -eq $parameterBlock) {
			return
		}

		$results = @()
		foreach ($parameterAst in $parameterBlock.Parameters) {
			if ($null -eq $parameterAst.Attributes.TypeName) {
				$results += [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
					'Message'  = 'A parameter block variable needs to be typed'
					'Extent'   = $parameterAst.Extent
					'RuleName' = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
					'Severity' = 'Warning'
				}
			}
			elseif ($parameterAst.Attributes.TypeName.Extent.StartLineNumber -eq $parameterAst.Name.Extent.StartLineNumber) {
				$results += [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
					'Message'  = 'The type definition and variable should be on a seperate lines'
					'Extent'   = $parameterAst.Extent
					'RuleName' = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
					'Severity' = 'Warning'
				}
			}
		}
		return $results
	}
}

function neo42PSDontUseEmptyStringLiterals {
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
	[CmdletBinding()]
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst
	)
	Process {
		[System.Management.Automation.Language.StringConstantExpressionAst[]]$stringConstants = $TestAst.FindAll({
				$args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $args[0].Value -eq [string]::Empty -and
				$args[0].Parent.TypeName.Name -ne 'Diagnostics.CodeAnalysis.SuppressMessageAttribute'
			}, $false)
		$results = @()
		foreach ($stringConstant in $stringConstants) {
			$suggestedCorrections = New-Object System.Collections.ObjectModel.Collection["Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent"]
			$suggestedCorrections.add(
				[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
					$stringConstant.Extent.StartLineNumber,
					$stringConstant.Extent.EndLineNumber,
					$stringConstant.Extent.StartColumnNumber,
					$stringConstant.Extent.EndColumnNumber,
					'[string]::Empty',
					$MyInvocation.MyCommand.Definition,
					'Use .NET string empty instead of empty string literal.'
				)
			) | Out-Null
			$results += [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
				'Message'              = 'Empty strings should not be used'
				'Extent'               = $stringConstant.Extent
				'RuleName'             = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
				'Severity'             = 'Warning'
				'SuggestedCorrections' = $suggestedCorrections
			}
		}
		return $results
	}
}

function neo42PSEnforceConsistantConditionalStatements {
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
	[CmdletBinding()]
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst
	)
	$results = @()
	[System.Management.Automation.Language.BinaryExpressionAst[]]$wrongSideOperators = $TestAst.FindAll({
			$args[0] -is [System.Management.Automation.Language.BinaryExpressionAst] -and
			$args[0].Right.Extent.Text -in @('$true', '$false')
		}, $false)
	foreach ($wrongSideOperator in $wrongSideOperators) {
		$suggestedCorrections = New-Object System.Collections.ObjectModel.Collection["Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent"]
		$suggestedCorrections.add(
			[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
				$wrongSideOperator.Extent.StartLineNumber,
				$wrongSideOperator.Extent.EndLineNumber,
				$wrongSideOperator.Extent.StartColumnNumber,
				$wrongSideOperator.Extent.EndColumnNumber,
				$wrongSideOperator.Right.Extent.Text + ' -' + $wrongSideOperator.Operator + ' ' + $wrongSideOperator.Left.Extent.Text,
				$MyInvocation.MyCommand.Definition,
				'Switch the boolean literal to the left side of the comparison.'
			)
		) | Out-Null
		$results += [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
			'Message'              = 'Boolean literals should be on the left side of a comparison'
			'Extent'               = $wrongSideOperator.Extent
			'RuleName'             = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
			'Severity'             = 'Warning'
			'SuggestedCorrections' = $suggestedCorrections
		}
	}

	<# Currently very basic... Can only detect conditions without any operator
	$noOperators = $TestAst.FindAll({
			(
				$args[0] -is [System.Management.Automation.Language.IfStatementAst] -and
				$args[0].Clauses.Item1.Extent.Text -notmatch ('-')
			) -or
			(
				(
					$args[0] -is [System.Management.Automation.Language.DoUntilStatementAst] -or
					$args[0] -is [System.Management.Automation.Language.DoWhileStatementAst] -or
					$args[0] -is [System.Management.Automation.Language.WhileStatementAst]
				) -and
				$args[0].Condition.Extent.Text -notmatch ('-')
			)
		}, $false)
	foreach ($noOperator in $noOperators) {
		$suggestedCorrections = New-Object System.Collections.ObjectModel.Collection["Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent"]
		$suggestedCorrections.add(
			[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
				$noOperator.Extent.StartLineNumber,
				$noOperator.Extent.EndLineNumber,
				$noOperator.Extent.StartColumnNumber,
				$noOperator.Extent.EndColumnNumber,
				'$true -eq ' + $noOperator.Extent.Text,
				$MyInvocation.MyCommand.Definition,
				'Evaluate the condition with an operator against a boolean literal.'
			)
		) | Out-Null
		$results += [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
			'Message'  = 'Conditional statements should be used in conjunction with an operator'
			'Extent'   = $noOperator.Extent
			'RuleName' = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
			'Severity' = 'Warning'
		}
	}
	#>

	return $results
}

function neo42PSEnforceNewLineAtEndOfFile {
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
	[CmdletBinding()]
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst
	)
	Process {
		if ($null -ne $TestAst.Parent) {
			return
		}
		[string]$lastLine = $TestAst.Extent.Text -split [System.Environment]::NewLine | Select-Object -Last 1
		if ($true -eq [string]::IsNullOrWhiteSpace($lastLine)) {
			return
		}
		$suggestedCorrections = New-Object System.Collections.ObjectModel.Collection["Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent"]
		$suggestedCorrections.add(
			[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
				$TestAst.Extent.EndLineNumber,
				$TestAst.Extent.EndLineNumber,
				1,
				$TestAst.Extent.EndColumnNumber,
				$lastLine + "`r`n",
				$MyInvocation.MyCommand.Definition,
				'Add a new line at the end of the file.'
			)
		) | Out-Null
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
		return [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
			'Message'              = 'There should be a new line at the end of the file'
			'Extent'               = $extent
			'RuleName'             = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
			'Severity'             = 'Warning'
			'SuggestedCorrections' = $suggestedCorrections
		}
	}
}

Export-ModuleMember -Function 'neo42*'
