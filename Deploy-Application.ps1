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
	Initialize-NxtEnvironment
	
	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================

	## Variables not from neo42PackageConfig.json
	[string]$setupCfgPath = "$dirSupportFiles\Setup.cfg"
	[string]$timestamp = Get-Date -format "yyyy-MM-dd_HH-mm-ss"

	## Variables: Application
	[string]$appScriptAuthor = $global:PackageConfig.ScriptAuthor
	[string]$appScriptDate = $global:PackageConfig.ScriptDate
	[string]$inventoryID = $global:PackageConfig.InventoryID
	[string]$description = $global:PackageConfig.Description
	[string]$method = $global:PackageConfig.Method
	[string]$testedOn = $global:PackageConfig.TestedOn
	[string]$dependencies = $global:PackageConfig.Dependencies
	[string]$lastChange = $global:PackageConfig.LastChange
	[string]$build = $global:PackageConfig.Build
	
	[string]$appArch = $global:PackageConfig.AppArch
	
	[string]$appName = $global:PackageConfig.AppName
	[string]$appVendor = $global:PackageConfig.AppVendor
	[string]$appVersion = $global:PackageConfig.AppVersion
	[string]$appRevision = $global:PackageConfig.AppRevision
	[string]$appLang = $global:PackageConfig.AppLang
	[string]$appScriptVersion = $global:PackageConfig.AppScriptVersion
	
	[string]$uninstallKeyName = $global:PackageConfig.UninstallKeyName
	[string]$regPackagesKey = $global:PackageConfig.RegPackagesKey
	[string]$uninstallDisplayName = $ExecutionContext.InvokeCommand.ExpandString($global:PackageConfig.UninstallDisplayName)
	[string]$app = $ExecutionContext.InvokeCommand.ExpandString($global:PackageConfig.App)
	[string]$uninstallDisplayIcon = $ExecutionContext.InvokeCommand.ExpandString($global:PackageConfig.UninstallDisplayIcon)

	[bool]$uninstallOld = $global:PackageConfig.UninstallOld
	[int]$reboot = $global:PackageConfig.Reboot
	[int]$deferDays = $global:PackageConfig.DeferDays
	[bool]$reinstallModeIsRepair = $global:PackageConfig.ReinstallModeIsRepair
	[bool]$userPartOnInstallation = $global:PackageConfig.UserPartOnInstallation
	[bool]$userPartOnUninstallation = $global:PackageConfig.UserPartOnUninstallation
	[string]$userPartRevision = $global:PackageConfig.UserPartRevision
	[bool]$softMigration = $global:PackageConfig.SoftMigration
	[bool]$hidePackageUninstallButton = $global:PackageConfig.HidePackageUninstallButton
	[bool]$hidePackageUninstallEntry = $global:PackageConfig.HidePackageUninstallEntry
	
	[bool]$registerPackage = $global:PackageConfig.RegisterPackage
	
	##*===============================================
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = $global:PackageConfig.InstallName
	[string]$installTitle = $global:PackageConfig.InstallTitle

	## Environment
	[string]$displayVersion = $global:PackageConfig.DisplayVersion
	[string]$uninstallKey = $global:PackageConfig.UninstallKey
	[string]$installLocation = $ExecutionContext.InvokeCommand.ExpandString($global:PackageConfig.InstallLocation)
	
	[string]$instLogFile = $ExecutionContext.InvokeCommand.ExpandString($global:PackageConfig.InstLogFile)
	[string]$uninstLogFile = $ExecutionContext.InvokeCommand.ExpandString($global:PackageConfig.UninstLogFile)
	[string]$regUninstallKey = $ExecutionContext.InvokeCommand.ExpandString($global:PackageConfig.RegUninstallKey)
	[string]$detectedDisplayVersion = Get-RegistryKey -Key $regUninstallKey -Value 'DisplayVersion'

	[string]$instPara = $ExecutionContext.InvokeCommand.ExpandString($global:PackageConfig.InstPara)
	[string]$uninstPara = $ExecutionContext.InvokeCommand.ExpandString($global:PackageConfig.UninstPara)

	[string]$askKillProcessApps = $global:PackageConfig.AppKillProcesses -join ","

	return

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
.EXAMPLE
	Main
