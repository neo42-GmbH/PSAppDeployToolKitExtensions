#Requires -Version 3.0
# Import Localized Data
# Explicit culture needed for culture that do not match when using PowerShell Core: https://github.com/PowerShell/PowerShell/issues/8219
if ([System.Threading.Thread]::CurrentThread.CurrentUICulture.Name -ne 'en-US') {
	Import-LocalizedData -BindingVariable Messages -UICulture 'en-US'
}
else {
	Import-LocalizedData -BindingVariable Messages
}

######################################################################
##
## Rules
##
######################################################################

<#
.DESCRIPTION
    Finds instances of Invoke-Expression, which can be used to invoke arbitrary
    code if supplied with untrusted input.
#>
function Measure-InvokeExpression {
	[CmdletBinding()]
	[OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.Language.ScriptBlockAst]
		$ScriptBlockAst
	)

	[ScriptBlock] $predicate = {
		Param (
			[System.Management.Automation.Language.Ast]
			$Ast
		)

		$targetAst = $Ast -as [System.Management.Automation.Language.CommandAst]
		if ($targetAst) {
			if ($targetAst.CommandElements[0].Extent.Text -in ('Invoke-Expression', 'iex')) {
				return $true
			}
		}
	}

	$foundNode = $ScriptBlockAst.Find($predicate, $false)
	if ($foundNode) {
		$result = New-Object `
			-TypeName 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord' `
			-ArgumentList $Messages.MeasureInvokeExpression, $foundNode.Extent, $PSCmdlet.MyInvocation.InvocationName, Warning, $null
		$results += $result
	}
	return $results
}


function Measure-AddType {
	<#
		.DESCRIPTION
			Find instances of Add-Type, which can be used to run arbitrary code if supplied with untrusted input.
	#>
	[CmdletBinding()]
	[OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.Language.ScriptBlockAst]
		$ScriptBlockAst
	)

	[ScriptBlock] $predicate = {
		Param (
			[System.Management.Automation.Language.Ast]
			$Ast
		)

		$targetAst = $Ast -as [System.Management.Automation.Language.CommandAst]
		if ($targetAst) {
			if ($targetAst.CommandElements[0].Extent.Text -eq 'Add-Type') {
				$addTypeParameters = [System.Management.Automation.Language.StaticParameterBinder]::BindCommand($targetAst)
				$typeDefinitionParameter = $addTypeParameters.BoundParameters.TypeDefinition

				## If it's not a constant value, check if it's a variable with a constant value
				if (-not $typeDefinitionParameter.ConstantValue) {
					if ($addTypeParameters.BoundParameters.TypeDefinition.Value -is [System.Management.Automation.Language.VariableExpressionAst]) {
						$variableName = $addTypeParameters.BoundParameters.TypeDefinition.Value.VariablePath.UserPath
						$constantAssignmentForVariable = $ScriptBlockAst.FindAll( {
								Param (
									[System.Management.Automation.Language.Ast]
									$Ast
								)

								$assignmentAst = $Ast -as [System.Management.Automation.Language.AssignmentStatementAst]
								if ($assignmentAst -and
                               ($assignmentAst.Left.VariablePath.UserPath -eq $variableName) -and
                               ($assignmentAst.Right.Expression -is [System.Management.Automation.Language.ConstantExpressionAst])) {
									return $true
								}
							}, $true)

						if ($constantAssignmentForVariable) {
							return $false
						}
						else {
							return $true
						}
					}

					return $true
				}
			}
		}
	}

	$foundNode = $ScriptBlockAst.Find($predicate, $false)
	if ($foundNode) {
		$result = New-Object `
			-TypeName 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord' `
			-ArgumentList $Messages.MeasureAddType, $foundNode.Extent, $PSCmdlet.MyInvocation.InvocationName, Warning, $null
		$results += $result
	}
	return $results
}


<#
.DESCRIPTION
    Finds instances of dangerous methods, which can be used to invoke arbitrary
    code if supplied with untrusted input.
