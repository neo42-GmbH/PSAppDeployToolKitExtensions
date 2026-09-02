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
					(& (& $getModule -FullyQualifiedName @{ ModuleName = 'PSAppDeployToolkit'; GUID = '8c3c366b-8606-4576-9f2d-4051144f7ca2'; ModuleVersion = '1.0' }).ExportedFunctions.'Get-ADTCommandTable')
				)
				# Add additional modules to the command table.
				& $commandTable.'Import-Module' -Global -Force -PassThru -ErrorAction 'Stop' -FullyQualifiedName @(
					@{ ModuleName = 'Appx'; Guid = 'aeef2bef-eba9-4a1d-a3d2-d0b52df76deb'; ModuleVersion = '1.0' }
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

# Set the module's preferences.
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

# Validate the files have not been tampered with, if the module file is signed.
Get-AuthenticodeSignature -LiteralPath $MyInvocation.MyCommand.Path | & {
	process {
		if ($_.Status -eq [System.Management.Automation.SignatureStatus]::NotSigned) {
			return
		}
		elseif ($_.Status -ne [System.Management.Automation.SignatureStatus]::Valid) {
			throw [System.Security.SecurityException]::new("The module [$($MyInvocation.MyCommand.Path)] is signed with an untrusted or invalid signature. Module integrity cannot be guaranteed.")
		}
		else {
			[System.String]$thumbprint = $_.SignerCertificate.Thumbprint
			Get-ChildItem -Recurse -File -Path $PSScriptRoot -Include '*.dll', '*.ps1', '*.psd1' | & {
				process {
					[System.Management.Automation.Signature]$signature = Get-AuthenticodeSignature -LiteralPath $_.FullName
					if (-not $signature.SignerCertificate -or $thumbprint -ne $signature.SignerCertificate.Thumbprint -or $signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid) {
						throw [System.Security.SecurityException]::new("The file [$($_.FullName)] has been tampered with or is not signed with the same certificate as the module. Module integrity cannot be guaranteed.")
					}
				}
			}
		}
	}
}

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

# Mount PSDrives for path resolution.
$ExecutionContext.SessionState.Provider.GetOne('Microsoft.PowerShell.Core\Registry') | & {
	process {
		if ($_.Drives.Name -notcontains 'HKCR') { $null = $ExecutionContext.SessionState.Drive.New([System.Management.Automation.PSDriveInfo]::new('HKCR', $_, 'HKEY_CLASSES_ROOT', $null, $null), 'script') }
		if ($_.Drives.Name -notcontains 'HKU') { $null = $ExecutionContext.SessionState.Drive.New([System.Management.Automation.PSDriveInfo]::new('HKU', $_, 'HKEY_USERS', $null, $null), 'script') }
		if ($_.Drives.Name -notcontains 'HKCC') { $null = $ExecutionContext.SessionState.Drive.New([System.Management.Automation.PSDriveInfo]::new('HKCC', $_, 'HKEY_CURRENT_CONFIG', $null, $null), 'script') }
	}
}

# Define the deployment callback store.
New-Variable -Name 'DeploymentCallbacks' -Option Constant -Force -Scope Script -Value (
	[System.Collections.ObjectModel.ReadOnlyDictionary[PSADTNXT.Deployment.DeploymentHookPoint, System.Collections.Generic.List[System.Management.Automation.CommandInfo]]]::new(
		$(
			$dict = [System.Collections.Generic.Dictionary[PSADTNXT.Deployment.DeploymentHookPoint, System.Collections.Generic.List[System.Management.Automation.CommandInfo]]]::new()
			[System.Enum]::GetValues([PSADTNXT.Deployment.DeploymentHookPoint]) | . { process { $dict.Add($_, [System.Collections.Generic.List[System.Management.Automation.CommandInfo]]::new()) } }
			$dict
		)
	)
)

# Add our initialization hooks to the PSADT command table.
Add-ADTModuleCallback -HookPoint PostOpen -Callback $script:CommandTable.'Open-NXTSession'
Add-ADTModuleCallback -HookPoint PreClose -Callback $script:CommandTable.'Close-NXTSession'
#endregion Initialization