.LINK
	https://neo42.de/psappdeploytoolkit
#>
	try {
		CustomPreInit
		switch ($DeploymentType) {
			{ ($_ -eq "Install") -or ($_ -eq "Repair") } {
				## START OF INSTALL
				Uninstall-NxtOld 
				if ($true -eq $(Get-NxtRegisterOnly)) {
					## Application is present. Only register the package
					[string]$installPhase = 'Package-Registration'
					Register-NxtPackage
					Exit-Script -ExitCode $mainExitCode
				}
				Show-NxtInstallationWelcome -IsInstall $true
				CustomPreInstallAndReinstall
				[bool]$isInstalled = $false
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
				if (($true -eq $isInstalled) -and ($true -eq $registerPackage)) {
					## Register package for uninstall
					[string]$installPhase = 'Package-Registration'
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
					[string]$installPhase = 'Package-Registration'
					Unregister-NxtPackage
				}

				## END OF UNINSTALL
			}
			"InstallUserPart" {
				## START OF USERPARTINSTALL

				# CustomInstallUserPart

				## END OF USERPARTINSTALL
			}
			"UninstallUserPart" {
				## START OF USERPARTUNINSTALL

				# CustomUninstallUserPart

				## END OF USERPARTUNINSTALL
			}
			Default {}
		}

		## Calculate exit code
		If ($reboot -eq '1') { [int32]$mainExitCode = 3010 }
		If ($reboot -eq '2' -and ($mainExitCode -eq 3010 -or $mainExitCode -eq 1641)) { [int32]$mainExitCode = 0 }
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
.EXAMPLE
	Install-NxtApplication
.LINK
	https://neo42.de/psappdeploytoolkit
#>
	
	##*===============================================
	##* PRE-INSTALLATION
	##*===============================================
	[string]$installPhase = 'Pre-Installation'

	## <Perform Pre-Installation tasks here>
	


	##*===============================================
	##* INSTALLATION
	##*===============================================
	[string]$installPhase = 'Installation'

	## <Perform Post-Installation tasks here>

	Invoke-Expression $InstPara

	##*===============================================
	##* POST-INSTALLATION
	##*===============================================
	[string]$installPhase = 'Post-Installation'

	## <Perform Post-Installation tasks here>

	[string]$desktopShortcut = Get-IniValue -FilePath $setupCfgPath -Section 'Options' -Key 'DESKTOPSHORTCUT'
	If ($desktopShortcut -ne '1') {
		Remove-File -Path "$envCommonDesktop\FreeCommander XE.lnk"
	}
	Else {
		Copy-File -Path "$envCommonStartMenuPrograms\FreeCommander XE\FreeCommander XE.lnk" -Destination "$envCommonDesktop\" 
	}

	Set-RegistryKey -Key HKLM\Software$global:Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKey -Name 'SystemComponent' -Type 'Dword' -Value '1'
	
	If ($true -eq $userPartOnInstallation) {
		##*===============================================
		##* USERPART-INSTALLATION ON INSTALLATION
		##*===============================================
		[string]$installPhase = 'Userpart-Installation'

		## <Userpart-Installation-RegKeys: Set or remove HKCU-Registry Keys for all Users during Installaiton here>
		[scriptblock]$HKCURegistrySettings = {
			Set-RegistryKey -Key 'HKCU\Software\FreeCommander' -Name 'Test1' -Value 5 -Type DWord -SID $UserProfile.SID
			Set-RegistryKey -Key 'HKCU\Software\FreeCommander' -Name 'Test2' -Value 1 -Type Binary -SID $UserProfile.SID
			Set-RegistryKey -Key 'HKCU\Software\FreeCommander' -Name 'Test3' -Value 'InstallationTest' -SID $UserProfile.SID
			Remove-RegistryKey -Key 'HKCU\Software\FreeCommander' -Name 'Test3' -SID $UserProfile.SID
			Remove-RegistryKey -Key 'HKCU\Software\FreeCommander' -Name 'Test4' -SID $UserProfile.SID
		}
		Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $HKCURegistrySettings

		## <Userpart-Installation-Batch: Copy all needed files to "...\SupportFiles\neo42-Uerpart\" and add your per User commands to the neo42-Userpart.cmd.>
		Copy-File -Path "$dirSupportFiles\neo42-Userpart\*.*" -Destination "$app\neo42-Userpart\SupportFiles"
		Copy-item -Path "$scriptDirectory/*" -Exclude "Files", "SupportFiles" -Destination "$app\neo42-Userpart\"
		Set-ActiveSetup -StubExePath "$app\neo42-Userpart\Deploy-Application.exe" -Arguments "/installUserpart" -Version $UserPartRevision -Key "$UninstallKeyName"
	}
	return $true
}

