<#
.SYNOPSIS
This script performs the installation, repair or uninstallation of an application(s).
.DESCRIPTION
This script serves as a template for handling the lifecycle of applications using the PSAppDeploymentToolkit (PSADT) with the Neo42.Extensions module.
It supports deployment types "Install", "Repair", "Uninstall", as well as user-specific tasks "InstallUserPart" and "UninstallUserPart".

The script leverages the extended functionality provided by the Neo42.Extensions module to simplify the deployment process.
The main deployment logic is handled by the toolkit itself through the external configuration file "neo42PackageConfig.json", which must be placed in the same directory as this script.
Any code based customizations must be implemented within the "Custom" hook functions, which are called at specific points during the deployment.
.NOTES
# LICENSE #
This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

# COPYRIGHT #
Copyright (c) 2026 neo42 GmbH, Germany.

# SCRIPT VERSION #
Version: 0.0.0.0
#>
#region PARAMETERS - DO NOT EDIT
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Variables are read by New-NXTSessionParameter')]
[CmdletBinding(HelpUri = 'https://neo42.de/psappdeploytoolkit')]
param (
	# PSADT parameters #
	[Parameter(Position = 0, HelpMessage = 'The type of deployment to perform.')]
	[ValidateSet('Install', 'Uninstall', 'Repair', 'InstallUserPart', 'UninstallUserPart', 'TriggerInstallUserPart', 'TriggerUninstallUserPart')]
	[System.String]
	$DeploymentType = 'Install',
	[Parameter(Position = 1, HelpMessage = 'Specify if the installation will be run in Interactive, Silent or NonInteractive mode. Refer to the PSADT documentation for more information.')]
	[ValidateSet('Auto', 'Interactive', 'Silent', 'NonInteractive')]
	[System.String]
	$DeployMode = 'Auto',
	[Parameter(HelpMessage = 'If set, will deny the session to pass through codes indicating a reboot is required. Codes like 3010 will be converted to 0.')]
	[System.Management.Automation.SwitchParameter]
	$SuppressRebootPassThru,
	[Parameter(HelpMessage = 'Changes to user install mode and back to user execute mode for installing/uninstalling applications on Remote Desktop Session Host/Citrix servers')]
	[System.Management.Automation.SwitchParameter]
	$TerminalServerMode,
	[Parameter(HelpMessage = 'If set, will disable logging to file. ALl logs will still be written to console.')]
	[System.Management.Automation.SwitchParameter]
	$DisableLogging,
	# Neo42.Extensions parameters #
	[Parameter(HelpMessage = 'Parameter representing the deployment system. May be used by downstream extensions or hooks. If not set, the Extension will try to determine the deployment system automatically.')]
	[System.String]
	$DeploymentSystem,
	[Parameter(HelpMessage = 'If set, the script will stop before the deployment and will not close the active session. Useful for debugging purposes.')]
	[System.Management.Automation.SwitchParameter]
	$SkipDeployment
)
#endregion PARAMETERS - DO NOT EDIT

#region Hook Functions
<#
Custom functions represent hook points in the deployment process of Invoke-NXTDeployment, where customization PowerShell code can be placed.
Below functions are templates for said hooks, sorted by order of execution and constructed as follows, where every subsequent part is optional:
Custom{Phase}{PrePosition}{SubPhase}

Altering the flow of the deployment process is possible by changing values in the ADT session object, which is accessible through the $adtSession variable.
For example, setting the exit code with $adtSession.SetExitCode(5) will mark the deployment as failed and return the exit code 5.
#>
function CustomBegin {
	<#
	.DESCRIPTION
	This function is called at the beginning of every deployment regardless of DeploymentType.
	Ideal for providing script-wide data, such as variables or functions.
	Be aware that this function is also called in user-context and therefore should not assume any elevated rights.
	#>
	#region CustomBegin content
	#endregion CustomBegin content
}

function CustomInstallAndReinstallAndSoftMigrationBegin {
	<#
	.DESCRIPTION
	This function is called before right before the install deployment logic is started.
	At this point the soft migration logic has not yet been processed.
	This function can be used to implement a custom soft migration detection by setting the $adtSession.NXT.SoftMigration.Result value to the desired state.
	#>
	#region CustomInstallAndReinstallAndSoftMigrationBegin content
	#endregion CustomInstallAndReinstallAndSoftMigrationBegin content
}

function CustomSoftMigrationBegin {
	<#
	.DESCRIPTION
	If the install deployment detects that a soft migration would be possible, this function is called.
	Allows for custom actions to be performed before the soft migration process is started or to skip the soft migration.
	The soft migration can still be skipped by setting $adtSession.NXT.SoftMigration.Result to $false.
	#>
	#region CustomSoftMigrationBegin content
	#endregion CustomSoftMigrationBegin content
}

