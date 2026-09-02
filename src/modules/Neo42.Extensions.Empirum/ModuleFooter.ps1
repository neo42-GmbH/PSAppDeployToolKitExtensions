#region Initialization
# Make sure the module is loaded via the psd1 file.
if ([System.Environment]::StackTrace -notlike '*Microsoft.PowerShell.Commands.ModuleCmdletBase.LoadModuleManifest(*') {
	throw [System.InvalidOperationException]::new('This module must be imported via its .psd1 file, which is recommended for all modules that supply a .psd1 file.')
}

# Create a secure command table for the module derived from the PSADT command table.
$ExecutionContext.SessionState.PSVariable.Set(
	[System.Management.Automation.PSVariable]::new(
		'CommandTable',
		(
			& {
				# Get the original get-module cmdlet to ensure there was no external override.
				if (-not ([System.Management.Automation.CmdletInfo]$getModule = $ExecutionContext.InvokeCommand.GetCmdlet('Get-Module')) -or -not $getModule.PSSnapIn.IsDefault) {
					throw [System.Security.SecurityException]::new('The core cmdlet [Get-Module] was overridden or is not available.')
				}
				# Create a new writeable command table copy from the PSADT command table.
				[System.Collections.Generic.Dictionary[System.String, System.Management.Automation.CommandInfo]]$commandTable = [System.Collections.Generic.Dictionary[System.String, System.Management.Automation.CommandInfo]]::new(
					(& (& $getModule -FullyQualifiedName @{ ModuleName = 'PSAppDeployToolkit.Neo42.Extensions'; GUID = '042bb3b2-d0a5-40b1-8fde-f15727c951b9'; ModuleVersion = '0.0' }).ExportedFunctions.'Get-NXTCommandTable')
				)
				# Add new functions to the command table from the current script.
				$args[0].MyCommand.ScriptBlock.Ast.EndBlock.Statements | & {
					process { if ($_ -is [System.Management.Automation.Language.FunctionDefinitionAst]) { $commandTable[$_.Name] = $ExecutionContext.InvokeCommand.GetCommand($_.Name, [System.Management.Automation.CommandTypes]::Function) } }
				}
				# Output the command table as a read-only dictionary.
				return [System.Collections.ObjectModel.ReadOnlyDictionary[System.String, System.Management.Automation.CommandInfo]]::new($commandTable)
			} $MyInvocation
		),
		[System.Management.Automation.ScopedItemOptions]::Constant
	)
)

@{
	'ErrorActionPreference'         = [System.Management.Automation.ActionPreference]::Stop
	'PSModuleAutoloadingPreference' = [System.Management.Automation.PSModuleAutoLoadingPreference]::None
	'InformationPreference'         = [System.Management.Automation.ActionPreference]::Continue
	'WarningPreference'             = [System.Management.Automation.ActionPreference]::Continue
	'DebugPreference'               = [System.Management.Automation.ActionPreference]::SilentlyContinue
	'ProgressPreference'            = [System.Management.Automation.ActionPreference]::SilentlyContinue
	'ConfirmPreference'             = [System.Management.Automation.ConfirmImpact]::None
}.GetEnumerator() | & { process { New-Variable -Name $_.Name -Force -Scope Script -Option Constant -Value $_.Value } }

# Ensure coding standards are enforced.
Set-StrictMode -Version 3.0

# Integrate into the PSADT initialization process.
Add-ADTModuleCallback -HookPoint 'OnStart' -Callback $script:CommandTable.'Initialize-NXTModule'
Add-ADTModuleCallback -HookPoint 'PostOpen' -Callback $script:CommandTable.'Invoke-NXTEmpirumPreAction'
Add-ADTModuleCallback -HookPoint 'PostClose' -Callback $script:CommandTable.'Invoke-NXTEmpirumPostAction'

Add-NXTDeploymentCallback -HookPoint 'CustomInstallAndReinstallAndSoftMigrationBegin' -Callback $script:CommandTable.'Remove-NXTOldEmpirumApplication'
#endregion Initialization
