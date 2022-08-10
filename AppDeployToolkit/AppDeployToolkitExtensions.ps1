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
			If ($currentArch -ine 'x86' -and $currentArch -ine 'x64' -and $currentArch -ine '*') {
				[int32]$mainExitCode = 70001
				[string]$mainErrorMessage = 'ERROR: The value of $appArch arch must be set to "x86", "x64" or "*". Abort!'
				Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
				Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
				Exit-Script -ExitCode $mainExitCode
			}
			ElseIf ($currentArch -ieq 'x64' -and $env:PROCESSOR_ARCHITECTURE -ieq 'x86') {
				[int32]$mainExitCode = 70001
				[string]$mainErrorMessage = 'ERROR: This software package can only be installed on 64 bit Windows systems. Abort!'
				Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
				Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
				Exit-Script -ExitCode $mainExitCode
			}
			ElseIf ($currentArch -ieq 'x86' -and $env:PROCESSOR_ARCHITECTURE -ieq 'AMD64') {
				[string]$global:ProgramFilesDir = ${env:ProgramFiles(x86)}
				[string]$global:ProgramFilesDirx86 = ${env:ProgramFiles(x86)}
				[string]$global:CommonFilesDir = ${env:CommonProgramFiles(x86)}
				[string]$global:CommonFilesDirx86 = ${env:CommonProgramFiles(x86)}
				[string]$global:System = "${env:SystemRoot}\SysWOW64"
				[string]$global:Wow6432Node = '\Wow6432Node'
			}
			ElseIf (($currentArch -ieq 'x86' -or $currentArch -ieq '*') -and $env:PROCESSOR_ARCHITECTURE -ieq 'x86') {
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

#region Function Uninstall-NxtOld
Function Uninstall-NxtOld {
	<#
	.SYNOPSIS
		Uninstalls old package versions if $UninstallOld = '1'.
	.DESCRIPTION
		If $UninstallOld is set to '1', the function checks for old versions of the same package (same $UninstallKeyName) and uninstalls them.
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
		Write-Log -Message "Checking if old packages need to be uninstalled..." -Source ${cmdletName}
		Try {
			If (Test-RegistryValue -Key HKLM\Software\Wow6432Node\neoPackages\$uninstallKeyName -Value 'UninstallString') {
				[string]$regUninstallKeyName = "HKLM\Software\Wow6432Node\neoPackages\$uninstallKeyName"
			}
			Else {
				[string]$regUninstallKeyName = "HKLM\Software\neoPackages\$uninstallKeyName"
			}
			If (($true -eq $uninstallOld) -and (Get-RegistryKey -Key $regUninstallKeyName -Value 'Version') -ilt $appVersion -and (Test-RegistryValue -Key $regUninstallKeyName -Value 'UninstallString')) {
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
			Set-RegistryKey -Key HKLM\Software$Wow6432Node\neoPackages\$UninstallKeyName -Name 'UninstallString' -Value ('"' + $app + '\neoInstall\Deploy-Application.exe"', 'uninstall')
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

#region Remove-NxtLocalGroupMember
function Remove-NxtLocalGroupMember {
	<#
	.DESCRIPTION
		Removes a member from the given group by name.
		Returns $null if the group was not found.
	.EXAMPLE
		Remove-NxtLocalGroupMember -GroupName "Administrators" -MemberName "Dummy"
	.PARAMETER GroupName
		Name of the target group
	.PARAMETER MemberName
		Name of the member to remove
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
			$MemberName
		)
		Begin {
			## Get the name of this function and write header
			[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		}
		Process {
			try {
				[bool]$groupExists = ([ADSI]::Exists("WinNT://$($env:COMPUTERNAME)/$GroupName"))
				if($groupExists){
					[System.DirectoryServices.DirectoryEntry]$group = [ADSI]"WinNT://$($env:COMPUTERNAME)/$GroupName,group"
					foreach($member in $group.psbase.Invoke("Members"))
					{
						[string]$name = $member.GetType().InvokeMember("Name", 'GetProperty', $Null, $member, $Null)
						if($name -eq $MemberName)
						{
							$group.Remove($($member.GetType().InvokeMember("Adspath", 'GetProperty', $Null, $member, $Null)))
							Write-Output $true
							return
						}
					}
					Write-Output $false
					
				}
				else{
					Write-Output $null
				}
			}
			catch {
				Write-Log -Message "Failed to remove $MemberName from $GroupName. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
				Write-Output $null
			}
		}
		End {
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
		}
}

#endregion

#region Remove-NxtLocalGroupMembers
function Remove-NxtLocalGroupMembers {
	<#
	.DESCRIPTION
		Removes a type of member from the given group by name.
		Returns the amount of members removed.
		Returns $null if the groups was not found.
	.EXAMPLE
		Remove-NxtLocalGroupMembers -GroupName "Users" All
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
			[Parameter(ParameterSetName='-Users', Mandatory=$false)]
			[Switch]
			$Users,
			[Parameter(ParameterSetName='-Groups', Mandatory=$false)]
			[Switch]
			$Groups,
			[Parameter(ParameterSetName='-All', Mandatory=$false)]
			[Switch]
			$All
		)
		Begin {
			## Get the name of this function and write header
			[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
			Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		}
		Process {
			try {
				[bool]$groupExists = ([ADSI]::Exists("WinNT://$($env:COMPUTERNAME)/$GroupName"))
				if($groupExists){
					[int]$count = 0
					[System.DirectoryServices.DirectoryEntry]$group = [ADSI]"WinNT://$($env:COMPUTERNAME)/$GroupName,group"
					foreach($member in $group.psbase.Invoke("Members"))
					{
						$class = $member.GetType().InvokeMember("Class", 'GetProperty', $Null, $member, $Null)
						if($All){
							$group.Remove($($member.GetType().InvokeMember("Adspath", 'GetProperty', $Null, $member, $Null)))
							$count++
						}
						elseif($Users){
							if($class -eq "user"){
								$group.Remove($($member.GetType().InvokeMember("Adspath", 'GetProperty', $Null, $member, $Null)))
								$count++
							}
						}
						elseif($Groups){
							if($class -eq "group"){
								$group.Remove($($member.GetType().InvokeMember("Adspath", 'GetProperty', $Null, $member, $Null)))
								$count++
							}
						}
					}
					Write-Output $count
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
