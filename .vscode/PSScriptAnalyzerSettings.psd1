# PSAppDeployToolkitExtension default rules for PSScriptAnalyser, to ensure compatibility with PowerSHell 5.1 and ensure coding standards are met.
@{
	IncludeDefaultRules = $true
	Severity            = @(
		'Error',
		'Warning'
	)
	ExcludeRules        = @(
		'PSUseDeclaredVarsMoreThanAssignments', # PSADT uses global variables
		'PSAvoidGlobalVars', # PSADT uses global variables
		'PSUseShouldProcessForStateChangingFunctions', # We don't use ShouldProcess in our scripts
		'PSUseOutputTypeCorrectly', # Does not work good with array types
		'PSAvoidUsingWriteHost' # Ignored because we use Write-Host in tools
	)
	Rules               = @{
		PSUseCompatibleCmdlets    = @{
			TargetProfiles = @(
				'desktop-5.1.14393.206-windows'
			)
			IgnoreCommands = @(
				'Write-Log'
			)
		}
		PSProvideCommentHelp      = @{
			ExportedOnly            = $false
			BlockComment            = $true
			VSCodeSnippetCorrection	= $true
			Placement               = 'begin'
		}
		PSUseConsistentWhitespace = @{
			CheckInnerBrace                         = $true
			CheckOpenBrace                          = $true
			CheckOpenParen                          = $true
			CheckOperator                           = $true
			CheckPipe                               = $true
			CheckPipeForRedundantWhitespace         = $true
			CheckSeparator                          = $true
			CheckParameter                          = $true
			IgnoreAssignmentOperatorInsideHashTable	= $true
		}
	}
	CustomRulePath      = @(
		'.vscode\neo42PSScriptAnalyzerRules'
	)
}
