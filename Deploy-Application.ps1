<#
.SYNOPSIS
	This script performs the installation, repair or uninstallation of an application(s).
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
	powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; exit $LastExitCode }"
.EXAMPLE
	powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru $false; exit $LastExitCode }"
.EXAMPLE
	powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; exit $LastExitCode }"
.NOTES
	This script has been extensively modified by neo42 GmbH, building upon the template provided by the PowerShell App Deployment Toolkit.
	Be aware that while it serves the original purpose of the PowerShell App Deployment Toolkit, it is not compatible with the original version.
	Changes include but are not limited to:
		- Unified script file
		- External configuration file
		- Customized logging
		- Custom hook functions

	# LICENSE #
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

	# ORIGINAL COPYRIGHT #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.

	# MODIFICATION COPYRIGHT #
	Copyright (c) 2024 neo42 GmbH, Germany.

	Version: ##REPLACEVERSION##
	ConfigVersion: 2023.10.31.1
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
#region Function Start-NxtProcess
function Start-NxtProcess {
	<#
	.SYNOPSIS
		Start a process by filename.
	.DESCRIPTION
		Replacement for the native Start-Process cmdlet using .NET process Object.
	.PARAMETER FilePath
		Path for the filename that should be called.
	.PARAMETER Arguments
		Arguments for the process.
	.PARAMETER UseShellExecute
		Specifies the UseShellExecute parameter. Default: $false.
	.EXAMPLE
		Start-NxtProcess -FileName "C:\Windows\SysNative\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-File "C:\Users\labadmin\PSAppDeployToolKitExtensions\Deploy-Application.ps1""
	.OUTPUTS
		System.Diagnostics.Process
	.LINK
		https://neo42.de/psappdeploytoolkit
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$FilePath,
		[Parameter(Mandatory = $false)]
		[string]
		$Arguments,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Switch]
		$UseShellExecute = $false
	)
	Process {
		[System.Diagnostics.ProcessStartInfo]$processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
		$processStartInfo.FileName = $FilePath
		$processStartInfo.Arguments = $Arguments
		$processStartInfo.UseShellExecute = $UseShellExecute
		[System.Diagnostics.Process]$process = [System.Diagnostics.Process]::Start($processStartInfo)
		Write-Output -InputObject $process
	}
}
#endregion
## Only use system environment variables and modules during script execution
if ($DeploymentType -notin @('InstallUserPart', 'UninstallUserPart')) {
	foreach ($variable in [System.Environment]::GetEnvironmentVariables("User").Keys) {
		[System.Environment]::SetEnvironmentVariable($variable, [System.Environment]::GetEnvironmentVariable($variable, "Machine"), "Process")
	}
}
$env:PSModulePath = @("$env:ProgramFiles\WindowsPowerShell\Modules","$env:windir\system32\WindowsPowerShell\v1.0\Modules") -join ";"
## If running in 32-bit PowerShell, reload in 64-bit PowerShell if possible
if ($env:PROCESSOR_ARCHITECTURE -eq "x86" -and (Get-WmiObject Win32_OperatingSystem).OSArchitecture -eq "64-bit") {
	Write-Host "PROCESSOR_ARCHITECTURE: $($env:PROCESSOR_ARCHITECTURE)"
	Write-Host "OSArchitecture: $((Get-WmiObject Win32_OperatingSystem).OSArchitecture)"
	Write-Host $($MyInvocation.BoundParameters)
	Write-Host "Will restart script in 64bit PowerShell"
	[string]$file = $MyInvocation.MyCommand.Path
	# add all bound parameters to the argument list
	[string]$arguments = [string]::Empty
	foreach ($item in $MyInvocation.BoundParameters.Keys) {
		[PsObject]$type = $($MyInvocation.BoundParameters[$item]).GetType()
		if ($type -eq [switch]) {
			if ($true -eq $MyInvocation.BoundParameters[$item]) {
				$arguments += " -$item"
			}
		}
		elseif ($type -eq [string]) {
			$arguments += " -$item `"$($MyInvocation.BoundParameters[$item])`""
		}
		elseif ($type -eq [int]) {
			$arguments += " -$item $($MyInvocation.BoundParameters[$item])"
		}
		elseif ($type -eq [bool]) {
			$arguments += " -$item $($MyInvocation.BoundParameters[$item])"
		}
	}
	if ($true -eq (Test-Path -Path "$PSScriptRoot\DeployNxtApplication.exe")) {
		[System.Diagnostics.Process]$process = Start-NxtProcess -FilePath "$PSScriptRoot\DeployNxtApplication.exe" -Arguments "$arguments"
	}
	else {
		[System.Diagnostics.Process]$process = Start-NxtProcess -FilePath "$env:windir\SysNative\WindowsPowerShell\v1.0\powershell.exe" -Arguments " -ExecutionPolicy $(Get-ExecutionPolicy -Scope Process) -File `"$file`"$arguments"
	}
	$process.WaitForExit()
	[int]$exitCode = $process.ExitCode
	exit $exitCode
}
## During UserPart execution, invoke self asynchronously to prevent logon freeze caused by active setup.
switch ($DeploymentType) {
	TriggerInstallUserPart {
		if ($true -eq (Test-Path -Path "$PSScriptRoot\DeployNxtApplication.exe")) {
			[System.Diagnostics.Process]$process = Start-NxtProcess -FilePath "$PSScriptRoot\DeployNxtApplication.exe" -Arguments "-DeploymentType InstallUserPart"
		}
		else {
			Start-NxtProcess -FilePath "$env:windir\system32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy $(Get-ExecutionPolicy -Scope Process) -WindowStyle hidden -NoProfile -File `"$($script:MyInvocation.MyCommand.Path)`" -DeploymentType InstallUserPart" | Out-Null
		}
		exit
	}
	TriggerUninstallUserPart {
		if ($true -eq (Test-Path -Path "$PSScriptRoot\DeployNxtApplication.exe")) {
			[System.Diagnostics.Process]$process = Start-NxtProcess -FilePath "$PSScriptRoot\DeployNxtApplication.exe" -Arguments "-DeploymentType UninstallUserPart"
		}
		else {
			Start-NxtProcess -FilePath "$env:windir\system32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy $(Get-ExecutionPolicy -Scope Process) -WindowStyle hidden -NoProfile -File `"$($script:MyInvocation.MyCommand.Path)`" -DeploymentType UninstallUserPart" | Out-Null
		}
		exit
	}
	Default {}
}
## Global default variables
[string]$global:Neo42PackageConfigPath = "$PSScriptRoot\neo42PackageConfig.json"
[string]$global:Neo42PackageConfigValidationPath = "$PSScriptRoot\neo42PackageConfigValidationRules.json"
[string]$global:SetupCfgPath = "$PSScriptRoot\Setup.cfg"
[string]$global:CustomSetupCfgPath = "$PSScriptRoot\CustomSetup.cfg"
[string]$global:DeployApplicationPath = "$PSScriptRoot\Deploy-Application.ps1"
[string]$global:AppDeployToolkitExtensionsPath = "$PSScriptRoot\AppDeployToolkit\AppDeployToolkitExtensions.ps1"
[string]$global:AppDeployToolkitConfigPath = "$PSScriptRoot\AppDeployToolkit\AppDeployToolkitConfig.xml"
[string]$global:DeploymentSystem = $DeploymentSystem
[string]$global:UserPartDir = "User"
## Attention: All file/directory entries in this array will be deleted at the end of the script if it is a subpath of the default temp folder!
[string[]]$script:NxtTempDirectories = @()
## We temporarily load the package config to get the appVendor, appName and appVersion variables which are also required to define the AppLogFolder.
$tempLoadPackageConfig = (Get-Content "$global:Neo42PackageConfigPath" -raw ) | ConvertFrom-Json
## Several PSADT-functions do not work, if these variables are not set here.
[string]$appVendor = $tempLoadPackageConfig.AppVendor
[string]$appName = $tempLoadPackageConfig.AppName
[string]$appVersion = $tempLoadPackageConfig.AppVersion
[string]$global:AppLogFolder = "$env:ProgramData\$($tempLoadPackageConfig.AppRootFolder)Logs\$appVendor\$appName\$appVersion"
Remove-Variable -Name tempLoadPackageConfig
##* Do not modify section below =============================================================================================================================================
#region DoNotModify
## Set the script execution policy for this process
[xml]$tempLoadToolkitConfig = Get-Content "$global:AppDeployToolkitConfigPath" -Raw
[string]$powerShellOptionsExecutionPolicy = $tempLoadToolkitConfig.AppDeployToolkit_Config.NxtPowerShell_Options.NxtPowerShell_ExecutionPolicy
if (($true -eq [string]::IsNullOrEmpty($powerShellOptionsExecutionPolicy)) -or ([Enum]::GetNames([Microsoft.Powershell.ExecutionPolicy]) -notcontains $powerShellOptionsExecutionPolicy)) {
	Write-Error -Message "Invalid value for 'Toolkit_ExecutionPolicy' property in 'AppDeployToolkitConfig.xml'."
	exit 60014
}
try {
	Set-ExecutionPolicy -ExecutionPolicy $powerShellOptionsExecutionPolicy -Scope 'Process' -Force -ErrorAction 'Stop'
}
catch {
	Write-Warning "Execution Policy did not match current and override was not successful. Is a GPO in place? Error: $($_.Exception.Message)"
}
Remove-Variable -Name powerShellOptionsExecutionPolicy
Remove-Variable -Name tempLoadToolkitConfig
## Variables: Exit Code
[int32]$mainExitCode = 0
## Variables: Script
[string]$deployAppScriptFriendlyName = 'Deploy Application'
[string]$deployAppScriptVersion = [string]'##REPLACEVERSION##'
[string]$deployAppScriptDate = '02/05/2023'
[hashtable]$deployAppScriptParameters = $psBoundParameters
## Variables: Environment
if (Test-Path -LiteralPath 'variable:HostInvocation') {
	$InvocationInfo = $HostInvocation
}
else {
	$InvocationInfo = $MyInvocation
}
[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
## dot source the required AppDeploy Toolkit functions
try {
	[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
	if ($false -eq (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) {
		throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]."
	}
	if ($true -eq $DisableLogging) {
		. $moduleAppDeployToolkitMain -DisableLogging
	} else {
		. $moduleAppDeployToolkitMain
	}
	## add custom 'Nxt' variables
	[string]$appDeployLogoBannerDark = Join-Path -Path $scriptRoot -ChildPath $xmlBannerIconOptions.Banner_Filename_Dark
}
catch {
	if ($mainExitCode -eq 0) {
		[int32]$mainExitCode = 60008
	}
	Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
	## exit the script, returning the exit code to SCCM
	if (Test-Path -LiteralPath 'variable:HostInvocation') {
		$script:ExitCode = $mainExitCode
		exit
	}
	else {
		exit $mainExitCode
	}
}
#endregion
##* Do not modify section above	=============================================================================================================================================

try {
	[string]$script:installPhase = 'Initialize-Environment'
	Initialize-NxtEnvironment
	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================

	## App global variables
	Get-NxtVariablesFromDeploymentSystem

	[bool]$global:SoftMigrationCustomResult = $false
	[bool]$global:AppInstallDetectionCustomResult = $false

	## Validate package config variables
	Test-NxtPackageConfig

	## Write variables to verbose channel to prevent warnings issued by PSScriptAnalyzer
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] Neo42PackageConfigValidationPath: $global:Neo42PackageConfigValidationPath"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] Neo42PackageConfigPath: $global:Neo42PackageConfigPath"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] SetupCfgPath: $global:SetupCfgPath"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] CustomSetupCfgPath: $global:CustomSetupCfgPath"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] DeployApplicationPath: $global:DeployApplicationPath"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] AppDeployToolkitExtensionsPath: $global:AppDeployToolkitExtensionsPath"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] deployAppScriptVersion: $deployAppScriptVersion"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] deployAppScriptDate: $deployAppScriptDate"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] deployAppScriptParameters: $deployAppScriptParameters"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] appDeployLogoBannerDark: $appDeployLogoBannerDark"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] DetectedDisplayVersion: $global:DetectedDisplayVersion"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] SoftMigrationCustomResult (prefillvalue): $global:SoftMigrationCustomResult"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] UserPartDir: $global:UserPartDir"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] appVendor: $appVendor"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] appName: $appName"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] appVersion: $appVersion"
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] AppLogFolder: $global:AppLogFolder"

	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================
}
catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	if ($DeploymentType -notin @("InstallUserPart", "UninstallUserPart")) {
		Clear-NxtTempFolder
	}
	Exit-Script -ExitCode $mainExitCode
}

