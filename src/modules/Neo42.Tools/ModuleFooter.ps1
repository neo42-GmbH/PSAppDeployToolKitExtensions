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
				if (-not ([System.Management.Automation.CmdletInfo]$importModule = $ExecutionContext.InvokeCommand.GetCmdlet('Import-Module')) -or -not $importModule.PSSnapIn.IsDefault) {
					throw [System.Security.SecurityException]::new('The core cmdlet [Import-Module] was overridden or is not available.')
				}
				# Create a new writeable command table copy from the PSADT command table.
				[System.Collections.Generic.Dictionary[System.String, System.Management.Automation.CommandInfo]]$commandTable = [System.Collections.Generic.Dictionary[System.String, System.Management.Automation.CommandInfo]]::new()
				$ExecutionContext.SessionState.InvokeCommand.GetCmdlets() | & { process { if ($_.PSSnapIn -and $_.PSSnapIn.Name.Equals('Microsoft.PowerShell.Core') -and $_.PSSnapIn.IsDefault) { $commandTable.Add($_.Name, $_) } } }
				# Add additional modules to the command table.
				& $importModule -Global -Force -PassThru -ErrorAction 'Stop' -FullyQualifiedName @(
					@{ ModuleName = 'Microsoft.PowerShell.Management'; Guid = 'eefcb906-b326-4e99-9f54-8b4bb6ef3c6d'; ModuleVersion = '1.0' },
					@{ ModuleName = 'Microsoft.PowerShell.Utility'; Guid = '1da87e53-152b-403e-98dc-74d7b4d63d59'; ModuleVersion = '1.0' },
					@{ ModuleName = 'Microsoft.PowerShell.Archive'; Guid = 'eb74e8da-9ae2-482a-a648-e96550fb8733'; ModuleVersion = '1.0' },
					@{ ModuleName = 'PSScriptAnalyzer'; GUID = 'd6245802-193d-4068-a631-8863a4342a18'; ModuleVersion = '1.0' }
				) | & { process { $_.ExportedCommands.Values | & { process { $commandTable.Add($_.Name, $_) } } } }
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

# Import assemblies required for the module. Due to network location support, the assemblies are loaded within the module itself.
[System.IO.Directory]::EnumerateFiles("$PSScriptRoot\lib\$(if ($PSVersionTable.PSEdition.Equals('Desktop')) { 'net472' } else { 'net8.0' })", '*.dll') | & {
	begin {
		[System.Boolean]$isNetworkLocation = [System.Uri]::new($PSScriptRoot).IsUnc -or (($PSScriptRoot -match '^[A-Z]:\\') -and [System.IO.DriveInfo]::new($Matches.0).DriveType.Equals([System.IO.DriveType]::Network))
	}
	process {
		if ($isNetworkLocation) {
			[System.Reflection.Assembly]::UnsafeLoadFrom($_)
		}
		else {
			[System.Reflection.Assembly]::LoadFrom($_)
		}
	}
}

#endregion Initialization