function CustomInstallAndReinstallAndSoftMigrationEnd {
	<#
	.DESCRIPTION
	This function is called on any successful install based deployment regardless of the logic that was executed.
	Information about executed installers might be available in the $adtSession.NXT.ProcessResults object.
	#>
	#region CustomInstallAndReinstallAndSoftMigrationEnd content
	#endregion CustomInstallAndReinstallAndSoftMigrationEnd content
}

function CustomInstallAndReinstallPreInstallAndReinstall {
	<#
	.DESCRIPTION
	This function is called in an install deployment before the reinstall logic is processed, regardless of ReinstallMode setting.
	It can be used to implement custom actions for a reinstall process.
	#>
	#region CustomInstallAndReinstallPreInstallAndReinstall content
	#endregion CustomInstallAndReinstallPreInstallAndReinstall content
}

function CustomReinstallPreUninstall {
	<#
	.DESCRIPTION
	This function is called when the reinstall logic will start an uninstallation process.
	#>
	#region CustomReinstallPreUninstall content
	#endregion CustomReinstallPreUninstall content
}

function CustomReinstallPostUninstallOnError {
	<#
	.DESCRIPTION
	A function called before ending the deployment process in case there was an error during the uninstallation in the reinstall logic.
	The information about the error is available in the $adtSession.NXT.ProcessResults object.
	#>
	#region CustomReinstallPostUninstallOnError content
	#endregion CustomReinstallPostUninstallOnError content
}

function CustomReinstallPostUninstall {
	<#
	.DESCRIPTION
	This function is called after the successful uninstallation in the reinstall logic.
	The $adtSession.NXT.ProcessResults might contain information about the uninstallation process depending on the uninstall logic used.
	#>
	#region CustomReinstallPostUninstall content
	#endregion CustomReinstallPostUninstall content
}

function CustomReinstallPreInstall {
	<#
	.DESCRIPTION
	This function is called before the reinstallation logic.
	#>
	#region CustomReinstallPreInstall content
	#endregion CustomReinstallPreInstall content
}

function CustomReinstallPostInstallOnError {
	<#
	.DESCRIPTION
	A function called before ending the deployment process in case there was an error during the installation in the reinstall logic.
	The information about the error is available in the $adtSession.NXT.ProcessResults object.
	#>
	#region CustomReinstallPostInstallOnError content
	#endregion CustomReinstallPostInstallOnError content
}

function CustomReinstallPostInstall {
	<#
	.DESCRIPTION
	This function is called after the successful installation in the reinstall logic.
	The $adtSession.NXT.ProcessResults might contain information about the installation process depending on the install logic used.
	#>
	#region CustomReinstallPostInstall content
	#endregion CustomReinstallPostInstall content
}

function CustomUpgradePostUninstallOnError {
	<#
	.DESCRIPTION
	This function is called after the successful installation in the reinstall logic.
	The $adtSession.NXT.ProcessResults might contain information about the installation process depending on the install logic used.
	#>
	#region CustomUpgradePostUninstallOnError content
	#endregion CustomUpgradePostUninstallOnError content
}

function CustomUpgradePostInstallOnError {
	<#
	.DESCRIPTION
	This function is called after the successful installation in the reinstall logic.
	The $adtSession.NXT.ProcessResults might contain information about the installation process depending on the install logic used.
	#>
	#region CustomUpgradePostInstallOnError content
	#endregion CustomUpgradePostInstallOnError content
}

function CustomInstallBegin {
	<#
	.DESCRIPTION
	Is called before the installation logic is processed.
	#>
	#region CustomInstallBegin content
	#endregion CustomInstallBegin content
}

function CustomInstallEndOnError {
	<#
	.DESCRIPTION
	If an error occurs during the installation process, this function is called before the deployment process ends.
	The information about the error is available in the $adtSession.NXT.ProcessResults object.
	#>
	#region CustomInstallEndOnError content
	#endregion CustomInstallEndOnError content
}

function CustomInstallEnd {
	<#
	.DESCRIPTION
	Executes after the successful installation process.
	The $adtSession.NXT.ProcessResults might contain information about the installation process depending on the install logic used.
	#>
	#region CustomInstallEnd content
	#endregion CustomInstallEnd content
}

function CustomInstallAndReinstallEnd {
	<#
	.DESCRIPTION
	Executes after the successful installation or reinstallation process.
	The $adtSession.NXT.ProcessResults might contain information about the installation process depending on the install logic used.
	#>
	#region CustomInstallAndReinstallEnd content
	#endregion CustomInstallAndReinstallEnd content
}

