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

#region Function Set-PackageArchitecture
Function Set-PackageArchitecture {
<#
.SYNOPSIS
	Sets variables depending on the $appArch value and the system architecture.
.DESCRIPTION
	Sets variables (e.g. $ProgramFilesDir[x86], $CommonFilesDir[x86], $System, $Wow6432Node) that are depending on the $appArch (x86, x64 or *) value and the system architecture (AMD64 or x86).
.EXAMPLE
	Set-PackageArchitecture
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
            If ($appArch -ine 'x86' -and $appArch -ine 'x64' -and $appArch -ine '*') {
                [int32]$mainExitCode = 70001
	            [string]$mainErrorMessage = 'ERROR: The value of $appArch arch must be set to "x86", "x64" or "*". Abort!'
	            Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	            Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	            Exit-Script -ExitCode $mainExitCode
                }
            ElseIf ($appArch -ieq 'x64' -and $env:PROCESSOR_ARCHITECTURE -ieq 'x86') {
                [int32]$mainExitCode = 70001
	            [string]$mainErrorMessage = 'ERROR: This software package can only be installed on 64 bit Windows systems. Abort!'
	            Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	            Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	            Exit-Script -ExitCode $mainExitCode
            }
            ElseIf ($appArch -ieq 'x86' -and $env:PROCESSOR_ARCHITECTURE -ieq 'AMD64') {
                [string]$global:ProgramFilesDir = ${env:ProgramFiles(x86)}
                [string]$global:ProgramFilesDirx86 = ${env:ProgramFiles(x86)}
                [string]$global:CommonFilesDir = ${env:CommonProgramFiles(x86)}
                [string]$global:CommonFilesDirx86 = ${env:CommonProgramFiles(x86)}
                [string]$global:System = "${env:SystemRoot}\SysWOW64"
                [string]$global:Wow6432Node = '\Wow6432Node'
            }
            ElseIf (($appArch -ieq 'x86' -or $appArch -ieq '*') -and $env:PROCESSOR_ARCHITECTURE -ieq 'x86') {
                [string]$global:ProgramFilesDir = ${env:ProgramFiles}
                [string]$global:ProgramFilesDirx86 = ${env:ProgramFiles}
                [string]$global:CommonFilesDir = ${env:CommonProgramFiles}
                [string]$global:CommonFilesDirx86 = ${env:CommonProgramFiles}
                [string]$global:System = "${env:SystemRoot}\System32"
                [string]$global:Wow6432Node = ''
            }
            Else {
                [string]$global:ProgramFilesDir = ${env:ProgramFiles}
                [string]$global:ProgramFilesDirx86 = ${env:ProgramFiles(x86)}
                [string]$global:CommonFilesDir = ${env:CommonProgramFiles}
                [string]$global:CommonFilesDirx86 = ${env:CommonProgramFiles(x86)}
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

#region Function Uninstall-Old
Function Uninstall-Old {
<#
.SYNOPSIS
	Uninstalls old package versions if $UninstallOld = '1'.
.DESCRIPTION
	If $UninstallOld is set to '1', the function checks for old versions of the same package (same $UninstallKeyName) and uninstalls them.
.EXAMPLE
	Uninstall-Old
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
        Write-Log -Message "Checking if old packages need to be uninstalled..." -Source ${cmdletName}
		Try {
            If (Test-RegistryValue -Key HKLM\Software\Wow6432Node\neoPackages\$uninstallKeyName -Value 'UninstallString') {
                [string]$regUninstallKeyName = "HKLM\Software\Wow6432Node\neoPackages\$uninstallKeyName"
            }
            Else {
                [string]$regUninstallKeyName = "HKLM\Software\neoPackages\$uninstallKeyName"
            }
            If ($UninstallOld -ieq '1' -and (Get-RegistryKey -Key $regUninstallKeyName -Value 'Version') -ilt $appVersion -and (Test-RegistryValue -Key $regUninstallKeyName -Value 'UninstallString')) {
                Write-Log -Message "$uninstallOld is set to '1' and an old package version was found: Uninstalling old package..." -Source ${cmdletName}
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
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion

#region Function Register-NxtPackage
Function Register-NxtPackage {
<#
.SYNOPSIS
	Copies package files and registers the package in the registry.
.DESCRIPTION
	Copies the package files to "$APP\neoInstall\" and writes the package's registry keys under "HKLM\Software[\Wow6432Node]\neoPackages\$UninstallKeyName" and "HKLM\Software[\Wow6432Node]\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName".
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
	}
	Process {
        Write-Log -Message "Registering package..." -Source ${cmdletName}
		Try {
            Copy-File -Path "$src\AppDeployToolkit" -Destination "$app\neoInstall\" -Recurse
		    Copy-File -Path "$src\Deploy-Application.exe" -Destination "$app\neoInstall\"
		    Copy-File -Path "$src\Deploy-Application.exe.config" -Destination "$app\neoInstall\"
		    Copy-File -Path "$src\Deploy-Application.ps1" -Destination "$app\neoInstall\"

		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'AppPath' -Value $app
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'Date' -Value (Get-Date -format "yyyy-MM-dd HH:mm:ss")
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'DebugLogFile' -Value $configToolkitLogDir\$logName
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'DeveloperName' -Value $appVendor
		    # Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'PackageStatus' -Value '$PackageStatus'
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'ProductName' -Value $appName
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'ReturnCode (%ERRORLEVEL%)' -Value $mainExitCode
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'Revision' -Value $appRevision
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'SrcPath' -Value $src
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'StartupProcessor_Architecture' -Value $envArchitecture
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'StartupProcessOwner' -Value $envUserDomain\$envUserName
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'StartupProcessOwnerSID' -Value $ProcessNTAccountSID
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'UninstallOld' -Type 'Dword' -Value $UninstallOld
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'UninstallString' -Value ('"' + $app + '\neoInstall\Deploy-Application.exe"','uninstall')
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'UserPart' -Value $UserPart -Type 'DWord'
            If ($userPart -ieq '1') {
                Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'UserPartPath' -Value ('"' + $app + '\neo42-Uerpart"')
		        Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'UserPartUninstPath' -Value ('"%AppData%\neoPackages\' + $uninstallKeyName + '"')
		        Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'UserPartRevision' -Value $userPartRevision
            }
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'Version' -Value $appVersion

		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'DisplayIcon' -Value $uninstallDisplayIcon
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'DisplayName' -Value $uninstallDisplayName
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'DisplayVersion' -Value $appVersion
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'MachineKeyName' -Value ('neoPackages\' + $uninstallKeyName)
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'NoModify' -Type 'Dword' -Value '1'
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'NoRemove' -Type 'Dword' -Value $hidePackageUninstallButton
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'NoRepair' -Type 'Dword' -Value '1'
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'PackageApplicationDir' -Value $app
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'PackageProductName' -Value $appName
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'PackageRevision' -Value $appRevision
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'Publisher' -Value $appVendor
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'SystemComponent' -Type 'Dword' -Value $hidePackageUninstallEntry
		    Set-RegistryKey -Key HKLM\Software$Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName -Name 'UninstallString' -Type 'ExpandString' -Value ('"' + $app + '\neoInstall\Deploy-Application.exe"','uninstall')
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
	Removes the package files from "$APP\neoInstall\" and deletes the package's registry keys under "HKLM\Software[\Wow6432Node]\neoPackages\$UninstallKeyName" and "HKLM\Software[\Wow6432Node]\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKeyName".
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
            Copy-File -Path "$PSScriptRoot\CleanUp.cmd" -Destination "$app\"
            Start-Sleep 1
		    Execute-Process -Path "$APP\CleanUp.cmd" -NoWait
		    Remove-RegistryKey -Key HKLM\Software$global:Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$uninstallKeyName
		    Remove-RegistryKey -Key HKLM\Software$global:Wow6432Node\neoPackages\$uninstallKeyName
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

##*===============================================
##* END FUNCTION LISTINGS
##*===============================================

##*===============================================
##* SCRIPT BODY
##*===============================================

If ($scriptParentPath) {
	Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] dot-source invoked by [$(((Get-Variable -Name MyInvocation).Value).ScriptName)]" -Source $appDeployToolkitExtName
} Else {
	Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] invoked directly" -Source $appDeployToolkitExtName
}

##*===============================================
##* END SCRIPT BODY
##*===============================================
