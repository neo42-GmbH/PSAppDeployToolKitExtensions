# PSAppDeployToolkit default rules for PSScriptAnalyser, to ensure compatibility with PowerSHell 3.0
@{
	Severity     = @(
		'Error',
		'Warning'
	)
	ExcludeRules = @(
		'PSUseDeclaredVarsMoreThanAssignments',
		'PSAvoidUsingWriteHost',
		'PSAvoidGlobalVars'
	)
	Rules        = @{
		PSUseCompatibleCmdlets                = @{
			TargetProfiles = @(
				'desktop-5.1.14393.206-windows'
			)
			IgnoreCommands = @(
				'Write-Log'
			)
		}
		PSProvideCommentHelp                  = @{
			ExportedOnly            = $false
			BlockComment            = $true
			VSCodeSnippetCorrection = $true
			Placement               = 'begin'
		}
	}
	<#
		CustomRulePath = @(
		'.\neo42PSScriptAnalyzerRules'
	);
	#>
}
