# PSAppDeployToolkitExtension default rules for PSScriptAnalyser, to ensure compatibility with PowerSHell 5.1 and ensure coding standards are met.
@{
	IncludeDefaultRules = $true
	Severity       = @(
		'Error',
		'Warning'
	)
	ExcludeRules   = @(
		'PSUseDeclaredVarsMoreThanAssignments',
		'PSAvoidUsingWriteHost',
		'PSAvoidGlobalVars',
		'PSUseShouldProcessForStateChangingFunctions'
	)
	Rules          = @{
		PSUseCompatibleCmdlets = @{
			TargetProfiles = @(
				'desktop-5.1.14393.206-windows'
			)
			IgnoreCommands = @(
				'Write-Log'
			)
		}
		PSProvideCommentHelp   = @{
			ExportedOnly            = $false
			BlockComment            = $true
			VSCodeSnippetCorrection = $true
			Placement               = 'begin'
		}
	}
	CustomRulePath = @(
		'.vscode\neo42PSScriptAnalyzerRules'
	);
}
