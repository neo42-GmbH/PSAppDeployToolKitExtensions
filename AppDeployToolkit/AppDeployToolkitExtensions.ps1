<#
.SYNOPSIS
	This script is a template that allows you to extend the toolkit with your own custom functions.
    # LICENSE #
    PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
    Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
    This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
    You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is automatically dot-sourced by the AppDeployToolkitMain.ps1 script.
.NOTES
    Toolkit Exit Code Ranges:
    60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
    69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
    70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK
	https://neo42.de/psappdeploytoolkit
#>
[CmdletBinding()]
Param (
)

##*===============================================
##* VARIABLE DECLARATION
##*===============================================

# Variables: Script
[string]$appDeployToolkitExtName = 'N42PSAppDeployToolkitExt'
[string]$appDeployExtScriptFriendlyName = 'neo42 App Deploy Toolkit Extensions'
[version]$appDeployExtScriptVersion = [version]'3.8.4'
[string]$appDeployExtScriptDate = '26/01/2021'
[hashtable]$appDeployExtScriptParameters = $PSBoundParameters

##*===============================================
##* FUNCTION LISTINGS
##*===============================================

#region Function Initialize-NxtEnvironment
Function Initialize-NxtEnvironment {
	<#
	.SYNOPSIS
		Initializes all neo42 functions and variables
	.DESCRIPTION
		Should be called on top of at any 'Deploy-Application.ps1' 
	.EXAMPLE
		Initialize-NxtEnvironment
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
	)
		
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		If (-not ([Management.Automation.PSTypeName]'PSADTNXT.Extensions').Type) {
			[string]$extensionCsPath = "$scriptRoot\AppDeployToolkitExtensions.cs"
			if(Test-Path -Path $extensionCsPath) {
				Add-Type -Path $extensionCsPath -IgnoreWarnings -ErrorAction 'Stop'
			}
			else {
				throw "File not found: $extensionCsPath"
			}
		}
		Get-NxtPackageConfig
		Set-NxtPackageArchitecture
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion

#region Function Initialize-NxtEnvironment
Function Get-NxtPackageConfig {
	<#
	.SYNOPSIS
		Initializes all neo42 functions and variables
	.DESCRIPTION
		Should be called on top of any 'Deploy-Application.ps1' 
	.EXAMPLE
		Initialize-NxtEnvironment
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
	)
		
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		$global:PackageConfig = Get-Content "$scriptDirectory\neo42PackageConfig.json" | Out-String | ConvertFrom-Json
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion

