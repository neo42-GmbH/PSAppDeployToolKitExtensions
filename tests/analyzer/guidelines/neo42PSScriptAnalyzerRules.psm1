[System.Collections.Generic.HashSet[System.String]]$script:BuiltInVariables = [System.Collections.Generic.HashSet[System.String]]::new(
	[System.String[]]@(
		'ConsoleFileName', 'EnabledExperimentalFeatures', 'Error', 'Event', 'EventArgs', 'EventSubscriber', 'ExecutionContext', 'HOME', 'Host', 'IsCoreCLR', 'MyInvocation',
		'IsLinux', 'IsMacOS', 'IsWindows', 'LASTEXITCODE', 'Matches', 'NestedPromptLevel', 'PID', 'PROFILE', 'PWD', 'Sender', 'ShellId', 'StackTrace', 'OutputEncoding',
		'InformationPreference', 'WarningPreference', 'ErrorActionPreference', 'DebugPreference', 'VerbosePreference', 'ProgressPreference',
		'PSBoundParameters', 'PSCmdlet', 'PSCommandPath', 'PSCulture', 'PSDebugContext', 'PSEdition', 'PSHOME', 'PSItem', 'PSScriptRoot', 'PSSenderInfo', 'PSUICulture', 'PSVersionTable'
	),
	[System.StringComparer]::OrdinalIgnoreCase
)

