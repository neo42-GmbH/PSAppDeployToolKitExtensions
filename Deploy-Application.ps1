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
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered. Default is: $true.
	Please use the corresponding value 'Reboot' from the PackageConfig object to control behavior of such reboot return codes instead.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Desktop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.PARAMETER SkipUnregister
	Skips unregister during uninstall of a package. Default is: $false.
	Note: internally used to prevent unregister of assigned application packages to a product if called from another script only. Also additionally again prevents attempts to remove product member packages in the recursive uninstall call.
.PARAMETER DeploymentSystem
	Can be used to specify the deployment system that is used to deploy the application. Default is: [string]::Empty.
	Required by some "*-Nxt*" functions to handle deployment system specific tasks.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru $false; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
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
	[bool]$AllowRebootPassThru = $true,
	[Parameter(Mandatory = $false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory = $false)]
	[switch]$DisableLogging = $false,
	[Parameter(Mandatory = $false)]
	[switch]$SkipUnregister = $false,
	[Parameter(Mandatory = $false)]
	[string]$DeploymentSystem = [string]::Empty
)
## During UserPart execution, invoke self asynchronously to prevent logon freeze caused by active setup.
switch ($DeploymentType) {
	TriggerInstallUserPart { 
		Start-Process -FilePath "$env:windir\system32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -WindowStyle hidden -NoProfile -File `"$($script:MyInvocation.MyCommand.Path)`" -DeploymentType InstallUserPart"
		Exit
	}
	TriggerUninstallUserPart { 
		Start-Process -FilePath "$env:windir\system32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -WindowStyle hidden -NoProfile -File `"$($script:MyInvocation.MyCommand.Path)`" -DeploymentType UninstallUserPart"
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
[string]$global:UserPartDir = "User"
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
## dot source the required AppDeploy Toolkit functions
Try {
	[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
	If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
	If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	## add custom 'Nxt' variables
	[string]$appDeployLogoBannerDark = Join-Path -Path $scriptRoot -ChildPath $xmlBannerIconOptions.Banner_Filename_Dark
}
Catch {
	If ($mainExitCode -eq 0) { [int32]$mainExitCode = 60008 }
	Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
	## exit the script, returning the exit code to SCCM
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

function Main {
	<#
	.SYNOPSIS
		Defines the flow of the installation script.
	.DESCRIPTION
		Do not modify to ensure correct script flow!
		To customize the script always use the "CustomXXXX" entry points.
	.PARAMETER SkipUnregister
		Skips unregister during uninstall of a package.
		Defaults to the the corresponding call parameter of this script.
	.PARAMETER ProductGUID
		Specifies a membership GUID for a product of an application package.
		Can be found under "HKLM:\Software\<RegPackagesKey>\<PackageGUID>" for an application package with product membership.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RemovePackagesWithSameProductGUID
		Defines to uninstall found all application packages with same ProductGUID (product membership) assigned.
		The uninstalled application packages stay registered, when removed during installation process of current application package.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PackageGUID
		Specifies the registry key name used for the packages wrapper uninstall entry.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegPackagesKey
		Defines the name of the registry key keeping track of all packages delivered by this packaging framework.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER Reboot
		Defines if a reboot exit code should be returned instead of the main exit code.
		0 = do not override mainExitCode
		1 = always set mainExitCode to 3010 (reboot required)
		2 = Set exit code to 0 instead of a reboot exit code, exit codes other than 1641 and 3010 will be passed through.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER InstallMethod
		Defines the type of the installer used in this package.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegisterPackage
		Specifies if package may be registered (maybe superseded by deployment system!).
		Defaults to the corresponding global value.
	.EXAMPLE
		Main
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	param (
		[Parameter(Mandatory = $false)]
		[bool]
		$SkipUnregister = $SkipUnregister,
		[Parameter(Mandatory = $false)]
		[String]
		$ProductGUID = $global:PackageConfig.ProductGUID,
		[Parameter(Mandatory = $false)]
		[bool]
		$RemovePackagesWithSameProductGUID = $global:PackageConfig.RemovePackagesWithSameProductGUID,
		[Parameter(Mandatory = $false)]
		[string]
		$PackageGUID = $global:PackageConfig.PackageGUID,
		[Parameter(Mandatory = $false)]
		[string]
		$RegPackagesKey = $global:PackageConfig.RegPackagesKey,
		[Parameter(Mandatory = $false)]
		[int]
		[ValidateSet(0, 1, 2)]
		$Reboot = $global:PackageConfig.reboot,
		[Parameter(Mandatory = $false)]
		[string]
		$InstallMethod = $global:PackageConfig.InstallMethod,
		[Parameter(Mandatory = $false)]
		[bool]
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
					Close-BlockExecutionWindow
					Exit-Script -ExitCode $mainNxtResult.MainExitCode
				}
				Unregister-NxtOld
				Resolve-NxtDependentPackage
				if ( ($true -eq $global:SetupCfg.Options.SoftMigration) -and -not (Test-RegistryValue -Key HKLM\Software\$RegPackagesKey\$PackageGUID -Value 'ProductName') -and ($true -eq $RegisterPackage) -and ((Get-NxtRegisteredPackage -ProductGUID "$ProductGUID").count -eq 0) -and (-not $RemovePackagesWithSameProductGUID) ) {
					CustomSoftMigrationBegin
				}
				[string]$script:installPhase = 'Check-SoftMigration'
				if ($true -eq $(Get-NxtRegisterOnly)) {
					## soft migration = application is installed
					$mainNxtResult.Success = $true
				}
				else {
					## soft migration is not requested or not possible
					[string]$script:installPhase = 'Package-Preparation'
					Remove-NxtProductMember
					[int]$showInstallationWelcomeResult = Show-NxtInstallationWelcome -IsInstall $true -AllowDeferCloseApps
					if ($showInstallationWelcomeResult -ne 0) {
						Close-BlockExecutionWindow
						Exit-Script -ExitCode $showInstallationWelcomeResult
					}
					CustomInstallAndReinstallPreInstallAndReinstall
					[string]$script:installPhase = 'Decide-ReInstallMode'
					if ( ($true -eq $(Test-NxtAppIsInstalled -DeploymentMethod $InstallMethod)) -or ($true -eq $global:AppInstallDetectionCustomResult) ) {
						if ($true -eq $global:AppInstallDetectionCustomResult) {
							Write-Log -Message "Found an installed application: detected by custom pre-checks." -Source $deployAppScriptFriendlyName
						}
						else {
							[string]$global:PackageConfig.ReinstallMode = $(Switch-NxtMSIReinstallMode)
						}
						Write-Log -Message "[$script:installPhase] selected mode: $($global:PackageConfig.ReinstallMode)" -Source $deployAppScriptFriendlyName
						switch ($global:PackageConfig.ReinstallMode) {
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
								Throw "Unsupported 'ReinstallMode' property: $($global:PackageConfig.ReinstallMode)"
							}
						}
					}
					else {
						## default installation
						CustomInstallBegin
						[string]$script:installPhase = 'Package-Installation'
						[PSADTNXT.NxtApplicationResult]$mainNxtResult = Install-NxtApplication 
						CustomInstallEnd -ResultToCheck $mainNxtResult
					}
					CustomInstallAndReinstallEnd -ResultToCheck $mainNxtResult
				}
				## here we continue if application is present and/or register package is necessary only.
				CustomInstallAndReinstallAndSoftMigrationEnd -ResultToCheck $mainNxtResult
				If ($false -ne $mainNxtResult.Success) {
					[string]$script:installPhase = 'Package-Completion'
					Complete-NxtPackageInstallation
					if ($true -eq $RegisterPackage) {
						## register package for uninstall
						[string]$script:installPhase = 'Package-Registration'
						Register-NxtPackage
					} else {
						Write-Log -Message "No need to register package." -Source $deployAppScriptFriendlyName
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
				if ( ($true -eq $RemovePackagesWithSameProductGUID) -and ($false -eq $SkipUnregister) ) {
					Remove-NxtProductMember
				}
				if ($true -eq $(Get-NxtRegisteredPackage -PackageGUID "$PackageGUID" -InstalledState 1)) {
					Show-NxtInstallationWelcome -IsInstall $false
					Initialize-NxtUninstallApplication
					CustomUninstallBegin
					[string]$script:installPhase = 'Package-Uninstallation'
					[PSADTNXT.NxtApplicationResult]$mainNxtResult = Uninstall-NxtApplication
					CustomUninstallEnd -ResultToCheck $mainNxtResult
					if ($false -ne $mainNxtResult.Success) {
						[string]$script:installPhase = 'Package-Completion'
						Complete-NxtPackageUninstallation
					}
					else {
						Exit-NxtScriptWithError -ErrorMessage $mainNxtResult.ErrorMessage -ErrorMessagePSADT $mainNxtResult.ErrorMessagePSADT -MainExitCode $mainNxtResult.MainExitCode
					}
				}
				if ($false -eq $SkipUnregister) {
					[string]$script:installPhase = 'Package-Unregistration'
					Unregister-NxtPackage
				}
				else {
					Write-Log -Message "No need to unregister package(s) now..." -Source ${cmdletName}
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
		## calculate exit code
		if ($Reboot -eq 1) { [int32]$mainExitCode = 3010 }
		if ($Reboot -eq 2 -and ($mainExitCode -eq 3010 -or $mainExitCode -eq 1641 -or $true -eq $msiRebootDetected)) {
			[int32]$mainExitCode = 0
			Set-Variable -Name 'msiRebootDetected' -Value $false -Scope 'Script'
		}
		Close-BlockExecutionWindow
		Exit-Script -ExitCode $mainExitCode
	}
	catch {
		## unhandled exception occured
		[int32]$mainExitCode = 60001
		[string]$mainErrorMessage = "$(Resolve-Error)"
		Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
		Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
		Exit-NxtScriptWithError -ErrorMessage "The installation/uninstallation aborted with an error message!" -ErrorMessagePSADT $($Error[0].Exception.Message) -MainExitCode $mainExitCode
	}
}

#region entry point functions to perform custom tasks during script run
## custom functions are sorted by occurrence order in the main function.
## naming pattern: 
## {functionType}{Phase}{PrePosition}{SubPhase}
function CustomBegin {
	[string]$script:installPhase = 'CustomBegin'

	## executes always at the beginning of the script regardless of the DeploymentType ('Install', 'Uninstall', 'Repair', 'InstallUserPart', 'UninstallUserPart')
	#region CustomBegin content

	#endregion CustomBegin content
}

function CustomInstallAndReinstallBegin {
	[string]$script:installPhase = 'CustomInstallAndReinstallBegin'

	## executes before any installation, reinstallation or soft migration tasks are performed
	#region CustomInstallAndReinstallBegin content

	#endregion CustomInstallAndReinstallBegin content
}

function CustomSoftMigrationBegin {
	[string]$script:installPhase = 'CustomSoftMigrationBegin'

	## executes before a default check of soft migration runs
	## after successful individual checks for soft migration the following variable has to be set at the end of this section:
	## [bool]$global:SoftMigrationCustomResult = $true
	#region CustomSoftMigrationBegin content

	#endregion CustomSoftMigrationBegin content
}

function CustomInstallAndReinstallAndSoftMigrationEnd {
	param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomInstallAndReinstallAndSoftMigrationEnd'

	## executes after the completed install or reinstall process and on soft migration
	#region CustomInstallAndReinstallAndSoftMigrationEnd content

	#endregion CustomInstallAndReinstallAndSoftMigrationEnd content
}

function CustomInstallAndReinstallPreInstallAndReinstall {
	[string]$script:installPhase = 'CustomInstallAndReinstallPreInstallAndReinstall'

	## executes before any installation or reinstallation tasks are performed
	## after successful individual checks for installed application state the following variable has to be set at the end of this section:
	## [bool]$global:AppInstallDetectionCustomResult = $true
	#region CustomInstallAndReinstallPreInstallAndReinstall content

	#endregion CustomInstallAndReinstallPreInstallAndReinstall content
}

function CustomReinstallPreUninstall {
	[string]$script:installPhase = 'CustomReinstallPreUninstall'

	## executes before the uninstallation in the reinstall process
	#region CustomReinstallPreUninstall content

	#endregion CustomReinstallPreUninstall content
}

function CustomReinstallPostUninstall {
	param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomReinstallPostUninstall'

	## executes at after the uninstallation in the reinstall process
	#region CustomReinstallPostUninstall content

	#endregion CustomReinstallPostUninstall content
}

function CustomReinstallPreInstall {
	[string]$script:installPhase = 'CustomReinstallPreInstall'

	## executes before the installation in the reinstall process
	#region CustomReinstallPreInstall content

	#endregion CustomReinstallPreInstall content
}

function CustomReinstallPostInstall {
	param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomReinstallPostInstall'

	## executes after the installation in the reinstall process
	#region CustomReinstallPostInstall content

	#endregion CustomReinstallPostInstall content
}

function CustomInstallBegin {
	[string]$script:installPhase = 'CustomInstallBegin'

	## executes before the installation in the install process
	#region CustomInstallBegin content

	#endregion CustomInstallBegin content
}

function CustomInstallEnd {
	param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomInstallEnd'

	## executes after the installation in the install process
	#region CustomInstallEnd content

	#endregion CustomInstallEnd content
}

function CustomInstallAndReinstallEnd {
	param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomPostInstallAndReinstall'

	## executes after the completed install or reinstall process
	#region CustomInstallAndReinstallEnd content

	#endregion CustomInstallAndReinstallEnd content
}

function CustomUninstallBegin {
	[string]$script:installPhase = 'CustomUninstallBegin'

	## executes before the uninstallation in the uninstall process
	#region CustomUninstallBegin content

	#endregion CustomUninstallBegin content
}

function CustomUninstallEnd {
	param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomUninstallEnd'

	## executes after the uninstallation in the uninstall process
	#region CustomUninstallEnd content

	#endregion CustomUninstallEnd content
}

function CustomInstallUserPartBegin {
	[string]$script:installPhase = 'CustomInstallUserPartBegin'

	## executes at the beginning of InstallUserPart if the script is started with the value 'InstallUserPart' for parameter 'DeploymentType'
	#region CustomInstallUserPartBegin content

	#endregion CustomInstallUserPartBegin content
}

function CustomInstallUserPartEnd {
	[string]$script:installPhase = 'CustomInstallUserPartEnd'

	## executes at the end of InstallUserPart if the script is executed started with the value 'InstallUserPart' for parameter 'DeploymentType'
	#region CustomInstallUserPartEnd content

	#endregion CustomInstallUserPartEnd content
}

function CustomUninstallUserPartBegin {
	[string]$script:installPhase = 'CustomUninstallUserPartBegin'

	## executes at the beginning of UnInstallUserPart if the script is started with the value 'UnInstallUserPart' for parameter 'DeploymentType'
	#region CustomUninstallUserPartBegin content

	#endregion CustomUninstallUserPartBegin content
}

function CustomUninstallUserPartEnd {
	[string]$script:installPhase = 'CustomUninstallUserPartEnd'

	## executes at the end of UnInstallUserPart if the script is executed started with the value 'UninstallUserPart' for parameter 'DeploymentType'
	#region CustomUninstallUserPartEnd content

	#endregion CustomUninstallUserPartEnd content
}

#endregion

## execute the main function to start the process
Main
