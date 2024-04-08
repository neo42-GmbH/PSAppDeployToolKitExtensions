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
		[string[]]$keywordList = @('if', 'else', 'elseif', 'function', 'foreach', 'for', 'while', 'do', 'in', 'switch', 'try', 'catch', 'finally', 'return', 'break', 'continue', 'throw', 'exit', 'Process', 'Begin', 'End', 'Param')
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
				'RuleName'             = $PSCmdlet.MyInvocation.InvocationName
				'Severity'             = 'Warning'
				'SuggestedCorrections' = $suggestedCorrections
			}
		}
		return $results
	}
}

function neo42PSUseCorrectCmdtletCapitalization {
	<#
	.SYNOPSIS
	Checks that cmndlets are capitalized correctly.
	.DESCRIPTION
	Checks that cmndlets are capitalized correctly.
	.INPUTS
	[System.Management.Automation.Language.ScriptBlockAst]
	.OUTPUTS
	[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
	#>
	[CmdletBinding()]
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst
	)
	Begin {
		[string[]]$cmdtletNames = (Get-Command -CommandType Cmdlet -Module * -ErrorAction SilentlyContinue).Name
	}
	Process {
		[System.Management.Automation.Language.CommandAst[]]$commandAsts = $TestAst.FindAll({
				$args[0] -is [System.Management.Automation.Language.CommandAst]
			}, $false)
		$results = @()
		foreach ($commandAst in $commandAsts) {
			if ($commandAst.InvocationOperator -ne 'Unknown') {
				continue
			}
			[System.Management.Automation.Language.StringConstantExpressionAst]$commandNameAst = $commandAst.CommandElements[0]
			[string]$spelling = $cmdtletNames | Where-Object { $_ -ieq $commandNameAst.Value } | Select-Object -First 1

			if ($null -eq $spelling -or $spelling -ceq $commandNameAst.Value) {
				continue
			}
			## Create a suggestion object
			$suggestedCorrections = New-Object System.Collections.ObjectModel.Collection["Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent"]
			$suggestedCorrections.add(
				[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
					$commandNameAst.Extent.StartLineNumber,
					$commandNameAst.Extent.EndLineNumber,
					$commandNameAst.Extent.StartColumnNumber,
					$commandNameAst.Extent.EndColumnNumber,
					$spelling,
					$MyInvocation.MyCommand.Definition,
					'Apply the correct capitalization.'
				)
			) | Out-Null
			## Return the diagnostic record
			$results += [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
				'Message'              = 'The commandlet is not capitalized correctly.'
				'Extent'               = $commandNameAst.Extent
				'RuleName'             = $PSCmdlet.MyInvocation.InvocationName
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
					'RuleName' = $PSCmdlet.MyInvocation.InvocationName
					'Severity' = 'Warning'
				}
			}
		}
		return $results
	}
}

function neo42PSVariablesInParamBlockShouldBeTyped {
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
		[System.Management.Automation.Language.FunctionDefinitionAst[]]$functions = $TestAst.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)
		$results = @()
		foreach ($functionAst in $functions) {
			[System.Management.Automation.Language.ParamBlockAst]$paramBlockAst = $functionAst.Body.ParamBlock
			if ($null -eq $paramBlockAst) {
				continue
			}
			foreach ($parameterAst in $paramBlockAst.Parameters) {
				if ($parameterAst.StaticType -ne 'System.Object') {
					continue
				}
				$results += [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
					'Message'  = 'A parameter block variable needs to be typed'
					'Extent'   = $parameterAst.Extent
					'RuleName' = $PSCmdlet.MyInvocation.InvocationName
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
				if ($null -eq $namedBlockAst) { continue }
				# Get All capitalized variables that are not automatically defined
				[System.Management.Automation.Language.VariableExpressionAst[]]$capitalizedVariables = $namedBlockAst.FindAll({
						$args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and
						$args[0].VariablePath.UserPath -cmatch '^[A-Z]' -and
						$args[0].VariablePath.UserPath -notin @('ConsoleFileName', 'EnabledExperimentalFeatures', 'Error', 'Event', 'EventArgs', 'EventSubscriber', 'ExecutionContext', 'false', 'foreach', 'HOME', 'Host', 'input', 'IsCoreCLR', 'IsLinux', 'IsMacOS', 'IsWindows', 'LASTEXITCODE', 'Matches', 'MyInvocation', 'NestedPromptLevel', 'null', 'PID', 'PROFILE', 'PSBoundParameters', 'PSCmdlet', 'PSCommandPath', 'PSCulture', 'PSDebugContext', 'PSEdition', 'PSHOME', 'PSItem', 'PSScriptRoot', 'PSSenderInfo', 'PSUICulture', 'PSVersionTable', 'PWD', 'Sender', 'ShellId', 'StackTrace', 'switch', 'this', 'true')
					}, $false)

				foreach ($variableAst in $capitalizedVariables) {
					if ($variableAst.VariablePath.UserPath -in $paramBlockAst.Parameters.Name.VariablePath.UserPath) {
						continue
					}
					$results += [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
						'Message'  = 'A capatalized variable needs to be defined in the param block'
						'Extent'   = $variableAst.Extent
						'RuleName' = $PSCmdlet.MyInvocation.InvocationName
						'Severity' = 'Warning'
					}
				}
			}
		}
		return $results
	}
}