#>
function Measure-DangerousMethod {
	[CmdletBinding()]
	[OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.Language.ScriptBlockAst]
		$ScriptBlockAst
	)

	[ScriptBlock] $predicate = {
		Param (
			[System.Management.Automation.Language.Ast]
			$Ast
		)

		$targetAst = $Ast -as [System.Management.Automation.Language.InvokeMemberExpressionAst]
		if ($targetAst) {
			if ($targetAst.Member.Extent.Text -in ('InvokeScript', 'CreateNestedPipeline', 'AddScript', 'NewScriptBlock', 'ExpandString')) {
				return $true
			}

			if (($targetAst.Member.Extent.Text -eq 'Create') -and
               ($targetAst.Expression.Extent.Text -match 'ScriptBlock')) {
				return $true
			}
		}
	}

	$foundNode = $ScriptBlockAst.Find($predicate, $false)
	<#if($foundNode)
    {
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord] @{
            "Message"  = "Possible script injection risk via the a dangerous method. Untrusted input can cause " +
                         "arbitrary PowerShell expressions to be run. The PowerShell.AddCommand().AddParameter() APIs " +
                         "should be used instead."
            "Extent"   = $foundNode.Extent
            "RuleName" = "InjectionRisk.$($foundNode.Member.Extent.Text)"
            "Severity" = "Warning" }
    }#>
	if ($foundNode) {
		$result = New-Object `
			-TypeName 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord' `
			-ArgumentList $($Messages.MeasureDangerousMethod + $foundNode.Extent), $foundNode.Extent, $PSCmdlet.MyInvocation.InvocationName, Warning, $null
		$results += $result
	}
	return $results
}


<#
.DESCRIPTION
    Finds instances of command invocation with user input, which can be abused for
    command injection.
#>
function Measure-CommandInjection {
	[CmdletBinding()]
	[OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.Language.ScriptBlockAst]
		$ScriptBlockAst
	)

	## Finds CommandAst nodes that invoke PowerShell or CMD with user input
	[ScriptBlock] $predicate = {
		Param (
			[System.Management.Automation.Language.Ast]
			$Ast
		)

		$targetAst = $Ast -as [System.Management.Automation.Language.CommandAst]
		if ($targetAst) {
			if ($targetAst.CommandElements[0].Extent.Text -match 'cmd|powershell') {
				$commandInvoked = $targetAst.CommandElements[1]
				for ($parameterPosition = 1; $parameterPosition -lt $targetAst.CommandElements.Count; $parameterPosition++) {
					if ($targetAst.CommandElements[$parameterPosition].Extent.Text -match '/c|/k|command') {
						$commandInvoked = $targetAst.CommandElements[$parameterPosition + 1]
						break
					}
				}

				if ($commandInvoked -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) {
					return $true
				}
			}
		}
	}

	$foundNode = $ScriptBlockAst.Find($predicate, $false)
	if ($foundNode) {
		$result = New-Object `
			-TypeName 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord' `
			-ArgumentList $Messages.MeasureCommandInjection, $foundNode.Extent, $PSCmdlet.MyInvocation.InvocationName, Warning, $null
		$results += $result
	}
	return $results
}


<#
.DESCRIPTION
    Finds instances of Foreach-Object used with non-constant member names, which can be abused for
    arbitrary member access / invocation when supplied with untrusted user input.
#>
function Measure-ForeachObjectInjection {
	[CmdletBinding()]
	[OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.Language.ScriptBlockAst]
		$ScriptBlockAst
	)

	## Finds CommandAst nodes that invoke Foreach-Object with user input
	[ScriptBlock]$predicate = {
		Param (
			[System.Management.Automation.Language.Ast]
			$Ast
		)

		$targetAst = $Ast -as [System.Management.Automation.Language.CommandAst]
		if ($targetAst) {
			if ($targetAst.CommandElements[0].Extent.Text -match 'foreach|%') {
				$memberInvoked = $targetAst.CommandElements[1]
				for ($parameterPosition = 1; $parameterPosition -lt $targetAst.CommandElements.Count; $parameterPosition++) {
					if ($targetAst.CommandElements[$parameterPosition].Extent.Text -match 'Process|MemberName') {
						$memberInvoked = $targetAst.CommandElements[$parameterPosition + 1]
						break
					}
				}

				if ((-not ($memberInvoked -is [System.Management.Automation.Language.ConstantExpressionAst])) -and
                   (-not ($memberInvoked -is [System.Management.Automation.Language.ScriptBlockExpressionAst]))) {
					return $true
				}
			}
		}
	}

	$foundNode = $ScriptBlockAst.Find($predicate, $false)
	if ($foundNode) {
		$result = New-Object `
			-TypeName 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord' `
			-ArgumentList $($Messages.MeasureForeachObjectInjection + $FoundNode.Extent), $foundNode.Extent, $PSCmdlet.MyInvocation.InvocationName, Warning, $null
		$results += $result
	}
	return $results
}

