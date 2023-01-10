<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
	# LICENSE #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
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
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
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
	[ValidateSet('Install', 'Uninstall', 'Repair', 'InstallUserPart', 'UninstallUserPart')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory = $false)]
	[ValidateSet('Interactive', 'Silent', 'NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory = $false)]
	[switch]$AllowRebootPassThru,
	[Parameter(Mandatory = $false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory = $false)]
	[switch]$DisableLogging = $false
)

## Several PSADT-functions do not work, if these variables are not set here. You may improve but NOT delete this section! <-- HJT
$global:PackageConfig = Get-Content "$PSScriptRoot\neo42PackageConfig.json" | Out-String | ConvertFrom-Json
[string]$appVendor = $global:PackageConfig.AppVendor
[string]$appName = $global:PackageConfig.AppName
[string]$appVersion = $global:PackageConfig.AppVersion

##* Do not modify section below =============================================================================================================================================
#region DoNotModify
## Set the script execution policy for this process
Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
## Variables: Exit Code
[int32]$mainExitCode = 0
## Variables: Script
[string]$deployAppScriptFriendlyName = 'Deploy Application'
[version]$deployAppScriptVersion = [version]'3.8.4'
[string]$deployAppScriptDate = '26/01/2021'
[hashtable]$deployAppScriptParameters = $psBoundParameters
## Variables: Environment
If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
## Dot source the required App Deploy Toolkit Functions
Try {
	[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
	If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
	If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
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
	[string]$global:installPhase = 'Initialize-Environment'
	Initialize-NxtEnvironment
	
	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================

	## Variables not from neo42PackageConfig.json
	[string]$setupCfgPath = "$scriptParentPath\Setup.cfg"
	

	## Variables: Application
	## Handled by HJT***
	[string]$method = $global:PackageConfig.Method

	## Environment
	[string]$installLocation = $global:PackageConfig.InstallLocation # Not referenced anywhere, obsolete?

	## App Global Variables
	[string]$global:detectedDisplayVersion = Get-RegistryKey -Key "$($global:PackageConfig.RegUninstallKey)" -Value 'DisplayVersion'


	Get-NxtVariablesFromDeploymentSystem


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
.PARAMETER ReinstallModeIsRepair
		Defines if an installation should perform a repair.
		Defaults to the corresponding value from the PackageConfig object.
.EXAMPLE
	Main
.LINK
	https://neo42.de/psappdeploytoolkit
#>
param (
	[Parameter(Mandatory=$false)]
	[int]
	[ValidateSet(0,1,2)]
	$Reboot = $global:PackageConfig.reboot,
	[Parameter(Mandatory=$false)]
	[bool]
	$ReinstallModeIsRepair = $global:PackageConfig.ReinstallModeIsRepair
)
	try {
		CustomPreInit
		switch ($DeploymentType) {
			{ ($_ -eq "Install") -or ($_ -eq "Repair") } {
				## START OF INSTALL
				[string]$global:installPhase = 'Pre-InstallationChecks'

				Uninstall-NxtOld 
				if (($true -eq $(Get-NxtRegisterOnly)) -and ($true -eq $global:registerPackage)) {
					## Application is present. Only register the package
					[string]$global:installPhase = 'Package-Registration'
					Register-NxtPackage
					CustomPostInstallAndReinstall
					Complete-NxtPackageInstallation
					Exit-Script -ExitCode $mainExitCode
				}
				Show-NxtInstallationWelcome -IsInstall $true
				CustomPreInstallAndReinstall
				[bool]$isInstalled = $false
				[string]$global:installPhase = 'Check-ReinstallMethod'
				if ($true -eq $(Get-NxtShouldReinstall)) {
					if ($false -eq $ReinstallModeIsRepair) {
						## Reinstall mode is set to default
						CustomPreUninstallReinstall
						Uninstall-NxtApplication
						CustomPostUninstallReinstall
						CustomPreInstallReinstall
						$isInstalled = Install-NxtApplication
						CustomPostInstallReinstall
					}
					else {
						## Reinstall mode is set to repair
						CustomPreInstallReinstall
						$isInstalled = Repair-NxtApplication
						CustomPostInstallReinstall
					}
				}
				else {
					## Default installation
					CustomPreInstall
					$isInstalled = Install-NxtApplication
					CustomPostInstall
				}
				CustomPostInstallAndReinstall
				If ($true -eq $isInstalled) {
					Complete-NxtPackageInstallation
				}
				if (($true -eq $isInstalled) -and ($true -eq $global:registerPackage)) {
					## Register package for uninstall
					[string]$global:installPhase = 'Package-Registration'
					Register-NxtPackage
				}
				
				## END OF INSTALL
			}
			"Uninstall" {
				## START OF UNINSTALL
				
				Show-NxtInstallationWelcome -IsInstall $false
				CustomPreUninstall
				[bool]$isUninstalled = Uninstall-NxtApplication
				CustomPostUninstall
				if ($true -eq $isUninstalled) {
					Complete-NxtPackageUninstallation
					[string]$global:installPhase = 'Package-Unregistration'
					Unregister-NxtPackage
				}

				## END OF UNINSTALL
			}
			"InstallUserPart" {
				## START OF USERPARTINSTALL

				CustomInstallUserPart

				## END OF USERPARTINSTALL
			}
			"UninstallUserPart" {
				## START OF USERPARTUNINSTALL

				CustomUninstallUserPart

				## END OF USERPARTUNINSTALL
			}
			Default {}
		}

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
		Exit-Script -ExitCode $mainExitCode
	}
}

#region neo42 default functions used in Main

function Install-NxtApplication {
		<#
	.SYNOPSIS
		Defines the required steps to install the application based on the target installer type
	.DESCRIPTION
		Is only called in the Main function and should not be modified!
		To customize the script always use the "CustomXXXX" entry points.
	.PARAMETER UninstallKey
		Name of the uninstall registry key of the application (e.g. "This Application_is1" or "{XXXXXXXX-XXXX-XXXXXXXX-XXXXXXXXXXXX}_is1").
		Can be found under "HKLM\SOFTWARE\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\".
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER InstLogFile
		Defines the path to the Logfile that should be used by the installer.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegUninstallKey
		Defines the path to the Uninstall Key in the Registry.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER InstFile
		Defines the path to the Installation File.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER InstPara
		Defines the parameters which will be passed in the Installation Commandline.
		Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Install-NxtApplication
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	param (
	[Parameter(Mandatory=$false)]
	[String]
	$UninstallKey = $global:PackageConfig.UninstallKey,
	[Parameter(Mandatory=$false)]
	[String]
	$InstLogFile = $global:PackageConfig.InstLogFile,
	[Parameter(Mandatory=$false)]
	[string]
	$RegUninstallKey = $global:PackageConfig.RegUninstallKey,
	[Parameter(Mandatory=$false)]
	[string]
	$InstFile = $global:PackageConfig.InstFile,
	[Parameter(Mandatory=$false)]
	[string]
	$InstPara = $global:PackageConfig.InstPara,
	[Parameter(Mandatory=$false)]
	[bool]
	$AppendInstParaToDefaultParameters = $global:PackageConfig.AppendInstParaToDefaultParameters
)
	[string]$global:installPhase = 'Installation'

	[hashtable]$executeNxtParams = @{
		Action	= 'Install'
		Path	= "$InstFile"
	}
	if ($AppendInstParaToDefaultParameters){
		$executeNxtParams["AddParameters"] = "$InstPara"
	}else{
		$executeNxtParams["Parameters"] = "$InstPara"
	}
	## <Perform Installation tasks here>
	switch -Wildcard ($method) {
		MSI {
			Execute-MSI @executeNxtParams -LogName	= "$InstLogFile"
		}
		"Inno*" {
			Execute-NxtInnoSetup @executeNxtParams -UninstallKey "$UninstallKey" -Log "$InstLogFile"
		}
		Nullsoft {
			Execute-NxtNullsoft @executeNxtParams -UninstallKey "$UninstallKey"
		}
		Default {
			Execute-Process -Path "$InstFile" -Parameters "$InstPara"
		}
	}
	$InstallExitCode = $LastExitCode

	Start-Sleep -Seconds 5

	## Test successfull installation
	If (-not (Test-RegistryValue -Key $RegUninstallKey -Value 'UninstallString')) {
		Write-Log -Message "Installation of $appName failed. ErrorLevel: $InstallExitCode" -Severity 3 -Source ${CmdletName}
		# Exit-Script -ExitCode ...Which ExitCode? $InstallExitCode?
	}

	return $true
}

function Complete-NxtPackageInstallation {
	<#
	.SYNOPSIS
		Defines the required steps to finalize the installation of the package
	.DESCRIPTION
		Is only called in the Main function and should not be modified!
		To customize the script always use the "CustomXXXX" entry points.
	.PARAMETER App
		Defines the path to a local persistent cache for installation files.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UserPartOnInstallation
		Defines if the Userpart should be executed for this installation.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PackageFamilyGUID
		Specifies the Registry Key Name used for the Packages Wrapper Uninstall entry
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UserPartRevision
		Specifies the UserPartRevision for this installation
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeys
		Specifies a list of UninstallKeys set by the Installer in this Package.
		Defaults to the corresponding values from the PackageConfig object.
	.EXAMPLE
		Complete-NxtPackageInstallation
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
Param (
		[Parameter(Mandatory=$false)]
		[string]
		$App = $global:PackageConfig.App,
		[Parameter(Mandatory=$false)]
		[bool]
		$UserPartOnInstallation = $global:PackageConfig.UserPartOnInstallation,
		[Parameter(Mandatory=$false)]
		[string]
		$PackageFamilyGUID = $global:PackageConfig.PackageFamilyGUID,
		[Parameter(Mandatory=$false)]
		[string]
		$UserPartRevision = $global:PackageConfig.UserPartRevision,
		[Parameter(Mandatory=$false)]
		[PSCustomObject]
		$UninstallKeys = $global:PackageConfig.UninstallKeysToHide
		
	)
	[string]$global:installPhase = 'Complete-NxtPackageInstallation'

	## <Perform Complete-NxtPackageInstallation tasks here>

	[string]$desktopShortcut = Get-IniValue -FilePath $setupCfgPath -Section 'Options' -Key 'DESKTOPSHORTCUT'
	If ($desktopShortcut -ne '1') {
		Remove-NxtDesktopShortcuts
	}
	Else {
		Copy-NxtDesktopShortcuts
	}

	foreach($uninstallKeyToHide in $UninstallKeys) {
		[string]$wowEntry = ""
		if($false -eq $uninstallKeyToHide.Is64Bit) {
			$wowEntry = "WOW6432Node"
		}
		Set-RegistryKey -Key HKLM\Software$wowEntry\Microsoft\Windows\CurrentVersion\Uninstall\$($uninstallKeyToHide.KeyName) -Name 'SystemComponent' -Type 'Dword' -Value '1'
	}
	
	If ($true -eq $UserPartOnInstallation) {
		## <Userpart-Installation: Copy all needed files to "...\SupportFiles\neo42-Userpart\" and add your per User commands to the CustomInstallUserPart-function below.>
		Set-ActiveSetup -PurgeActiveSetupKey -Key "$PackageFamilyGUID.uninstall"
		Copy-File -Path "$dirSupportFiles\neo42-Userpart\*.*" -Destination "$App\neo42-Userpart\SupportFiles"
		Copy-File -Path "$scriptParentPath\Setup.ico" -Destination "$App\neo42-Userpart\"
		Copy-item -Path "$scriptDirectory\*" -Exclude "Files", "SupportFiles" -Destination "$App\neo42-Userpart\" -Recurse
		Write-NxtSingleXmlNode -XmlFilePath "$App\neo42-Userpart\AppDeployToolkit\AppDeployToolkitConfig.xml" -SingleNodeName "//Toolkit_RequireAdmin" -Value "False"
		Set-ActiveSetup -StubExePath "$global:System\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ex bypass -file ""$App\neo42-Userpart\Deploy-Application.ps1"" installUserpart" -Version $UserPartRevision -Key "$PackageFamilyGUID"
	}
}

function Uninstall-NxtApplication {
		<#
	.SYNOPSIS
		Defines the required steps to uninstall the application based on the target installer type
	.DESCRIPTION
		Is only called in the Main function and should not be modified!
	.PARAMETER UninstallKey
		Specifies the original UninstallKey set by the Installer in this Package.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstLogFile
    	Defines the path to the Logfile that should be used by the uninstaller.
    	Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegUninstallKey
		Defines the path to the Uninstall Key in the Registry.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstFile
		Defines the path to the Installation File.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstPara
		Defines the parameters which will be passed in the UnInstallation Commandline.
		Defaults to the corresponding value from the PackageConfig object.
		To customize the script always use the "CustomXXXX" entry points.
	.EXAMPLE
		Uninstall-NxtApplication
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
Param(
		[Parameter(Mandatory=$false)]
		[string]
		$UninstallKey = $global:PackageConfig.UninstallKey,
		[Parameter(Mandatory=$false)]
		[string]
		$UninstLogFile = $global:PackageConfig.UninstLogFile,
		[Parameter(Mandatory=$false)]
		[string]
		$RegUninstallKey = $global:PackageConfig.RegUninstallKey,
		[Parameter(Mandatory=$false)]
		[string]
		$UninstFile = $global:PackageConfig.UninstFile,
		[Parameter(Mandatory=$false)]
		[string]
		$UninstPara = $global:PackageConfig.UninstPara,
		[Parameter(Mandatory=$false)]
		[bool]
		$AppendUninstParaToDefaultParameters = $global:PackageConfig.AppendUninstParaToDefaultParameters
)
	[string]$global:installPhase = 'Pre-Uninstallation'
	
	## <Perform Pre-Uninstallation tasks here>
	Remove-RegistryKey -Key HKLM\Software$global:Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$($global:PackageConfig.UninstallKey) -Name 'SystemComponent'

	[string]$global:installPhase = 'Uninstallation'
	
	If (Test-RegistryValue -Key $RegUninstallKey -Value 'UninstallString') {
	
		## <Perform Uninstallation tasks here, which should only be executed, if the software is actually installed.>

		[hashtable]$executeNxtParams = @{
			Action	= 'Uninstall'
		}
		if ($AppendUninstParaToDefaultParameters){
			$executeNxtParams["AddParameters"] = "$UninstPara"
		}else{
			$executeNxtParams["Parameters"] = "$UninstPara"
		}
		switch -Wildcard ($method) {
			MSI {
				Execute-MSI @executeNxtParams -Path "$UninstallKey" -LogName "$UninstLogFile"
			}
			"Inno*" {
				Execute-NxtInnoSetup @executeNxtParams -UninstallKey "$UninstallKey" -Log "$UninstLogFile"
			}
			Nullsoft {
				Execute-NxtNullsoft @executeNxtParams -UninstallKey "$UninstallKey"
			}
			"BitRock*" {
				Execute-NxtBitRockInstaller @executeNxtParams -UninstallKey "$UninstallKey"
			}
			none {

			}
			Default {

			}
		}
		$UninstallExitCode = $LastExitCode

		Start-Sleep -Seconds 5

		## Test successfull uninstallation
		If (Test-RegistryValue -Key $RegUninstallKey -Value 'UninstallString') {
			Write-Log -Message "Uninstallation of $appName failed. ErrorLevel: $UninstallExitCode" -Severity 3 -Source ${CmdletName}
			# Exit-Script -ExitCode ...Which ExitCode? $UninstallExitCode?
		}
	}
	## <Perform Uninstallation tasks here, which should always be executed, even if the software is not installed anymore.>
		
	return $true
}

function Complete-NxtPackageUninstallation {
	<#
	.SYNOPSIS
		Defines the required steps to finalize the uninstallation of the package
	.DESCRIPTION
		Is only called in the Main function and should not be modified!
		To customize the script always use the "CustomXXXX" entry points.
	.PARAMETER App
		Defines the path to a local persistent cache for installation files.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PackageFamilyGUID
		Specifies the Registry Key Name used for the Packages Wrapper Uninstall entry
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UserPartOnUninstallation
		Specifies if a Userpart should take place during uninstallation.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UserPartRevision
		Specifies the UserPartRevision for this installation.
		Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Complete-NxtPackageUninstallation
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	Param (
		[Parameter(Mandatory=$false)]
		[string]
		$App = $global:PackageConfig.App,
		[Parameter(Mandatory=$false)]
		[string]
		$PackageFamilyGUID = $global:PackageConfig.PackageFamilyGUID,
		[Parameter(Mandatory=$false)]
		[bool]
		$UserPartOnUninstallation = $global:PackageConfig.UserPartOnUninstallation,
		[Parameter(Mandatory=$false)]
		[string]
		$UserPartRevision = $global:PackageConfig.UserPartRevision
	)
	[string]$global:installPhase = 'Complete-NxtPackageUninstallation'

	## <Perform Complete-NxtPackageUninstallation tasks here>

	Remove-NxtDesktopShortcuts
	
	If ($true -eq $UserPartOnUninstallation) {
		## <Userpart-unInstallation: Copy all needed files to "...\SupportFiles\neo42-Uerpart\" and add your per User commands to the CustomUninstallUserPart-function below.>
		Set-ActiveSetup -PurgeActiveSetupKey -Key "$PackageFamilyGUID"
		Copy-File -Path "$dirSupportFiles\neo42-Userpart\*.*" -Destination "$App\neo42-Userpart\SupportFiles"
		Copy-File -Path "$scriptParentPath\Setup.ico" -Destination "$App\neo42-Userpart\"
		Copy-item -Path "$scriptDirectory\*" -Exclude "Files", "SupportFiles" -Destination "$App\neo42-Userpart\" -Recurse
		Write-NxtSingleXmlNode -XmlFilePath "$App\neo42-Userpart\AppDeployToolkit\AppDeployToolkitConfig.xml" -SingleNodeName "//Toolkit_RequireAdmin" -Value "False"
		Set-ActiveSetup -StubExePath "$global:System\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ex bypass -file ""$App\neo42-Userpart\Deploy-Application.ps1"" uninstallUserpart" -Version $UserPartRevision -Key "$PackageFamilyGUID.uninstall"
	}
}

function Repair-NxtApplication {
	<#
	.SYNOPSIS
		Defines the required steps to repair the application based on the target installer type
	.DESCRIPTION
		Is only called in the Main function and should not be modified!
		To customize the script always use the "CustomXXXX" entry points.
	.EXAMPLE
		Repair-NxtApplication
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>

	[string]$global:installPhase = 'Repair-NxtApplication'

	## <Perform repair tasks here>
}

function Get-NxtShouldReinstall {
	<#
.SYNOPSIS
	Detects if the target application is already installed.
.DESCRIPTION
	Uses the registry Uninstall Key to detect of the application is already present.
.PARAMETER RegUninstallKey
		Defines the path to the Uninstall Key in the Registry.
		Defaults to the corresponding value from the PackageConfig object.
.EXAMPLE
	Get-NxtShouldReinstall
.LINK
	https://neo42.de/psappdeploytoolkit
#>
param(
	[Parameter(Mandatory=$false)]
		[string]
		$RegUninstallKey = $global:PackageConfig.RegUninstallKey
)
	return (Test-RegistryValue -Key $RegUninstallKey -Value 'UninstallString')
}

function Show-NxtInstallationWelcome {
	<#
.SYNOPSIS
	Wrapps around the Show-InstallationWelcome function to insert default Values from the neo42PackageConfigJson
.DESCRIPTION
	Is only called in the Main function and should not be modified!
	To customize the script always use the "CustomXXXX" entry points.
.Parameter IsInstall
	Calls the Show-InstallationWelcome Function differently based on if it is an (un)intallation.
.PARAMETER DeferDays
	Specifies how long a user may defer an installation (will be ignored on uninstallation)
	Defaults to the corresponding value from the PackageConfig object.
.PARAMETER AskKillProcessApps
	Specifies a list of Processnames which should be stopped for the (un)installation to start.
	For Example "WINWORD,EXCEL"
	Defaults to the corresponding value from the PackageConfig object.
.PARAMETER CloseAppsCountdown
	Countdown until the Apps will either be forcibly closed or the Installation will abort
	Defaults to the timeout value from the Setup.cfg.
.PARAMETER ContinueType
	If a dialog window is displayed that shows all processes or applications that must be closed by the user before an installation / uninstallation,
	this window is automatically closed after the timeout and the further behavior can be influenced with the following values:
		ABORT:       After the timeout has expired, the installation will be abort 
		CONTINUE:    After the timeout has expired, the processes and applications will be terminated and the installation continues
	Defaults to the timeout value from the Setup.cfg.
.PARAMETER BlockExecution
	Option to prevent the user from launching processes/applications, specified in -CloseApps, during the installation.
	Defaults to the corresponding value from the PackageConfig object.
.EXAMPLE
	Show-NxtInstallationWelcome
.LINK
	https://neo42.de/psappdeploytoolkit
#>
	param (
		[Parameter(Mandatory=$true)]
		[bool]
		$IsInstall,
		[Parameter(Mandatory=$false)]
		[String]
		$DeferDays = $global:PackageConfig.DeferDays,
		[Parameter(Mandatory=$false)]
		[String]
		$AskKillProcessApps = $($global:PackageConfig.AppKillProcesses -join ","),
		[Parameter(Mandatory=$false)]
		[String]
		$CloseAppsCountdown = $global:SetupCfg.AskKillProcesses.Timeout,
		[Parameter(Mandatory=$false)]
		[ValidateSet("ABORT","CONTINUE")]
		[String]
		$ContinueType = $global:SetupCfg.AskKillProcesses.ContinueType,
		[Parameter(Mandatory=$false)]
		[bool]
		$BlockExecution = $($global:PackageConfig.BlockExecution)
	)
	## override $DeferDays with 0 in Case of Uninstall
	if (!$isInstall){
		$DeferDays = 0
	}

	switch ($ContinueType){
		"ABORT" {
			Show-InstallationWelcome -CloseApps $AskKillProcessApps -CloseAppsCountdown $CloseAppsCountdown -PersistPrompt -BlockExecution:$BlockExecution -AllowDeferCloseApps -DeferDays $DeferDays -CheckDiskSpace
		}
		"CONTINUE" {
			Show-InstallationWelcome -CloseApps $AskKillProcessApps -ForceCloseAppsCountdown $CloseAppsCountdown -PersistPrompt -BlockExecution:$BlockExecution -AllowDeferCloseApps -DeferDays $DeferDays -CheckDiskSpace
		}		
	}
	
}

#endregion

#region Entry point funtions to perform custom tasks during script run

function CustomPreInit {
	[string]$global:installPhase = 'CustomPreInit'

	## Executes at the start of the Main function
}

function CustomPreInstallAndReinstall {
	[string]$global:installPhase = 'CustomPreInstallAndReinstall'

	## Executes before any installation or reinstallation tasks are performed
}

function CustomPreUninstallReinstall {
	[string]$global:installPhase = 'CustomPreUninstallReinstall'

	## Executes before the uninstallation in the reinstall process
}

function CustomPostUninstallReinstall {
	[string]$global:installPhase = 'CustomPostUninstallReinstall'

	## Executes at after the uninstallation in the reinstall process
}

function CustomPreInstallReinstall {
	[string]$global:installPhase = 'CustomPreInstallReinstall'

	## Executes before the installation in the reinstall process
}

function CustomPostInstallReinstall {
	[string]$global:installPhase = 'CustomPostInstallReinstall'

	## Executes after the installation in the reinstall process
}

function CustomPreInstall {
	[string]$global:installPhase = 'CustomPreInstall'

	## Executes before the installation in the install process
}

function CustomPostInstall {
	[string]$global:installPhase = 'CustomPostInstall'

	## Executes after the installation in the install process
}

function CustomPostInstallAndReinstall {
	[string]$global:installPhase = 'CustomPostInstallAndReinstall'

	## Executes after the completed install or repair process
}

function CustomPreUninstall {
	[string]$global:installPhase = 'CustomPreUninstall'

	## Executes before the uninstallation in the uninstall process
}

function CustomPostUninstall {
	[string]$global:installPhase = 'CustomPostUninstall'

	## Executes after the uninstallation in the uninstall process
}

function CustomInstallUserPart {
	[string]$global:installPhase = 'CustomInstallUserPart'

	## Executes if the script is executed started with the value 'InstallUserPart' for parameter 'DeploymentType'
}

function CustomUninstallUserPart {
	[string]$global:installPhase = 'CustomUninstallUserPart'

	## Executes if the script is executed started with the value 'UninstallUserPart' for parameter 'DeploymentType'
}

#endregion

## Execute the main function to start the process
Main