function CustomUninstallBegin {
	<#
	.DESCRIPTION
	Is called before the uninstallation in the uninstall process.
	#>
	#region CustomUninstallBegin content
	#endregion CustomUninstallBegin content
}

function CustomUninstallEndOnError {
	<#
	.DESCRIPTION
	If an error occurs during the uninstallation process, this function is called before the deployment process ends.
	The information about the error is available in the $adtSession.NXT.ProcessResults object.
	#>
	#region CustomUninstallEndOnError content
	#endregion CustomUninstallEndOnError content
}

function CustomUninstallEnd {
	<#
	.DESCRIPTION
	Executes after the successful uninstallation in the uninstall process.
	The $adtSession.NXT.ProcessResults might contain information about the uninstallation process depending on the uninstall logic used.
	#>
	#region CustomUninstallEnd content
	#endregion CustomUninstallEnd content
}

function CustomInstallUserPartBegin {
	<#
	.DESCRIPTION
	Is called as first stage in the user installation process.
	#>
	#region CustomInstallUserPartBegin content
	#endregion CustomInstallUserPartBegin content
}

function CustomInstallUserPartEnd {
	<#
	.DESCRIPTION
	Is called as last stage in the user installation process.
	#>
	#region CustomInstallUserPartEnd content
	#endregion CustomInstallUserPartEnd content
}

function CustomUninstallUserPartBegin {
	<#
	.DESCRIPTION
	Is called as first stage in the user uninstallation process.
	#>
	#region CustomUninstallUserPartBegin content
	#endregion CustomUninstallUserPartBegin content
}

function CustomUninstallUserPartEnd {
	<#
	.DESCRIPTION
	Is called as last stage in the user uninstallation process.
	#>
	#region CustomUninstallUserPartEnd content
	#endregion CustomUninstallUserPartEnd content
}

function CustomEnd {
	<#
	.DESCRIPTION
	If no error occurred during the deployment process, this function is called after all tasks of deployment process are executed.
	The $adtSession.NXT.ProcessResults might contain information about the deployment process depending on the logic used.
	#>
	#region CustomEnd content
	#endregion CustomEnd content
}

function CustomEndOnError {
	<#
	.DESCRIPTION
	If an error occurs at any point during the deployment process, this function is called after the deployment process ends.
	The information about the error may available in the $adtSession.NXT.ProcessResults object.
	#>
	#region CustomEndOnError content
	#endregion CustomEndOnError content
}
#endregion Hook Functions

#region INTERNALS - DO NOT EDIT
try {
	# Remove all prior instances of PSAppDeployToolkit modules
	Remove-Module -Name 'PSAppDeployToolkit*' -Force
	# Import the PSADT and extension modules from the script directory and unblock all files to prevent issues with downloaded modules.
	Get-ChildItem -Directory -LiteralPath $PSScriptRoot -Filter 'PSAppDeployToolkit*' | ForEach-Object {
		Get-ChildItem -LiteralPath $PSItem.FullName -File -Recurse | Unblock-File
		Import-Module -Name $PSItem.FullName -Force -ErrorAction Stop
	}
	# Restarting is required to not have blocking processes on ActiveSetup.
	Restart-NXTDeployScript -Invocation $MyInvocation -WhenTriggerDeployment -When32on64Bit
	# Initialize and open the ADT session.
	Initialize-ADTModule -AdditionalEnvironmentVariables (New-NXTEnvironmentTable) -ScriptDirectory (
		@("$PSScriptRoot\PSAppDeployToolkit.Neo42.Extensions", $PSScriptRoot) +
		@(Get-ChildItem -LiteralPath $PSScriptRoot -Directory -Filter 'Overrides.*' | Select-Object -ExpandProperty 'FullName')
	)
	Add-NXTDeploymentCallback -Callback (Get-Item -Path 'Function:\Custom*')
	# Open the ADT session with the parameters collected from the script and the customizations.
	$adtSession = New-NXTSessionParameter -Invocation $MyInvocation
	$adtSession = Open-ADTSession @adtSession -PassThru -ForceWimDetection -NoProcessDetection -ExitWithMsiCodes
}
catch {
	$Host.UI.WriteErrorLine((Out-String -InputObject $_ -Width ([System.Int32]::MaxValue)))
	exit 60008
}

if (-not $SkipDeployment) {
	try {
		Invoke-NXTDeployment -ADTSession $adtSession
	}
	catch {
		$Host.UI.WriteErrorLine((Out-String -InputObject $_ -Width ([System.Int32]::MaxValue)))
		if (Test-ADTSessionActive) { Close-ADTSession -ExitCode 60001 }
	}
	finally {
		if (Test-ADTSessionActive) { Close-ADTSession } else { exit 60001 }
	}
}
#endregion INTERNALS - DO NOT EDIT
