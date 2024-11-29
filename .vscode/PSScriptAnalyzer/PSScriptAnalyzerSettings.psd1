@{
	IncludeDefaultRules = $true
	Rules               = @{
		# Rules extracted from PSScriptAnalyzer 1.23.0
		# https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/readme?view=ps-modules
		PSAlignAssignmentStatement                      = @{
			Enable         = $true
			CheckHashtable = $true
		}
		PSAvoidAssignmentToAutomaticVariable            = @{
			Enable = $true
		}
		PSAvoidDefaultValueForMandatoryParameter        = @{
			Enable = $true
		}
		PSAvoidDefaultValueSwitchParameter              = @{
			Enable = $true
		}
		PSAvoidExclaimOperator                          = @{
			Enable = $true
		}
		PSAvoidGlobalAliases                            = @{
			Enable = $true
		}
		PSAvoidGlobalFunctions                          = @{
			Enable = $true
		}
		PSAvoidGlobalVars                               = @{
			Enable = $true
		}
		PSAvoidInvokingEmptyMembers                     = @{
			Enable = $true
		}
		PSAvoidLongLines                                = @{
			Enable            = $true
			MaximumLineLength = 256
		}
		PSAvoidMultipleTypeAttributes                   = @{
			Enable = $true
		}
		PSAvoidNullOrEmptyHelpMessageAttribute          = @{
			Enable = $true
		}
		PSAvoidOverwritingBuiltInCmdlets                = @{
			PowerShellVersion = @(
				'desktop-5.1.14393.206-windows',
				'core-6.1.0-windows'
			)
		}
		PSAvoidSemicolonsAsLineTerminators              = @{
			Enable    = $true
			AllowList = @()
		}
		PSAvoidShouldContinueWithoutForceSwitch         = @{
			Enable = $true
		}
		PSAvoidTrailingWhitespace                       = @{
			Enable = $true
		}
		PSAvoidUsingAllowUnencryptedAuthentication      = @{
			Enable = $true
		}
		PSAvoidUsingBrokenHashAlgorithms                = @{
			Enable = $true
		}
		PSAvoidUsingCmdletAliases                       = @{
			Enable = $true
		}
		PSAvoidUsingComputerNameHardcoded               = @{
			Enable = $true
		}
		PSAvoidUsingConvertToSecureStringWithPlainText  = @{
			Enable = $true
		}
		PSAvoidUsingDeprecatedManifestFields            = @{
			Enable = $true
		}
		PSAvoidUsingDoubleQuotesForConstantString       = @{
			Enable = $true
		}
		PSAvoidUsingEmptyCatchBlock                     = @{
			Enable = $true
		}
		PSAvoidUsingInvokeExpression                    = @{
			Enable = $true
		}
		PSAvoidUsingPlainTextForPassword                = @{
			Enable = $true
		}
		PSAvoidUsingPositionalParameters                = @{
			Enable           = $true
			CommandAllowList = @()
		}
		PSAvoidUsingUsernameAndPasswordParams           = @{
			Enable = $true
		}
		PSAvoidUsingWMICmdlet                           = @{
			Enable = $true
		}
		PSAvoidUsingWriteHost                           = @{
			Enable = $true
		}
		PSMisleadingBacktick                            = @{
			Enable = $true
		}
		PSMissingModuleManifestField                    = @{
			Enable = $true
		}
		PSPlaceCloseBrace                               = @{
			Enable             = $true
			NewLineAfter       = $true
			IgnoreOneLineBlock = $true
			NoEmptyLineBefore  = $true
		}
		PSPlaceOpenBrace                                = @{
			Enable             = $true
			OnSameLine         = $true
			NewLineAfter       = $true
			IgnoreOneLineBlock = $false
		}
		PSPossibleIncorrectComparisonWithNull           = @{
			Enable = $true
		}
		PSPossibleIncorrectUsageOfAssignmentOperator    = @{
			Enable = $true
		}
		PSPossibleIncorrectUsageOfRedirectionOperator   = @{
			Enable = $true
		}
		PSProvideCommentHelp                            = @{
			Enable                  = $true
			ExportedOnly            = $false
			BlockComment            = $true
			VSCodeSnippetCorrection	= $true
			Placement               = 'begin'
		}
		PSReservedCmdletChar                            = @{
			Enable = $true
		}
		PSReservedParams                                = @{
			Enable = $true
		}
		PSReviewUnusedParameters                        = @{
			Enable = $true
		}
		PSUseApprovedVerbs                              = @{
			Enable = $true
		}
		PSUseBOMForUnicodeEncodedFile                   = @{
			Enable = $true
		}
		PSUseCmdletCorrectly                            = @{
			Enable = $true
		}
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
		PSUseConsistentIndentation                      = @{
			Enable              = $true
			PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
			Kind                = 'tab'
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
		PSUseCorrectCasing                              = @{
			Enable = $true
		}
		PSUseDeclaredVarsMoreThanAssignments            = @{
			Enable = $true
		}
		PSUseLiteralInitializerForHashtable             = @{
			Enable = $true
		}
		PSUseOutputTypeCorrectly                        = @{
			Enable = $true
		}
		PSUseProcessBlockForPipelineCommand             = @{
			Enable = $true
		}
		PSUsePSCredentialType                           = @{
			Enable = $true
		}
		PSUseShouldProcessForStateChangingFunctions     = @{
			Enable = $true
		}
		PSUseSingularNouns                              = @{
			Enable = $true
		}
		PSUseSupportsShouldProcess                      = @{
			Enable = $true
		}
		PSUseToExportFieldsInManifest                   = @{
			Enable = $true
		}
		PSUseUsingScopeModifierInNewRunspaces           = @{
			Enable = $true
		}
		PSUseUTF8EncodingForHelpFiles                   = @{
			Enable = $true
		}

		# neo42
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