function Uninstall-NxtApplication {
	<#
.SYNOPSIS
	Defines the required steps to uninstall the application based on the target installer type
.DESCRIPTION
	Is only called in the Main function and should not be modified!
	To customize the script always use the "CustomXXXX" entry points.
.EXAMPLE
	Uninstall-NxtApplication
.LINK
	https://neo42.de/psappdeploytoolkit
#>
	##*===============================================
	##* PRE-UNINSTALLATION
	##*===============================================
	[string]$installPhase = 'Pre-Uninstallation'
	
	## <Perform Pre-Uninstallation tasks here>
	Remove-RegistryKey -Key HKLM\Software$global:Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKey -Name 'SystemComponent'
	
	##*===============================================
	##* UNINSTALLATION
	##*===============================================
	[string]$installPhase = 'Uninstallation'
	
	If (Test-RegistryValue -Key $RegUninstallKey -Value 'UninstallString') {
	
		## <Perform Uninstallation tasks here, which should only be executed, if the software is actually installed.>
		Invoke-Expression $UninstPara
	}
	## <Perform Uninstallation tasks here, which should always be executed, even if the software is not installed anymore.>
			
	
	##*===============================================
	##* POST-UNINSTALLATION
	##*===============================================
	[string]$installPhase = 'Post-Uninstallation'
	
	## <Perform Post-Uninstallation tasks here>
			
	If ($true -eq $userPartOnUninstallation) {
		##*===============================================
		##* USERPART-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Userpart-Uninstallation'
	
		## <Userpart-Uninstallation-RegKeys: Set or remove HKCU-Registry Keys for all Users during Uninstallaiton here>
		[scriptblock]$hkcuRegistrySettings = {
			Remove-RegistryKey -Key 'HKCU\Software\FreeCommander' -Name 'Test1' -SID $UserProfile.SID
			Remove-RegistryKey -Key 'HKCU\Software\FreeCommander' -Name 'Test2' -SID $UserProfile.SID
			Remove-RegistryKey -Key 'HKCU\Software\FreeCommander' -Name 'Test3' -SID $UserProfile.SID
			Set-RegistryKey -Key 'HKCU\Software\FreeCommander' -Name 'Test4' -Value 'UninstallationTest' -SID $UserProfile.SID
		}
		Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $hkcuRegistrySettings
	
		Set-ActiveSetup -PurgeActiveSetupKey -Key "$uninstallKeyName"
		Set-RegistryKey -Key "HKLM\Software\Microsoft\Active Setup\Installed Components\$uninstallKeyName.uninstall" -Name '(Default)' -Value "$installName" -ContinueOnError $false
		Set-RegistryKey -Key "HKLM\Software\Microsoft\Active Setup\Installed Components\$uninstallKeyName.uninstall" -Name 'StubPath' -Value "cmd /c ""%AppData%\neoPackages\$uninstallKeyName\neo42-Userpart.cmd"" /uninstall $timestamp" -Type 'String' -ContinueOnError $false
		Set-RegistryKey -Key "HKLM\Software\Microsoft\Active Setup\Installed Components\$uninstallKeyName.uninstall" -Name 'Version' -Value $userPartRevision -ContinueOnError $false
		Set-RegistryKey -Key "HKLM\Software\Microsoft\Active Setup\Installed Components\$uninstallKeyName.uninstall" -Name 'IsInstalled' -Value 1 -Type 'DWord' -ContinueOnError $false
		#Set-ActiveSetup -StubExePath "%AppData%\neoPackages\$UninstallKeyName\neo42-Userpart.cmd" -Arguments "/uninstall $timestamp" -Version $UserPartRevision -Key "<$UninstallKeyName.uninstall"
	}
	return $true
}

