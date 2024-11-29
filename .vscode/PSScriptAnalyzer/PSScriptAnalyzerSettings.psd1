@{
	IncludeDefaultRules = $true
	Severity            = @(
		'Error',
		'Warning',
		'Information'
	)
	ExcludeRules        = @()
	Rules               = @{
		PSUseCompatibleCmdlets                          = @{
			Enable         = $true
			TargetProfiles = @(
				'desktop-5.1.14393.206-windows',
				'core-6.1.0-windows'
			)
			IgnoreCommands = @(
			)
		}
		PSUseCompatibleCommands                         = @{
			Enable         = $true
			TargetProfiles = @(
				'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework',
				'win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core'
			)
			IgnoreCommands = @(
				'Should',
				'Invoke-Pester',
				'Context',
				'Invoke-Pester',
				'It',
				'Should',
				'Describe',
				'Write-Log'
			)
		}
		PSUseCompatibleSyntax                           = @{
			Enable         = $true
			TargetVersions = @(
				'5.1',
				'7.4'
			)
		}
		PSUSeCompatibleTypes                            = @{
			Enable         = $true
			TargetProfiles = @(
				'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework',
				'win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core'
			)
		}
		PSProvideCommentHelp                            = @{
			Enable                  = $true
			ExportedOnly            = $false
			BlockComment            = $true
			VSCodeSnippetCorrection	= $true
			Placement               = 'begin'
		}
		PSUseConsistentWhitespace                       = @{
			Enable                                  = $true
			CheckInnerBrace                         = $true
			CheckOpenBrace                          = $true
			CheckOpenParen                          = $true
			CheckOperator                           = $true
			CheckPipe                               = $true
			CheckPipeForRedundantWhitespace         = $true
			CheckSeparator                          = $true
			CheckParameter                          = $true
			IgnoreAssignmentOperatorInsideHashTable = $true
		}
		PSUseConsistentIndentation                      = @{
			Enable              = $true
			PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
			Kind                = 'tab'
		}
		PSUseCorrectCasing                              = @{
			Enable = $true
		}
		PSPlaceOpenBrace                                = @{
			Enable             = $true
			OnSameLine         = $true
			NewLineAfter       = $true
			IgnoreOneLineBlock = $false
		}
		PSPlaceCloseBrace                               = @{
			Enable             = $true
			NewLineAfter       = $true
			IgnoreOneLineBlock = $true
			NoEmptyLineBefore  = $true
		}
		PSAvoidSemicolonsAsLineTerminators              = @{
			Enable = $true
		}
		PSAvoidExclaimOperator                          = @{
			Enable = $true
		}
		PSAvoidUsingPositionalParameters                = @{
			Enable           = $true
			CommandAllowList = @()
		}
		PSNxtUseCorrectTokenCapitalization              = @{
			Enable   = $true
			Keywords = @('if', 'else', 'elseif', 'function', 'foreach', 'for', 'while', 'do', 'in', 'switch', 'default', 'try', 'catch', 'finally', 'return', 'break', 'continue', 'throw', 'exit', 'Process', 'Begin', 'End', 'Param')
		}
		PSNxtVariablesInParamBlockMustBeCapitalized     = @{
			Enable = $true
		}
		PSNxtAvoidCapitalizedVarsOutsideParamBlock      = @{
			Enable = $true
		}
		PSNxtParamBlockVariablesShouldBeTyped           = @{
			Enable = $true
		}
		PSNxtDontUseEmptyStringLiteral                  = @{
			Enable = $true
		}
		PSNxtEnforceConsistantConditionalStatementStyle = @{
			Enable = $true
		}
		PSNxtEnforceNewLineAtEndOfFile                  = @{
			Enable = $true
		}
		PSNxtAvoidSpecificFunction                      = @{
			Enable    = $true
			Functions = @{
				'Update-SessionEnvironmentVariables'  = 'Due to security reasons we clear the environment at the start of the Deploy-Application.ps1. Reloading the environment would mitigate this security measure.'
				'Refresh-SessionEnvironmentVariables' = 'Due to security reasons we clear the environment at the start of the Deploy-Application.ps1. Reloading the environment would mitigate this security measure.'
			}
		}
		PSNxtMigrateLegacyFunctionName                  = @{
			Enable    = $true
			Functions = @{
				'Close-BlockExecutionWindow' = 'Close-NxtBlockExecutionWindow'
			}
		}
		PSNxtEnforceOptionalParameter                   = @{
			Enable    = $true
			Functions = @{
				'Write-Log' = @('Source')
			}
		}
	}
	CustomRulePath      = @(
		'.\.vscode\PSScriptAnalyzer\neo42PSScriptAnalyzerRules',
		'.\.vscode\PSScriptAnalyzer\InjectionHunter'
	)
}
