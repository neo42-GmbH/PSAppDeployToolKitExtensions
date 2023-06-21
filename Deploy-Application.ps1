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
## Global default variables 
[string]$global:Neo42PackageConfigPath = "$PSScriptRoot\neo42PackageConfig.json"
[string]$global:Neo42PackageConfigValidationPath = "$PSScriptRoot\neo42PackageConfigValidationRules.json"
[string]$global:SetupCfgPath = "$PSScriptRoot\Setup.cfg"
[string]$global:CustomSetupCfgPath = "$PSScriptRoot\CustomSetup.cfg"
[string]$global:DeploymentSystem = $DeploymentSystem
[string]$global:NeoForceLanguage = $NeoForceLanguage
## Several PSADT-functions do not work, if these variables are not set here.
Get-Content "$global:Neo42PackageConfigPath" | Out-String | ConvertFrom-Json | ForEach-Object {
	[string]$appVendor = $_.AppVendor
	[string]$appName = $_.AppName
	[string]$appVersion = $_.AppVersion
}
##* Do not modify section below =============================================================================================================================================
#region DoNotModify
## Set the script execution policy for this process
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
## Dot source the required App Deploy Toolkit Functions
Try {
	[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
	If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
	If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	## Add Custom Nxt Variables
	[string]$appDeployLogoBannerDark = Join-Path -Path $scriptRoot -ChildPath $xmlBannerIconOptions.Banner_Filename_Dark
}
Catch {
	If ($mainExitCode -eq 0) { [int32]$mainExitCode = 60008 }
	Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
	## Exit the script, returning the exit code to SCCM
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
}
#endregion
##* Do not modify section above	=============================================================================================================================================

try {
	[string]$script:installPhase = 'Initialize-Environment'
	Initialize-NxtEnvironment
	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================

	## App Global Variables
	[string]$global:DetectedDisplayVersion = Get-NxtCurrentDisplayVersion

	Get-NxtVariablesFromDeploymentSystem
	
	[bool]$global:SoftMigrationCustomResult = $false
	[bool]$global:AppInstallDetectionCustomResult = $false
	
	## Validate Package Config Variables
	Test-NxtPackageConfig

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

function Main {
	<#
	.SYNOPSIS
		Defines the flow of the installation script
	.DESCRIPTION
		Do not modify to ensure correct script flow!
		To customize the script always use the "CustomXXXX" entry points.
	.PARAMETER Reboot
		Defines if a reboot exitcode should be returned instead of the main Exitcode.
		0 = do not override mainexitcode
		1 = Set Mainexitcode to 3010 (Reboot required)
		2 = Set Exitcode to 0 instead of a reboot exit code exitcodes other than 1641 and 3010 will
		be passed through.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER ReinstallMode
		Defines how a reinstallation should be performed.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER InstallMethod
		Defines the type of the installer used in this package.
		Defaults to the corresponding value from the PackageConfig object
	.EXAMPLE
		Main
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	param (
		[Parameter(Mandatory = $false)]
		[string]
		$PackageGUID = $global:PackageConfig.PackageGUID,
		[Parameter(Mandatory = $false)]
		[int]
		[ValidateSet(0, 1, 2)]
		$Reboot = $global:PackageConfig.reboot,
		[Parameter(Mandatory = $false)]
		[string]
		$InstallMethod = $global:PackageConfig.InstallMethod,
		[Parameter(Mandatory = $false)]
		[string]
		$RegisterPackage = $global:registerPackage
	)
	try {
		CustomBegin
		switch ($DeploymentType) {
			{ ($_ -eq "Install") -or ($_ -eq "Repair") } {
				CustomInstallAndReinstallBegin
				## START OF INSTALL
				[string]$script:installPhase = 'Package-PreCleanup'
				[PSADTNXT.NxtApplicationResult]$mainNxtResult = Uninstall-NxtOld
				if ($false -eq $mainNxtResult.Success) {
					Exit-Script -ExitCode $mainNxtResult.MainExitCode
				}
				if ($true -eq $global:SetupCfg.Options.SoftMigration -and -not (Test-RegistryValue -Key HKLM\Software\neoPackages\$PackageFamilyGUID -Value 'ProductName') -and ($true -eq $RegisterPackage)) {
					CustomSoftMigrationBegin
				}
				[string]$script:installPhase = 'Check-Softmigration'
				if ($true -eq $(Get-NxtRegisterOnly)) {
					## soft migration = application is installed
					$mainNxtResult.Success = $true
				}
				else {
					## soft migration is not requested or not possible
					[string]$script:installPhase = 'Package-Preparation'
					[int]$showInstallationWelcomeResult = Show-NxtInstallationWelcome -IsInstall $true -AllowDeferCloseApps
					if ($showInstallationWelcomeResult -ne 0) {
						Exit-Script -ExitCode $showInstallationWelcomeResult
					}
					CustomInstallAndReinstallPreInstallAndReinstall
					[string]$script:installPhase = 'Decide-ReInstallMode'
					if ($true -eq $(Test-NxtAppIsInstalled -DeploymentMethod $InstallMethod) -or $true -eq $global:AppInstallDetectionCustomResult) {
						if ($true -eq $global:AppInstallDetectionCustomResult) {
							Write-Log -Message "Found an installed application: detected by custom pre-checks." -Source $deployAppScriptFriendlyName
						}
						[string]$reinstallMode = $(Switch-NxtMSIReinstallMode)
						Write-Log -Message "[$script:installPhase] selected Mode: $reinstallMode" -Source $deployAppScriptFriendlyName
						switch ($reinstallMode) {
							"Reinstall" {
								CustomReinstallPreUninstall
								[string]$script:installPhase = 'Package-Reinstallation'
								[PSADTNXT.NxtApplicationResult]$mainNxtResult = Uninstall-NxtApplication
								CustomReinstallPostUninstall -ResultToCheck $mainNxtResult
								if ($false -eq $mainNxtResult.Success) {
									Exit-NxtScriptWithError -ErrorMessage $mainNxtResult.ErrorMessage -ErrorMessagePSADT $mainNxtResult.ErrorMessagePSADT -MainExitCode $mainNxtResult.MainExitCode
								}
								CustomReinstallPreInstall
								[string]$script:installPhase = 'Package-Reinstallation'
								[PSADTNXT.NxtApplicationResult]$mainNxtResult = Install-NxtApplication
								CustomReinstallPostInstall -ResultToCheck $mainNxtResult
							}
							"MSIRepair" {
								if ("MSI" -eq $InstallMethod) {
									CustomReinstallPreInstall
									[string]$script:installPhase = 'Package-Reinstallation'
									[PSADTNXT.NxtApplicationResult]$mainNxtResult = Repair-NxtApplication
									CustomReinstallPostInstall -ResultToCheck $mainNxtResult
								}
								else {
									Throw "Unsupported combination of 'ReinstallMode' and 'InstallMethod' properties. Value 'MSIRepair' in 'ReinstallMode' is supported for installation method 'MSI' only!"
								}
							}
							"Install" {
								CustomReinstallPreInstall
								[string]$script:installPhase = 'Package-Reinstallation'
								[PSADTNXT.NxtApplicationResult]$mainNxtResult = Install-NxtApplication
								CustomReinstallPostInstall -ResultToCheck $mainNxtResult
							}
							Default {
								Throw "Unsupported 'ReinstallMode' property: $ReinstallMode"
							}
						}
					}
					else {
						## Default installation
						CustomInstallBegin
						[string]$script:installPhase = 'Package-Installation'
						[PSADTNXT.NxtApplicationResult]$mainNxtResult = Install-NxtApplication 
						CustomInstallEnd -ResultToCheck $mainNxtResult
					}
					CustomInstallAndReinstallEnd -ResultToCheck $mainNxtResult
				}
				## here we continue if application is present and/or register package is necesary only.
				CustomInstallAndReinstallAndSoftMigrationEnd -ResultToCheck $mainNxtResult
				If ($false -ne $mainNxtResult.Success) {
					[string]$script:installPhase = 'Package-Completition'
					Complete-NxtPackageInstallation
					if ($true -eq $RegisterPackage) {
						## Register package for uninstall
						[string]$script:installPhase = 'Package-Registration'
						Register-NxtPackage
					}
				}
				else {
					Exit-NxtScriptWithError -ErrorMessage $mainNxtResult.ErrorMessage -ErrorMessagePSADT $mainNxtResult.ErrorMessagePSADT -MainExitCode $mainNxtResult.MainExitCode
				}
				## END OF INSTALL
			}
			"Uninstall" {
				## START OF UNINSTALL
				[string]$script:installPhase = 'Package-Preparation'
				Show-NxtInstallationWelcome -IsInstall $false
				Initialize-NxtUninstallApplication
				CustomUninstallBegin
				[string]$script:installPhase = 'Package-Uninstallation'
				[PSADTNXT.NxtApplicationResult]$mainNxtResult = Uninstall-NxtApplication
				CustomUninstallEnd -ResultToCheck $mainNxtResult
				if ($false -ne $mainNxtResult.Success) {
					[string]$script:installPhase = 'Package-Completition'
					Complete-NxtPackageUninstallation
					[string]$script:installPhase = 'Package-Unregistration'
					Unregister-NxtPackage
				}
				else {
					Exit-NxtScriptWithError -ErrorMessage $mainNxtResult.ErrorMessage -ErrorMessagePSADT $mainNxtResult.ErrorMessagePSADT -MainExitCode $mainNxtResult.MainExitCode
				}
				## END OF UNINSTALL
			}
			"InstallUserPart" {
				## START OF USERPARTINSTALL
				CustomInstallUserPartBegin
				CustomInstallUserPartEnd
				## END OF USERPARTINSTALL
			}
			"UninstallUserPart" {
				## START OF USERPARTUNINSTALL
				CustomUninstallUserPartBegin
				CustomUninstallUserPartEnd
				## END OF USERPARTUNINSTALL
			}
			Default {}
		}
		[string]$script:installPhase = 'Package-Finish'
		## Calculate exit code
		If ($Reboot -eq 1) { [int32]$mainExitCode = 3010 }
		If ($Reboot -eq 2 -and ($mainExitCode -eq 3010 -or $mainExitCode -eq 1641)) { [int32]$mainExitCode = 0 }
		Exit-Script -ExitCode $mainExitCode
	}
	catch {
		## Unhandled exception occured
		[int32]$mainExitCode = 60001
		[string]$mainErrorMessage = "$(Resolve-Error)"
		Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
		Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
		Exit-NxtScriptWithError -ErrorMessage "The installation/uninstallation aborted with an error message!" -ErrorMessagePSADT $($Error[0].Exception.Message) -MainExitCode $mainExitCode
	}
}

#region Entry point funtions to perform custom tasks during script run
## Custom functions are sorted by occurence order in the main function.
## Naming pattern: 
## {functionType}{Phase}{PrePosition}{SubPhase}
function CustomBegin {
	[string]$script:installPhase = 'CustomBegin'

	## Always executes at the beginning of the script regardless of the DeploymentType ('Install', 'Uninstall', 'Repair', 'InstallUserPart', 'UninstallUserPart')
}

function CustomInstallAndReinstallBegin {
	[string]$script:installPhase = 'CustomInstallAndReinstallBegin'

	## Executes before any installation, reinstallation or softmigration tasks are performed
}

function CustomSoftMigrationBegin{
	[string]$script:installPhase = 'CustomSoftMigrationBegin'

	## Executes before a default check of SoftMigration runs
	## after successful individual checks for soft migration the following variable has to be set at the end of this section:
	## [bool]$global:SoftMigrationCustomResult = $true
}

function CustomInstallAndReinstallAndSoftMigrationEnd {
	param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomInstallAndReinstallAndSoftMigrationEnd'

	## Executes after the completed install or reinstall process and on SoftMigration
}

function CustomInstallAndReinstallPreInstallAndReinstall {
	[string]$script:installPhase = 'CustomInstallAndReinstallPreInstallAndReinstall'

	## Executes before any installation or reinstallation tasks are performed
	## after successful individual checks for installed application state the following variable has to be set at the end of this section:
	## [bool]$global:AppInstallDetectionCustomResult = $true
}

function CustomReinstallPreUninstall {
	[string]$script:installPhase = 'CustomReinstallPreUninstall'

	## Executes before the uninstallation in the reinstall process
}

function CustomReinstallPostUninstall {
	param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomReinstallPostUninstall'

	## Executes at after the uninstallation in the reinstall process
}

function CustomReinstallPreInstall {
	[string]$script:installPhase = 'CustomReinstallPreInstall'

	## Executes before the installation in the reinstall process
}

function CustomReinstallPostInstall {
	param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomReinstallPostInstall'

	## Executes after the installation in the reinstall process
}

function CustomInstallBegin {
	[string]$script:installPhase = 'CustomInstallBegin'

	## Executes before the installation in the install process
}

function CustomInstallEnd {
	param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomInstallEnd'

	## Executes after the installation in the install process
}

function CustomInstallAndReinstallEnd {
	param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomPostInstallAndReinstall'

	## Executes after the completed install or reinstall process
}

function CustomUninstallBegin {
	[string]$script:installPhase = 'CustomUninstallBegin'

	## Executes before the uninstallation in the uninstall process
}

function CustomUninstallEnd {
	param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomUninstallEnd'

	## Executes after the uninstallation in the uninstall process
}

function CustomInstallUserPartBegin {
	[string]$script:installPhase = 'CustomInstallUserPartBegin'

	## Executes at the Beginning of InstallUserPart if the script is started with the value 'InstallUserPart' for parameter 'DeploymentType'
}

function CustomInstallUserPartEnd {
	[string]$script:installPhase = 'CustomInstallUserPartEnd'

	## Executes at the end of InstallUserPart if the script is executed started with the value 'InstallUserPart' for parameter 'DeploymentType'
}

function CustomUninstallUserPartBegin {
	[string]$script:installPhase = 'CustomUninstallUserPartBegin'

	## Executes at the beginning of UnInstallUserPart if the script is started with the value 'UnInstallUserPart' for parameter 'DeploymentType'
}

function CustomUninstallUserPartEnd {
	[string]$script:installPhase = 'CustomUninstallUserPartEnd'

	## Executes at the end of UnInstallUserPart if the script is executed started with the value 'UninstallUserPart' for parameter 'DeploymentType'
}

#endregion

## Execute the main function to start the process
Main