function Resolve-TypeFullName {
	<#
	.SYNOPSIS
	Helper function to resolve a full type name from a Type object.
	#>
	param (
		[Parameter(Mandatory)]
		[System.Type]
		$Type
	)
	[System.Text.StringBuilder]$name = [System.Text.StringBuilder]::new()
	if ($Type.IsNested) {
		$null = $name.Append((Resolve-TypeFullName -Type $Type.DeclaringType))
		$null = $name.Append('+')
	}
	else {
		$null = $name.Append($Type.Namespace)
		$null = $name.Append('.')
	}
	$null = $name.Append($Type.Name.Split('`')[0])
	if ($Type.IsGenericType) {
		$null = $name.Append('[')
		foreach ($arg in $Type.GetGenericArguments()) {
			if ($name[-1] -ne '[') { $null = $name.Append(', ') }
			$null = $name.Append((Resolve-TypeFullName -Type $arg))
		}
		$null = $name.Append(']')
	}
	return $name.ToString()
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
	param (
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst
	)
	process {
		if (-not $TestAst.ParamBlock) { return }
		[System.Collections.Generic.List[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = @()
		foreach ($parameter in $TestAst.ParamBlock.Parameters) {
			$TestAst.FindAll(
				{
					$args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and
					$args[0].VariablePath.UserPath -eq $parameter.Name.VariablePath.UserPath -and
					-not [System.Char]::IsUpper($args[0].VariablePath.UserPath[0])
				},
				$true
			) | & {
				process {
					$suggestedCorrections = [System.Collections.ObjectModel.Collection[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]]::new()
					$suggestedCorrections.Add(
						[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
							$_.Extent,
							('$' + $_.VariablePath.UserPath.SubString(0, 1).ToUpper() + $_.VariablePath.UserPath.SubString(1, $_.VariablePath.UserPath.Length - 1)),
							$MyInvocation.MyCommand.Definition,
							'Capitalize the first letter of the parameter variable.'
						)
					)
					$results.Add(
						[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
							'Message'              = "A parameter block variable '$($parameter.Name.VariablePath.UserPath)' should be capitalized."
							'Extent'               = $_.Extent
							'RuleName'             = 'PSNxtVariablesInParamBlockMustBeCapitalized'
							'RuleSuppressionID'    = $parameter.Name.VariablePath.UserPath
							'Severity'             = 'Warning'
							'SuggestedCorrections' = $suggestedCorrections
						}
					)
				}
			}
		}
		$results.ToArray()
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
	param (
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst
	)
	process {
		[System.Collections.Generic.List[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = @()
		$TestAst.FindAll({
				$args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and
				[System.Char]::IsUpper($args[0].VariablePath.UserPath[0]) -and
				-not $script:BuiltInVariables.Contains($args[0].VariablePath.UserPath)
			},
			$false
		) | & {
			begin {
				[System.Collections.Generic.List[System.Management.Automation.Language.ParameterAst]]$parameters = [System.Collections.Generic.List[System.Management.Automation.Language.ParameterAst]]::new()
				[System.Management.Automation.Language.Ast]$currentAst = $TestAst
				do {
					if ($currentAst -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $currentAst.Parameters) {
						$parameters.AddRange($currentAst.Parameters)
					}
					elseif ($currentAst -is [System.Management.Automation.Language.ScriptBlockAst] -and $currentAst.ParamBlock -and $currentAst.ParamBlock.Parameters) {
						$parameters.AddRange($currentAst.ParamBlock.Parameters)
					}
					$currentAst = $currentAst.Parent
				} while ($currentAst)
			}
			process {
				[System.Management.Automation.Language.VariableExpressionAst]$variableAst = $_
				if ($variableAst.VariablePath.UserPath -notin $parameters.Name.VariablePath.UserPath) {
					$suggestedCorrections = [System.Collections.ObjectModel.Collection[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]]::new()
					[System.String]$varName = $variableAst.VariablePath.UserPath
					[System.String]$prefix = $variableAst.Extent.Text.SubString(0, 1)
					$null = $suggestedCorrections.Add(
						[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
							$variableAst.Extent,
							($prefix + $varName.SubString(0, 1).ToLower() + $varName.SubString(1, $varName.Length - 1)),
							$MyInvocation.MyCommand.Definition,
							'Use lowercase variable names outside of the param block.'
						)
					)
					$null = $results.Add([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
							'Message'              = "Variable '$($($variableAst.VariablePath.UserPath))' should not be capitalized or should originate from the param block"
							'Extent'               = $variableAst.Extent
							'RuleName'             = 'PSNxtAvoidCapitalizedVarsOutsideParamBlock'
							'RuleSuppressionID'    = $variableAst.VariablePath.UserPath
							'Severity'             = 'Warning'
							'SuggestedCorrections' = $suggestedCorrections
						})
				}
			}
		}
		$results.ToArray()
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
	param (
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst
	)
	process {
		if ($null -eq $TestAst.ParamBlock) { return }
		[System.Collections.Generic.List[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = @()
		foreach ($parameterAst in $TestAst.ParamBlock.Parameters) {
			if ($null -eq $parameterAst.Attributes.TypeName) {
				$null = $results.Add([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
						'Message'           = 'A parameter block variable needs to be typed'
						'Extent'            = $parameterAst.Extent
						'RuleName'          = 'PSNxtParamBlockVariablesShouldBeTyped'
						'RuleSuppressionID' = $parameterAst.Name.VariablePath.UserPath
						'Severity'          = 'Warning'
					})
			}
		}
		$results.ToArray()
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
	param (
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst
	)
	process {
		[System.Collections.Generic.List[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = @()
		$TestAst.FindAll({
				$args[0] -is [System.Management.Automation.Language.BinaryExpressionAst] -and
				$args[0].Right.Extent.Text -in @('$true', '$false', '$null')
			},
			$false
		) | & {
			process {
				[System.Management.Automation.Language.BinaryExpressionAst]$wrongSideOperator = $_
				$suggestedCorrections = [System.Collections.ObjectModel.Collection[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]]::new()
				$null = $suggestedCorrections.Add(
					[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
						$wrongSideOperator.Extent,
						$wrongSideOperator.Right.Extent.Text + ' -' + $wrongSideOperator.Operator.ToString().ToLower() + ' ' + $wrongSideOperator.Left.Extent.Text,
						$MyInvocation.MyCommand.Definition,
						'Switch the boolean literal to the left side of the comparison.'
					)
				)

				$null = $results.Add([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
						'Message'              = 'Constant expressions should be on the left side of the operator in conditional statements.'
						'Extent'               = $wrongSideOperator.Extent
						'RuleName'             = 'PSNxtEnforceConsistantConditionalStatement'
						'Severity'             = 'Warning'
						'SuggestedCorrections' = $suggestedCorrections
					})
			}
		}

		$results.ToArray()
	}
}

function PSNxtAvoidTypeAccelerator {
	<#
	.SYNOPSIS
	Checks that type accelerators are not used.
	.DESCRIPTION
	Checks that type accelerators are not used.
	.INPUTS
	[System.Management.Automation.Language.ScriptBlockAst]
	.OUTPUTS
	[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
	#>
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	param (
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst
	)
	process {
		[System.Collections.Generic.List[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = @()
		$TestAst.FindAll({
				(
					$args[0] -is [System.Management.Automation.Language.TypeConstraintAst] -or
					$args[0] -is [System.Management.Automation.Language.TypeExpressionAst]
				) -and
				$args[0].TypeName.Extent.Text -notin @('ref', 'PSCustomObject', 'PSCustomObject[]') # Ref and PSCustomObject are special as the full type name in pwsh is not the same as the accelerator
			},
			$false
		) | & {
			process {
				[System.Management.Automation.Language.Ast]$typeAst = $_
				if (-not ([System.Type]$type = $typeAst.TypeName.GetReflectionType())) { return }
				[System.String]$typeName = Resolve-TypeFullName -Type $type
				if (-not $typeAst.TypeName.Extent.Text.Equals($typeName)) {
					[System.String]$replacementText = $typeAst.Extent.Text.SubString(0, $typeAst.TypeName.Extent.StartOffset - $typeAst.Extent.StartOffset) + $typeName + $typeAst.Extent.Text.SubString($typeAst.TypeName.Extent.EndOffset - $typeAst.Extent.StartOffset)
					$suggestedCorrections = [System.Collections.ObjectModel.Collection[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]]::new()
					$null = $suggestedCorrections.Add(
						[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
							$typeAst.Extent,
							$replacementText,
							$MyInvocation.MyCommand.Definition,
							'Use the full type name instead of the type accelerator.'
						)
					)
					$null = $results.Add(
						[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
							'Message'              = 'Type accelerators should not be used.'
							'Extent'               = $typeAst.Extent
							'RuleName'             = 'PSNxtAvoidTypeAccelerator'
							'RuleSuppressionID'    = $typeAst.TypeName.Extent.Text
							'Severity'             = 'Warning'
							'SuggestedCorrections' = $suggestedCorrections
						}
					)
				}
			}
		}

		$results.ToArray()
	}
}

function PSNxtAvoidBaseTypes {
	<#
	.SYNOPSIS
	Checks that type constraints are not too generic.
	.DESCRIPTION
	Checks that type constraints are not too generic.
	.INPUTS
	[System.Management.Automation.Language.ScriptBlockAst]
	.OUTPUTS
	[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
	#>
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	param (
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst
	)
	begin {
		[System.Type[]]$typesToAvoid = @([System.Object], [System.Array], [System.Collections.ArrayList])
	}
	process {
		[System.Collections.Generic.List[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = @()
		$TestAst.FindAll({
				$args[0] -is [System.Management.Automation.Language.TypeConstraintAst] -and
				([System.Type]$type = $(try { [System.Type]$args[0].TypeName.Extent.Text } catch { $null })) -and
				$type -in $typesToAvoid
			},
			$false
		) | & {
			process {
				$results.Add(
					[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
						'Message'           = 'Use more specific type constraints instead of base types like System.Object or System.Array'
						'Extent'            = $_.Extent
						'RuleName'          = 'PSNxtAvoidBaseTypes'
						'RuleSuppressionID' = $_.TypeName.Extent.Text
						'Severity'          = 'Warning'
					})
			}
		}

		$results.ToArray()
	}
}

Export-ModuleMember -Function 'PSNxt*'