<#
.DESCRIPTION
    Finds instances of dynamic static property access, which can be vulnerable to property injection if
    supplied with untrusted user input.
#>
function Measure-PropertyInjection {
	[CmdletBinding()]
	[OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.Language.ScriptBlockAst]
		$ScriptBlockAst
	)

	## Finds MemberExpressionAst that uses a non-constant member
	[ScriptBlock]$predicate = {
		Param (
			[System.Management.Automation.Language.Ast]
			$Ast
		)

		$targetAst = $Ast -as [System.Management.Automation.Language.MemberExpressionAst]
		$methodAst = $Ast -as [System.Management.Automation.Language.InvokeMemberExpressionAst]
		if ($targetAst -and (-not $methodAst)) {
			if (-not ($targetAst.Member -is [System.Management.Automation.Language.ConstantExpressionAst])) {
				## This is not constant access, therefore dangerous
				return $true
			}
		}
	}

	$foundNode = $ScriptBlockAst.Find($predicate, $false)
	if ($foundNode) {
		$result = New-Object `
			-TypeName 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord' `
			-ArgumentList $($Messages.MeasurePropertyInjection + $FoundNode.Extent), $foundNode.Extent, $PSCmdlet.MyInvocation.InvocationName, Warning, $null
		$results += $result
	}
	return $results
}


<#
.DESCRIPTION
    Finds instances of dynamic method invocation, which can be used to invoke arbitrary
    methods if supplied with untrusted input.
#>
function Measure-MethodInjection {
	[CmdletBinding()]
	[OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.Language.ScriptBlockAst]
		$ScriptBlockAst
	)

	## Finds MemberExpressionAst nodes that don't invoke a constant expression
	[ScriptBlock]$predicate = {
		Param (
			[System.Management.Automation.Language.Ast]
			$Ast
		)

		$targetAst = $Ast -as [System.Management.Automation.Language.InvokeMemberExpressionAst]
		if ($targetAst) {
			if (-not ($targetAst.Member -is [System.Management.Automation.Language.ConstantExpressionAst])) {
				return $true
			}
		}
	}

	$foundNode = $ScriptBlockAst.Find($predicate, $false)
	if ($foundNode) {
		$result = New-Object `
			-TypeName 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord' `
			-ArgumentList $($Messages.MeasureMethodInjection + $FoundNode.Extent), $foundNode.Extent, $PSCmdlet.MyInvocation.InvocationName, Warning, $null
		$results += $result
	}
	return $results
}

<#
.DESCRIPTION
    Finds instances of unsafe string escaping, which is then likely to be used in a situation (like Invoke-Expression)
    where it is unsafe to use. methods if supplied with untrusted input.
    [System.Management.Automation.Language.CodeGeneration]::Escape* should be used instead.
#>
function Measure-UnsafeEscaping {
	[CmdletBinding()]
	[OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.Language.ScriptBlockAst]
		$ScriptBlockAst
	)

	## Finds replace operators likely being used to escape strings improperly
	[ScriptBlock]$predicate = {
		Param (
			[System.Management.Automation.Language.Ast]
			$Ast
		)

		$targetAst = $Ast -as [System.Management.Automation.Language.BinaryExpressionAst]
		if ($targetAst) {
			if (($targetAst.Operator -match 'replace') -and
               ($targetAst.Right.Extent.Text -match '`"|''''')) {
				return $true
			}
		}
	}

	$foundNode = $ScriptBlockAst.Find($predicate, $false)
	if ($foundNode) {
		$result = New-Object `
			-TypeName 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord' `
			-ArgumentList $Messages.MeasureUnsafeEscaping, $foundNode.Extent, $PSCmdlet.MyInvocation.InvocationName, Warning, $null
		$results += $result
	}
	return $results
}
