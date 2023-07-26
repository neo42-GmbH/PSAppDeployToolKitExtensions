<#
.SYNOPSIS
	This script performs the installation, repair or uninstallation of an application(s).
	# LICENSE #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is provided as a template to perform an install, repair or uninstall of an application(s).
	The script either performs an "Install", a "Repair" or an "Uninstall" deployment type.
	The script also supports tasks that are performed in the user context by using the "InstallUserPart" and "UninstallUserPart" deployment types.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
	The script makes heavy use of "*-Nxt*"" functions from the AppDeployToolkitExtensions.ps1 that are created by "neo42 GmbH" to extend the functionality of the PSADT.
	The "Main" function defines the basic procedure to handle various installer types automatically. It relies on the neo42PackageConfig.json file to determine the installer type and the parameters to be passed to the installer.
	The "Main" function should not be modified. Instead, the prepared functions starting with "Custom" should be used to customize the deployment process since they are called by the "Main" function in a specific order.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.PARAMETER DeploymentSystem
	Can be used to specify the deployment system that is used to deploy the application. Default is: [string]::Empty.
	Required by some "*-Nxt*" functions to handle deployment system specific tasks.
.PARAMETER NeoForceLanguage
	Can be used to explicitly specify the language will be used to install the application. Default is: [string]::Empty.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Version: ##REPLACEVERSION##
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory = $false)]
	[ValidateSet('Install', 'Uninstall', 'Repair', 'InstallUserPart', 'UninstallUserPart', 'TriggerInstallUserPart', 'TriggerUninstallUserPart')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory = $false)]
	[ValidateSet('Interactive', 'Silent', 'NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory = $false)]
	[switch]$AllowRebootPassThru,
	[Parameter(Mandatory = $false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory = $false)]
	[switch]$DisableLogging = $false,
	[Parameter(Mandatory = $false)]
	[string]$DeploymentSystem = [string]::Empty,
	[Parameter(Mandatory = $false)]
	[string]$NeoForceLanguage = [string]::Empty
)
## During UserPart execution, invoke self asynchronously to prevent logon freeze caused by active setup.
switch ($DeploymentType) {
	TriggerInstallUserPart { 
		Start-Process -FilePath "$env:windir\system32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -WindowStyle hidden -NoProfile -File `"$($script:MyInvocation.MyCommand.Path)`" -DeploymentType InstallUserpart"
		Exit
	}
	TriggerUninstallUserPart { 
		Start-Process -FilePath "$env:windir\system32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -WindowStyle hidden -NoProfile -File `"$($script:MyInvocation.MyCommand.Path)`" -DeploymentType UninstallUserpart"
		Exit
	}
	Default {}
}
## global default variables 
[string]$global:Neo42PackageConfigPath = "$PSScriptRoot\neo42PackageConfig.json"
[string]$global:Neo42PackageConfigValidationPath = "$PSScriptRoot\neo42PackageConfigValidationRules.json"
[string]$global:SetupCfgPath = "$PSScriptRoot\Setup.cfg"
[string]$global:CustomSetupCfgPath = "$PSScriptRoot\CustomSetup.cfg"
[string]$global:DeploymentSystem = $DeploymentSystem
[string]$global:NeoForceLanguage = $NeoForceLanguage
[int]$global:NxtScriptDepth = $env:nxtScriptDepth
## Several PSADT-functions do not work, if these variables are not set here.
$tempLoadPackageConfig = (Get-Content "$global:Neo42PackageConfigPath" -raw ) | ConvertFrom-Json
[string]$appVendor = $tempLoadPackageConfig.AppVendor
[string]$appName = $tempLoadPackageConfig.AppName
[string]$appVersion = $tempLoadPackageConfig.AppVersion
Remove-Variable -Name tempLoadPackageConfig
##* Do not modify section below =============================================================================================================================================
#region DoNotModify
## set the script execution policy for this process
Try { Set-ExecutionPolicy -ExecutionPolicy 'Bypass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
## Variables: Exit Code
[int32]$mainExitCode = 0
## Variables: Script
[string]$deployAppScriptFriendlyName = 'Deploy Application'
[string]$deployAppScriptVersion = [string]'##REPLACEVERSION##'
[string]$deployAppScriptDate = '02/05/2023'
[hashtable]$deployAppScriptParameters = $psBoundParameters
## Variables: Environment
If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
[int]$env:nxtScriptDepth += 1
## dot source the required AppDeploy Toolkit functions
Try {
	[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
	Write-Output $moduleAppDeployToolkitMain
	Test-Path $moduleAppDeployToolkitMain
	If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { 
		Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]."
	}
	If ($DisableLogging) {
		. $moduleAppDeployToolkitMain -DisableLogging
	} 
	Else {
		. $moduleAppDeployToolkitMain
	}
	## add custom 'Nxt' variables
	#[string]$appDeployLogoBannerDark = Join-Path -Path $scriptRoot -ChildPath $xmlBannerIconOptions.Banner_Filename_Dark
}
Catch {
	If ($mainExitCode -eq 0) { [int32]$mainExitCode = 60008 }
	Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
	## exit the script, returning the exit code
	Write-Output "Testing path $moduleAppDeployToolkitMain"
	Test-Path $moduleAppDeployToolkitMain
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
}
Write-Log "Current running script depth: $($global:NxtScriptDepth)" -Source $deployAppScriptFriendlyName
#endregion
##* Do not modify section above	=============================================================================================================================================

try {
	[string]$script:installPhase = 'Initialize-Environment'
	Initialize-NxtEnvironment
	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================

	## app global variables
	[string]$global:DetectedDisplayVersion = (Get-NxtCurrentDisplayVersion).DisplayVersion

	Get-NxtVariablesFromDeploymentSystem
	
	[bool]$global:SoftMigrationCustomResult = $false
	[bool]$global:AppInstallDetectionCustomResult = $false
	
	## validate package config variables
	Test-NxtPackageConfig

	## write variables to verbose channel to prevent warnings issued by PSScriptAnalyzer
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] Neo42PackageConfigValidationPath: $global:Neo42PackageConfigValidationPath"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] Neo42PackageConfigPath: $global:Neo42PackageConfigPath"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] SetupCfgPath: $global:SetupCfgPath"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] CustomSetupCfgPath: $global:CustomSetupCfgPath"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] deployAppScriptVersion: $deployAppScriptVersion"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] deployAppScriptDate: $deployAppScriptDate"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] deployAppScriptParameters: $deployAppScriptParameters"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] appDeployLogoBannerDark: $appDeployLogoBannerDark"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] DetectedDisplayVersion: $global:DetectedDisplayVersion"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] SoftMigrationCustomResult (prefillvalue): $global:SoftMigrationCustomResult"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] appVendor: $appVendor"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] appName: $appName"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] appVersion: $appVersion"

	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================
}
catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}