#region Function Set-NxtPackageArchitecture
Function Set-NxtPackageArchitecture {
	<#
	.SYNOPSIS
		Sets variables depending on the $appArch value and the system architecture.
	.DESCRIPTION
		Sets variables (e.g. $ProgramFilesDir[x86], $CommonFilesDir[x86], $System, $Wow6432Node) that are depending on the $appArch (x86, x64 or *) value and the system architecture (AMD64 or x86).
	.EXAMPLE
		Set-NxtPackageArchitecture
	.NOTES
		Should be executed during package Initialization only.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Write-Log -Message "Setting package architecture variables..." -Source ${CmdletName}
		Try {
			[string]$currentArch = $global:PackageConfig.AppArch
			If ($currentArch -ne 'x86' -and $currentArch -ne 'x64' -and $currentArch -ne '*') {
				[int32]$mainExitCode = 70001
				[string]$mainErrorMessage = 'ERROR: The value of $appArch must be set to "x86", "x64" or "*". Abort!'
				Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
				Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
				Exit-Script -ExitCode $mainExitCode
			}
			ElseIf ($currentArch -eq 'x64' -and $env:PROCESSOR_ARCHITECTURE -eq 'x86') {
				[int32]$mainExitCode = 70001
				[string]$mainErrorMessage = 'ERROR: This software package can only be installed on 64 bit Windows systems. Abort!'
				Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
				Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
				Exit-Script -ExitCode $mainExitCode
			}
			ElseIf ($currentArch -eq 'x86' -and $env:PROCESSOR_ARCHITECTURE -eq 'AMD64') {
				[string]$global:ProgramFilesDir = ${env:ProgramFiles(x86)}
				[string]$global:ProgramFilesDirx86 = ${env:ProgramFiles(x86)}
				[string]$global:ProgramW6432 = ${env:ProgramFiles}
				[string]$global:CommonFilesDir = ${env:CommonProgramFiles(x86)}
				[string]$global:CommonFilesDirx86 = ${env:CommonProgramFiles(x86)}
				[string]$global:CommonProgramW6432 = ${env:CommonProgramFiles}
				[string]$global:System = "${env:SystemRoot}\SysWOW64"
				[string]$global:Wow6432Node = '\Wow6432Node'
			}
			ElseIf (($currentArch -eq 'x86' -or $currentArch -eq '*') -and $env:PROCESSOR_ARCHITECTURE -eq 'x86') {
				[string]$global:ProgramFilesDir = ${env:ProgramFiles}
				[string]$global:ProgramFilesDirx86 = ${env:ProgramFiles}
				[string]$global:ProgramW6432 = ''
				[string]$global:CommonFilesDir = ${env:CommonProgramFiles}
				[string]$global:CommonFilesDirx86 = ${env:CommonProgramFiles}
				[string]$global:CommonProgramW6432 = ''
				[string]$global:System = "${env:SystemRoot}\System32"
				[string]$global:Wow6432Node = ''
			}
			Else {
				[string]$global:ProgramFilesDir = ${env:ProgramFiles}
				[string]$global:ProgramFilesDirx86 = ${env:ProgramFiles(x86)}
				[string]$global:ProgramW6432 = ${env:ProgramFiles}
				[string]$global:CommonFilesDir = ${env:CommonProgramFiles}
				[string]$global:CommonFilesDirx86 = ${env:CommonProgramFiles(x86)}
				[string]$global:CommonProgramW6432 = ${env:CommonProgramFiles}
				[string]$global:System = "${env:SystemRoot}\System32"
				[string]$global:Wow6432Node = ''
			}

			Write-Log -Message "Package architecture variables successfully set." -Source ${cmdletName}
		}
		Catch {
			Write-Log -Message "Failed to set the package architecture variables. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion

#region Function get-NxtVariablesFromDeploymentSystem
Function get-NxtVariablesFromDeploymentSystem {
	<#
	.SYNOPSIS
		Gets Enviroment Variables set by the deployment system
	.DESCRIPTION
		Should be called at the end of the variable definition section of any 'Deploy-Application.ps1' 
		Variables not set by the deployment system (or set to an unsuitable value) get a default value (e.g. [bool]$global:$registerPackage = $true)
		Variables set by the deployment system overwrite the values from the neo42PackageConfig.json
	.EXAMPLE
		get-NxtVariablesFromDeploymentSystem
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
	)
		
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		If ("false" -eq $env:registerPackage) {[bool]$global:registerPackage = $false} Else {[bool]$global:registerPackage = $true}
		If ("false" -eq $env:uninstallOld) {[bool]$global:uninstallOld = $false}
		If ($null -ne $env:Reboot) {[int]$global:reboot = $env:Reboot}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion

#region Function Uninstall-NxtOld
Function Uninstall-NxtOld {
	<#
	.SYNOPSIS
		Uninstalls old package versions if "UninstallOld": true.
	.DESCRIPTION
		If UninstallOld is set to true, the function checks for old versions of the same package (same $UninstallKeyName) and uninstalls them.
	.EXAMPLE
		Uninstall-NxtOld
	.NOTES
		Should be executed during package Initialization only.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		If ($true -eq $uninstallOld) {
			Write-Log -Message "Checking for old packages..." -Source ${cmdletName}
			Try {
				## Check for Empirum packages under "HKLM:SOFTWARE\WOW6432Node\"
				If (Test-Path -Path "HKLM:SOFTWARE\WOW6432Node\$regPackagesKey\$appVendor") {
					If (Test-Path -Path "HKLM:SOFTWARE\WOW6432Node\$regPackagesKey\$appVendor\$appName") {
						$appEmpirumPackageVersions=Get-ChildItem "HKLM:SOFTWARE\WOW6432Node\$regPackagesKey\$appVendor\$appName"
						If (($appEmpirumPackageVersions).Count -eq 0) {
							Remove-Item -Path "HKLM:SOFTWARE\WOW6432Node\$regPackagesKey\$appVendor\$appName"
							Write-Log -Message "Deleted an empty Empirum application key: HKLM:SOFTWARE\WOW6432Node\$regPackagesKey\$appVendor\$appName" -Source ${cmdletName}
						}
						Else {
							Foreach ($appEmpirumPackageVersion in $appEmpirumPackageVersions) {
								Write-Log -Message "Found an old Empirum package version key: $($appEmpirumPackageVersion.name)" -Source ${cmdletName}
								If (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString') {
									Try {
										cmd /c (Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString')
									}
									Catch {
									}
									If (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString') {
										[int32]$mainExitCode = 70001
										[string]$mainErrorMessage = "Uninstallation of Empirum package failed: $($appEmpirumPackageVersion.name)"
										Write-Log -Message $mainErrorMessage -Source ${cmdletName}
										Exit-Script -ExitCode $mainExitCode
									}
									Else {
										Write-Log -Message "Successfully uninstalled Empirum package: $($appEmpirumPackageVersion.name)" -Source ${cmdletName}
									}
								}
								Else {
									$appEmpirumPackageVersion | Remove-Item
									Write-Log -Message "This key contained no 'UninstallString' and was deleted: $($appEmpirumPackageVersion.name)" -Source ${cmdletName}
								}
							}
							If ((($appEmpirumPackageVersions).Count -eq 0) -and (Test-Path -Path "HKLM:SOFTWARE\WOW6432Node\$regPackagesKey\$appVendor\$appName")) {
								Remove-Item -Path "HKLM:SOFTWARE\WOW6432Node\$regPackagesKey\$appVendor\$appName"
								Write-Log -Message "Deleted the now empty Empirum application key: HKLM:SOFTWARE\WOW6432Node\$regPackagesKey\$appVendor\$appName" -Source ${cmdletName}
							}
						}
					}
					If ((Get-ChildItem "HKLM:SOFTWARE\WOW6432Node\$regPackagesKey\$appVendor").Count -eq 0) {
						Remove-Item -Path "HKLM:SOFTWARE\WOW6432Node\$regPackagesKey\$appVendor"
						Write-Log -Message "Deleted empty Empirum vendor key: HKLM:SOFTWARE\WOW6432Node\$regPackagesKey\$appVendor" -Source ${cmdletName}
					}
				}
				## Check for Empirum packages under "HKLM:SOFTWARE\"
				If (Test-Path -Path "HKLM:SOFTWARE\$regPackagesKey\$appVendor") {
					If (Test-Path -Path "HKLM:SOFTWARE\$regPackagesKey\$appVendor\$appName") {
						$appEmpirumPackageVersions=Get-ChildItem "HKLM:SOFTWARE\$regPackagesKey\$appVendor\$appName"
						If (($appEmpirumPackageVersions).Count -eq 0) {
							Remove-Item -Path "HKLM:SOFTWARE\$regPackagesKey\$appVendor\$appName"
							Write-Log -Message "Deleted an empty Empirum application key: HKLM:SOFTWARE\$regPackagesKey\$appVendor\$appName" -Source ${cmdletName}
						}
						Else {
							Foreach ($appEmpirumPackageVersion in $appEmpirumPackageVersions) {
								Write-Log -Message "Found an old Empirum package version key: $($appEmpirumPackageVersion.name)" -Source ${cmdletName}
								If (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString') {
									Try {
										cmd /c (Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString')
									}
									Catch {
									}
									If (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString') {
										[int32]$mainExitCode = 70001
										[string]$mainErrorMessage = "Uninstallation of Empirum package failed: $($appEmpirumPackageVersion.name)"
										Write-Log -Message $mainErrorMessage -Source ${cmdletName}
										Exit-Script -ExitCode $mainExitCode
									}
									Else {
										Write-Log -Message "Successfully uninstalled Empirum package: $($appEmpirumPackageVersion.name)" -Source ${cmdletName}
									}
								}
								Else {
									$appEmpirumPackageVersion | Remove-Item
									Write-Log -Message "This key contained no 'UninstallString' and was deleted: $($appEmpirumPackageVersion.name)" -Source ${cmdletName}
								}
							}
							If ((($appEmpirumPackageVersions).Count -eq 0) -and (Test-Path -Path "HKLM:SOFTWARE\$regPackagesKey\$appVendor\$appName")) {
								Remove-Item -Path "HKLM:SOFTWARE\$regPackagesKey\$appVendor\$appName"
								Write-Log -Message "Deleted the now empty Empirum application key: HKLM:SOFTWARE\$regPackagesKey\$appVendor\$appName" -Source ${cmdletName}
							}
						}
					}
					If ((Get-ChildItem "HKLM:SOFTWARE\$regPackagesKey\$appVendor").Count -eq 0) {
						Remove-Item -Path "HKLM:SOFTWARE\$regPackagesKey\$appVendor"
						Write-Log -Message "Deleted empty Empirum vendor key: HKLM:SOFTWARE\$regPackagesKey\$appVendor" -Source ${cmdletName}
					}
				}
				## Check for VBS or PSADT packages
				If (Test-RegistryValue -Key HKLM\Software\Wow6432Node\$regPackagesKey\$uninstallKeyName -Value 'UninstallString') {
					[string]$regUninstallKeyName = "HKLM\Software\Wow6432Node\$regPackagesKey\$uninstallKeyName"
				}
				Else {
					[string]$regUninstallKeyName = "HKLM\Software\$regPackagesKey\$uninstallKeyName"
				}
				## Check if the installed package's version is lower than the current one's and if the UninstallString entry exists
				If ((Get-RegistryKey -Key $regUninstallKeyName -Value 'Version') -lt $appVersion -and (Test-RegistryValue -Key $regUninstallKeyName -Value 'UninstallString')) {
					Write-Log -Message "UninstallOld is set to true and an old package version was found: Uninstalling old package..." -Source ${cmdletName}
					cmd /c (Get-RegistryKey -Key $regUninstallKeyName -Value 'UninstallString')
					If (Test-RegistryValue -Key $regUninstallKeyName -Value 'UninstallString') {
						[int32]$mainExitCode = 70001
						[string]$mainErrorMessage = 'ERROR: Uninstallation of old package failed. Abort!'
						Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
						Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
						Exit-Script -ExitCode $mainExitCode
					}
					Else {
						Write-Log -Message "Uninstallation of old package successful." -Source ${cmdletName}
					}
				}
				Else {
					Write-Log -Message "No need to uninstall old packages." -Source ${cmdletName}
				}
			}
			Catch {
				Write-Log -Message "The Uninstall-Old function threw an error. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion

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

#region Function Register-NxtPackage
Function Register-NxtPackage {
	<#
	.SYNOPSIS
		Copies package files and registers the package in the registry.
	.DESCRIPTION
		Copies the package files to "$APP\neoInstall\" and writes the package's registry keys under "HKLM\Software[\Wow6432Node]\$regPackagesKey\$UninstallKeyName" and "HKLM\Software[\Wow6432Node]\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName".
	.EXAMPLE
		Register-NxtPackage
	.NOTES
		Should be executed at the end of each neo42-package installation and when using Soft Migration only.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		[bool]$hidePackageUninstallButton = $global:PackageConfig.HidePackageUninstallButton
		[bool]$hidePackageUninstallEntry = $global:PackageConfig.HidePackageUninstallEntry
	}
	Process {
		Write-Log -Message "Registering package..." -Source ${cmdletName}
		Try {
			Copy-File -Path "$scriptParentPath\AppDeployToolkit" -Destination "$app\neoInstall\" -Recurse
			Copy-File -Path "$scriptParentPath\Deploy-Application.exe" -Destination "$app\neoInstall\"
			Copy-File -Path "$scriptParentPath\Deploy-Application.exe.config" -Destination "$app\neoInstall\"
			Copy-File -Path "$scriptParentPath\Deploy-Application.ps1" -Destination "$app\neoInstall\"

			Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'AppPath' -Value $app
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'Date' -Value (Get-Date -format "yyyy-MM-dd HH:mm:ss")
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'DebugLogFile' -Value $configToolkitLogDir\$logName
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'DeveloperName' -Value $appVendor
			# Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'PackageStatus' -Value '$PackageStatus'
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'ProductName' -Value $appName
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'ReturnCode (%ERRORLEVEL%)' -Value $mainExitCode
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'Revision' -Value $appRevision
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'SrcPath' -Value $scriptParentPath
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'StartupProcessor_Architecture' -Value $envArchitecture
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'StartupProcessOwner' -Value $envUserDomain\$envUserName
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'StartupProcessOwnerSID' -Value $ProcessNTAccountSID
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'UninstallOld' -Type 'Dword' -Value $UninstallOld
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'UninstallString' -Value ('"' + $app + '\neoInstall\Deploy-Application.exe"', 'uninstall')
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'UserPartOnInstallation' -Value $userPartOnInstallation -Type 'DWord'
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'UserPartOnUninstallation' -Value $userPartOnUninstallation -Type 'DWord'
			If ($true -eq $UserPartOnInstallation) {
				Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'UserPartPath' -Value ('"' + $app + '\neo42-Uerpart"')
				Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'UserPartUninstPath' -Value ('"%AppData%\neoPackages\' + $uninstallKeyName + '"')
				Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'UserPartRevision' -Value $userPartRevision
			}
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'Version' -Value $appVersion

			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'DisplayIcon' -Value '$app\neoInstall\AppDeployToolkit\Setup.ico'
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'DisplayName' -Value $uninstallDisplayName
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'DisplayVersion' -Value $appVersion
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'MachineKeyName' -Value ('$regPackagesKey\' + $uninstallKeyName)
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'NoModify' -Type 'Dword' -Value '1'
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'NoRemove' -Type 'Dword' -Value $hidePackageUninstallButton
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'NoRepair' -Type 'Dword' -Value '1'
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'PackageApplicationDir' -Value $app
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'PackageProductName' -Value $appName
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'PackageRevision' -Value $appRevision
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'Publisher' -Value $appVendor
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'SystemComponent' -Type 'Dword' -Value $hidePackageUninstallEntry
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'UninstallString' -Type 'ExpandString' -Value ('"' + $app + '\neoInstall\Deploy-Application.exe"', 'uninstall')
			Write-Log -Message "Package registration successful." -Source ${cmdletName}
		}
		Catch {
			Write-Log -Message "Failed to register package. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion

#region Function Unregister-NxtPackage
Function Unregister-NxtPackage {
	<#
	.SYNOPSIS
		Removes package files and unregisters the package in the registry.
	.DESCRIPTION
		Removes the package files from "$APP\neoInstall\" and deletes the package's registry keys under "HKLM\Software[\Wow6432Node]\$regPackagesKey\$UninstallKeyName" and "HKLM\Software[\Wow6432Node]\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName".
	.EXAMPLE
		Unregister-NxtPackage
	.NOTES
		Should be executed at the end of each neo42-package uninstallation only.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Write-Log -Message "Unregistering package..." -Source ${cmdletName}
		Try {
			Copy-File -Path "$scriptParentPath\CleanUp.cmd" -Destination "$app\"
			Start-Sleep 1
			Execute-Process -Path "$APP\CleanUp.cmd" -NoWait
			Remove-RegistryKey -Key HKLM\Software$global:Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$uninstallKeyName
			Remove-RegistryKey -Key HKLM\Software$global:Wow6432Node\$regPackagesKey\$uninstallKeyName
			Write-Log -Message "Package unregistration successful." -Source ${cmdletName}
		}
		Catch {
			Write-Log -Message "Failed to unregister package. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion

#region Function Stop-NxtProcess
Function Stop-NxtProcess {
	<#
	.SYNOPSIS
		Stops a process by name
	.DESCRIPTION
		Wrapper of the native Stop-Process cmdlet
	.PARAMETER Name
		Name of the process
	.EXAMPLE
		Stop-NxtProcess -Name Notepad
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[string]$Name
	)
		
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Write-Log -Message "Stop process with name '$Name'" -Source ${cmdletName}
		Try {
			Stop-Process -Name $Name -Force
			Write-Log -Message "Startup type set successful." -Source ${cmdletName}
		}
		Catch {
			Write-Log -Message "Failed to stop process. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion

#region Get-NxtComputerManufacturer

<#
.DESCRIPTION
    gets manufacturer of computersystem
.EXAMPLE
    Get-NxtComputerManufacturer
.LINK
    https://neo42.de/psappdeploytoolkit
#>
function Get-NxtComputerManufacturer {
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		[string]$result = [string]::Empty
		try {
			$result = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property Manufacturer).Manufacturer
		}
		catch {
			Write-Log -Message "Failed to get Computermanufacturer. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		return $result
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Get-NxtComputerModel

<#
.DESCRIPTION
    gets model of computersystem
.EXAMPLE
    Get-NxtComputerModel
.LINK
    https://neo42.de/psappdeploytoolkit
#>
function Get-NxtComputerModel {
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		[string]$result = [string]::Empty
		try {
			$result = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property Model).Model
		}
		catch {
			Write-Log -Message "Failed to get Computermodel. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		return $result
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Get-NxtFileVersion

<#
.DESCRIPTION
    Gets version of file.
    The return value is a version object.
.PARAMETER FilePath
    Full path to the file.
.EXAMPLE
    Get-NxtFileVersion "D:\setup.exe"
.LINK
    https://neo42.de/psappdeploytoolkit
#>
function Get-NxtFileVersion([string]$FilePath) {
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		[version]$result = $null
		try {
			$result = (New-Object -TypeName System.IO.FileInfo -ArgumentList $FilePath).VersionInfo.FileVersion
		}
		catch {
			Write-Log -Message "Failed to get version from file '$FilePath'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		return $result
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Get-NxtFolderSize

<#
.DESCRIPTION
    Gets size of folder recursive in bytes
.PARAMETER FolderPath
    Path to the folder.
.EXAMPLE
    Get-NxtFolderSize "D:\setup\"
.LINK
    https://neo42.de/psappdeploytoolkit
#>
function Get-NxtFolderSize([string]$FolderPath) {
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		[long]$result = 0
		try {
			[System.IO.FileInfo[]]$files = [System.Linq.Enumerable]::Select([System.IO.Directory]::EnumerateFiles($FolderPath, "*.*", "AllDirectories"), [Func[string, System.IO.FileInfo]] { param($x) (New-Object -TypeName System.IO.FileInfo -ArgumentList $x) })
			$result = [System.Linq.Enumerable]::Sum($files, [Func[System.IO.FileInfo, long]] { param($x) $x.Length })
		}
		catch {
			Write-Log -Message "Failed to get size from folder '$FolderPath'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		return $result
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Get-NxtDriveType 

function Get-NxtDriveType {
	<#
	.DESCRIPTION
		Gets drivetype.

		Return values:
		Unknown = 0
		NoRootDirectory = 1
		Removeable = 2
		Local = 3
		Network = 4
		Compact = 5
		Ram = 6
	.PARAMETER FolderPath
		Name of the drive
	.OUTPUTS
		PSADTNXT.DriveType
	.EXAMPLE
		Get-NxtDriveType "c:"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$DriveName
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			$disk = Get-WmiObject -Class Win32_logicaldisk -Filter "DeviceID = '$DriveName'"
			Write-Output ([PSADTNXT.DriveType]$disk.DriveType) 
		}
		catch {
			Write-Log -Message "Failed to get drive type for '$DriveName'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
			Write-Output ([PSADTNXT.DriveType]::Unknown)
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Get-NxtDriveFreeSpace

<#
.DESCRIPTION
    Gets free space of drive in bytes.
.PARAMETER FolderPath
    Name of the drive
.EXAMPLE
    Get-NxtDriveFreeSpace "c:"
.LINK
    https://neo42.de/psappdeploytoolkit
#>
function Get-NxtDriveFreeSpace([string]$DriveName) {
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			$disk = Get-WmiObject -Class Win32_logicaldisk -Filter "DeviceID = '$DriveName'"
			return $disk.FreeSpace
		}
		catch {
			Write-Log -Message "Failed to get freespace for '$DriveName'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		return 0
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Get-NxtProcessName

<#
.DESCRIPTION
    Gets name of process.
    Returns:
        The name of process or empty string.
.PARAMETER FolderPath
    Process Id
.EXAMPLE
    Get-NxtProcessName 1004
.LINK
    https://neo42.de/psappdeploytoolkit
#>
function Get-NxtProcessName([int]$ProcessId)
{
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		[string]$result = [string]::Empty
		try {
			$result = (Get-Process -Id $ProcessId).Name
		}
		catch {
			Write-Log -Message "Failed to get the name for process with pid '$ProcessId'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		Write-Output $result
		return
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Get-NxtIsSystemProcess

function Get-NxtIsSystemProcess {
	<#
	.DESCRIPTION
		Gets process is running with System-Account or not.
		Returns:
			$True or $False
	.PARAMETER FolderPath
		Process Id
	.OUTPUTS
		System.Boolean
	.EXAMPLE
		Get-NxtIsSystemProcess 1004
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[int]
		$ProcessId
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			[PSADTNXT.ProcessIdentity]$pi = [PSADTNXT.Extensions]::GetProcessIdentity($ProcessId)
			Write-Output $pi.IsSystem
		}
		catch {
			Write-Log -Message "Failed to get the owner for process with pid '$ProcessId'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
			Write-Output $false
		}
		return
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Get-NxtWindowsVersion

<#
.DESCRIPTION
    Gets the Windows Version (CurrentVersion) from the Registry
.EXAMPLE
    Get-NxtWindowsVersion
.OUTPUTS
	System.String
.LINK
    https://neo42.de/psappdeploytoolkit
#>
function Get-NxtWindowsVersion {
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			Write-Output (Get-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\' -Name CurrentVersion).CurrentVersion
		}
		catch {
			Write-Log -Message "Failed to get WindowsVersion from Registry. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Get-NxtOsLanguage

function Get-NxtOsLanguage {
	<#
.DESCRIPTION
    Gets OsLanguage as LCID Code from Get-Culture 
.EXAMPLE
    Get-NxtOsLanguage
.OUTPUTS
	System.Int
.LINK
    https://neo42.de/psappdeploytoolkit
#>
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			Write-Output (Get-Culture).LCID
		}
		catch {
			Write-Log -Message "Failed to get OsLanguage LCID Code. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Get-NxtUILanguage

function Get-NxtUILanguage {
	<#
.DESCRIPTION
    Gets UiLanguage as LCID Code from Get-UICulture 
.EXAMPLE
    Get-NxtUILanguage
.OUTPUTS
	System.Int
.LINK
    https://neo42.de/psappdeploytoolkit
#>
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			Write-Output (Get-UICulture).LCID
		}
		catch {
			Write-Log -Message "Failed to get UILanguage LCID Code. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Get-NxtProcessorArchiteW6432

function Get-NxtProcessorArchiteW6432 {
	<#
.DESCRIPTION
    Gets the Environment Variable $env:PROCESSOR_ARCHITEW6432 which is only set in a x86_32 process, returns empty string if run under 64-Bit Process
.EXAMPLE
    Get-NxtProcessorArchiteW6432
.OUTPUTS
	System.String
.LINK
    https://neo42.de/psappdeploytoolkit
#>
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			Write-Output $env:PROCESSOR_ARCHITEW6432
		}
		catch {
			Write-Log -Message "Failed to get the PROCESSOR_ARCHITEW6432 variable. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Get-NxtWindowsBits

function Get-NxtWindowsBits {
	<#
.DESCRIPTION
    Translates the  Environment Variable $env:PROCESSOR_ARCHITECTURE from x86 and amd64 to 32 / 64
.EXAMPLE
    Get-NxtWindowsBits
.OUTPUTS
	System.Int
.LINK
    https://neo42.de/psappdeploytoolkit
#>
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			switch ($env:PROCESSOR_ARCHITECTURE) {
				"AMD64" { 
					Write-Output 64
				}
				"x86" {
					Write-Output 32
				}
				Default {
					Write-Error "$($env:PROCESSOR_ARCHITECTURE) could not be translated to CPU bitness 'WindowsBits'"
				}
			}
		}
		catch {
			Write-Log -Message "Failed to translate $($env:PROCESSOR_ARCHITECTURE) variable. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Move-NxtItem


function Move-NxtItem {
	<#
.DESCRIPTION
    Renames or moves a File or Directory to the DestinationPath
.EXAMPLE
    Move-NxtItem -SourcePath C:\Temp\Sources\Installer.exe -DestinationPath C:\Temp\Sources\Installer_bak.exe
.PARAMETER Path
	Source Path of the File or Directory 
.PARAMETER DestinationPath
	Destination Path for the File or Directory
.OUTPUTS
	none
.LINK
    https://neo42.de/psappdeploytoolkit
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[String]
		$Path,
		[Parameter(Mandatory = $true)]
		[String]
		$DestinationPath
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			Move-Item -Path $Path -Destination $DestinationPath
		}
		catch {
			Write-Log -Message "Failed to move $path to $DestinationPath. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Test-NxtProcessExists

<#
.DESCRIPTION
    Tests if a process exists by name or custom WQL query.
.PARAMETER ProcessName
    Name of the process or WQL search string
.PARAMETER IsWql
    Defines if the given ProcessName is a WQL search string
.OUTPUTS
	System.Boolean
.EXAMPLE
    Test-NxtProcessExists "Notepad"
.LINK
    https://neo42.de/psappdeploytoolkit
#>
function Test-NxtProcessExists([string]$ProcessName, [switch]$IsWql = $false)
{
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			[string]$wqlString = ""
			if($IsWql){
				$wqlString = $ProcessName
			}
			else {
				$wqlString = "Name LIKE '$($ProcessName)'"
			}
			$processes = Get-WmiObject -Query "Select * from Win32_Process Where $($wqlString)" | Select-Object -First 1
			if($processes){
				Write-Output $true
			}
			else {
				Write-Output $false
			}
		}
		catch {
			Write-Log -Message "Failed to get processes for '$ProcessName'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Watch-NxtRegistryKey

<#
.DESCRIPTION
    Tests if a registry key exists in a given time
.PARAMETER RegistryKey
    Name of the registry key to watch
.PARAMETER Timeout
    Timeout in seconds the function waits for the key
.OUTPUTS
	System.Boolean
.EXAMPLE
    Watch-NxtRegistryKey -RegistryKey "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
.LINK
    https://neo42.de/psappdeploytoolkit
#>
function Watch-NxtRegistryKey([string]$RegistryKey, [int]$Timeout = 60)
{
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			$waited = 0
			while($waited -lt $Timeout) {
				$key = Get-RegistryKey -Key $RegistryKey -ReturnEmptyKeyIfExists
				if($key){
					Write-Output $true
					return
				}
				$waited += 1
				Start-Sleep -Seconds 1
			}
			Write-Output $false
		}
		catch {
			Write-Log -Message "Failed to wait for registry key '$RegistryKey'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Watch-NxtRegistryKeyIsRemoved

<#
.DESCRIPTION
    Tests if a registry key disappears in a given time
.PARAMETER RegistryKey
    Name of the registry key to watch
.PARAMETER Timeout
    Timeout in seconds the function waits for the key the disappear
.OUTPUTS
	System.Boolean
.EXAMPLE
    Watch-NxtRegistryKeyIsRemoved -RegistryKey "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
.LINK
    https://neo42.de/psappdeploytoolkit
#>
function Watch-NxtRegistryKeyIsRemoved([string]$RegistryKey, [int]$Timeout = 60)
{
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			$waited = 0
			while($waited -lt $Timeout) {
				$key = Get-RegistryKey -Key $RegistryKey -ReturnEmptyKeyIfExists
				if($null -eq $key){
					Write-Output $true
					return
				}
				$waited += 1
				Start-Sleep -Seconds 1
			}
			Write-Output $false
		}
		catch {
			Write-Log -Message "Failed to wait until registry key '$RegistryKey' is removed. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Watch-NxtFile

<#
.DESCRIPTION
    Tests if a file exists in a given time.
	Automatically resolves cmd environment variables.
.PARAMETER FileName
    Name of the file to watch
.PARAMETER Timeout
    Timeout in seconds the function waits for the file to appear
.OUTPUTS
	System.Boolean
.EXAMPLE
    Watch-NxtFile -FileName "C:\Temp\Sources\Installer.exe"
.LINK
    https://neo42.de/psappdeploytoolkit
#>
function Watch-NxtFile([string]$FileName, [int]$Timeout = 60)
{
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			$waited = 0
			while($waited -lt $Timeout) {
				$result = Test-Path -Path "$([System.Environment]::ExpandEnvironmentVariables($FileName))"
				if($result){
					Write-Output $true
					return
				}
				$waited += 1
				Start-Sleep -Seconds 1
			}
			Write-Output $false
		}
		catch {
			Write-Log -Message "Failed to wait until file '$FileName' appears. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Watch-NxtFileIsRemoved

<#
.DESCRIPTION
    Tests if a file disappears in a given time.
	Automatically resolves cmd environment variables.
.PARAMETER FileName
    Name of the file to watch
.PARAMETER Timeout
    Timeout in seconds the function waits for the file the disappear
.OUTPUTS
	System.Boolean
.EXAMPLE
    Watch-NxtFileIsRemoved -FileName "C:\Temp\Sources\Installer.exe"
.LINK
    https://neo42.de/psappdeploytoolkit
#>
function Watch-NxtFileIsRemoved([string]$FileName, [int]$Timeout = 60)
{
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			$waited = 0
			while($waited -lt $Timeout) {
				$result = Test-Path -Path "$([System.Environment]::ExpandEnvironmentVariables($FileName))"
				if($false -eq $result){
					Write-Output $true
					return
				}
				$waited += 1
				Start-Sleep -Seconds 1
			}
			Write-Output $false
		}
		catch {
			Write-Log -Message "Failed to wait until file '$FileName' is removed. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Watch-NxtProcess

<#
.DESCRIPTION
    Tests if a process exists by name or custom WQL query in a given time.
.PARAMETER ProcessName
    Name of the process or WQL search string
.PARAMETER Timeout
    Timeout in seconds the function waits for the process to start
.PARAMETER IsWql
    Defines if the given ProcessName is a WQL search string
.OUTPUTS
	System.Boolean
.EXAMPLE
    Watch-NxtProcess -ProcessName "Notepad.exe"
.LINK
    https://neo42.de/psappdeploytoolkit
#>
function Watch-NxtProcess([string]$ProcessName, [int]$Timeout = 60, [switch]$IsWql = $false)
{
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			$waited = 0
			while($waited -lt $Timeout) {
				if($IsWql){
					$result = Test-NxtProcessExists -ProcessName $ProcessName -IsWql
				}
				else{
					$result = Test-NxtProcessExists -ProcessName $ProcessName
				}
				
				if($result){
					Write-Output $true
					return
				}
				$waited += 1
				Start-Sleep -Seconds 1
			}
			Write-Output $false
		}
		catch {
			Write-Log -Message "Failed to wait until process '$ProcessName' is started. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Watch-NxtProcessIsStopped

<#
.DESCRIPTION
    Tests if a process stops by name or custom WQL query in a given time.
.PARAMETER ProcessName
    Name of the process or WQL search string
.PARAMETER Timeout
    Timeout in seconds the function waits for the process the stop
.PARAMETER IsWql
    Defines if the given ProcessName is a WQL search string
.OUTPUTS
	System.Boolean
.EXAMPLE
    Watch-NxtProcessIsStopped -ProcessName "Notepad.exe"
.LINK
    https://neo42.de/psappdeploytoolkit
#>
function Watch-NxtProcessIsStopped([string]$ProcessName, [int]$Timeout = 60, [switch]$IsWql = $false)
{
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			$waited = 0
			while($waited -lt $Timeout) {
				if($IsWql){
					$result = Test-NxtProcessExists -ProcessName $ProcessName -IsWql
				}
				else{
					$result = Test-NxtProcessExists -ProcessName $ProcessName
				}
				
				if($false -eq $result){
					Write-Output $true
					return
				}
				$waited += 1
				Start-Sleep -Seconds 1
			}
			Write-Output $false
		}
		catch {
			Write-Log -Message "Failed to wait until process '$ProcessName' is stopped. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Get-NxtServiceState

<#
.DESCRIPTION
    Gets the state of the given service name.
	Returns $null if service was not found.
.PARAMETER ServiceName
    Name of the service
.OUTPUTS
	System.String
.EXAMPLE
    Get-NxtServiceState "BITS"
.LINK
    https://neo42.de/psappdeploytoolkit
#>
function Get-NxtServiceState([string]$ServiceName)
{
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			$service = Get-WmiObject -Query "Select State from Win32_Service Where Name = '$($ServiceName)'" | Select-Object -First 1
			if($service){
				Write-Output $service.State
			}
			else {
				Write-Output $null
				return
			}
		}
		catch {
			Write-Log -Message "Failed to get state for service '$ServiceName'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Get-NxtNameBySid

<#
.DESCRIPTION
    Gets the netbios user name for a SID.
	Returns $null if SID was not found.
.PARAMETER Sid
    SID to search
.OUTPUTS
	System.String
.EXAMPLE
    Get-NxtNameBySid -Sid "S-1-5-21-3072877179-2344900292-1557472252-500"
.LINK
    https://neo42.de/psappdeploytoolkit
#>
function Get-NxtNameBySid([string]$Sid)
{
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			[System.Management.ManagementObject]$wmiAccount = ([wmi]"win32_SID.SID='$Sid'")
			[string]$result = "$($wmiAccount.ReferencedDomainName)\$($wmiAccount.AccountName)"
			if($result -eq "\"){
				Write-Output $null
				return
			}
			else {
				Write-Output $result
			}
		}
		catch {
			Write-Log -Message "Failed to get user name for SID '$Sid'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Compare-NxtVersion

function Compare-NxtVersion([string]$InstalledPackageVersion, [string]$NewPackageVersion)
{
	<#
	.DESCRIPTION
		Compares two versions.

	    Return values:
			Equal = 1
   			Update = 2
   			Downgrade = 3
	.PARAMETER InstalledPackageVersion
		Version of the installed package.
	.PARAMETER NewPackageVersion
		Version of the new package.
	.OUTPUTS
		PSADTNXT.VersionCompareResult
	.EXAMPLE
		Compare-NxtVersion "1.7" "1.7.2"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			$parseVersion = { param($version) 	
				[int[]]$result = 0,0,0,0
				$versionParts = [System.Linq.Enumerable]::ToArray([System.Linq.Enumerable]::Select($Version.Split('.'), [Func[string,PSADTNXT.VersionKeyValuePair]]{ param($x) New-Object PSADTNXT.VersionKeyValuePair -ArgumentList $x,([System.Linq.Enumerable]::ToArray([System.Linq.Enumerable]::Select($x.ToCharArray(), [System.Func[char,PSADTNXT.VersionPartInfo]]{ param($x) New-Object -TypeName "PSADTNXT.VersionPartInfo" -ArgumentList $x }))) }))
				for ($i=0; $i -lt $versionParts.count; $i++){
					[int]$versionPartValue = 0
					$pair = [System.Linq.Enumerable]::ElementAt($versionParts, $i)
					if ([System.Linq.Enumerable]::All($pair.Value, [System.Func[PSADTNXT.VersionPartInfo,bool]]{ param($x) [System.Char]::IsDigit($x.Value) })) {
						$versionPartValue = [int]::Parse($pair.Key)
					}
					else {
						$value = [System.Linq.Enumerable]::FirstOrDefault($pair.Value)
						if ($value -ne $null -and [System.Char]::IsLetter($value.Value)) {
							#Importent for compare (An upper 'A'==65 char must have the value 10) 
							$versionPartValue = $value.AsciiValue - 55
						}
					}
					$result[$i] = $versionPartValue
				}
				Write-Output (New-Object System.Version -ArgumentList $result[0],$result[1],$result[2],$result[3])
				return }.GetNewClosure()

			[System.Version]$instVersion = &$parseVersion -Version $InstalledPackageVersion
			[System.Version]$newVersion = &$parseVersion -Version $NewPackageVersion
			if ($instVersion -eq $newVersion)
			{
				Write-Output ([PSADTNXT.VersionCompareResult]::Equal)
			}
			elseif ($newVersion -gt $instVersion)
			{
				Write-Output ([PSADTNXT.VersionCompareResult]::Update)
			}
			else
			{
				Write-Output ([PSADTNXT.VersionCompareResult]::Downgrade)
			}
		}
		catch {
			Write-Log -Message "Failed to get the owner for process with pid '$ProcessId'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		return
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Function Get-NxtFileEncoding
function Get-NxtFileEncoding {
	<#
  	.SYNOPSIS
		Returns the estimated Encoding based on Bom Detection, Defaults to ASCII
  	.DESCRIPTION
		Returns the estimated Encoding based on Bom Detection, Defaults to ASCII,
		Used to get the default encoding for Add-NxtContent
  	.PARAMETER Path
		The Path to the File
	.PARAMETER DefaultEncoding
	  	Encoding to be returned in case the encoding could not be detected
  	.OUTPUTS
		System.String
  	.EXAMPLE
		Get-NxtFileEncoding -Path C:\Temp\testfile.txt
  	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[String]
		$Path,
		[Parameter()]
		[ValidateSet("Ascii", "BigEndianUTF32", "Default", "String", "Default", "Unknown", "UTF7", "BigEndianUnicode", "Byte", "Oem", "Unicode", "UTF32", "UTF8")]
		[String]
		$DefaultEncoding
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			$intEncoding = [PSADTNXT.Extensions]::GetEncoding($Path)
			if ([System.String]::IsNullOrEmpty($intEncoding)) {
				$intEncoding = $DefaultEncoding
			}
			Write-Output $intEncoding
			return
		}
		catch {
			Write-Log -Message "Failed to run the encoding detection `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
  
#region Add-NxtContent
  
function Add-NxtContent {
	<#
	.DESCRIPTION
		Appends Files
  .PARAMETER Path
	  Path to the File to be appended
  	.PARAMETER Value
		String to be appended to the File
  .PARAMETER Encoding
	  Encoding to be used, defaults to the value obtained from Get-NxtFileEncoding
  .PARAMETER DefaultEncoding
	  Encoding to be used in case the encoding could not be detected
  .EXAMPLE
	  Add-NxtContent -Path C:\Temp\testfile.txt -Value "Text to be appended to a file"
  .LINK
	  https://neo42.de/psappdeploytoolkit
  #>
	[CmdletBinding()]
	param(
		[Parameter()]
		[String]
		$Path,
		[Parameter()]
		[String]
		$Value,
		[Parameter()]
		[ValidateSet("Ascii", "BigEndianUTF32", "Default", "String", "Default", "Unknown", "UTF7", "BigEndianUnicode", "Byte", "Oem", "Unicode", "UTF32", "UTF8")]
		[String]
		$Encoding,
		[Parameter()]
		[ValidateSet("Ascii", "BigEndianUTF32", "Default", "String", "Default", "Unknown", "UTF7", "BigEndianUnicode", "Byte", "Oem", "Unicode", "UTF32", "UTF8")]
		[String]
		$DefaultEncoding
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		[String]$intEncoding = $Encoding
		if (!(Test-Path $Path) -and ([String]::IsNullOrEmpty($intEncoding))) {
			[String]$intEncoding = "UTF8"
		}
		elseif ((Test-Path $Path) -and ([String]::IsNullOrEmpty($intEncoding))) {
			try {
				[hashtable]$getFileEncodingParams = @{
					Path = $Path
				}
				if (![string]::IsNullOrEmpty($DefaultEncoding)) {
					$getFileEncodingParams['DefaultEncoding'] = $DefaultEncoding
				}
				$intEncoding = (Get-NxtFileEncoding @getFileEncodingParams)
				if($intEncoding -eq "UTF8"){
					[bool]$noBOMDetected = $true
				}ElseIf($intEncoding -eq "UTF8withBom"){
					[bool]$noBOMDetected = $false
					$intEncoding = "UTF8"
				}
			}
			catch {
				$intEncoding = "UTF8"
			}
		}
		try {
			[hashtable]$contentParams = @{
				Path  = $Path
				Value = $Value
			}
			if (![string]::IsNullOrEmpty($intEncoding)) {
				$contentParams['Encoding'] = $intEncoding 
			}
			if($noBOMDetected -and ($intEncoding -eq "UTF8")){
				[System.IO.File]::AppendAllLines($Path, $Content)
			}else{
				Add-Content @contentParams
			}
			
		}
		catch {
			Write-Log -Message "Failed to Add content to the file $Path'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		return
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
  
#endregion

#region Update-NxtTextInFile
  
function Update-NxtTextInFile {
	<#
  	.DESCRIPTION
	  Replaces the text in a file by searchstring
  	.PARAMETER Path
	  Path to the File to be updated
  	.PARAMETER SearchString
	  String to be updated in the File
  	.PARAMETER ReplaceString
	  The String to be inserted to the found occurences
  	.PARAMETER Count
	  Number of occurences to be replaced
  	.PARAMETER Encoding
	  Encoding to be used, defaults to the value obtained from Get-NxtFileEncoding
	.PARAMETER DefaultEncoding
	  Encoding to be used in case the encoding could not be detected
  	.EXAMPLE
	  Update-NxtTextInFile -Path C:\Temp\testfile.txt -SearchString "Hello" 
  	.LINK
	  https://neo42.de/psappdeploytoolkit
  #>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[String]
		$Path,
		[Parameter(Mandatory = $true)]
		[String]
		$SearchString,
		[Parameter(Mandatory = $true)]
		[String]
		$ReplaceString,
		[Parameter()]
		[Int]
		$Count = [int]::MaxValue,
		[Parameter()]
		[ValidateSet("Ascii", "BigEndianUTF32", "Default", "String", "Default", "Unknown", "UTF7", "BigEndianUnicode", "Byte", "Oem", "Unicode", "UTF32", "UTF8")]
		[String]
		$Encoding,
		[Parameter()]
		[ValidateSet("Ascii", "BigEndianUTF32", "Default", "String", "Default", "Unknown", "UTF7", "BigEndianUnicode", "Byte", "Oem", "Unicode", "UTF32", "UTF8")]
		[String]
		$DefaultEncoding,
		[Parameter()]
		[Bool]
		$AddBOMIfUTF8 = $true
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		[String]$intEncoding = $Encoding
		if (!(Test-Path $Path) -and ([String]::IsNullOrEmpty($intEncoding))) {
			$intEncoding = "UTF8"
		}
		elseif ((Test-Path $Path) -and ([String]::IsNullOrEmpty($intEncoding))) {
			try {
				$getFileEncodingParams = @{
					Path = $Path
				}
				if (![string]::IsNullOrEmpty($DefaultEncoding)) {
					$getFileEncodingParams['DefaultEncoding'] = $DefaultEncoding
				}
				$intEncoding = (Get-NxtFileEncoding @GetFileEncodingParams)
				if($intEncoding -eq "UTF8"){
					[bool]$noBOMDetected = $true
				}ElseIf($intEncoding -eq "UTF8withBom"){
					[bool]$noBOMDetected = $false
					$intEncoding = "UTF8"
				}
			}
			catch {
				$intEncoding = "UTF8"
			}
		}
		try {
			[hashtable]$contentParams = @{
				Path = $Path
			}
			if (![string]::IsNullOrEmpty($intEncoding)) {
				$contentParams['Encoding'] = $intEncoding
			}
			$Content = Get-Content @contentParams -Raw
			[regex]$pattern = $SearchString
			[Array]$regexMatches = $pattern.Matches($Content) | Select-Object -First $Count
			if ($regexMatches.count -eq 0){
				Write-Log -Message "Did not find anything to replace in file '$Path'."
				return
			}
			[ARRAY]::Reverse($regexMatches)
			foreach ($match in $regexMatches) {
				$Content = $Content.Remove($match.index, $match.Length).Insert($match.index, $ReplaceString)
			}
			if($noBOMDetected -and ($intEncoding -eq "UTF8")){
				[System.IO.File]::WriteAllLines($Path, $Content)
			}else{
				$Content | Set-Content @contentParams -NoNewline
			}
		}
		catch {
			Write-Log -Message "Failed to Add content to the file $Path'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		return
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
  
#endregion

#region Get-NxtSidByName

function Get-NxtSidByName {
	<#
	.DESCRIPTION
		Gets the SID for a given user name.
		Returns $null if user is not found.
	.PARAMETER UserName
		Name of the user to search.
	.EXAMPLE
		Get-NxtSidByName -UserName "Workgroup\Administrator"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$UserName
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
            [string]$sid = (Get-WmiObject -Query "Select SID from Win32_UserAccount Where Caption LIKE '$($UserName.Replace("\","\\").Replace("\\\\","\\"))'").Sid
			if([string]::IsNullOrEmpty($sid)) {
				Write-Output $null
			}
			else {
				Write-Output $sid
			}
		}
		catch {
			Write-Log -Message "Failed to get the owner for process with pid '$ProcessId'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
        return
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Get-NxtProcessEnvironmentVariable

function Get-NxtProcessEnvironmentVariable([string]$Key)  {
	<#
	.DESCRIPTION
		Gets the value of the process enviroment variable.
	.PARAMETER Key
		Key of the variable
	.OUTPUTS
		string
	.EXAMPLE
		Get-NxtProcessEnvironmentVariable "Test"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
        [string]$result = $null
		try {
            $result = [System.Environment]::GetEnvironmentVariable($Key, [System.EnvironmentVariableTarget]::Process)
		}
		catch {
			Write-Log -Message "Failed to get the process enviroment variable with key '$Key'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
        Write-Output $result
        return
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Set-NxtProcessEnvironmentVariable

function Set-NxtProcessEnvironmentVariable([string]$Key, [string]$Value)  {
	<#
	.DESCRIPTION
		Sets a process enviroment variable.
	.PARAMETER Key
		Key of the variable
	.PARAMETER Key
		Value of the variable
	.EXAMPLE
		Set-NxtProcessEnvironmentVariable "Test" "Hello world"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
            [System.Environment]::SetEnvironmentVariable($Key, $Value, [System.EnvironmentVariableTarget]::Process)
		}
		catch {
			Write-Log -Message "Failed to set the process enviroment variable with key '$Key' and value '{$Value}'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Remove-NxtProcessEnvironmentVariable

function Remove-NxtProcessEnvironmentVariable([string]$Key)  {
	<#
	.DESCRIPTION
		Deletes a process enviroment variable.
	.PARAMETER Key
		Key of the variable
	.EXAMPLE
		Remove-NxtProcessEnvironmentVariable "Test"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
            [System.Environment]::SetEnvironmentVariable($Key, $null, [System.EnvironmentVariableTarget]::Process)
		}
		catch {
			Write-Log -Message "Failed to remove the process enviroment variable with key '$Key'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Get-NxtSystemEnvironmentVariable

function Get-NxtSystemEnvironmentVariable([string]$Key)  {
	<#
	.DESCRIPTION
		Gets the value of the system enviroment variable.
	.PARAMETER Key
		Key of the variable
	.OUTPUTS
		string
	.EXAMPLE
		Get-NxtSystemEnvironmentVariable "windir"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
        [string]$result = $null
		try {
            $result = [System.Environment]::GetEnvironmentVariable($Key, [System.EnvironmentVariableTarget]::Machine)
		}
		catch {
			Write-Log -Message "Failed to get the system enviroment variable with key '$Key'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
        Write-Output $result
        return
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Set-NxtSystemEnvironmentVariable

function Set-NxtSystemEnvironmentVariable([string]$Key, [string]$Value)  {
	<#
	.DESCRIPTION
		Sets a system enviroment variable.
	.PARAMETER Key
		Key of the variable
	.PARAMETER Key
		Value of the variable
	.EXAMPLE
		Set-NxtSystemEnvironmentVariable "Test" "Hello world"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
            [System.Environment]::SetEnvironmentVariable($Key, $Value, [System.EnvironmentVariableTarget]::Machine)
		}
		catch {
			Write-Log -Message "Failed to set the system enviroment variable with key '$Key' and value '{$Value}'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Remove-NxtSystemEnvironmentVariable

function Remove-NxtSystemEnvironmentVariable([string]$Key)  {
	<#
	.DESCRIPTION
		Deletes a system enviroment variable.
	.PARAMETER Key
		Key of the variable
	.EXAMPLE
		Remove-NxtSystemEnvironmentVariable "Test"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
            [System.Environment]::SetEnvironmentVariable($Key, $null, [System.EnvironmentVariableTarget]::Machine)
		}
		catch {
			Write-Log -Message "Failed to remove the system enviroment variable with key '$Key'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Test-NxtLocalUserExists
function Test-NxtLocalUserExists {
	<#
	.DESCRIPTION
		Checks if a local user exists by name
	.EXAMPLE
		Test-NxtLocalUserExists -UserName "Administrator"
	.PARAMETER UserName
		Name of the user
	.OUTPUTS
		System.Boolean
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
		[CmdletBinding()]
		param (
			[Parameter(Mandatory=$true)]
			[ValidateNotNullorEmpty()]
			[string]
			$UserName
		)
		Begin {
			## Get the name of this function and write header
			[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		}
		Process {
			try {
				[bool]$userExists = ([ADSI]::Exists("WinNT://$($env:COMPUTERNAME)/$UserName,user"))
				Write-Output $userExists
			}
			catch {
				## Skip log output since [ADSI]::Exists throws if user is not found
				#Write-Log -Message "Failed to search for user $UserName. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
				Write-Output $false
			}
		}
		End {
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
		}
}
#endregion

#region Add-NxtLocalUser
function Add-NxtLocalUser {
	<#
	.DESCRIPTION
		Creates a local user with the given parameter.
		If the user already exists only FullName, Description, SetPwdExpired and SetPwdNeverExpires are processed.
	.EXAMPLE
		Add-NxtLocalUser -UserName "ServiceUser" -Password "123!abc" -Description "User to run service" -SetPwdNeverExpires
	.PARAMETER UserName
		Name of the user
	.PARAMETER Password
		Password for the new user.
	.PARAMETER FullName
		Full name of the user
	.PARAMETER Description
		Description for the new user
	.PARAMETER SetPwdExpired
		If set the user has to change the password at first logon.
	.PARAMETER SetPwdNeverExpires
		If set the password is set to not expire.
	.OUTPUTS
		System.Boolean
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
		[CmdletBinding(DefaultParameterSetName = 'Default')]
		param (
			[Parameter(ParameterSetName='Default', Mandatory=$true)]
			[Parameter(ParameterSetName='SetPwdNeverExpires', Mandatory=$true)]
			[ValidateNotNullorEmpty()]
			[string]
			$UserName,
			[Parameter(ParameterSetName='Default', Mandatory=$true)]
			[Parameter(ParameterSetName='SetPwdNeverExpires', Mandatory=$true)]
			[ValidateNotNullorEmpty()]
			[string]
			$Password,
			[Parameter(Mandatory=$false)]
			[ValidateNotNullorEmpty()]
			[string]
			$FullName,
			[Parameter(Mandatory=$false)]
			[ValidateNotNullorEmpty()]
			[string]
			$Description,
            [Parameter(ParameterSetName='Default', Mandatory=$false)]
			[ValidateNotNullorEmpty()]
			[switch]
			$SetPwdExpired,
            [Parameter(ParameterSetName='SetPwdNeverExpires', Mandatory=$false)]
			[ValidateNotNullorEmpty()]
			[switch]
			$SetPwdNeverExpires
		)
		Begin {
			## Get the name of this function and write header
			[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		}
		Process {
			try {
				[System.DirectoryServices.DirectoryEntry]$adsiObj = [ADSI]"WinNT://$($env:COMPUTERNAME)"
				[bool]$userExists = Test-NxtLocalUserExists -UserName $UserName
				if($false -eq $userExists){
					[System.DirectoryServices.DirectoryEntry]$objUser = $adsiObj.Create("User", $UserName)
					$objUser.setpassword($Password)
					$objUser.SetInfo()
				}
				else {
					[System.DirectoryServices.DirectoryEntry]$objUser = [ADSI]"WinNT://$($env:COMPUTERNAME)/$UserName,user"
				}
				if(-NOT [string]::IsNullOrEmpty($FullName)){
					$objUser.Put("FullName",$FullName)
					$objUser.SetInfo()
				}
				if(-NOT [string]::IsNullOrEmpty($Description)){
					$objUser.Put("Description",$Description)
					$objUser.SetInfo()
				}
				if($SetPwdExpired){
					## Reset to normal account flag ADS_UF_NORMAL_ACCOUNT
					$objUser.UserFlags = 512
					$objUser.SetInfo()
					## Set password expired
					$objUser.Put("PasswordExpired",1)
					$objUser.SetInfo()
				}
				if($SetPwdNeverExpires){
					## Set flag ADS_UF_DONT_EXPIRE_PASSWD 
					$objUser.UserFlags = 65536
					$objUser.SetInfo()
				}
				return $true
			}
			catch {
				Write-Log -Message "Failed to create user $UserName. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
				Write-Output $false
			}
			
		}
		End {
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
		}
}
#endregion

#region Remove-NxtLocalUser
function Remove-NxtLocalUser {
	<#
	.DESCRIPTION
		Deletes a local group with the given name.
	.EXAMPLE
		Remove-NxtLocalUser -UserName "Test"
	.PARAMETER UserName
		Name of the user
	.OUTPUTS
		System.Boolean
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
		[CmdletBinding()]
		param (
			[Parameter(Mandatory=$true)]
			[ValidateNotNullorEmpty()]
			[string]
			$UserName
		)
		Begin {
			## Get the name of this function and write header
			[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		}
		Process {
			try {
				
				[bool]$userExists = Test-NxtLocalUserExists -UserName $UserName
				if($userExists){
					[System.DirectoryServices.DirectoryEntry]$adsiObj = [ADSI]"WinNT://$($env:COMPUTERNAME)"
					$adsiObj.Delete("User", $UserName)
					Write-Output $true
					return
				}
				Write-Output $false
			}
			catch {
				Write-Log -Message "Failed to delete user $UserName. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
				Write-Output $false
			}
			
		}
		End {
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
		}
}
#endregion

#region Test-NxtLocalGroupExists
function Test-NxtLocalGroupExists {
	<#
	.DESCRIPTION
		Checks if a local group exists by name
	.EXAMPLE
		Test-NxtLocalGroupExists -GroupName "Administrators"
	.PARAMETER GroupName
		Name of the group
	.OUTPUTS
		System.Boolean
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
		[CmdletBinding()]
		param (
			[Parameter(Mandatory=$true)]
			[ValidateNotNullorEmpty()]
			[string]
			$GroupName
		)
		Begin {
			## Get the name of this function and write header
			[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		}
		Process {
			try {
				[bool]$groupExists = ([ADSI]::Exists("WinNT://$($env:COMPUTERNAME)/$GroupName,group"))
				Write-Output $groupExists
			}
			catch {
				Write-Log -Message "Failed to search for group $GroupName. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
				Write-Output $false
			}
		}
		End {
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
		}
}
#endregion

#region Add-NxtLocalGroup
function Add-NxtLocalGroup {
	<#
	.DESCRIPTION
		Creates a local group with the given parameter.
		If group already exists only the description parameter is processed.
	.EXAMPLE
		Add-NxtLocalGroup -GroupName "TestGroup"
	.PARAMETER GroupName
		Name of the group
	.PARAMETER Description
		Description for the new group
	.OUTPUTS
		System.Boolean
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
		[CmdletBinding()]
		param (
			[Parameter(Mandatory=$true)]
			[ValidateNotNullorEmpty()]
			[string]
			$GroupName,
			[Parameter(Mandatory=$false)]
			[ValidateNotNullorEmpty()]
			[string]
			$Description
		)
		Begin {
			## Get the name of this function and write header
			[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		}
		Process {
			try {
				[System.DirectoryServices.DirectoryEntry]$adsiObj = [ADSI]"WinNT://$($env:COMPUTERNAME)"
				[bool]$groupExists = Test-NxtLocalGroupExists -GroupName $GroupName
				if($false -eq $groupExists){
					[System.DirectoryServices.DirectoryEntry]$objGroup = $adsiObj.Create("Group", $GroupName)
					$objGroup.SetInfo()
				}
				else {
					[System.DirectoryServices.DirectoryEntry]$objGroup = [ADSI]"WinNT://$($env:COMPUTERNAME)/$GroupName,group"
				}
				if(-NOT [string]::IsNullOrEmpty($Description)){
					$objGroup.Put("Description",$Description)
					$objGroup.SetInfo()
				}
				return $true
			}
			catch {
				Write-Log -Message "Failed to create group $GroupName. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
				Write-Output $false
			}
			
		}
		End {
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
		}
}
#endregion

#region Remove-NxtLocalGroup
function Remove-NxtLocalGroup {
	<#
	.DESCRIPTION
		Deletes a local group with the given name.
	.EXAMPLE
		Remove-NxtLocalGroup -GroupName "TestGroup"
	.PARAMETER GroupName
		Name of the group
	.OUTPUTS
		System.Boolean
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
		[CmdletBinding()]
		param (
			[Parameter(Mandatory=$true)]
			[ValidateNotNullorEmpty()]
			[string]
			$GroupName
		)
		Begin {
			## Get the name of this function and write header
			[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		}
		Process {
			try {
				
				[bool]$groupExists = Test-NxtLocalGroupExists -GroupName $GroupName
				if($groupExists){
					[System.DirectoryServices.DirectoryEntry]$adsiObj = [ADSI]"WinNT://$($env:COMPUTERNAME)"
					$adsiObj.Delete("Group", $GroupName)
					Write-Output $true
					return
				}
				Write-Output $false
			}
			catch {
				Write-Log -Message "Failed to delete group $GroupName. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
				Write-Output $false
			}
			
		}
		End {
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
		}
}
#endregion

#region Remove-NxtLocalGroupMember
function Remove-NxtLocalGroupMember {
	<#
	.DESCRIPTION
		Removes a single member or a type of member from the given group by name.
		Returns the amount of members removed.
		Returns $null if the groups was not found.
	.EXAMPLE
		Remove-NxtLocalGroupMember -GroupName "Users" -All
	.EXAMPLE
		Remove-NxtLocalGroupMember -GroupName "Administrators" -MemberName "Dummy"
	.PARAMETER MemberName
		Name of the member to remove
	.PARAMETER Users
		If defined all users are removed
	.PARAMETER Groups
		If defined all groups are removed
	.PARAMETER All
		If defined all members are removed
	.OUTPUTS
		System.Int32
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
		[CmdletBinding()]
		param (
			[Parameter(Mandatory=$true)]
			[ValidateNotNullorEmpty()]
			[string]
			$GroupName,
			[Parameter(ParameterSetName='SingleMember')]
			[ValidateNotNullorEmpty()]
			[string]
			$MemberName,
			[Parameter(ParameterSetName='Users')]
			[Switch]
			$AllUsers,
			[Parameter(ParameterSetName='Groups')]
			[Switch]
			$AllGroups,
			[Parameter(ParameterSetName='All')]
			[Switch]
			$AllMember
		)
		Begin {
			## Get the name of this function and write header
			[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		}
		Process {
			try {
				[bool]$groupExists = ([ADSI]::Exists("WinNT://$($env:COMPUTERNAME)/$GroupName,group"))
				if($groupExists){
                    [System.DirectoryServices.DirectoryEntry]$group = [ADSI]"WinNT://$($env:COMPUTERNAME)/$GroupName,group"
                    if([string]::IsNullOrEmpty($MemberName))
                    {
                        [int]$count = 0
					    foreach($member in $group.psbase.Invoke("Members"))
					    {
						    $class = $member.GetType().InvokeMember("Class", 'GetProperty', $Null, $member, $Null)
						    if($AllMember){
							    $group.Remove($($member.GetType().InvokeMember("Adspath", 'GetProperty', $Null, $member, $Null)))
							    $count++
						    }
						    elseif($AllUsers){
							    if($class -eq "user"){
								    $group.Remove($($member.GetType().InvokeMember("Adspath", 'GetProperty', $Null, $member, $Null)))
								    $count++
							    }
						    }
						    elseif($AllGroups){
							    if($class -eq "group"){
								    $group.Remove($($member.GetType().InvokeMember("Adspath", 'GetProperty', $Null, $member, $Null)))
								    $count++
							    }
						    }
					    }
					    Write-Output $count
                    }
					else{
                        foreach($member in $group.psbase.Invoke("Members"))
					    {
						    [string]$name = $member.GetType().InvokeMember("Name", 'GetProperty', $Null, $member, $Null)
						    if($name -eq $MemberName)
						    {
							    $group.Remove($($member.GetType().InvokeMember("Adspath", 'GetProperty', $Null, $member, $Null)))
							    Write-Output 1
							    return
						    }
					    }
                    }
				}
				else{
					Write-Output $null
				}
			}
			catch {
				Write-Log -Message "Failed to remove members from $GroupName. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
				Write-Output $null
			}
		}
		End {
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
		}
}
#endregion


#region Add-NxtLocalGroupMember
function Add-NxtLocalGroupMember {
	<#
	.DESCRIPTION
		Adds local member to a local group
	.EXAMPLE
		Add-NxtLocalGroupMember -GroupName "TestGroup" -MemberName "TestUser" -MemberType "User"
	.PARAMETER GroupName
		Name of the target group
	.PARAMETER MemberName
		Name of the member to add
	.PARAMETER MemberType
		Defines the type of member
	.OUTPUTS
		System.Boolean
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
		[CmdletBinding()]
		param (
			[Parameter(Mandatory=$true)]
			[ValidateNotNullorEmpty()]
			[string]
			$GroupName,
			[Parameter(Mandatory=$true)]
			[ValidateNotNullorEmpty()]
			[string]
			$MemberName,
			[Parameter(Mandatory=$true)]
			[ValidateSet('Group','User')]
			[string]
			$MemberType
		)
		Begin {
			## Get the name of this function and write header
			[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		}
		Process {
			try {
				[bool]$groupExists = Test-NxtLocalGroupExists -GroupName $GroupName
				if($false -eq $groupExists){
					Write-Output $false
					return
				}
				[System.DirectoryServices.DirectoryEntry]$targetGroup = [ADSI]"WinNT://$($env:COMPUTERNAME)/$GroupName,group"
				if($MemberType -eq "Group"){
					[bool]$groupExists = Test-NxtLocalGroupExists -GroupName $MemberName
					if($false -eq $groupExists){
						Write-Output $false
						return
					}
					[System.DirectoryServices.DirectoryEntry]$memberGroup = [ADSI]"WinNT://$($env:COMPUTERNAME)/$MemberName,group"
					#$targetGroup.psbase.Invoke("Add", "WinNT://$($env:COMPUTERNAME)/$MemberName,")
					$targetGroup.psbase.Invoke("Add", $memberGroup.path)
					Write-Output $true
					return
				}
				elseif($MemberType -eq "User"){
					[bool]$userExists = Test-NxtLocalUserExists -UserName $MemberName
					if($false -eq $userExists ){
						Write-Output $false
						return
					}
					[System.DirectoryServices.DirectoryEntry]$memberUser = [ADSI]"WinNT://$($env:COMPUTERNAME)/$MemberName,user"
					$targetGroup.psbase.Invoke("Add", $memberUser.path)
					Write-Output $true
					return
				}
				Write-Output $false
			}
			catch {
				Write-Log -Message "Failed to add $MemberName of type $MemberType to $GroupName. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
				Write-Output $false
			}
			
		}
		End {
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
		}
}
#endregion

#region Read-NxtSingleXmlNode

function Read-NxtSingleXmlNode([string]$XmlFilePath, [string]$SingleNodeName) 
{
	<#
	.DESCRIPTION
		Reads single node of xml-file.
	.PARAMETER XmlFilePath
		Path to the Xml-File.
	.PARAMETER SingleNodeName
		Node path. (https://www.w3schools.com/xml/xpath_syntax.asp)
	.OUTPUTS
		string
	.EXAMPLE
		Read-NxtSingleXmlNode -XmlFilePath "C:\Test\setup.xml" -SingleNodeName "//UserId"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
    Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
            [System.Xml.XmlDocument]$xmlDoc = New-Object System.Xml.XmlDocument
            $xmlDoc.Load($XmlFilePath)
            Write-Output ($xmlDoc.DocumentElement.SelectSingleNode($SingleNodeName).InnerText)
		}
		finally {
			Write-Log -Message "Failed to read single node '$SingleNodeName' from Xml-File '$XmlFilePath'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Write-NxtSingleXmlNode

function Write-NxtSingleXmlNode([string]$XmlFilePath, [string]$SingleNodeName, [string]$Value) 
{
	<#
	.DESCRIPTION
		Writes single node to xml-file.
	.PARAMETER XmlFilePath
		Path to the Xml-File.
	.PARAMETER SingleNodeName
		Node path. (https://www.w3schools.com/xml/xpath_syntax.asp)
	.PARAMETER Value
		Node value.
	.EXAMPLE
		Write-NxtSingleXmlNode -XmlFilePath "C:\Test\setup.xml" -SingleNodeName "//UserId" -Value "müller"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
    Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
            [System.Xml.XmlDocument]$xmlDoc = New-Object System.Xml.XmlDocument
            $xmlDoc.Load($XmlFilePath)
            $xmlDoc.DocumentElement.SelectSingleNode($SingleNodeName).InnerText = $Value
            $xmlDoc.Save($XmlFilePath)
		}
		catch {
			Write-Log -Message "Failed to write value '$Value' to single node '$SingleNodeName' in Xml-File '$XmlFilePath'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Write-NxtXmlNode

function Write-NxtXmlNode([string]$XmlFilePath, [PSADTNXT.XmlNodeModel]$Model) 
{
	<#
	.DESCRIPTION
		Adds a node with attributes and values to an existing xml-file.
	.PARAMETER XmlFilePath
		Path to the Xml-File.
	.PARAMETER Model
		Xml Node model.
	.EXAMPLE
		$newNode = New-Object PSADTNXT.XmlNodeModel
		$newNode.name = "item"
		$newNode.AddAttribute("oor:path", "/org.openoffice.Setup/Office/Factories/org.openoffice.Setup:Fac-tory[com.sun.star.presentation.PresentationDocument]")
		$newNode.Child = New-Object PSADTNXT.XmlNodeModel
		$newNode.Child.name = "prop"
		$newNode.Child.AddAttribute("oor:name", "ooSetupFactoryDefaultFilter")
		$newNode.Child.AddAttribute("oor:op", "fuse")
		$newNode.Child.Child = New-Object PSADTNXT.XmlNodeModel
		$newNode.Child.Child.name = "value"
		$newNode.Child.Child.value = "Impress MS PowerPoint 2007 XML"
		Write-NxtXmlNode -XmlFilePath "C:\Test\setup.xml" -Model $newNode

		Creates this node:

		<item oor:path="/org.openoffice.Setup/Office/Factories/org.openoffice.Setup:Fac-tory[com.sun.star.presentation.PresentationDocument]">
			<prop oor:name="ooSetupFactoryDefaultFilter" oor:op="fuse">
				<value>Impress MS PowerPoint 2007 XML</value>
 			</prop>
		</item>
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
    Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
            [System.Xml.XmlDocument]$xmlDoc = New-Object System.Xml.XmlDocument
            $xmlDoc.Load($XmlFilePath)

			$createXmlNode = { param([System.Xml.XmlDocument]$doc, [PSADTNXT.XmlNodeModel]$child) 
				[System.Xml.XmlNode]$xmlNode = $doc.CreateNode("element", $child.Name, "")

				for ($i=0; $i -lt $child.Attributes.count; $i++) {
					$attribute = [System.Linq.Enumerable]::ElementAt($child.Attributes, $i)
					[System.Xml.XmlAttribute]$xmlAttribute = $doc.CreateAttribute($attribute.Key, "http://www.w3.org/1999/XSL/Transform")
					$xmlAttribute.Value = $attribute.Value
					[void]$xmlNode.Attributes.Append($xmlAttribute)
				}
			
				if ($false -eq [string]::IsNullOrEmpty($child.Value)) {
					$xmlNode.InnerText = $child.Value
				}
				elseif ($null -ne $child.Child) {
					$node = &$createXmlNode -Doc $doc -Child ($child.Child)
					[void]$xmlNode.AppendChild($node)
				}

				return $xmlNode
			}
			
			$newNode = &$createXmlNode -Doc $xmlDoc -Child $Model
			[void]$xmlDoc.DocumentElement.AppendChild($newNode)
            [void]$xmlDoc.Save($XmlFilePath)
		}
		catch {
			Write-Log -Message "Failed to write node in Xml-File '$XmlFilePath'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Function Remove-NxtEmptyFolder
Function Remove-NxtEmptyFolder {
	<#
	.SYNOPSIS
		Removes only empty folders
	.DESCRIPTION
		Removes folders only if they are empty and continues otherwise without any action.
	.PARAMETER Path
		Path to the empty folder to remove
	.EXAMPLE
		Remove-NxtEmptyFolder -Path "$installLocation\SomeEmptyFolder"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Path
	)
		
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Write-Log -Message "Check if [$path] exists and is empty..." -Source ${CmdletName}
		If (Test-Path -LiteralPath $Path -PathType 'Container') {
			Try {
				If( (Get-ChildItem $Path | Measure-Object).Count -eq 0) {
					Write-Log -Message "Delete empty folder [$path]..." -Source ${CmdletName}
					Remove-Item -LiteralPath $Path -Force -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorRemoveFolder'
					If ($ErrorRemoveFolder) {
						Write-Log -Message "The following error(s) took place while deleting the empty folder [$path]. `n$(Resolve-Error -ErrorRecord $ErrorRemoveFolder)" -Severity 2 -Source ${CmdletName}
					} else {
						Write-Log -Message "Empty folder [$Path] was deleted successfully..." -Source ${CmdletName}
					}
				} else {
					Write-Log -Message "Folder [$Path] is not empty, so it was not deleted..." -Source ${CmdletName}
				}
			}
			Catch {
				Write-Log -Message "Failed to delete empty folder [$path]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
					Throw "Failed to delete empty folder [$path]: $($_.Exception.Message)"
				}
			}
		}
		Else {
			Write-Log -Message "Folder [$Path] does not exist..." -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion

##*===============================================
##* END FUNCTION LISTINGS
##*===============================================

##*===============================================
##* SCRIPT BODY
##*===============================================

If ($scriptParentPath) {
	Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] dot-source invoked by [$(((Get-Variable -Name MyInvocation).Value).ScriptName)]" -Source $appDeployToolkitExtName
}
Else {
	Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] invoked directly" -Source $appDeployToolkitExtName
}

##*===============================================
##* END SCRIPT BODY
##*===============================================