function neo42PSUseTabulatorIntendation {
	<#
	.SYNOPSIS
	Checks that intendation is done with tabulators.
	.DESCRIPTION
	Checks that intendation is done with tabulators.
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
	Begin {
		[regex]$whitespaceRegex = '^[\s]*'
	}
	Process {
		## Only check the root script block
		if ($TestAst.Extent.StartLineNumber -ne 1 -or $TestAst.Extent.StartColumnNumber -ne 1) {
			return
		}
		$results = @()
		[string[]]$lines = $TestAst.Extent.Text -split "$([Environment]::NewLine)"
		[int]$lineNumber = 0
		foreach ($line in $lines) {
			$lineNumber++
			if ($line -match '^\t+(?:[^\s])|^[^\s]|^$') {
				continue
			}
			[int]$count = $whitespaceRegex.Matches($line).Value.Length
			$scriptPositionStart = [System.Management.Automation.Language.ScriptPosition]::new($TestAst.Extent.File, $lineNumber, 1, $line)
			$scriptPositionEnd = [System.Management.Automation.Language.ScriptPosition]::new($TestAst.Extent.File, $lineNumber, 1 + $count, $line)
			$extent = [System.Management.Automation.Language.ScriptExtent]::new($scriptPositionStart, $scriptPositionEnd)
			$results += [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
				'Message'  = 'Use tabulator intendation'
				'RuleName' = $PSCmdlet.MyInvocation.InvocationName
				'Extent'   = $extent
				'Severity' = 'Warning'
			}
		}
		return $results
	}
}

function neo42PSUseTabulatorIntendation {
	<#
	.SYNOPSIS
	Checks that intendation is done with tabulators.
	.DESCRIPTION
	Checks that intendation is done with tabulators.
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
	Begin {
		[regex]$whitespaceRegex = '^[\s]*'
	}
	Process {
		## Only check the root script block
		if ($TestAst.Extent.StartLineNumber -ne 1 -or $TestAst.Extent.StartColumnNumber -ne 1) {
			return
		}
		$results = @()
		[string[]]$lines = $TestAst.Extent.Text -split "$([Environment]::NewLine)"
		[int]$lineNumber = 0
		foreach ($line in $lines) {
			$lineNumber++
			if ($line -match '^\t+(?:[^\s])|^[^\s]|^$') {
				continue
			}
			[int]$count = $whitespaceRegex.Matches($line).Value.Length
			$scriptPositionStart = [System.Management.Automation.Language.ScriptPosition]::new($TestAst.Extent.File, $lineNumber, 1, $line)
			$scriptPositionEnd = [System.Management.Automation.Language.ScriptPosition]::new($TestAst.Extent.File, $lineNumber, 1 + $count, $line)
			$extent = [System.Management.Automation.Language.ScriptExtent]::new($scriptPositionStart, $scriptPositionEnd)
			$results += [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
				'Message'  = 'Use tabulator intendation'
				'RuleName' = $PSCmdlet.MyInvocation.InvocationName
				'Extent'   = $extent
				'Severity' = 'Warning'
			}
		}
		return $results
	}
}

Export-ModuleMember -Function 'neo42*'
