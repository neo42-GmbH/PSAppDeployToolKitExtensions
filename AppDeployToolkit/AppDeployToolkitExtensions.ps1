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
	.DESCRIPTION
		Initializes all neo42 functions and variables.
		Should be called on top of any 'Deploy-Application.ps1'.
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
			if (Test-Path -Path $extensionCsPath) {
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

#region Function Get-NxtPackageConfig
Function Get-NxtPackageConfig {
	<#
	.DESCRIPTION
		Parses the neo42PackageConfig.json into the variable $global:PackageConfig.
	.EXAMPLE
		Get-NxtPackageConfig
	.OUTPUTS
		none
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
	.OUTPUTS
		none
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

#region Function Get-NxtVariablesFromDeploymentSystem
Function Get-NxtVariablesFromDeploymentSystem {
	<#
	.SYNOPSIS
		Gets enviroment variables set by the deployment system
	.DESCRIPTION
		Should be called at the end of the variable definition section of any 'Deploy-Application.ps1' 
		Variables not set by the deployment system (or set to an unsuitable value) get a default value (e.g. [bool]$global:$registerPackage = $true)
		Variables set by the deployment system overwrite the values from the neo42PackageConfig.json
	.EXAMPLE
		Get-NxtVariablesFromDeploymentSystem
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
		Write-Log -Message "Getting enviroment variables set by the deployment system..." -Source ${cmdletName}
		Try {
			If ("false" -eq $env:registerPackage) {[bool]$global:registerPackage = $false} Else {[bool]$global:registerPackage = $true}
			If ("false" -eq $env:uninstallOld) {[bool]$global:uninstallOld = $false}
			If ($null -ne $env:Reboot) {[int]$global:reboot = $env:Reboot}
			Write-Log -Message "Enviroment variables successfully read." -Source ${cmdletName}
		}
		Catch {
			Write-Log -Message "Failed to get enviroment variables. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
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
		If $UninstallOld is set to true, the function checks for old versions of the same package / $UninstallKeyName and uninstalls them.
	.EXAMPLE
		Uninstall-NxtOld
	.NOTES
		Should be executed during package Initialization only.
	.OUTPUTS
		none
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
		Copies the package files to the local store and writes the package's registry keys under "HKLM\Software[\Wow6432Node]\$regPackagesKey\$UninstallKeyName" and "HKLM\Software[\Wow6432Node]\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName".
	.EXAMPLE
		Register-NxtPackage
	.NOTES
		Should be executed at the end of each neo42-package installation and when using Soft Migration only.
	.OUTPUTS
		none
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
			Copy-File -Path "$scriptParentPath\Deploy-Application.ps1" -Destination "$app\neoInstall\"
			Copy-File -Path "$dirSupportFiles\Setup.ico" -Destination "$app\neoInstall\"

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
				Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'UserPartPath' -Value ('"' + $app + '\neo42-Userpart"')
				Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'UserPartUninstPath' -Value ('"%AppData%\neoPackages\' + $uninstallKeyName + '"')
				Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'UserPartRevision' -Value $userPartRevision
			}
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\$regPackagesKey\$UninstallKeyName -Name 'Version' -Value $appVersion

			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'DisplayIcon' -Value $app\neoInstall\Setup.ico
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'DisplayName' -Value $uninstallDisplayName
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'DisplayVersion' -Value $appVersion
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'MachineKeyName' -Value $regPackagesKey\$uninstallKeyName
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'NoModify' -Type 'Dword' -Value 1
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'NoRemove' -Type 'Dword' -Value $hidePackageUninstallButton
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'NoRepair' -Type 'Dword' -Value 1
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
	.OUTPUTS
		none
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
			Copy-File -Path "$scriptRoot\CleanUp.cmd" -Destination "$app\"
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

#region Function Remove-NxtDesktopShortcuts
Function Remove-NxtDesktopShortcuts {
	<#
	.SYNOPSIS
		Removes the Shortcots defined under "CommonDesktopSortcutsToDelete" in the neo42PackageConfig.json from the common desktop
	.DESCRIPTION
		Is called after an installation/reinstallation if DESKTOPSHORTCUT=0 is defined in the Setup.cfg.
		Is always called before the uninstallation.
	.EXAMPLE
		Remove-NxtDesktopShortcuts
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
		Try {
			foreach($value in $global:PackageConfig.CommonDesktopSortcutsToDelete) {
				Write-Log -Message "Removing desktop shortcut '$envCommonDesktop\$value'..." -Source ${cmdletName}
				Remove-File -Path "$envCommonDesktop\$value"
				Write-Log -Message "Desktop shortcut succesfully removed." -Source ${cmdletName}
			}
		}
		Catch {
			Write-Log -Message "Failed to remove desktopshortcuts. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion


#region Function Copy-NxtDesktopShortcuts
Function Copy-NxtDesktopShortcuts {
	<#
	.SYNOPSIS
		Copys the Shortcots defined under "CommonStartmenuSortcutsToCopyToCommonDesktop" in the neo42PackageConfig.json to the common desktop
	.DESCRIPTION
		Is called after an installation/reinstallation if DESKTOPSHORTCUT=1 is defined in the Setup.cfg.
	.EXAMPLE
		Copy-NxtDesktopShortcuts
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
		Try {
			foreach($value in $global:PackageConfig.CommonStartmenuSortcutsToCopyToCommonDesktop) {
				Write-Log -Message "Copying start menu shortcut'$envCommonStartMenu\$($value.Source)' to the common desktop..." -Source ${cmdletName}
				Copy-File -Path "$envCommonStartMenu\$($value.Source)" -Destination "$envCommonDesktop\$($value.TargetName)"
				Write-Log -Message "Shortcut succesfully copied." -Source ${cmdletName}
			}
		}
		Catch {
			Write-Log -Message "Failed to copy shortcuts to the common desktop. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
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
		Stops a process by name.
	.DESCRIPTION
		Wrapper of the native Stop-Process cmdlet.
	.PARAMETER Name
		Name of the process.
	.EXAMPLE
		Stop-NxtProcess -Name Notepad
	.OUTPUTS
		none
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
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
function Get-NxtComputerManufacturer {
	<#
	.DESCRIPTION
		Gets the manufacturer of the computer system.
	.EXAMPLE
		Get-NxtComputerManufacturer
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
		[string]$result = [string]::Empty
		try {
			$result = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property Manufacturer).Manufacturer
		}
		catch {
			Write-Log -Message "Failed to get computer manufacturer. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		Write-Output $result
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion

#region Get-NxtComputerModel
function Get-NxtComputerModel {
	<#
	.DESCRIPTION
		Gets the model of the computer system.
	.EXAMPLE
		Get-NxtComputerModel
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
		[string]$result = [string]::Empty
		try {
			$result = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property Model).Model
		}
		catch {
			Write-Log -Message "Failed to get computer model. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		Write-Output $result
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion

#region Get-NxtFileVersion
function Get-NxtFileVersion([string]$FilePath) {
	<#
	.DESCRIPTION
		Gets version of file.
		The return value is a version object.
	.PARAMETER FilePath
		Full path to the file.
	.EXAMPLE
		Get-NxtFileVersion "D:\setup.exe"
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
		[version]$result = $null
		try {
			$result = (New-Object -TypeName System.IO.FileInfo -ArgumentList $FilePath).VersionInfo.FileVersion
		}
		catch {
			Write-Log -Message "Failed to get version from file '$FilePath'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		Write-Output $result
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion

#region Get-NxtFolderSize
function Get-NxtFolderSize([string]$FolderPath) {
	<#
	.DESCRIPTION
		Gets the size of the folder recursive in bytes.
	.PARAMETER FolderPath
		Path to the folder.
	.EXAMPLE
		Get-NxtFolderSize "D:\setup\"
	.OUTPUTS
		System.Long
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
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
		Write-Output $result
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
		Gets the drive type.
	.PARAMETER FolderPath
		Name of the drive.
	.OUTPUTS
		PSADTNXT.DriveType

		Values:
		Unknown = 0
		NoRootDirectory = 1
		Removable = 2
		Local = 3
		Network = 4
		Compact = 5
		Ram = 6
	.EXAMPLE
		Get-NxtDriveType "c:"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
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
function Get-NxtDriveFreeSpace([string]$DriveName) {
	<#
	.DESCRIPTION
		Gets free space of drive in bytes.
	.PARAMETER FolderPath
		Name of the drive.
	.EXAMPLE
		Get-NxtDriveFreeSpace "c:"
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
			$disk = Get-WmiObject -Class Win32_logicaldisk -Filter "DeviceID = '$DriveName'"
			Write-Output $disk.FreeSpace
		}
		catch {
			Write-Log -Message "Failed to get free space for '$DriveName'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		return 0
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion

#region Get-NxtProcessName
function Get-NxtProcessName([int]$ProcessId) {
	<#
	.DESCRIPTION
		Gets name of process.
		Returns an empty string if process was not found.
	.PARAMETER FolderPath
		Id of the process.
	.EXAMPLE
		Get-NxtProcessName 1004
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
		Detects if process is running with system account or not.
	.PARAMETER FolderPath
		Id of the process.
	.OUTPUTS
		System.Boolean
	.EXAMPLE
		Get-NxtIsSystemProcess 1004
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
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
function Get-NxtWindowsVersion {
	<#
	.DESCRIPTION
		Gets the Windows Version (CurrentVersion) from the Registry.
	.EXAMPLE
		Get-NxtWindowsVersion
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
		Gets OsLanguage as LCID Code from the Get-Culture cmdlet.
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
		Gets UiLanguage as LCID Code from Get-UICulture.
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
		Gets the environment variable $env:PROCESSOR_ARCHITEW6432 which is only set in a x86_32 process, returns empty string if run under 64-Bit Process.
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
		Translates the environment variable $env:PROCESSOR_ARCHITECTURE from x86 and amd64 to 32 / 64.
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
		Renames or moves a file or directory.
	.EXAMPLE
		Move-NxtItem -SourcePath C:\Temp\Sources\Installer.exe -DestinationPath C:\Temp\Sources\Installer_bak.exe
	.PARAMETER Path
		Source Path of the File or Directory.
	.PARAMETER DestinationPath
		Destination Path for the File or Directory.
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
function Test-NxtProcessExists([string]$ProcessName, [switch]$IsWql = $false) {
	<#
	.DESCRIPTION
		Tests if a process exists by name or custom WQL query.
	.PARAMETER ProcessName
		Name of the process or WQL search string.
	.PARAMETER IsWql
		Defines if the given ProcessName is a WQL search string.
	.OUTPUTS
		System.Boolean
	.EXAMPLE
		Test-NxtProcessExists "Notepad"
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
			[string]$wqlString = ""
			if ($IsWql) {
				$wqlString = $ProcessName
			}
			else {
				$wqlString = "Name LIKE '$($ProcessName)'"
			}
			$processes = Get-WmiObject -Query "Select * from Win32_Process Where $($wqlString)" | Select-Object -First 1
			if ($processes) {
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
function Watch-NxtRegistryKey([string]$RegistryKey, [int]$Timeout = 60) {
	<#
	.DESCRIPTION
		Tests if a registry key exists in a given time.
	.PARAMETER RegistryKey
		Name of the registry key to watch.
	.PARAMETER Timeout
		Timeout in seconds that the function waits for the key.
	.OUTPUTS
		System.Boolean
	.EXAMPLE
		Watch-NxtRegistryKey -RegistryKey "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
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
			$waited = 0
			while ($waited -lt $Timeout) {
				$key = Get-RegistryKey -Key $RegistryKey -ReturnEmptyKeyIfExists
				if ($key) {
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
function Watch-NxtRegistryKeyIsRemoved([string]$RegistryKey, [int]$Timeout = 60) {
	<#
	.DESCRIPTION
		Tests if a registry key disappears in a given time.
	.PARAMETER RegistryKey
		Name of the registry key to watch.
	.PARAMETER Timeout
		Timeout in seconds the function waits for the key the disappear.
	.OUTPUTS
		System.Boolean
	.EXAMPLE
		Watch-NxtRegistryKeyIsRemoved -RegistryKey "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
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
			$waited = 0
			while ($waited -lt $Timeout) {
				$key = Get-RegistryKey -Key $RegistryKey -ReturnEmptyKeyIfExists
				if ($null -eq $key) {
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
function Watch-NxtFile([string]$FileName, [int]$Timeout = 60) {
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
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			$waited = 0
			while ($waited -lt $Timeout) {
				$result = Test-Path -Path "$([System.Environment]::ExpandEnvironmentVariables($FileName))"
				if ($result) {
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
function Watch-NxtFileIsRemoved([string]$FileName, [int]$Timeout = 60) {
	<#
	.DESCRIPTION
		Tests if a file disappears in a given time.
		Automatically resolves cmd environment variables.
	.PARAMETER FileName
		Name of the file to watch.
	.PARAMETER Timeout
		Timeout in seconds the function waits for the file the disappear.
	.OUTPUTS
		System.Boolean
	.EXAMPLE
		Watch-NxtFileIsRemoved -FileName "C:\Temp\Sources\Installer.exe"
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
			$waited = 0
			while ($waited -lt $Timeout) {
				$result = Test-Path -Path "$([System.Environment]::ExpandEnvironmentVariables($FileName))"
				if ($false -eq $result) {
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
function Watch-NxtProcess([string]$ProcessName, [int]$Timeout = 60, [switch]$IsWql = $false) {
	<#
	.DESCRIPTION
		Checks whether a process exists within a given time based on the name or a custom WQL query.
	.PARAMETER ProcessName
		Name of the process or WQL search string.
	.PARAMETER Timeout
		Timeout in seconds the function waits for the process to start.
	.PARAMETER IsWql
		Defines if the given ProcessName is a WQL search string.
	.OUTPUTS
		System.Boolean
	.EXAMPLE
		Watch-NxtProcess -ProcessName "Notepad.exe"
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
			$waited = 0
			while ($waited -lt $Timeout) {
				if ($IsWql) {
					$result = Test-NxtProcessExists -ProcessName $ProcessName -IsWql
				}
				else {
					$result = Test-NxtProcessExists -ProcessName $ProcessName
				}
				
				if ($result) {
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
function Watch-NxtProcessIsStopped([string]$ProcessName, [int]$Timeout = 60, [switch]$IsWql = $false) {
	<#
	.DESCRIPTION
		Checks whether a process ends within a given time based on the name or a custom WQL query.
	.PARAMETER ProcessName
		Name of the process or WQL search string.
	.PARAMETER Timeout
		Timeout in seconds the function waits for the process the stop.
	.PARAMETER IsWql
		Defines if the given ProcessName is a WQL search string.
	.OUTPUTS
		System.Boolean
	.EXAMPLE
		Watch-NxtProcessIsStopped -ProcessName "Notepad.exe"
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
			$waited = 0
			while ($waited -lt $Timeout) {
				if ($IsWql) {
					$result = Test-NxtProcessExists -ProcessName $ProcessName -IsWql
				}
				else {
					$result = Test-NxtProcessExists -ProcessName $ProcessName
				}
				
				if ($false -eq $result) {
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
function Get-NxtServiceState([string]$ServiceName) {
	<#
	.DESCRIPTION
		Gets the state of the given service name.
		Returns $null if service was not found.
	.PARAMETER ServiceName
		Name of the service.
	.OUTPUTS
		System.String
	.EXAMPLE
		Get-NxtServiceState "BITS"
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
			$service = Get-WmiObject -Query "Select State from Win32_Service Where Name = '$($ServiceName)'" | Select-Object -First 1
			if ($service) {
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
function Get-NxtNameBySid([string]$Sid) {
	<#
	.DESCRIPTION
		Gets the netbios user name for a SID.
		Returns $null if SID was not found.
	.PARAMETER Sid
		SID to search.
	.OUTPUTS
		System.String
	.EXAMPLE
		Get-NxtNameBySid -Sid "S-1-5-21-3072877179-2344900292-1557472252-500"
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
			[System.Management.ManagementObject]$wmiAccount = ([wmi]"win32_SID.SID='$Sid'")
			[string]$result = "$($wmiAccount.ReferencedDomainName)\$($wmiAccount.AccountName)"
			if ($result -eq "\") {
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
function Compare-NxtVersion([string]$InstalledPackageVersion, [string]$NewPackageVersion) {
	<#
	.DESCRIPTION
		Compares two package versions.

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
				[int[]]$result = 0, 0, 0, 0
				$versionParts = [System.Linq.Enumerable]::ToArray([System.Linq.Enumerable]::Select($Version.Split('.'), [Func[string, PSADTNXT.VersionKeyValuePair]] { param($x) New-Object PSADTNXT.VersionKeyValuePair -ArgumentList $x, ([System.Linq.Enumerable]::ToArray([System.Linq.Enumerable]::Select($x.ToCharArray(), [System.Func[char, PSADTNXT.VersionPartInfo]] { param($x) New-Object -TypeName "PSADTNXT.VersionPartInfo" -ArgumentList $x }))) }))
				for ($i = 0; $i -lt $versionParts.count; $i++) {
					[int]$versionPartValue = 0
					$pair = [System.Linq.Enumerable]::ElementAt($versionParts, $i)
					if ([System.Linq.Enumerable]::All($pair.Value, [System.Func[PSADTNXT.VersionPartInfo, bool]] { param($x) [System.Char]::IsDigit($x.Value) })) {
						$versionPartValue = [int]::Parse($pair.Key)
					}
					else {
						$value = [System.Linq.Enumerable]::FirstOrDefault($pair.Value)
						if ($null -ne $value -and [System.Char]::IsLetter($value.Value)) {
							#Important for compare (An upper 'A'==65 char must have the value 10) 
							$versionPartValue = $value.AsciiValue - 55
						}
					}
					$result[$i] = $versionPartValue
				}
				Write-Output (New-Object System.Version -ArgumentList $result[0], $result[1], $result[2], $result[3])
				return }.GetNewClosure()

			[System.Version]$instVersion = &$parseVersion -Version $InstalledPackageVersion
			[System.Version]$newVersion = &$parseVersion -Version $NewPackageVersion
			if ($instVersion -eq $newVersion) {
				Write-Output ([PSADTNXT.VersionCompareResult]::Equal)
			}
			elseif ($newVersion -gt $instVersion) {
				Write-Output ([PSADTNXT.VersionCompareResult]::Update)
			}
			else {
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
  	.DESCRIPTION
		Returns the estimated encoding based on BOM detection, defaults to ASCII.
		Used to get the default encoding for Add-NxtContent.
  	.PARAMETER Path
		The path to the file.
	.PARAMETER DefaultEncoding
	  	Encoding to be returned in case the encoding could not be detected.
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
		Appends strings to text files.
	.PARAMETER Path
		Path to the file.
	.PARAMETER Value
		String to be appended.
	.PARAMETER Encoding
		Encoding to be used, defaults to the value obtained from Get-NxtFileEncoding.
	.PARAMETER DefaultEncoding
		Encoding to be used in case the encoding could not be detected.
	.EXAMPLE
		Add-NxtContent -Path C:\Temp\testfile.txt -Value "Text to be appended to a file"
  	.OUTPUTS
		none
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
				if ($intEncoding -eq "UTF8") {
					[bool]$noBOMDetected = $true
				}
				ElseIf ($intEncoding -eq "UTF8withBom") {
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
			if ($noBOMDetected -and ($intEncoding -eq "UTF8")) {
				[System.IO.File]::AppendAllLines($Path, $Content)
			}
			else {
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
		Replaces text in a file by search string.
  	.PARAMETER Path
		Path to the File to be updated.
  	.PARAMETER SearchString
		String to be replaced in the File.
  	.PARAMETER ReplaceString
		The string to be inserted to the found occurrences.
  	.PARAMETER Count
		Number of occurrences to be replaced.
  	.PARAMETER Encoding
		Encoding to be used, defaults to the value obtained from Get-NxtFileEncoding.
	.PARAMETER DefaultEncoding
		Encoding to be used in case the encoding could not be detected.
  	.EXAMPLE
		Update-NxtTextInFile -Path C:\Temp\testfile.txt -SearchString "Hello" 
	.OUTPUTS
		none
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
				if ($intEncoding -eq "UTF8") {
					[bool]$noBOMDetected = $true
				}
				ElseIf ($intEncoding -eq "UTF8withBom") {
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
			if ($regexMatches.count -eq 0) {
				Write-Log -Message "Did not find anything to replace in file '$Path'."
				return
			}
			[Array]::Reverse($regexMatches)
			foreach ($match in $regexMatches) {
				$Content = $Content.Remove($match.index, $match.Length).Insert($match.index, $ReplaceString)
			}
			if ($noBOMDetected -and ($intEncoding -eq "UTF8")) {
				[System.IO.File]::WriteAllLines($Path, $Content)
			}
			else {
				$Content | Set-Content @contentParams -NoNewline
			}
		}
		catch {
			Write-Log -Message "Failed to add content to the file $Path'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
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
	.OUTPUTS
		none
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
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
			if ([string]::IsNullOrEmpty($sid)) {
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
function Get-NxtProcessEnvironmentVariable([string]$Key) {
	<#
	.DESCRIPTION
		Gets the value of the process environment variable.
	.PARAMETER Key
		Key of the variable.
	.OUTPUTS
		System.String
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
			Write-Log -Message "Failed to get the process environment variable with key '$Key'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
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
function Set-NxtProcessEnvironmentVariable([string]$Key, [string]$Value) {
	<#
	.DESCRIPTION
		Sets a process environment variable.
	.PARAMETER Key
		Key of the variable.
	.PARAMETER Value
		Value of the variable.
	.EXAMPLE
		Set-NxtProcessEnvironmentVariable -Key "Test" -Value "Hello world"
	.OUTPUTS
		none
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
			Write-Log -Message "Failed to set the process environment variable with key '$Key' and value '{$Value}'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion

#region Remove-NxtProcessEnvironmentVariable
function Remove-NxtProcessEnvironmentVariable([string]$Key) {
	<#
	.DESCRIPTION
		Deletes a process environment variable.
	.PARAMETER Key
		Key of the variable.
	.EXAMPLE
		Remove-NxtProcessEnvironmentVariable "Test"
	.OUTPUTS
		none
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
			Write-Log -Message "Failed to remove the process environment variable with key '$Key'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion

#region Get-NxtSystemEnvironmentVariable
function Get-NxtSystemEnvironmentVariable([string]$Key) {
	<#
	.DESCRIPTION
		Gets the value of the system environment variable.
	.PARAMETER Key
		Key of the variable
	.OUTPUTS
		System.String
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
			Write-Log -Message "Failed to get the system environment variable with key '$Key'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
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
function Set-NxtSystemEnvironmentVariable([string]$Key, [string]$Value) {
	<#
	.DESCRIPTION
		Sets a system environment variable.
	.PARAMETER Key
		Key of the variable
	.PARAMETER Value
		Value of the variable
	.EXAMPLE
		Set-NxtSystemEnvironmentVariable "Test" "Hello world"
	.OUTPUTS
		none
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
			Write-Log -Message "Failed to set the system environment variable with key '$Key' and value '{$Value}'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion

#region Remove-NxtSystemEnvironmentVariable
function Remove-NxtSystemEnvironmentVariable([string]$Key) {
	<#
	.DESCRIPTION
		Deletes a system environment variable.
	.PARAMETER Key
		Key of the variable.
	.EXAMPLE
		Remove-NxtSystemEnvironmentVariable "Test"
	.OUTPUTS
		none
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
			Write-Log -Message "Failed to remove the system environment variable with key '$Key'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
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
		Checks if a local user exists by name.
	.PARAMETER UserName
		Name of the user
	.EXAMPLE
		Test-NxtLocalUserExists -UserName "Administrator"
	.OUTPUTS
		System.Boolean
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
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
	.EXAMPLE
		Add-NxtLocalUser -UserName "ServiceUser" -Password "123!abc" -Description "User to run service" -SetPwdNeverExpires
	.OUTPUTS
		System.Boolean
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	param (
		[Parameter(ParameterSetName = 'Default', Mandatory = $true)]
		[Parameter(ParameterSetName = 'SetPwdNeverExpires', Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[string]
		$UserName,
		[Parameter(ParameterSetName = 'Default', Mandatory = $true)]
		[Parameter(ParameterSetName = 'SetPwdNeverExpires', Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[string]
		$Password,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]
		$FullName,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]
		$Description,
		[Parameter(ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[switch]
		$SetPwdExpired,
		[Parameter(ParameterSetName = 'SetPwdNeverExpires', Mandatory = $false)]
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
			if ($false -eq $userExists) {
				[System.DirectoryServices.DirectoryEntry]$objUser = $adsiObj.Create("User", $UserName)
				$objUser.setpassword($Password)
				$objUser.SetInfo()
			}
			else {
				[System.DirectoryServices.DirectoryEntry]$objUser = [ADSI]"WinNT://$($env:COMPUTERNAME)/$UserName,user"
			}
			if (-NOT [string]::IsNullOrEmpty($FullName)) {
				$objUser.Put("FullName", $FullName)
				$objUser.SetInfo()
			}
			if (-NOT [string]::IsNullOrEmpty($Description)) {
				$objUser.Put("Description", $Description)
				$objUser.SetInfo()
			}
			if ($SetPwdExpired) {
				## Reset to normal account flag ADS_UF_NORMAL_ACCOUNT
				$objUser.UserFlags = 512
				$objUser.SetInfo()
				## Set password expired
				$objUser.Put("PasswordExpired", 1)
				$objUser.SetInfo()
			}
			if ($SetPwdNeverExpires) {
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
		Deletes a local group by name.
	.PARAMETER UserName
		Name of the user
	.EXAMPLE
		Remove-NxtLocalUser -UserName "Test"
	.OUTPUTS
		System.Boolean
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
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
			if ($userExists) {
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
		Checks if a local group exists by name.
	.PARAMETER GroupName
		Name of the group.
	.EXAMPLE
		Test-NxtLocalGroupExists -GroupName "Administrators"
	.OUTPUTS
		System.Boolean
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
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
	.PARAMETER GroupName
		Name of the group.
	.PARAMETER Description
		Description for the new group.
	.EXAMPLE
		Add-NxtLocalGroup -GroupName "TestGroup"
	.OUTPUTS
		System.Boolean
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[string]
		$GroupName,
		[Parameter(Mandatory = $false)]
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
			if ($false -eq $groupExists) {
				[System.DirectoryServices.DirectoryEntry]$objGroup = $adsiObj.Create("Group", $GroupName)
				$objGroup.SetInfo()
			}
			else {
				[System.DirectoryServices.DirectoryEntry]$objGroup = [ADSI]"WinNT://$($env:COMPUTERNAME)/$GroupName,group"
			}
			if (-NOT [string]::IsNullOrEmpty($Description)) {
				$objGroup.Put("Description", $Description)
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
	.PARAMETER GroupName
		Name of the group
	.EXAMPLE
		Remove-NxtLocalGroup -GroupName "TestGroup"
	.OUTPUTS
		System.Boolean
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
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
			if ($groupExists) {
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
	.PARAMETER MemberName
		Name of the member to remove
	.PARAMETER Users
		If defined all users are removed
	.PARAMETER Groups
		If defined all groups are removed
	.PARAMETER All
		If defined all members are removed
	.EXAMPLE
		Remove-NxtLocalGroupMember -GroupName "Users" -All
	.EXAMPLE
		Remove-NxtLocalGroupMember -GroupName "Administrators" -MemberName "Dummy"
	.OUTPUTS
		System.Int32
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[string]
		$GroupName,
		[Parameter(ParameterSetName = 'SingleMember')]
		[ValidateNotNullorEmpty()]
		[string]
		$MemberName,
		[Parameter(ParameterSetName = 'Users')]
		[Switch]
		$AllUsers,
		[Parameter(ParameterSetName = 'Groups')]
		[Switch]
		$AllGroups,
		[Parameter(ParameterSetName = 'All')]
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
			if ($groupExists) {
				[System.DirectoryServices.DirectoryEntry]$group = [ADSI]"WinNT://$($env:COMPUTERNAME)/$GroupName,group"
				if ([string]::IsNullOrEmpty($MemberName)) {
					[int]$count = 0
					foreach ($member in $group.psbase.Invoke("Members")) {
						$class = $member.GetType().InvokeMember("Class", 'GetProperty', $Null, $member, $Null)
						if ($AllMember) {
							$group.Remove($($member.GetType().InvokeMember("Adspath", 'GetProperty', $Null, $member, $Null)))
							$count++
						}
						elseif ($AllUsers) {
							if ($class -eq "user") {
								$group.Remove($($member.GetType().InvokeMember("Adspath", 'GetProperty', $Null, $member, $Null)))
								$count++
							}
						}
						elseif ($AllGroups) {
							if ($class -eq "group") {
								$group.Remove($($member.GetType().InvokeMember("Adspath", 'GetProperty', $Null, $member, $Null)))
								$count++
							}
						}
					}
					Write-Output $count
				}
				else {
					foreach ($member in $group.psbase.Invoke("Members")) {
						[string]$name = $member.GetType().InvokeMember("Name", 'GetProperty', $Null, $member, $Null)
						if ($name -eq $MemberName) {
							$group.Remove($($member.GetType().InvokeMember("Adspath", 'GetProperty', $Null, $member, $Null)))
							Write-Output 1
							return
						}
					}
				}
			}
			else {
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
		Adds local member to a local group.
	.PARAMETER GroupName
		Name of the target group.
	.PARAMETER MemberName
		Name of the member to add.
	.PARAMETER MemberType
		Defines the type of member.
	.EXAMPLE
		Add-NxtLocalGroupMember -GroupName "TestGroup" -MemberName "TestUser" -MemberType "User"
	.OUTPUTS
		System.Boolean
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[string]
		$GroupName,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[string]
		$MemberName,
		[Parameter(Mandatory = $true)]
		[ValidateSet('Group', 'User')]
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
			if ($false -eq $groupExists) {
				Write-Output $false
				return
			}
			[System.DirectoryServices.DirectoryEntry]$targetGroup = [ADSI]"WinNT://$($env:COMPUTERNAME)/$GroupName,group"
			if ($MemberType -eq "Group") {
				[bool]$groupExists = Test-NxtLocalGroupExists -GroupName $MemberName
				if ($false -eq $groupExists) {
					Write-Output $false
					return
				}
				[System.DirectoryServices.DirectoryEntry]$memberGroup = [ADSI]"WinNT://$($env:COMPUTERNAME)/$MemberName,group"
				$targetGroup.psbase.Invoke("Add", $memberGroup.path)
				Write-Output $true
				return
			}
			elseif ($MemberType -eq "User") {
				[bool]$userExists = Test-NxtLocalUserExists -UserName $MemberName
				if ($false -eq $userExists ) {
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
function Read-NxtSingleXmlNode([string]$XmlFilePath, [string]$SingleNodeName) {
	<#
	.DESCRIPTION
		Reads single node of xml file.
	.PARAMETER XmlFilePath
		Path to the xml file.
	.PARAMETER SingleNodeName
		Node path. (https://www.w3schools.com/xml/xpath_syntax.asp)
	.EXAMPLE
		Read-NxtSingleXmlNode -XmlFilePath "C:\Test\setup.xml" -SingleNodeName "//UserId"
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
			[System.Xml.XmlDocument]$xmlDoc = New-Object System.Xml.XmlDocument
			$xmlDoc.Load($XmlFilePath)
			Write-Output ($xmlDoc.DocumentElement.SelectSingleNode($SingleNodeName).InnerText)
		}
		finally {
			Write-Log -Message "Failed to read single node '$SingleNodeName' from xml file '$XmlFilePath'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion

#region Write-NxtSingleXmlNode
function Write-NxtSingleXmlNode([string]$XmlFilePath, [string]$SingleNodeName, [string]$Value) {
	<#
	.DESCRIPTION
		Writes single node to xml file.
	.PARAMETER XmlFilePath
		Path to the xml file.
	.PARAMETER SingleNodeName
		Node path. (https://www.w3schools.com/xml/xpath_syntax.asp)
	.PARAMETER Value
		Node value.
	.EXAMPLE
		Write-NxtSingleXmlNode -XmlFilePath "C:\Test\setup.xml" -SingleNodeName "//UserId" -Value "müller"
	.OUTPUTS
		none
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
			Write-Log -Message "Failed to write value '$Value' to single node '$SingleNodeName' in xml file '$XmlFilePath'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion

#region Write-NxtXmlNode
function Write-NxtXmlNode([string]$XmlFilePath, [PSADTNXT.XmlNodeModel]$Model) {
	<#
	.DESCRIPTION
		Adds a node with attributes and values to an existing xml file.
	.PARAMETER XmlFilePath
		Path to the xml file.
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
	.OUTPUTS
		none
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

				for ($i = 0; $i -lt $child.Attributes.count; $i++) {
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
			Write-Log -Message "Failed to write node in xml file '$XmlFilePath'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
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
	.OUTPUTS
		none
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
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
				If ( (Get-ChildItem $Path | Measure-Object).Count -eq 0) {
					Write-Log -Message "Delete empty folder [$path]..." -Source ${CmdletName}
					Remove-Item -LiteralPath $Path -Force -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorRemoveFolder'
					If ($ErrorRemoveFolder) {
						Write-Log -Message "The following error(s) took place while deleting the empty folder [$path]. `n$(Resolve-Error -ErrorRecord $ErrorRemoveFolder)" -Severity 2 -Source ${CmdletName}
					}
					else {
						Write-Log -Message "Empty folder [$Path] was deleted successfully..." -Source ${CmdletName}
					}
				}
				else {
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

#region Function Execute-NxtInnoSetup
function Execute-NxtInnoSetup {
    <#
	.SYNOPSIS
		Executes the following actions for InnoSetup installations: install (with UninstallKey AND installation file), uninstall (with UninstallKey).
	.DESCRIPTION
		Sets default switches to be passed to un-/installation file based on the preferences in the XML configuration file, if no Parameters are specifed.
		Automatically generates a log file name and creates a log file, if none is specifed.
		Can handle installation files by name in the "Files" sub directory or full paths anywhere.
	.PARAMETER Action
		The action to perform. Options: Install, Uninstall. Default is: Install.
	.PARAMETER UninstallKey
		Name of the uninstall registry key of the application (e.g. "This Application_is1" or "{XXXXXXXX-XXXX-XXXXXXXX-XXXXXXXXXXXX}_is1").
		Can be found under "HKLM\SOFTWARE\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\".
	.PARAMETER Path
		The path to the Inno Setup installation File in case of an installation. (Not needed for "Uninstall" actions!)
	.PARAMETER Parameters
		Overrides the default parameters specified in the XML configuration file.
		Install default is: "/FORCEINSTALL /SILENT /SP- /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /RESTARTEXITCODE=3010".
		Uninstall default is: "/SILENT /SP- /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /RESTARTEXITCODE=3010".
	.PARAMETER AddParameters
		Adds to the default parameters specified in the XML configuration file.
		Install default is: "/FORCEINSTALL /SILENT /SP- /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /RESTARTEXITCODE=3010".
		Uninstall default is: "/SILENT /SP- /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /RESTARTEXITCODE=3010".
	.PARAMETER MergeTasks
		Specifies the tasks which should be done WITHOUT(!) overriding the default tasks (preselected default tasks from the setup).
		Use "!" before a task name for deselecting a specific task, otherwise it is selected.
		For specific informations see: https://jrsoftware.org/ishelp/topic_setupcmdline.htm
	.PARAMETER Log
		Log file name or full path including it's name and file format (eg. '-Log "InstLogFile"', '-Log "UninstLog.txt"' or '-Log "$app\Install.$timestamp.log"')
		If only a name ist specified the log path is taken from AppDeployToolkitConfig.xml (node "NxtInnoSetup_LogPath").
		If this parameter is not specified a log name is generated automatically and the log path is again taken from AppDeployToolkitConfig.xml (node "NxtInnoSetup_LogPath").
	.PARAMETER PassThru
		Returns ExitCode, STDOut, and STDErr output from the process.
	.PARAMETER ContinueOnError
		Continue if an error is encountered. Default is: $false.
	.EXAMPLE
		Execute-NxtInnoSetup -UninstallKey "This Application_is1" -Path "InstallThisApp.exe" -AddParameters "/LOADINF=`"$dirSupportFiles\Comp.inf`"" -Log "InstallationLog"
	.EXAMPLE
		Execute-NxtInnoSetup -Action "Uninstall" -UninstallKey "This Application_is1" -Log "$app\Uninstall.$timestamp.log"
	.NOTES
		AppDeployToolkit is required in order to run this function.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Install', 'Uninstall')]
        [string]$Action = 'Install',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [string]$UninstallKey,

        [Parameter(Mandatory = $false)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$Parameters,
        
        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [string]$AddParameters,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$MergeTasks,

        [Parameter(Mandatory = $false)]
        [string]$Log,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [switch]$PassThru = $false,
        
        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [boolean]$ContinueOnError = $false
    )
    Begin {
        ## read config data
        [Xml.XmlElement]$xmlConfigNxtInnoSetup = $xmlConfig.NxtInnoSetup_Options
        [string]$ConfigNxtInnoSetupInstallParams = $ExecutionContext.InvokeCommand.ExpandString($xmlConfigNxtInnoSetup.NxtInnoSetup_InstallParams)
        [string]$ConfigNxtInnoSetupUninstallParams = $ExecutionContext.InvokeCommand.ExpandString($xmlConfigNxtInnoSetup.NxtInnoSetup_UninstallParams)
        [string]$ConfigNxtInnoSetupLogPath = $ExecutionContext.InvokeCommand.ExpandString($xmlConfigNxtInnoSetup.NxtInnoSetup_LogPath)

		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
    Process {

        [string]$innoUninstallKey = $UninstallKey
   
        switch ($Action) {
            'Install' {
                $InnoSetupDefaultParams = $ConfigNxtInnoSetupInstallParams

        		## If the Setup File is in the Files directory, set the full path during an installation
				If (Test-Path -LiteralPath (Join-Path -Path $dirFiles -ChildPath $path -ErrorAction 'SilentlyContinue') -PathType 'Leaf' -ErrorAction 'SilentlyContinue') {
					[string]$innoSetupPath = Join-Path -Path $dirFiles -ChildPath $path
				}
				ElseIf (Test-Path -LiteralPath $Path -ErrorAction 'SilentlyContinue') {
					[string]$innoSetupPath = (Get-Item -LiteralPath $Path).FullName
				}
				Else {
					Write-Log -Message "Failed to find installation file [$path]." -Severity 3 -Source ${CmdletName}
					If (-not $ContinueOnError) {
						Throw "Failed to find installation file [$path]."
					}
					Continue
				}
            }
            'Uninstall' {
                $InnoSetupDefaultParams = $ConfigNxtInnoSetupUninstallParams
                $InstalledAppResults = Get-InstalledApplication -ProductCode $innoUninstallKey -Exact -ErrorAction 'SilentlyContinue'
    
                if (!$InstalledAppResults) {
                    Write-Log -Message "No Application with UninstallKey `"$innoUninstallKey`" found. Skipping action [$Action]..." -Source ${CmdletName}
					return
                }
    
                [string]$innoUninstallString = $InstalledAppResults.UninstallString
    
                ## check for and remove quotation marks around the uninstall string
                if ($innoUninstallString.StartsWith('"')) {
                    [string]$innoSetupPath = $innoUninstallString.Substring(1, $innoUninstallString.IndexOf('"', 1) - 1)
                }
                else {
                    [string]$innoSetupPath = $innoUninstallString.Substring(0, $innoUninstallString.IndexOf('.exe', [System.StringComparison]::CurrentCultureIgnoreCase) + 4)
                }
				
				## Get the parent folder of the uninstallation file
				[string]$UninsFolder = split-path $innoSetupPath -Parent

				## If the uninstall file does not exist, restore it from $App, if it exists there
				if (![System.IO.File]::Exists($innoSetupPath) -and ($true -eq (Get-Item "$App\neoSource\unins[0-9][0-9][0-9].exe"))) {
					Write-Log -Message "Uninstall file not found. Restoring it from backup..." -Source ${CmdletName}
					Remove-File -Path "$UninsFolder\unins*.*"
					Copy-File -Path "$App\neoSource\unins[0-9][0-9][0-9].*" -Destination "$UninsFolder\"	
				}

				## If any "$UninsFolder\unins[0-9][0-9][0-9].exe" exists, use the one with the highest number
				If ($true -eq (Get-Item "$UninsFolder\unins[0-9][0-9][0-9].exe")) {
					[string]$innoSetupPath = Get-Item "$UninsFolder\unins[0-9][0-9][0-9].exe" | Select-Object -last 1 -ExpandProperty FullName
					Write-Log -Message "Uninstall file set to: `"$innoSetupPath`"." -Source ${CmdletName}
				}

				## If $innoSetupPath is still unexistend, write Error to log and abort
				if (![System.IO.File]::Exists($innoSetupPath)) {
                    Write-Log -Message "Uninstallation file could not be found nor restored." -Severity 3 -Source ${CmdletName}

                    if ($ContinueOnError) {
						## Uninstallation without uninstallation file is impossible --> Abort the function without error
                        return
                    }
                    else {
                        throw "Uninstallation file could not be found nor restored."
                    }
                }

            }
        }
    
        [string]$argsInnoSetup = $InnoSetupDefaultParams
    
        ## Replace default parameters if specified.
        If ($Parameters) {
            $argsInnoSetup = $Parameters
        }
        ## Append parameters to default parameters if specified.
        If ($AddParameters) {
            $argsInnoSetup = "$argsInnoSetup $AddParameters"
        }

        ## MergeTasks if parameters were not replaced
        if ((-not($Parameters)) -and (-not([string]::IsNullOrWhiteSpace($MergeTasks)))) {
            $argsInnoSetup += " /MERGETASKS=`"$MergeTasks`""
        }
    
        [string]$fullLogPath = $null

        ## Logging
        if ([string]::IsNullOrWhiteSpace($Log)) {
            ## create Log file name if non is specified
            if ($Action -eq 'Install') {
				[string]$Log = "Install_$($Path -replace ' ',[string]::Empty)_$timestamp"
            }
            else {
                [string]$Log = "Uninstall_$($InstalledAppResults.DisplayName -replace ' ',[string]::Empty)_$timestamp"
            }
        }

        [string]$LogFileExtension = [System.IO.Path]::GetExtension($Log)

        ## Append file extension if necessary
        if (($LogFileExtension -ne '.txt') -and ($LogFileExtension -ne '.log')) {
            $Log = $Log + '.log'
        }

        ## Check, if $Log is a full path
        if (-not($Log.Contains('\'))) {
            $fullLogPath = Join-Path -Path $ConfigNxtInnoSetupLogPath -ChildPath $($Log -replace ' ',[string]::Empty)
        }
        else {
            $fullLogPath = $Log
        }

        $argsInnoSetup = "$argsInnoSetup /LOG=`"$fullLogPath`""
    
        [hashtable]$ExecuteProcessSplat = @{
            Path             = $innoSetupPath
            Parameters       = $argsInnoSetup
            WindowStyle      = 'Normal'
        }
        
        If ($ContinueOnError) {
            $ExecuteProcessSplat.Add('ContinueOnError', $ContinueOnError)
        }
        If ($PassThru) {
            $ExecuteProcessSplat.Add('PassThru', $PassThru)
        }
    
        If ($PassThru) {
            [psobject]$ExecuteResults = Execute-Process @ExecuteProcessSplat
        }
        Else {
            Execute-Process @ExecuteProcessSplat
        }
    
        ## Update the desktop (in case of changed or added enviroment variables)
        Update-Desktop

		## Copy uninstallation file from $UninsFolder to $App after a successful installation
		if ($Action -eq 'Install') {
			$InstalledAppResults = Get-InstalledApplication -ProductCode $innoUninstallKey -Exact -ErrorAction 'SilentlyContinue'
    
			if (!$InstalledAppResults) {
				Write-Log -Message "No Application with UninstallKey `"$innoUninstallKey`" found. Skipping [copy uninstallation files to backup]..." -Source ${CmdletName}
			}
			Else {
				[string]$innoUninstallString = $InstalledAppResults.UninstallString

				## check for and remove quotation marks around the uninstall string
				if ($innoUninstallString.StartsWith('"')) {
					[string]$innoUninstallPath = $innoUninstallString.Substring(1, $innoUninstallString.IndexOf('"', 1) - 1)
				}
				else {
					[string]$innoUninstallPath = $innoUninstallString.Substring(0, $innoUninstallString.IndexOf('.exe', [System.StringComparison]::CurrentCultureIgnoreCase) + 4)
				}
				
				## Get the parent folder of the uninstallation file
				[string]$UninsFolder = split-path $innoUninstallPath -Parent

				## Actually copy the uninstallation file, if it exists
				If ($true -eq (Get-Item "$UninsFolder\unins[0-9][0-9][0-9].exe")) {
					Write-Log -Message "Copy uninstallation files to backup..." -Source ${CmdletName}
					Copy-File -Path "$UninsFolder\unins[0-9][0-9][0-9].*" -Destination "$App\neoSource\"	
				}
				Else {
					Write-Log -Message "Uninstall file not found. Skipping [copy of uninstallation files to backup]..." -Source ${CmdletName}
				}
			}
		}
    }
    End {
		If ($PassThru) {
            Write-Output -InputObject $ExecuteResults
        }

		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Execute-NxtNullsoft
function Execute-NxtNullsoft {
    <#
	.SYNOPSIS
		Executes the following actions for Nullsoft installations: install (with UninstallKey AND installation file), uninstall (with UninstallKey).
	.DESCRIPTION
		Sets default switches to be passed to un-/installation file based on the preferences in the XML configuration file, if no Parameters are specifed.
		Can handle installation files by name in the "Files" sub directory or full paths anywhere.
	.PARAMETER Action
		The action to perform. Options: Install, Uninstall. Default is: Install.
	.PARAMETER UninstallKey
		Name of the uninstall registry key of the application (e.g. "ThisApplication").
		Can be found under "HKLM\SOFTWARE\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\".
	.PARAMETER Path
		The path to the Nullsoft installation File in case of an installation. (Not needed for "Uninstall" actions!)
	.PARAMETER Parameters
		Overrides the default parameters specified in the XML configuration file.
		Install default is: "/AllUsers /S".
		Uninstall default is: "/AllUsers /S".
	.PARAMETER AddParameters
		Adds to the default parameters specified in the XML configuration file.
		Install default is: "/AllUsers /S".
		Uninstall default is: "/AllUsers /S".
	.PARAMETER PassThru
		Returns ExitCode, STDOut, and STDErr output from the process.
	.PARAMETER ContinueOnError
		Continue if an error is encountered. Default is: $false.
	.EXAMPLE
		Execute-NxtNullsoft -UninstallKey "ThisApplication" -Path "InstallThisApp.exe" -Parameters "SILENT=1"
	.EXAMPLE
		Execute-NxtNullsoft -Action "Uninstall" -UninstallKey "ThisApplication"
	.NOTES
		AppDeployToolkit is required in order to run this function.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Install', 'Uninstall')]
        [string]$Action = 'Install',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [string]$UninstallKey,

        [Parameter(Mandatory = $false)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$Parameters,
        
        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [string]$AddParameters,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [switch]$PassThru = $false,
        
        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [boolean]$ContinueOnError = $false
    )
    Begin {
        ## read config data
        [Xml.XmlElement]$xmlConfigNxtNullsoft = $xmlConfig.NxtNullsoft_Options
        [string]$ConfigNxtNullsoftInstallParams = $ExecutionContext.InvokeCommand.ExpandString($xmlConfigNxtNullsoft.NxtNullsoft_InstallParams)
        [string]$ConfigNxtNullsoftUninstallParams = $ExecutionContext.InvokeCommand.ExpandString($xmlConfigNxtNullsoft.NxtNullsoft_UninstallParams)
        [string]$ConfigNxtNullsoftLogPath = $ExecutionContext.InvokeCommand.ExpandString($xmlConfigNxtNullsoft.NxtNullsoft_LogPath)

		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
    Process {

        [string]$innoUninstallKey = $UninstallKey
   
        switch ($Action) {
            'Install' {
                $InnoSetupDefaultParams = $ConfigNxtNullsoftInstallParams

        		## If the Setup File is in the Files directory, set the full path during an installation
				If (Test-Path -LiteralPath (Join-Path -Path $dirFiles -ChildPath $path -ErrorAction 'SilentlyContinue') -PathType 'Leaf' -ErrorAction 'SilentlyContinue') {
					[string]$innoSetupPath = Join-Path -Path $dirFiles -ChildPath $path
				}
				ElseIf (Test-Path -LiteralPath $Path -ErrorAction 'SilentlyContinue') {
					[string]$innoSetupPath = (Get-Item -LiteralPath $Path).FullName
				}
				Else {
					Write-Log -Message "Failed to find installation file [$path]." -Severity 3 -Source ${CmdletName}
					If (-not $ContinueOnError) {
						Throw "Failed to find installation file [$path]."
					}
					Continue
				}
            }
            'Uninstall' {
                $InnoSetupDefaultParams = $ConfigNxtNullsoftUninstallParams
                $InstalledAppResults = Get-InstalledApplication -ProductCode $innoUninstallKey -Exact -ErrorAction 'SilentlyContinue'
    
                if (!$InstalledAppResults) {
                    Write-Log -Message "No Application with UninstallKey `"$innoUninstallKey`" found. Skipping action [$Action]..." -Source ${CmdletName}
					return
                }
    
                [string]$innoUninstallString = $InstalledAppResults.UninstallString
    
                ## check for and remove quotation marks around the uninstall string
                if ($innoUninstallString.StartsWith('"')) {
                    [string]$innoSetupPath = $innoUninstallString.Substring(1, $innoUninstallString.IndexOf('"', 1) - 1)
                }
                else {
                    [string]$innoSetupPath = $innoUninstallString.Substring(0, $innoUninstallString.IndexOf('.exe', [System.StringComparison]::CurrentCultureIgnoreCase) + 4)
                }
				
				## Get the parent folder of the uninstallation file
				[string]$UninsFolder = split-path $innoSetupPath -Parent

				## If the uninstall file does not exist, restore it from $App, if it exists there
				if (![System.IO.File]::Exists($innoSetupPath) -and ($true -eq (Get-Item "$App\neoSource\unins[0-9][0-9][0-9].exe"))) {
					Write-Log -Message "Uninstall file not found. Restoring it from backup..." -Source ${CmdletName}
					Remove-File -Path "$UninsFolder\unins*.*"
					Copy-File -Path "$App\neoSource\unins[0-9][0-9][0-9].*" -Destination "$UninsFolder\"	
				}

				## If any "$UninsFolder\unins[0-9][0-9][0-9].exe" exists, use the one with the highest number
				If ($true -eq (Get-Item "$UninsFolder\unins[0-9][0-9][0-9].exe")) {
					[string]$innoSetupPath = Get-Item "$UninsFolder\unins[0-9][0-9][0-9].exe" | Select-Object -last 1 -ExpandProperty FullName
					Write-Log -Message "Uninstall file set to: `"$innoSetupPath`"." -Source ${CmdletName}
				}

				## If $innoSetupPath is still unexistend, write Error to log and abort
				if (![System.IO.File]::Exists($innoSetupPath)) {
                    Write-Log -Message "Uninstallation file could not be found nor restored." -Severity 3 -Source ${CmdletName}

                    if ($ContinueOnError) {
						## Uninstallation without uninstallation file is impossible --> Abort the function without error
                        return
                    }
                    else {
                        throw "Uninstallation file could not be found nor restored."
                    }
                }

            }
        }
    
        [string]$argsInnoSetup = $InnoSetupDefaultParams
    
        ## Replace default parameters if specified.
        If ($Parameters) {
            $argsInnoSetup = $Parameters
        }
        ## Append parameters to default parameters if specified.
        If ($AddParameters) {
            $argsInnoSetup = "$argsInnoSetup $AddParameters"
        }

        ## MergeTasks if parameters were not replaced
        if ((-not($Parameters)) -and (-not([string]::IsNullOrWhiteSpace($MergeTasks)))) {
            $argsInnoSetup += " /MERGETASKS=`"$MergeTasks`""
        }
    
        [string]$fullLogPath = $null

        ## Logging
        if ([string]::IsNullOrWhiteSpace($Log)) {
            ## create Log file name if non is specified
            if ($Action -eq 'Install') {
				[string]$Log = "Install_$($Path -replace ' ',[string]::Empty)_$timestamp"
            }
            else {
                [string]$Log = "Uninstall_$($InstalledAppResults.DisplayName -replace ' ',[string]::Empty)_$timestamp"
            }
        }

        [string]$LogFileExtension = [System.IO.Path]::GetExtension($Log)

        ## Append file extension if necessary
        if (($LogFileExtension -ne '.txt') -and ($LogFileExtension -ne '.log')) {
            $Log = $Log + '.log'
        }

        ## Check, if $Log is a full path
        if (-not($Log.Contains('\'))) {
            $fullLogPath = Join-Path -Path $ConfigNxtNullsoftLogPath -ChildPath $($Log -replace ' ',[string]::Empty)
        }
        else {
            $fullLogPath = $Log
        }

        $argsInnoSetup = "$argsInnoSetup /LOG=`"$fullLogPath`""
    
        [hashtable]$ExecuteProcessSplat = @{
            Path             = $innoSetupPath
            Parameters       = $argsInnoSetup
            WindowStyle      = 'Normal'
        }
        
        If ($ContinueOnError) {
            $ExecuteProcessSplat.Add('ContinueOnError', $ContinueOnError)
        }
        If ($PassThru) {
            $ExecuteProcessSplat.Add('PassThru', $PassThru)
        }
    
        If ($PassThru) {
            [psobject]$ExecuteResults = Execute-Process @ExecuteProcessSplat
        }
        Else {
            Execute-Process @ExecuteProcessSplat
        }
    
        ## Update the desktop (in case of changed or added enviroment variables)
        Update-Desktop

		## Copy uninstallation file from $UninsFolder to $App after a successful installation
		if ($Action -eq 'Install') {
			$InstalledAppResults = Get-InstalledApplication -ProductCode $innoUninstallKey -Exact -ErrorAction 'SilentlyContinue'
    
			if (!$InstalledAppResults) {
				Write-Log -Message "No Application with UninstallKey `"$innoUninstallKey`" found. Skipping [copy uninstallation files to backup]..." -Source ${CmdletName}
			}
			Else {
				[string]$innoUninstallString = $InstalledAppResults.UninstallString

				## check for and remove quotation marks around the uninstall string
				if ($innoUninstallString.StartsWith('"')) {
					[string]$innoUninstallPath = $innoUninstallString.Substring(1, $innoUninstallString.IndexOf('"', 1) - 1)
				}
				else {
					[string]$innoUninstallPath = $innoUninstallString.Substring(0, $innoUninstallString.IndexOf('.exe', [System.StringComparison]::CurrentCultureIgnoreCase) + 4)
				}
				
				## Get the parent folder of the uninstallation file
				[string]$UninsFolder = split-path $innoUninstallPath -Parent

				## Actually copy the uninstallation file, if it exists
				If ($true -eq (Get-Item "$UninsFolder\unins[0-9][0-9][0-9].exe")) {
					Write-Log -Message "Copy uninstallation files to backup..." -Source ${CmdletName}
					Copy-File -Path "$UninsFolder\unins[0-9][0-9][0-9].*" -Destination "$App\neoSource\"	
				}
				Else {
					Write-Log -Message "Uninstall file not found. Skipping [copy of uninstallation files to backup]..." -Source ${CmdletName}
				}
			}
		}
    }
    End {
		If ($PassThru) {
            Write-Output -InputObject $ExecuteResults
        }

		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
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
