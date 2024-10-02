function Get-NxtPSUseCorrectTokenCapitalization {
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
		[System.Management.Automation.Language.Token[]]
		$TestToken
	)
	Begin {
		[string[]]$keywordList = @('if', 'else', 'elseif', 'function', 'foreach', 'for', 'while', 'do', 'in', 'switch', 'default', 'try', 'catch', 'finally', 'return', 'break', 'continue', 'throw', 'exit', 'Process', 'Begin', 'End', 'Param')
		[hashtable]$keywordHash = @{}
		foreach ($keyword in $keywordList) {
			$keywordHash[$keyword] = $keyword
		}
	}
	Process {
		[System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = [System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]::new()
		foreach ($token in $TestToken) {
			## Check if the token is a keyword and if it is already in the correct case
			if ($false -eq $token.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::Keyword)) {
				continue
			}
			## Check if we have a suggestion, otherwise return nothing
			if ($false -eq $keywordHash.ContainsKey($token.Text) -or $keywordHash[$token.Text] -ceq $token.Text) {
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
					$keywordHash[$token.Text],
					$MyInvocation.MyCommand.Definition,
					'Apply the correct capitalization.'
				)
			)
			## Return the diagnostic record
			$results.Add([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
					'Message'              = 'The token is not capitalized correctly.'
					'Extent'               = $token.Extent
					'RuleName'             = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
					'Severity'             = 'Warning'
					'SuggestedCorrections' = $suggestedCorrections
				})
		}
		return $results
	}
}

function Get-NxtPSVariablesInParamBlockShouldBeCapitalized {
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
		$TestAst
	)
	Process {
		[System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = [System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]::new()
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
				$results.Add([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
						'Message'  = 'A parameter block variable needs to start with a capital letter'
						'Extent'   = $parameterVariableAst.Extent
						'RuleName' = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
						'Severity' = 'Warning'
					})
			}
		}
		return $results
	}
}

function Get-NxtPSCapatalizedVariablesNeedToOriginateFromParamBlock {
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
		$TestAst
	)
	Process {
		[System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = [System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]::new()
		[System.Management.Automation.Language.VariableExpressionAst[]]$capitalizedVariables = $TestAst.FindAll({
				$args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and
				$args[0].VariablePath.UserPath -cmatch '^[A-Z]' -and
				$args[0].VariablePath.UserPath -notin @('ConsoleFileName', 'EnabledExperimentalFeatures', 'Error', 'Event', 'EventArgs', 'EventSubscriber', 'ExecutionContext', 'HOME', 'Host', 'IsCoreCLR', 'IsLinux', 'IsMacOS', 'IsWindows', 'LASTEXITCODE', 'Matches', 'MyInvocation', 'HostInvocation', 'NestedPromptLevel', 'PID', 'PROFILE', 'PSBoundParameters', 'PSCmdlet', 'PSCommandPath', 'PSCulture', 'PSDebugContext', 'PSEdition', 'PSHOME', 'PSItem', 'PSScriptRoot', 'PSSenderInfo', 'PSUICulture', 'PSVersionTable', 'PWD', 'Sender', 'ShellId', 'StackTrace')
			}, $false)

		foreach ($variableAst in $capitalizedVariables) {
			if ($variableAst.VariablePath.UserPath -notin $TestAst.ParamBlock.Parameters.Name.VariablePath.UserPath) {
				$results.Add([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
						'Message'  = 'A capatalized variable needs to be defined in the param block'
						'Extent'   = $variableAst.Extent
						'RuleName' = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
						'Severity' = 'Warning'
					})
			}
		}
		return $results
	}
}

function Get-NxtPSParamBlockVariablesShouldBeTyped {
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
		$TestAst
	)
	Process {
		if ($null -eq $TestAst.ParamBlock) {
			return
		}
		[System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = [System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]::new()
		foreach ($parameterAst in $TestAst.ParamBlock.Parameters) {
			if ($null -eq $parameterAst.Attributes.TypeName) {
				$results.Add([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
						'Message'  = 'A parameter block variable needs to be typed'
						'Extent'   = $parameterAst.Extent
						'RuleName' = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
						'Severity' = 'Warning'
					})
			}
			elseif ($parameterAst.Attributes.TypeName.Extent.StartLineNumber -eq $parameterAst.Name.Extent.StartLineNumber) {
				$results.Add([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
						'Message'  = 'The type definition and variable should be on a seperate lines'
						'Extent'   = $parameterAst.Extent
						'RuleName' = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
						'Severity' = 'Warning'
					})
			}
		}
		return $results
	}
}

function Get-NxtPSDontUseEmptyStringLiterals {
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
		$TestAst
	)
	Process {
		[System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = [System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]::new()
		[System.Management.Automation.Language.StringConstantExpressionAst[]]$stringConstants = $TestAst.FindAll({
				$args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
				$args[0].Value -eq [string]::Empty
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
			$results.Add([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
					'Message'              = 'Empty strings should not be used'
					'Extent'               = $stringConstant.Extent
					'RuleName'             = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
					'Severity'             = 'Warning'
					'SuggestedCorrections' = $suggestedCorrections
				})
		}
		return $results
	}
}

function Get-NxtPSEnforceConsistantConditionalStatements {
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
		$TestAst
	)
	[System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = [System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]::new()
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

		$results.Add([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
				'Message'              = 'Boolean literals should be on the left side of a comparison'
				'Extent'               = $wrongSideOperator.Extent
				'RuleName'             = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
				'Severity'             = 'Warning'
				'SuggestedCorrections' = $suggestedCorrections
			})
	}
	return $results
}

function Get-NxtPSEnforceNewLineAtEndOfFile {
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
		$TestAst
	)
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
		return [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
			'Message'              = 'There should be a new line at the end of the file'
			'Extent'               = $extent
			'RuleName'             = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
			'Severity'             = 'Warning'
			'SuggestedCorrections' = $suggestedCorrections
		}
	}
}

function Get-NxtPSIncompatibleFunctions {
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
		$TestAst
	)
	Begin {
		[hashtable]$incompatibleFunctions = @{
			'Update-SessionEnvironmentVariables'  = 'Due to security reasons we clear the environment at the start of the Deploy-Application.ps1. Reloading the environment would mitigate this security measure.'
			'Refresh-SessionEnvironmentVariables' = 'Due to security reasons we clear the environment at the start of the Deploy-Application.ps1. Reloading the environment would mitigate this security measure.'
		}
	}
	Process {
		[System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = [System.Collections.Generic.List[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]]::new()

		[System.Management.Automation.Language.CommandAst[]]$commandAsts = $TestAst.FindAll({
				$args[0] -is [System.Management.Automation.Language.CommandAst] -and
				$args[0].GetCommandName() -in $incompatibleFunctions.Keys
			}, $false)

		foreach ($commandAst in $commandAsts) {
			$results.Add([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
					'Message'  = $incompatibleFunctions[$commandAst.GetCommandName()]
					'Extent'   = $commandAst.Extent
					'RuleName' = Split-Path -Leaf $PSCmdlet.MyInvocation.InvocationName
					'Severity' = 'Warning'
				})
		}

		return $results
	}
}

Export-ModuleMember -Function 'Get-NxtPS*'
