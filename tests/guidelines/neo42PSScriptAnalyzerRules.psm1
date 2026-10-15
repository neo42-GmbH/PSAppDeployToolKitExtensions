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
	if ($Type.IsArray) {
		return (Resolve-TypeFullName -Type $Type.GetElementType()) + '[' + [System.String]::new([System.Char]',', $Type.GetArrayRank() - 1) + ']'
	}
	if ($Type.IsGenericParameter) {
		return $Type.Name
	}
	if (-not $Type.IsGenericType -or $Type.IsGenericTypeDefinition) {
		return $Type.FullName
	}
	[System.Type[]]$genericArguments = $Type.GetGenericArguments()
	[System.String]$definitionName = $Type.GetGenericTypeDefinition().FullName
	# PowerShell infers the arity suffix from the argument count, nested types of generic types need to keep it as their arguments include the ones of the declaring type
	if ($definitionName.EndsWith('`' + $genericArguments.Length)) {
		$definitionName = $definitionName.Substring(0, $definitionName.LastIndexOf('`'))
	}
	[System.String[]]$argumentNames = foreach ($genericArgument in $genericArguments) {
		Resolve-TypeFullName -Type $genericArgument
	}
	return $definitionName + '[' + [System.String]::Join(', ', $argumentNames) + ']'
}

function Get-CasedVariableText {
	<#
	.SYNOPSIS
	Helper function to change the case of the first letter of a variable name while keeping its sigil, braces and scope.
	#>
	param (
		[Parameter(Mandatory)]
		[System.Management.Automation.Language.VariableExpressionAst]
		$VariableAst,
		[System.Management.Automation.SwitchParameter]
		$ToUpper
	)
	[System.String]$text = $VariableAst.Extent.Text
	[System.Int32]$nameStart = if ($text.StartsWith('${')) { 2 } else { 1 }
	[System.Char]$firstLetter = if ($ToUpper) { [System.Char]::ToUpperInvariant($text[$nameStart]) } else { [System.Char]::ToLowerInvariant($text[$nameStart]) }
	return $text.Substring(0, $nameStart) + $firstLetter + $text.Substring($nameStart + 1)
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
		[Parameter(Mandatory)]
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
					[System.Char]::IsLower($args[0].VariablePath.UserPath[0])
				},
				$true
			) | & {
				process {
					$suggestedCorrections = [System.Collections.ObjectModel.Collection[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]]::new()
					$suggestedCorrections.Add(
						[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
							$_.Extent,
							(Get-CasedVariableText -VariableAst $_ -ToUpper),
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
		[Parameter(Mandatory)]
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
					$null = $suggestedCorrections.Add(
						[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
							$variableAst.Extent,
							(Get-CasedVariableText -VariableAst $variableAst),
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
		[Parameter(Mandatory)]
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst
	)
	process {
		if ($null -eq $TestAst.ParamBlock) { return }
		[System.Collections.Generic.List[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = @()
		foreach ($parameterAst in $TestAst.ParamBlock.Parameters) {
			if (-not $parameterAst.Attributes.Where({ $_ -is [System.Management.Automation.Language.TypeConstraintAst] })) {
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
		[Parameter(Mandatory)]
		[System.Management.Automation.Language.ScriptBlockAst]
		$TestAst
	)
	begin {
		# Only equality comparisons can be mirrored without changing the operator
		[System.Management.Automation.Language.TokenKind[]]$equalityOperators = @('Ieq', 'Ine', 'Ceq', 'Cne')
	}
	process {
		[System.Collections.Generic.List[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]]$results = @()
		$TestAst.FindAll({
				$args[0] -is [System.Management.Automation.Language.BinaryExpressionAst] -and
				$args[0].Operator -in $equalityOperators -and
				$args[0].Right.Extent.Text -in @('$true', '$false', '$null')
			},
			$false
		) | & {
			process {
				[System.Management.Automation.Language.BinaryExpressionAst]$wrongSideOperator = $_
				[System.String]$leftText = $wrongSideOperator.Left.Extent.Text
				# Comparisons are left associative, so a chained comparison has to stay grouped once it moves to the right side
				if ($wrongSideOperator.Left -is [System.Management.Automation.Language.BinaryExpressionAst]) {
					$leftText = "($leftText)"
				}
				$suggestedCorrections = [System.Collections.ObjectModel.Collection[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]]::new()
				$null = $suggestedCorrections.Add(
					[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
						$wrongSideOperator.Extent,
						$wrongSideOperator.Right.Extent.Text + ' ' + $wrongSideOperator.ErrorPosition.Text + ' ' + $leftText,
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
		[Parameter(Mandatory)]
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
		[Parameter(Mandatory)]
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