function Main {
	<#
	.SYNOPSIS
		Defines the flow of the installation script.
	.DESCRIPTION
		Do not modify to ensure correct script flow!
		To customize the script always use the "CustomXXXX" entry points.
	.PARAMETER DeploymentType
		The type of deployment that is performed.
		Defaults to the corresponding call parameter of the Deploy-Application.ps1 script.
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
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$DeploymentType = $DeploymentType,
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
		[string]
		$InstallMethod = $global:PackageConfig.InstallMethod,
		[Parameter(Mandatory = $false)]
		[bool]
		$RegisterPackage = $global:registerPackage
	)
	try {
		Test-NxtConfigVersionCompatibility
		CustomBegin
		switch ($DeploymentType) {
			{
				($_ -eq "Install") -or ($_ -eq "Repair")
			} {
				CustomInstallAndReinstallAndSoftMigrationBegin
				## START OF INSTALL
				[string]$script:installPhase = 'Package-PreCleanup'
				[PSADTNXT.NxtApplicationResult]$mainNxtResult = Uninstall-NxtOld
				if ($false -eq $mainNxtResult.Success) {
					Clear-NxtTempFolder
					Unblock-NxtAppExecution
					Exit-Script -ExitCode $mainNxtResult.MainExitCode
				}
				Unregister-NxtOld
				Resolve-NxtDependentPackage
				[string]$script:installPhase = 'Check-SoftMigration'
				if ( ($true -eq $global:SetupCfg.Options.SoftMigration) -and ($false -eq (Test-RegistryValue -Key HKLM\Software\$RegPackagesKey\$PackageGUID -Value 'ProductName')) -and ($true -eq $RegisterPackage) -and ((Get-NxtRegisteredPackage -ProductGUID "$ProductGUID").count -eq 0) -and ($false -eq $RemovePackagesWithSameProductGUID) ) {
					CustomSoftMigrationBegin
				}
				[string]$script:installPhase = 'Check-SoftMigration'
				if ($false -eq $(Get-NxtRegisterOnly)) {
					## soft migration is not requested or not possible
					[string]$script:installPhase = 'Package-Preparation'
					Remove-NxtProductMember
					[int]$showInstallationWelcomeResult = Show-NxtInstallationWelcome -IsInstall $true -AllowDeferCloseApps
					if ($showInstallationWelcomeResult -ne 0) {
						switch ($showInstallationWelcomeResult) {
							'1618' {
								[string]$currentShowInstallationWelcomeMessageInstall = "Aborted by dialog window action or timeout of waiting for processes."
							}
							'60012' {
								[string]$currentShowInstallationWelcomeMessageInstall = "User deferred installation request."
							}
							default {
								[string]$currentShowInstallationWelcomeMessageInstall = "Show installation welcome window exit code: $showInstallationWelcomeResult"
							}
						}
						Exit-NxtScriptWithError -ErrorMessage $currentShowInstallationWelcomeMessageInstall -MainExitCode $showInstallationWelcomeResult
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
								if ($false -eq $mainNxtResult.Success) {
									CustomReinstallPostUninstallOnError -ResultToCheck $mainNxtResult
									Exit-NxtScriptWithError -ErrorMessage $mainNxtResult.ErrorMessage -ErrorMessagePSADT $mainNxtResult.ErrorMessagePSADT -MainExitCode $mainNxtResult.MainExitCode
								}
								CustomReinstallPostUninstall -ResultToCheck $mainNxtResult
								CustomReinstallPreInstall
								[string]$script:installPhase = 'Package-Reinstallation'
								[PSADTNXT.NxtApplicationResult]$mainNxtResult = Install-NxtApplication
								if ($false -eq $mainNxtResult.Success) {
									CustomReinstallPostInstallOnError -ResultToCheck $mainNxtResult
									Exit-NxtScriptWithError -ErrorMessage $mainNxtResult.ErrorMessage -ErrorMessagePSADT $mainNxtResult.ErrorMessagePSADT -MainExitCode $mainNxtResult.MainExitCode
								}
								CustomReinstallPostInstall -ResultToCheck $mainNxtResult
							}
							"MSIRepair" {
								if ("MSI" -eq $InstallMethod) {
									CustomReinstallPreInstall
									[string]$script:installPhase = 'Package-Reinstallation'
									[PSADTNXT.NxtApplicationResult]$mainNxtResult = Repair-NxtApplication
									if ($false -eq $mainNxtResult.Success) {
										CustomReinstallPostInstallOnError -ResultToCheck $mainNxtResult
										Exit-NxtScriptWithError -ErrorMessage $mainNxtResult.ErrorMessage -ErrorMessagePSADT $mainNxtResult.ErrorMessagePSADT -MainExitCode $mainNxtResult.MainExitCode
									}
									CustomReinstallPostInstall -ResultToCheck $mainNxtResult
								}
								else {
									throw "Unsupported combination of 'ReinstallMode' and 'InstallMethod' properties. Value 'MSIRepair' in 'ReinstallMode' is supported for installation method 'MSI' only!"
								}
							}
							"Install" {
								CustomReinstallPreInstall
								[string]$script:installPhase = 'Package-Reinstallation'
								[PSADTNXT.NxtApplicationResult]$mainNxtResult = Install-NxtApplication
								if ($false -eq $mainNxtResult.Success) {
									CustomReinstallPostInstallOnError -ResultToCheck $mainNxtResult
									Exit-NxtScriptWithError -ErrorMessage $mainNxtResult.ErrorMessage -ErrorMessagePSADT $mainNxtResult.ErrorMessagePSADT -MainExitCode $mainNxtResult.MainExitCode
								}
								CustomReinstallPostInstall -ResultToCheck $mainNxtResult
							}
							Default {
								throw "Unsupported 'ReinstallMode' property: $($global:PackageConfig.ReinstallMode)"
							}
						}
					}
					else {
						## default installation
						CustomInstallBegin
						[string]$script:installPhase = 'Package-Installation'
						[PSADTNXT.NxtApplicationResult]$mainNxtResult = Install-NxtApplication
						if ($false -eq $mainNxtResult.Success) {
							CustomInstallEndOnError -ResultToCheck $mainNxtResult
							Exit-NxtScriptWithError -ErrorMessage $mainNxtResult.ErrorMessage -ErrorMessagePSADT $mainNxtResult.ErrorMessagePSADT -MainExitCode $mainNxtResult.MainExitCode
						}
						CustomInstallEnd -ResultToCheck $mainNxtResult
					}
					if ($true -eq $global:SetupCfg.Options.SoftMigration) {
						[string]$softMigrationOccurred = "false"
					}
					CustomInstallAndReinstallEnd -ResultToCheck $mainNxtResult
				}
				else {
					[string]$softMigrationOccurred = "true"
				}
				## here we continue if application is present and/or register package is necessary only.
				CustomInstallAndReinstallAndSoftMigrationEnd -ResultToCheck $mainNxtResult
				## calculate exit code (at this point we always should have a non-error case or a reboot request)
				[string]$script:installPhase = 'Package-Completion'
				[PSADTNXT.NxtRebootResult]$rebootRequirementResult = Get-NxtRebootRequirement
				Complete-NxtPackageInstallation
				if ($true -eq $RegisterPackage) {
					## register package for uninstall
					[string]$script:installPhase = 'Package-Registration'
					Register-NxtPackage -MainExitCode $rebootRequirementResult.MainExitCode -LastErrorMessage $returnErrorMessage -SoftMigrationOccurred $softMigrationOccurred
				}
				else {
					Write-Log -Message "No need to register package." -Source $deployAppScriptFriendlyName
				}
				## END OF INSTALL
			}
			"Uninstall" {
				## START OF UNINSTALL
				[string]$script:installPhase = 'Package-Preparation'
				if ( ($true -eq $RemovePackagesWithSameProductGUID) -and ($false -eq $SkipUnregister) ) {
					Remove-NxtProductMember
				}
				if ( ($true -eq $RegisterPackage) -and ($true -eq $(Get-NxtRegisteredPackage -PackageGUID "$PackageGUID" -InstalledState 1)) ) {
					[int]$showUnInstallationWelcomeResult = Show-NxtInstallationWelcome -IsInstall $false
					if ($showUnInstallationWelcomeResult -ne 0) {
						switch ($showUnInstallationWelcomeResult) {
							'1618' {
								[string]$currentShowInstallationWelcomeMessageUninstall = "Aborted by dialog window action or timeout of waiting for processes."
							}
							'60012' {
								[string]$currentShowInstallationWelcomeMessageUninstall = "User deferred installation request."
							}
							default {
								[string]$currentShowInstallationWelcomeMessageUninstall = "Show installation welcome window exit code: $showInstallationWelcomeResult"
							}
						}
						Exit-NxtScriptWithError -ErrorMessage $currentShowInstallationWelcomeMessageUninstall -MainExitCode $showUnInstallationWelcomeResult
					}
					Initialize-NxtUninstallApplication
					CustomUninstallBegin
					[string]$script:installPhase = 'Package-Uninstallation'
					[PSADTNXT.NxtApplicationResult]$mainNxtResult = Uninstall-NxtApplication
					if ($false -eq $mainNxtResult.Success) {
						CustomUninstallEndOnError -ResultToCheck $mainNxtResult
						Exit-NxtScriptWithError -ErrorMessage $mainNxtResult.ErrorMessage -ErrorMessagePSADT $mainNxtResult.ErrorMessagePSADT -MainExitCode $mainNxtResult.MainExitCode
					}
					CustomUninstallEnd -ResultToCheck $mainNxtResult
					[string]$script:installPhase = 'Package-Completion'
					Complete-NxtPackageUninstallation
				}
				if ($false -eq $SkipUnregister) {
					[string]$script:installPhase = 'Package-Unregistration'
					Unregister-NxtPackage
				}
				else {
					Write-Log -Message "No need to unregister package(s) now..." -Source $deployAppScriptFriendlyName
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
		[PSADTNXT.NxtRebootResult]$rebootRequirementResult = Set-NxtRebootVariable
		if ($DeploymentType -notin @("InstallUserPart", "UninstallUserPart")) {
			Clear-NxtTempFolder
			Unblock-NxtAppExecution
		}
		Exit-Script -ExitCode $rebootRequirementResult.MainExitCode
	}
	catch {
		## unhandled exception occured
		Write-Log -Message "$(Resolve-Error)" -Severity 3 -Source $deployAppScriptFriendlyName
		Exit-NxtScriptWithError -ErrorMessage "The installation/uninstallation aborted with an error message!" -ErrorMessagePSADT $($Error[0].Exception.Message) -MainExitCode 60001
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

function CustomInstallAndReinstallAndSoftMigrationBegin {
	[string]$script:installPhase = 'CustomInstallAndReinstallAndSoftMigrationBegin'

	## executes before any installation, reinstallation or soft migration tasks are performed
	#region CustomInstallAndReinstallAndSoftMigrationBegin content

	#endregion CustomInstallAndReinstallAndSoftMigrationBegin content
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
	Param (
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

function CustomReinstallPostUninstallOnError {
	Param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomReinstallPostUninstallOnError'

	## executes right after the uninstallation in the reinstall process (just add possible cleanup steps here, because scripts exits right after this function!)
	#region CustomReinstallPostUninstallOnError content

	#endregion CustomReinstallPostUninstallOnError content
}

function CustomReinstallPostUninstall {
	Param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomReinstallPostUninstall'

	## executes after the successful uninstallation in the reinstall process
	#region CustomReinstallPostUninstall content

	#endregion CustomReinstallPostUninstall content
}

function CustomReinstallPreInstall {
	[string]$script:installPhase = 'CustomReinstallPreInstall'

	## executes before the installation in the reinstall process
	#region CustomReinstallPreInstall content

	#endregion CustomReinstallPreInstall content
}

function CustomReinstallPostInstallOnError {
	Param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomReinstallPostInstallOnError'

	## executes right after the installation in the reinstall process (just add possible cleanup steps here, because scripts exits right after this function!)
	#region CustomReinstallPostInstallOnError content

	#endregion CustomReinstallPostInstallOnError content
}

function CustomReinstallPostInstall {
	Param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomReinstallPostInstall'

	## executes after the successful installation in the reinstall process
	#region CustomReinstallPostInstall content

	#endregion CustomReinstallPostInstall content
}

function CustomInstallBegin {
	[string]$script:installPhase = 'CustomInstallBegin'

	## executes before the installation in the install process
	#region CustomInstallBegin content

	#endregion CustomInstallBegin content
}

function CustomInstallEndOnError {
	Param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomInstallEndOnError'

	## executes right after the installation in the install process (just add possible cleanup steps here, because scripts exits right after this function!)
	#region CustomInstallEndOnError content

	#endregion CustomInstallEndOnError content
}

function CustomInstallEnd {
	Param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomInstallEnd'

	## executes after the successful installation in the install process
	#region CustomInstallEnd content

	#endregion CustomInstallEnd content
}

function CustomInstallAndReinstallEnd {
	Param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomInstallAndReinstallEnd'

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

function CustomUninstallEndOnError {
	Param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomUninstallEndOnError'

	## executes right after the uninstallation in the uninstall process (just add possible cleanup steps here, because scripts exits right after this function!)
	#region CustomUninstallEndOnError content

	#endregion CustomUninstallEndOnError content
}

function CustomUninstallEnd {
	Param (
		[Parameter(Mandatory = $true)]
		[PSADTNXT.NxtApplicationResult]
		$ResultToCheck
	)
	[string]$script:installPhase = 'CustomUninstallEnd'

	## executes after the successful uninstallation in the uninstall process
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
