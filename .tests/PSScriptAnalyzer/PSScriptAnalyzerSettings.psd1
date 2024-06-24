# PSAppDeployToolkitExtension default rules for PSScriptAnalyser, to ensure compatibility with PowerSHell 5.1 and ensure coding standards are met.
@{
	IncludeDefaultRules = $true
	Severity            = @(
		'Error',
		'Warning',
		'Information'
	)
	ExcludeRules        = @(
		'PSUseDeclaredVarsMoreThanAssignments', # PSADT uses global variables
		'PSAvoidGlobalVars', # PSADT uses global variables
		'PSUseShouldProcessForStateChangingFunctions', # We don't use ShouldProcess in our scripts
		'PSUseOutputTypeCorrectly', # Does not work good with array types
		'PSAvoidUsingWriteHost' # Ignored because we use Write-Host in tools
		'PSUseSingularNouns' # Ignored because we use plural nouns
		'PSAvoidUsingEmptyCatchBlock' # Ignored because we use empty catch blocks
	)
	Rules               = @{
		PSUseCompatibleCmdlets             = @{
			Enable         = $true
			TargetProfiles = @(
				'desktop-5.1.14393.206-windows'
			)
			IgnoreCommands = @(
			)
		}
		PSUseCompatibleCommands            = @{
			Enable         = $true
			TargetProfiles = @(
				'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'
			)
			IgnoreCommands = @(
				'Should',
				'Invoke-Pester',
				'Write-Log'
			)
		}
		PSUseCompatibleSyntax              = @{
			Enable         = $true
			TargetVersions = @(
				'5.1'
			)
		}
		PSUSeCompatibleTypes               = @{
			Enable         = $true
			TargetProfiles = @(
				'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'
			)
		}
		PSProvideCommentHelp               = @{
			Enable                  = $true
			ExportedOnly            = $false
			BlockComment            = $true
			VSCodeSnippetCorrection	= $true
			Placement               = 'begin'
		}
		PSUseConsistentWhitespace          = @{
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
		PSUseConsistentIndentation         = @{
			Enable              = $true
			PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
			Kind                = 'tab'
		}
		PSUseCorrectCasing                 = @{
			Enable = $true
		}
		PSPlaceOpenBrace                   = @{
			Enable             = $true
			OnSameLine         = $true
			NewLineAfter       = $true
			IgnoreOneLineBlock = $false
		}
		PSPlaceCloseBrace                  = @{
			Enable             = $true
			NewLineAfter       = $true
			IgnoreOneLineBlock = $true
			NoEmptyLineBefore  = $true
		}
		PSAvoidSemicolonsAsLineTerminators = @{
			Enable = $true
		}
		PSAvoidExclaimOperator             = @{
			Enable = $true
		}
		PSAvoidUsingPositionalParameters   = @{
			Enable           = $true
			CommandAllowList = @()
		}
	}
	CustomRulePath      = @(
		'.\.tests\PSScriptAnalyzer\neo42PSScriptAnalyzerRules'
	)
}