function Get-NxtRegisterOnly {
	<#
.SYNOPSIS
	Detects if the target application is already installed
.DESCRIPTION
	Uses registry values to detect the application in target or higher versions
.EXAMPLE
	Get-NxtRegisterOnly
.LINK
	https://neo42.de/psappdeploytoolkit
#>
	If ($true -eq $softMigration) {
		## Perform soft migration 

		[string]$installPhase = 'Soft-Migration'

		If ($detectedDisplayVersion -ge $displayVersion -and -not (Test-RegistryValue -Key HKLM\Software$global:Wow6432Node\neoPackages\$uninstallKeyName -Value 'ProductName') ) {
			Set-RegistryKey -Key HKLM\Software$global:Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$uninstallKey -Name 'SystemComponent' -Type 'Dword' -Value '1'
			Write-Log -Message 'Application was already present. Installation was not executed. Only package files were copied and package was registered. Exit!'
			return $true
		}
	}
	return $false
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

	[string]$installPhase = 'Repair-Installation'

	## <Perform repair tasks here>
}

function Get-NxtShouldReinstall {
	<#
.SYNOPSIS
	Detects if the target application is already installed
.DESCRIPTION
	Uses the registry Uninstall Key to detect of the application is already present
.EXAMPLE
	Get-NxtShouldReinstall
.LINK
	https://neo42.de/psappdeploytoolkit
#>
	return (Test-RegistryValue -Key $regUninstallKey -Value 'UninstallString')
}

function Show-NxtInstallationWelcome {
	<#
.SYNOPSIS
	Defines the required steps to uninstall the application based on the target installer type
.DESCRIPTION
	Is only called in the Main function and should not be modified!
	To customize the script always use the "CustomXXXX" entry points.
.EXAMPLE
	Show-NxtInstallationWelcome
.LINK
	https://neo42.de/psappdeploytoolkit
#>
	param (
		[bool]$IsInstall
	)
	#ifelse install uninstall
	Show-InstallationWelcome -CloseApps $askKillProcessApps -CloseAppsCountdown $closeAppsCountdown -PersistPrompt -BlockExecution -AllowDeferCloseApps -DeferDays $deferDays -CheckDiskSpace	
}

#endregion

#region Entry point funtions to perform custom tasks during script run

function CustomPreInit {
	## Executes at the start of the Main function
}

function CustomPreInstallAndReinstall {
	## Executes before any installation or reinstallation tasks are performed
}

function CustomPreUninstallReinstall {
	## Executes before the uninstallation in the reinstall process
}

function CustomPostUninstallReinstall {
	## Executes at after the uninstallation in the reinstall process
}

function CustomPreInstallReinstall {
	## Executes before the installation in the reinstall process
}

function CustomPostInstallReinstall {
	## Executes after the installation in the reinstall process
}

function CustomPreInstall {
	## Executes before the installation in the install process
}

function CustomPostInstall {
	## Executes after the installation in the install process
}

function CustomPostInstallAndReinstall {
	## Executes after the completed install or repair process
}

function CustomPreUninstall {
	## Executes before the uninstallation in the uninstall process
}

function CustomPostUninstall {
	## Executes after the uninstallation in the uninstall process
}

function CustomInstallUserPart {
	## Executes if the script is executed started with the value 'InstallUserPart' for parameter 'DeploymentType'
}

function CustomUninstallUserPart {
	## Executes if the script is executed started with the value 'UninstallUserPart' for parameter 'DeploymentType'
}

#endregion

## Execute the main function to start the process
Main