<#
.SYNOPSIS
	This script is a template that allows you to extend the toolkit with your own custom functions.
	The "*-Nxt*" function name pattern is used by "neo42 GmbH" to avoid naming conflicts with the built-in functions of the toolkit.
    # LICENSE #
    PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
    Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
    This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
    You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is automatically dot-sourced by the AppDeployToolkitMain.ps1 script.
.NOTES
	Version: ##REPLACEVERSION##
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
[string]$appDeployExtScriptVersion = [string]'##REPLACEVERSION##'
[hashtable]$appDeployExtScriptParameters = $PSBoundParameters
[string]$extensionCsPath = "$scriptRoot\AppDeployToolkitExtensions.cs"
if (-not ([Management.Automation.PSTypeName]'PSADTNXT.Extensions').Type) {
	if (Test-Path -Path $extensionCsPath) {
		Add-Type -Path $extensionCsPath -IgnoreWarnings -ErrorAction 'Stop'
	}
	else {
		throw "File not found: $extensionCsPath"
	}
}

##*===============================================
##* FUNCTION LISTINGS
##*===============================================
#region Function Add-NxtContent
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
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
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
	}
	Process {
		[String]$intEncoding = $Encoding
		if (!(Test-Path -Path $Path) -and ($true -eq [String]::IsNullOrEmpty($intEncoding))) {
			[String]$intEncoding = "UTF8"
		}
		elseif ((Test-Path -Path $Path) -and ($true -eq [String]::IsNullOrEmpty($intEncoding))) {
			try {
				[hashtable]$getFileEncodingParams = @{
					Path = $Path
				}
				if ($false -eq [string]::IsNullOrEmpty($DefaultEncoding)) {
					[string]$getFileEncodingParams['DefaultEncoding'] = $DefaultEncoding
				}
				[string]$intEncoding = (Get-NxtFileEncoding @getFileEncodingParams)
				if ($intEncoding -eq "UTF8") {
					[bool]$noBOMDetected = $true
				}
				elseif ($intEncoding -eq "UTF8withBom") {
					[bool]$noBOMDetected = $false
					[string]$intEncoding = "UTF8"
				}
			}
			catch {
				[string]$intEncoding = "UTF8"
			}
		}
		try {
			[hashtable]$contentParams = @{
				Path  = $Path
				Value = $Value
			}
			if ($false -eq [string]::IsNullOrEmpty($intEncoding)) {
				[string]$contentParams['Encoding'] = $intEncoding 
			}
			if ($noBOMDetected -and ($intEncoding -eq "UTF8")) {
				[System.IO.File]::AppendAllLines($Path, $Content)
			}
			else {
				Add-Content @contentParams
			}
			Write-Log -Message "Add content to the file '$Path'." -Source ${cmdletName}		
		}
		catch {
			Write-Log -Message "Failed to add content to the file '$Path'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Add-NxtLocalGroup
function Add-NxtLocalGroup {
	<#
	.DESCRIPTION
		Creates a local group with the given parameter.
		If group already exists only the description parameter is processed.
	.PARAMETER GroupName
		Name of the group.
	.PARAMETER Computername
		Name of the Computer,
		Defaults to $env:COMPUTERNAME.
	.PARAMETER Description
		Description for the new group.
	.EXAMPLE
		Add-NxtLocalGroup -GroupName "TestGroup"
	.OUTPUTS
		System.Boolean.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$GroupName,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Description,
		[Parameter(Mandatory = $false)]
		[string]
		$COMPUTERNAME = $env:COMPUTERNAME
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[System.DirectoryServices.DirectoryEntry]$adsiObj = [ADSI]"WinNT://$COMPUTERNAME"
			[bool]$groupExists = Test-NxtLocalGroupExists -GroupName $GroupName
			if ($false -eq $groupExists) {
				[System.DirectoryServices.DirectoryEntry]$objGroup = $adsiObj.Create("Group", $GroupName)
				$objGroup.SetInfo()
			}
			else {
				[System.DirectoryServices.DirectoryEntry]$objGroup = [ADSI]"WinNT://$COMPUTERNAME/$GroupName,group"
			}
			if (-NOT [string]::IsNullOrEmpty($Description)) {
				$objGroup.Put("Description", $Description)
				$objGroup.SetInfo()
			}
			Write-Output $true
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
#region Function Add-NxtLocalGroupMember
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
	.PARAMETER Computername
		Name of the Computer,
		Defaults to $env:COMPUTERNAME.
	.EXAMPLE
		Add-NxtLocalGroupMember -GroupName "TestGroup" -MemberName "TestUser" -MemberType "User"
	.OUTPUTS
		System.Boolean.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$GroupName,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$MemberName,
		[Parameter(Mandatory = $true)]
		[ValidateSet('Group', 'User')]
		[string]
		$MemberType,
		[Parameter(Mandatory = $false)]
		[string]
		$COMPUTERNAME = $env:COMPUTERNAME
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[bool]$groupExists = Test-NxtLocalGroupExists -GroupName $GroupName
			if ($false -eq $groupExists) {
				Write-Output $false
				return
			}
			[System.DirectoryServices.DirectoryEntry]$targetGroup = [ADSI]"WinNT://$COMPUTERNAME/$GroupName,group"
			if ($MemberType -eq "Group") {
				[bool]$groupExists = Test-NxtLocalGroupExists -GroupName $MemberName
				if ($false -eq $groupExists) {
					Write-Output $false
					return
				}
				[System.DirectoryServices.DirectoryEntry]$memberGroup = [ADSI]"WinNT://$COMPUTERNAME/$MemberName,group"
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
				[System.DirectoryServices.DirectoryEntry]$memberUser = [ADSI]"WinNT://$COMPUTERNAME/$MemberName,user"
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
#region Function Add-NxtLocalUser
function Add-NxtLocalUser {
	<#
	.DESCRIPTION
		Creates a local user with the given parameter.
		If the user already exists only FullName, Description, SetPwdExpired and SetPwdNeverExpires are processed.
	.PARAMETER UserName
		Name of the user.
	.PARAMETER Password
		Password for the new user.
	.PARAMETER FullName
		Full name of the user.
	.PARAMETER Description
		Description for the new user.
	.PARAMETER SetPwdExpired
		If set the user has to change the password at first logon.
	.PARAMETER SetPwdNeverExpires
		If set the password is set to not expire.
	.PARAMETER Computername
		Name of the Computer,
		Defaults to $env:COMPUTERNAME.
	.EXAMPLE
		Add-NxtLocalUser -UserName "ServiceUser" -Password "123!abc" -Description "User to run service" -SetPwdNeverExpires
	.OUTPUTS
		System.Boolean.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	Param (
		[Parameter(ParameterSetName = 'Default', Mandatory = $true)]
		[Parameter(ParameterSetName = 'SetPwdNeverExpires', Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$UserName,
		[Parameter(ParameterSetName = 'Default', Mandatory = $true)]
		[Parameter(ParameterSetName = 'SetPwdNeverExpires', Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Password,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$FullName,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Description,
		[Parameter(ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[switch]
		$SetPwdExpired,
		[Parameter(ParameterSetName = 'SetPwdNeverExpires', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[switch]
		$SetPwdNeverExpires,
		[Parameter(Mandatory = $false)]
		[string]
		$COMPUTERNAME = $env:COMPUTERNAME
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[System.DirectoryServices.DirectoryEntry]$adsiObj = [ADSI]"WinNT://$COMPUTERNAME"
			[bool]$userExists = Test-NxtLocalUserExists -UserName $UserName
			if ($false -eq $userExists) {
				[System.DirectoryServices.DirectoryEntry]$objUser = $adsiObj.Create("User", $UserName)
				$objUser.setpassword($Password)
				$objUser.SetInfo()
			}
			else {
				[System.DirectoryServices.DirectoryEntry]$objUser = [ADSI]"WinNT://$COMPUTERNAME/$UserName,user"
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
			Write-Output $true
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
#region Function Compare-NxtVersion
function Compare-NxtVersion {
	<#
	.DESCRIPTION
		Compares two versions.

	    Return values:
			Equal = 1
   			Update = 2
   			Downgrade = 3.
	.PARAMETER DetectedVersion
		Currently installed Version.
	.PARAMETER TargetVersion
		The new Version.
	.OUTPUTS
		PSADTNXT.VersionCompareResult.
	.EXAMPLE
		Compare-NxtVersion -DetectedVersion "1.7" -TargetVersion "1.7.2"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[string]
		$DetectedVersion,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$TargetVersion
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ([string]::IsNullOrEmpty($DetectedVersion)) {
			[string]$DetectedVersion = "0"
		}
		try {
			[scriptblock]$parseVersion = { Param ($version) 	
				[int[]]$result = 0, 0, 0, 0
				[System.Array]$versionParts = [System.Linq.Enumerable]::ToArray([System.Linq.Enumerable]::Select($Version.Split('.'), [Func[string, PSADTNXT.VersionKeyValuePair]] { Param ($x) New-Object PSADTNXT.VersionKeyValuePair -ArgumentList $x, ([System.Linq.Enumerable]::ToArray([System.Linq.Enumerable]::Select($x.ToCharArray(), [System.Func[char, PSADTNXT.VersionPartInfo]] { Param ($x) New-Object -TypeName "PSADTNXT.VersionPartInfo" -ArgumentList $x }))) }))
				for ([int]$i = 0; $i -lt $versionParts.count; $i++) {
					[int]$versionPartValue = 0
					[System.Object]$pair = [System.Linq.Enumerable]::ElementAt($versionParts, $i)
					if ([System.Linq.Enumerable]::All($pair.Value, [System.Func[PSADTNXT.VersionPartInfo, bool]] { Param ($x) [System.Char]::IsDigit($x.Value) })) {
						[int]$versionPartValue = [int]::Parse($pair.Key)
					}
					else {
						[PSADTNXT.VersionPartInfo]$value = [System.Linq.Enumerable]::FirstOrDefault($pair.Value)
						if ($null -ne $value -and [System.Char]::IsLetter($value.Value)) {
							#Important for compare (An upper 'A'==65 char must have the value 10) 
							[int]$versionPartValue = $value.AsciiValue - 55
						}
					}
					[int]$result[$i] = $versionPartValue
				}
				Write-Output (New-Object System.Version -ArgumentList $result[0], $result[1], $result[2], $result[3])
				return }.GetNewClosure()

			[System.Version]$instVersion = &$parseVersion -Version $DetectedVersion
			[System.Version]$newVersion = &$parseVersion -Version $TargetVersion
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
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Complete-NxtPackageInstallation
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
	.PARAMETER PackageGUID
		Specifies the registry key name used for the packages wrapper uninstall entry.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UserPartRevision
		Specifies the UserPartRevision for this installation
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeysToHide
		Specifies a list of UninstallKeys set by the Installer(s) in this Package, which the function will hide from the user (e.g. under "Apps" and "Programs and Features").
		Defaults to the corresponding values from the PackageConfig object.
	.PARAMETER DesktopShortcut
		Specifies, if desktop shortcuts should be copied (1/$true) or deleted (0/$false).
		Defaults to the DESKTOPSHORTCUT value from the Setup.cfg.
	.PARAMETER Wow6432Node
		Switches between 32/64 Bit Registry Keys.
		Defaults to the Variable $global:Wow6432Node populated by Set-NxtPackageArchitecture.
	.EXAMPLE
		Complete-NxtPackageInstallation
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$App = $global:PackageConfig.App,
		[Parameter(Mandatory = $false)]
		[bool]
		$UserPartOnInstallation = $global:PackageConfig.UserPartOnInstallation,
		[Parameter(Mandatory = $false)]
		[string]
		$PackageGUID = $global:PackageConfig.PackageGUID,
		[Parameter(Mandatory = $false)]
		[string]
		$UserPartRevision = $global:PackageConfig.UserPartRevision,
		[Parameter(Mandatory = $false)]
		[PSCustomObject]
		$UninstallKeysToHide = $global:PackageConfig.UninstallKeysToHide,
		[Parameter(Mandatory = $false)]
		[bool]
		$DesktopShortcut = [bool]([int]$global:SetupCfg.Options.DesktopShortcut),
		[Parameter(Mandatory = $false)]
		[string]
		$Wow6432Node = $global:Wow6432Node
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ($DesktopShortcut) {
			Copy-NxtDesktopShortcuts
		}
		else {
			Remove-NxtDesktopShortcuts
		}
		foreach ($uninstallKeyToHide in $UninstallKeysToHide) {
			[hashtable]$hideNxtParams = @{
				UninstallKey			= $uninstallKeyToHide.KeyName
				DisplayNamesToExclude	= $uninstallKeyToHide.DisplayNamesToExcludeFromHiding
			}
			if ($false -eq [string]::IsNullOrEmpty($uninstallKeyToHide.KeyNameIsDisplayName)) {
				$hideNxtParams["UninstallKeyIsDisplayName"] = $uninstallKeyToHide.KeyNameIsDisplayName
			}
			if ($false -eq [string]::IsNullOrEmpty($uninstallKeyToHide.KeyNameContainsWildCards)) {
				$hideNxtParams["UninstallKeyContainsWildCards"] = $uninstallKeyToHide.KeyNameContainsWildCards
			}
			if ($false -eq $uninstallKeyToHide.Is64Bit) {
				[bool]$thisUninstallKeyToHideIs64Bit = $false
			}
			else {
				[bool]$thisUninstallKeyToHideIs64Bit = $true
			}
			Write-Log -Message "Hiding uninstall key with KeyName [$($uninstallKeyToHide.KeyName)], Is64Bit [$thisUninstallKeyToHideIs64Bit], KeyNameIsDisplayName [$($uninstallKeyToHide.KeyNameIsDisplayName)], KeyNameContainsWildCards [$($uninstallKeyToHide.KeyNameContainsWildCards)] and DisplayNamesToExcludeFromHiding [$($uninstallKeyToHide.DisplayNamesToExcludeFromHiding -join "][")]..." -Source ${CmdletName}
			[array]$installedAppResults = Get-NxtInstalledApplication @hideNxtParams | Where-Object Is64BitApplication -eq $thisUninstallKeyToHideIs64Bit
			if ($installedAppResults.Count -eq 1) {
				[string]$wowEntry = [string]::Empty
				if ($false -eq $thisUninstallKeyToHideIs64Bit -and $true -eq $Is64Bit) {
					[string]$wowEntry = "\Wow6432Node"
				}
				Set-RegistryKey -Key "HKLM:\Software$wowEntry\Microsoft\Windows\CurrentVersion\Uninstall\$($installedAppResults.UninstallSubkey)" -Name "SystemComponent" -Type "Dword" -Value "1"
			}
		}
		if ($true -eq $UserPartOnInstallation) {
			## Userpart-Installation: Copy all needed files to "...\SupportFiles\neo42-Userpart\" and add more needed tasks per user commands to the CustomInstallUserPart*-functions inside of main script.
			Set-ActiveSetup -PurgeActiveSetupKey -Key "$PackageGUID.uninstall"
			Copy-File -Path "$dirSupportFiles\neo42-Userpart\*" -Destination "$App\neo42-Userpart\SupportFiles" -Recurse
			Copy-File -Path "$scriptRoot\$($xmlConfigFile.GetElementsByTagName('BannerIcon_Options').Icon_Filename)" -Destination "$App\neo42-Userpart\"
			Copy-item -Path "$scriptDirectory\*" -Exclude "Files", "SupportFiles" -Destination "$App\neo42-Userpart\" -Recurse -Force -ErrorAction Continue
			Write-NxtSingleXmlNode -XmlFilePath "$App\neo42-Userpart\$(Split-Path "$scriptRoot" -Leaf)\$(Split-Path "$appDeployConfigFile" -Leaf)" -SingleNodeName "//Toolkit_RequireAdmin" -Value "False"
			Write-NxtSingleXmlNode -XmlFilePath "$App\neo42-Userpart\$(Split-Path "$scriptRoot" -Leaf)\$(Split-Path "$appDeployConfigFile" -Leaf)" -SingleNodeName "//ShowBalloonNotifications" -Value "False"
			Set-ActiveSetup -StubExePath "$env:Systemroot\System32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Bypass -NoProfile -File ""$App\neo42-Userpart\Deploy-Application.ps1"" TriggerInstallUserpart" -Version $UserPartRevision -Key "$PackageGUID"
		}
		foreach ($oldAppFolder in $((Get-ChildItem -Path (Get-Item -Path $App).Parent.FullName | Where-Object Name -ne (Get-Item -Path $App).Name).FullName)) {
			## note: we always use the script from current application package source folder (it is basically identical in each package)
			Copy-File -Path "$scriptRoot\Clean-Neo42AppFolder.ps1" -Destination "$oldAppFolder\"
			Start-Sleep -Seconds 1
			Execute-Process -Path powershell.exe -Parameters "-File `"$oldAppFolder\Clean-Neo42AppFolder.ps1`"" -WorkingDirectory "$oldAppFolder" -NoWait
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Complete-NxtPackageUninstallation
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
	.PARAMETER PackageGUID
		Specifies the registry key name used for the packages wrapper uninstall entry.
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
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$App = $global:PackageConfig.App,
		[Parameter(Mandatory = $false)]
		[string]
		$PackageGUID = $global:PackageConfig.PackageGUID,
		[Parameter(Mandatory = $false)]
		[bool]
		$UserPartOnUninstallation = $global:PackageConfig.UserPartOnUninstallation,
		[Parameter(Mandatory = $false)]
		[string]
		$UserPartRevision = $global:PackageConfig.UserPartRevision
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		Remove-NxtDesktopShortcuts
		Set-ActiveSetup -PurgeActiveSetupKey -Key "$PackageGUID"
		if ($true -eq $UserPartOnUninstallation) {
			## Userpart-Uninstallation: Copy all needed files to "...\SupportFiles\neo42-Userpart\" and add more needed tasks per user commands to the CustomUninstallUserPart*-functions inside of main script.
			Copy-File -Path "$dirSupportFiles\neo42-Userpart\*" -Destination "$App\neo42-Userpart\SupportFiles" -Recurse
			Copy-File -Path "$scriptRoot\$($xmlConfigFile.GetElementsByTagName('BannerIcon_Options').Icon_Filename)" -Destination "$App\neo42-Userpart\"
			Copy-item -Path "$scriptDirectory\*" -Exclude "Files", "SupportFiles" -Destination "$App\neo42-Userpart\" -Recurse -Force -ErrorAction Continue
			Write-NxtSingleXmlNode -XmlFilePath "$App\neo42-Userpart\$(Split-Path "$scriptRoot" -Leaf)\$(Split-Path "$appDeployConfigFile" -Leaf)" -SingleNodeName "//Toolkit_RequireAdmin" -Value "False"
			Write-NxtSingleXmlNode -XmlFilePath "$App\neo42-Userpart\$(Split-Path "$scriptRoot" -Leaf)\$(Split-Path "$appDeployConfigFile" -Leaf)" -SingleNodeName "//ShowBalloonNotifications" -Value "False"
			Set-ActiveSetup -StubExePath "$env:Systemroot\System32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Bypass -NoProfile -File `"$App\neo42-Userpart\Deploy-Application.ps1`" TriggerUninstallUserpart" -Version $UserPartRevision -Key "$PackageGUID.uninstall"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Copy-NxtDesktopShortcuts
function Copy-NxtDesktopShortcuts {
	<#
	.SYNOPSIS
		By default: Copys the shortcuts defined under "CommonStartMenuShortcutsToCopyToCommonDesktop" in the neo42PackageConfig.json to the common desktop.
	.DESCRIPTION
		Is called after an installation/reinstallation if DESKTOPSHORTCUT=1 is defined in the Setup.cfg.
	.PARAMETER StartMenuShortcutsToCopyToDesktop
		Specifies the links from the start menu which should be copied to the desktop.
		Defaults to the CommonStartMenuShortcutsToCopyToCommonDesktop array defined in the Setup.cfg.
	.PARAMETER Desktop
		Specifies the path to the Desktop (eg. $envCommonDesktop or $envUserDesktop).
		Defaults to $envCommonDesktop defined in AppDeploymentToolkitMain.ps1.
	.PARAMETER StartMenu
		Specifies the path to the StartMenu (e.g. $envCommonStartMenu or $envUserStartMenu).
		Defaults to $envCommonStartMenu defined in AppDeploymentToolkitMain.ps1.
	.EXAMPLE
		Copy-NxtDesktopShortcuts
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[array]
		$StartMenuShortcutsToCopyToDesktop = $global:PackageConfig.CommonStartMenuShortcutsToCopyToCommonDesktop,
		[Parameter(Mandatory = $false)]
		[string]
		$Desktop = $envCommonDesktop,
		[Parameter(Mandatory = $false)]
		[string]
		$StartMenu = $envCommonStartMenu
	)	
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			foreach ($value in $StartMenuShortcutsToCopyToDesktop) {
				Write-Log -Message "Copying start menu shortcut'$StartMenu\$($value.Source)' to [$Desktop]..." -Source ${cmdletName}
				Copy-File -Path "$StartMenu\$($value.Source)" -Destination "$Desktop\$($value.TargetName)"
				Write-Log -Message "Shortcut succesfully copied." -Source ${cmdletName}
			}
		}
		catch {
			Write-Log -Message "Failed to copy shortcuts to [$Desktop]. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Execute-NxtBitRockInstaller
function Execute-NxtBitRockInstaller {
	<#
	.SYNOPSIS
		Executes the following actions for BitRock Installer installations: install (with UninstallKey AND installation file), uninstall (with UninstallKey).
	.DESCRIPTION
		Sets default switches to be passed to un-/installation file based on the preferences in the XML configuration file, if no Parameters are specifed.
		Can handle installation files by name in the "Files" sub directory or full paths anywhere.
	.PARAMETER Action
		The action to perform. Options: Install, Uninstall. Default is: Install.
	.PARAMETER UninstallKey
		Name of the uninstall registry key of the application (e.g. "ThisApplication").
		Can be found under "HKLM:\Software\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\".
	.PARAMETER UninstallKeyIsDisplayName
		Determines if the value given as UninstallKey should be interpreted as a displayname. Default is: $false.
	.PARAMETER UninstallKeyContainsWildCards
		Determines if the value given as UninstallKey contains WildCards. Default is: $false.
		If set to $true, "*" are interpreted as WildCards.
		If set to $false, "*" are interpreted as part of the actual string.
	.PARAMETER DisplayNamesToExclude
		DisplayName(s) to exclude, when retrieving Data about the application from the uninstall key in the registry.
		Use commas to separate more than one value.
		"*" inside this parameter will not be interpreted as WildCards. (This has no effect on the use of WildCards in other parameters!)
		We reccommend always adding "$global:PackageConfig.UninstallDisplayName" if used inside a package to exclude the current package itself, especially if combined with the "UninstallKeyContainsWildCards" parameter.
	.PARAMETER Path
		The path to the BitRock Installer installation File in case of an installation. (Not needed for "Uninstall" actions!)
	.PARAMETER Parameters
		Overrides the default parameters specified in the XML configuration file.
		Install default is: "--mode unattended --unattendedmodeui minimal".
		Uninstall default is: "--mode unattended".
	.PARAMETER AddParameters
		Adds to the default parameters specified in the XML configuration file.
		Install default is: "--mode unattended --unattendedmodeui minimal".
		Uninstall default is: "--mode unattended".
	.PARAMETER PassThru
		Returns ExitCode, STDOut, and STDErr output from the process.
	.PARAMETER AcceptedExitCodes
		Defines a list of exit codes or * for all exit codes that will be accepted for success by called setup execution.
	.PARAMETER ContinueOnError
		Continue if an error is encountered. Default is: $false.
	.PARAMETER XmlConfigNxtBitRockInstaller
		The Default Settings for BitRockInstaller.
		Defaults to $xmlConfig.NxtBitRockInstaller_Options.
	.PARAMETER DirFiles
		The Files directory specified in AppDeployToolkitMain.ps1, Defaults to $dirfiles.
	.EXAMPLE
		Execute-NxtBitRockInstaller -UninstallKey "ThisApplication" -Path "ThisApp-1.0.exe" -Parameters "--mode unattended --installer-language en"
	.EXAMPLE
		Execute-NxtBitRockInstaller -Action "Uninstall" -UninstallKey "ThisApplication"
	.EXAMPLE
		Execute-NxtBitRockInstaller -Action "Uninstall" -UninstallKey "SomeApp - Version *" -UninstallKeyIsDisplayName $true -UninstallKeyContainsWildCards $true -DisplayNamesToExclude "SomeApp - Version 1.0","SomeApp - Version 1.1",$global:PackageConfig.UninstallDisplayName
	.EXAMPLE
		Execute-NxtBitRockInstaller -Action "Uninstall" -UninstallKey "***MySuperSparklingApp***" -UninstallKeyIsDisplayName $true -UninstallKeyContainsWildCards $false
	.NOTES
		AppDeployToolkit is required in order to run this function.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[ValidateSet('Install', 'Uninstall')]
		[string]
		$Action = 'Install',
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$UninstallKey,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyIsDisplayName = $false,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyContainsWildCards = $false,
		[Parameter(Mandatory = $false)]
		[array]
		$DisplayNamesToExclude,
		[Parameter(Mandatory = $false)]
		[string]
		$Path,
		[Parameter(Mandatory = $false)]
		[string]
		$Parameters,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$AddParameters,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[switch]
		$PassThru = $false,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$AcceptedExitCodes,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[boolean]
		$ContinueOnError = $false,
		[Parameter(Mandatory = $false)]
		[Xml.XmlElement]
		$XmlConfigNxtBitRockInstaller = $xmlConfig.NxtBitRockInstaller_Options,
		[Parameter(Mandatory = $false)]
		[string]
		$DirFiles = $dirFiles
	)
	Begin {
		## read config data from AppDeployToolkitConfig.xml
        
		[string]$configNxtBitRockInstallerInstallParams = $ExecutionContext.InvokeCommand.ExpandString($XmlConfigNxtBitRockInstaller.NxtBitRockInstaller_InstallParams)
		[string]$configNxtBitRockInstallerUninstallParams = $ExecutionContext.InvokeCommand.ExpandString($XmlConfigNxtBitRockInstaller.NxtBitRockInstaller_UninstallParams)
		[string]$configNxtBitRockInstallerUninsBackupPath = $ExecutionContext.InvokeCommand.ExpandString($XmlConfigNxtBitRockInstaller.NxtBitRockInstaller_UninsBackupPath)

		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[string]$bitRockInstallerUninstallKey = $UninstallKey
		[bool]$bitRockInstallerUninstallKeyIsDisplayName = $UninstallKeyIsDisplayName
		[bool]$bitRockInstallerUninstallKeyContainsWildCards = $UninstallKeyContainsWildCards
		[array]$bitRockInstallerDisplayNamesToExclude = $DisplayNamesToExclude
		switch ($Action) {
			'Install' {
				[string]$bitRockInstallerDefaultParams = $configNxtBitRockInstallerInstallParams

				## If the Setup File is in the Files directory, set the full path during an installation
				if (Test-Path -LiteralPath (Join-Path -Path $DirFiles -ChildPath $Path -ErrorAction 'SilentlyContinue') -PathType 'Leaf' -ErrorAction 'SilentlyContinue') {
					[string]$bitRockInstallerSetupPath = Join-Path -Path $DirFiles -ChildPath $Path
				}
				elseif (Test-Path -LiteralPath $Path -ErrorAction 'SilentlyContinue') {
					[string]$bitRockInstallerSetupPath = (Get-Item -LiteralPath $Path).FullName
				}
				else {
					Write-Log -Message "Failed to find installation file [$Path]." -Severity 3 -Source ${CmdletName}
					if (-not $ContinueOnError) {
						throw "Failed to find installation file [$Path]."
					}
					Continue
				}
			}
			'Uninstall' {
				[string]$bitRockInstallerDefaultParams = $configNxtbitRockInstallerUninstallParams
				[array]$installedAppResults = Get-NxtInstalledApplication -UninstallKey $bitRockInstallerUninstallKey -UninstallKeyIsDisplayName $bitRockInstallerUninstallKeyIsDisplayName -UninstallKeyContainsWildCards $bitRockInstallerUninstallKeyContainsWildCards -DisplayNamesToExclude $bitRockInstallerDisplayNamesToExclude
				if ($installedAppResults.Count -eq 0) {
					Write-Log -Message "Found no Application with UninstallKey [$bitRockInstallerUninstallKey], UninstallKeyIsDisplayName [$bitRockInstallerUninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$bitRockInstallerUninstallKeyContainsWildCards] and DisplayNamesToExclude [$($bitRockInstallerDisplayNamesToExclude -join "][")]. Skipping action [$Action]..." -Severity 2 -Source ${CmdletName}
					return
				}
				if ($installedAppResults.Count -gt 1) {
					Write-Log -Message "Found more than one Application with UninstallKey [$bitRockInstallerUninstallKey], UninstallKeyIsDisplayName [$bitRockInstallerUninstallKeyIsDisplayName] , UninstallKeyContainsWildCards [$bitRockInstallerUninstallKeyContainsWildCards] and DisplayNamesToExclude [$($bitRockInstallerDisplayNamesToExclude -join "][")]. Skipping action [$Action]..." -Severity 2 -Source ${CmdletName}
					return
				}
				[string]$bitRockInstallerUninstallString = $installedAppResults.UninstallString
				[string]$bitRockInstallerBackupSubfolderName = $installedAppResults.UninstallSubkey
    
				## check for and remove quotation marks around the uninstall string
				if ($bitRockInstallerUninstallString.StartsWith('"')) {
					[string]$bitRockInstallerSetupPath = $bitRockInstallerUninstallString.Substring(1, $bitRockInstallerUninstallString.IndexOf('"', 1) - 1)
				}
				else {
					[string]$bitRockInstallerSetupPath = $bitRockInstallerUninstallString.Substring(0, $bitRockInstallerUninstallString.IndexOf('.exe', [System.StringComparison]::CurrentCultureIgnoreCase) + 4)
				}

				## Get parent folder and filename of the uninstallation file
				[string]$uninsFolder = Split-Path $bitRockInstallerSetupPath -Parent
				[string]$uninsFileName = Split-Path $bitRockInstallerSetupPath -Leaf

				## If the uninstall file does not exist, restore it from $configNxtBitRockInstallerUninsBackupPath, if it exists there
				if (![System.IO.File]::Exists($bitRockInstallerSetupPath) -and ($true -eq (Test-Path -Path "$configNxtBitRockInstallerUninsBackupPath\$bitRockInstallerBackupSubfolderName\$uninsFileName"))) {
					Write-Log -Message "Uninstall file not found. Restoring it from backup..." -Source ${CmdletName}
					Copy-File -Path "$configNxtBitRockInstallerUninsBackupPath\$bitRockInstallerBackupSubfolderName\unins*.*" -Destination "$uninsFolder\"	
				}

				## If $bitRockInstallerSetupPath is still unexistend, write Error to log and abort
				if (![System.IO.File]::Exists($bitRockInstallerSetupPath)) {
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
    
		[string]$argsBitRockInstaller = $bitRockInstallerDefaultParams
    
		## Replace default parameters if specified.
		if ($Parameters) {
			[string]$argsBitRockInstaller = $Parameters
		}
		## Append parameters to default parameters if specified.
		if ($AddParameters) {
			[string]$argsBitRockInstaller = "$argsBitRockInstaller $AddParameters"
		}
 
		[hashtable]$ExecuteProcessSplat = @{
			Path        = $bitRockInstallerSetupPath
			Parameters  = $argsBitRockInstaller
			WindowStyle = 'Normal'
		}
        
		if ($ContinueOnError) {
			$ExecuteProcessSplat.Add('ContinueOnError', $ContinueOnError)
		}
		if ($PassThru) {
			$ExecuteProcessSplat.Add('PassThru', $PassThru)
		}
		if (![string]::IsNullOrEmpty($AcceptedExitCodes)) {
			$ExecuteProcessSplat.Add('IgnoreExitCodes', $AcceptedExitCodes)
		}
    
		if ($PassThru) {
			[psobject]$ExecuteResults = Execute-Process @ExecuteProcessSplat
		}
		else {
			Execute-Process @ExecuteProcessSplat
		}

		if ($Action -eq 'Uninstall') {
			## Wait until all uninstallation processes are terminated or write a warning to the log if the waiting period is exceeded
			Write-Log -Message "Wait while an uninstallation process is still running..." -Source ${CmdletName}
			## wait for process 5 times, BitRock uninstaller can close and reappear several times
			for ($i = 0; $i -lt 5; $i++) {
				[bool]$result_UninstallProcess = Watch-NxtProcessIsStopped -ProcessName "_Uninstall*" -Timeout 500
				Start-Sleep 1
			}
			If ($false -eq $result_UninstallProcess) {
				Write-Log -Message "Note: an uninstallation process was still running after the waiting period of at least 500s!" -Severity 2 -Source ${CmdletName}
			} else {
				Write-Log -Message "All uninstallation processes finished." -Source ${CmdletName}
			}
		}
    
		## Update the desktop (in case of changed or added enviroment variables)
		Update-Desktop

		## Copy uninstallation file from $uninsFolder to $configNxtBitRockInstallerUninsBackupPath after a successful installation
		if ($Action -eq 'Install') {
			[array]$installedAppResults = Get-NxtInstalledApplication -UninstallKey $bitRockInstallerUninstallKey -UninstallKeyIsDisplayName $bitRockInstallerUninstallKeyIsDisplayName -UninstallKeyContainsWildCards $bitRockInstallerUninstallKeyContainsWildCards -DisplayNamesToExclude $bitRockInstallerDisplayNamesToExclude
			if ($installedAppResults.Count -eq 0) {
				Write-Log -Message "Found no Application with UninstallKey [$bitRockInstallerUninstallKey], UninstallKeyIsDisplayName [$bitRockInstallerUninstallKeyIsDisplayName] , UninstallKeyContainsWildCards [$bitRockInstallerUninstallKeyContainsWildCards] and DisplayNamesToExclude [$($bitRockInstallerDisplayNamesToExclude -join "][")]. Skipping [copy uninstallation file to backup]..." -Severity 2 -Source ${CmdletName}
			}
			elseif ($installedAppResults.Count -gt 1) {
				Write-Log -Message "Found more than one Application with UninstallKey [$bitRockInstallerUninstallKey], UninstallKeyIsDisplayName [$bitRockInstallerUninstallKeyIsDisplayName] , UninstallKeyContainsWildCards [$bitRockInstallerUninstallKeyContainsWildCards] and DisplayNamesToExclude [$($bitRockInstallerDisplayNamesToExclude -join "][")]. Skipping [copy uninstallation file to backup]..." -Severity 2 -Source ${CmdletName}
			}
			else {
				[string]$bitRockInstallerUninstallString = $installedAppResults.UninstallString

				## check for and remove quotation marks around the uninstall string
				if ($bitRockInstallerUninstallString.StartsWith('"')) {
					[string]$bitRockInstallerUninstallPath = $bitRockInstallerUninstallString.Substring(1, $bitRockInstallerUninstallString.IndexOf('"', 1) - 1)
				}
				else {
					[string]$bitRockInstallerUninstallPath = $bitRockInstallerUninstallString.Substring(0, $bitRockInstallerUninstallString.IndexOf('.exe', [System.StringComparison]::CurrentCultureIgnoreCase) + 4)
				}
				
				## Get parent folder of the uninstallation file
				[string]$uninsFolder = Split-Path $bitRockInstallerUninstallPath -Parent

				## Actually copy the uninstallation file, if it exists
				if ($true -eq (Test-Path -Path "$bitRockInstallerUninstallPath")) {
					Write-Log -Message "Copy uninstallation file to backup..." -Source ${CmdletName}
					Copy-File -Path "$uninsFolder\unins*.*" -Destination "$configNxtBitRockInstallerUninsBackupPath\$($InstalledAppResults.UninstallSubkey)\"	
				}
				else {
					Write-Log -Message "Uninstall file not found. Skipping [copy of uninstallation file to backup]..." -Source ${CmdletName}
				}
			}
		}
	}
	End {
		if ($PassThru) {
			Write-Output -InputObject $ExecuteResults
		}

		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
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
		Can be found under "HKLM:\Software\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\".
	.PARAMETER UninstallKeyIsDisplayName
		Determines if the value given as UninstallKey should be interpreted as a displayname. Default is: $false.
	.PARAMETER UninstallKeyContainsWildCards
		Determines if the value given as UninstallKey contains WildCards. Default is: $false.
		If set to $true, "*" are interpreted as WildCards.
		If set to $false, "*" are interpreted as part of the actual string.
	.PARAMETER DisplayNamesToExclude
		DisplayName(s) to exclude, when retrieving Data about the application from the uninstall key in the registry.
		Use commas to separate more than one value.
		"*" inside this parameter will not be interpreted as WildCards. (This has no effect on the use of WildCards in other parameters!)
		We reccommend always adding "$global:PackageConfig.UninstallDisplayName" if used inside a package to exclude the current package itself, especially if combined with the "UninstallKeyContainsWildCards" parameter.
	.PARAMETER Path
		The path to the Inno Setup installation File in case of an installation. (Not needed for "Uninstall" actions!)
	.PARAMETER Parameters
		Overrides the default parameters specified in the XML configuration file.
		Install default is: "/FORCEINSTALL /SILENT /SP- /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /RESTARTEXITCODE=3010".
		Uninstall default is: "/VERYSILENT /SP- /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /RESTARTEXITCODE=3010".
	.PARAMETER AddParameters
		Adds to the default parameters specified in the XML configuration file.
		Install default is: "/FORCEINSTALL /SILENT /SP- /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /RESTARTEXITCODE=3010".
		Uninstall default is: "/VERYSILENT /SP- /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /RESTARTEXITCODE=3010".
	.PARAMETER MergeTasks
		Specifies the tasks which should be done WITHOUT(!) overriding the default tasks (preselected default tasks from the setup).
		Use "!" before a task name for deselecting a specific task, otherwise it is selected.
		For specific information see: https://jrsoftware.org/ishelp/topic_setupcmdline.htm
	.PARAMETER Log
		Log file name or full path including it's name and file format (eg. '-Log "InstLogFile"', '-Log "UninstLog.txt"' or '-Log "$app\Install.$($global:DeploymentTimestamp).log"')
		If only a name is specified the log path is taken from AppDeployToolkitConfig.xml (node "NxtInnoSetup_LogPath").
		If this parameter is not specified a log name is generated automatically and the log path is again taken from AppDeployToolkitConfig.xml (node "NxtInnoSetup_LogPath").
	.PARAMETER PassThru
		Returns ExitCode, STDOut, and STDErr output from the process.
	.PARAMETER AcceptedExitCodes
		Defines a list of exit codes or * for all exit codes that will be accepted for success by called setup execution.
	.PARAMETER ContinueOnError
		Continue if an error is encountered. Default is: $false.
	.PARAMETER DeploymentTimestamp
		Timestamp used for logs (in this case if $Log is empty).
		Defaults to $global:DeploymentTimestamp.
	.PARAMETER XmlConfigNxtInnoSetup
		Contains the Default Settings for Innosetup.
		Defaults to $xmlConfig.NxtInnoSetup_Options.
	.EXAMPLE
		Execute-NxtInnoSetup -UninstallKey "This Application_is1" -Path "ThisAppSetup.exe" -AddParameters "/LOADINF=`"$dirSupportFiles\Comp.inf`"" -Log "InstallationLog"
	.EXAMPLE
		Execute-NxtInnoSetup -Action "Uninstall" -UninstallKey "This Application_is1" -Log "$app\Uninstall.$($global:deploymentTimestamp).log"
	.EXAMPLE
		Execute-NxtInnoSetup -Action "Uninstall" -UninstallKey "SomeApp - Version *" -UninstallKeyIsDisplayName $true -UninstallKeyContainsWildCards $true -DisplayNamesToExclude "SomeApp - Version 1.0","SomeApp - Version 1.1",$global:PackageConfig.UninstallDisplayName
	.EXAMPLE
		Execute-NxtInnoSetup -Action "Uninstall" -UninstallKey "***MySuperSparklingApp***" -UninstallKeyIsDisplayName $true -UninstallKeyContainsWildCards $false
	.NOTES
		AppDeployToolkit is required in order to run this function.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[ValidateSet('Install', 'Uninstall')]
		[string]
		$Action = 'Install',
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$UninstallKey,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyIsDisplayName = $false,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyContainsWildCards = $false,
		[Parameter(Mandatory = $false)]
		[array]
		$DisplayNamesToExclude,
		[Parameter(Mandatory = $false)]
		[string]
		$Path,
		[Parameter(Mandatory = $false)]
		[string]
		$Parameters,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$AddParameters,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$MergeTasks,
		[Parameter(Mandatory = $false)]
		[string]
		$Log,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[switch]
		$PassThru = $false,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$AcceptedExitCodes,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[boolean]
		$ContinueOnError = $false,
		[Parameter(Mandatory = $false)]
		[string]
		$DeploymentTimestamp = $global:DeploymentTimestamp,
		[Parameter(Mandatory = $false)]
		[Xml.XmlElement]
		$XmlConfigNxtInnoSetup = $xmlConfig.NxtInnoSetup_Options,
		[Parameter(Mandatory = $false)]
		[string]
		$DirFiles = $dirFiles
	)
	Begin {
		## read config data from AppDeployToolkitConfig.xml
		[string]$configNxtInnoSetupInstallParams = $ExecutionContext.InvokeCommand.ExpandString($XmlConfigNxtInnoSetup.NxtInnoSetup_InstallParams)
		[string]$configNxtInnoSetupUninstallParams = $ExecutionContext.InvokeCommand.ExpandString($XmlConfigNxtInnoSetup.NxtInnoSetup_UninstallParams)
		[string]$configNxtInnoSetupLogPath = $ExecutionContext.InvokeCommand.ExpandString($XmlConfigNxtInnoSetup.NxtInnoSetup_LogPath)
		[string]$configNxtInnoSetupUninsBackupPath = $ExecutionContext.InvokeCommand.ExpandString($XmlConfigNxtInnoSetup.NxtInnoSetup_UninsBackupPath)

		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[string]$innoUninstallKey = $UninstallKey
		[bool]$innoUninstallKeyIsDisplayName = $UninstallKeyIsDisplayName
		[bool]$innoUninstallKeyContainsWildCards = $UninstallKeyContainsWildCards
		[array]$innoDisplayNamesToExclude = $DisplayNamesToExclude
		switch ($Action) {
			'Install' {
				[string]$innoSetupDefaultParams = $configNxtInnoSetupInstallParams

				## If the Setup File is in the Files directory, set the full path during an installation
				if (Test-Path -LiteralPath (Join-Path -Path $DirFiles -ChildPath $path -ErrorAction 'SilentlyContinue') -PathType 'Leaf' -ErrorAction 'SilentlyContinue') {
					[string]$innoSetupPath = Join-Path -Path $DirFiles -ChildPath $path
				}
				elseif (Test-Path -LiteralPath $Path -ErrorAction 'SilentlyContinue') {
					[string]$innoSetupPath = (Get-Item -LiteralPath $Path).FullName
				}
				else {
					Write-Log -Message "Failed to find installation file [$path]." -Severity 3 -Source ${CmdletName}
					if (-not $ContinueOnError) {
						throw "Failed to find installation file [$path]."
					}
					Continue
				}
			}
			'Uninstall' {
				[string]$innoSetupDefaultParams = $configNxtInnoSetupUninstallParams
				[array]$installedAppResults = Get-NxtInstalledApplication -UninstallKey $innoUninstallKey -UninstallKeyIsDisplayName $innoUninstallKeyIsDisplayName -UninstallKeyContainsWildCard $innoUninstallKeyContainsWildCards -DisplayNamesToExclude $innoDisplayNamesToExclude
				if ($installedAppResults.Count -eq 0) {
					Write-Log -Message "Found no Application with UninstallKey [$innoUninstallKey], UninstallKeyIsDisplayName [$innoUninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$innoUninstallKeyContainsWildCards] and DisplayNamesToExclude [$($innoDisplayNamesToExclude -join "][")]. Skipping action [$Action]..." -Severity 2 -Source ${CmdletName}
					return
				}
				if ($installedAppResults.Count -gt 1) {
					Write-Log -Message "Found more than one Application with UninstallKey [$innoUninstallKey], UninstallKeyIsDisplayName [$innoUninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$innoUninstallKeyContainsWildCards] and DisplayNamesToExclude [$($innoDisplayNamesToExclude -join "][")]. Skipping action [$Action]..." -Severity 2 -Source ${CmdletName}
					return
				}
				[string]$innoUninstallString = $installedAppResults.UninstallString
				[string]$innoSetupBackupSubfolderName = $installedAppResults.UninstallSubkey
    
				## check for and remove quotation marks around the uninstall string
				if ($innoUninstallString.StartsWith('"')) {
					[string]$innoSetupPath = $innoUninstallString.Substring(1, $innoUninstallString.IndexOf('"', 1) - 1)
				}
				else {
					[string]$innoSetupPath = $innoUninstallString.Substring(0, $innoUninstallString.IndexOf('.exe', [System.StringComparison]::CurrentCultureIgnoreCase) + 4)
				}
				
				## Get the parent folder of the uninstallation file
				[string]$uninsFolder = Split-Path $innoSetupPath -Parent

				## If the uninstall file does not exist, restore it from $configNxtInnoSetupUninsBackupPath, if it exists there
				if ( (![System.IO.File]::Exists($innoSetupPath)) -and ($true -eq (Test-Path -Path "$configNxtInnoSetupUninsBackupPath\$innoSetupBackupSubfolderName\unins[0-9][0-9][0-9].exe")) ) {
					Write-Log -Message "Uninstall file not found. Restoring it from backup..." -Source ${CmdletName}
					Remove-File -Path "$uninsFolder\unins*.*"
					Copy-File -Path "$configNxtInnoSetupUninsBackupPath\$innoSetupBackupSubfolderName\unins[0-9][0-9][0-9].*" -Destination "$uninsFolder\"	
				}

				## If any "$uninsFolder\unins[0-9][0-9][0-9].exe" exists, use the one with the highest number
				if ($true -eq (Test-Path -Path "$uninsFolder\unins[0-9][0-9][0-9].exe")) {
					[string]$innoSetupPath = Get-Item "$uninsFolder\unins[0-9][0-9][0-9].exe" | Select-Object -last 1 -ExpandProperty FullName
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
    
		[string]$argsInnoSetup = $innoSetupDefaultParams
    
		## Replace default parameters if specified.
		if ($Parameters) {
			[string]$argsInnoSetup = $Parameters
		}
		## Append parameters to default parameters if specified.
		if ($AddParameters) {
			[string]$argsInnoSetup = "$argsInnoSetup $AddParameters"
		}

		## MergeTasks if parameters were not replaced
		if ((-not($Parameters)) -and (-not([string]::IsNullOrWhiteSpace($MergeTasks)))) {
			[string]$argsInnoSetup += " /MERGETASKS=`"$MergeTasks`""
		}
    
		[string]$fullLogPath = $null

		## Logging
		if ([string]::IsNullOrWhiteSpace($Log)) {
			## create Log file name if non is specified
			if ($Action -eq 'Install') {
				[string]$Log = "Install_$($Path -replace ' ',[string]::Empty)_$DeploymentTimestamp"
			}
			else {
				[string]$Log = "Uninstall_$($InstalledAppResults.DisplayName -replace ' ',[string]::Empty)_$DeploymentTimestamp"
			}
		}

		[string]$LogFileExtension = [System.IO.Path]::GetExtension($Log)

		## Append file extension if necessary
		if (($LogFileExtension -ne '.txt') -and ($LogFileExtension -ne '.log')) {
			[string]$Log = $Log + '.log'
		}

		## Check, if $Log is a full path
		if (-not($Log.Contains('\'))) {
			[string]$fullLogPath = Join-Path -Path $configNxtInnoSetupLogPath -ChildPath $($Log -replace ' ', [string]::Empty)
		}
		else {
			[string]$fullLogPath = $Log
		}

		[string]$argsInnoSetup = "$argsInnoSetup /LOG=`"$fullLogPath`""
    
		[hashtable]$ExecuteProcessSplat = @{
			Path        = $innoSetupPath
			Parameters  = $argsInnoSetup
			WindowStyle = 'Normal'
		}
        
		if ($ContinueOnError) {
			$ExecuteProcessSplat.Add('ContinueOnError', $ContinueOnError)
		}
		if ($PassThru) {
			$ExecuteProcessSplat.Add('PassThru', $PassThru)
		}
		if (![string]::IsNullOrEmpty($AcceptedExitCodes)) {
			$ExecuteProcessSplat.Add('IgnoreExitCodes', $AcceptedExitCodes)
		}
 
		if ($PassThru) {
			[psobject]$ExecuteResults = Execute-Process @ExecuteProcessSplat
		}
		else {
			Execute-Process @ExecuteProcessSplat
		}
    
		## Update the desktop (in case of changed or added enviroment variables)
		Update-Desktop

		## Copy uninstallation file from $uninsfolder to $configNxtInnoSetupUninsBackupPath after a successful installation
		if ($Action -eq 'Install') {
			[array]$installedAppResults = Get-NxtInstalledApplication -UninstallKey $innoUninstallKey -UninstallKeyIsDisplayName $innoUninstallKeyIsDisplayName -UninstallKeyContainsWildCard $innoUninstallKeyContainsWildCards -DisplayNamesToExclude $innoDisplayNamesToExclude
			if ($installedAppResults.Count -eq 0) {
				Write-Log -Message "Found no Application with UninstallKey [$innoUninstallKey], UninstallKeyIsDisplayName [$innoUninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$innoUninstallKeyContainsWildCards] and DisplayNamesToExclude [$($innoDisplayNamesToExclude -join "][")]. Skipping [copy uninstallation file to backup]..." -Severity 2 -Source ${CmdletName}
			}
			elseif ($installedAppResults.Count -gt 1) {
				Write-Log -Message "Found more than one Application with UninstallKey [$innoUninstallKey], UninstallKeyIsDisplayName [$innoUninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$innoUninstallKeyContainsWildCards] and DisplayNamesToExclude [$($innoDisplayNamesToExclude -join "][")]. Skipping [copy uninstallation file to backup]..." -Severity 2 -Source ${CmdletName}
			}
			else {
				[string]$innoUninstallString = $InstalledAppResults.UninstallString

				## check for and remove quotation marks around the uninstall string
				if ($innoUninstallString.StartsWith('"')) {
					[string]$innoUninstallPath = $innoUninstallString.Substring(1, $innoUninstallString.IndexOf('"', 1) - 1)
				}
				else {
					[string]$innoUninstallPath = $innoUninstallString.Substring(0, $innoUninstallString.IndexOf('.exe', [System.StringComparison]::CurrentCultureIgnoreCase) + 4)
				}
				
				## Get the parent folder of the uninstallation file
				[string]$uninsfolder = Split-Path $innoUninstallPath -Parent

				## Actually copy the uninstallation file, if it exists
				if ($true -eq (Test-Path -Path "$uninsfolder\unins[0-9][0-9][0-9].exe")) {
					Write-Log -Message "Copy uninstallation files to backup..." -Source ${CmdletName}
					Copy-File -Path "$uninsfolder\unins[0-9][0-9][0-9].*" -Destination "$configNxtInnoSetupUninsBackupPath\$($InstalledAppResults.UninstallSubkey)\"	
				}
				else {
					Write-Log -Message "Uninstall file not found. Skipping [copy of uninstallation files to backup]..." -Source ${CmdletName}
				}
			}
		}
	}
	End {
		if ($PassThru) {
			Write-Output -InputObject $ExecuteResults
		}

		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Execute-NxtMSI
function Execute-NxtMSI {
	<#
	.SYNOPSIS
		Wraps around the Execute-MSI Function. Executes msiexec.exe to perform the following actions for MSI & MSP files and MSI product codes: install, uninstall, patch, repair, active setup.
	.DESCRIPTION
		Executes msiexec.exe to perform the following actions for MSI & MSP files and MSI product codes: install, uninstall, patch, repair, active setup.
		If the -Action parameter is set to "Install" and the MSI is already installed, the function will exit.
		Sets default switches to be passed to msiexec based on the preferences in the XML configuration file.
		Automatically generates a log file name and creates a verbose log file for all msiexec operations.
		Expects the MSI or MSP file to be located in the "Files" sub directory of the App Deploy Toolkit. Expects transform files to be in the same directory as the MSI file.
	.PARAMETER Action
		The action to perform. Options: Install, Uninstall, Patch, Repair, ActiveSetup.
	.PARAMETER Path
		The path to the MSI/MSP file, the product code or the DisplayName of the application installed by the MSI file.
	.PARAMETER UninstallKeyIsDisplayName
		Determines if the value given as Path should be interpreted as a DisplayName. Default is: $false.
	.PARAMETER UninstallKeyContainsWildCards
		Determines if the value given as Path contains WildCards. Default is: $false.
		Works for product codes and DisplayNames only, but NOT with an actual path to the MSI/MSP file.
		If set to $true, "*" are interpreted as WildCards.
		If set to $false, "*" are interpreted as part of the actual string.
	.PARAMETER DisplayNamesToExclude
		DisplayName(s) to exclude, when retrieving Data about the application from the uninstall key in the registry.
		Use commas to separate more than one value.
		"*" inside this parameter will not be interpreted as WildCards. (This has no effect on the use of WildCards in other parameters!)
		We reccommend always adding "$global:PackageConfig.UninstallDisplayName" if used inside a package to exclude the current package itself, especially if combined with the "UninstallKeyContainsWildCards" parameter.
	.PARAMETER Transform
		The name of the transform file(s) to be applied to the MSI. The transform file is expected to be in the same directory as the MSI file. Multiple transforms have to be separated by a semi-colon.
	.PARAMETER Patch
		The name of the patch (msp) file(s) to be applied to the MSI for use with the "Install" action. The patch file is expected to be in the same directory as the MSI file. Multiple patches have to be separated by a semi-colon.
	.PARAMETER Parameters
		Overrides the default parameters specified in the XML configuration file. Install default is: "REBOOT=ReallySuppress /QB!". Uninstall default is: "REBOOT=ReallySuppress /QN".
	.PARAMETER AddParameters
		Adds to the default parameters specified in the XML configuration file. Install default is: "REBOOT=ReallySuppress /QB!". Uninstall default is: "REBOOT=ReallySuppress /QN".
	.PARAMETER SecureParameters
		Hides all parameters passed to the MSI or MSP file from the toolkit Log file.
	.PARAMETER LoggingOptions
		Overrides the default logging options specified in the XML configuration file. Default options are: "/L*v".
	.PARAMETER Log
		Sets the Log Path either as Full Path or as logname
	.PARAMETER WorkingDirectory
		Overrides the working directory. The working directory is set to the location of the MSI file.
	.PARAMETER SkipMSIAlreadyInstalledCheck
		Skips the check to determine if the MSI is already installed on the system. Default is: $false.
	.PARAMETER IncludeUpdatesAndHotfixes
		Include matches against updates and hotfixes in results.
	.PARAMETER NoWait
		Immediately continue after executing the process.
	.PARAMETER PassThru
		Returns ExitCode, STDOut, and STDErr output from the process.
	.PARAMETER IgnoreExitCodes
		List the exit codes to ignore or * to ignore all exit codes.
	.PARAMETER AcceptedExitCodes
		Defines a list of exit codes or * for all exit codes that will be accepted for success by called setup execution.
	.PARAMETER PriorityClass	
		Specifies priority class for the process. Options: Idle, Normal, High, AboveNormal, BelowNormal, RealTime. Default: Normal
	.PARAMETER ExitOnProcessFailure
		Specifies whether the function should call Exit-Script when the process returns an exit code that is considered an error/failure. Default: $true
	.PARAMETER RepairFromSource
		Specifies whether we should repair from source. Also rewrites local cache. Default: $false
	.PARAMETER ContinueOnError
		Continue if an error occurred while trying to start the process. Default: $false.
	.PARAMETER ConfigMSILogDir
		Contains the FolderPath to the centrally configured Logdirectory from psadt main.
		Defaults to $configMSILogDirc
	.EXAMPLE
		Execute-NxtMSI -Action 'Install' -Path 'Adobe_FlashPlayer_11.2.202.233_x64_EN.msi'
		Installs an MSI
	.EXAMPLE
		Execute-NxtMSI -Action 'Install' -Path 'Adobe_FlashPlayer_11.2.202.233_x64_EN.msi' -Transform 'Adobe_FlashPlayer_11.2.202.233_x64_EN_01.mst' -Parameters '/QN'
		Installs an MSI, applying a transform and overriding the default MSI toolkit parameters
	.EXAMPLE
		[psobject]$ExecuteMSIResult = Execute-NxtMSI -Action 'Install' -Path 'Adobe_FlashPlayer_11.2.202.233_x64_EN.msi' -PassThru
		Installs an MSI and stores the result of the execution into a variable by using the -PassThru option
	.EXAMPLE
		Execute-NxtMSI -Action 'Uninstall' -Path '{26923b43-4d38-484f-9b9e-de460746276c}'
		Uninstalls an MSI using a product code
	.EXAMPLE
		Execute-NxtMSI -Action 'Patch' -Path 'Adobe_Reader_11.0.3_EN.msp'
		Installs an MSP
	.NOTES
			AppDeployToolkit is required in order to run this function.
	.LINK
		http://psappdeploytoolkit.com
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[ValidateSet('Install', 'Uninstall', 'Patch', 'Repair', 'ActiveSetup')]
		[string]$Action = 'Install',
		[Parameter(Mandatory = $true, HelpMessage = 'Please enter either the path to the MSI/MSP file or the ProductCode')]
		[Alias('FilePath')]
		[string]$Path,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyIsDisplayName = $false,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyContainsWildCards = $false,
		[Parameter(Mandatory = $false)]
		[array]
		$DisplayNamesToExclude,
		[Parameter(Mandatory = $false)]
		[AllowEmptyString()]
		[ValidatePattern("\.log$|^$|^[^\\/]+$")]
		[string]
		$Log,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]$Transform,
		[Parameter(Mandatory = $false)]
		[Alias('Arguments')]
		[string]$Parameters,
		[Parameter(Mandatory = $false)]
		[string]$AddParameters,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[switch]$SecureParameters = $false,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]$Patch,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]$LoggingOptions,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]$WorkingDirectory,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[switch]$SkipMSIAlreadyInstalledCheck = $false,
		[Parameter(Mandatory = $false)]
		[switch]$IncludeUpdatesAndHotfixes = $false,
		[Parameter(Mandatory = $false)]
		[switch]$NoWait = $false,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[switch]$PassThru = $false,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]$AcceptedExitCodes,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]$IgnoreExitCodes,
		[Parameter(Mandatory = $false)]
		[ValidateSet('Idle', 'Normal', 'High', 'AboveNormal', 'BelowNormal', 'RealTime')]
		[Diagnostics.ProcessPriorityClass]$PriorityClass = 'Normal',
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ExitOnProcessFailure = $true,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$RepairFromSource = $false,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $false,
		[Parameter(Mandatory = $false)]
		[string]
		$ConfigMSILogDir = $configMSILogDir
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		[string]$xmlConfigMSIOptionsLogPath = $ExecutionContext.InvokeCommand.ExpandString($xmlConfigMSIOptions.MSI_LogPath)
		## Add all parameters with defaults to the PSBoundParameters:
		[array]$functionParametersWithDefaults = (
			"Action",
			"SecureParameters",
			"SkipMSIAlreadyInstalledCheck",
			"IncludeUpdatesAndHotfixes",
			"NoWait",
			"PassThru",
			"PriorityClass",
			"ExitOnProcessFailure",
			"RepairFromSource",
			"ContinueOnError",
			"ConfigMSILogDir"
		)
		foreach ($functionParametersWithDefault in $functionParametersWithDefaults) {
			[PSObject]$PSBoundParameters[$functionParametersWithDefault] = Get-Variable -Name $functionParametersWithDefault -ValueOnly
		}
		[array]$functionParametersToBeRemoved = (
			"Log",
			"UninstallKeyIsDisplayName",
			"UninstallKeyContainsWildCards",
			"DisplayNamesToExclude",
			"ConfigMSILogDir"
		)
		foreach ($functionParameterToBeRemoved in $functionParametersToBeRemoved) {
			$null = $PSBoundParameters.Remove($functionParameterToBeRemoved)
		}
	}
	Process {
		if (
			($UninstallKeyIsDisplayName -or $UninstallKeyContainsWildCards -or ($false -eq [string]::IsNullOrEmpty($DisplayNamesToExclude))) -and 
			$Action -eq "Uninstall"
		) {
			[array]$installedAppResults = Get-NxtInstalledApplication -UninstallKey $Path -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude
			if ($installedAppResults.Count -eq 0) {
				Write-Log -Message "Found no Application with UninstallKey [$Path], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Skipping action [$Action]..." -Severity 2 -Source ${CmdletName}
				return
			}
			elseif ($installedAppResults.Count -gt 1) {
				Write-Log -Message "Found more than one Application with UninstallKey [$Path], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Skipping action [$Action]..." -Severity 2 -Source ${CmdletName}
				return
			}
			elseif ([string]::IsNullOrEmpty($installedAppResults.ProductCode)) {
				Write-Log -Message "Found no MSI product code for the Application with UninstallKey [$Path], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Skipping action [$Action]..." -Severity 2 -Source ${CmdletName}
				return
			}
			else {
				$PSBoundParameters["Path"] = $installedAppResults.ProductCode
			}
		}
		if ([string]::IsNullOrEmpty($Parameters)) {
			$null = $PSBoundParameters.Remove('Parameters')
		}
		if ([string]::IsNullOrEmpty($AddParameters)) {
			$null = $PSBoundParameters.Remove('AddParameters')
		}
		if (![string]::IsNullOrEmpty($AcceptedExitCodes)) {
			[string]$PSBoundParameters["IgnoreExitCodes"] = "$AcceptedExitCodes"
		}
		if (![string]::IsNullOrEmpty($Log)) {
			[String]$msiLogName = ($Log | Split-Path -Leaf).TrimEnd(".log")
			$PSBoundParameters.add("LogName", $msiLogName )
		}
		Execute-MSI @PSBoundParameters
		## Move Logs to correct destination
		if ([System.IO.Path]::IsPathRooted($Log)) {
			[string]$msiLogName = "$($msiLogName.TrimEnd(".log"))_$($action).log"
			[String]$logPath = Join-Path -Path $xmlConfigMSIOptionsLogPath -ChildPath $msiLogName
			if (Test-Path -Path $logPath) {
				Move-NxtItem $logPath -Destination $Log -Force
			}
			else {
				Write-Log -Message "MSI log [$logPath] not found. Skipped moving it to [$Log]." -Severity 2 -Source ${CmdletName}
			}
		}
	}
	End {
		if ($PassThru) {
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
		Can be found under "HKLM:\Software\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\".
	.PARAMETER UninstallKeyIsDisplayName
		Determines if the value given as UninstallKey should be interpreted as a displayname. Default is: $false.
	.PARAMETER UninstallKeyContainsWildCards
		Determines if the value given as UninstallKey contains WildCards. Default is: $false.
		If set to $true, "*" are interpreted as WildCards.
		If set to $false, "*" are interpreted as part of the actual string.
	.PARAMETER DisplayNamesToExclude
		DisplayName(s) to exclude, when retrieving Data about the application from the uninstall key in the registry.
		Use commas to separate more than one value.
		"*" inside this parameter will not be interpreted as WildCards. (This has no effect on the use of WildCards in other parameters!)
		We reccommend always adding "$global:PackageConfig.UninstallDisplayName" if used inside a package to exclude the current package itself, especially if combined with the "UninstallKeyContainsWildCards" parameter.
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
	.PARAMETER AcceptedExitCodes
		Defines a list of exit codes or * for all exit codes that will be accepted for success by called setup execution.
	.PARAMETER ContinueOnError
		Continue if an error is encountered. Default is: $false.
	.PARAMETER XmlConfigNxtNullsoft
		The Default Settings for Nullsoftsetup.
		Defaults to $xmlConfig.NxtNullsoft_Options.
	.PARAMETER DirFiles
		The Files directory specified in AppDeployToolkitMain.ps1, Defaults to $dirfiles.
	.EXAMPLE
		Execute-NxtNullsoft -UninstallKey "ThisApplication" -Path "ThisApp.1.0.Installer.exe" -Parameters "SILENT=1"
	.EXAMPLE
		Execute-NxtNullsoft -Action "Uninstall" -UninstallKey "ThisApplication"
	.EXAMPLE
		Execute-NxtNullsoft -Action "Uninstall" -UninstallKey "SomeApp - Version *" -UninstallKeyIsDisplayName $true -UninstallKeyContainsWildCards $true -DisplayNamesToExclude "SomeApp - Version 1.0","SomeApp - Version 1.1",$global:PackageConfig.UninstallDisplayName
	.EXAMPLE
		Execute-NxtNullsoft -Action "Uninstall" -UninstallKey "***MySuperSparklingApp***" -UninstallKeyIsDisplayName $true -UninstallKeyContainsWildCards $false
	.NOTES
		AppDeployToolkit is required in order to run this function.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[ValidateSet('Install', 'Uninstall')]
		[string]
		$Action = 'Install',
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$UninstallKey,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyIsDisplayName = $false,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyContainsWildCards = $false,
		[Parameter(Mandatory = $false)]
		[array]
		$DisplayNamesToExclude,
		[Parameter(Mandatory = $false)]
		[string]
		$Path,
		[Parameter(Mandatory = $false)]
		[string]
		$Parameters,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$AddParameters,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[switch]
		$PassThru = $false,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$AcceptedExitCodes,
		[Parameter(Mandatory = $false)]
		[boolean]
		$ContinueOnError = $false,
		[Parameter(Mandatory = $false)]
		[Xml.XmlElement]
		$XmlConfigNxtNullsoft = $xmlConfig.NxtNullsoft_Options,
		[Parameter(Mandatory = $false)]
		[string]
		$DirFiles = $dirFiles
	)
	Begin {
		## read config data from AppDeployToolkitConfig.xml
		[string]$configNxtNullsoftInstallParams = $ExecutionContext.InvokeCommand.ExpandString($XmlConfigNxtNullsoft.NxtNullsoft_InstallParams)
		[string]$configNxtNullsoftUninstallParams = $ExecutionContext.InvokeCommand.ExpandString($XmlConfigNxtNullsoft.NxtNullsoft_UninstallParams)
		[string]$configNxtNullsoftUninsBackupPath = $ExecutionContext.InvokeCommand.ExpandString($XmlConfigNxtNullsoft.NxtNullsoft_UninsBackupPath)

		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[string]$nullsoftUninstallKey = $UninstallKey
		[bool]$nullsoftUninstallKeyIsDisplayName = $UninstallKeyIsDisplayName
		[bool]$nullsoftUninstallKeyContainsWildCards = $UninstallKeyContainsWildCards
		[array]$nullsoftDisplayNamesToExclude = $DisplayNamesToExclude
		switch ($Action) {
			'Install' {
				[string]$nullsoftDefaultParams = $configNxtNullsoftInstallParams

				## If the Setup File is in the Files directory, set the full path during an installation
				if (Test-Path -LiteralPath (Join-Path -Path $DirFiles -ChildPath $path -ErrorAction 'SilentlyContinue') -PathType 'Leaf' -ErrorAction 'SilentlyContinue') {
					[string]$nullsoftSetupPath = Join-Path -Path $DirFiles -ChildPath $path
				}
				elseif (Test-Path -LiteralPath $Path -ErrorAction 'SilentlyContinue') {
					[string]$nullsoftSetupPath = (Get-Item -LiteralPath $Path).FullName
				}
				else {
					Write-Log -Message "Failed to find installation file [$path]." -Severity 3 -Source ${CmdletName}
					if (-not $ContinueOnError) {
						throw "Failed to find installation file [$path]."
					}
					Continue
				}
			}
			'Uninstall' {
				[string]$nullsoftDefaultParams = $configNxtNullsoftUninstallParams
				[array]$installedAppResults = Get-NxtInstalledApplication -UninstallKey $nullsoftUninstallKey -UninstallKeyIsDisplayName $nullsoftUninstallKeyIsDisplayName -UninstallKeyContainsWildCards $nullsoftUninstallKeyContainsWildCards -DisplayNamesToExclude $nullsoftDisplayNamesToExclude
				if ($installedAppResults.Count -eq 0) {
					Write-Log -Message "Found no Application with UninstallKey [$nullsoftUninstallKey], UninstallKeyIsDisplayName [$nullsoftUninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$nullsoftUninstallKeyContainsWildCards] and DisplayNamesToExclude [$($nullsoftDisplayNamesToExclude -join "][")]. Skipping action [$Action]..." -Severity 2 -Source ${CmdletName}
					return
				}
				if ($installedAppResults.Count -gt 1) {
					Write-Log -Message "Found more than one Application with UninstallKey [$nullsoftUninstallKey], UninstallKeyIsDisplayName [$nullsoftUninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$nullsoftUninstallKeyContainsWildCards] and DisplayNamesToExclude [$($nullsoftDisplayNamesToExclude -join "][")]. Skipping action [$Action]..." -Severity 2 -Source ${CmdletName}
					return
				}
				[string]$nullsoftUninstallString = $installedAppResults.UninstallString
				[string]$nullsoftBackupSubfolderName = $installedAppResults.UninstallSubkey
    
				## check for and remove quotation marks around the uninstall string
				if ($nullsoftUninstallString.StartsWith('"')) {
					[string]$nullsoftSetupPath = $nullsoftUninstallString.Substring(1, $nullsoftUninstallString.IndexOf('"', 1) - 1)
				}
				else {
					[string]$nullsoftSetupPath = $nullsoftUninstallString.Substring(0, $nullsoftUninstallString.IndexOf('.exe', [System.StringComparison]::CurrentCultureIgnoreCase) + 4)
				}
				
				## Get parent folder and filename of the uninstallation file
				[string]$uninsFolder = Split-Path $nullsoftSetupPath -Parent
				[string]$uninsFileName = Split-Path $nullsoftSetupPath -Leaf

				## If the uninstall file does not exist, restore it from $configNxtNullsoftUninsBackupPath, if it exists there
				if (![System.IO.File]::Exists($nullsoftSetupPath) -and ($true -eq (Test-Path -Path "$configNxtNullsoftUninsBackupPath\$nullsoftBackupSubfolderName\$uninsFileName"))) {
					Write-Log -Message "Uninstall file not found. Restoring it from backup..." -Source ${CmdletName}
					Copy-File -Path "$configNxtNullsoftUninsBackupPath\$nullsoftBackupSubfolderName\$uninsFileName" -Destination "$uninsFolder\"	
				}

				## If $nullsoftSetupPath is still unexistend, write Error to log and abort
				if (![System.IO.File]::Exists($nullsoftSetupPath)) {
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
    
		[string]$argsnullsoft = $nullsoftDefaultParams
    
		## Replace default parameters if specified.
		if ($Parameters) {
			[string]$argsnullsoft = $Parameters
		}
		## Append parameters to default parameters if specified.
		if ($AddParameters) {
			[string]$argsnullsoft = "$argsnullsoft $AddParameters"
		}
 
		[hashtable]$ExecuteProcessSplat = @{
			Path        = $nullsoftSetupPath
			Parameters  = $argsnullsoft
			WindowStyle = 'Normal'
		}
        
		if ($ContinueOnError) {
			$ExecuteProcessSplat.Add('ContinueOnError', $ContinueOnError)
		}
		if ($PassThru) {
			$ExecuteProcessSplat.Add('PassThru', $PassThru)
		}
		if (![string]::IsNullOrEmpty($AcceptedExitCodes)) {
			$ExecuteProcessSplat.Add('IgnoreExitCodes', $AcceptedExitCodes)
		}
    
		if ($PassThru) {
			[psobject]$ExecuteResults = Execute-Process @ExecuteProcessSplat
		}
		else {
			Execute-Process @ExecuteProcessSplat
		}

		if ($Action -eq 'Uninstall') {
			## Wait until all uninstallation processes hopefully terminated
			Write-Log -Message "Wait while one of the possible uninstallation processes is still running..." -Source ${CmdletName}
			[bool]$resultAU_process = Watch-NxtProcessIsStopped -ProcessName "AU_.exe" -Timeout "500"
			[bool]$resultUn_Aprocess = Watch-NxtProcessIsStopped -ProcessName "Un_A.exe" -Timeout "500"
			If (($false -eq $resultAU_process) -or ($false -eq $resultUn_Aprocess)) {
				Write-Log -Message "Note: an uninstallation process was still running after the waiting period of 500s!" -Severity 2 -Source ${CmdletName}
			} else {
				Write-Log -Message "All uninstallation processes finished." -Source ${CmdletName}
			}
		}
    
		## Update the desktop (in case of changed or added enviroment variables)
		Update-Desktop

		## Copy uninstallation file from $uninsFolder to $configNxtNullsoftUninsBackupPath after a successful installation
		if ($Action -eq 'Install') {
			[array]$installedAppResults = Get-NxtInstalledApplication -UninstallKey $nullsoftUninstallKey -UninstallKeyIsDisplayName $nullsoftUninstallKeyIsDisplayName -UninstallKeyContainsWildCards $nullsoftUninstallKeyContainsWildCards -DisplayNamesToExclude $nullsoftDisplayNamesToExclude
			if ($installedAppResults.Count -eq 0) {
				Write-Log -Message "Found no Application with UninstallKey [$nullsoftUninstallKey], UninstallKeyIsDisplayName [$nullsoftUninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$nullsoftUninstallKeyContainsWildCards] and DisplayNamesToExclude [$($nullsoftDisplayNamesToExclude -join "][")]. Skipping [copy uninstallation file to backup]..." -Severity 2 -Source ${CmdletName}
			}
			elseif ($installedAppResults.Count -gt 1) {
				Write-Log -Message "Found more than one Application with UninstallKey [$nullsoftUninstallKey], UninstallKeyIsDisplayName [$nullsoftUninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$nullsoftUninstallKeyContainsWildCards] and DisplayNamesToExclude [$($nullsoftDisplayNamesToExclude -join "][")]. Skipping [copy uninstallation file to backup]..." -Severity 2 -Source ${CmdletName}
			}
			else {
				[string]$nullsoftUninstallString = $installedAppResults.UninstallString

				## check for and remove quotation marks around the uninstall string
				if ($nullsoftUninstallString.StartsWith('"')) {
					[string]$nullsoftUninstallPath = $nullsoftUninstallString.Substring(1, $nullsoftUninstallString.IndexOf('"', 1) - 1)
				}
				else {
					[string]$nullsoftUninstallPath = $nullsoftUninstallString.Substring(0, $nullsoftUninstallString.IndexOf('.exe', [System.StringComparison]::CurrentCultureIgnoreCase) + 4)
				}

				## Actually copy the uninstallation file, if it exists
				if ($true -eq (Test-Path -Path "$nullsoftUninstallPath")) {
					Write-Log -Message "Copy uninstallation file to backup..." -Source ${CmdletName}
					Copy-File -Path "$nullsoftUninstallPath" -Destination "$configNxtNullsoftUninsBackupPath\$($InstalledAppResults.UninstallSubkey)\"	
				}
				else {
					Write-Log -Message "Uninstall file not found. Skipping [copy of uninstallation file to backup]..." -Source ${CmdletName}
				}
			}
		}
	}
	End {
		if ($PassThru) {
			Write-Output -InputObject $ExecuteResults
		}

		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Exit-NxtAbortReboot
function Exit-NxtAbortReboot {
	<#
	.SYNOPSIS
		Exits the script after deleting all package registry keys and requests a reboot from the deployment system.
	.DESCRIPTION
		Deletes the package machine key under "HKLM:\Software\", which defaults to the PackageGUID under the RegPackagesKey value from the neo42PackageConfig.json.
		Deletes the package uninstallkey under "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\", which defaults to the PackageGUID value from the neo42PackageConfig.json.
		Writes an "error" message to the package log and an error entry to the registry, which defaults to "Uninstall of $installTitle requires a reboot before proceeding with the installation. AbortReboot!"
		Exits the script with a return code to trigger a system reboot, which defaults to "3010".
		Also deletes corresponding Empirum registry keys, if the pacakge was deployed with Matrix42 Empirum.
	.PARAMETER PackageMachineKey
		Path to the the package machine key under "HKLM:\Software\".
		Defaults to "$($global:PackageConfig.RegPackagesKey)\$($global:PackageConfig.PackageGUID)".
	.PARAMETER PackageUninstallKey
		Name of the the package uninstallkey under "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\".
		Defaults to the PackageGUID value from the PackageConfig object.
	.PARAMETER RebootMessage
		The Message, that will apear in the package log and the error entry in the the registry.
		Defaults to "Uninstall of $installTitle requires a reboot before proceeding with the installation. AbortReboot!"
	.PARAMETER RebootExitCode
		The value, the script returns to the deployment system to trigger a system reboot and that will be written as LastExitCode to the error entry in the the registry.
		Defaults to "3010".
	.PARAMETER PackageStatus
		The value, that will be written as PackageStatus to the error entry in the the registry.
		Defaults to "AbortReboot".
	.PARAMETER EmpirumMachineKey
		Path to the Empirum package machine key under "HKLM:\Software\".
		Defaults to "$($global:PackageConfig.RegPackagesKey)\$AppVendor\$AppName\$appVersion".
	.PARAMETER EmpirumUninstallKey
		Name of the the Empirum package uninstallkey under "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\".
		Defaults to "$global:PackageConfig.UninstallDisplayName".
	.EXAMPLE
		Exit-NxtAbortReboot
	.EXAMPLE
		Exit-NxtAbortReboot -PackageMachineKey "OurPackages\{XXXXXXXX-XXXX-XXXXXXXX-XXXXXXXXXXXX}" -PackageUninstallKey "{XXXXXXXX-XXXX-XXXXXXXX-XXXXXXXXXXXX}"
	.EXAMPLE
		Exit-NxtAbortReboot -RebootMessage "This package requires a system reboot..." -RebootExitCode "1641" -PackageStatus "RebootPending"
	.EXAMPLE
		Exit-NxtAbortReboot -EmpirumMachineKey "OurPackages\Microsoft\Office365\16.0" -EmpirumUninstallKey "OurPackage Microsoft Office365 16.0"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$PackageMachineKey = "$($global:PackageConfig.RegPackagesKey)\$($global:PackageConfig.PackageGUID)",
		[Parameter(Mandatory = $false)]
		[string]
		$PackageUninstallKey = $global:PackageConfig.PackageGUID,
		[Parameter(Mandatory = $false)]
		[string]
		$RebootMessage = "'$installTitle' requires a reboot before proceeding with the installation. AbortReboot!",
		[Parameter(Mandatory = $false)]
		[int32]
		$RebootExitCode = 3010,
		[Parameter(Mandatory = $false)]
		[string]
		$PackageStatus = "AbortReboot",
		[Parameter(Mandatory = $false)]
		[string]
		$EmpirumMachineKey = "$($global:PackageConfig.RegPackagesKey)\$AppVendor\$AppName\$appVersion",
		[Parameter(Mandatory = $false)]
		[string]
		$EmpirumUninstallKey = $global:PackageConfig.UninstallDisplayName
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		Write-Log -Message "Initiating AbortReboot..." -Source ${CmdletName}
		try {
			Remove-RegistryKey -Key "HKLM:\Software\$PackageMachineKey" -Recurse
			Remove-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageUninstallKey" -Recurse
			if (Test-Path -Path "HKLM:Software\$EmpirumMachineKey") {
				Remove-RegistryKey -Key "HKLM:\Software\$EmpirumMachineKey" -Recurse
			}
			if (Test-Path -Path "HKLM:Software\Microsoft\Windows\CurrentVersion\Uninstall\$EmpirumUninstallKey") {
				Remove-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$EmpirumUninstallKey" -Recurse
			}
			Exit-NxtScriptWithError -ErrorMessage $RebootMessage -MainExitCode $RebootExitCode -PackageStatus $PackageStatus
		}
		catch {
			Write-Log -Message "Failed to execute AbortReboot. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			throw "Failed to execute AbortReboot: $($_.Exception.Message)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Exit-NxtScriptWithError
function Exit-NxtScriptWithError {
	<#
	.SYNOPSIS
		Exits the Script writing an error entry to the registry.
	.DESCRIPTION
		Exits the Script writing information about the installation attempt to the registry below the RegPackagesKey
		defined in the neo42PackageConfig.json.
	.PARAMETER ErrorMessage
		The message that should be written to the registry key to leave a hint of what went wrong with the installation.
	.PARAMETER ErrorMessagePSADT
		The exception message generated by PowerShell, if a function fails. Can be passed by $($Error[0].Exception.Message).
	.PARAMETER PackageGUID
		Specifies the registry key name used for the packages wrapper uninstall entry.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegPackagesKey
		Defines the name of the registry key keeping track of all packages delivered by this packaging framework.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER App
		Defines the path to a local persistent cache for installation files.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER DeploymentTimestamp
		Defines the Deployment Starttime which should be added as information to the error registry key.
		Defaults to the $global:DeploymentTimestamp.
	.PARAMETER DebugLogFile
		Path to the Debuglogfile which should be added as information to the error registry key.
		Defaults to "$ConfigToolkitLogDir\$LogName".
	.PARAMETER AppVendor
		Specifies the Application Vendor used in the registry etc.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppArch
		Specifies the package architecture ("x86", "x64" or "*").
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER MainExitCode
		The value, the script returns to the deployment system and that will be written as LastExitCode to the error entry in the the registry.
	.PARAMETER PackageStatus
		The value, that will be written as PackageStatus to the error entry in the the registry.
		Defaults to "Failure".
	.PARAMETER AppRevision
		Specifies the Application Revision used in the registry etc.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER ScriptParentPath
		Specifies the ScriptParentPath.
		Defaults to $scriptParentPath defined in the AppDeployToolkitMain.
	.PARAMETER EnvArchitecture
		Defines the EnvArchitecture.
		Defaults to $envArchitecture derived from $env:PROCESSOR_ARCHITECTURE.
	.PARAMETER EnvUserDomain
		Defines ... which should be added as information to the error registry key.
		Defaults to the corresponding value from $global:Packageconfig.
	.PARAMETER EnvUserName
		Defines the EnvUserDomain.
		Defaults to $envUserDomain derived from [Environment]::UserDomainName.
	.PARAMETER ProcessNTAccountSID
		Defines the NT Account SID the current Process is run as.
		Defaults to $ProcessNTAccountSID defined in the PSADT Main script.
	.PARAMETER UninstallOld
		Defines if the Setting "Uninstallold" is set.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UserPartOnInstallation
		Specifies if a Userpart should take place during installation.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UserPartOnUnInstallation
		Specifies if a Userpart should take place during uninstallation.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER ContinueOnError
		Continue if an error is encountered. Default is: $true.
	.EXAMPLE
		Exit-NxtScriptWithError -ErrorMessage "The Installer returned the following Exit Code $someExitcode, installation failed!" -MainExitCode 69001 -PackageStatus "InternalInstallerError"
	.EXAMPLE
		Exit-NxtScriptWithError -ErrorMessage "Script execution failed!" -ErrorMessagePSADT $($Error[0].Exception.Message) -MainExitCode $mainExitCode
	.NOTES
		AppDeployToolkit is required in order to run this function.
	.LINK
		http://psappdeploytoolkit.com
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$ErrorMessage,
		[Parameter(Mandatory = $false)]
		[string]
		$ErrorMessagePSADT,
		[Parameter(Mandatory = $false)]
		[string]
		$PackageGUID = $global:PackageConfig.PackageGUID,
		[Parameter(Mandatory = $false)]
		[string]
		$RegPackagesKey = $global:PackageConfig.RegPackagesKey,
		[Parameter(Mandatory = $false)]
		[string]
		$App = $global:PackageConfig.App,
		[Parameter(Mandatory = $false)]
		[string]
		$DeploymentTimestamp = $global:DeploymentTimestamp,
		[Parameter(Mandatory = $false)]
		[string]
		$DebugLogFile = "$ConfigToolkitLogDir\$LogName",
		[Parameter(Mandatory = $false)]
		[string]
		$AppVendor = $global:PackageConfig.AppVendor,
		[Parameter(Mandatory = $false)]
		[string]
		$AppArch = $global:PackageConfig.AppArch,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[int32]
		$MainExitCode,
		[Parameter(Mandatory = $false)]
		[string]
		$PackageStatus = "Failure",
		[Parameter(Mandatory = $false)]
		[string]
		$AppRevision = $global:PackageConfig.AppRevision,
		[Parameter(Mandatory = $false)]
		[string]
		$ScriptParentPath = $scriptParentPath,
		[Parameter(Mandatory = $false)]
		[string]
		$EnvArchitecture = $envArchitecture,
		[Parameter(Mandatory = $false)]
		[string]
		$EnvUserDomain = $envUserDomain,
		[Parameter(Mandatory = $false)]
		[string]
		$EnvUserName = $envUserName,
		[Parameter(Mandatory = $false)]
		[string]
		$ProcessNTAccountSID = $ProcessNTAccountSID,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallOld = $global:PackageConfig.UninstallOld,
		[Parameter(Mandatory = $false)]
		[bool]
		$UserPartOnInstallation = $global:PackageConfig.UserPartOnInstallation,
		[Parameter(Mandatory = $false)]
		[bool]
		$UserPartOnUnInstallation = $global:PackageConfig.UserPartOnUnInstallation
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			Write-Log -Message $ErrorMessage -Severity 3 -Source ${CmdletName}
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'AppPath' -Value $App
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'DebugLogFile' -Value $DebugLogFile
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'DeploymentStartTime' -Value $DeploymentTimestamp
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'DeveloperName' -Value $AppVendor
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'ErrorTimeStamp' -Value $(Get-Date -format "yyyy-MM-dd_HH-mm-ss")
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'ErrorMessage' -Value $ErrorMessage
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'ErrorMessagePSADT' -Value $ErrorMessagePSADT
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'LastExitCode' -Value $MainExitCode
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'PackageArchitecture' -Value $AppArch
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'PackageStatus' -Value $PackageStatus
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'ProductName' -Value $AppName
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'Revision' -Value $AppRevision
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'SrcPath' -Value $ScriptParentPath
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'StartupProcessor_Architecture' -Value $EnvArchitecture
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'StartupProcessOwner' -Value $EnvUserDomain\$EnvUserName
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'StartupProcessOwnerSID' -Value $ProcessNTAccountSID
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'UninstallOld' -Type 'Dword' -Value $UninstallOld
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'UserPartOnInstallation' -Value $UserPartOnInstallation -Type 'DWord'
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'UserPartOnUninstallation' -Value $UserPartOnUnInstallation -Type 'DWord'
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'Version' -Value $AppVersion
		}
		catch {
			Write-Log -Message "Failed to create error key in registry. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
		if ($MainExitCode -eq 0) {
			[int32]$MainExitCode = 70000
		}
		Exit-Script -ExitCode $MainExitCode
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Expand-NxtPackageConfig
function Expand-NxtPackageConfig {
	<#
	.DESCRIPTION
		Expands a set of Subkeys in the $global:PackageConfig back into the variable $global:PackageConfig.
	.PARAMETER PackageConfig
		Expects an Object containing the Packageconfig, defaults to $global:PackageConfig
		Defaults to $global:PackageConfig
	.EXAMPLE
		Expand-NxtPackageConfig
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[PSObject]
		$PackageConfig = $global:PackageConfig
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[string]$global:PackageConfig.SoftMigration.File.FullNameToCheck = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.SoftMigration.File.FullNameToCheck)
		[string]$global:PackageConfig.App = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.App)
		[string]$global:PackageConfig.UninstallDisplayName = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.UninstallDisplayName)
		[string]$global:PackageConfig.InstallLocation = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.InstallLocation)
		[string]$global:PackageConfig.InstLogFile = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.InstLogFile)
		[string]$global:PackageConfig.UninstLogFile = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.UninstLogFile)
		[string]$global:PackageConfig.InstFile = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.InstFile)
		[string]$global:PackageConfig.InstPara = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.InstPara)
		[string]$global:PackageConfig.UninstFile = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.UninstFile)
		[string]$global:PackageConfig.UninstPara = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.UninstPara)
		[array]$global:PackageConfig.DisplayNamesToExcludeFromAppSearches = foreach ($displayNameToExcludeFromAppSearches in $global:PackageConfig.DisplayNamesToExcludeFromAppSearches) {
			$ExecutionContext.InvokeCommand.ExpandString($displayNameToExcludeFromAppSearches)
		}
		foreach ($uninstallKeyToHide in $global:PackageConfig.UninstallKeysToHide) {
			[string]$uninstallKeyToHide.KeyName = $ExecutionContext.InvokeCommand.ExpandString($uninstallKeyToHide.KeyName)
			if ($false -eq [string]::IsNullOrEmpty($uninstallKeyToHide.KeyNameIsDisplayName)) {
				try {
					[bool]$uninstallKeyToHide.KeyNameIsDisplayName = [System.Convert]::ToBoolean($ExecutionContext.InvokeCommand.ExpandString($uninstallKeyToHide.KeyNameIsDisplayName))
				}
				catch [FormatException] {
					throw "Failed to expand UninstallKeysToHide. Could not convert [$($uninstallKeyToHide.KeyNameIsDisplayName)] to boolean value."
				}
			}
			if ($false -eq [string]::IsNullOrEmpty($uninstallKeyToHide.KeyNameContainsWildCards)) {
				try {
					[bool]$uninstallKeyToHide.KeyNameContainsWildCards = [System.Convert]::ToBoolean($ExecutionContext.InvokeCommand.ExpandString($uninstallKeyToHide.KeyNameContainsWildCards))
				}
				catch [FormatException] {
					throw "Failed to expand UninstallKeysToHide. Could not convert [$($uninstallKeyToHide.KeyNameContainsWildCards)] to boolean value."
				}
			}
			if ($false -eq [string]::IsNullOrEmpty($uninstallKeyToHide.DisplayNamesToExcludeFromHiding)) {
				[array]$uninstallKeyToHide.DisplayNamesToExcludeFromHiding = foreach ($displayNameToExcludeFromHiding in $uninstallKeyToHide.DisplayNamesToExcludeFromHiding) {
					$ExecutionContext.InvokeCommand.ExpandString($displayNameToExcludeFromHiding)
				}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Expand-NxtVariablesInFile
function Expand-NxtVariablesInFile {
	<#
  	.DESCRIPTION
		Expands different variables types in a text file.
		Supports local, script, $env:, $global: and common Windows environment variables.
  	.PARAMETER Path
		The path to the file.
  	.OUTPUTS
		none
  	.EXAMPLE
		Expand-NxtVariablesInFile -Path C:\Temp\testfile.txt
  	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[String]
		$Path
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[string[]]$content = Get-Content -Path $Path
			[string]$fileEncoding = Get-NxtFileEncoding -Path $Path -DefaultEncoding Default

			for ([int]$i = 0; $i -lt $content.Length; $i++) {
				[string]$line = $content[$i]

				## Replace PowerShell global variables in brackets
				[PSObject]$globalVariableMatchesInBracket = [regex]::Matches($line, '\$\(\$global:([A-Za-z_.][A-Za-z0-9_.\[\]]+)\)')
				foreach ($globalVariableMatch in $globalVariableMatchesInBracket) {
					[string]$globalVariableName = $globalVariableMatch.Groups[1].Value
					if ($globalVariableName.Contains('.')) {
						[string]$tempVariableName = $globalVariableName.Split('.')[0]
						[PSObject]$tempVariableValue = (Get-Variable -Name $tempVariableName -Scope Global -ValueOnly -ErrorAction SilentlyContinue)
						## Variables with properties and/or subproperties won't be found
						if (![string]::IsNullOrEmpty($tempVariableValue)) {
							[string]$globalVariableValue = Invoke-Command -ScriptBlock ([ScriptBlock]::Create($globalVariableMatch.Value))
						}
					}
					else {
						[string]$globalVariableValue = (Get-Variable -Name $globalVariableName -Scope Global -ValueOnly -ErrorAction SilentlyContinue)
					}

					[string]$line = $line.Replace($globalVariableMatch.Value, $globalVariableValue)
				}
				[PSObject]$globalVariableMatchesInBracket = $null

				## Replace PowerShell global variables
				[PSObject]$globalVariableMatches = [regex]::Matches($line, '\$global:([A-Za-z_.][A-Za-z0-9_.\[\]]+)')
				foreach ($globalVariableMatch in $globalVariableMatches) {
					[string]$globalVariableName = $globalVariableMatch.Groups[1].Value
					[PSObject]$globalVariableValue = (Get-Variable -Name $globalVariableName -Scope Global -ValueOnly -ErrorAction SilentlyContinue)
					## Variables with properties and/or subproperties won't be found
					if ([string]::IsNullOrEmpty($globalVariableValue)) {
						[PSObject]$globalVariableValue = Invoke-Command -ScriptBlock ([ScriptBlock]::Create($globalVariableMatch.Value))
					}
					[string]$line = $line.Replace($globalVariableMatch.Value, $globalVariableValue)
				}
				[PSObject]$globalVariableMatches = $null

				## Replace PowerShell environment variables in brackets
				[PSObject]$environmentMatchesInBracket = [regex]::Matches($line, '\$\(\$env:([A-Za-z_.][A-Za-z0-9_.]+)(\([^)]*\))?\)')
				foreach ($expressionMatch in $environmentMatchesInBracket) {
					if ($expressionMatch.Groups.Count -gt 2) {
						[string]$envVariableName = "$($expressionMatch.Groups[1].Value)$($expressionMatch.Groups[2].Value)" 
					}
					else {
						[string]$envVariableName = $expressionMatch.Groups[1].Value.TrimStart('$(').TrimEnd('")')
					}
                    
					[string]$envVariableValue = (Get-ChildItem env:* | Where-Object { $_.Name -EQ $envVariableName }).Value

					[string]$line = $line.Replace($expressionMatch.Value, $envVariableValue)
				}
				[PSObject]$environmentMatchesInBracket = $null

				## Replace PowerShell environment variables
				[PSObject]$environmentMatches = [regex]::Matches($line, '\$env:([A-Za-z_.][A-Za-z0-9_.]+)(\([^)]*\))?')
				foreach ($expressionMatch in $environmentMatches) {
					if ($expressionMatch.Groups.Count -gt 2) {
						[string]$envVariableName = "$($expressionMatch.Groups[1].Value)$($expressionMatch.Groups[2].Value)" 
					}
					else {
						[string]$envVariableName = $expressionMatch.Groups[1].Value.TrimStart('$(').TrimEnd('")')
					}
					[string]$envVariableValue = (Get-ChildItem env:* | Where-Object { $_.Name -EQ $envVariableName }).Value

					[string]$line = $line.Replace($expressionMatch.Value, $envVariableValue)
				}
				[PSObject]$environmentMatches = $null

				## Replace PowerShell variable in brackets with its value
				[PSObject]$variableMatchesInBrackets = [regex]::Matches($line, '\$\(\$[A-Za-z_.][A-Za-z0-9_.\[\]]+\)')
				foreach ($expressionMatch in $variableMatchesInBrackets) {
					[string]$expression = $expressionMatch.Groups[0].Value
					[string]$cleanedExpression = $expression.TrimStart('$(').TrimEnd('")')
					if ($cleanedExpression.Contains('.')) {
						[string]$tempVariableName = $cleanedExpression.Split('.')[0]
						[PSObject]$tempVariableValue = (Get-Variable -Name $tempVariableName -Scope Global -ValueOnly -ErrorAction SilentlyContinue)
						## Variables with properties and/or subproperties won't be found
						if (![string]::IsNullOrEmpty($tempVariableValue)) {
							[string]$variableValue = Invoke-Command -ScriptBlock ([ScriptBlock]::Create($expressionMatch.Value))
						}
					}
					else {
						[string]$variableValue = (Get-Variable -Name $cleanedExpression -ValueOnly)
					}

					[string]$line = $line.Replace($expressionMatch.Value, $variableValue)
				}
				[PSObject]$variableMatchesInBrackets = $null

				## Replace PowerShell variable with its value
				[PSObject]$variableMatches = [regex]::Matches($line, '\$[A-Za-z_.][A-Za-z0-9_.\[\]]+')
				foreach ($match in $variableMatches) {
					[string]$variableName = $match.Value.Substring(1)
					if ($variableName.Contains('.')) {
						[string]$tempVariableName = $variableName.Split('.')[0]
						[PSObject]$tempVariableValue = (Get-Variable -Name $tempVariableName -Scope Global -ValueOnly -ErrorAction SilentlyContinue)
						## Variables with properties and/or subproperties won't be found
						if (![string]::IsNullOrEmpty($tempVariableValue)) {
							[string]$variableValue = Invoke-Command -ScriptBlock ([ScriptBlock]::Create($match.Value))
						}
					}
					else {
						[string]$variableValue = (Get-Variable -Name $variableName -ValueOnly)
					}
                    
					[string]$line = $line.Replace($match.Value, $variableValue)
				}
				[PSObject]$variableMatches = $null

				## Replace common Windows environment variables
				[string]$line = [System.Environment]::ExpandEnvironmentVariables($line)

				[string]$content[$i] = $line
			}

			Set-Content -Path $Path -Value $content -Encoding $fileEncoding

		}
		catch {
			Write-Log -Message "Failed to expand variables in '$($Path)' `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		##Return with success code 0 and continue
		Write-Output 0
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Format-NxtPackageSpecificVariables
function Format-NxtPackageSpecificVariables {
	<#
	.DESCRIPTION
		Formats the PackageSpecificVariables from PackageSpecificVariablesRaw in the $global:PackageConfig.
		The variables can then be acquired like this:
		$global:PackageConfig.PackageSpecificVariables.CustomVariableName
		Expands variables if "ExpandVariables" is set to true
	.PARAMETER PackageConfig
		Expects an object containing the Packageconfig, defaults to $global:PackageConfig
		Defaults to $global:PackageConfig
	.EXAMPLE
		Format-NxtPackageSpecificVariables
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[PSObject]
		$PackageConfig = $global:PackageConfig
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		## Get String from object and Expand String if requested
		[System.Collections.Generic.Dictionary[string, string]]$packageSpecificVariableDictionary = New-Object "System.Collections.Generic.Dictionary[string,string]"
		foreach ($packageSpecificVariable in $PackageConfig.PackageSpecificVariablesRaw) {
			if ($packageSpecificVariable.ExpandVariables) {
				$packageSpecificVariableDictionary.Add($packageSpecificVariable.Name, $ExecutionContext.InvokeCommand.ExpandString($packageSpecificVariable.Value))
			}
			else {
				$packageSpecificVariableDictionary.Add($packageSpecificVariable.Name, $packageSpecificVariable.Value)
			}
		}
		$global:PackageConfig | Add-Member -MemberType NoteProperty -Name "PackageSpecificVariables" -Value $packageSpecificVariableDictionary
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Get-NxtComputerManufacturer
function Get-NxtComputerManufacturer {
	<#
	.DESCRIPTION
		Gets the manufacturer of the computer system.
	.EXAMPLE
		Get-NxtComputerManufacturer
	.OUTPUTS
		System.String.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param ()
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[string]$result = [string]::Empty
		try {
			[string]$result = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property Manufacturer).Manufacturer
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
#region Function Get-NxtComputerModel
function Get-NxtComputerModel {
	<#
	.DESCRIPTION
		Gets the model of the computer system.
	.EXAMPLE
		Get-NxtComputerModel
	.OUTPUTS
		System.String.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param ()
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[string]$result = [string]::Empty
		try {
			[string]$result = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property Model).Model
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
#region Function Get-NxtCurrentDisplayVersion
function Get-NxtCurrentDisplayVersion {
	<#
	.SYNOPSIS
		Retrieves currently found display version of an application.
	.DESCRIPTION
		Retrieves currently found display version of an application from the registry depending on the name of its uninstallkey or its display name, based on exact values only or with wildcards if specified.
	.PARAMETER UninstallKey
		Name of the uninstall registry key of the application (e.g. "ThisApplication").
		Can be found under "HKLM:\Software\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\".
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyIsDisplayName
		Determines if the value given as UninstallKey should be interpreted as a displayname.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyContainsWildCards
		Determines if the value given as UninstallKey contains WildCards.
		If set to $true, "*" are interpreted as WildCards.
		If set to $false, "*" are interpreted as part of the actual string.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER DisplayNamesToExclude
		DisplayName(s) to exclude from the search result.
		Use commas to separate more than one value.
		"*" inside this parameter will not be interpreted as WildCards. (This has no effect on the use of WildCards in other parameters!)
		We reccommend always adding "$global:PackageConfig.UninstallDisplayName" if used inside a package to exclude the current package itself, especially if combined with the "UninstallKeyContainsWildCards" parameter.
		Defaults to the "DisplayNamesToExcludeFromAppSearches" value from the PackageConfig object.
	.EXAMPLE
		Get-NxtCurrentDisplayVersion -UninstallKey "{12345678-A123-45B6-CD7E-12345FG6H78I}"
	.EXAMPLE
		Get-NxtCurrentDisplayVersion -UninstallKey "MyNewApp" -UninstallKeyIsDisplayName $true
	.EXAMPLE
		Get-NxtCurrentDisplayVersion -UninstallKey "SomeApp - Version *" -UninstallKeyIsDisplayName $true -UninstallKeyContainsWildCards $true -DisplayNamesToExclude "SomeApp - Version 1.0","SomeApp - Version 1.1",$global:PackageConfig.UninstallDisplayName
	.EXAMPLE
		Get-NxtCurrentDisplayVersion -UninstallKey "***MySuperSparklingApp***" -UninstallKeyIsDisplayName $true -UninstallKeyContainsWildCards $false
	.NOTES
		AppDeployToolkit is required in order to run this function.
	.OUTPUTS
		PSADTNXT.NxtDisplayVersionResult.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$UninstallKey = $global:PackageConfig.UninstallKey,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyIsDisplayName = $global:PackageConfig.UninstallKeyIsDisplayName,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyContainsWildCards = $global:PackageConfig.UninstallKeyContainsWildCards,
		[Parameter(Mandatory = $false)]
		[array]
		$DisplayNamesToExclude = $global:PackageConfig.DisplayNamesToExcludeFromAppSearches
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ([string]::IsNullOrEmpty($UninstallKey)) {
			Write-Log -Message "Can't detect display version: No uninstallkey or display name defined." -Source ${CmdletName}
		}
		else {
			[PSADTNXT.NxtDisplayVersionResult]$DisplayVersionResult = New-Object -TypeName PSADTNXT.NxtDisplayVersionResult
			try {
				Write-Log -Message "Detect currently set DisplayVersion value of package application..." -Source ${CmdletName}
				[array]$installedAppResults = Get-NxtInstalledApplication -UninstallKey $UninstallKey -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude
				if ($installedAppResults.Count -eq 0) {
					Write-Log -Message "Found no uninstall key with UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Skipped detecting a DisplayVersion." -Severity 2 -Source ${CmdletName}
					$DisplayVersionResult.DisplayVersion = [string]::Empty
					$DisplayVersionResult.UninstallKeyExists = $false
				}
				elseif ($installedAppResults.Count -gt 1) {
					Write-Log -Message "Found more than one uninstall key with UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Skipped detecting a DisplayVersion." -Severity 2 -Source ${CmdletName}
					$DisplayVersionResult.DisplayVersion = [string]::Empty
					$DisplayVersionResult.UninstallKeyExists = $false
				}
				elseif ([string]::IsNullOrEmpty($installedAppResults.DisplayVersion)) {
					Write-Log -Message "Detected no DisplayVersion for UninstallKey [$UninstallKey] with UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]." -Severity 2 -Source ${CmdletName}
					$DisplayVersionResult.DisplayVersion = [string]::Empty
					$DisplayVersionResult.UninstallKeyExists = $true
				}
				else {
					Write-Log -Message "Currently detected display version [$($installedAppResults.DisplayVersion)] for UninstallKey [$UninstallKey] with UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]." -Source ${CmdletName}
					$DisplayVersionResult.DisplayVersion = $installedAppResults.DisplayVersion
					$DisplayVersionResult.UninstallKeyExists = $true
				}
				Write-Output $DisplayVersionResult
			}
			catch {
				Write-Log -Message "Failed to detect DisplayVersion for UninstallKey [$UninstallKey] with UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. `n$(Resolve-Error)" -Severity 2 -Source ${CmdletName}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Get-NxtDriveFreeSpace
function Get-NxtDriveFreeSpace {
	<#
	.DESCRIPTION
		Gets free space of drive in bytes.
	.PARAMETER DriveName
		Name of the drive.
	.PARAMETER Unit
		Unit the disksize should be returned in.
	.EXAMPLE
		Get-NxtDriveFreeSpace "c:"
	.OUTPUTS
		System.String.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$DriveName,
		[Parameter(Mandatory = $false)]
		[ValidateSet("B", "KB", "MB", "GB", "TB", "PB")]
		[string]
		$Unit = "B"
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[System.Management.ManagementObject]$disk = Get-WmiObject -Class Win32_logicaldisk -Filter "DeviceID = '$DriveName'"
			[long]$diskFreekSize = [math]::Floor(($disk.FreeSpace / "$("1$Unit" -replace "1B","1D")"))
		}
		catch {
			Write-Log -Message "Failed to get free space for '$DriveName'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		Write-Output $diskFreekSize
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Get-NxtDriveType
function Get-NxtDriveType {
	<#
	.DESCRIPTION
		Gets the drive type.
	.PARAMETER DriveName
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
		Ram = 6.
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
	}
	Process {
		try {
			[System.Management.ManagementObject]$disk = Get-WmiObject -Class Win32_logicaldisk -Filter "DeviceID = '$DriveName'"
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
		System.String.
  	.EXAMPLE
		Get-NxtFileEncoding -Path C:\Temp\testfile.txt
  	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
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
	}
	Process {
		try {
			[string]$intEncoding = [PSADTNXT.Extensions]::GetEncoding($Path)
			if ([System.String]::IsNullOrEmpty($intEncoding)) {
				[string]$intEncoding = $DefaultEncoding
			}
			Write-Output $intEncoding
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
#region Function Get-NxtFileVersion
function Get-NxtFileVersion {
	<#
	.DESCRIPTION
		Gets version of file.
		The return value is a version object.
	.PARAMETER FilePath
		Full path to the file.
	.EXAMPLE
		Get-NxtFileVersion "D:\setup.exe"
	.OUTPUTS
		System.String.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$FilePath
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[string]$result = $null
		try {
			[string]$result = (New-Object -TypeName System.IO.FileInfo -ArgumentList $FilePath).VersionInfo.FileVersion
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
#region Function Get-NxtFolderSize
function Get-NxtFolderSize {
	<#
	.DESCRIPTION
		Gets the size of the folder recursive in bytes.
	.PARAMETER FolderPath
		Path to the folder.
	.PARAMETER Unit
		Unit the foldersize should be returned in.
	.EXAMPLE
		Get-NxtFolderSize "D:\setup\"
	.OUTPUTS
		System.Long.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$FolderPath,
		[Parameter(Mandatory = $false)]
		[ValidateSet("B", "KB", "MB", "GB", "TB", "PB")]
		[string]
		$Unit = "B"
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[long]$result = 0
		try {
			[System.IO.FileInfo[]]$files = [System.Linq.Enumerable]::Select([System.IO.Directory]::EnumerateFiles($FolderPath, "*.*", "AllDirectories"), [Func[string, System.IO.FileInfo]] { Param ($x) (New-Object -TypeName System.IO.FileInfo -ArgumentList $x) })
			[long]$result = [System.Linq.Enumerable]::Sum($files, [Func[System.IO.FileInfo, long]] { Param ($x) $x.Length })
			[long]$folderSize = [math]::round(($result / "$("1$Unit" -replace "1B","1D")"))
		}
		catch {
			Write-Log -Message "Failed to get size from folder '$FolderPath'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		Write-Output $folderSize
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Get-NxtInstalledApplication
function Get-NxtInstalledApplication {
	<#
	.SYNOPSIS
		Retrieves information about installed applications based on exact values only or with WildCards if specified.
	.DESCRIPTION
		Retrieves information about installed applications by querying the registry depending on the name of its uninstallkey or its display name.
		Returns information about application publisher, name & version, product code, uninstall string, install source, location, date, and application architecture.
	.PARAMETER UninstallKey
		Name of the uninstall registry key of the application (e.g. "ThisApplication").
		Can be found under "HKLM:\Software\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\".
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyIsDisplayName
		Determines if the value given as UninstallKey should be interpreted as a DisplayName.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyContainsWildCards
		Determines if the value given as UninstallKey contains WildCards.
		If set to $true "*" are interpreted as WildCards.
		If set to $false "*" are interpreted as part of the actual string.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER DisplayNamesToExclude
		DisplayName(s) to exclude from the search result.
		Use commas to separate more than one value.
		"*" inside this parameter will not be interpreted as WildCards. (This has no effect on the use of WildCards in other parameters!)
		We reccommend always adding "$global:PackageConfig.UninstallDisplayName" if used inside a package to exclude the current package itself, especially if combined with the "UninstallKeyContainsWildCards" parameter.
		Defaults to the "DisplayNamesToExcludeFromAppSearches" value from the PackageConfig object.
	.EXAMPLE
		Get-NxtInstalledApplication -UninstallKey "{12345678-A123-45B6-CD7E-12345FG6H78I}"
	.EXAMPLE
		Get-NxtInstalledApplication -UninstallKey "MyNewApp" -UninstallKeyIsDisplayName $true
	.EXAMPLE
		Get-NxtInstalledApplication -UninstallKey "SomeApp - Version *" -UninstallKeyIsDisplayName $true -UninstallKeyContainsWildCards $true -DisplayNamesToExclude "SomeApp - Version 1.0","SomeApp - Version 1.1",$global:PackageConfig.UninstallDisplayName
	.EXAMPLE
		Get-NxtInstalledApplication -UninstallKey "***MySuperSparklingApp***" -UninstallKeyIsDisplayName $true -UninstallKeyContainsWildCards $false
	.NOTES
		AppDeployToolkit is required in order to run this function.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$UninstallKey = $global:PackageConfig.UninstallKey,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyIsDisplayName = $global:PackageConfig.UninstallKeyIsDisplayName,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyContainsWildCards = $global:PackageConfig.UninstallKeyContainsWildCards,
		[Parameter(Mandatory = $false)]
		[array]
		$DisplayNamesToExclude = $global:PackageConfig.DisplayNamesToExcludeFromAppSearches
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ([string]::IsNullOrEmpty($UninstallKey)) {
			Write-Log -Message "Cannot retrieve information about installed applications: No uninstallkey or display name defined." -Severity 2 -Source ${CmdletName}
		}
		else {
			try {
				if ($true -eq $UninstallKeyContainsWildCards) {
					if ($true -eq $UninstallKeyIsDisplayName) {
						[PSCustomObject]$installedAppResults = Get-InstalledApplication -Name $UninstallKey -WildCard
					}
					else {
						[PSCustomObject]$installedAppResults = Get-InstalledApplication -Name "*" -WildCard | Where-Object UninstallSubkey -Like $UninstallKey
						foreach ($installedAppResult in $installedAppResults) {
							Write-Log -Message "Selected [$($installedAppResult.DisplayName)] version [$($installedAppResult.DisplayVersion)] using wildcard matching UninstallKey [$UninstallKey] from the results above." -Source ${CmdletName}
						}
					}
				}
				else {
					if ($true -eq $UninstallKeyIsDisplayName) {
						[PSCustomObject]$installedAppResults = Get-InstalledApplication -Name $UninstallKey -Exact
					}
					else {
						[PSCustomObject]$installedAppResults = Get-InstalledApplication -ProductCode $UninstallKey | Where-Object UninstallSubkey -eq $UninstallKey
					}
				}
				foreach ($displayNameToExclude in $DisplayNamesToExclude) {
					$installedAppResults = $installedAppResults | Where-Object DisplayName -ne $displayNameToExclude
					Write-Log -Message "Excluded [$displayNameToExclude] from the results above." -Source ${CmdletName}
				}
				Write-Output $installedAppResults
			}
			catch {
				Write-Log -Message "Failed to retrieve information about installed applications based on [$UninstallKey]. `n$(Resolve-Error)" -Severity 2 -Source ${CmdletName}
			}
		}
		
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Get-NxtIsSystemProcess
function Get-NxtIsSystemProcess {
	<#
	.DESCRIPTION
		Detects if process is running with system account or not.
	.PARAMETER ProcessId
		Id of the process.
	.OUTPUTS
		System.Boolean.
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
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Get-NxtNameBySid
function Get-NxtNameBySid {
	<#
	.DESCRIPTION
		Gets the netbios user name for a SID.
		Returns $null if SID was not found.
	.PARAMETER Sid
		SID to search.
	.OUTPUTS
		System.String.
	.EXAMPLE
		Get-NxtNameBySid -Sid "S-1-5-21-3072877179-2344900292-1557472252-500"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Sid
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
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
#region Function Get-NxtOsLanguage
function Get-NxtOsLanguage {
	<#
	.DESCRIPTION
		Gets OsLanguage as LCID Code from the Get-Culture cmdlet.
	.EXAMPLE
		Get-NxtOsLanguage
	.OUTPUTS
		System.Int.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
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
#region Function Get-NxtPackageConfig
function Get-NxtPackageConfig {
	<#
	.DESCRIPTION
		Parses a neo42PackageConfig.json into the variable $global:PackageConfig.
	.PARAMETER Path
		Path to the Packageconfig.json
		Defaults to "$global:Neo42PackageConfigPath"
	.EXAMPLE
		Get-NxtPackageConfig
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$Path = "$global:Neo42PackageConfigPath"
	)
		
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[PSObject]$global:PackageConfig = Get-Content $Path | Out-String | ConvertFrom-Json
		Write-Log -Message "Package configuration successfully parsed into global:PackageConfig object." -Source ${CmdletName}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Get-NxtParentProcess
function Get-NxtParentProcess {
	<#
	.DESCRIPTION
		Gets the Parent Process of a given Process ID.
	.PARAMETER Id
		The Id of the child process.
	.OUTPUTS
		System.Management.ManagementBaseObject.
	.EXAMPLE
		Get-NxtParentProcess -Id 1234 -Recurse
	.EXAMPLE
		Get-NxtParentProcess
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter()]
		[int]
		$Id = $global:PID,
		[Parameter()]
		[switch]
		$Recurse = $false
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[System.Management.ManagementBaseObject]$process = Get-WmiObject Win32_Process -filter "ProcessID ='$ID'"
		[System.Management.ManagementBaseObject]$parentProcess = Get-WmiObject Win32_Process -filter "ProcessID ='$($process.ParentProcessId)'"
		Write-Output $parentProcess
		if ($Recurse -and ![string]::IsNullOrEmpty($parentProcess)) {
			Get-NxtParentProcess -Id ($process.ParentProcessId) -Recurse
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Get-NxtProcessEnvironmentVariable
function Get-NxtProcessEnvironmentVariable {
	<#
	.DESCRIPTION
		Gets the value of the process environment variable.
	.PARAMETER Key
		Key of the variable.
	.OUTPUTS
		System.String.
	.EXAMPLE
		Get-NxtProcessEnvironmentVariable "Test"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Key
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[string]$result = $null
		try {
			[string]$result = [System.Environment]::GetEnvironmentVariable($Key, [System.EnvironmentVariableTarget]::Process)
		}
		catch {
			Write-Log -Message "Failed to get the process environment variable with key '$Key'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		Write-Output $result
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Get-NxtProcessName
function Get-NxtProcessName {
	<#
	.DESCRIPTION
		Gets name of process.
		Returns an empty string if process was not found.
	.PARAMETER ProcessId
		Id of the process.
	.EXAMPLE
		Get-NxtProcessName 1004
	.OUTPUTS
		System.String.
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
	}
	Process {
		[string]$result = [string]::Empty
		try {
			[string]$result = (Get-Process -Id $ProcessId).Name
		}
		catch {
			Write-Log -Message "Failed to get the name for process with pid '$ProcessId'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		Write-Output $result
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Get-NxtProcessorArchiteW6432
function Get-NxtProcessorArchiteW6432 {
	<#
	.DESCRIPTION
		Gets the environment variable $env:PROCESSOR_ARCHITEW6432 which is only set in a x86_32 process, returns empty string if run under 64-Bit Process.
	.PARAMETER PROCESSOR_ARCHITEW6432
		Defines the String to be returned.
		Defaults to $env:PROCESSOR_ARCHITEW6432.
	.EXAMPLE
		Get-NxtProcessorArchiteW6432
	.OUTPUTS
		System.String.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter()]
		[ValidateSet($null, "AMD64")]
		[string]
		$PROCESSOR_ARCHITEW6432 = $env:PROCESSOR_ARCHITEW6432
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			Write-Output $PROCESSOR_ARCHITEW6432
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
#region Function Get-NxtRegisteredPackage
function Get-NxtRegisteredPackage {
	<#
	.SYNOPSIS
		Retrieves information about registered packages on a local machine.
	.DESCRIPTION
		Gets details of the registered application packages installed on a local machine by using registry keys.
		The function fetches details such as PackageGUID, ProductGUID, and InstalledState, and returns an object of type PSADTNXT.NxtRegisteredApplication.
	.PARAMETER ProductGUID
		Specifies a membership GUID for a product of an application package.
		Can be found under "HKLM:\Software\<RegPackagesKey>\<PackageGUID>" for an application package with product membership.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PackageGUID
		Specifies the registry key name used for the packages wrapper uninstall entry.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER InstalledState
		Represents the installation state of the package in a binary string ("0" or "1"):
		"0" represents that the package is not installed
		"1" represents that the package is installed.
	.PARAMETER RegPackagesKey
		Defines the name of the registry key keeping track of all packages delivered by this packaging framework.
		Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Get-NxtRegisteredPackage -PackageGUID "12345678-1234-1234-1234-123456789012"
	.EXAMPLE
		Get-NxtRegisteredPackage -ProductGUID "12345678-1234-1234-1234-123456789012"
	.EXAMPLE
		Get-NxtRegisteredPackage -ProductGUID "12345678-1234-1234-1234-123456789012" -InstalledState 1
	.INPUTS
		None.
	.OUTPUTS
		PSADTNXT.NxtRegisteredApplication object with properties: PackageGUID, ProductGUID, Installed.
	.NOTES
		- If the specified RegPackagesKey does not exist in the registry, the function writes a log message and stops execution.
		- If the PackageGUID provided is not a valid GUID, it continues to the next registered package.
		- If the InstalledState is provided, it converts "0" to False and "1" to True before comparison.
		- If not provided the optional parameter ProductGUID, the function will return information about all products, filtered by the other FilterParameters.
		- If not provided the optional parameter PackageGUID, the function will return information about all packages starting with '{042'.
		- If not provided the optional parameter InstalledState, the function will return the installed state for all packages, filtered by the other FilterParameters.
		- The output of the function can be used as input to other functions that need information about installed packages.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$PackageGUID,
		[Parameter(Mandatory = $false)]
		[string]
		$ProductGUID,
		[Parameter(Mandatory = $false)]
		[string]
		[ValidateSet("0", "1")]
		$InstalledState,
		[Parameter(Mandatory = $false)]
		[string]
		$RegPackagesKey = $global:PackageConfig.RegPackagesKey
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ($false -eq (Test-Path -Path "HKLM:\Software\$RegPackagesKey")) {
			Write-Log -Message "Registry key 'HKLM:\Software\$RegPackagesKey' does not exist." -Source ${cmdletName}
			return
		}
		[Microsoft.Win32.RegistryKey[]]$neoPackages = Get-ChildItem "HKLM:\Software\$RegPackagesKey"
		foreach ($neoPackage in $neoPackages) {
			[string]$neoPackageGUID = [string]::Empty
			[string]$neoProductGUID = [string]::Empty
			[bool]$neoPackageIsInstalled = $false
			[PSADTNXT.NxtRegisteredApplication]$registeredApplication = New-Object -TypeName PSADTNXT.NxtRegisteredApplication
			[string]$neoPackageGUID = $neoPackage.PSChildName
			## Check if the PackageGUID is a valid GUID
			if ( $false -eq [System.Guid]::TryParse($neoPackageGUID, [ref][System.Guid]::Empty)) {
				continue
			}
			if ([string]::IsNullOrEmpty($PackageGUID)) {
				if ($false -eq $neoPackageGUID.StartsWith("{042")) {
					continue
				}
			}
			else {
				if ($PackageGUID -ne $neoPackageGUID) {
					continue
				}
			}
			[string]$neoProductGUID = Get-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$neoPackageGUID" -Value "ProductGUID"
			if ($false -eq [string]::IsNullOrEmpty($ProductGUID)) {
				if ($neoProductGUID -ne $ProductGUID) {
					continue
				}
			}
			##cast 1 into true and 0 into false
			[bool]$neoPackageIsInstalled = ( (Get-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$neoPackageGUID" -Value "Installed" ) -eq "1" )
			if ($false -eq [string]::IsNullOrEmpty($InstalledState)) {
				if ([System.Convert]::ToBoolean([System.Convert]::ToInt32($InstalledState)) -ne $neoPackageIsInstalled) {
					continue
				}
			}
			$registeredApplication.PackageGUID = $neoPackageGUID
			$registeredApplication.ProductGUID = $neoProductGUID
			$registeredApplication.Installed = $neoPackageIsInstalled
			Write-Output $registeredApplication
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Get-NxtRegisterOnly
function Get-NxtRegisterOnly {
	<#
	.SYNOPSIS
		Detects if the target application is already installed
	.DESCRIPTION
		Uses registry values to detect the application in target or higher versions
	.PARAMETER PackageRegisterPath
		Specifies the registry path used for the registered package (wrapper) entries
		Defaults to the default location under "HKLM:\Software" constructed with corresponding values from the PackageConfig objects of 'RegPackagesKey' and 'PackageGUID'.
	.PARAMETER SoftMigration
		Specifies if a Software should be registered only if it already exists through a different installation.
		Defaults to the corresponding value from the Setup.cfg.
	.PARAMETER DisplayVersion
		Specifies the DisplayVersion of the Software Package.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKey
		Specifies the original UninstallKey set by the Installer in this Package.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER SoftMigrationFileName
		Specifies a file name (instead of DisplayVersion) depending a SoftMigration of the Software Package.
		Defaults to the corresponding value from the PackageConfig object $global:PackageConfig.SoftMigration.File.FullNameToCheck.
	.PARAMETER SoftMigrationFileVersion
		Specifies the file version of the file name specified (instead of DisplayVersion) depending a SoftMigration of the Software Package.
		Defaults to the corresponding value from the PackageConfig object $global:PackageConfig.SoftMigration.File.VersionToCheck.
	.PARAMETER SoftMigrationCustomResult
		Specifies the result of a custom check routine for a SoftMigration of the Software Package.
		Defaults to the corresponding value from the Deploy-Aplication.ps1 object $global:SoftMigrationCustomResult.
	.PARAMETER RegisterPackage
		Specifies if package may be registered.
		Defaults to the corresponding global value.
	.PARAMETER RemovePackagesWithSameProductGUID
		Defines to uninstall found all application packages with same ProductGUID (product membership) assigned.
		The uninstalled application packages stay registered, when removed during installation process of current application package.
		Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Get-NxtRegisterOnly
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$PackageRegisterPath = "HKLM:\Software\$($global:PackageConfig.RegPackagesKey)\$($global:PackageConfig.PackageGUID)",
		[Parameter(Mandatory = $false)]
		[bool]
		$SoftMigration = [bool]([int]$global:SetupCfg.Options.SoftMigration),
		[Parameter(Mandatory = $false)]
		[string]
		$DisplayVersion = $global:PackageConfig.DisplayVersion,
		[Parameter(Mandatory = $false)]
		[string]
		$UninstallKey = $global:PackageConfig.UninstallKey,
		[Parameter(Mandatory = $false)]
		[string]
		$SoftMigrationFileName = $global:PackageConfig.SoftMigration.File.FullNameToCheck,
		[Parameter(Mandatory = $false)]
		[string]
		$SoftMigrationFileVersion = $global:PackageConfig.SoftMigration.File.VersionToCheck,
		[Parameter(Mandatory = $false)]
		[bool]
		$SoftMigrationCustomResult = $global:SoftMigrationCustomResult,
		[Parameter(Mandatory = $false)]
		[string]
		$RegisterPackage = $global:registerPackage,
		[Parameter(Mandatory = $false)]
		[bool]
		$RemovePackagesWithSameProductGUID = $global:PackageConfig.RemovePackagesWithSameProductGUID
	)
	if ($false -eq $RegisterPackage) {
		Write-Log -Message 'Package should not be registered. Performing an (re)installation depending on found application state...' -Source ${cmdletName}
		Write-Output $false
	}
	elseif ( ($true -eq $SoftMigration) -and -not (Test-RegistryValue -Key $PackageRegisterPath -Value 'ProductName') -and ((Get-NxtRegisteredPackage -ProductGUID "PackageGUID").count -eq 0) -and -not $RemovePackagesWithSameProductGUID ) {
		if ($true -eq $SoftMigrationCustomResult) {
			Write-Log -Message 'Application is already present (pre-checked individually). Installation is not executed. Only package files are copied and package is registered. Performing SoftMigration ...' -Source ${cmdletName}
			Write-Output $true
		}
		elseif ( $false -eq ([string]::IsNullOrEmpty($SoftMigrationFileName)) ) {
			if ($true -eq (Test-Path -Path $SoftMigrationFileName)) {
				if ( $false -eq ([string]::IsNullOrEmpty($SoftMigrationFileVersion)) ) {
					[string]$currentlyDetectedFileVersion = (Get-Item -Path "$SoftMigrationFileName").VersionInfo.FileVersionRaw    
					Write-Log -Message "Currently detected file version [$($currentlyDetectedFileVersion)] for SoftMigration detection file [$SoftMigrationFileName] with expected version [$SoftMigrationFileVersion]." -Source ${cmdletName}
					if ( (Compare-NxtVersion -DetectedVersion $currentlyDetectedFileVersion -TargetVersion $SoftMigrationFileVersion) -ne "Update" ) {
						Write-Log -Message "Application is already present (checked by FileVersion). Installation is not executed. Only package files are copied and package is registered. Performing SoftMigration ..." -Source ${cmdletName}
						Write-Output $true
					}
					elseif ($false -eq $SoftMigrationCustomResult) {
						Write-Log -Message 'No valid conditions for SoftMigration present.' -Source ${cmdletName}
						Write-Output $false
					}
				}
				elseif ( $true -eq ([string]::IsNullOrEmpty($SoftMigrationFileVersion)) ) {
					Write-Log -Message "SoftMigration detection file [$SoftMigrationFileName] found." -Source ${cmdletName}
					Write-Log -Message "Application is already present (checked by FileName). Installation is not executed. Only package files are copied and package is registered. Performing SoftMigration ..." -Source ${cmdletName}
					Write-Output $true
				}
			}
			elseif ($false -eq $SoftMigrationCustomResult) {
				Write-Log -Message 'No valid conditions for SoftMigration present.' -Source ${cmdletName}
				Write-Output $false
			}
		}
		else {
			[string]$currentlyDetectedDisplayVersion = (Get-NxtCurrentDisplayVersion).DisplayVersion
			if ($true -eq [string]::IsNullOrEmpty($DisplayVersion)) {
				Write-Log -Message 'DisplayVersion in this package config is $null or empty. SoftMigration not possible.' -Source ${cmdletName}
				Write-Output $false
			}
			elseif ($true -eq [string]::IsNullOrEmpty($currentlyDetectedDisplayVersion)) {
				Write-Log -Message 'Currently detected DisplayVersion is $null or empty. SoftMigration not possible.' -Source ${cmdletName}
				Write-Output $false
			}
			elseif ( (Compare-NxtVersion -DetectedVersion $currentlyDetectedDisplayVersion -TargetVersion $DisplayVersion) -ne "Update" ) {
				Write-Log -Message 'Application is already present (checked by DisplayVersion). Installation is not executed. Only package files are copied and package is registered. Performing SoftMigration ...' -Source ${cmdletName}
				Write-Output $true
			}
			else {
				Write-Log -Message 'No valid conditions for SoftMigration present.' -Source ${cmdletName}
				Write-Output $false
			}
		}
	}
	elseif ( ($false -eq $SoftMigration) -and -not (Test-RegistryValue -Key $PackageRegisterPath -Value 'ProductName') ) {
		Write-Log -Message 'SoftMigration is disabled. Performing an (re)installation depending on found application state...' -Source ${cmdletName}
		Write-Output $false
	}
	else {
		Write-Log -Message 'No valid conditions for SoftMigration present.' -Source ${cmdletName}
		Write-Output $false
	}
}
#endregion
#region Function Get-NxtServiceState
function Get-NxtServiceState {
	<#
	.DESCRIPTION
		Gets the state of the given service name.
		Returns $null if service was not found.
	.PARAMETER ServiceName
		Name of the service.
	.OUTPUTS
		System.String.
	.EXAMPLE
		Get-NxtServiceState "BITS"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$ServiceName
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[System.Management.ManagementBaseObject]$service = Get-WmiObject -Query "Select State from Win32_Service Where Name = '$($ServiceName)'" | Select-Object -First 1
			if ($service) {
				Write-Output $service.State
			}
			else {
				Write-Output $null
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
#region Function Get-NxtSidByName
function Get-NxtSidByName {
	<#
	.DESCRIPTION
		Gets the SID for a given user name,
		Returns $null if user is not found.
	.PARAMETER UserName
		Name of the user to search.
	.EXAMPLE
		Get-NxtSidByName -UserName "Workgroup\Administrator"
	.OUTPUTS
		none.
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
			Write-Log -Message "Failed to get the sid for the user '$UserName'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Get-NxtSystemEnvironmentVariable
function Get-NxtSystemEnvironmentVariable {
	<#
	.DESCRIPTION
		Gets the value of the system environment variable.
	.PARAMETER Key
		Key of the variable.
	.OUTPUTS
		System.String.
	.EXAMPLE
		Get-NxtSystemEnvironmentVariable "windir"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Key
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[string]$result = $null
		try {
			[string]$result = [System.Environment]::GetEnvironmentVariable($Key, [System.EnvironmentVariableTarget]::Machine)
		}
		catch {
			Write-Log -Message "Failed to get the system environment variable with key '$Key'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
		Write-Output $result
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Get-NxtUILanguage
function Get-NxtUILanguage {
	<#
	.DESCRIPTION
		Gets UiLanguage as LCID Code from Get-UICulture.
	.EXAMPLE
		Get-NxtUILanguage
	.OUTPUTS
		System.Int.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
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
#region Function Get-NxtVariablesFromDeploymentSystem
function Get-NxtVariablesFromDeploymentSystem {
	<#
	.SYNOPSIS
		Gets environment variables set by the deployment system
	.DESCRIPTION
		Should be called at the end of the variable definition section of any 'Deploy-Application.ps1' 
		Variables not set by the deployment system (or set to an unsuitable value) get a default value (e.g. [bool]$global:$registerPackage = $true)
		Variables set by the deployment system overwrite the values from the neo42PackageConfig.json
	.PARAMETER RegisterPackage
		Value to set $global:RegisterPackage to. Defaults to $env:registerPackage
	.PARAMETER UninstallOld
		Value to set $global:UninstallOld to. Defaults to $env:uninstallOld
	.EXAMPLE
		Get-NxtVariablesFromDeploymentSystem
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$RegisterPackage = $env:registerPackage,
		[Parameter(Mandatory = $false)]
		[string]
		$UninstallOld = $env:uninstallOld,
		[Parameter(Mandatory = $false)]
		[string]
		$Reboot = $env:Reboot
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		Write-Log -Message "Getting environment variables set by the deployment system..." -Source ${cmdletName}
		try {
			if ("false" -eq $RegisterPackage) {
				[bool]$global:RegisterPackage = $false 
			} 
			else { 
				[bool]$global:RegisterPackage = $true
			}
			## actually this $global:UninstallOld is not be used, because no re-overriding in this way should be allowed yet
			if ("false" -eq $UninstallOld) {
				[bool]$global:UninstallOld = $false
			}
			if ($null -ne $Reboot) {
				[int]$global:Reboot = $Reboot
			}
			Write-Log -Message "Environment variables successfully read." -Source ${cmdletName}
		}
		catch {
			Write-Log -Message "Failed to get environment variables. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Get-NxtWindowsBits
function Get-NxtWindowsBits {
	<#
	.DESCRIPTION
		Translates the environment variable $env:PROCESSOR_ARCHITECTURE from x86 and amd64 to 32 / 64.
	.PARAMETER ProcessorArchitecture
		Accepts the string "x86" or "AMD64".
		Defaults to $env:PROCESSOR_ARCHITECTURE.
	.EXAMPLE
		Get-NxtWindowsBits
	.OUTPUTS
		System.Int.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter()]
		[string]
		$ProcessorArchitecture = $env:PROCESSOR_ARCHITECTURE
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			switch ($ProcessorArchitecture.ToUpper()) {
				"AMD64" { 
					Write-Output 64
				}
				"X86" {
					Write-Output 32
				}
				Default {
					Write-Error "$($ProcessorArchitecture) could not be translated to CPU bitness 'WindowsBits'"
				}
			}
		}
		catch {
			Write-Log -Message "Failed to translate $($ProcessorArchitecture) variable. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Get-NxtWindowsVersion
function Get-NxtWindowsVersion {
	<#
	.DESCRIPTION
		Gets the Windows Version (CurrentVersion) from the Registry.
	.EXAMPLE
		Get-NxtWindowsVersion
	.OUTPUTS
		System.String.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
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
#region Function Import-NxtIniFile
function Import-NxtIniFile {
	<#
	.SYNOPSIS
		Imports an INI file into Powershell Object.
	.DESCRIPTION
		Imports an INI file into Powershell Object.
	.PARAMETER Path
		The path to the INI file.
	.EXAMPLE
		Import-NxtIniFile -Path C:\path\to\ini\file.ini
	.NOTES
		AppDeployToolkit is required in order to run this function.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[String]
		$Path,
		[Parameter(Mandatory = $false)]
		[bool]
		$ContinueOnError = $true
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[hashtable]$ini = @{}
			[string]$section = 'default'
			[Array]$content = Get-Content -Path $Path
			foreach ($line in $content) {
				if ($line -match '^\[(.+)\]$') {
					[string]$section = $matches[1]
					if (!$ini.ContainsKey($section)) {
						[hashtable]$ini[$section] = @{}
					}
				}
				elseif ($line -match '^(;|#)') {
				}
				elseif ($line -match '^(.+?)\s*=\s*(.*)$') {
					[string]$variableName = $matches[1]
					[string]$value = $matches[2]
					[string]$ini[$section][$variableName] = $value
				}
			}
			Write-Output $ini
			Write-Log -Message "Read ini file [$path]. " -Source ${CmdletName}
		}
		catch {
			Write-Log -Message "Failed to read ini file [$path]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			if (-not $ContinueOnError) {
				throw "Failed to read ini file [$path]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Import-NxtIniFileWithComments
function Import-NxtIniFileWithComments {
    <#
	.SYNOPSIS
		Imports an INI file into Powershell Object.
	.DESCRIPTION
		Imports an INI file into Powershell Object.
	.PARAMETER Path
		The path to the INI file.
	.PARAMETER ContinueOnError
		Continue on error.
	.EXAMPLE
		Import-NxtIniFileWithComments -Path C:\path\to\ini\file.ini
	.NOTES
		AppDeployToolkit is required in order to run this function.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Path,
        [Parameter(Mandatory = $false)]
        [bool]
        $ContinueOnError = $true
    )
    try {
        [hashtable]$ini = @{}
        [string]$section = 'default'
        [array]$commentBuffer = @()
        [Array]$content = Get-Content -Path $Path
        foreach ($line in $content) {
            if ($line -match '^\[(.+)\]$') {
                [string]$section = $matches[1]
                if (!$ini.ContainsKey($section)) {
                    [hashtable]$ini[$section] = @{}
                }
            }
            elseif ($line -match '^(;|#)\s*(.*)') {
                [array]$commentBuffer += $matches[2].trim("; ")
            }
            elseif ($line -match '^(.+?)\s*=\s*(.*)$') {
                [string]$variableName = $matches[1]
                [string]$value = $matches[2].Trim()
                [hashtable]$ini[$section][$variableName] = @{
                    Value    = $value.trim()
                    Comments = $commentBuffer -join "`r`n"
                }
                [array]$commentBuffer = @()
            }
        }
        Write-Output $ini
    }
    catch {
        if (-not $ContinueOnError) {
            throw "Failed to read ini file [$path]: $($_.Exception.Message)"
        }
    }
}
#endregion
#region Function Initialize-NxtEnvironment
function Initialize-NxtEnvironment {
	<#
	.DESCRIPTION
		Initializes all neo42 functions and variables.
		Should be called on top of any 'Deploy-Application.ps1'.
		parses the neo42PackageConfig.json
	.PARAMETER PackageConfigPath
		Defines the path to the Packageconfig.json to be loaded to the global packageconfig Variable.
		Defaults to "$global:Neo42PackageConfigPath"
	.PARAMETER SetupCfgPath
		Defines the path to the Setup.cfg to be loaded to the global setupcfg Variable.
		Defaults to the "$global:SetupCfgPath".
	.PARAMETER SetupCfgPathOverride
		Defines the path to the Setup.cfg to be loaded to the global setupcfg Variable.
		Defaults to "$env:temp\$($global:Packageconfig.RegPackagesKey)\$($global:Packageconfig.PackageGUID)".
	.OUTPUTS
		System.Int32.
	.EXAMPLE
		Initialize-NxtEnvironment
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$PackageConfigPath = "$global:Neo42PackageConfigPath",
		[Parameter(Mandatory = $false)]
		[string]
		$SetupCfgPath = "$global:SetupCfgPath",
		[Parameter(Mandatory = $false)]
		[string]
		$CustomSetupCfgPath = "$global:CustomSetupCfgPath",
		[Parameter(Mandatory = $false)]
		[string]
		$SetupCfgPathOverride = "$env:temp\$($global:Packageconfig.RegPackagesKey)\$($global:Packageconfig.PackageGUID)"
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		Get-NxtPackageConfig -Path $PackageConfigPath
		if ($true -eq (Test-path $SetupCfgPathOverride\setupOverride.cfg)) {
			Move-NxtItem -Path $SetupCfgPathOverride\setupOverride.cfg -Destination $SetupCfgPathOverride\setup.cfg
			Set-NxtSetupCfg -Path $SetupCfgPathOverride\setup.cfg
		}
		else {
			if (
				$true -eq (Test-path $SetupCfgPathOverride) -and
				$SetupCfgPathOverride -like "$env:temp\$($global:Packageconfig.RegPackagesKey)\*"
			) {
				Remove-Item -Recurse $SetupCfgPathOverride
			}
			Set-NxtSetupCfg -Path $SetupCfgPath
		}
		Set-NxtCustomSetupCfg -Path $CustomSetupCfgPath
		if (0 -ne $(Set-NxtPackageArchitecture)) {
			throw "Error during setting package architecture variables."
		}
		[string]$global:DeploymentTimestamp = Get-Date -format "yyyy-MM-dd_HH-mm-ss"
		Expand-NxtPackageConfig
		Format-NxtPackageSpecificVariables
		switch ($SetupCfg.Options.ShowBalloonNotifications) {
			"0"	{
				[bool]$script:configShowBalloonNotifications = $false
				Write-Log -Message "Overriding ShowBalloonNotifications setting from XML config: balloon notifications deactivated" -Source ${CmdletName}
			}
			"1" {
				[bool]$script:configShowBalloonNotifications = $true
				Write-Log -Message "Overriding ShowBalloonNotifications setting from XML config: balloon notifications activated" -Source ${CmdletName}
			}
			"2" {
				## Use ShowBalloonNotifications setting from XML config
			}
			default {
				if ($false -eq [string]::IsNullOrEmpty($SetupCfg.Options.ShowBalloonNotifications)) {
					throw "Not supported value detected for option 'SHOWBALLOONNOTIFICATIONS' while reading setting from setup.cfg"
				}
			}
		}		
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Initialize-NxtUninstallApplication
function Initialize-NxtUninstallApplication {
	<#
	.SYNOPSIS
		Defines the required steps to prepare the uninstallation of the package
	.DESCRIPTION
		Unhides all defined registry keys from a corresponding value in the PackageConfig object.
		Is only called in the Main function and should not be modified!
		To customize the script always use the "CustomXXXX" entry points.
	.PARAMETER UninstallKeysToHide
		Specifies a list of UninstallKeys set by the Installer(s) in this Package, which the function will hide from the user (e.g. under "Apps" and "Programs and Features").
		Defaults to the corresponding values from the PackageConfig object.
	.EXAMPLE
		Initialize-NxtUninstallApplication
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[PSCustomObject]
		$UninstallKeysToHide = $global:PackageConfig.UninstallKeysToHide
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		foreach ($uninstallKeyToHide in $UninstallKeysToHide) {
			[string]$wowEntry = [string]::Empty
			if ($false -eq $uninstallKeyToHide.Is64Bit -and $true -eq $Is64Bit) {
				$wowEntry = "\Wow6432Node"
			}
			if ($true -eq $uninstallKeyToHide.KeyNameIsDisplayName) {
				[string]$currentKeyName = (Get-NxtInstalledApplication -UninstallKey $uninstallKeyToHide.KeyName -UninstallKeyIsDisplayName $true).UninstallSubkey
			}
			else {
				[string]$currentKeyName = $uninstallKeyToHide.KeyName
			}
			if (Get-RegistryKey -Key "HKLM:\Software$wowEntry\Microsoft\Windows\CurrentVersion\Uninstall\$currentKeyName" -Value SystemComponent) {
				Remove-RegistryKey -Key "HKLM:\Software$wowEntry\Microsoft\Windows\CurrentVersion\Uninstall\$currentKeyName" -Name 'SystemComponent'
			}
			else {
				if ($true -eq $uninstallKeyToHide.KeyNameIsDisplayName) {
					Write-Log -Message "Did not find an uninstall registry key with DisplayName [$($uninstallKeyToHide.KeyName)]. Skipped deleting SystemComponent entry." -Source ${CmdletName}
				}
				else {
					Write-Log -Message "Did not find a SystemComponent entry under registry key [$currentKeyName]. Skipped deleting the entry for this key." -Source ${CmdletName}
				}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Install-NxtApplication
function Install-NxtApplication {
	<#
	.SYNOPSIS
		Defines the required steps to install the application based on the target installer type
	.DESCRIPTION
		Is only called in the Main function and should not be modified!
		To customize the script always use the "CustomXXXX" entry points.
	.PARAMETER UninstallKey
		Name of the uninstall registry key of the application (e.g. "This Application_is1" or "{XXXXXXXX-XXXX-XXXXXXXX-XXXXXXXXXXXX}_is1").
		Can be found under "HKLM:\Software\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\".
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyIsDisplayName
		Determins if the value given as UninstallKey should be interpreted as a displayname.
		Only applies to Inno Setup, Nullsoft and BitRockInstaller.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyContainsWildCards
		Determines if the value given as UninstallKey contains WildCards.
		If set to $true "*" are interpreted as WildCards.
		If set to $false "*" are interpreted as part of the actual string.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER DisplayNamesToExclude
		DisplayName(s) to exclude, when retrieving Data about the application from the uninstall key in the registry.
		Use commas to separate more than one value.
		"*" inside this parameter will not be interpreted as WildCards. (This has no effect on the use of WildCards in other parameters!)
		We reccommend always adding "$global:PackageConfig.UninstallDisplayName" if used inside a package to exclude the current package itself, especially if combined with the "UninstallKeyContainsWildCards" parameter.
		Defaults to the "DisplayNamesToExcludeFromAppSearches" value from the PackageConfig object.
	.PARAMETER InstLogFile
		Defines the path to the Logfile that should be used by the installer.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER InstFile
		Defines the path to the Installation File.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER InstPara
		Defines the parameters which will be passed in the Installation Commandline.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppendInstParaToDefaultParameters
		If set to $true the parameters specified with InstPara are added to the default parameters specified in the XML configuration file.
		If set to $false the parameters specified with InstPara overwrite the default parameters specified in the XML configuration file.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AcceptedInstallExitCodes
		Defines a list of exit codes or * for all exit codes that will be accepted for success by called setup execution.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER InstallMethod
		Defines the type of the installer used in this package.
		Defaults to the corresponding value from the PackageConfig object
	.PARAMETER PreSuccessCheckTotalSecondsToWaitFor
		Timeout in seconds the function waits and checks for the condition to occur.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PreSuccessCheckProcessOperator
		Operator to define process condition requirements.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PreSuccessCheckProcessesToWaitFor
		An array of process conditions to check for.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PreSuccessCheckRegKeyOperator
		Operator to define regkey condition requirements.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PreSuccessCheckRegkeysToWaitFor
		An array of regkey conditions to check for.
		Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Install-NxtApplication
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[String]
		$UninstallKey = $global:PackageConfig.UninstallKey,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyIsDisplayName = $global:PackageConfig.UninstallKeyIsDisplayName,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyContainsWildCards = $global:PackageConfig.UninstallKeyContainsWildCards,
		[Parameter(Mandatory = $false)]
		[array]
		$DisplayNamesToExclude = $global:PackageConfig.DisplayNamesToExcludeFromAppSearches,
		[Parameter(Mandatory = $false)]
		[String]
		$InstLogFile = $global:PackageConfig.InstLogFile,
		[Parameter(Mandatory = $false)]
		[string]
		$InstFile = $global:PackageConfig.InstFile,
		[Parameter(Mandatory = $false)]
		[string]
		$InstPara = $global:PackageConfig.InstPara,
		[Parameter(Mandatory = $false)]
		[bool]
		$AppendInstParaToDefaultParameters = $global:PackageConfig.AppendInstParaToDefaultParameters,
		[Parameter(Mandatory = $false)]
		[string]
		$AcceptedInstallExitCodes = $global:PackageConfig.AcceptedInstallExitCodes,
		[Parameter(Mandatory = $false)]
		[string]
		$InstallMethod = $global:PackageConfig.InstallMethod,
		[Parameter(Mandatory = $false)]
		[int]
		$PreSuccessCheckTotalSecondsToWaitFor = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Install.TotalSecondsToWaitFor,
		[Parameter(Mandatory = $false)]
		[string]
		$PreSuccessCheckProcessOperator = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Install.ProcessOperator,
		[Parameter(Mandatory = $false)]
		[array]
		$PreSuccessCheckProcessesToWaitFor = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Install.ProcessesToWaitFor,
		[Parameter(Mandatory = $false)]
		[string]
		$PreSuccessCheckRegKeyOperator = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Install.RegKeyOperator,
		[Parameter(Mandatory = $false)]
		[array]
		$PreSuccessCheckRegkeysToWaitFor = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Install.RegkeysToWaitFor
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[PSADTNXT.NxtApplicationResult]$installResult = New-Object -TypeName PSADTNXT.NxtApplicationResult
		if ($InstallMethod -eq "none") {
			$installResult.ApplicationExitCode = $null
			$installResult.ErrorMessage = "An installation method was not set. Skipping a default process execution."
			$installResult.Success = $null
			[int]$logMessageSeverity = 1
		}
		else {
			$installResult.Success = $false
			[int]$logMessageSeverity = 1
			[hashtable]$executeNxtParams = @{
				Action                        = 'Install'
				Path                          = "$InstFile"
				UninstallKeyIsDisplayName     = $UninstallKeyIsDisplayName
				UninstallKeyContainsWildCards	= $UninstallKeyContainsWildCards
				DisplayNamesToExclude         = $DisplayNamesToExclude
			}
			if (![string]::IsNullOrEmpty($InstPara)) {
				if ($AppendInstParaToDefaultParameters) {
					[string]$executeNxtParams["AddParameters"] = "$InstPara"
				}
				else {
					[string]$executeNxtParams["Parameters"] = "$InstPara"
				}
			}
			if (![string]::IsNullOrEmpty($AcceptedInstallExitCodes)) {
				[string]$executeNxtParams["IgnoreExitCodes"] = "$AcceptedInstallExitCodes"
			}
			if ([string]::IsNullOrEmpty($UninstallKey)) {
				[string]$internalInstallerMethod = [string]::Empty
			}
			else {
				[string]$internalInstallerMethod = $InstallMethod
			}

			switch -Wildcard ($internalInstallerMethod) {
				MSI {
					Execute-NxtMSI @executeNxtParams -Log "$InstLogFile"
				}
				"Inno*" {
					Execute-NxtInnoSetup @executeNxtParams -UninstallKey "$UninstallKey" -Log "$InstLogFile"
				}
				Nullsoft {
					Execute-NxtNullsoft @executeNxtParams -UninstallKey "$UninstallKey"
				}
				"BitRock*" {
					Execute-NxtBitRockInstaller @executeNxtParams -UninstallKey "$UninstallKey"
				}
				Default {
					[hashtable]$executeParams = @{
						Path	= "$InstFile"
					}
					if (![string]::IsNullOrEmpty($InstPara)) {
						[string]$executeParams["Parameters"] = "$InstPara"
					}
					if (![string]::IsNullOrEmpty($AcceptedExitCodes)) {
						[string]$ExecuteParams["IgnoreExitCodes"] = "$AcceptedExitCodes"
					}
					Execute-Process @executeParams
				}
			}
			$installResult.MainExitCode = $mainExitCode
			$installResult.ApplicationExitCode = $LastExitCode
			## Delay for filehandle release etc. to occur.
			Start-Sleep -Seconds 5

			## Test for successfull installation (if UninstallKey value is set)
			if ([string]::IsNullOrEmpty($UninstallKey)) {
				$installResult.ErrorMessage = "UninstallKey value NOT set. Skipping test for successfull installation of '$appName' via registry."
				$installResult.Success = $null
				[int]$logMessageSeverity = 2
			}
			else {
				if ( $false -eq (Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor $PreSuccessCheckTotalSecondsToWaitFor -ProcessOperator $PreSuccessCheckProcessOperator -ProcessesToWaitFor $PreSuccessCheckProcessesToWaitFor -RegKeyOperator $PreSuccessCheckRegKeyOperator -RegkeysToWaitFor $PreSuccessCheckRegkeysToWaitFor) ) {
					$installResult.ErrorMessage = "Installation RegistryAndProcessCondition of '$appName' failed. ErrorLevel: $($installResult.ApplicationExitCode)"
					$installResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
					$installResult.Success = $false
					[int]$logMessageSeverity = 3
				}
				else {
					if ($false -eq $(Test-NxtAppIsInstalled -UninstallKey "$UninstallKey" -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -DeploymentMethod $internalInstallerMethod)) {
						$installResult.ErrorMessage = "Installation of '$appName' failed. ErrorLevel: $($installResult.ApplicationExitCode)"
						$installResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
						$installResult.Success = $false
						[int]$logMessageSeverity = 3
					}
					else {
						$installResult.ErrorMessage = "Installation of '$appName' was successful."
						$installResult.Success = $true
						[int]$logMessageSeverity = 1
					}
				}
			}
		}
		Write-Log -Message $($installResult.ErrorMessage) -Severity $logMessageSeverity -Source ${CmdletName}
		Write-Output $installResult
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Move-NxtItem
function Move-NxtItem {
	<#
	.DESCRIPTION
		Renames or moves a file or directory.
	.EXAMPLE
		Move-NxtItem -Path C:\Temp\Sources\Installer.exe -Destination C:\Temp\Sources\Installer_bak.exe
	.PARAMETER Path
		Source Path of the File or Directory.
	.PARAMETER Destination
		Destination Path for the File or Directory.
	.PARAMETER Force
		Overwrite existing file.
	.PARAMETER ContinueOnError
		Continue if an error is encountered. Default is: $true.
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[String]
		$Path,
		[Parameter(Mandatory = $true)]
		[String]
		$Destination,
		[Parameter(Mandatory = $false)]
		[switch]
		$Force,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[array]$functionParametersToBeRemoved = (
				"ContinueOnError"
			)
			foreach ($functionParameterToBeRemoved in $functionParametersToBeRemoved) {
				$null = $PSBoundParameters.Remove($functionParameterToBeRemoved)
			}
			Write-Log -Message "Move '$path' to '$Destination'." -Source ${cmdletName}
			Move-Item @PSBoundParameters -ErrorAction Stop
		}
		catch {
			Write-Log -Message "Failed to move '$Path' to '$Destination'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
			if (-not $ContinueOnError) {
				throw "Failed to move '$Path' to '$Destination'`: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function New-NxtWpfControl
function New-NxtWpfControl() {
	<#
	.DESCRIPTION
		Creates a WPF control.
	.PARAMETER InputXml
		Xml input that is converted to a WPF control.
	.EXAMPLE
		New-NxtWpfControl -InputXml $inputXml
	.OUTPUTS
		none.
	.NOTES
		This is an internal script function and should typically not be called directly. It is used by the Show-NxtWelcomePrompt to create the WPF control.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	Param(
		[Parameter(Mandatory = $True)]
		[string]
		$InputXml
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
		$InputXml = $InputXml -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
		#Read XAML
		[xml]$xaml = $InputXml
		[System.Xml.XmlNodeReader]$reader = (New-Object System.Xml.XmlNodeReader $xaml)
		try {
			[System.Windows.Window]$control = [Windows.Markup.XamlReader]::Load($reader)
		}
		catch {  
			Write-Log "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed." -Severity 3
			throw "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
		}
		return $control
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}

#endregion
#region Function Read-NxtSingleXmlNode
function Read-NxtSingleXmlNode {
	<#
	.DESCRIPTION
		Reads single node of xml file.
	.PARAMETER XmlFilePath
		Path to the xml file.
	.PARAMETER SingleNodeName
		Node path. (https://www.w3schools.com/xml/xpath_syntax.asp).
	.EXAMPLE
		Read-NxtSingleXmlNode -XmlFilePath "C:\Test\setup.xml" -SingleNodeName "//UserId"
	.OUTPUTS
		System.String.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$XmlFilePath,
		[Parameter(Mandatory = $true)]
		[string]
		$SingleNodeName
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
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
#region Function Register-NxtPackage
function Register-NxtPackage {
	<#
	.SYNOPSIS
		Copies package files and registers the package in the registry.
	.DESCRIPTION
		Copies the package files to the local store and writes the package's registry keys under "HKLM:\Software\$regPackagesKey\$PackageGUID" and "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID".
	.PARAMETER App
		Defines the path to a local persistent cache for installation files.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppName
        Specifies the Application Name used in the registry etc.
        Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppVendor
		Specifies the Application Vendor used in the registry etc.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppVersion
		Specifies the Application Version used in the registry etc.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppRevision
		Specifies the Application Revision used in the registry etc.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppArch
		Specifies the package architecture ("x86", "x64" or "*").
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER DisplayVersion
		Specifies the DisplayVersion used in the registry etc.
		Defaults to the corresponding value from the PackageConfig object.
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
	.PARAMETER UninstallDisplayName
		Specifies the DisplayName used in the corresponding value uninstall key in the Registry.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UserPartOnUninstallation
		Specifies if a Userpart should take place during uninstallation.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UserPartOnInstallation
		Specifies if a Userpart should take place during installation.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UserPartRevision
		Specifies the UserPartRevision for this installation.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER HidePackageUninstallButton
		Specifies if the Uninstallbutton for this installation should be hidden.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER HidePackageUninstallEntry
		Specifies if the PackageUninstallEntry for this installation should be hidden.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER ScriptParentPath
		Specifies the ScriptParentPath.
		Defaults to $scriptParentPath defined in the AppDeployToolkitMain.
	.PARAMETER ConfigToolkitLogDir
		Specifies the ConfigToolkitLogDir.
		Defaults to $configToolkitLogDir defined in the AppDeployToolkitMain.
	.PARAMETER Logname
		Specifies the Logname.
		Defaults to $logname defined in the AppDeployToolkitMain.
	.PARAMETER MainExitCode
		The value, the script returns to the deployment system and that will be written as LastExitCode to the package entry in the the registry.
		Defaults to the variable $mainExitCode.
	.PARAMETER PackageStatus
		The value, that will be written as PackageStatus to the package entry in the the registry.
		Defaults to "Success".
	.PARAMETER UninstallOld
		Defines if the Setting "Uninstallold" is set.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER EnvUserDomain
		Defines the EnvUserDomain.
		Defaults to $envUserDomain derived from [Environment]::UserDomainName.
	.PARAMETER EnvArchitecture
		Defines the EnvArchitecture.
		Defaults to $envArchitecture derived from $env:PROCESSOR_ARCHITECTURE.
	.PARAMETER ProcessNTAccountSID
		Defines the NT Account SID the current Process is run as.
		Defaults to $ProcessNTAccountSID defined in the PSADT Main script.
	.PARAMETER LastErrorMessage
		If set the message is written to the registry.
		Defaults to the $global:LastErrorMessage.
	.PARAMETER SetupCfgPathOverride
		Defines the SetupCfgPathOverride.
		Defaults to $env:temp\$($global:Packageconfig.RegPackagesKey)\$($global:Packageconfig.PackageGUID).
	.EXAMPLE
		Register-NxtPackage
	.NOTES
		Should be executed at the end of each neo42-package installation and when using Soft Migration only.
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$AppName = $global:PackageConfig.AppName,
		[Parameter(Mandatory = $false)]
		[string]
		$AppVendor = $global:PackageConfig.AppVendor,
		[Parameter(Mandatory = $false)]
		[string]
		$AppVersion = $global:PackageConfig.AppVersion,
		[Parameter(Mandatory = $false)]
		[string]
		$AppRevision = $global:PackageConfig.AppRevision,
		[Parameter(Mandatory = $false)]
		[string]
		$AppArch = $global:PackageConfig.AppArch,
		[Parameter(Mandatory = $false)]
		[string]
		$DisplayVersion = $global:PackageConfig.DisplayVersion,
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
		$UninstallDisplayName = $global:PackageConfig.UninstallDisplayName,
		[Parameter(Mandatory = $false)]
		[string]
		$App = $global:PackageConfig.App,
		[Parameter(Mandatory = $false)]
		[bool]
		$UserPartOnInstallation = $global:PackageConfig.UserPartOnInstallation,
		[Parameter(Mandatory = $false)]
		[bool]
		$UserPartOnUnInstallation = $global:PackageConfig.UserPartOnUnInstallation,
		[Parameter(Mandatory = $false)]
		[string]
		$UserPartRevision = $global:PackageConfig.UserPartRevision,
		[Parameter(Mandatory = $false)]
		[bool]
		$HidePackageUninstallButton = $global:PackageConfig.HidePackageUninstallButton,
		[Parameter(Mandatory = $false)]
		[bool]
		$HidePackageUninstallEntry = $global:PackageConfig.HidePackageUninstallEntry,
		[Parameter(Mandatory = $false)]
		[string]
		$ScriptParentPath = $scriptParentPath,
		[Parameter(Mandatory = $false)]
		[string]
		$ConfigToolkitLogDir = $configToolkitLogDir,
		[Parameter(Mandatory = $false)]
		[string]
		$LogName = $logName,
		[Parameter(Mandatory = $false)]
		[string]
		$MainExitCode = $mainExitCode,
		[Parameter(Mandatory = $false)]
		[string]
		$PackageStatus = "Success",
		[Parameter(Mandatory = $false)]
		[string]
		$EnvArchitecture = $envArchitecture,
		[Parameter(Mandatory = $false)]
		[string]
		$EnvUserDomain = $envUserDomain,
		[Parameter(Mandatory = $false)]
		[string]
		$EnvUserName = $envUserName,
		[Parameter(Mandatory = $false)]
		[string]
		$ProcessNTAccountSID = $ProcessNTAccountSID,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallOld = $global:PackageConfig.UninstallOld,
		[Parameter(Mandatory = $false)]
		[string]
		$SetupCfgPathOverride = "$env:temp\$($global:Packageconfig.RegPackagesKey)\$($global:Packageconfig.PackageGUID)",
		[Parameter(Mandatory = $false)]
		[string]
		$LastErrorMessage = $global:LastErrorMessage
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		Write-Log -Message "Registering package..." -Source ${cmdletName}
		try {
			Copy-File -Path "$scriptRoot" -Destination "$App\neo42-Install\" -Recurse
			Copy-File -Path "$ScriptParentPath\Deploy-Application.ps1" -Destination "$App\neo42-Install\"
			Copy-File -Path "$global:Neo42PackageConfigPath" -Destination "$App\neo42-Install\"
			Copy-File -Path "$global:Neo42PackageConfigValidationPath" -Destination "$App\neo42-Install\"
			if ($true -eq (Test-Path "$SetupCfgPathOverride\Setup.cfg")) {
				Move-NxtItem -Path "$SetupCfgPathOverride\Setup.cfg" -Destination "$App\neo42-Install\" -Force
				Remove-Item -Recurse -Path "$SetupCfgPathOverride"
			} elseif ($true -eq (Test-Path "$ScriptParentPath\Setup.cfg")) {
				Copy-File -Path "$ScriptParentPath\Setup.cfg" -Destination "$App\neo42-Install\"
			} else {
				Write-Log -Message "Could not copy default setup config file 'setup.cfg'. There is no such file provided with this package." -Severity 2 -Source ${cmdletName}
			}
			if ($true -eq (Test-Path "$ScriptParentPath\CustomSetup.cfg")) {
				Copy-File -Path "$ScriptParentPath\CustomSetup.cfg" -Destination "$App\neo42-Install\"
				Write-Log -Message "Found a custom setup config file 'CustomSetup.cfg' too..."-Source ${cmdletName}
			}
			Copy-File -Path "$scriptRoot\$($xmlConfigFile.GetElementsByTagName('BannerIcon_Options').Icon_Filename)" -Destination "$App\neo42-Install\"
	
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'AppPath' -Value $App
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'Date' -Value (Get-Date -format "yyyy-MM-dd HH:mm:ss")
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'DebugLogFile' -Value $ConfigToolkitLogDir\$LogName
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'DeveloperName' -Value $AppVendor
			if (![string]::IsNullOrEmpty($LastErrorMessage)) {
				Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'LastErrorMessage' -Value $LastErrorMessage
			}
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'LastExitCode' -Value $MainExitCode
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'PackageArchitecture' -Value $AppArch
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'PackageStatus' -Value $PackageStatus
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'ProductName' -Value $AppName
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'Revision' -Value $AppRevision
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'SrcPath' -Value $ScriptParentPath
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'StartupProcessor_Architecture' -Value $EnvArchitecture
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'StartupProcessOwner' -Value $EnvUserDomain\$EnvUserName
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'StartupProcessOwnerSID' -Value $ProcessNTAccountSID
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'UninstallOld' -Type 'Dword' -Value $UninstallOld
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'UninstallString' -Value ("""$env:Systemroot\System32\WindowsPowerShell\v1.0\powershell.exe"" -ex bypass -WindowStyle hidden -file ""$App\neo42-Install\Deploy-Application.ps1"" uninstall")
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'UserPartOnInstallation' -Value $UserPartOnInstallation -Type 'DWord'
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'UserPartOnUninstallation' -Value $UserPartOnUnInstallation -Type 'DWord'
			if ($true -eq $UserPartOnInstallation) {
				Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'UserPartPath' -Value ('"' + $App + '\neo42-Userpart"')
				Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'UserPartUninstPath' -Value ('"%AppData%\neoPackages\' + $PackageGUID + '"')
				Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'UserPartRevision' -Value $UserPartRevision
			}
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'Version' -Value $AppVersion
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'ProductGUID' -Value $ProductGUID
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'RemovePackagesWithSameProductGUID' -Type 'Dword' -Value $RemovePackagesWithSameProductGUID

			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'DisplayIcon' -Value $App\neo42-Install\$(Split-Path "$scriptRoot\$($xmlConfigFile.GetElementsByTagName('BannerIcon_Options').Icon_Filename)" -Leaf)
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'DisplayName' -Value $UninstallDisplayName
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'DisplayVersion' -Value $AppVersion
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'MachineKeyName' -Value $RegPackagesKey\$PackageGUID
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'NoModify' -Type 'Dword' -Value 1
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'NoRemove' -Type 'Dword' -Value $HidePackageUninstallButton
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'NoRepair' -Type 'Dword' -Value 1
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'PackageApplicationDir' -Value $App
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'PackageProductName' -Value $AppName
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'PackageRevision' -Value $AppRevision
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'DisplayVersion' -Value $DisplayVersion
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'Publisher' -Value $AppVendor
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'SystemComponent' -Type 'Dword' -Value $HidePackageUninstallEntry
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'UninstallString' -Type 'ExpandString' -Value ("""$env:Systemroot\System32\WindowsPowerShell\v1.0\powershell.exe"" -ex bypass -WindowStyle hidden -file ""$App\neo42-Install\Deploy-Application.ps1"" uninstall")
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'Installed' -Type 'Dword' -Value '1'
			Remove-RegistryKey "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")"
			Write-Log -Message "Package registration successful." -Source ${cmdletName}
		}
		catch {
			Write-Log -Message "Failed to register package. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Remove-NxtDesktopShortcuts
function Remove-NxtDesktopShortcuts {
	<#
	.SYNOPSIS
		By default: Removes the Shortcots defined under "CommonDesktopShortcutsToDelete" in the neo42PackageConfig.json from the common desktop.
	.DESCRIPTION
		Is called after an installation/reinstallation if DESKTOPSHORTCUT=0 is defined in the Setup.cfg.
		Is always called before the uninstallation.
	.PARAMETER DesktopShortcutsToDelete
		A list of Desktopshortcuts that should be deleted.
		Defaults to the CommonDesktopShortcutsToDelete value from the PackageConfig object.
	.PARAMETER Desktop
		Specifies the path to the Desktop (eg. $envCommonDesktop or $envUserDesktop).
		Defaults to $envCommonDesktop defined in AppDeploymentToolkitMain.ps1.
	.EXAMPLE
		Remove-NxtDesktopShortcuts
	.EXAMPLE
		Remove-NxtDesktopShortcuts -DesktopShortcutsToDelete "SomeUserShortcut.lnk" -Desktop "$envUserDesktop"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string[]]
		$DesktopShortcutsToDelete = $global:PackageConfig.CommonDesktopShortcutsToDelete,
		[Parameter(Mandatory = $false)]
		[string]
		$Desktop = $envCommonDesktop
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			foreach ($value in $DesktopShortcutsToDelete) {
				Write-Log -Message "Removing desktop shortcut '$Desktop\$value'..." -Source ${cmdletName}
				Remove-File -Path "$Desktop\$value"
				Write-Log -Message "Desktop shortcut succesfully removed." -Source ${cmdletName}
			}
		}
		catch {
			Write-Log -Message "Failed to remove desktopshortcuts from [$Desktop]. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Remove-NxtEmptyFolder
function Remove-NxtEmptyFolder {
	<#
	.SYNOPSIS
		Removes only empty folders.
	.DESCRIPTION
		Removes folders only if they are empty and continues otherwise without any action.
	.PARAMETER Path
		Path to the empty folder to remove.
	.EXAMPLE
		Remove-NxtEmptyFolder -Path "$installLocation\SomeEmptyFolder"
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Path
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		Write-Log -Message "Check if [$Path] exists and is empty..." -Source ${CmdletName}
		if (Test-Path -LiteralPath $Path -PathType 'Container') {
			try {
				if ( (Get-ChildItem $Path | Measure-Object).Count -eq 0) {
					Write-Log -Message "Delete empty folder [$Path]..." -Source ${CmdletName}
					Remove-Item -LiteralPath $Path -Force -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorRemoveFolder'
					if ($ErrorRemoveFolder) {
						Write-Log -Message "The following error(s) took place while deleting the empty folder [$Path]. `n$(Resolve-Error -ErrorRecord $ErrorRemoveFolder)" -Severity 2 -Source ${CmdletName}
					}
					else {
						Write-Log -Message "Empty folder [$Path] was deleted successfully..." -Source ${CmdletName}
					}
				}
				else {
					Write-Log -Message "Folder [$Path] is not empty, so it was not deleted..." -Source ${CmdletName}
				}
			}
			catch {
				Write-Log -Message "Failed to delete empty folder [$Path]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				if (-not $ContinueOnError) {
					throw "Failed to delete empty folder [$Path]: $($_.Exception.Message)"
				}
			}
		}
		else {
			Write-Log -Message "Folder [$Path] does not exist..." -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Remove-NxtLocalGroup
function Remove-NxtLocalGroup {
	<#
	.DESCRIPTION
		Deletes a local group with the given name.
	.PARAMETER GroupName
		Name of the group.
	.PARAMETER Computername
		Name of the Computer,
		Defaults to $env:COMPUTERNAME.
	.EXAMPLE
		Remove-NxtLocalGroup -GroupName "TestGroup"
	.OUTPUTS
		System.Boolean.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$GroupName,
		[Parameter(Mandatory = $false)]
		[string]
		$COMPUTERNAME = $env:COMPUTERNAME
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[bool]$groupExists = Test-NxtLocalGroupExists -GroupName $GroupName
			if ($groupExists) {
				[System.DirectoryServices.DirectoryEntry]$adsiObj = [ADSI]"WinNT://$COMPUTERNAME"
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
#region Function Remove-NxtLocalGroupMember
function Remove-NxtLocalGroupMember {
	<#
	.DESCRIPTION
		Removes a single member or a type of member from the given group by name.
		Returns the amount of members removed.
		Returns $null if the group(s) could not be found.
	.PARAMETER GroupName
		Name of the Group to remove Members from.
	.PARAMETER MemberName
		Name of the member to remove.
	.PARAMETER Users
		If defined all users are removed.
	.PARAMETER Groups
		If defined all groups are removed.
	.PARAMETER AllMember
		If defined all members are removed.
	.PARAMETER Computername
		Name of the Computer,
		Defaults to $env:COMPUTERNAME.
	.EXAMPLE
		Remove-NxtLocalGroupMember -GroupName "Users" -All
	.EXAMPLE
		Remove-NxtLocalGroupMember -GroupName "Administrators" -MemberName "Dummy"
	.OUTPUTS
		System.Int32.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$GroupName,
		[Parameter(ParameterSetName = 'SingleMember')]
		[ValidateNotNullOrEmpty()]
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
		$AllMember,
		[Parameter(Mandatory = $false)]
		[string]
		$COMPUTERNAME = $env:COMPUTERNAME
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[bool]$groupExists = ([ADSI]::Exists("WinNT://$COMPUTERNAME/$GroupName,group"))
			if ($groupExists) {
				[System.DirectoryServices.DirectoryEntry]$group = [ADSI]"WinNT://$COMPUTERNAME/$GroupName,group"
				if ([string]::IsNullOrEmpty($MemberName)) {
					[int]$count = 0
					foreach ($member in $group.psbase.Invoke("Members")) {
						[string]$class = $member.GetType().InvokeMember("Class", 'GetProperty', $Null, $member, $Null)
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
#region Function Remove-NxtLocalUser
function Remove-NxtLocalUser {
	<#
	.DESCRIPTION
		Deletes a local group by name.
	.PARAMETER UserName
		Name of the user.
	.PARAMETER Computername
		Name of the Computer,
		Defaults to $env:COMPUTERNAME.
	.EXAMPLE
		Remove-NxtLocalUser -UserName "Test"
	.OUTPUTS
		System.Boolean.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$UserName,
		[Parameter(Mandatory = $false)]
		[string]
		$COMPUTERNAME = $env:COMPUTERNAME
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[bool]$userExists = Test-NxtLocalUserExists -UserName $UserName
			if ($userExists) {
				[System.DirectoryServices.DirectoryEntry]$adsiObj = [ADSI]"WinNT://$COMPUTERNAME"
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
#region Function Remove-NxtProcessEnvironmentVariable
function Remove-NxtProcessEnvironmentVariable {
	<#
	.DESCRIPTION
		Deletes a process environment variable.
	.PARAMETER Key
		Key of the variable.
	.EXAMPLE
		Remove-NxtProcessEnvironmentVariable "Test"
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Key
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[System.Environment]::SetEnvironmentVariable($Key, $null, [System.EnvironmentVariableTarget]::Process)
			Write-Log -Message "Remove the process environment variable with key '$Key'." -Source ${cmdletName}
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
#region Function Remove-NxtProductMember
function Remove-NxtProductMember {
	<#
	.SYNOPSIS
		Removes an installed and registered product member application package.
	.DESCRIPTION
		Removes an application package assigned to a product if the assigned application package is registered and installed only.
		Uses the value 'ProductGUID' in registry sub keys (installed application packages) under 'RegPackagesKey' to detect if an application package is a product member.
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
	.EXAMPLE
		Remove-NxtProductMember
	.EXAMPLE
		Remove-NxtProductMember -ProductGUID "{042XXXXX-XXXX-XXXXXXXX-XXXXXXXXXXXX}" -PackageGUID "{042XXXXX-XXXX-XXXXXXXX-XXXXXXXXXXXX}"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[String]
		$ProductGUID = $global:PackageConfig.ProductGUID,
		[Parameter(Mandatory = $false)]
		[bool]
		$RemovePackagesWithSameProductGUID = $global:PackageConfig.RemovePackagesWithSameProductGUID,
		[Parameter(Mandatory = $false)]
		[String]
		$PackageGUID = $global:PackageConfig.PackageGUID,
		[Parameter(Mandatory = $false)]
		[string]
		$RegPackagesKey = $global:PackageConfig.RegPackagesKey
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[int]$removalCounter = 0
		if ($true -eq $RemovePackagesWithSameProductGUID) {
			(Get-NxtRegisteredPackage -ProductGUID $ProductGUID -InstalledState 1).PackageGUID | Where-Object {$null -ne $($_)} | ForEach-Object {
				[string]$assignedPackageGUID = $_
				## we don't remove the current package inside this function
				if ($assignedPackageGUID -ne $PackageGUID) {
					[string]$assignedPackageUninstallString = $(Get-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$assignedPackageGUID" -Value 'UninstallString')
					Write-Log -Message "Processing product member application package with 'PackageGUID' [$assignedPackageGUID]..." -Source ${CmdletName}
					if (![string]::IsNullOrEmpty($assignedPackageUninstallString)) {
						Write-Log -Message "Removing package with uninstall call: '$assignedPackageUninstallString'." -Source ${CmdletName}
						[Diagnostics.Process]$runUninstallString = (Start-Process -FilePath "$(($assignedPackageUninstallString -split '"', 3)[1])" -ArgumentList "$((($assignedPackageUninstallString -split '"', 3)[2]).Replace('"','`"').Trim())" -PassThru -Wait)
						$runUninstallString.WaitForExit()
						if ($runUninstallString.ExitCode -ne 0) {
							Write-Log -Message "Removal of found product member application package failed with return code '$($runUninstallString.ExitCode)'." -Severity 3 -Source ${CmdletName}
							throw "Removal of found product member application package failed."
						}
						Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$assignedPackageGUID" -Name 'Installed' -Type 'Dword' -Value '0'
						Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$assignedPackageGUID" -Name 'SystemComponent' -Type 'Dword' -Value '1'
						Write-Log -Message "Set current install state and hided the uninstall entry for product member application package with PackageGUID '$assignedPackageGUID'." -Source ${cmdletName}
						$removalCounter += 1
					}
					else {
						Write-Log -Message "Removal of product member package with 'PackageGUID' [$assignedPackageGUID] is not processable. There is no current 'UninstallString' available." -Severity 2 -Source ${cmdletName}
					}
				}
			}
		}
		if ($removalCounter -eq 0) {
			Write-Log -Message "No valid conditions for removal of application packages assigned to a product." -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Remove-NxtSystemEnvironmentVariable
function Remove-NxtSystemEnvironmentVariable {
	<#
	.DESCRIPTION
		Deletes a system environment variable.
	.PARAMETER Key
		Key of the variable.
	.EXAMPLE
		Remove-NxtSystemEnvironmentVariable "Test"
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Key
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[System.Environment]::SetEnvironmentVariable($Key, $null, [System.EnvironmentVariableTarget]::Machine)
			Write-Log -Message "Remove the system environment variable with key '$Key'." -Source ${cmdletName}
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
#region Function Repair-NxtApplication
function Repair-NxtApplication {
	<#
	.SYNOPSIS
		Defines the required steps to repair an MSI based application.
	.DESCRIPTION
		Is only called in the Main function and should not be modified!
		To customize the script always use the "CustomXXXX" entry points.
	.PARAMETER RegPackagesKey
		Defines the name of the registry key keeping track of all packages delivered by this packaging framework.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKey
		Either the applications uninstallregistrykey or the applications displayname, searched for in the regvalue "Displayname" below all uninstallkeys (e.g. "{XXXXXXXX-XXXX-XXXXXXXX-XXXXXXXXXXXX}" or "an application display name").
		Using a displayname value requires to set the parameter -UninstallKeyIsDisplayName to $true.
		Can be found under "HKLM:\Software\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\" (basically this matches with the entry 'ProductCode' in property table inside of source msi file, therefore the InstFile is not provided as parameter for this function).
	.PARAMETER UninstallKeyIsDisplayName
		Determines if the value given as UninstallKey should be interpreted as a displayname.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyContainsWildCards
		Determines if the value given as UninstallKey contains WildCards.
		If set to $true "*" are interpreted as WildCards.
		If set to $false "*" are interpreted as part of the actual string.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER DisplayNamesToExclude
		DisplayName(s) to exclude, when retrieving Data about the application from the uninstall key in the registry.
		Use commas to separate more than one value.
		"*" inside this parameter will not be interpreted as WildCards. (This has no effect on the use of WildCards in other parameters!)
		We reccommend always adding "$global:PackageConfig.UninstallDisplayName" if used inside a package to exclude the current package itself, especially if combined with the "UninstallKeyContainsWildCards" parameter.
		Defaults to the "DisplayNamesToExcludeFromAppSearches" value from the PackageConfig object.
	.PARAMETER DeploymentTimestamp
		Timestamp used for logs (in this case if $Log is empty).
		Defaults to $global:DeploymentTimestamp.
	.PARAMETER RepairLogFile
		Defines the path to the Logfile that should be used by the installer.
		Defaults to a file name "Repair_<ProductCode>.$global:DeploymentTimestamp.log" in app path (a corresponding value from the PackageConfig object).
		Note: <ProductCode> will be retrieved from installed msi by registry with provided Uninstallkey automatically
	.PARAMETER RepairPara
		Defines the parameters which will be passed in the Repair Commandline.
		Defaults to the value "InstPara" from the PackageConfig object.
	.PARAMETER AppendRepairParaToDefaultParameters
		If set to $true the parameters specified with InstPara are added to the default parameters specified in the XML configuration file.
		If set to $false the parameters specified with InstPara overwrite the default parameters specified in the XML configuration file.
		Defaults to the value "AppendInstParaToDefaultParameters" from the PackageConfig object.
	.PARAMETER AcceptedRepairExitCodes
		Defines a list of exit codes or * for all exit codes that will be accepted for success by called setup execution.
		Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Repair-NxtApplication
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$RegPackagesKey = $global:PackageConfig.RegPackagesKey,
		[Parameter(Mandatory = $false)]
		[string]
		$UninstallKey = $global:PackageConfig.UninstallKey,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyIsDisplayName = $global:PackageConfig.UninstallKeyIsDisplayName,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyContainsWildCards = $global:PackageConfig.UninstallKeyContainsWildCards,
		[Parameter(Mandatory = $false)]
		[array]
		$DisplayNamesToExclude = $global:PackageConfig.DisplayNamesToExcludeFromAppSearches,
		[Parameter(Mandatory = $false)]
		[string]
		$DeploymentTimestamp = $global:DeploymentTimestamp,
		[Parameter(Mandatory = $false)]
		[AllowEmptyString()]
		[ValidatePattern("\.log$|^$|^[^\\/]+$")]
		[string]
		$RepairLogFile,
		[Parameter(Mandatory = $false)]
		[string]
		$RepairPara = $global:PackageConfig.InstPara,
		[Parameter(Mandatory = $false)]
		[bool]
		$AppendRepairParaToDefaultParameters = $global:PackageConfig.AppendInstParaToDefaultParameters,
		[Parameter(Mandatory = $false)]
		[string]
		$AcceptedRepairExitCodes = $global:PackageConfig.AcceptedRepairExitCodes
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[PSADTNXT.NxtApplicationResult]$repairResult = New-Object -TypeName PSADTNXT.NxtApplicationResult
		$repairResult.Success = $false
		[int]$logMessageSeverity = 1
		[hashtable]$executeNxtParams = @{
			Action	= 'Repair'
		}
		if ([string]::IsNullOrEmpty($UninstallKey)) {
			$repairResult.MainExitCode = $mainExitCode
			$repairResult.ErrorMessage = "No repair function executable - missing value for parameter 'UninstallKey'!"
			$repairResult.ErrorMessagePSADT = "expected function parameter 'UninstallKey' is empty"
			$repairResult.Success = $false
			[int]$logMessageSeverity = 3
		}
		else {
			$executeNxtParams["Path"] = (Get-NxtInstalledApplication -UninstallKey $UninstallKey -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName).ProductCode
			if ([string]::IsNullOrEmpty($executeNxtParams.Path)) {
				$repairResult.ErrorMessage = "Repair function could not run for provided parameter 'UninstallKey=$UninstallKey'. The expected msi setup of the application seems not to be installed on system!"
				$repairResult.Success = $null
				[int]$logMessageSeverity = 2
			}
			else {
				if (![string]::IsNullOrEmpty($RepairPara)) {
					if ($AppendRepairParaToDefaultParameters) {
						[string]$executeNxtParams["AddParameters"] = "$RepairPara"
					}
					else {
						[string]$executeNxtParams["Parameters"] = "$RepairPara"
					}
				}
				if (![string]::IsNullOrEmpty($AcceptedRepairExitCodes)) {
					[string]$executeNxtParams["IgnoreExitCodes"] = "$AcceptedRepairExitCodes"
				}
				if ([string]::IsNullOrEmpty($RepairLogFile)) {
					## now set default path and name including retrieved ProductCode
					[string]$RepairLogFile = Join-Path -Path $($global:PackageConfig.app) -ChildPath ("Repair_$($executeNxtParams.Path).$DeploymentTimestamp.log")
				}

				## running with parameter -PassThru to get always a valid return code (needed here for validation later) from underlying Execute-MSI
				$repairResult.ApplicationExitCode = (Execute-NxtMSI @executeNxtParams -Log "$RepairLogFile" -RepairFromSource $true -PassThru).ExitCode

				## transferred exitcodes requesting reboot must be set to 0 for this function to return success, for compatibility with the Execute-NxtMSI -PassThru parameter.
				if ( (3010 -eq $repairResult.ApplicationExitCode) -or (1641 -eq $repairResult.ApplicationExitCode) ) {
					$repairResult.ApplicationExitCode = 0
				}
				## Delay for filehandle release etc. to occur.
				Start-Sleep -Seconds 5

				if ( (0 -ne $repairResult.ApplicationExitCode) -or ($false -eq $(Test-NxtAppIsInstalled -UninstallKey "$UninstallKey" -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -DeploymentMethod "MSI")) ) {
					$repairResult.MainExitCode = $mainExitCode
					$repairResult.ErrorMessage = "Repair of '$appName' failed. ErrorLevel: $($repairResult.ApplicationExitCode)"
					$repairResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
					$repairResult.Success = $false
					[int]$logMessageSeverity = 3
				}
				else {
					$repairResult.ErrorMessage = "Repair of '$appName' was successful."
					$repairResult.Success = $true
					[int]$logMessageSeverity = 1
				}
			}
		}
		Write-Log -Message $($repairResult.ErrorMessage) -Severity $logMessageSeverity -Source ${CmdletName}
		Write-Output $repairResult
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Resolve-NxtDependentPackage
function Resolve-NxtDependentPackage {
	<#
	.DESCRIPTION
		Checks if depentent packages are (not) installed and updates the status of the packages accordingly.
	.PARAMETER DependentPackages
		Defines a (list of) dependent package(s) to check.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegPackagesKey
		Defines the Name of the Registry Key keeping track of all Packages delivered by this Packaging Framework.
		Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Resolve-NxtDependentPackages -DependentPackages "$($global:PackageConfig.DependentPackages)"
	.OUTPUTS
		PSADTNXT.ResolvedPackagesResult
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[array]
		$DependentPackages = $global:PackageConfig.DependentPackages,
		[Parameter(Mandatory = $false)]
		[string]
		$RegPackagesKey = $global:PackageConfig.RegPackagesKey
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		foreach ($dependentPackage in $DependentPackages) {
			[PSADTNXT.NxtRegisteredApplication]$registeredDependentPackage = Get-NxtRegisteredPackage -PackageGUID "$($dependentPackage.GUID)"
			Write-Log -message "Processing tasks for dependent application package with PackageGUID [$($dependentPackage.GUID)]..."  -Source ${CmdletName}
			if ($true -eq $registeredDependentPackage.Installed) {
				Write-Log -Message "...is installed." -Source ${CmdletName}
				if ($dependentPackage.DesiredState -eq "Present") {
					Write-Log -Message "Dependent package '$($dependentPackage.GUID)' is already in desired state '$($dependentPackage.DesiredState)'." -Source ${CmdletName}
				}
				elseif ($dependentPackage.DesiredState -eq "Absent") {
					Write-Log -Message "Dependent package '$($dependentPackage.GUID)' is not in desired state '$($dependentPackage.DesiredState)'." -Source ${CmdletName}
					if ($dependentPackage.OnConflict -eq "Uninstall") {
						## Trigger uninstallstring, throw exception if uninstall fails.
						[string]$dependentPackageUninstallString = $(Get-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$($dependentPackage.GUID)" -Value 'UninstallString')
						Write-Log -Message "Removing dependent application package with uninstall call: '$dependentPackageUninstallString'." -Source ${CmdletName}
						[Diagnostics.Process]$runUninstallString = (Start-Process -FilePath "$(($dependentPackageUninstallString -split '"', 3)[1])" -ArgumentList "$((($dependentPackageUninstallString -split '"', 3)[2]).Replace('"','`"').Trim())" -PassThru -Wait)
						$runUninstallString.WaitForExit()
						if ($runUninstallString.ExitCode -ne 0) {
							Write-Log -Message "Removal of dependent application package failed with return code '$($runUninstallString.ExitCode)'." -Severity 3 -Source ${CmdletName}
							throw "Removal of dependent application package failed."
						}
						## !!! next line has to be activated after merging issue #303 -> afterwards unregister is working in newly introduced script depth 0 only!!!
						#Unregister-NxtPackage -RemovePackagesWithSameProductGUID $false -PackageGUID "$($dependentPackage.GUID)" -RegPackagesKey "$RegPackagesKey"
						if ( ($true -eq $(Get-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$($dependentPackage.GUID)" -ReturnEmptyKeyIfExists)) -or ($true -eq $(Get-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$($dependentPackage.GUID)" -ReturnEmptyKeyIfExists )) ) {
							Write-Log -Message "Removal of dependent application package was done not successful." -Severity 3 -Source ${CmdletName}
							throw "Removal of dependent application package not successful."
						}
					}
					elseif ($dependentPackage.OnConflict -eq "Fail") {
						## Throw exception
						Write-Log -Message "Failure: throwing exception: $($dependentPackage.ErrorMessage)" -Severity 3 -Source ${CmdletName}
						throw "Dependent package '$($dependentPackage.GUID)' is not in desired state '$($dependentPackage.DesiredState)'. $($dependentPackage.ErrorMessage)"
					}
					elseif ($dependentPackage.OnConflict -eq "Warn") {
						## Write warning
						Write-Log -Message "$($dependentPackage.ErrorMessage), but still trying to continue" -Severity 2 -Source ${CmdletName}
					}
					elseif ($dependentPackage.OnConflict -eq "Continue") {
						## Do nothing
						Write-Log -Message "Due to the defined action '$($dependentPackage.OnConflict)' still trying to continue." -Source ${CmdletName}
					}
				}
			}
			else {
				if ($false -eq $registeredDependentPackage.Installed) {
					Write-Log -Message "...is not installed, but still registered as product member application package for ProductGUID '$($registeredDependentPackage.ProductGUID)'." -Severity 2 -Source ${CmdletName}
				}
				else {
					Write-Log -Message "...is not registered and not installed." -Source ${CmdletName}
				}
				if ($dependentPackage.DesiredState -eq "Absent") {
					Write-Log -Message "Dependent package '$($dependentPackage.GUID)' is already in desired state '$($dependentPackage.DesiredState)'." -Source ${CmdletName}
				}
				elseif ($dependentPackage.DesiredState -eq "Present") {
					Write-Log -Message "Dependent package '$($dependentPackage.GUID)' is not in desired state '$($dependentPackage.DesiredState)'." -Source ${CmdletName}
					if ($dependentPackage.OnConflict -eq "Uninstall") {
						Write-Log -Message "Defined action '$($dependentPackage.OnConflict)' is not supported in this case, still trying to continue." -Severity 2 -Source ${CmdletName}
					}
					if ($dependentPackage.OnConflict -eq "Fail") {
						## Throw exception
						Write-Log -Message "Failure: throwing exception: $($dependentPackage.ErrorMessage)" -Severity 3 -Source ${CmdletName}
						throw "Dependent package '$($dependentPackage.GUID)' is not in desired state '$($dependentPackage.DesiredState)', $($dependentPackage.ErrorMessage)."
					}
					elseif ($dependentPackage.OnConflict -eq "Warn") {
						## Write warning
						Write-Log -Message "$($dependentPackage.ErrorMessage), but still trying to continue." -Severity 2 -Source ${CmdletName}
					}
					elseif ($dependentPackage.OnConflict -eq "Continue") {
						## Do nothing
						Write-Log -Message "Due to the defined action '$($dependentPackage.OnConflict)' still trying to continue." -Source ${CmdletName}
					}
				}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Set-NxtIniValue
function Set-NxtIniValue {
	<#
	.SYNOPSIS
		Opens or creates an INI file and sets the value of the specified section and key.
	.DESCRIPTION
		Opens or creates an INI file and sets the value of the specified section and key.
	.PARAMETER FilePath
		Path to the INI file.
	.PARAMETER Section
		Section within the INI file.
	.PARAMETER Key
		Key within the section of the INI file.
	.PARAMETER Value
		Value for the key within the section of the INI file. To remove a value, set this variable to $null.
	.PARAMETER ContinueOnError
		Continue if an error is encountered. Default is: $true.
	.PARAMETER Create
		Creates the file if it does not exist. Default is: $true.
	.EXAMPLE
		Set-NxtIniValue -FilePath "$envProgramFilesX86\IBM\Notes\notes.ini" -Section 'Notes' -Key 'KeyFileName' -Value 'MyFile.ID'
	.NOTES
		AppDeployToolkit is required in order to run this function.
	.LINK
		http://psappdeploytoolkit.com
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$FilePath,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Section,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Key,
		# Don't strongly type this variable as [string] b/c PowerShell replaces [string]$Value = $null with an empty string
		[Parameter(Mandatory = $true)]
		[AllowNull()]
		$Value,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[bool]$ContinueOnError = $true,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[bool]$Create = $true
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			if (!(Test-Path -Path $FilePath) -and $Create) {
				New-Item -ItemType File -Path $FilePath -Force
			}

			if (Test-Path -Path $FilePath) {
				Set-IniValue -FilePath $FilePath -Section $Section -Key $Key -Value $Value -ContinueOnError $ContinueOnError
			}
			else {
				Write-Log -Message "INI file '$FilePath' does not exist!" -Source ${CmdletName}
			}
		}
		catch {
			Write-Log -Message "Failed to create INI file or write INI file key value. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Set-NxtPackageArchitecture
function Set-NxtPackageArchitecture {
	<#
	.SYNOPSIS
		Sets variables depending on the $appArch value and the system architecture.
	.DESCRIPTION
		Sets variables (e.g. $ProgramFilesDir[x86], $CommonFilesDir[x86], $System, $Wow6432Node) that are depending on the $appArch (x86, x64 or *) value and the system architecture (AMD64 or x86).
	.PARAMETER AppArch
		Defines the Application Architecture (x86/x64/*)
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PROCESSOR_ARCHITECTURE
		The processor architecture of the system.
		Defaults to $env:PROCESSOR_ARCHITECTURE.
	.PARAMETER ProgramFiles
		The environment variable for the Program Files directory on the system.
		Defaults to $env:ProgramFiles.
	.PARAMETER ProgramFiles(x86)
		The environment variable for the Program Files (x86) directory on the system.
		Defaults to $env:ProgramFiles(x86).
	.PARAMETER CommonProgramFiles
		The environment variable for the Common Program Files directory on the system.
		Defaults to $env:CommonProgramFiles.
	.PARAMETER CommonProgramFiles(x86)
		The environment variable for the Common Program Files (x86) directory on the system.
		Defaults to $env:CommonProgramFiles(x86).
	.PARAMETER SystemRoot
		The environment variable for the root directory of the system.
		Defaults to $env:SystemRoot.
	.PARAMETER deployAppScriptFriendlyName
		The friendly name of the script used for deploying applications.
		Defaults to $deployAppScriptFriendlyName definded in the DeployApplication.ps1.
	.EXAMPLE
		Set-NxtPackageArchitecture -AppArch "x64"
	.NOTES
		Should be executed during package Initialization only.
	.PARAMETER AppArch
		Provide the AppArchitecture.
	.OUTPUTS
		System.Int32.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$AppArch = $global:PackageConfig.AppArch,
		[Parameter(Mandatory = $false)]
		[string]
		$PROCESSOR_ARCHITECTURE = $env:PROCESSOR_ARCHITECTURE,
		[Parameter(Mandatory = $false)]
		[string]
		${ProgramFiles(x86)} = ${env:ProgramFiles(x86)},
		[Parameter(Mandatory = $false)]
		[string]
		$ProgramFiles = $env:ProgramFiles,
		[Parameter(Mandatory = $false)]
		[string]
		${CommonProgramFiles(x86)} = ${env:CommonProgramFiles(x86)},
		[Parameter(Mandatory = $false)]
		[string]
		$CommonProgramFiles = $env:CommonProgramFiles,
		[Parameter(Mandatory = $false)]
		[string]
		$SystemRoot = $env:SystemRoot,
		[Parameter(Mandatory = $false)]
		[string]
		$DeployAppScriptFriendlyName = $deployAppScriptFriendlyName
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		Write-Log -Message "Setting package architecture variables..." -Source ${CmdletName}
		try {
			if ($AppArch -ne 'x86' -and $AppArch -ne 'x64' -and $AppArch -ne '*') {
				[int32]$mainExitCode = 70001
				[int32]$thisFunctionReturnCode = $mainExitCode
				[string]$mainErrorMessage = "ERROR: The value of '$appArch' must be set to 'x86', 'x64' or '*'. Abort!"
				Write-Log -Message $mainErrorMessage -Severity 3 -Source $DeployAppScriptFriendlyName
				throw "Wrong setting for value 'appArch'."
			}
			elseif ($AppArch -eq 'x64' -and $PROCESSOR_ARCHITECTURE -eq 'x86') {
				[int32]$mainExitCode = 70001
				[int32]$thisFunctionReturnCode = $mainExitCode
				[string]$mainErrorMessage = "ERROR: This software package can only be installed on 64 bit Windows systems. Abort!"
				Write-Log -Message $mainErrorMessage -Severity 3 -Source $DeployAppScriptFriendlyName
				throw "This software is not allowed to run on this architecture."
			}
			elseif ($AppArch -eq 'x86' -and $PROCESSOR_ARCHITECTURE -eq 'AMD64') {
				[string]$global:ProgramFilesDir = ${ProgramFiles(x86)}
				[string]$global:ProgramFilesDirx86 = ${ProgramFiles(x86)}
				[string]$global:ProgramW6432 = $ProgramFiles
				[string]$global:CommonFilesDir = ${CommonProgramFiles(x86)}
				[string]$global:CommonFilesDirx86 = ${CommonProgramFiles(x86)}
				[string]$global:CommonProgramW6432 = $CommonProgramFiles
				[string]$global:System = "$SystemRoot\SysWOW64"
				[string]$global:Wow6432Node = '\Wow6432Node'
				[string]$global:RegSoftwarePath = 'HKLM:\Software'
				[string]$global:RegSoftwarePathx86 = 'HKLM:\Software\Wow6432Node'
			}
			elseif (($AppArch -eq 'x86' -or $AppArch -eq '*') -and $PROCESSOR_ARCHITECTURE -eq 'x86') {
				[string]$global:ProgramFilesDir = $ProgramFiles
				[string]$global:ProgramFilesDirx86 = $ProgramFiles
				[string]$global:ProgramW6432 = ''
				[string]$global:CommonFilesDir = $CommonProgramFiles
				[string]$global:CommonFilesDirx86 = $CommonProgramFiles
				[string]$global:CommonProgramW6432 = ''
				[string]$global:System = "$SystemRoot\System32"
				[string]$global:Wow6432Node = ''
				[string]$global:RegSoftwarePath = 'HKLM:\Software'
				[string]$global:RegSoftwarePathx86 = 'HKLM:\Software'
			}
			else {
				[string]$global:ProgramFilesDir = $ProgramFiles
				[string]$global:ProgramFilesDirx86 = ${ProgramFiles(x86)}
				[string]$global:ProgramW6432 = $ProgramFiles
				[string]$global:CommonFilesDir = $CommonProgramFiles
				[string]$global:CommonFilesDirx86 = ${CommonProgramFiles(x86)}
				[string]$global:CommonProgramW6432 = $CommonProgramFiles
				[string]$global:System = "$SystemRoot\System32"
				[string]$global:Wow6432Node = ''
				[string]$global:RegSoftwarePath = 'HKLM:\Software'
				[string]$global:RegSoftwarePathx86 = 'HKLM:\Software\Wow6432Node'
			}
			Write-Log -Message "Package architecture variables successfully set." -Source ${cmdletName}
			[int32]$thisFunctionReturnCode = 0
		}
		catch {
			Write-Log -Message "Failed to set the package architecture variables. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
			[int32]$thisFunctionReturnCode = $mainExitCode
		}
		Write-Output $thisFunctionReturnCode
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Set-NxtProcessEnvironmentVariable
function Set-NxtProcessEnvironmentVariable {
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
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Key,
		[Parameter(Mandatory = $true)]
		[string]
		$Value
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[System.Environment]::SetEnvironmentVariable($Key, $Value, [System.EnvironmentVariableTarget]::Process)
			Write-Log -Message "Process the environment variable with key '$Key' and value '{$Value}'." -Source ${cmdletName}
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
#region Function Set-NxtCustomSetupCfg
function Set-NxtCustomSetupCfg {
	<#
	.SYNOPSIS
		Set the contents from CustomSetup.cfg to $global:CustomSetupCfg.
	.DESCRIPTION
		Imports a CustomSetup.cfg file in INI format.
	.PARAMETER Path
		The path to the CustomSetup.cfg file (including file name).
	.EXAMPLE
		Set-NxtCustomSetupCfg -Path C:\path\to\customsetupcfg\CustomSetup.cfg -ContinueOnError $false
	.NOTES
		AppDeployToolkit is required in order to run this function.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[String]$Path,
		[Parameter(Mandatory = $false)]
		[bool]
		$ContinueOnError = $true
	)
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			[string]$customSetupCfgFileName = Split-Path -path "$Path" -Leaf
			Write-Log -Message "Checking for custom config file [$customSetupCfgFileName] under [$Path]..." -Source ${CmdletName}
			if ($true -eq (Test-Path $Path)) {
				[hashtable]$global:CustomSetupCfg = Import-NxtIniFile -Path $Path -ContinueOnError $ContinueOnError
				Write-Log -Message "[$customSetupCfgFileName] was found and successfully parsed into global:CustomSetupCfg object." -Source ${CmdletName}
				foreach ($sectionKey in $($global:SetupCfg.Keys)) {
					foreach ($sectionKeySubkey in $($global:SetupCfg.$sectionKey.Keys)) {
						if ($null -ne $global:CustomSetupCfg.$sectionKey.$sectionKeySubkey) {
							Write-Log -Message "Override global object value [`$global:SetupCfg.$sectionKey.$sectionKeySubkey] with content from global:CustomSetupCfg object: [$($global:CustomSetupCfg.$sectionKey.$sectionKeySubkey)]" -Source ${CmdletName}
							[string]$global:SetupCfg.$sectionKey.$sectionKeySubkey = $($global:CustomSetupCfg.$sectionKey.$sectionKeySubkey)
						}
					}
				}
			}
			else {
				Write-Log -Message "No [$customSetupCfgFileName] found. Skipped parsing customized values." -Source ${CmdletName}
			}
		}
		catch {
			Write-Log -Message "Failed to set the CustomSetupCfg. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Set-NxtSetupCfg
function Set-NxtSetupCfg {
	<#
	.SYNOPSIS
		Set the contents from Setup.cfg to $global:SetupCfg.
	.DESCRIPTION
		Imports a Setup.cfg file in INI format.
	.PARAMETER Path
		The path to the Setup.cfg file (including file name).
	.EXAMPLE
		Set-NxtSetupCfg -Path C:\path\to\setupcfg\setup.cfg -ContinueOnError $false
	.NOTES
		AppDeployToolkit is required in order to run this function.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[String]$Path,
		[Parameter(Mandatory = $false)]
		[bool]
		$ContinueOnError = $true
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[string]$setupCfgFileName = Split-Path -Path "$Path" -Leaf
		Write-Log -Message "Checking for config file [$setupCfgFileName] under [$Path]..." -Source ${CmdletName}
		if ([System.IO.File]::Exists($Path)) {
			[hashtable]$global:SetupCfg = Import-NxtIniFile -Path $Path -ContinueOnError $ContinueOnError
			Write-Log -Message "[$setupCfgFileName] was found and successfully parsed into global:SetupCfg object." -Source ${CmdletName}
		}
		else {
			Write-Log -Message "No [$setupCfgFileName] found. Skipped parsing values." -Severity 2 -Source ${CmdletName}
			[hashtable]$global:SetupCfg = $null
		}
		## provide all expected predefined values from ADT framework config file if they are missing/undefined in a default file 'setup.cfg' only
		if ($Path -eq $global:SetupCfgPath) {
			if ($null -eq $global:SetupCfg) {
				[hashtable]$global:SetupCfg = @{}
			}
			## note: xml nodes are case-sensitive
			foreach ( $xmlSection in ($xmlConfigFile.AppDeployToolkit_Config.SetupCfg_Parameters.ChildNodes.Name | Where-Object { $_ -ne "#comment" }) ) {
				foreach ( $xmlSectionSubValue in ($xmlConfigFile.AppDeployToolkit_Config.SetupCfg_Parameters.$xmlSection.ChildNodes.Name | Where-Object { $_ -ne "#comment" }) ) {
					if ($null -eq $global:SetupCfg.$xmlSection.$xmlSectionSubValue) {
						if ($null -eq $global:SetupCfg.$xmlSection) {
							[hashtable]$global:SetupCfg.$xmlSection = @{}
						}
						[hashtable]$global:SetupCfg.$xmlSection.add("$($xmlSectionSubValue)", "$($xmlConfigFile.AppDeployToolkit_Config.SetupCfg_Parameters.$xmlSection.$xmlSectionSubValue)")
						Write-Log -Message "Set undefined necessary global object value [`$global:SetupCfg.$($xmlSection).$($xmlSectionSubValue)] with predefined default content: [$($xmlConfigFile.AppDeployToolkit_Config.SetupCfg_Parameters.$xmlSection.$xmlSectionSubValue)]" -Severity 2 -Source ${CmdletName}
					}
				}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Set-NxtSystemEnvironmentVariable
function Set-NxtSystemEnvironmentVariable {
	<#
	.DESCRIPTION
		Sets a system environment variable.
	.PARAMETER Key
		Key of the variable.
	.PARAMETER Value
		Value of the variable.
	.EXAMPLE
		Set-NxtSystemEnvironmentVariable "Test" "Hello world"
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Key,
		[Parameter(Mandatory = $true)]
		[string]
		$Value
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[System.Environment]::SetEnvironmentVariable($Key, $Value, [System.EnvironmentVariableTarget]::Machine)
			Write-Log -Message "Set a system environment variable with key '$Key' and value '{$Value}'." -Source ${cmdletName}
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
#region Function Show-NxtInstallationWelcome
Function Show-NxtInstallationWelcome {
	<#
    .SYNOPSIS
    	Show a welcome dialog prompting the user with information about the installation and actions to be performed before the installation can begin.
    .DESCRIPTION
		The following prompts can be included in the welcome dialog:
			a) Close the specified running applications, or optionally close the applications without showing a prompt (using the -Silent switch).
			b) Defer the installation a certain number of times, for a certain number of days or until a deadline is reached.
			c) Countdown until applications are automatically closed.
			d) Prevent users from launching the specified applications while the installation is in progress.

		Notes:
			The process descriptions are retrieved from WMI, with a fall back on the process name if no description is available. Alternatively, you can specify the description yourself with a '=' symbol - see examples.
			The dialog box will timeout after the timeout specified in the XML configuration file (default 1 hour and 55 minutes) to prevent SCCM installations from timing out and returning a failure code to SCCM. When the dialog times out, the script will exit and return a 1618 code (SCCM fast retry code).
    .PARAMETER Silent
    	Stop processes without prompting the user.
    .PARAMETER CloseAppsCountdown
    	Option to provide a countdown in seconds until the specified applications are automatically closed. This only takes effect if deferral is not allowed or has expired.
    .PARAMETER ForceCloseAppsCountdown
    	Option to provide a countdown in seconds until the specified applications are automatically closed regardless of whether deferral is allowed.
    .PARAMETER PromptToSave
    	Specify whether to prompt to save working documents when the user chooses to close applications by selecting the "Close Programs" button. Option does not work in SYSTEM context unless toolkit launched with "psexec.exe -s -i" to run it as an interactive process under the SYSTEM account.
    .PARAMETER PersistPrompt
    	Specify whether to make the Show-InstallationWelcome prompt persist in the center of the screen every couple of seconds, specified in the AppDeployToolkitConfig.xml. The user will have no option but to respond to the prompt. This only takes effect if deferral is not allowed or has expired.
    .PARAMETER BlockExecution
    	Option to prevent the user from launching processes/applications, specified in -CloseApps, during the installation.
    .PARAMETER AllowDefer
    	Enables an optional defer button to allow the user to defer the installation.
    .PARAMETER AllowDeferCloseApps
    	Enables an optional defer button to allow the user to defer the installation only if there are running applications that need to be closed. This parameter automatically enables -AllowDefer
    .PARAMETER DeferTimes
    	Specify the number of times the installation can be deferred.
		Defaults to the corresponding value from the $global:SetupCfg object.
    .PARAMETER DeferDays
    	Specify the number of days since first run that the installation can be deferred. This is converted to a deadline.
		Defaults to the corresponding value from the $global:SetupCfg object.
    .PARAMETER DeferDeadline
		Specify the deadline date until which the installation can be deferred.
		Specify the date in the local culture if the script is intended for that same culture.
		If the script is intended to run on EN-US machines, specify the date in the format: "08/25/2013" or "08-25-2013" or "08-25-2013 18:00:00"
		If the script is intended for multiple cultures, specify the date in the universal sortable date/time format: "2013-08-22 11:51:52Z"
		The deadline date will be displayed to the user in the format of their culture.
    .PARAMETER MinimizeWindows
    	Specifies whether to minimize other windows when displaying prompt. Defaults to the corresponding value 'MINIMIZEALLWINDOWS' from the Setup.cfg.
    .PARAMETER TopMost
    	Specifies whether the windows is the topmost window. Defaults to the corresponding value 'TOPMOSTWINDOW' from the Setup.cfg.
    .PARAMETER ForceCountdown
    	Specify a countdown to display before automatically proceeding with the installation when a deferral is enabled.
    .PARAMETER CustomText
    	Specify whether to display a custom message specified in the XML file. Custom message must be populated for each language section in the XML.   
    .Parameter IsInstall
        Calls the Show-InstallationWelcome Function differently based on if it is an (un)intallation.
    .PARAMETER ContinueType
    	Specify if the window is automatically closed after the timeout and the further behavior can be influenced with the ContinueType.
    .PARAMETER UserCanCloseAll
    	Specifies if the user can close all applications.
		Defaults to the corresponding value from the $global:SetupCfg object.
    .PARAMETER UserCanAbort
		Specifies if the user can abort the process.
		Defaults to the corresponding value from the $global:SetupCfg object.
    .OUTPUTS
		Exit code depending on the user's response or the timeout.
    .EXAMPLE
		Show-InstallationWelcome -AskKillProcessApps @([pscustomobject]@{Name = "iexplore"},[pscustomobject]@{Name = "winword"},[pscustomobject]@{Name = "excel"})
		Prompt the user to close Internet Explorer, Word and Excel.
    .EXAMPLE
		Show-InstallationWelcome -AskKillProcessApps @([pscustomobject]@{Name = "iexplore"},[pscustomobject]@{Name = "winword"}) -Silent
		Close Word and Excel without prompting the user.
    .EXAMPLE
		Show-InstallationWelcome -AskKillProcessApps @([pscustomobject]@{Name = "iexplore"},[pscustomobject]@{Name = "winword"}) -BlockExecution
		Close Word and Excel and prevent the user from launching the applications while the installation is in progress.
    .EXAMPLE
		Show-InstallationWelcome -AskKillProcessApps @([pscustomobject]@{Name = "winword";Description = "Microsoft Office Word"},[pscustomobject]@{Name = "excel";Description = "Microsoft Office Excel"}) -CloseAppsCountdown 600
		Prompt the user to close Word and Excel, with customized descriptions for the applications and automatically close the applications after 10 minutes.
    .EXAMPLE
		Show-InstallationWelcome -AskKillProcessApps @([pscustomobject]@{Name = "excel"},[pscustomobject]@{Name = "winword"}) -PersistPrompt
		Prompt the user to close Word and Excel.
		By using the PersistPrompt switch, the dialog will return to the center of the screen every couple of seconds, specified in the AppDeployToolkitConfig.xml, so the user cannot ignore it by dragging it aside.
    .EXAMPLE
		Show-InstallationWelcome -AllowDefer -DeferDeadline '25/08/2013'
		Allow the user to defer the installation until the deadline is reached.
    .EXAMPLE
		Show-InstallationWelcome -AskKillProcessApps @([pscustomobject]@{Name = "excel"},[pscustomobject]@{Name = "winword"}) -BlockExecution -AllowDefer -DeferTimes 10 -DeferDeadline '25/08/2013' -CloseAppsCountdown 600
		Close Word and Excel and prevent the user from launching the applications while the installation is in progress.
		Allow the user to defer the installation a maximum of 10 times or until the deadline is reached, whichever happens first.
		When deferral expires, prompt the user to close the applications and automatically close them after 10 minutes.
	.EXAMPLE
		Show-InstallationWelcome -AskKillProcessApps @([pscustomobject]@{Name = "excel"},[pscustomobject]@{Name = "winword"}) -UserCanCloseAll -UserCanAbort
		Prompt the user to close Word and Excel. The user can close all applications or abort the installation.
	.NOTES
		The code of this function is mainly adopted from the PSAppDeployToolkit.
    .LINK
    	https://neo42.de/psappdeploytoolkit
    #>
	[CmdletBinding()]
	Param (
		## Specify whether to prompt user or force close the applications
		[Parameter(Mandatory = $false)]
		[Switch]$Silent = $false,
		## Specify a countdown to display before automatically closing applications where deferral is not allowed or has expired
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Int32]$CloseAppsCountdown = $global:SetupCfg.AskKillProcesses.Timeout,
		## Specify a countdown to display before automatically closing applications whether or not deferral is allowed
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Int32]$ForceCloseAppsCountdown = 0,
		## Specify whether to prompt to save working documents when the user chooses to close applications by selecting the "Close Programs" button
		[Parameter(Mandatory = $false)]
		[Switch]$PromptToSave = $false,
		## Specify whether to make the prompt persist in the center of the screen every couple of seconds, specified in the AppDeployToolkitConfig.xml.
		[Parameter(Mandatory = $false)]
		[Switch]$PersistPrompt = $false,
		## Specify whether to block execution of the processes during installation
		[Parameter(Mandatory = $false)]
		[Switch]$BlockExecution = $($global:PackageConfig.BlockExecution),
		## Specify whether to enable the optional defer button on the dialog box
		[Parameter(Mandatory = $false)]
		[Switch]$AllowDefer = $false,
		## Specify whether to enable the optional defer button on the dialog box only if an app needs to be closed
		[Parameter(Mandatory = $false)]
		[Switch]$AllowDeferCloseApps = $false,
		## Specify the number of times the deferral is allowed
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Int32]$DeferTimes = $global:SetupCfg.AskKillProcesses.DeferTimes,
		## Specify the number of days since first run that the deferral is allowed
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Int32]$DeferDays = $global:SetupCfg.AskKillProcesses.DeferDays,
		## Specify the deadline (in format dd/mm/yyyy) for which deferral will expire as an option
		[Parameter(Mandatory = $false)]
		[String]$DeferDeadline = '',
		## Specify whether to minimize other windows when displaying prompt
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Boolean]$MinimizeWindows = [System.Convert]::ToBoolean([System.Convert]::ToInt32($global:SetupCfg.AskKillProcesses.MINMIZEALLWINDOWS)),
		## Specifies whether the window is the topmost window
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Boolean]$TopMost = [System.Convert]::ToBoolean([System.Convert]::ToInt32($global:SetupCfg.AskKillProcesses.TOPMOSTWINDOW)),
		## Specify a countdown to display before automatically proceeding with the installation when a deferral is enabled
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Int32]$ForceCountdown = 0,
		## Specify whether to display a custom message specified in the XML file. Custom message must be populated for each language section in the XML.
		[Parameter(Mandatory = $false)]
		[Switch]$CustomText = $false,
		[Parameter(Mandatory = $true)]
		[bool]
		$IsInstall,
		[Parameter(Mandatory = $false)]
		[array]
		$AskKillProcessApps = $($global:PackageConfig.AppKillProcesses),
		## this window is automatically closed after the timeout and the further behavior can be influenced with the ContinueType.
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[PSADTNXT.ContinueType]$ContinueType = $global:SetupCfg.AskKillProcesses.ContinueType,
		## Specifies if the user can close all applications
		[Parameter(Mandatory = $false)]
		[Switch]$UserCanCloseAll = [System.Convert]::ToBoolean([System.Convert]::ToInt32($global:SetupCfg.ASKKILLPROCESSES.USERCANCLOSEALL)),
		## Specifies if the user can abort the process
		[Parameter(Mandatory = $false)]
		[Switch]$UserCanAbort = [System.Convert]::ToBoolean([System.Convert]::ToInt32($global:SetupCfg.ASKKILLPROCESSES.ALLOWABORTBYUSER))
	)
	Begin {
		## Get the name of this function and write header
		[String]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		## To break the array references to the parent object we have to create new(copied) objects from the provided array.
		[array]$AskKillProcessApps = $AskKillProcessApps | Select-Object *
		## override $DeferDays with 0 in Case of Uninstall
		if (!$IsInstall) {
			[int]$DeferDays = 0
		}
		## If running in NonInteractive mode, force the processes to close silently
		If ($deployModeNonInteractive) {
			$Silent = $true
		}
        
		[string]$fileExtension = ".exe"
		foreach ( $processAppsItem in $AskKillProcessApps ) {
			if ( "*$fileExtension" -eq "$($processAppsItem.Name)" ) {
				Write-Log -Message "Not supported list entry '*.exe' for 'CloseApps' process collection found, please check the parameter for processes ask to kill in config file!" -Severity 3 -Source ${cmdletName}
				throw "Not supported list entry '*.exe' for 'CloseApps' process collection found, please check the parameter for processes ask to kill in config file!"
			}
			elseif ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($processAppsItem.Name)) {				
				Write-Log -Message "Wildcard in list entry for 'CloseApps' process collection detected, retrieving all matching running processes for '$($processAppsItem.Name)' ..." -Source ${cmdletName}
				## Get-WmiObject Win32_Process always requires an extension, so we add one in case there is none
				[string]$processAppsItem.Name = $($processAppsItem.Name -replace "\$fileExtension$","") + $fileExtension
				[string]$processAppsItem.Name = (($(Get-WmiObject -Query "Select * from Win32_Process Where Name LIKE '$(($processAppsItem.Name).Replace("*","%"))'").name) -replace "\$fileExtension$","") -join ","
				if ( [String]::IsNullOrEmpty($processAppsItem.Name) ) {
					Write-Log -Message "... no processes found." -Source ${cmdletName}
				}
				else {
					Write-Log -Message "... found processes (with file extensions removed): $($processAppsItem.Name)" -Source ${cmdletName}
				}
				## be sure there is no description to add in case of process name with wildcards
				[string]$processAppsItem.Description = [string]::Empty
			}
			else {
				## default item improvement: for later calling of ADT CMDlet no file extension is allowed (remove extension if exist)
				[string]$processAppsItem.Name = $processAppsItem.Name -replace "\$fileExtension$", ""
				if (![String]::IsNullOrEmpty($processAppsItem.Description)) {
					[string]$processAppsItem.Name = $processAppsItem.Name + "=" + $processAppsItem.Description
				}
			}
		}
		[string]$closeApps = ($AskKillProcessApps | Where-Object -property 'Name' -ne '').Name -join ","

		## If using Zero-Config MSI Deployment, append any executables found in the MSI to the CloseApps list
		If ($useDefaultMsi) {
			[string]$closeApps = "$closeApps,$defaultMsiExecutablesList"
		}

		if ($true -eq [string]::IsNullOrEmpty($closeApps)) {
			## prevent BlockExecution function if there is no process to kill
			$BlockExecution = $false
		}
		else {
			## Create a Process object with custom descriptions where they are provided (split on an '=' sign)
			[PSObject[]]$processObjects = @()
			#  Split multiple processes on a comma, then split on equal sign, then create custom object with process name and description
			ForEach ($process in ($closeApps -split ',' | Where-Object { $_ })) {
				If ($process.Contains('=')) {
					[String[]]$ProcessSplit = $process -split '='
					$processObjects += New-Object -TypeName 'PSObject' -Property @{
						ProcessName        = $ProcessSplit[0]
						ProcessDescription = $ProcessSplit[1]
					}
				}
				Else {
					[String]$ProcessInfo = $process
					$processObjects += New-Object -TypeName 'PSObject' -Property @{
						ProcessName        = $process
						ProcessDescription = ''
					}
				}
			}
		}

		## Check Deferral history and calculate remaining deferrals
		If (($allowDefer) -or ($AllowDeferCloseApps)) {
			#  Set $allowDefer to true if $AllowDeferCloseApps is true
			$allowDefer = $true

			#  Get the deferral history from the registry
			$deferHistory = Get-DeferHistory
			$deferHistoryTimes = $deferHistory | Select-Object -ExpandProperty 'DeferTimesRemaining' -ErrorAction 'SilentlyContinue'
			$deferHistoryDeadline = $deferHistory | Select-Object -ExpandProperty 'DeferDeadline' -ErrorAction 'SilentlyContinue'

			#  Reset Switches
			$checkDeferDays = $false
			$checkDeferDeadline = $false
			If ($DeferDays -ne 0) {
				$checkDeferDays = $true
			}
			If ($DeferDeadline) {
				$checkDeferDeadline = $true
			}
			If ($DeferTimes -ne 0) {
				If ($deferHistoryTimes -ge 0) {
					Write-Log -Message "Defer history shows [$($deferHistory.DeferTimesRemaining)] deferrals remaining." -Source ${CmdletName}
					$DeferTimes = $deferHistory.DeferTimesRemaining - 1
				}
				Else {
					$DeferTimes = $DeferTimes - 1
				}
				Write-Log -Message "The user has [$deferTimes] deferrals remaining." -Source ${CmdletName}
				If ($DeferTimes -lt 0) {
					Write-Log -Message 'Deferral has expired.' -Source ${CmdletName}
					$AllowDefer = $false
				}
			}
			Else {
				If (Test-Path -LiteralPath 'variable:deferTimes') {
					Remove-Variable -Name 'deferTimes'
				}
				$DeferTimes = $null
			}
			If ($checkDeferDays -and $allowDefer) {
				If ($deferHistoryDeadline) {
					Write-Log -Message "Defer history shows a deadline date of [$deferHistoryDeadline]." -Source ${CmdletName}
					[String]$deferDeadlineUniversal = Get-UniversalDate -DateTime $deferHistoryDeadline
				}
				Else {
					[String]$deferDeadlineUniversal = Get-UniversalDate -DateTime (Get-Date -Date ((Get-Date).AddDays($deferDays)) -Format ($culture).DateTimeFormat.UniversalDateTimePattern).ToString()
				}
				Write-Log -Message "The user has until [$deferDeadlineUniversal] before deferral expires." -Source ${CmdletName}
				If ((Get-UniversalDate) -gt $deferDeadlineUniversal) {
					Write-Log -Message 'Deferral has expired.' -Source ${CmdletName}
					$AllowDefer = $false
				}
			}
			If ($checkDeferDeadline -and $allowDefer) {
				#  Validate Date
				Try {
					[String]$deferDeadlineUniversal = Get-UniversalDate -DateTime $deferDeadline -ErrorAction 'Stop'
				}
				Catch {
					Write-Log -Message "Date is not in the correct format for the current culture. Type the date in the current locale format, such as 20/08/2014 (Europe) or 08/20/2014 (United States). If the script is intended for multiple cultures, specify the date in the universal sortable date/time format, e.g. '2013-08-22 11:51:52Z'. `r`n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
					Throw "Date is not in the correct format for the current culture. Type the date in the current locale format, such as 20/08/2014 (Europe) or 08/20/2014 (United States). If the script is intended for multiple cultures, specify the date in the universal sortable date/time format, e.g. '2013-08-22 11:51:52Z': $($_.Exception.Message)"
				}
				Write-Log -Message "The user has until [$deferDeadlineUniversal] remaining." -Source ${CmdletName}
				If ((Get-UniversalDate) -gt $deferDeadlineUniversal) {
					Write-Log -Message 'Deferral has expired.' -Source ${CmdletName}
					$AllowDefer = $false
				}
			}
		}
		If (($deferTimes -lt 0) -and (-not $deferDeadlineUniversal)) {
			$AllowDefer = $false
		}

		[string]$promptResult = [string]::Empty
		## Prompt the user to close running applications and optionally defer if enabled
		If ((-not $deployModeSilent) -and (-not $silent)) {
			If ($forceCloseAppsCountdown -gt 0) {
				#  Keep the same variable for countdown to simplify the code:
				$closeAppsCountdown = $forceCloseAppsCountdown
				#  Change this variable to a boolean now to switch the countdown on even with deferral
				[Boolean]$forceCloseAppsCountdown = $true
			}
			ElseIf ($forceCountdown -gt 0) {
				#  Keep the same variable for countdown to simplify the code:
				$closeAppsCountdown = $forceCountdown
				#  Change this variable to a boolean now to switch the countdown on
				[Boolean]$forceCountdown = $true
			}
			Set-Variable -Name 'closeAppsCountdownGlobal' -Value $closeAppsCountdown -Scope 'Script'
			While ((Get-RunningProcesses -ProcessObjects $processObjects -OutVariable 'runningProcesses') -or ((-not $promptResult.Contains('Defer')) -and (-not $promptResult.Contains('Close')))) {
				[String]$runningProcessDescriptions = ($runningProcesses | Where-Object { $_.ProcessDescription } | Select-Object -ExpandProperty 'ProcessDescription') -join ','
				#  If no proccesses are running close
				if ([string]::IsNullOrEmpty($runningProcessDescriptions)) {
					break
				}
				#  Check if we need to prompt the user to defer, to defer and close apps, or not to prompt them at all
				If ($allowDefer) {
					#  If there is deferral and closing apps is allowed but there are no apps to be closed, break the while loop
					If ($AllowDeferCloseApps -and (-not $runningProcessDescriptions)) {
						Break
					}
					#  Otherwise, as long as the user has not selected to close the apps or the processes are still running and the user has not selected to continue, prompt user to close running processes with deferral
					ElseIf ((-not $promptResult.Contains('Close')) -or (($runningProcessDescriptions) -and (-not $promptResult.Contains('Continue')))) {
						[String]$promptResult = Show-NxtWelcomePrompt -ProcessDescriptions $runningProcessDescriptions -CloseAppsCountdown $closeAppsCountdownGlobal -PersistPrompt $PersistPrompt -AllowDefer -DeferTimes $deferTimes -DeferDeadline $deferDeadlineUniversal -MinimizeWindows $MinimizeWindows -CustomText:$CustomText -TopMost $TopMost -ContinueType $ContinueType -UserCanCloseAll:$UserCanCloseAll -UserCanAbort:$UserCanAbort
					}
				}
				#  If there is no deferral and processes are running, prompt the user to close running processes with no deferral option
				ElseIf (($runningProcessDescriptions) -or ($forceCountdown)) {
					[String]$promptResult = Show-NxtWelcomePrompt -ProcessDescriptions $runningProcessDescriptions -CloseAppsCountdown $closeAppsCountdownGlobal -PersistPrompt $PersistPrompt -MinimizeWindows $minimizeWindows -CustomText:$CustomText -TopMost $TopMost -ContinueType $ContinueType -UserCanCloseAll:$UserCanCloseAll -UserCanAbort:$UserCanAbort
				}
				#  If there is no deferral and no processes running, break the while loop
				Else {
					Break
				}

				If ($promptResult.Contains('Cancel')) {
					Write-Log -Message 'The user selected to cancel or grace period to wait for closing processes was over...' -Source ${CmdletName}
                    
					#  Restore minimized windows
					$null = $shellApp.UndoMinimizeAll()

					Write-Output $configInstallationUIExitCode
					return
				}

				#  If the user has clicked OK, wait a few seconds for the process to terminate before evaluating the running processes again
				If ($promptResult.Contains('Continue')) {
					Write-Log -Message 'The user selected to continue...' -Source ${CmdletName}
					Start-Sleep -Seconds 2

					#  Break the while loop if there are no processes to close and the user has clicked OK to continue
					If (-not $runningProcesses) {
						Break
					}
				}
				#  Force the applications to close
				ElseIf ($promptResult.Contains('Close')) {
					Write-Log -Message 'The user selected to force the application(s) to close...' -Source ${CmdletName}
					If (($PromptToSave) -and ($SessionZero -and (-not $IsProcessUserInteractive))) {
						Write-Log -Message 'Specified [-PromptToSave] option will not be available, because current process is running in session zero and is not interactive.' -Severity 2 -Source ${CmdletName}
					}
					# Update the process list right before closing, in case it changed
					$runningProcesses = Get-RunningProcesses -ProcessObjects $processObjects
					# Close running processes
					ForEach ($runningProcess in $runningProcesses) {
						[PSObject[]]$AllOpenWindowsForRunningProcess = Get-WindowTitle -GetAllWindowTitles -DisableFunctionLogging | Where-Object { $_.ParentProcess -eq $runningProcess.ProcessName }
						#  If the PromptToSave parameter was specified and the process has a window open, then prompt the user to save work if there is work to be saved when closing window
						If (($PromptToSave) -and (-not ($SessionZero -and (-not $IsProcessUserInteractive))) -and ($AllOpenWindowsForRunningProcess) -and ($runningProcess.MainWindowHandle -ne [IntPtr]::Zero)) {
							[Timespan]$PromptToSaveTimeout = New-TimeSpan -Seconds $configInstallationPromptToSave
							[Diagnostics.StopWatch]$PromptToSaveStopWatch = [Diagnostics.StopWatch]::StartNew()
							$PromptToSaveStopWatch.Reset()
							ForEach ($OpenWindow in $AllOpenWindowsForRunningProcess) {
								Try {
									Write-Log -Message "Stopping process [$($runningProcess.ProcessName)] with window title [$($OpenWindow.WindowTitle)] and prompt to save if there is work to be saved (timeout in [$configInstallationPromptToSave] seconds)..." -Source ${CmdletName}
									[Boolean]$IsBringWindowToFrontSuccess = [PSADT.UiAutomation]::BringWindowToFront($OpenWindow.WindowHandle)
									[Boolean]$IsCloseWindowCallSuccess = $runningProcess.CloseMainWindow()
									If (-not $IsCloseWindowCallSuccess) {
										Write-Log -Message "Failed to call the CloseMainWindow() method on process [$($runningProcess.ProcessName)] with window title [$($OpenWindow.WindowTitle)] because the main window may be disabled due to a modal dialog being shown." -Severity 3 -Source ${CmdletName}
									}
									Else {
										$PromptToSaveStopWatch.Start()
										Do {
											[Boolean]$IsWindowOpen = [Boolean](Get-WindowTitle -GetAllWindowTitles -DisableFunctionLogging | Where-Object { $_.WindowHandle -eq $OpenWindow.WindowHandle })
											If (-not $IsWindowOpen) {
												Break
											}
											Start-Sleep -Seconds 3
										} While (($IsWindowOpen) -and ($PromptToSaveStopWatch.Elapsed -lt $PromptToSaveTimeout))
										$PromptToSaveStopWatch.Reset()
										If ($IsWindowOpen) {
											Write-Log -Message "Exceeded the [$configInstallationPromptToSave] seconds timeout value for the user to save work associated with process [$($runningProcess.ProcessName)] with window title [$($OpenWindow.WindowTitle)]." -Severity 2 -Source ${CmdletName}
										}
										Else {
											Write-Log -Message "Window [$($OpenWindow.WindowTitle)] for process [$($runningProcess.ProcessName)] was successfully closed." -Source ${CmdletName}
										}
									}
								}
								Catch {
									Write-Log -Message "Failed to close window [$($OpenWindow.WindowTitle)] for process [$($runningProcess.ProcessName)]. `r`n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
									Continue
								}
								Finally {
									$runningProcess.Refresh()
								}
							}
						}
						Else {
							Write-Log -Message "Stopping process $($runningProcess.ProcessName)..." -Source ${CmdletName}
							Stop-Process -Name $runningProcess.ProcessName -Force -ErrorAction 'SilentlyContinue'
						}
					}

					If ($runningProcesses = Get-RunningProcesses -ProcessObjects $processObjects -DisableLogging) {
						# Apps are still running, give them 2s to close. If they are still running, the Welcome Window will be displayed again
						Write-Log -Message 'Sleeping for 2 seconds because the processes are still not closed...' -Source ${CmdletName}
						Start-Sleep -Seconds 2
					}
				}
				#  Stop the script (if not actioned before the timeout value)
				ElseIf ($promptResult.Contains('Timeout')) {
					Write-Log -Message 'Installation not actioned before the timeout value.' -Source ${CmdletName}
					$BlockExecution = $false

					If (($deferTimes -ge 0) -or ($deferDeadlineUniversal)) {
						Set-DeferHistory -DeferTimesRemaining $DeferTimes -DeferDeadline $deferDeadlineUniversal
					}
					## Dispose the welcome prompt timer here because if we dispose it within the Show-WelcomePrompt function we risk resetting the timer and missing the specified timeout period
					If ($script:welcomeTimer) {
						Try {
							$script:welcomeTimer.Dispose()
							$script:welcomeTimer = $null
						}
						Catch {
						}
					}

					#  Restore minimized windows
					$null = $shellApp.UndoMinimizeAll()

					Write-Output $configInstallationUIExitCode
					return
				}
				#  Stop the script (user chose to defer)
				ElseIf ($promptResult.Contains('Defer')) {
					Write-Log -Message 'Installation deferred by the user.' -Source ${CmdletName}
					$BlockExecution = $false

					Set-DeferHistory -DeferTimesRemaining $DeferTimes -DeferDeadline $deferDeadlineUniversal

					#  Restore minimized windows
					$null = $shellApp.UndoMinimizeAll()

					Write-Output $configInstallationDeferExitCode
					return
				}
			}
		}

		## Force the processes to close silently, without prompting the user
		If (($Silent -or $deployModeSilent) -and $closeApps) {
			[Array]$runningProcesses = $null
			[Array]$runningProcesses = Get-RunningProcesses $processObjects
			If ($runningProcesses) {
				[String]$runningProcessDescriptions = ($runningProcesses | Where-Object { $_.ProcessDescription } | Select-Object -ExpandProperty 'ProcessDescription') -join ','
				Write-Log -Message "Force closing application(s) [$($runningProcessDescriptions)] without prompting user." -Source ${CmdletName}
				$runningProcesses.ProcessName | ForEach-Object -Process { Stop-Process -Name $_ -Force -ErrorAction 'SilentlyContinue' }
				Start-Sleep -Seconds 2
			}
		}

		## Force nsd.exe to stop if Notes is one of the required applications to close
		If (($processObjects | Select-Object -ExpandProperty 'ProcessName') -contains 'notes') {
			## Get the path where Notes is installed
			[String]$notesPath = Get-Item -LiteralPath $regKeyLotusNotes -ErrorAction 'SilentlyContinue' | Get-ItemProperty | Select-Object -ExpandProperty 'Path'

			## Ensure we aren't running as a Local System Account and Notes install directory was found
			If ((-not $IsLocalSystemAccount) -and ($notesPath)) {
				#  Get a list of all the executables in the Notes folder
				[string[]]$notesPathExes = Get-ChildItem -LiteralPath $notesPath -Filter '*.exe' -Recurse | Select-Object -ExpandProperty 'BaseName' | Sort-Object
				## Check for running Notes executables and run NSD if any are found
				$notesPathExes | ForEach-Object {
					If ((Get-Process | Select-Object -ExpandProperty 'Name') -contains $_) {
						[String]$notesNSDExecutable = Join-Path -Path $notesPath -ChildPath 'NSD.exe'
						Try {
							If (Test-Path -LiteralPath $notesNSDExecutable -PathType 'Leaf' -ErrorAction 'Stop') {
								Write-Log -Message "Executing [$notesNSDExecutable] with the -kill argument..." -Source ${CmdletName}
								[Diagnostics.Process]$notesNSDProcess = Start-Process -FilePath $notesNSDExecutable -ArgumentList '-kill' -WindowStyle 'Hidden' -PassThru -ErrorAction 'SilentlyContinue'

								If (-not $notesNSDProcess.WaitForExit(10000)) {
									Write-Log -Message "[$notesNSDExecutable] did not end in a timely manner. Force terminate process." -Source ${CmdletName}
									Stop-Process -Name 'NSD' -Force -ErrorAction 'SilentlyContinue'
								}
							}
						}
						Catch {
							Write-Log -Message "Failed to launch [$notesNSDExecutable]. `r`n$(Resolve-Error)" -Source ${CmdletName}
						}

						Write-Log -Message "[$notesNSDExecutable] returned exit code [$($notesNSDProcess.ExitCode)]." -Source ${CmdletName}

						#  Force NSD process to stop in case the previous command was not successful
						Stop-Process -Name 'NSD' -Force -ErrorAction 'SilentlyContinue'
					}
				}
			}

			#  Strip all Notes processes from the process list except notes.exe, because the other notes processes (e.g. notes2.exe) may be invoked by the Notes installation, so we don't want to block their execution.
			If ($notesPathExes) {
				[Array]$processesIgnoringNotesExceptions = Compare-Object -ReferenceObject ($processObjects | Select-Object -ExpandProperty 'ProcessName' | Sort-Object) -DifferenceObject $notesPathExes -IncludeEqual | Where-Object { ($_.SideIndicator -eq '<=') -or ($_.InputObject -eq 'notes') } | Select-Object -ExpandProperty 'InputObject'
				[Array]$processObjects = $processObjects | Where-Object { $processesIgnoringNotesExceptions -contains $_.ProcessName }
			}
		}

		## If block execution switch is true, call the function to block execution of these processes
		If ($true -eq $BlockExecution) {
			#  Make this variable globally available so we can check whether we need to call Unblock-AppExecution
			Set-Variable -Name 'BlockExecution' -Value $BlockExecution -Scope 'Script'
			Write-Log -Message '[-BlockExecution] parameter specified.' -Source ${CmdletName}
			Block-AppExecution -ProcessName ($processObjects | Select-Object -ExpandProperty 'ProcessName')
			if ($true -eq (Test-Path -Path "$dirAppDeployTemp\BlockExecution\$(Split-Path "$AppDeployConfigFile" -Leaf)")) {
				## in case of showing a message for a blocked application by ADT there has to be a valid application icon in copied temporary ADT framework
				Copy-File -Path "$scriptRoot\$($xmlConfigFile.GetElementsByTagName('BannerIcon_Options').Icon_Filename)" -Destination "$dirAppDeployTemp\BlockExecution\AppDeployToolkitLogo.ico"
				Write-NxtSingleXmlNode -XmlFilePath "$dirAppDeployTemp\BlockExecution\$(Split-Path "$AppDeployConfigFile" -Leaf)" -SingleNodeName "//Icon_Filename" -Value "AppDeployToolkitLogo.ico"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Show-NxtWelcomePrompt
Function Show-NxtWelcomePrompt {
    <#
	.SYNOPSIS
		Called by Show-InstallationWelcome to prompt the user to optionally do the following:
			1) Close the specified running applications.
			2) Provide an option to defer the installation.
			3) Show a countdown before applications are automatically closed.
	.DESCRIPTION
		The user is presented with a Windows Forms dialog box to close the applications themselves and continue or to have the script close the applications for them.
		If the -AllowDefer option is set to true, an optional "Defer" button will be shown to the user. If they select this option, the script will exit and return a 1618 code (SCCM fast retry code).
		The dialog box will timeout after the timeout specified in the XML configuration file (default 1 hour and 55 minutes) to prevent SCCM installations from timing out and returning a failure code to SCCM. When the dialog times out, the script will exit and return a 1618 code (SCCM fast retry code).
	.PARAMETER ProcessDescriptions
		The descriptive names of the applications that are running and need to be closed.
	.PARAMETER CloseAppsCountdown
		Specify the countdown time in seconds before running applications are automatically closed when deferral is not allowed or expired.
	.PARAMETER PersistPrompt
		Specify whether to make the prompt persist in the center of the screen every couple of seconds, specified in the AppDeployToolkitConfig.xml.
	.PARAMETER AllowDefer
		Specify whether to provide an option to defer the installation.
	.PARAMETER DeferTimes
		Specify the number of times the user is allowed to defer.
	.PARAMETER DeferDeadline
		Specify the deadline date before the user is allowed to defer.
	.PARAMETER MinimizeWindows
		Specifies whether to minimize other windows when displaying prompt. Default: $true.
	.PARAMETER TopMost
		Specifies whether the windows is the topmost window. Default: $true.
	.PARAMETER CustomText
		Specify whether to display a custom message specified in the XML file. Custom message must be populated for each language section in the XML.
	.PARAMETER ContinueType
		Specify if the window is automatically closed after the timeout and the further behavior can be influenced with the ContinueType.
	.PARAMETER UserCanCloseAll
		Specifies if the user can close all applications. Default: $false.
	.PARAMETER UserCanAbort
		Specifies if the user can abort the process. Default: $false.
	.INPUTS
		None
		You cannot pipe objects to this function.
	.OUTPUTS
		System.String
		Returns the user's selection.
	.EXAMPLE
		Show-WelcomePrompt -ProcessDescriptions 'Lotus Notes, Microsoft Word' -CloseAppsCountdown 600 -AllowDefer -DeferTimes 10
	.NOTES
		This is an internal script function and should typically not be called directly. It is used by the Show-NxtInstallationWelcome prompt to display a custom prompt.
		The code of this function is mainly adopted from the PSAppDeployToolkit.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false)]
        [String]$ProcessDescriptions,
        [Parameter(Mandatory = $false)]
        [Int32]$CloseAppsCountdown,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [Boolean]$PersistPrompt = $false,
        [Parameter(Mandatory = $false)]
        [Switch]$AllowDefer = $false,
        [Parameter(Mandatory = $false)]
        [String]$DeferTimes,
        [Parameter(Mandatory = $false)]
        [String]$DeferDeadline,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [Boolean]$MinimizeWindows = $true,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [Boolean]$TopMost = $true,
        [Parameter(Mandatory = $false)]
        [Switch]$CustomText = $false,
        [Parameter(Mandatory = $false)]
        [PSADTNXT.ContinueType]$ContinueType = [PSADTNXT.ContinueType]::Abort,
        [Parameter(Mandatory = $false)]
        [Switch]$UserCanCloseAll = $false,
        [Parameter(Mandatory = $false)]
        [Switch]$UserCanAbort = $false
    )

    Begin {
        ## Get the name of this function and write header
        [String]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
    }
    Process {
        ## Reset switches
        [bool]$showCloseApps = $false
        [bool]$showDefer = $false

        ## Check if the countdown was specified
        If ($CloseAppsCountdown -and ($CloseAppsCountdown -gt $configInstallationUITimeout)) {
            Throw 'The close applications countdown time cannot be longer than the timeout specified in the XML configuration for installation UI dialogs to timeout.'
        }

        ## Initial form layout: Close Applications / Allow Deferral
        If ($ProcessDescriptions) {
            Write-Log -Message "Prompting the user to close application(s) [$ProcessDescriptions]..." -Source ${CmdletName}
            $showCloseApps = $true
        }
        If (($AllowDefer) -and (($DeferTimes -ge 0) -or ($DeferDeadline))) {
            Write-Log -Message 'The user has the option to defer.' -Source ${CmdletName}
            $showDefer = $true
            If ($DeferDeadline) {
                #  Remove the Z from universal sortable date time format, otherwise it could be converted to a different time zone
                $DeferDeadline = $DeferDeadline -replace 'Z', ''
                #  Convert the deadline date to a string
                $DeferDeadline = (Get-Date -Date $DeferDeadline).ToString()
            }
        }

        ## If deferral is being shown and 'close apps countdown' or 'persist prompt' was specified, enable those features.
        If (-not $showDefer) {
            If ($CloseAppsCountdown -gt 0) {
                Write-Log -Message "Close applications countdown has [$CloseAppsCountdown] seconds remaining." -Source ${CmdletName}
            }
        }
        if ($CloseAppsCountdown -gt 0)
        {
            [bool]$showCountdown = $true
            Write-Log -Message "Close applications countdown has [$CloseAppsCountdown] seconds remaining." -Source ${CmdletName}
        }

[string]$inputXML = @'
<Window x:Class="InstallationWelcome.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008" Background="Red"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" WindowStartupLocation="CenterScreen"
        xmlns:local="clr-namespace:InstallationWelcome" ResizeMode="NoResize" WindowStyle="None"
        mc:Ignorable="d" SizeToContent="Height" x:Name="InstallationWelcomeMainWindow"
        Width="450">
    <Window.Resources>
        <Color x:Key="ErrorColor" A="255" R="236" G="105" B="53" ></Color>
        <SolidColorBrush x:Key="ErrorColorBrush" Color="{DynamicResource ErrorColor}"></SolidColorBrush>
        <Color x:Key="MainColor" A="255" R="227" G="0" B="15" ></Color>
        <SolidColorBrush x:Key="MainColorBrush" Color="{DynamicResource MainColor}"></SolidColorBrush>
        <Color x:Key="BackColor" A="255" R="40" G="40" B="39"/>
        <SolidColorBrush x:Key="BackColorBrush" Color="{DynamicResource BackColor}"></SolidColorBrush>
        <Color x:Key="BackLightColor" A="255" R="87" G="86" B="86"/>
        <SolidColorBrush x:Key="BackLightColorBrush" Color="{DynamicResource BackLightColor}"></SolidColorBrush>
        <Color x:Key="ForeColor" A="255" R="255" G="255" B="255"/>
        <SolidColorBrush x:Key="ForeColorBrush" Color="{DynamicResource ForeColor}"></SolidColorBrush>
        <Color x:Key="MouseHoverColor" A="255" R="200" G="200" B="200"/>
        <SolidColorBrush x:Key="MouseHoverColorBrush" Color="{DynamicResource MouseHoverColor}"></SolidColorBrush>
        <Color x:Key="PressedColor" A="255" R="87" G="86" B="86"/>
        <SolidColorBrush x:Key="PressedBrush" Color="{DynamicResource PressedColor}"></SolidColorBrush>
        <Style TargetType="TextBlock">
            <Setter Property="FontSize" Value="12"></Setter>
            <Setter Property="Foreground" Value="{DynamicResource ForeColorBrush}"></Setter>
            <Style.Triggers>
                <Trigger Property="Text" Value="">
                    <Setter Property="Visibility" Value="Collapsed" />
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="ToolTip">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ToolTip">
                        <Border Background="{DynamicResource BackLightColorBrush}">
                            <StackPanel>
                                <TextBlock Text="{TemplateBinding Content}" Foreground="{DynamicResource ForeColorBrush}" Padding="5"/>
                            </StackPanel>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="TextBlockListStyle" TargetType="TextBlock">
            <Setter Property="FontSize" Value="12"></Setter>
            <Setter Property="Foreground" Value="{DynamicResource ForeColorBrush}"></Setter>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type Button}">
                        <Border Background="{TemplateBinding Background}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Setter Property="Height" Value="30"/>
            <Setter Property="Width" Value="140"/>
            <Setter Property="Foreground" Value="{DynamicResource ForeColorBrush}"/>
            <Setter Property="Background" Value="{DynamicResource BackLightColorBrush}"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="{DynamicResource MouseHoverColorBrush}"/>
                </Trigger>
                <Trigger Property="IsPressed" Value="True">
                    <Setter Property="Background" Value="{DynamicResource PressedBrush}"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>
    <DockPanel HorizontalAlignment="Stretch"
           VerticalAlignment="Stretch"
           LastChildFill="True">
           <Popup Placement="Center" x:Name="Popup">
           <Border Background="{DynamicResource BackColorBrush}" BorderBrush="{DynamicResource ForeColorBrush}" BorderThickness="1">
               <StackPanel Margin="10">
                   <TextBlock x:Name="PopupCloseWithoutSavingText" Margin="0,0,0,10" Text="[will be replaced later]" VerticalAlignment="Center" TextAlignment="Center" Background="{DynamicResource BackColorBrush}" Foreground="{DynamicResource ForeColorBrush}"></TextBlock>
                   <TextBlock x:Name="PopupListText" Text="[will be replaced later]" Foreground="{DynamicResource ErrorColorBrush}" VerticalAlignment="Center" FontSize="14" TextAlignment="Center" Background="{DynamicResource BackColorBrush}"></TextBlock>
                   <TextBlock x:Name="PopupSureToCloseText" Text="[will be replaced later]" Margin="0,10,0,0" VerticalAlignment="Center" TextAlignment="Center" Background="{DynamicResource BackColorBrush}" Foreground="{DynamicResource ForeColorBrush}"></TextBlock>
                   <DockPanel VerticalAlignment="Bottom"  DockPanel.Dock="Bottom" Margin="0,10,0,0">
                       <Button x:Name="PopupCloseApplication" DockPanel.Dock="Left" Content="Close"></Button>
                       <Button x:Name="PopupCancel" Content="back" HorizontalAlignment="Right" DockPanel.Dock="Right"/>
                   </DockPanel>
               </StackPanel>
           </Border>
       </Popup>
        <DockPanel x:Name="HeaderPanel" HorizontalAlignment="Stretch" Height="30" DockPanel.Dock="Top" Background="{DynamicResource BackColorBrush}">
            <TextBlock DockPanel.Dock="Left" x:Name="TitleText" VerticalAlignment="Center" Text="[will be replaced later]" Margin="5,0,0,0" FontWeight="Bold" FontSize="14" />
            <Button OverridesDefaultStyle="True" BorderThickness="0" DockPanel.Dock="Right" HorizontalContentAlignment="Center" VerticalContentAlignment="Center" HorizontalAlignment="Right" VerticalAlignment="Center" x:Name="WindowCloseButton" Background="Transparent" Content="X" Margin="0,0,0,0" FontWeight="Bold" FontSize="16" Foreground="{DynamicResource ForeColorBrush}" Height="20" Width="20">
                <Button.Style>
                    <Style TargetType="Button">
                        <Setter Property="Template">
                            <Setter.Value>
                                <ControlTemplate TargetType="{x:Type Button}">
                                    <Border x:Name="controlBorder" Margin="0,-5,0,0" Background="{TemplateBinding Background}">
                                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    </Border>
                                    <ControlTemplate.Triggers>
                                        <Trigger  Property="IsMouseOver" Value="true">
                                            <Setter TargetName="controlBorder" Property="Background"  Value="{DynamicResource MainColorBrush}"/>
                                        </Trigger>
                                        <Trigger Property="IsPressed" Value="True">
                                            <Setter TargetName="controlBorder" Property="BorderBrush" Value="{DynamicResource PressedBrush}"/>
                                            <Setter TargetName="controlBorder" Property="BorderThickness" Value="1"/>
                                        </Trigger>
                                    </ControlTemplate.Triggers>
                                </ControlTemplate>
                            </Setter.Value>
                        </Setter>
                    </Style>
                </Button.Style>
            </Button>
        </DockPanel>
        <DockPanel x:Name="MainPanel" Background="{DynamicResource BackColorBrush}">
            <Image x:Name="Banner" DockPanel.Dock="Top" Source="[will be replaced later]" MaxHeight="100"></Image>
            <StackPanel DockPanel.Dock="Top" Margin="0,10,0,0">
                <TextBlock x:Name="FollowApplicationText" TextAlignment="Center" TextWrapping="Wrap" Text="[will be replaced later]" HorizontalAlignment="Center" ></TextBlock>
                <TextBlock x:Name="AppNameText" Foreground="{DynamicResource MainColorBrush}" TextAlignment="Center" Margin="0,10,0,0" TextWrapping="Wrap" Text="[will be replaced later]" HorizontalAlignment="Center" FontWeight="Bold" FontSize="14" ></TextBlock>
                <TextBlock x:Name="CustomTextBlock" TextAlignment="Center" Margin="0,10,0,0" TextWrapping="Wrap" Text="[will be replaced later]" HorizontalAlignment="Center" ></TextBlock>
                <TextBlock x:Name="ApplicationCloseText" TextAlignment="Center" TextWrapping="Wrap" Margin="0,10,0,0" Text="[will be replaced later]" HorizontalAlignment="Center"></TextBlock>
                <TextBlock x:Name="SaveWorkText" TextWrapping="Wrap" Margin="10,10,10,0" Text="[will be replaced later]"  HorizontalAlignment="Center" TextAlignment="Center"></TextBlock>
                <ListView BorderThickness="0" Margin="10" HorizontalAlignment="center" x:Name="CloseApplicationList" Grid.Column="0" Width="Auto" Background="{DynamicResource BackColorBrush}">
                    <ListView.View>
                        <GridView  AllowsColumnReorder="False">
                            <GridView.ColumnHeaderContainerStyle>
                                <Style TargetType="{x:Type GridViewColumnHeader}">
                                    <Setter Property="Template">
                                        <Setter.Value>
                                            <ControlTemplate TargetType="{x:Type GridViewColumnHeader}">
                                                <TextBlock FontWeight="Bold" Foreground="{DynamicResource ErrorColorBrush}" Style="{DynamicResource TextBlockListStyle}" TextAlignment="Left" x:Name="ContentHeader" Text="{TemplateBinding Content}" Padding="5,5,5,0" Width="{TemplateBinding Width}"  />
                                            </ControlTemplate>
                                        </Setter.Value>
                                    </Setter>
                                </Style>
                            </GridView.ColumnHeaderContainerStyle>
                            <GridViewColumn  Header="Name" DisplayMemberBinding="{Binding Name}" />
                            <GridViewColumn  Header="StartedBy" DisplayMemberBinding="{Binding StartedBy}" />
                        </GridView>
                    </ListView.View>
                    <ListView.ItemContainerStyle>
                        <Style TargetType="{x:Type ListViewItem}">
                            <Setter Property="Background" Value="Transparent" />
                            <Setter Property="Template">
                                <Setter.Value>
                                    <ControlTemplate TargetType="{x:Type ListViewItem}">
                                        <Border
                                            BorderBrush="Transparent"
                                            BorderThickness="0"
                                            Background="{TemplateBinding Background}">
                                            <GridViewRowPresenter HorizontalAlignment="Stretch" VerticalAlignment="{TemplateBinding VerticalContentAlignment}" Width="Auto" Margin="0" Content="{TemplateBinding Content}">
                                                <GridViewRowPresenter.Resources>
                                                    <Style TargetType="{x:Type TextBlock}">
                                                        <Setter Property="Foreground" Value="{DynamicResource ErrorColorBrush}"/>
                                                    </Style>
                                                </GridViewRowPresenter.Resources>
                                            </GridViewRowPresenter>
                                        </Border>
                                    </ControlTemplate>
                                </Setter.Value>
                            </Setter>
                        </Style>
                    </ListView.ItemContainerStyle>
                </ListView>

                <TextBlock x:Name="DeferTextOne" TextAlignment="Center"  Margin="0,0,0,10" TextWrapping="Wrap" Text="[will be replaced later]" HorizontalAlignment="Center" ></TextBlock>
                <TextBlock x:Name="DeferTimerText" TextAlignment="Center" TextWrapping="Wrap" Text="" HorizontalAlignment="Center" ></TextBlock>
                <TextBlock x:Name="DeferDeadlineText" TextAlignment="Center" TextWrapping="Wrap" Text="" HorizontalAlignment="Center" ></TextBlock>
                <TextBlock x:Name="DeferTextTwo"  Margin="0,10,0,0" TextAlignment="Center" TextWrapping="Wrap" Text="[will be replaced later]" HorizontalAlignment="Center" ></TextBlock>
                <TextBlock x:Name="TimerText" Margin="20,10,20,0" TextAlignment="Center" TextWrapping="Wrap" Text="[will be replaced later]" HorizontalAlignment="Center" ></TextBlock>
                <Grid x:Name="ProgressGrid"  Margin="0,10,0,5">
                    <ProgressBar x:Name="Progress" Value="5" Minimum="0" Maximum="10" Height="30">
                        <ProgressBar.Template>
                            <ControlTemplate TargetType="ProgressBar">
                                <Grid>
                                    <Border Margin="5,0,5,0" CornerRadius="2">
                                        <Grid>
                                            <Rectangle x:Name="PART_Track"  Fill="{DynamicResource PressedBrush}" RadiusX="2" RadiusY="2"/>
                                            <Rectangle x:Name="PART_Indicator" HorizontalAlignment="Left" Fill="{DynamicResource MainColorBrush}" RadiusX="2" RadiusY="2"/>
                                        </Grid>
                                    </Border>
                                </Grid>
                            </ControlTemplate>
                        </ProgressBar.Template>
                    </ProgressBar>
                    <TextBlock x:Name="TimerBlock" Text="[will be replaced later]"  Background="Transparent" FontWeight="Bold" Style="{DynamicResource TextBlockListStyle}" HorizontalAlignment="Center" TextAlignment="Center" VerticalAlignment="Center"/>
                </Grid>
            </StackPanel>
            <DockPanel DockPanel.Dock="Bottom">
                <Button x:Name="CloseButton" Margin="5,5,0,5" DockPanel.Dock="Left" Width="140" Height="30" Content="Close applications"></Button>
                <Button x:Name="CancelButton" DockPanel.Dock="Right"  Margin="0,5,5,5"  Width="140" Height="30" Content="Cancel"></Button>
                <Button x:Name="DeferButton" Width="140" Margin="0,5,0,5" Height="30" Content="Defer"></Button>
            </DockPanel>
        </DockPanel>
    </DockPanel>
</Window>
'@
        [bool]$IsLightTheme = Test-NxtPersonalizationLightTheme

        [System.Windows.Window]$control = New-NxtWpfControl $inputXML

        [System.Windows.Media.Color]$backColor = $control.Resources['BackColor']
        [System.Windows.Media.Color]$backLightColor = $control.Resources['BackLightColor']
        [System.Windows.Media.Color]$foreColor = $control.Resources['ForeColor']
        [System.Windows.Media.Color]$mouseHoverColor = $control.Resources['MouseHoverColor']
        [System.Windows.Media.Color]$pressedColor = $control.Resources['PressedColor']
        
        [System.Windows.Window]$control_MainWindow = $control.FindName('InstallationWelcomeMainWindow')
        [System.Windows.Controls.TextBlock]$control_FollowApplicationText = $control.FindName('FollowApplicationText')
        [System.Windows.Controls.TextBlock]$control_AppNameText = $control.FindName('AppNameText')
        [System.Windows.Controls.TextBlock]$control_ApplicationCloseText = $control.FindName('ApplicationCloseText')
        [System.Windows.Controls.TextBlock]$control_SaveWorkText = $control.FindName('SaveWorkText')
        [System.Windows.Controls.ListView]$control_CloseApplicationList = $control.FindName('CloseApplicationList')
        [System.Windows.Controls.TextBlock]$control_DeferTextOne = $control.FindName('DeferTextOne')
        [System.Windows.Controls.TextBlock] $control_DeferTimerText = $control.FindName('DeferTimerText')
        [System.Windows.Controls.TextBlock] $control_DeferTextTwo = $control.FindName('DeferTextTwo')
        [System.Windows.Controls.TextBlock]$control_TimerText = $control.FindName('TimerText')
        [System.Windows.Controls.Button]$control_CloseButton = $control.FindName('CloseButton')
        [System.Windows.Controls.Button]$control_CancelButton = $control.FindName('CancelButton')
        [System.Windows.Controls.Button]$control_DeferButton = $control.FindName('DeferButton')
        [System.Windows.Controls.Button]$control_WindowCloseButton = $control.FindName('WindowCloseButton')
        [System.Windows.Controls.ProgressBar]$control_Progress = $control.FindName('Progress')
        [System.Windows.Controls.TextBlock]$control_TimerBlock = $control_Progress.FindName('TimerBlock')
        [System.Windows.Controls.Image]$control_Banner = $control.FindName('Banner')
        [System.Windows.Controls.TextBlock]$control_TitleText = $control.FindName('TitleText')
        [System.Windows.Controls.TextBlock]$control_DeferDeadlineText = $control.FindName('DeferDeadlineText')
        [System.Windows.Controls.TextBlock]$control_CustomText = $control.FindName('CustomTextBlock')
        [System.Windows.Controls.TextBlock]$control_PopupCloseWithoutSavingText = $control.FindName('PopupCloseWithoutSavingText')
        [System.Windows.Controls.TextBlock]$control_PopupListText = $control.FindName('PopupListText')
        [System.Windows.Controls.TextBlock]$control_PopupSureToCloseText = $control.FindName('PopupSureToCloseText')
        [System.Windows.Controls.DockPanel]$control_HeaderPanel = $control.FindName('HeaderPanel')
        [System.Windows.Controls.DockPanel]$control_MainPanel = $control.FindName('MainPanel')
        [System.Windows.Controls.Primitives.Popup]$control_Popup = $control.FindName('Popup')
        [System.Windows.Controls.Button]$control_PopupCloseApplication = $control.FindName('PopupCloseApplication')
        [System.Windows.Controls.Button]$control_PopupCancel = $control.FindName('PopupCancel')

        $control_MainWindow.TopMost = $TopMost

		[ScriptBlock]$windowLeftButtonDownHandler = {
            # Check if the left mouse button is pressed
            if ($_.ChangedButton -eq [System.Windows.Input.MouseButton]::Left) {
                # Call the DragMove method to allow the user to move the window
                $control_MainWindow.DragMove()
            }
        }

        [ScriptBlock]$windowsCloseButtonClickHandler = {
            $control_MainWindow.Tag = "Cancel"
            $control_MainWindow.Close()
        }

        [ScriptBlock]$closeButtonClickHandler = {
            $control_Popup.IsOpen = $true
            $control_HeaderPanel.IsEnabled = $false
            $control_HeaderPanel.Opacity = 0.8
            $control_MainPanel.IsEnabled = $false
            $control_MainPanel.Opacity = 0.8
        }

        [ScriptBlock]$deferbuttonClickHandler = {
            $control_MainWindow.Tag = "Defer"
            $control_MainWindow.Close()
        }

        [ScriptBlock]$cancelButtonClickHandler = {
            $control_MainWindow.Tag = "Cancel"
            $control_MainWindow.Close()
        }

        [ScriptBlock]$popupCloseApplicationClickHandler = {
            $control_Popup.IsOpen = $false
            $control_HeaderPanel.IsEnabled = $true
            $control_HeaderPanel.Opacity = 1
            $control_MainPanel.IsEnabled = $true
            $control_MainPanel.Opacity = 1
            $control_MainWindow.Tag = "Close"
            $control_MainWindow.Close()
        }

        [ScriptBlock]$popupCancelClickHandler = {
            $control_Popup.IsOpen = $false
            $control_HeaderPanel.IsEnabled = $true
            $control_HeaderPanel.Opacity = 1
            $control_MainPanel.IsEnabled = $true
            $control_MainPanel.Opacity = 1
        }


		$control_HeaderPanel.add_MouseLeftButtonDown($windowLeftButtonDownHandler)
        $control_WindowCloseButton.add_Click($windowsCloseButtonClickHandler)
        $control_CloseButton.add_Click($closeButtonClickHandler)
        $control_DeferButton.add_Click($deferbuttonClickHandler)
        $control_CancelButton.add_Click($cancelButtonClickHandler)
        $control_PopupCloseApplication.add_Click($popupCloseApplicationClickHandler)
        $control_PopupCancel.add_Click($popupCancelClickHandler)
            
        if ($IsLightTheme)
        {
            $backColor.r = 246
            $backColor.g = 246
            $backColor.b = 246
            $backLightColor.r = 218
            $backLightColor.g = 218
            $backLightColor.b = 218
            $foreColor.r = 0
            $foreColor.g = 0
            $foreColor.b = 0
            $mouseHoverColor.r = 255
            $mouseHoverColor.g = 255
            $mouseHoverColor.b = 255
            $pressedColor.r = 218
            $pressedColor.g = 218
            $pressedColor.b = 218
            $control.Resources['BackColor'] = $backColor
            $control.Resources['BackLightColor'] = $backLightColor
            $control.Resources['ForeColor'] = $foreColor
            $control.Resources['MouseHoverColor'] = $mouseHoverColor
            $control.Resources['PressedColor'] = $pressedColor  

            $control_Banner.Source =  $appDeployLogoBanner
        }
        else
        {
            $control_Banner.Source =  $appDeployLogoBannerDark
        }

		if ($xmlUIMessageLanguage -ne "UI_Messages_EN" -and $xmlUIMessageLanguage -ne "UI_Messages_DE") {
			## until we not support same languages in dialogues like ADT, we switch to english as default
			[Xml.XmlElement]$xmlUIMessages = $xmlConfig."UI_Messages_EN"
		}
		else {
			[Xml.XmlElement]$xmlUIMessages = $xmlConfig.$xmlUIMessageLanguage
		}
		if ($true -eq $UserCanCloseAll) {
			$control_SaveWorkText.Text = $xmlUIMessages.NxtWelcomePrompt_SaveWork
		}
		else {
			$control_SaveWorkText.Text = $xmlUIMessages.NxtWelcomePrompt_SaveWorkWithoutCloseButton
		}
        $control_DeferTextTwo.Text = $xmlUIMessages.NxtWelcomePrompt_DeferalExpired
        $control_CloseButton.Content = $xmlUIMessages.NxtWelcomePrompt_CloseApplications
        $control_CancelButton.Content = $xmlUIMessages.NxtWelcomePrompt_Close
        $control_DeferButton.Content = $xmlUIMessages.NxtWelcomePrompt_Defer
        $control_CloseApplicationList.View.Columns[0].Header = $xmlUIMessages.NxtWelcomePrompt_ApplicationName
        $control_CloseApplicationList.View.Columns[1].Header = $xmlUIMessages.NxtWelcomePrompt_StartedBy
        $control_PopupCloseWithoutSavingText.Text = $xmlUIMessages.NxtWelcomePrompt_PopUpCloseApplicationText
        $control_PopupSureToCloseText.Text = $xmlUIMessages.NxtWelcomePrompt_PopUpSureToCloseText
        $control_PopupCloseApplication.Content = $xmlUIMessages.NxtWelcomePrompt_CloseApplications
        $control_PopupCancel.Content = $xmlUIMessages.NxtWelcomePrompt_Close
        Switch ($deploymentType) {
            'Uninstall' {
				if ($ContinueType -eq [PSADTNXT.ContinueType]::Abort) {
					$control_TimerText.Text = ($xmlUIMessages.NxtWelcomePrompt_CloseWithoutSaving_Abort -f $xmlUIMessages.DeploymentType_Uninstall)
				}
				else {
					$control_TimerText.Text = ($xmlUIMessages.NxtWelcomePrompt_CloseWithoutSaving_Continue -f $xmlUIMessages.DeploymentType_Uninstall)
				};
                $control_FollowApplicationText.Text = ($xmlUIMessages.NxtWelcomePrompt_FollowApplication -f $xmlUIMessages.DeploymentType_UninstallVerb);
                $control_ApplicationCloseText.Text = ($xmlUIMessages.NxtWelcomePrompt_ApplicationClose -f $xmlUIMessages.DeploymentType_Uninstall);
                $control_DeferTextOne.Text = ($xmlUIMessages.NxtWelcomePrompt_ChooseDefer -f $xmlUIMessages.DeploymentType_Uninstall);
                Break
            }
            'Repair' {
				if ($ContinueType -eq [PSADTNXT.ContinueType]::Abort) {
					$control_TimerText.Text = ($xmlUIMessages.NxtWelcomePrompt_CloseWithoutSaving_Abort -f $xmlUIMessages.DeploymentType_Repair)
				}
				else {
					$control_TimerText.Text = ($xmlUIMessages.NxtWelcomePrompt_CloseWithoutSaving_Continue -f $xmlUIMessages.DeploymentType_Repair)
				};
                $control_FollowApplicationText.Text = ($xmlUIMessages.NxtWelcomePrompt_FollowApplication -f $xmlUIMessages.DeploymentType_RepairVerb);
                $control_ApplicationCloseText.Text = ($xmlUIMessages.NxtWelcomePrompt_ApplicationClose -f $xmlUIMessages.DeploymentType_Repair);
                $control_DeferTextOne.Text = ($xmlUIMessages.NxtWelcomePrompt_ChooseDefer -f $xmlUIMessages.DeploymentType_Repair);
                Break
            }
            Default {
				if ($ContinueType -eq [PSADTNXT.ContinueType]::Abort) {
					$control_TimerText.Text = ($xmlUIMessages.NxtWelcomePrompt_CloseWithoutSaving_Abort -f $xmlUIMessages.DeploymentType_Install)
				}
				else {
					$control_TimerText.Text = ($xmlUIMessages.NxtWelcomePrompt_CloseWithoutSaving_Continue -f $xmlUIMessages.DeploymentType_Install)
				};
                $control_FollowApplicationText.Text = ($xmlUIMessages.NxtWelcomePrompt_FollowApplication -f $xmlUIMessages.DeploymentType_InstallVerb);
                $control_ApplicationCloseText.Text = ($xmlUIMessages.NxtWelcomePrompt_ApplicationClose -f $xmlUIMessages.DeploymentType_Install);
                $control_DeferTextOne.Text = ($xmlUIMessages.NxtWelcomePrompt_ChooseDefer -f $xmlUIMessages.DeploymentType_Install);
                Break
            }
        }
        If ($CustomText -and $configWelcomePromptCustomMessage) {
            $control_CustomText.Text = $configWelcomePromptCustomMessage
            $control_CustomText.Visibility = "Visible"
        }
        else {
            $control_CustomText.Visibility = "Collapsed"
        }

        $control_AppNameText.Text = $installTitle
        $control_TitleText.Text = $installTitle
                
        [PSObject[]]$runningProcesses = foreach ($processObject in $processObjects){
			Get-RunningProcesses -ProcessObjects $processObject | Where-Object {$false -eq [string]::IsNullOrEmpty($_.id)}
		}
		[ScriptBlock]$FillCloseApplicationList = {
            param($runningProcessesParam)
            ForEach ($runningProcessItem in $runningProcessesParam) {
                [PSObject[]]$AllOpenWindowsForRunningProcess = Get-WindowTitle -GetAllWindowTitles -DisableFunctionLogging | Where-Object { $_.ParentProcessID -eq $runningProcessItem.Id }
				## actually don't add processes without a viewable window to the list yet
				if ($AllOpenWindowsForRunningProcess.count -gt 0) {		
					foreach ($WindowForRunningProcess in $AllOpenWindowsForRunningProcess){
						Get-WmiObject -Class Win32_Process -Filter "ProcessID = '$($WindowForRunningProcess.ParentProcessId)'" | ForEach-Object {
							$item = New-Object PSObject -Property @{
								Name = $runningProcessItem.ProcessDescription
								StartedBy = $_.GetOwner().Domain + "\" + $_.GetOwner().User
							}
							$control_CloseApplicationList.Items.Add($item)
						}
					}
                }
				else {
					$runningProcessesParam = $runningProcessesParam | Where-Object { $_ -ne $runningProcessItem }
					Write-Log -Message "The Process $($runningProcessItem.ProcessName) with id $($runningProcessItem.Id) has no Window and will not be shown in the ui." -Severity 2 -Source ${cmdletName}
				}
            }
        }
		& $FillCloseApplicationList $runningProcesses

        [string]$names = $runningProcesses | Select-Object -ExpandProperty Name
        $control_PopupListText.Text = $names.Trim()
        
        [Int32]$OutNumber = $null

        If ([Int32]::TryParse($DeferTimes,[ref]$OutNumber) -and $DeferTimes -ge 0) {
            $control_DeferTimerText.Text =  $xmlUIMessages.NxtWelcomePrompt_RemainingDefferals -f $([Int32]$DeferTimes + 1)
        }
        If ($DeferDeadline) {
            $control_DeferDeadlineText.Text = $xmlUIMessages.DeferPrompt_Deadline + " " + $DeferDeadline
        }

        if ($true -eq [string]::IsNullOrEmpty($control_DeferTimerText.Text))
        {
           $control_DeferTextOne.Visibility = "Collapsed"
           $control_DeferTextTwo.Visibility = "Collapsed"
           $control_DeferButton.Visibility = "Collapsed"
           $control_DeferDeadlineText.Visibility = "Collapsed"         
        }
        else
        {  
          $control_DeferTextOne.Visibility = "Visible"
          $control_DeferTextTwo.Visibility = "Visible"
          $control_DeferButton.Visibility = "Visible"
            If ($DeferDeadline)
            {
                $control_DeferDeadlineText.Visibility = "Visible"
            }
            else
            {
                $control_DeferDeadlineText.Visibility = "Collapsed"
            }
        }

        if (-not $UserCanCloseAll)
        {
            $control_CloseButton.Visibility = "Collapsed"
        }

        if (-not $UserCanAbort)
        {
            $control_CancelButton.Visibility = "Collapsed"
            $control_WindowCloseButton.Visibility = "Collapsed"
        }

        If ($showCloseApps) {
            $control_CloseButton.ToolTip = $xmlUIMessages.ClosePrompt_ButtonContinueTooltip
        }
      
        ## Add the timer if it doesn't already exist - this avoids the timer being reset if the continue button is clicked
        If (-not $script:welcomeTimer) {
            [System.Windows.Threading.DispatcherTimer]$script:welcomeTimer = New-Object System.Windows.Threading.DispatcherTimer
        }

        [ScriptBlock]$mainWindowLoaded = {
            If ($showCountdown)
            {
                $control_Progress.Maximum = $CloseAppsCountdown
                $control_Progress.Value = $CloseAppsCountdown
                [Timespan]$tmpTime = [timespan]::fromseconds($CloseAppsCountdown)
            }
            else {
                $control_Progress.Maximum = $configInstallationUITimeout
                $control_Progress.Value = $configInstallationUITimeout
                [Timespan]$tmpTime = [timespan]::fromseconds($configInstallationUITimeout)
                Set-Variable -Name 'closeAppsCountdownGlobal' -Value $configInstallationUITimeout -Scope 'Script'
            }
            $control_TimerBlock.Text = [String]::Format('{0}:{1:d2}:{2:d2}', $tmpTime.Days * 24 + $tmpTime.Hours, $tmpTime.Minutes, $tmpTime.Seconds)
            $script:welcomeTimer.Start()
        }

        [ScriptBlock]$mainWindowClosed = {
            Try {
                $control_WindowCloseButton.remove_Click($windowsCloseButtonClickHandler)
                $control_CloseButton.remove_Click($closeButtonClickHandler)
                $control_DeferButton.remove_Click($deferbuttonClickHandler)
                $control_CancelButton.remove_Click($cancelButtonClickHandler)
                $control_PopupCloseApplication.remove_Click($popupCloseApplicationClickHandler)
                $control_PopupCancel.remove_Click($popupCancelClickHandler)
				$control_HeaderPanel.remove_MouseLeftButtonDown($windowLeftButtonDownHandler)
				if ($null -ne $welcomeTimerPersist.IsEnabled -eq $true) {
                    $welcomeTimerPersist.remove_Tick($welcomeTimerPersist_Tick)
                }
                if ($null -ne $timerRunningProcesses.IsEnabled -eq $true) {
                    $timerRunningProcesses.remove_Tick($timerRunningProcesses_Tick)
                }
                if ($script:welcomeTimer.IsEnabled -eq $true) {
                    $script:welcomeTimer.remove_Tick($welcomeTimer_Tick)
                }
                $control_MainWindow.remove_Loaded($mainWindowLoaded)
                $control_MainWindow.remove_Closed($mainWindowClosed)
            }
            Catch {
            }
        }

        $control_MainWindow.Add_Loaded($mainWindowLoaded)

        $control_MainWindow.Add_Closed($mainWindowClosed)
     
        $script:welcomeTimer.Interval = [timespan]::fromseconds(1)
        [ScriptBlock]$welcomeTimer_Tick = {
        # Your code to be executed every second goes here
        Try {
                [Int32]$progressValue = $closeAppsCountdownGlobal - 1
                Set-Variable -Name 'closeAppsCountdownGlobal' -Value $progressValue -Scope 'Script'
                ## If the countdown is complete, close the application(s) or continue
                If ($progressValue -lt 0) {
                    if ($showCountdown)
                    {
                        if ($ContinueType -eq [PSADTNXT.ContinueType]::Abort) {
                            $control_MainWindow.Tag = "Cancel"
                        }
                        else {
                            $control_MainWindow.Tag = "Close"
                        }
                    }   
                    else {
                        $control_MainWindow.Tag = "Timeout"
                    }
                    $control_MainWindow.Close()
                }
                Else {
                    $control_Progress.Value = $progressValue
                    [timespan]$progressTime = [timespan]::fromseconds($progressValue)
                    $control_TimerBlock.Text = [String]::Format('{0}:{1:d2}:{2:d2}', $progressTime.Days * 24 + $progressTime.Hours, $progressTime.Minutes, $progressTime.Seconds)
            
                }
            }
            Catch {
            }
        }
        
        $script:welcomeTimer.add_Tick($welcomeTimer_Tick)

        ## Persistence Timer
        If ($PersistPrompt) {
            [System.Windows.Threading.DispatcherTimer]$welcomeTimerPersist = New-Object System.Windows.Threading.DispatcherTimer
            $welcomeTimerPersist.Interval = [timespan]::fromseconds($configInstallationPersistInterval)
            [ScriptBlock]$welcomeTimerPersist_Tick = {
                $control_MainWindow.Topmost = $true;  
                $control_MainWindow.Topmost = $TopMost;
            }
            $welcomeTimerPersist.add_Tick($welcomeTimerPersist_Tick)
            $welcomeTimerPersist.Start()
        }
        ## Process Re-Enumeration Timer
        If ($configInstallationWelcomePromptDynamicRunningProcessEvaluation) {
            [System.Windows.Threading.DispatcherTimer]$timerRunningProcesses = New-Object System.Windows.Threading.DispatcherTimer
            $timerRunningProcesses.Interval = [timespan]::fromseconds($configInstallationWelcomePromptDynamicRunningProcessEvaluationInterval)
            [ScriptBlock]$timerRunningProcesses_Tick = {
                Try {
                    [PSObject[]]$dynamicRunningProcesses = $null
                    $dynamicRunningProcesses = Get-RunningProcesses -ProcessObjects $processObjects -DisableLogging
                    [String]$dynamicRunningProcessDescriptions = ($dynamicRunningProcesses | Where-Object { $_.ProcessDescription } | Select-Object -ExpandProperty 'ProcessDescription') -join ','
                    If ($dynamicRunningProcessDescriptions -ne $script:runningProcessDescriptions) {
                        # Update the runningProcessDescriptions variable for the next time this function runs
                        Set-Variable -Name 'runningProcessDescriptions' -Value $dynamicRunningProcessDescriptions -Force -Scope 'Script'
                        If ($dynamicRunningProcesses) {
                            Write-Log -Message "The running processes have changed. Updating the apps to close: [$script:runningProcessDescriptions]..." -Source ${CmdletName}
                        }
                        # Update the list box with the processes to close
                        $control_CloseApplicationList.Items.Clear()
                        & $FillCloseApplicationList $dynamicRunningProcesses
                    }
                    # If CloseApps processes were running when the prompt was shown, and they are subsequently detected to be closed while the form is showing, then close the form. The deferral and CloseApps conditions will be re-evaluated.
                    If ($ProcessDescriptions) {
                        If (-not $dynamicRunningProcesses) {
                            Write-Log -Message 'Previously detected running processes are no longer running.' -Source ${CmdletName}
                            $control_MainWindow.Close()
                        }
                    }
                    # If CloseApps processes were not running when the prompt was shown, and they are subsequently detected to be running while the form is showing, then close the form for relaunch. The deferral and CloseApps conditions will be re-evaluated.
                    Else {
                        If ($dynamicRunningProcesses) {
                            Write-Log -Message 'New running processes detected. Updating the form to prompt to close the running applications.' -Source ${CmdletName}
                            $control_MainWindow.Close()
                        }
                    }
                }
                Catch {
                }
            }
            $timerRunningProcesses.add_Tick($timerRunningProcesses_Tick)
            $timerRunningProcesses.Start()
        }

        If ($MinimizeWindows) {
            $shellApp.MinimizeAll()
        }

        # Open dialog and Wait
        $control_MainWindow.ShowDialog() | Out-Null
              
        If ($configInstallationWelcomePromptDynamicRunningProcessEvaluation) {
            $timerRunningProcesses.Stop()
        }

        Write-Output -InputObject ($control_MainWindow.Tag)
    }
    End {
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
    }
}
#endregion
#region Function Stop-NxtProcess
function Stop-NxtProcess {
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
		none.
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
	}
	Process {
		Write-Log -Message "Stopping process with name '$Name'..." -Source ${cmdletName}
		try {
			if (Get-Process -Name $Name -ErrorAction SilentlyContinue) {
				Stop-Process -Name $Name -Force
				Start-Sleep 1
				if (Get-Process -Name $Name -ErrorAction SilentlyContinue) {
					Write-Log -Message "Failed to stop process. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
				}
				else {
					Write-Log -Message "The process was successfully stopped." -Source ${cmdletName}
				}
			}
			else {
				Write-Log -Message "The process does not exist. Skipped stopping the process." -Source ${cmdletName}
			}
		}
		catch {
			Write-Log -Message "Failed to stop process. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Switch-NxtMSIReinstallMode
function Switch-NxtMSIReinstallMode {
	<#
	.SYNOPSIS
		Switches the ReinstallMode for a msi setup depending on comparison of exact DisplayVersion if the target application is installed.
	.DESCRIPTION
		Changes the ReinstallMode for the package depending on comparison of exact DisplayVersion if the application is present.
		Only applies to MSI Installer.
	.PARAMETER UninstallKey
		Name of the uninstall registry key of the application (e.g. "This Application_is1" or "{XXXXXXXX-XXXX-XXXXXXXX-XXXXXXXXXXXX}").
		Can be found under "HKLM:\Software\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\".
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyIsDisplayName
		Determines if the value given as UninstallKey should be interpreted as a displayname.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyContainsWildCards
		Determines if the value given as UninstallKey contains WildCards.
		If set to $true, "*" are interpreted as WildCards.
		If set to $false, "*" are interpreted as part of the actual string.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER DisplayNamesToExclude
		DisplayName(s) to exclude from the search result.
		Use commas to separate more than one value.
		"*" inside this parameter will not be interpreted as WildCards. (This has no effect on the use of WildCards in other parameters!)
		We reccommend always adding "$global:PackageConfig.UninstallDisplayName" if used inside a package to exclude the current package itself, especially if combined with the "UninstallKeyContainsWildCards" parameter.
		Defaults to the "DisplayNamesToExcludeFromAppSearches" value from the PackageConfig object.
	.PARAMETER DisplayVersion
		Expected version of installed application from a msi setup.
		Defaults to the corresponding value 'DisplayVersion' from the PackageConfig object.
	.PARAMETER InstallMethod
		Defines the type of the installer used in this package for installation.
		Only applies to MSI Installer and is necessary when MSI product code is not independent (i.e. ProductCode depends on OS language).
		Defaults to the corresponding value for installation case and uninstallation case from the PackageConfig object ('InstallMethod' includes repair mode or 'UninstallMethod').
	.PARAMETER ReinstallMode
		Defines how a reinstallation should be performed. By default read from global parameter (especially for msi setups this maybe switched after display version check inside of this function!).
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER MSIInplaceUpgradeable
		Defines the behavior of msi setup process in case of an upgrade.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER MSIDowngradeable
		Defines the behavior of msi setup process in case of a downgrade.
		Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Switch-NxtMSIReinstallMode
	.EXAMPLE
		Switch-NxtMSIReinstallMode -ReinstallMode "MSIRepair"
	.OUTPUTS
		System.String.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[String]
		$UninstallKey = $global:PackageConfig.UninstallKey,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyIsDisplayName = $global:PackageConfig.UninstallKeyIsDisplayName,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyContainsWildCards = $global:PackageConfig.UninstallKeyContainsWildCards,
		[Parameter(Mandatory = $false)]
		[array]
		$DisplayNamesToExclude = $global:PackageConfig.DisplayNamesToExcludeFromAppSearches,
		[Parameter(Mandatory = $false)]
		[string]
		$DisplayVersion = $global:PackageConfig.DisplayVersion,
		[Parameter(Mandatory = $false)]
		[string]
		$InstallMethod = $global:PackageConfig.InstallMethod,
		[Parameter(Mandatory = $false)]
		[string]
		$ReinstallMode = $global:PackageConfig.ReinstallMode,
		[Parameter(Mandatory = $false)]
		[bool]
		$MSIInplaceUpgradeable = $global:PackageConfig.MSIInplaceUpgradeable,
		[Parameter(Mandatory = $false)]
		[bool]
		$MSIDowngradeable = $global:PackageConfig.MSIDowngradeable
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ("MSI" -eq $InstallMethod) {
			if ([string]::IsNullOrEmpty($DisplayVersion)) {
				Write-Log -Message "No 'DisplayVersion' provided. Processing msi setup without double check ReinstallMode for an expected msi display version!. Returning [$ReinstallMode]." -Severity 2 -Source ${cmdletName}
			}
			else {
				[PSADTNXT.NxtDisplayVersionResult]$displayVersionResult = Get-NxtCurrentDisplayVersion
				If ($false -eq $displayVersionResult.UninstallKeyExists) {
					Write-Log -Message "No installed application was found and no 'DisplayVersion' was detectable!" -Source ${CmdletName}
					throw "No repair function executable under current conditions!"
				}
				elseif ($true -eq [string]::IsNullOrEmpty($displayVersionResult.DisplayVersion)) {
					### Note: By default an empty value 'DisplayVersion' for an installed msi setup may not be possible unless it was manipulated manually.
					Write-Log -Message "Detected 'DisplayVersion' is empty. Wrong installation results may be possible." -Severity 2 -Source ${cmdletName}
					Write-Log -Message "Exact check for an installed msi application not possible! But found application matching UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Returning [$ReinstallMode]." -Source ${CmdletName}
				}
				else {
					Write-Log -Message "Processing msi setup: double check ReinstallMode for expected msi display version [$DisplayVersion]." -Source ${cmdletName}
					switch ($(Compare-NxtVersion -DetectedVersion ($displayVersionResult.DisplayVersion) -TargetVersion $DisplayVersion)) {
						"Equal" { 
							Write-Log -Message "Found the expected display version." -Source ${cmdletName}
						}
						"Update" {
							[string]$infoMessage = "Found a lower target display version than expected."
							## check just for sure
							if ($DeploymentType -eq "Install") {
								# in this case the defined reinstall mode set by PackageConfig.json has to change
								If ($true -eq $MSIInplaceUpgradeable) {
									[string]$infoMessage += " Doing an msi inplace upgrade ..."
									[string]$ReinstallMode = "Install"
								} else {
									[string]$ReinstallMode = "Reinstall"
								}
							}
							Write-Log -Message "$infoMessage Returning [$ReinstallMode]." -Severity 2 -Source ${cmdletName}
						}
						"Downgrade" {
							[string]$infoMessage = "Found a higher target display version than expected."
							## check just for sure
							if ($DeploymentType -eq "Install") {
								## in this case the defined reinstall mode set by PackageConfig.json has to change
								If ($true -eq $MSIDowngradeable) {
									[string]$infoMessage += " Doing a msi downgrade ..."
									[string]$ReinstallMode = "Install"
								} else {
									[string]$ReinstallMode = "Reinstall"
								}
							}
							Write-Log -Message "$infoMessage Returning [$ReinstallMode]." -Severity 2 -Source ${cmdletName}
						}
						default {
							Write-Log -Message "Unsupported compare result at this point: '$_'" -Severity 3 -Source ${cmdletName}
							throw "Unsupported compare result at this point: '$_'"
						}
					}
				}
			}
		} 
		Write-Output $ReinstallMode			
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Test-NxtAppIsInstalled
function Test-NxtAppIsInstalled {
	<#
	.SYNOPSIS
		Detects if the target application is installed.
	.DESCRIPTION
		Uses the registry Uninstall Key to detect if the application is present.
	.PARAMETER UninstallKey
		Name of the uninstall registry key of the application (e.g. "This Application_is1" or "{XXXXXXXX-XXXX-XXXXXXXX-XXXXXXXXXXXX}").
		Can be found under "HKLM:\Software\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\".
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyIsDisplayName
		Determines if the value given as UninstallKey should be interpreted as a displayname.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyContainsWildCards
		Determines if the value given as UninstallKey contains WildCards.
		If set to $true, "*" are interpreted as WildCards.
		If set to $false, "*" are interpreted as part of the actual string.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER DisplayNamesToExclude
		DisplayName(s) to exclude from the search result.
		Use commas to separate more than one value.
		"*" inside this parameter will not be interpreted as WildCards. (This has no effect on the use of WildCards in other parameters!)
		We reccommend always adding "$global:PackageConfig.UninstallDisplayName" if used inside a package to exclude the current package itself, especially if combined with the "UninstallKeyContainsWildCards" parameter.
		Defaults to the "DisplayNamesToExcludeFromAppSearches" value from the PackageConfig object.
	.PARAMETER DeploymentMethod
		Defines the type of the installer used in this package.
		Only applies to MSI Installer and is necessary when MSI product code is not independent (i.e. ProductCode depends on OS language).
		Defaults to the corresponding value for installation case and uninstallation case from the PackageConfig object ('InstallMethod' includes repair mode or 'UninstallMethod').
	.EXAMPLE
		Test-NxtAppIsInstalled
	.EXAMPLE
		Test-NxtAppIsInstalled -UninstallKey "This Application_is1"
	.EXAMPLE
		Test-NxtAppIsInstalled -UninstallKey "This Application" -UninstallKeyIsDisplayName $true
	.EXAMPLE
		Test-NxtAppIsInstalled -UninstallKey "SomeApp - Version *" -UninstallKeyIsDisplayName $true -UninstallKeyContainsWildCards $true -DisplayNamesToExclude "SomeApp - Version 1.0","SomeApp - Version 1.1",$global:PackageConfig.UninstallDisplayName
	.EXAMPLE
		Test-NxtAppIsInstalled -UninstallKey "***MySuperSparklingApp***" -UninstallKeyIsDisplayName $true -UninstallKeyContainsWildCards $false
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[String]
		$UninstallKey = $global:PackageConfig.UninstallKey,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyIsDisplayName = $global:PackageConfig.UninstallKeyIsDisplayName,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyContainsWildCards = $global:PackageConfig.UninstallKeyContainsWildCards,
		[Parameter(Mandatory = $false)]
		[array]
		$DisplayNamesToExclude = $global:PackageConfig.DisplayNamesToExcludeFromAppSearches,
		[Parameter(Mandatory = $false)]
		[string]
		$DeploymentMethod
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		Write-Log -Message "Checking if application is installed..." -Source ${CmdletName}
		[array]$installedAppResults = Get-NxtInstalledApplication -UninstallKey $UninstallKey -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude
		if ($installedAppResults.Count -eq 0) {
			[bool]$approvedResult = $false
			Write-Log -Message "Found no application matching UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Returning [$approvedResult]." -Source ${CmdletName}
		}
		elseif ($installedAppResults.Count -gt 1) {
			if ("MSI" -eq $DeploymentMethod) {
				## This case maybe resolved with a foreach-loop in future.
				[bool]$approvedResult = $false
				Write-Log -Message "Found more than one application matching UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Returning [$approvedResult]." -Severity 3 -Source ${CmdletName}
				throw "Processing multiple found msi installations is not supported yet! Abort."
			} else {
				[bool]$approvedResult = $true
				Write-Log -Message "Found more than one application matching UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Returning [$approvedResult]." -Severity 2 -Source ${CmdletName}
			}
		}
		else {
			## for all types of installer (just 1 search result)
			[bool]$approvedResult = $true
			Write-Log -Message "Found one application matching UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Returning [$approvedResult]." -Source ${CmdletName}
		}
		Write-Output $approvedResult
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Test-NxtLocalGroupExists
function Test-NxtLocalGroupExists {
	<#
	.DESCRIPTION
		Checks if a local group exists by name.
	.PARAMETER GroupName
		Name of the group.
	.PARAMETER Computername
		Name of the Computer,
		Defaults to $env:COMPUTERNAME.
	.EXAMPLE
		Test-NxtLocalGroupExists -GroupName "Administrators"
	.OUTPUTS
		System.Boolean.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$GroupName,
		[Parameter(Mandatory = $false)]
		[string]
		$COMPUTERNAME = $env:COMPUTERNAME
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[bool]$groupExists = ([ADSI]::Exists("WinNT://$COMPUTERNAME/$GroupName,group"))
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
#region Function Test-NxtLocalUserExists
function Test-NxtLocalUserExists {
	<#
	.DESCRIPTION
		Checks if a local user exists by name.
	.PARAMETER UserName
		Name of the user.
	.PARAMETER ComputerName
		Name of the Computer,
		Defaults to $env:COMPUTERNAME.
	.EXAMPLE
		Test-NxtLocalUserExists -UserName "Administrator".
	.OUTPUTS
		System.Boolean.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$UserName,
		[Parameter(Mandatory = $false)]
		[string]
		$ComputerName = $env:COMPUTERNAME
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[bool]$userExists = ([ADSI]::Exists("WinNT://$ComputerName/$UserName,user"))
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
#region Function Test-NxtObjectValidation
function Test-NxtObjectValidation {
	<#
	.SYNOPSIS
		Validates the package configuration object.
	.DESCRIPTION
		Validates the package configuration object against the validation rules.
	.PARAMETER ValidationRule
		Validation rule object.
	.PARAMETER ObjectToValidate
		Object to validate.
	.PARAMETER ContainsDirectValues
		Indicates if the object contains direct values.
	.PARAMETER ParentObjectName
		Name of the parent object.
	.PARAMETER ContinueOnError
		Indicates if the validation should continue on error.
	.EXAMPLE
		Test-NxtObjectValidation -ValidationRule $ValidationRule -ObjectToValidate $ObjectToValidate
	.OUTPUTS
		none.
	.LINK
		private
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[psobject]
		$ValidationRule,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[psobject]
		$ObjectToValidate,
		[Parameter(Mandatory=$false)]
		[switch]
		$ContainsDirectValues = $false,
		[Parameter(Mandatory=$false)]
		[string]
		$ParentObjectName,
		[Parameter(Mandatory=$false)]
		[bool]
		$ContinueOnError
		)
		Begin {

		}
		Process{
			## ckeck for missing mandatory parameters
			foreach ($validationRuleKey in ($ValidationRule | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty name)){
				if ($ValidationRule.$validationRuleKey.Mandatory -eq $true){
					if ($false -eq ([bool]($ObjectToValidate.psobject.Properties.Name -contains $validationRuleKey))){
						Write-Log -Message "The mandatory variable '$ParentObjectName $validationRuleKey' is missing." -severity 3
					}
					else{
						Write-Verbose "[${cmdletName}] The variable '$ParentObjectName $validationRuleKey' is present."
					}
				}
				## check for allowed object types and trigger the validation function for sub objects
				switch ($ValidationRule.$validationRuleKey.Type) {
					"System.Array" {
						if ($true -eq ([bool]($ValidationRule.$validationRuleKey.Type -match [Regex]::Escape($ObjectToValidate.$validationRuleKey.GetType().BaseType.FullName)))){
							Write-Verbose "[${cmdletName}] The variable '$ParentObjectName $validationRuleKey' is of the allowed type $($ObjectToValidate.$validationRuleKey.GetType().BaseType.FullName)"
						}
						else{
							Write-Log -Message "The variable '$ParentObjectName $validationRuleKey' is not of the allowed type $($ValidationRule.$validationRuleKey.Type) in the package configuration object."-severity 3
							if ($false -eq $ContinueOnError){
								throw "The variable '$ParentObjectName $validationRuleKey' is not of the allowed type $($ValidationRule.$validationRuleKey.Type) in the package configuration object. $($ValidationRule.$validationRuleKey.HelpText)"
							}
						}
						## check for sub objects
						foreach ($arrayItem in $ObjectToValidate.$validationRuleKey){
							[hashtable]$testNxtObjectValidationParams = @{
								"ValidationRule" = $ValidationRule.$validationRuleKey.SubKeys
								"ObjectToValidate" = $arrayItem
								"ContinueOnError" = $ContinueOnError
								"ParentObjectName" = $validationRuleKey
							}
							if($true -eq $ValidationRule.$validationRuleKey.ContainsDirectValues){
								$testNxtObjectValidationParams["ContainsDirectValues"] = $true
							}
							Test-NxtObjectValidation @testNxtObjectValidationParams
						}
					}
					"System.Management.Automation.PSCustomObject" {
						if ($true -eq ([bool]($ValidationRule.$validationRuleKey.Type -match $ObjectToValidate.$validationRuleKey.GetType().FullName))){
							Write-Verbose "[${cmdletName}] The variable '$ParentObjectName $validationRuleKey' is of the allowed type $($ObjectToValidate.$validationRuleKey.GetType().FullName)"
						}
						else{
							Write-Log -Message "The variable '$ParentObjectName $validationRuleKey' is not of the allowed type $($ValidationRule.$validationRuleKey.Type) in the package configuration object." -severity 3
							if ($false -eq $ContinueOnError){
								throw "The variable '$ParentObjectName $validationRuleKey' is not of the allowed type $($ValidationRule.$validationRuleKey.Type) in the package configuration object. $($ValidationRule.$validationRuleKey.HelpText)"
							}
						}
						## check for sub objects
						foreach ($subkey in $ValidationRule.$validationRuleKey.SubKeys.Keys){
							Test-NxtObjectValidation -ValidationRule $ValidationRule.$validationRuleKey.SubKeys[$subkey].SubKeys -ObjectToValidate $ObjectToValidate.$validationRuleKey.$Subkey -ParentObjectName $validationRuleKey -ContinueOnError $ContinueOnError
						}
					}
					{$true -eq $ContainsDirectValues}{
						## cast the object to an array in case it is a single value
						foreach ($directValue in [array]$ObjectToValidate){
							Test-NxtObjectValidationHelper -ValidationRule $ValidationRule.$ValidationRuleKey -ObjectToValidate $directValue -ValidationRuleKey $validationRuleKey -ParentObjectName $ParentObjectName -ContinueOnError $ContinueOnError
						}
					}
					Default {
						Test-NxtObjectValidationHelper -ValidationRule $ValidationRule.$ValidationRuleKey -ObjectToValidate $ObjectToValidate.$validationRuleKey -ValidationRuleKey $validationRuleKey -ParentObjectName $ParentObjectName -ContinueOnError $ContinueOnError
					}
				}
			}
		}
		End{

		}
}
#endregion
#region Function Test-NxtObjectValidationHelper
function Test-NxtObjectValidationHelper {
	<#
	.SYNOPSIS
		Tests for Regex, ValidateSet, AllowEmpty etc.
	.DESCRIPTION
		Helper function for Test-NxtObjectValidation.
	.PARAMETER ValidationRule
		ValidationRule for the object.
	.PARAMETER ObjectToValidate
		Object to validate.
	.PARAMETER ValidationRuleKey
		ValidationRuleKey for the object, needed for logging.
	.PARAMETER ParentObjectName
		ParentObjectName for the object, needed for logging.
	.PARAMETER ContinueOnError
		Continue on error.
	.EXAMPLE
		Test-NxtObjectValidationHelper -ValidationRule $ValidationRule.$ValidationRuleKey -ObjectToValidate $ObjectToValidate.$validationRuleKey -ValidationRuleKey $validationRuleKey -ContinueOnError $ContinueOnError
	.OUTPUTS
		none.
	.Link
		private
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[psobject]
		$ValidationRule,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[psobject]
		$ObjectToValidate,
		[Parameter(Mandatory = $false)]
		[string]
		$ParentObjectName,
		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[string]
		$ValidationRuleKey,
		[Parameter(Mandatory = $false)]
		[bool]
		$ContinueOnError
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ($true -eq [bool]($ValidationRule.Type -match $ObjectToValidate.GetType().FullName)){
			Write-Verbose "[${cmdletName}]The variable '$ParentObjectName $ValidationRuleKey' is of the allowed type $($ObjectToValidate.GetType().FullName)"
		}
		else{
			Write-Log -Message "The variable '$ParentObjectName $ValidationRuleKey' is not of the allowed type $($ValidationRule.Type) in the package configuration object." -severity 3
			if ($false -eq $ContinueOnError){
				throw "The variable '$ParentObjectName $ValidationRuleKey' is not of the allowed type $($ValidationRule.Type) in the package configuration object. $($ValidationRule.HelpText)"
			}
		}
		if (
			$true -eq $ValidationRule.AllowEmpty -and
			[string]::IsNullOrEmpty($ObjectToValidate)
		){
			Write-Verbose "[${cmdletName}]'$ParentObjectName $ValidationRuleKey' is allowed to be empty"
		}elseif( [string]::IsNullOrEmpty($ObjectToValidate) ){
			Write-Log -Message "The variable '$ParentObjectName $ValidationRuleKey' is not allowed to be empty in the package configuration object." -severity 3
			if ($false -eq $ContinueOnError){
				throw "The variable '$ParentObjectName $ValidationRuleKey' is not allowed to be empty in the package configuration object. $($ValidationRule.HelpText)"
			}
		}else{
			## regex
			## CheckInvalidFileNameChars
			if ($true -eq $ValidationRule.Regex.CheckInvalidFileNameChars) {
				if ($ObjectToValidate.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0){
					Write-Log -Message "The variable '$ParentObjectName $ValidationRuleKey' contains invalid characters in the package configuration object. $($ValidationRule.HelpText)" -severity 3
					if ($false -eq $ContinueOnError){
						throw "The variable '$ParentObjectName $ValidationRuleKey' contains invalid characters in the package configuration object. $($ValidationRule.HelpText)"
					}
				}
				else {
					Write-Verbose "[${cmdletName}] The variable '$ParentObjectName $ValidationRuleKey' passed the filename check"
				}
			}
			if ($false -eq [string]::IsNullOrEmpty($ValidationRule.Regex.ReplaceBeforeMatch)) {
				$ObjectToValidate = $ObjectToValidate -replace $ValidationRule.Regex.ReplaceBeforeMatch
			}
			if ($ValidationRule.Regex.Operator -eq "match"){
				## validate regex pattern
				if ($true -eq ([bool]($ObjectToValidate -match $ValidationRule.Regex.Pattern))){
					Write-Verbose "[${cmdletName}] The variable '$ParentObjectName $ValidationRuleKey' matches the regex $($ValidationRule.Regex.Pattern)"
				}
				else{
					Write-Log -Message "The variable '$ParentObjectName $ValidationRuleKey' does not match the regex $($ValidationRule.Regex.Pattern) in the package configuration object." -severity 3
					if ($false -eq $ContinueOnError){
						throw "The variable '$ParentObjectName $ValidationRuleKey' does not match the regex $($ValidationRule.Regex.Pattern) in the package configuration object. $($ValidationRule.HelpText)"
					}
				}
			}
			## ValidateSet
			if ($false -eq [string]::IsNullOrEmpty($ValidationRule.ValidateSet)){
				if ($true -eq ([bool]($ValidationRule.ValidateSet -contains $ObjectToValidate))){
					Write-Verbose "[${cmdletName}] The variable '$ParentObjectName $ValidationRuleKey' is in the allowed set $($ValidationRule.ValidateSet)"
				}
				else{
					Write-Log -Message "The variable '$ParentObjectName $ValidationRuleKey' is not in the allowed set $($ValidationRule.ValidateSet) in the package configuration object." -severity 3
					if ($false -eq $ContinueOnError){
						throw "The variable '$ParentObjectName $ValidationRuleKey' is not in the allowed set $($ValidationRule.ValidateSet) in the package configuration object. $($ValidationRule.HelpText)"
					}
				}
			}
		}
	}
}
#endregion
#region Function Test-NxtPackageConfig
function Test-NxtPackageConfig {
	<#
	.SYNOPSIS
		Executes validation steps for custom variables of the package configuration.
	.DESCRIPTION
		Is only called in the Main function and should not be modified!
	.PARAMETER PackageConfig
		Collection of variables to validate.
		Default: $global:PackageConfig
	.PARAMETER ContinueOnError
		Continue on error.
		Default: $false
	.EXAMPLE
		Test-NxtPackageConfig
		Test-NxtPackageConfig -PackageConfig "$global:PackageConfig"
	.OUTPUTS
		System.Boolean.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[PSCustomObject]
		$PackageConfig = $global:PackageConfig,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[PSCustomObject]
		$ValidationRulePath = "$global:Neo42PackageConfigValidationPath",
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[bool]
		$ContinueOnError = $false
	)
	Begin {
		## break reference to global variable
		$PackageConfig = $PackageConfig | Select-Object *
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		[PSCustomObject]$validationRules = Get-Content $ValidationRulePath -Raw | Out-String | ConvertFrom-Json
	}
	Process {
			Test-NxtObjectValidation -ValidationRule $validationRules -Object $PackageConfig -ContinueOnError $ContinueOnError -ParentObjectName "PackageConfig"
		}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Test-NxtPersonalizationLightTheme
function Test-NxtPersonalizationLightTheme {
	<#
	.DESCRIPTION
		Tests if a user has the light theme enabled.
	.OUTPUTS
		System.Boolean.
	.EXAMPLE
		Test-NxtPersonalizationLightTheme
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[bool]$lightThemeResult = $true
		if ($true -eq (Test-RegistryValue -Key "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Value "AppsUseLightTheme")) {
			if ((Get-RegistryKey -Key "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Value "AppsUseLightTheme") -eq 1) {
				[bool]$lightThemeResult = $true
			} 
			else {
				[bool]$lightThemeResult = $false
			}
		} 
		else {
			if ($true -eq (Test-RegistryValue -Key "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Value "SystemUsesLightTheme")) {
				if ((Get-RegistryKey -Key "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Value "SystemUsesLightTheme") -eq 1) {
					[bool]$lightThemeResult = $true
				} 
				else {
					[bool]$lightThemeResult = $false
				}
			} 
		}
		Write-Output $lightThemeResult
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Test-NxtProcessExists
function Test-NxtProcessExists {
	<#
	.DESCRIPTION
		Tests if a process exists by name or custom WQL query.
	.PARAMETER ProcessName
		Name of the process or WQL search string.
	.PARAMETER IsWql
		Defines if the given ProcessName is a WQL search string.
		Defaults to $false.
	.OUTPUTS
		System.Boolean.
	.EXAMPLE
		Test-NxtProcessExists "Notepad"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$ProcessName,
		[Parameter()]
		[switch]
		$IsWql = $false
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[string]$wqlString = [string]::Empty
			if ($IsWql) {
				[string]$wqlString = $ProcessName
			}
			else {
				[string]$wqlString = "Name LIKE '$($ProcessName.Replace("*","%"))'"
			}
			[System.Management.ManagementBaseObject]$processes = Get-WmiObject -Query "Select * from Win32_Process Where $($wqlString)" | Select-Object -First 1
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
#region Function Uninstall-NxtApplication
function Uninstall-NxtApplication {
	<#
	.SYNOPSIS
		Defines the required steps to uninstall the application based on the target installer type
	.DESCRIPTION
		Is only called in the Main function and should not be modified!
	.PARAMETER UninstallKey
		Specifies the original UninstallKey set by the Installer in this Package.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyIsDisplayName
		Determines if the value given as UninstallKey should be interpreted as a displayname.
		Only applies to Inno Setup, Nullsoft and BitRockInstaller.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyContainsWildCards
		Determines if the value given as UninstallKey contains WildCards.
		If set to $true "*" are interpreted as WildCards.
		If set to $false "*" are interpreted as part of the actual string.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER DisplayNamesToExclude
		DisplayName(s) to exclude, when retrieving Data about the application from the uninstall key in the registry.
		Use commas to separate more than one value.
		"*" inside this parameter will not be interpreted as WildCards. (This has no effect on the use of WildCards in other parameters!)
		We reccommend always adding "$global:PackageConfig.UninstallDisplayName" if used inside a package to exclude the current package itself, especially if combined with the "UninstallKeyContainsWildCards" parameter.
		Defaults to the "DisplayNamesToExcludeFromAppSearches" value from the PackageConfig object.
	.PARAMETER UninstLogFile
		Defines the path to the Logfile that should be used by the uninstaller.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstFile
		Defines the path to the Installation File.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstPara
		Defines the parameters which will be passed in the UnInstallation Commandline.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppendUninstParaToDefaultParameters
		If set to $true the parameters specified with UninstPara are added to the default parameters specified in the XML configuration file.
		If set to $false the parameters specified with UninstPara overwrite the default parameters specified in the XML configuration file.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AcceptedUninstallExitCodes
		Defines a list of exit codes or * for all exit codes that will be accepted for success by called setup execution.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallMethod
		Defines the type of the uninstaller used in this package.
		Defaults to the corresponding value from the PackageConfig object
	.PARAMETER PreSuccessCheckTotalSecondsToWaitFor
		Timeout in seconds the function waits and checks for the condition to occur.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PreSuccessCheckProcessOperator
		Operator to define process condition requirements.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PreSuccessCheckProcessesToWaitFor
		An array of process conditions to check for.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PreSuccessCheckRegKeyOperator
		Operator to define regkey condition requirements.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PreSuccessCheckRegkeysToWaitFor
		An array of regkey conditions to check for.
		Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Uninstall-NxtApplication
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$UninstallKey = $global:PackageConfig.UninstallKey,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyIsDisplayName = $global:PackageConfig.UninstallKeyIsDisplayName,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyContainsWildCards = $global:PackageConfig.UninstallKeyContainsWildCards,
		[Parameter(Mandatory = $false)]
		[array]
		$DisplayNamesToExclude = $global:PackageConfig.DisplayNamesToExcludeFromAppSearches,
		[Parameter(Mandatory = $false)]
		[string]
		$UninstLogFile = $global:PackageConfig.UninstLogFile,
		[Parameter(Mandatory = $false)]
		[string]
		$UninstFile = $global:PackageConfig.UninstFile,
		[Parameter(Mandatory = $false)]
		[string]
		$UninstPara = $global:PackageConfig.UninstPara,
		[Parameter(Mandatory = $false)]
		[bool]
		$AppendUninstParaToDefaultParameters = $global:PackageConfig.AppendUninstParaToDefaultParameters,
		[Parameter(Mandatory = $false)]
		[string]
		$AcceptedUninstallExitCodes = $global:PackageConfig.AcceptedUninstallExitCodes,
		[Parameter(Mandatory = $false)]
		[string]
		$UninstallMethod = $global:PackageConfig.UninstallMethod,
		[Parameter(Mandatory = $false)]
		[int]
		$PreSuccessCheckTotalSecondsToWaitFor = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Uninstall.TotalSecondsToWaitFor,
		[Parameter(Mandatory = $false)]
		[string]
		$PreSuccessCheckProcessOperator = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Uninstall.ProcessOperator,
		[Parameter(Mandatory = $false)]
		[array]
		$PreSuccessCheckProcessesToWaitFor = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Uninstall.ProcessesToWaitFor,
		[Parameter(Mandatory = $false)]
		[string]
		$PreSuccessCheckRegKeyOperator = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Uninstall.RegKeyOperator,
		[Parameter(Mandatory = $false)]
		[array]
		$PreSuccessCheckRegkeysToWaitFor = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Uninstall.RegkeysToWaitFor
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[PSADTNXT.NxtApplicationResult]$uninstallResult = New-Object -TypeName PSADTNXT.NxtApplicationResult
		if ($UninstallMethod -eq "none") {
			$uninstallResult.ApplicationExitCode = $null
			$uninstallResult.ErrorMessage = "An uninstallation method was NOT set. Skipping a default process execution."
			$uninstallResult.Success = $null
			[int]$logMessageSeverity = 1
		}
		else {
			$uninstallResult.Success = $false
			[int]$logMessageSeverity = 1
			if ([string]::IsNullOrEmpty($UninstallKey)) {
				Write-Log -Message "UninstallKey value NOT set. Skipping test for installed application via registry. Checking for UninstFile instead..." -Source ${CmdletName}
				$uninstallResult.Success = $null
				if ([string]::IsNullOrEmpty($UninstFile)) {
					$uninstallResult.ApplicationExitCode = $null
					$uninstallResult.ErrorMessage = "Value 'UninstFile' NOT set. Uninstallation NOT executed."
					[int]$logMessageSeverity = 2
				}
				else {
					if ([System.IO.File]::Exists($UninstFile)) {
						Write-Log -Message "File for running an uninstallation found: '$UninstFile'. Executing the uninstallation..." -Source ${CmdletName}
						Execute-Process -Path "$UninstFile" -Parameters "$UninstPara"
						$uninstallResult.ApplicationExitCode = $LastExitCode
						$uninstallResult.ErrorMessage = "Uninstallation done with return code '$($uninstallResult.ApplicationExitCode)'."
						[int]$logMessageSeverity = 1
					}
					else {
						$uninstallResult.ErrorMessage = "Excpected file for running an uninstallation NOT found: '$UninstFile'. Uninstallation NOT executed. Possibly the expected application is not installed on system anymore!"
						[int]$logMessageSeverity = 2
					}
				}
			}
			else {
				if ($true -eq $(Test-NxtAppIsInstalled -UninstallKey "$UninstallKey" -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -DeploymentMethod $UninstallMethod)) {

					[hashtable]$executeNxtParams = @{
						Action							= 'Uninstall'
						UninstallKeyIsDisplayName		= $UninstallKeyIsDisplayName
						UninstallKeyContainsWildCards	= $UninstallKeyContainsWildCards
						DisplayNamesToExclude			= $DisplayNamesToExclude
					}
					if ($false -eq [string]::IsNullOrEmpty($UninstPara)) {
						if ($AppendUninstParaToDefaultParameters) {
							[string]$executeNxtParams["AddParameters"] = "$UninstPara"
						}
						else {
							[string]$executeNxtParams["Parameters"] = "$UninstPara"
						}
					}
					if (![string]::IsNullOrEmpty($AcceptedUninstallExitCodes)) {
						[string]$executeNxtParams["IgnoreExitCodes"] = "$AcceptedUninstallExitCodes"
					}
					if ([string]::IsNullOrEmpty($UninstallKey)) {
						[string]$internalInstallerMethod = [string]::Empty
					}
					else {
						[string]$internalInstallerMethod = $UninstallMethod
					}
					switch -Wildcard ($internalInstallerMethod) {
						MSI {
							Execute-NxtMSI @executeNxtParams -Path "$UninstallKey" -Log "$UninstLogFile"
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
						default {
							[hashtable]$executeParams = @{
								Path	= "$UninstFile"
							}
							if (![string]::IsNullOrEmpty($UninstPara)) {
								[string]$executeParams["Parameters"] = "$UninstPara"
							}
							if (![string]::IsNullOrEmpty($AcceptedUninstallExitCodes)) {
								[string]$executeParams["IgnoreExitCodes"] = "$AcceptedUninstallExitCodes"
							}
							Execute-Process @executeParams
						}
					}
					$uninstallResult.MainExitCode = $mainExitCode
					$uninstallResult.ApplicationExitCode = $LastExitCode
					## Delay for filehandle release etc. to occur.
					Start-Sleep -Seconds 5

					## Test successfull uninstallation
					if ([string]::IsNullOrEmpty($UninstallKey)) {
						$uninstallResult.ErrorMessage = "UninstallKey value NOT set. Skipping test for successfull uninstallation of '$appName' via registry."
						$uninstallResult.Success = $null
						[int]$logMessageSeverity = 2
					}
					else {
						if ($false -eq (Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor $PreSuccessCheckTotalSecondsToWaitFor -ProcessOperator $PreSuccessCheckProcessOperator -ProcessesToWaitFor $PreSuccessCheckProcessesToWaitFor -RegKeyOperator $PreSuccessCheckRegKeyOperator -RegkeysToWaitFor $PreSuccessCheckRegkeysToWaitFor)) {
							$uninstallResult.ErrorMessage = "Uninstallation RegistryAndProcessCondition of '$appName' failed. ErrorLevel: $($uninstallResult.ApplicationExitCode)"
							$uninstallResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
							$uninstallResult.Success = $false
							[int]$logMessageSeverity = 3
						}
						else {
							if ($true -eq $(Test-NxtAppIsInstalled -UninstallKey "$UninstallKey" -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -DeploymentMethod $internalInstallerMethod)) {
								$uninstallResult.ErrorMessage = "Uninstallation of '$appName' failed. ErrorLevel: $($uninstallResult.ApplicationExitCode)"
								$uninstallResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
								$uninstallResult.Success = $false
								[int]$logMessageSeverity = 3
							}
							else {
								$uninstallResult.ErrorMessage = "Uninstallation of '$appName' was successful."
								$uninstallResult.Success = $true
								[int]$logMessageSeverity = 1
							}
						}
					}
				}
				else {
					$uninstallResult.ErrorMessage = "Uninstall function could not run for provided parameter 'UninstallKey=$UninstallKey'. The expected application seems not to be installed on system!"
					$uninstallResult.Success = $null
					[int]$logMessageSeverity = 1
				}
			}
}

		Write-Log -Message $($uninstallResult.ErrorMessage) -Severity $logMessageSeverity -Source ${CmdletName}
		Write-Output $uninstallResult
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Uninstall-NxtOld
function Uninstall-NxtOld {
	<#
	.SYNOPSIS
		Uninstalls old package versions if corresponding value from the PackageConfig object "UninstallOld": true.
	.DESCRIPTION
		If $UninstallOld is set to true, the function checks for old versions of the same package / $PackageGUID and uninstalls them.
	.PARAMETER AppName
		Specifies the Application Name used in the registry etc.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppVendor
		Specifies the Application Vendor used in the registry etc.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppVersion
		Specifies the Application Version used in the registry etc.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PackageGUID
		Specifies the registry key name used for the packages wrapper uninstall entry.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegPackagesKey
		Defines the name of the registry key keeping track of all packages delivered by this packaging framework.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallOld
		Will uninstall previous Versions before Installation if set to $true.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER DeploymentSystem
		Defines the deployment system used for the deployment.
		Defaults to the corresponding value of the DeployApplication.ps1 parameter.
	.EXAMPLE
		Uninstall-NxtOld
	.NOTES
		Should be executed during package Initialization only.
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$AppName = $global:PackageConfig.AppName,
		[Parameter(Mandatory = $false)]
		[string]
		$AppVendor = $global:PackageConfig.AppVendor,
		[Parameter(Mandatory = $false)]
		[string]
		$AppVersion = $global:PackageConfig.AppVersion,
		[Parameter(Mandatory = $false)]
		[string]
		$PackageGUID = $global:PackageConfig.PackageGUID,
		[Parameter(Mandatory = $false)]
		[string]
		$RegPackagesKey = $global:PackageConfig.RegPackagesKey,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallOld = $global:PackageConfig.UninstallOld,
		[Parameter(Mandatory = $false)]
		[string]
		$DeploymentSystem = $global:DeploymentSystem
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[PSADTNXT.NxtApplicationResult]$uninstallOldResult = New-Object -TypeName PSADTNXT.NxtApplicationResult
		$uninstallOldResult.Success = $null
		$uninstallOldResult.ApplicationExitCode = $null
		if ($true -eq $UninstallOld) {
			Write-Log -Message "Checking for old package installed..." -Source ${cmdletName}
			try {
				[bool]$ReturnWithError = $false
				## Check for Empirum packages under "HKLM:\Software\WOW6432Node\"
				if (Test-Path -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor") {
					if (Test-Path -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName") {
						[array]$appEmpirumPackageVersions = Get-ChildItem "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName"
						if (($appEmpirumPackageVersions).Count -eq 0) {
							Remove-Item -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName"
							Write-Log -Message "Deleted an empty Empirum application key: HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName" -Source ${cmdletName}
						}
						else {
							foreach ($appEmpirumPackageVersion in $appEmpirumPackageVersions) {
								if ($true -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'PackageGUID')) {
									[string]$appEmpirumPackageVersionNumber = Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'Version'
									[string]$appEmpirumPackageGUID = Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'PackageGUID'
								}
								If (($false -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'PackageGUID')) -or (($appEmpirumPackageGUID -eq $PackageGUID) -and (("$(Compare-NxtVersion -DetectedVersion "$appEmpirumPackageVersionNumber" -TargetVersion "$AppVersion")") -ne "Equal"))) {
									Write-Log -Message "Found an old Empirum package version key: $($appEmpirumPackageVersion.name)" -Source ${cmdletName}
									if ($true -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString')) {
										try {
											[string]$appendAW = [string]::Empty
											if ((Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'MachineSetup') -eq "1") {
												[string]$appendAW = " /AW"
											}
											[string]$appEmpUninstallString = Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString'
											[string]$appEmpLogPath = Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'AppPath'
											[string]$appEmpLogDate = $currentDateTime | get-date -Format "yyyy-MM-dd_HH-mm-ss"
											cmd /c "$appEmpUninstallString /X8 /S0$appendAW /F /E+`"$appEmpLogPath\$appEmpLogDate.log`"" | Out-Null
										}
										catch {
										}
										if (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString') {
											[int32]$mainExitCode = 70001
											$uninstallOldResult.MainExitCode = $mainExitCode
											$uninstallOldResult.ApplicationExitCode = $LastExitCode
											$uninstallOldResult.ErrorMessage = "Uninstallation of found Empirum package '$($appEmpirumPackageVersion.name)' failed."
											$uninstallOldResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
											$uninstallOldResult.Success = $false
											[bool]$ReturnWithError = $true
											Write-Log -Message $($uninstallOldResult.ErrorMessage) -Severity 3 -Source ${cmdletName}
											break
										}
										else {
											$uninstallOldResult.ErrorMessage = "Uninstallation of found Empirum package: '$($appEmpirumPackageVersion.name)' was successful."
											$uninstallOldResult.Success = $true
											Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
										}
									}
									else {
										$appEmpirumPackageVersion | Remove-Item -Recurse
										$uninstallOldResult.ErrorMessage = "This key contained no value 'UninstallString' and was deleted: $($appEmpirumPackageVersion.name)"
										$uninstallOldResult.Success = $null
										Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
									}
								}
							}
							if ( !$ReturnWithError -and (($appEmpirumPackageVersions).Count -eq 0) -and (Test-Path -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName") ) {
								Remove-Item -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName"
								$uninstallOldResult.ErrorMessage = "Deleted the now empty Empirum application key: HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName"
								$uninstallOldResult.Success = $null
								Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
							}
						}
					}
					if ( !$ReturnWithError -and ((Get-ChildItem "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor").Count -eq 0) ) {
						Remove-Item -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor"
						$uninstallOldResult.ErrorMessage = "Deleted empty Empirum vendor key: HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor"
						$uninstallOldResult.Success = $null
						Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
					}
				}
				## Check for Empirum packages under "HKLM:\Software\"
				if ( !$ReturnWithError -and (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$AppVendor") ) {
					if (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$AppVendor\$AppName") {
						[array]$appEmpirumPackageVersions = Get-ChildItem "HKLM:\Software\$RegPackagesKey\$AppVendor\$AppName"
						if (($appEmpirumPackageVersions).Count -eq 0) {
							Remove-Item -Path "HKLM:\Software\$RegPackagesKey\$AppVendor\$AppName"
							Write-Log -Message "Deleted an empty Empirum application key: HKLM:\Software\$RegPackagesKey\$AppVendor\$AppName" -Source ${cmdletName}
						}
						else {
							foreach ($appEmpirumPackageVersion in $appEmpirumPackageVersions) {
								if ($true -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'PackageGUID')) {
									[string]$appEmpirumPackageVersionNumber = Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'Version'
									[string]$appEmpirumPackageGUID = Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'PackageGUID'
								}
								If (($false -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'PackageGUID')) -or (($appEmpirumPackageGUID -eq $PackageGUID) -and (("$(Compare-NxtVersion -DetectedVersion "$appEmpirumPackageVersionNumber" -TargetVersion "$AppVersion")") -ne "Equal"))) {
									Write-Log -Message "Found an old Empirum package version key: $($appEmpirumPackageVersion.name)" -Source ${cmdletName}
									if (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString') {
										try {
											[string]$appendAW = [string]::Empty
											if ((Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'MachineSetup') -eq "1") {
												[string]$appendAW = " /AW"
											}
											[string]$appEmpUninstallString = Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString'
											[string]$appEmpLogPath = Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'AppPath'
											[string]$appEmpLogDate = $currentDateTime | get-date -Format "yyyy-MM-dd_HH-mm-ss"
											cmd /c "$appEmpUninstallString /X8 /S0$appendAW /F /E+`"$appEmpLogPath\$appEmpLogDate.log`"" | Out-Null
										}
										catch {
										}
										if (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString') {
											[int32]$mainExitCode = 70001
											$uninstallOldResult.MainExitCode = $mainExitCode
											$uninstallOldResult.ApplicationExitCode = $LastExitCode
											$uninstallOldResult.ErrorMessage = "Uninstallation of found Empirum package '$($appEmpirumPackageVersion.name)' failed."
											$uninstallOldResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
											$uninstallOldResult.Success = $false
											Write-Log -Message $($uninstallOldResult.ErrorMessage) -Severity 3 -Source ${cmdletName}
											[bool]$ReturnWithError = $true
											break
										}
										else {
											$uninstallOldResult.ErrorMessage = "Uninstallation of found Empirum package '$($appEmpirumPackageVersion.name)' was successful."
											$uninstallOldResult.Success = $true
											Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
										}
									}
									else {
										$appEmpirumPackageVersion | Remove-Item -Recurse
										$uninstallOldResult.ErrorMessage = "This key contained no value 'UninstallString' and was deleted: $($appEmpirumPackageVersion.name)"
										$uninstallOldResult.Success = $null
										Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
									}
								}
							}
							if (!$ReturnWithError -and (($appEmpirumPackageVersions).Count -eq 0) -and (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$AppVendor\$AppName")) {
								Remove-Item -Path "HKLM:\Software\$RegPackagesKey\$AppVendor\$AppName"
								$uninstallOldResult.ErrorMessage = "Deleted the now empty Empirum application key: HKLM:\Software\$RegPackagesKey\$AppVendor\$AppName"
								$uninstallOldResult.Success = $null
								Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
							}
						}
					}
					if (!$ReturnWithError -and ((Get-ChildItem "HKLM:\Software\$RegPackagesKey\$AppVendor").Count -eq 0)) {
						Remove-Item -Path "HKLM:\Software\$RegPackagesKey\$AppVendor"
						$uninstallOldResult.ErrorMessage = "Deleted empty Empirum vendor key: HKLM:\Software\$RegPackagesKey\$AppVendor"
						$uninstallOldResult.Success = $null
						Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
					}
				}
				if (!$ReturnWithError) {
					[string]$regPackageGUID = $null
					## Check for VBS or PSADT packages
					if (Test-RegistryValue -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Value 'UninstallString') {
						[string]$regPackageGUID = "HKLM:\Software\$RegPackagesKey\$PackageGUID"
					}
					elseif (Test-RegistryValue -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$PackageGUID" -Value 'UninstallString') {
						[string]$regPackageGUID = "HKLM:\Software\Wow6432Node\$RegPackagesKey\$PackageGUID"
					}
					if (![string]::IsNullOrEmpty($regPackageGUID)) {
						## Check if the installed package's version is lower than the current one's (else we don't remove old package)
						if ("$(Compare-NxtVersion -DetectedVersion "$(Get-RegistryKey -Key "$regPackageGUID" -Value 'Version')" -TargetVersion "$AppVersion")" -ne "Update") {
							[string]$regPackageGUID = $null
						}
					} else {
						## Check for old VBS product member package (only here: old $PackageFamilyGUID is stored in $ProductGUID)
						if (Test-RegistryValue -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$ProductGUID" -Value 'UninstallString') {
							[string]$regPackageGUID = "HKLM:\Software\Wow6432Node\$RegPackagesKey\$ProductGUID"
						}
						elseif (Test-RegistryValue -Key "HKLM:\Software\$RegPackagesKey\$ProductGUID" -Value 'UninstallString') {
							[string]$regPackageGUID = "HKLM:\Software\$RegPackagesKey\$ProductGUID"
						}
						if (![string]::IsNullOrEmpty($regPackageGUID)) {
							Write-Log -Message "A former product member application package was found." -Source ${cmdletName}
						}
					}
					## if the current package is a new ADT package, but is actually only registered because it is a product member package, we cannot uninstall it again now
					if ((Get-NxtRegisteredPackage -ProductGUID "$ProductGUID" -InstalledState 1).PackageGUID -notcontains "$PackageGUID") {
						[string]$regPackageGUID = $null
					}
					if (![string]::IsNullOrEmpty($regPackageGUID)) {
						Write-Log -Message "Parameter 'UninstallOld' is set to true and an old package version was found: Uninstalling old package with PackageGUID [$(Split-Path -Path `"$regPackageGUID`" -Leaf)]..." -Source ${cmdletName}
						cmd /c (Get-RegistryKey -Key "$regPackageGUID" -Value 'UninstallString') | Out-Null
						if (Test-RegistryValue -Key "$regPackageGUID" -Value 'UninstallString') {
							[int32]$mainExitCode = 70001
							$uninstallOldResult.MainExitCode = $mainExitCode
							$uninstallOldResult.ApplicationExitCode = $LastExitCode
							$uninstallOldResult.ErrorMessage = "ERROR: Uninstallation of old package failed. Abort!"
							$uninstallOldResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
							$uninstallOldResult.Success = $false
							Write-Log -Message $($uninstallOldResult.ErrorMessage) -Severity 3 -Source ${cmdletName}
						}
						else {
							$uninstallOldResult.ErrorMessage = "Uninstallation of old package successful."
							$uninstallOldResult.Success = $true
							Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
						}
					}
					else {
						$uninstallOldResult.ErrorMessage = "No need to uninstall old package."
						$uninstallOldResult.Success = $null
						Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
					}
				}
			}
			catch {
				$uninstallOldResult.ErrorMessage = "The function '${cmdletName}' threw an error."
				$uninstallOldResult.Success = $false
				Write-Log -Message "$($uninstallOldResult.ErrorMessage)`n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
			}
		}
		Write-Output $uninstallOldResult
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Unregister-NxtOld
function Unregister-NxtOld {
	<#
	.SYNOPSIS
		Unregisters old package versions if UninstallOld from the PackageConfig object is false.
	.DESCRIPTION
		If $UninstallOld is set to false, the function checks for old versions of the same package ($ProductGUID is equal to former ProductFamilyGUID) and unregisters them.
	.PARAMETER ProductGUID
		Specifies a membership GUID for a product of an application package.
		Can be found under "HKLM:\Software\<RegPackagesKey>\<PackageGUID>" for an application package with product membership.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PackageGUID
		Specifies the registry key name used for the packages wrapper uninstall entry.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegPackagesKey
		Defines the name of the registry key keeping track of all packages delivered by this packaging framework.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallOld
		Will uninstall previous Versions before Installation if set to $true.
		Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Unregister-NxtOld
	.NOTES
		Should be executed during package Initialization only.
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$ProductGUID = $global:PackageConfig.ProductGUID,
		[Parameter(Mandatory = $false)]
		[string]
		$PackageGUID = $global:PackageConfig.PackageGUID,
		[Parameter(Mandatory = $false)]
		[string]
		$RegPackagesKey = $global:PackageConfig.RegPackagesKey,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallOld = $global:PackageConfig.UninstallOld
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ($false -eq $UninstallOld) {
			Write-Log -Message "Checking for old package registered..." -Source ${cmdletName}
			[string]$currentGUID = $null
			## process an old application package
			if ( ($true -eq (Test-Path -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -PathType 'Container')) -or
			($true -eq (Test-Path -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$PackageGUID" -PathType 'Container')) -or
			($true -eq (Test-Path -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -PathType 'Container')) -or
			($true -eq (Test-Path -Key "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -PathType 'Container')) ) {
				[string]$currentGUID = $PackageGUID
				if ((("$(Compare-NxtVersion -DetectedVersion "$(Get-RegistryKey -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID" -Value 'Version')" -TargetVersion "$AppVersion")") -eq "Update") -and (Test-RegistryValue -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID" -Value 'AppPath')) {
					[string]$currentAppPath = (Get-RegistryKey -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID" -Value 'AppPath')
				}
				elseif ((("$(Compare-NxtVersion -DetectedVersion "$(Get-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$currentGUID" -Value 'Version')" -TargetVersion "$AppVersion")") -eq "Update") -and (Test-RegistryValue -Key "HKLM:\Software\$RegPackagesKey\$currentGUID" -Value 'AppPath')) {
					[string]$currentAppPath = (Get-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$currentGUID" -Value 'AppPath')
				}
			}
			## process old product group member
			elseif ( ($true -eq (Test-Path -Key "HKLM:\Software\$RegPackagesKey\$ProductGUID" -PathType 'Container')) -or
			($true -eq (Test-Path -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$ProductGUID" -PathType 'Container')) -or
			($true -eq (Test-Path -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$ProductGUID" -PathType 'Container')) -or
			($true -eq (Test-Path -Key "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$ProductGUID" -PathType 'Container')) ) {
				[string]$currentGUID = $ProductGUID
				## retrieve AppPath for former VBS package (only here: old $PackageFamilyGUID is stored in $ProductGUID)
				if (Test-RegistryValue -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID" -Value 'AppPath') {
					[string]$currentAppPath = (Get-RegistryKey -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID" -Value 'AppPath')
					if ([string]::IsNullOrEmpty($currentAppPath)) {
						[string]$currentAppPath = (Get-RegistryKey -Key "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$currentGUID" -Value 'PackageApplicationDir')
					}
				}
				elseif (Test-RegistryValue -Key "HKLM:\Software\$RegPackagesKey\$currentGUID" -Value 'AppPath') {
					[string]$currentAppPath = (Get-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$currentGUID" -Value 'AppPath')
					if ([string]::IsNullOrEmpty($currentAppPath)) {
						[string]$currentAppPath = (Get-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$currentGUIDv" -Value 'PackageApplicationDir')
					}
					## for an old product member we always remove these registry keys (in case of x86 packages we do it later anyway)
					Remove-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$currentGUID"
					Remove-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$currentGUID"
				}
				else {
					[string]$currentGUID = $null
				}
			}
			if (![string]::IsNullOrEmpty($currentGUID)) {
				## note: the x64 uninstall registry keys are still the same as for old package and remains there if the old package should not to be uninstalled (not true for old product member packages, see above!)
				Remove-RegistryKey -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID"
				Remove-RegistryKey -Key "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$currentGUID"
				if ( ($true -eq (Test-Path -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID" -PathType 'Container')) -or
				($true -eq (Test-Path -Key "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$currentGUID" -PathType 'Container')) -or
				($true -eq (Test-Path -Key "HKLM:\Software\$RegPackagesKey\$currentGUID" -PathType 'Container')) -or
				($true -eq (Test-Path -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$currentGUID" -PathType 'Container')) ) {
					Write-Log -Message "Unregister of old package was incomplete! Some orphaned registry keys remain on the client." -Severity 2 -Source ${cmdletName}
				}
			}
			else {
				Write-Log -Message "No need to cleanup old package registration." -Source ${cmdletName}
			}
			if (![string]::IsNullOrEmpty($currentAppPath)) {
				if ($true -eq (Test-Path -Key "$currentAppPath")) {
					Remove-Folder -Path "$currentAppPath\neoInstall"
					Remove-Folder -Path "$currentAppPath\neoSource"
					if ( ($true -eq (Test-Path -Key "$currentAppPath\neoInstall")) -or ($true -eq (Test-Path -Key "$currentAppPath\neoSource")) ) {
						Write-Log -Message "Unregister of old package was incomplete! Some orphaned files and might remain on the client." -Severity 2 -Source ${cmdletName}
					}
				}
			}
			else {
				Write-Log -Message "No need to cleanup old package cached app folder." -Source ${cmdletName}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Unregister-NxtPackage
function Unregister-NxtPackage {
	<#
	.SYNOPSIS
		Removes package files and unregisters the package in the registry.
	.DESCRIPTION
		Removes the package files from folder "$APP\" and deletes the package's registry keys under "HKLM:\Software\$regPackagesKey\$PackageGUID" and "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID".
	.PARAMETER ProductGUID
		Specifies a membership GUID for a product of an application package.
		Can be found under "HKLM:\Software\<RegPackagesKey>\<PackageGUID>" for an application package with product membership.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RemovePackagesWithSameProductGUID
		Switch for awareness of product membership of the application package, a value of '$true' defines the package itself will be hided during removal of other product member application packages, it will be processed like an default independent application package then.
		During installation and uninstallation of itself the application package will operate like a product member too.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PackageGUID
		Specifies the registry key name used for the packages wrapper uninstall entry.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegPackagesKey
		Defines the name of the registry key keeping track of all packages delivered by this packaging framework.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER App
		Defines the path to a local persistent cache for installation files.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER ScriptRoot
		Defines the parent directory of the script.
		Defaults to the Variable $scriptRoot populated by AppDeployToolkitMain.ps1.
	.EXAMPLE
		Unregister-NxtPackage
	.NOTES
		Should be executed at the end of each neo42-package uninstallation only.
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
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
		$App = $global:PackageConfig.App,
		[Parameter(Mandatory = $false)]
		[string]
		$ScriptRoot = $scriptRoot
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		Write-Log -Message "Unregistering package(s)..." -Source ${cmdletName}
		try {
			if ($true -eq $RemovePackagesWithSameProductGUID) {
				[int]$removalCounter = 0
				if (![string]::IsNullOrEmpty($ProductGUID)) {
					Write-Log -Message "Cleanup registry entries and folder of assigned product member application packages with 'ProductGUID' [$ProductGUID]..." -Source ${CmdletName}
					(Get-NxtRegisteredPackage -ProductGUID $ProductGUID).PackageGUID | Where-Object { $null -ne $($_) } | ForEach-Object {
						[string]$assignedPackageGUID = $_
						Write-Log -Message "Processing tasks for product member application package with PackageGUID [$assignedPackageGUID]..."  -Source ${CmdletName}
						[string]$assignedPackageGUIDAppPath = (Get-Registrykey -Key "HKLM:\Software\$RegPackagesKey\$assignedPackageGUID").AppPath
						if (![string]::IsNullOrEmpty($assignedPackageGUIDAppPath)) {
							if ($true -eq (Test-Path -Path "$assignedPackageGUIDAppPath")) {
								## note: we always use the script from current application package source folder (it is basically identical in each package)
								Copy-File -Path "$scriptRoot\Clean-Neo42AppFolder.ps1" -Destination "$assignedPackageGUIDAppPath\"
								Start-Sleep -Seconds 1
								Execute-Process -Path powershell.exe -Parameters "-File `"$assignedPackageGUIDAppPath\Clean-Neo42AppFolder.ps1`"" -WorkingDirectory "$assignedPackageGUIDAppPath" -NoWait
							}
							else {
								Write-Log -Message "No current 'App' path [$assignedPackageGUIDAppPath] available, cleanup script will not be executed." -Source ${CmdletName}
							}
						}
						else {
							Write-Log -Message "No valid 'App' path found/defined, cleanup script will not be executed." -Source ${CmdletName}
						}
						Remove-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$assignedPackageGUID"
						Remove-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$assignedPackageGUID"
					}
					Write-Log -Message "All folder and registry entries of assigned product member application packages with 'ProductGUID' [$ProductGUID] are cleaned." -Source ${CmdletName}
					if ($removalCounter = 0) {
						Write-Log -Message "No application packages assigned to a product found for removal." -Source ${CmdletName}
					}
				}
				else {
					Write-Log -Message "No ProductGUID was provided. Cleanup for application packages assigned to a product skipped." -Severity 2 -Source ${CmdletName}
				}
			}
			else {
				Write-Log -Message "No valid conditions for removal of assigned product member application packages. Unregistering package with 'PackageGUID' [$PackageGUID] only..." -Source ${cmdletName}
				if ($PackageGUID -ne $global:PackageConfig.PackageGUID) {
					[string]$App = (Get-Registrykey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID").AppPath
				}
				if (![string]::IsNullOrEmpty($App)) {
					if ($true -eq (Test-Path -Path "$App")) {
						## note: we always use the script from current application package source folder (it is basically identical in each package)
						Copy-File -Path "$scriptRoot\Clean-Neo42AppFolder.ps1" -Destination "$App\"
						Start-Sleep -Seconds 1
						Execute-Process -Path powershell.exe -Parameters "-File `"$App\Clean-Neo42AppFolder.ps1`"" -WorkingDirectory "$App" -NoWait
					}
					else {
						Write-Log -Message "No current 'App' path [$App] available, cleanup script will not be executed." -Source ${CmdletName}
					}
				}
				else {
					Write-Log -Message "No valid 'App' path found/defined, cleanup script will not be executed." -Source ${CmdletName}
				}
				Remove-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID"
				Remove-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID"
				Write-Log -Message "Current package unregistration successful." -Source ${cmdletName}
			}
		}
		catch {
			Write-Log -Message "Failed to unregister package. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Update-NxtTextInFile
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
		none.
  	.LINK
		https://neo42.de/psappdeploytoolkit
  #>
	[CmdletBinding()]
	Param (
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
	}
	Process {
		[String]$intEncoding = $Encoding
		if (!(Test-Path $Path) -and ([String]::IsNullOrEmpty($intEncoding))) {
			[string]$intEncoding = "UTF8"
		}
		elseif ((Test-Path $Path) -and ([String]::IsNullOrEmpty($intEncoding))) {
			try {
				[hashtable]$getFileEncodingParams = @{
					Path = $Path
				}
				if (![string]::IsNullOrEmpty($DefaultEncoding)) {
					[string]$getFileEncodingParams['DefaultEncoding'] = $DefaultEncoding
				}
				[string]$intEncoding = (Get-NxtFileEncoding @GetFileEncodingParams)
				if ($intEncoding -eq "UTF8") {
					[bool]$noBOMDetected = $true
				}
				elseif ($intEncoding -eq "UTF8withBom") {
					[bool]$noBOMDetected = $false
					[string]$intEncoding = "UTF8"
				}
			}
			catch {
				[string]$intEncoding = "UTF8"
			}
		}
		try {
			[hashtable]$contentParams = @{
				Path = $Path
			}
			if (![string]::IsNullOrEmpty($intEncoding)) {
				[string]$contentParams['Encoding'] = $intEncoding
			}
			[string]$Content = Get-Content @contentParams -Raw
			[regex]$pattern = $SearchString
			[array]$regexMatches = $pattern.Matches($Content) | Select-Object -First $Count
			if ($regexMatches.count -eq 0) {
				Write-Log -Message "Did not find anything to replace in file '$Path'."
				return
			}
			else {
				Write-Log -Message "Replace found text in file '$Path'."
			}
			[array]::Reverse($regexMatches)
			foreach ($match in $regexMatches) {
				[string]$Content = $Content.Remove($match.index, $match.Length).Insert($match.index, $ReplaceString)
			}
			if ($noBOMDetected -and ($intEncoding -eq "UTF8")) {
				[System.IO.File]::WriteAllLines($Path, $Content)
			}
			else {
				$Content | Set-Content @contentParams -NoNewline
			}
		}
		catch {
			Write-Log -Message "Failed to add content to the file '$Path'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Wait-NxtRegistryAndProcessCondition
function Wait-NxtRegistryAndProcessCondition {
	<#
	.SYNOPSIS
		Runs tests against process and/or registry key collections during a setup action of installation/uninstallation.
		Integrated to Install-NxtApplication and Uninstall-Nxtapplication.
	.DESCRIPTION
		Runs tests against process and/or registry key collections during a setup action of installation/uninstallation.
		Integrated to Install-NxtApplication, Uninstall-Nxtapplication.
	.PARAMETER TotalSecondsToWaitFor
		Timeout in seconds the function waits and checks for the condition to occur.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER ProcessOperator
		Operator to define process condition requirements.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER ProcessesToWaitFor
		An array of process conditions to check for.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegKeyOperator
		Operator to define regkey condition requirements.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegkeyListToWaitFor
		An array of regkey conditions to check for.
		Defaults to the corresponding value from the PackageConfig object.
	.OUTPUTS
		System.Boolean.
	.EXAMPLE
		Wait-NxtRegistryAndProcessCondition
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[ValidateRange(1, 3600)]
		[int]
		$TotalSecondsToWaitFor = $global:packageConfig.TestConditionsPreSetupSuccessCheck.$Deploymenttype.TotalSecondsToWaitFor,
		[Parameter(Mandatory = $false)]
		[ValidateSet("And", "Or")]
		[string]
		$ProcessOperator = $global:packageConfig.TestConditionsPreSetupSuccessCheck.$Deploymenttype.ProcessOperator,
		[Parameter(Mandatory = $false)]
		[array]
		$ProcessesToWaitFor = $global:packageConfig.TestConditionsPreSetupSuccessCheck.$Deploymenttype.ProcessesToWaitFor,
		[Parameter(Mandatory = $false)]
		[ValidateSet("And", "Or")]
		[string]
		$RegKeyOperator = $global:packageConfig.TestConditionsPreSetupSuccessCheck.$Deploymenttype.RegKeyOperator,
		[Parameter(Mandatory = $false)]
		[array]
		$RegkeysToWaitFor = $global:packageConfig.TestConditionsPreSetupSuccessCheck.$Deploymenttype.RegkeysToWaitFor
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		## To break the array references to the parent object we have to create new(copied) objects from the provided array.
		[array]$ProcessesToWaitFor = $ProcessesToWaitFor | Select-Object *, @{n = "success"; e = { $false } }
		[array]$RegkeysToWaitFor = $RegkeysToWaitFor | Select-Object *, @{n = "success"; e = { $false } }
	}
	Process {
		# wait for Processes
		[System.Diagnostics.Stopwatch]$stopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
		$stopWatch.Start()
		[bool]$firstRun = $true
		if ($ProcessesToWaitFor.count -eq 0) {
			[bool]$processesFinished = $true
		}
		else {
			[bool]$processesFinished = $false
		}
		if ($RegkeysToWaitFor.count -eq 0) {
			[bool]$regKeysFinished = $true
		}
		else {
			[bool]$regKeysFinished = $false
		}
		
		while (
			$stopWatch.Elapsed.TotalSeconds -lt $TotalSecondsToWaitFor -and 
			!($processesFinished -and $regKeysFinished)
		) {
			if (!$firstRun) {
				Start-Sleep 5
			}
			## Check Process Conditions
			foreach ($processToWaitFor in ($ProcessesToWaitFor | Where-Object success -ne $true)) {
				if ($true -eq $processToWaitFor.ShouldExist) {
					$processToWaitFor.success = Watch-NxtProcess -ProcessName $processToWaitFor.Name -Timeout 0
					Write-Log -Message "Check if Process `"$($processToWaitFor.Name)`" exists: $($processToWaitFor.success)" -Severity 1 -Source ${cmdletName}
				}
				else {
					$processToWaitFor.success = Watch-NxtProcessIsStopped -ProcessName $processToWaitFor.Name -Timeout 0
					Write-Log -Message "Check if Process `"$($processToWaitFor.Name)`" not exists: $($processToWaitFor.success)" -Severity 1 -Source ${cmdletName}
				}
			}
			if ($ProcessOperator -eq "Or") {
				[bool]$processesFinished = ($ProcessesToWaitFor | Select-Object -ExpandProperty success) -contains $true
			}
			elseif ($ProcessOperator -eq "And") {
				[bool]$processesFinished = ($ProcessesToWaitFor | Select-Object -ExpandProperty success) -notcontains $false
			}
			## Check Regkey Conditions
			foreach ($regkeyToWaitFor in ($RegkeysToWaitFor | Where-Object success -ne $true)) {
				if (
					[WildcardPattern]::ContainsWildcardCharacters($regkeyToWaitFor.KeyPath) -or
					[WildcardPattern]::ContainsWildcardCharacters($regkeyToWaitFor.ValueName)
				) {
					Write-Log -Message "KeyPath `"$($regkeyToWaitFor.KeyPath)`" or ValueName `"$($regkeyToWaitFor.ValueName)`" contains wildcard pattern, please check the config file." -Severity 3 -Source ${cmdletName}
					throw "KeyPath `"$($regkeyToWaitFor.KeyPath)`" or ValueName `"$($regkeyToWaitFor.ValueName)`" contains wildcard pattern, please check the config file."
				}
				if (![string]::IsNullOrEmpty($regkeyToWaitFor.KeyPath)) {
					switch ($regkeyToWaitFor) {
						{
							## test pathExists
							([string]::IsNullOrEmpty($_.ValueName)) -and
							($null -eq $_.ValueData ) -and
							($true -eq $_.ShouldExist)
						} {
							Write-Log -Message "Check if KeyPath exists: `"$($regkeyToWaitFor.KeyPath)`"" -Severity 1 -Source ${cmdletName}
							$regkeyToWaitFor.success = Watch-NxtRegistryKey -RegistryKey $regkeyToWaitFor.KeyPath -Timeout 0
						}
						{
							## test pathNotExists
							([string]::IsNullOrEmpty($_.ValueName)) -and
							($null -eq $_.ValueData ) -and
							($false -eq $_.ShouldExist)
						} {
							Write-Log -Message "Check if KeyPath not exists: `"$($regkeyToWaitFor.KeyPath)`"" -Severity 1 -Source ${cmdletName}
							$regkeyToWaitFor.success = Watch-NxtRegistryKeyIsRemoved -RegistryKey $regkeyToWaitFor.KeyPath -Timeout 0
						}
						{
							## test valueExists
							(![string]::IsNullOrEmpty($_.ValueName)) -and
							($null -eq $_.ValueData ) -and
							($true -eq $_.ShouldExist)
						} {
							Write-Log -Message "Check if value exists: `"$($regkeyToWaitFor.KeyPath)`"" -Severity 1 -Source ${cmdletName}
							## Check if Value exists
							if ($null -ne (Get-RegistryKey -Key $regkeyToWaitFor.KeyPath -ReturnEmptyKeyIfExists -Value $regkeyToWaitFor.ValueName)) {
								$regkeyToWaitFor.success = $true
							}
						}
						{
							## test valueNotExists
							(![string]::IsNullOrEmpty($_.ValueName)) -and
							($null -eq $_.ValueData ) -and
							($false -eq $_.ShouldExist)
						} {
							Write-Log -Message "Check if value `"$($regkeyToWaitFor.ValueName)`" not exists in: `"$($regkeyToWaitFor.KeyPath)`"" -Severity 1 -Source ${cmdletName}
							## Check if Value not exists
							if ($null -eq (Get-RegistryKey -Key $regkeyToWaitFor.KeyPath -ReturnEmptyKeyIfExists -Value $regkeyToWaitFor.ValueName)) {
								$regkeyToWaitFor.success = $true
							}
						}
						{
							## valueEquals
						(![string]::IsNullOrEmpty($_.ValueName)) -and
						(![string]::IsNullOrEmpty($_.ValueData) ) -and
						($true -eq $_.ShouldExist)
						} {
								Write-Log -Message "Check if value `"$($regkeyToWaitFor.ValueName)`" is equal to `"$($regkeyToWaitFor.ValueData)`" in: `"$($regkeyToWaitFor.KeyPath)`"" -Severity 1 -Source ${cmdletName}
								## Check if Value is equal
								if ( $regkeyToWaitFor.ValueData -eq (Get-RegistryKey -Key $regkeyToWaitFor.KeyPath -ReturnEmptyKeyIfExists -Value $regkeyToWaitFor.ValueName)) {
									$regkeyToWaitFor.success = $true
								}
						}
						{
								## valueNotEquals
							(![string]::IsNullOrEmpty($_.ValueName)) -and
							(![string]::IsNullOrEmpty($_.ValueData) ) -and
							($false -eq $_.ShouldExist)
						} {
								Write-Log -Message "Check if value `"$($regkeyToWaitFor.ValueName)`" is not equal to `"$($regkeyToWaitFor.ValueData)`" in: `"$($regkeyToWaitFor.KeyPath)`"" -Severity 1 -Source ${cmdletName}
								## Check if Value is not equal
								if ( $regkeyToWaitFor.ValueData -ne (Get-RegistryKey -Key $regkeyToWaitFor.KeyPath -ReturnEmptyKeyIfExists -Value $regkeyToWaitFor.ValueName)) {
									$regkeyToWaitFor.success = $true
								}
						}
							default {
							Write-Log -Message "Could not check for values in `"$($regkeyToWaitFor.RegKey)`", please check the config file." -Severity 3 -Source ${cmdletName}
							throw "Could not check for values in `"$($regkeyToWaitFor.RegKey)`", please check the config file."
						}
					}
				}
				else {
					Write-Log -Message "A RegKey is required, please check the config file." -Severity 3 -Source ${cmdletName}
					throw "A RegKey is required, please check the config file."
				}
			}
			if ($RegkeyOperator -eq "Or") {
				[bool]$regkeysFinished = ($RegkeysToWaitFor | Select-Object -ExpandProperty success) -contains $true
			}
			elseif ($RegkeyOperator -eq "And") {
				[bool]$regkeysFinished = ($RegkeysToWaitFor | Select-Object -ExpandProperty success) -notcontains $false
			}
			[bool]$firstRun = $false
		}
		if ($processesFinished -and $regKeysFinished) {
			Write-Output $true
		}
		else {
			Write-Output $false
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Watch-NxtFile
function Watch-NxtFile {
	<#
	.DESCRIPTION
		Tests if a file exists in a given time.
		Automatically resolves cmd environment variables.
	.PARAMETER FileName
		Name of the file to watch
	.PARAMETER Timeout
		Timeout in seconds the function waits for the file to appear
	.OUTPUTS
		System.Boolean.
	.EXAMPLE
		Watch-NxtFile -FileName "C:\Temp\Sources\Installer.exe"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]$FileName,
		[Parameter()]
		[int]
		$Timeout = 60
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[int]$waited = 0
			while ($waited -lt $Timeout) {
				[bool]$result = Test-Path -Path "$([System.Environment]::ExpandEnvironmentVariables($FileName))"
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
#region Function Watch-NxtFileIsRemoved
function Watch-NxtFileIsRemoved {
	<#
	.DESCRIPTION
		Tests if a file disappears in a given time.
		Automatically resolves cmd environment variables.
	.PARAMETER FileName
		Name of the file to watch.
	.PARAMETER Timeout
		Timeout in seconds the function waits for the file the disappear.
	.OUTPUTS
		System.Boolean.
	.EXAMPLE
		Watch-NxtFileIsRemoved -FileName "C:\Temp\Sources\Installer.exe"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$FileName,
		[Parameter(Mandatory = $false)]
		[int]
		$Timeout = 60
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[int]$waited = 0
			while ($waited -lt $Timeout) {
				[bool]$result = Test-Path -Path "$([System.Environment]::ExpandEnvironmentVariables($FileName))"
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
#region Function Watch-NxtProcess
function Watch-NxtProcess {
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
		System.Boolean.
	.EXAMPLE
		Watch-NxtProcess -ProcessName "Notepad.exe"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$ProcessName,
		[Parameter(Mandatory = $false)]
		[int]
		$Timeout = 60,
		[switch]
		$IsWql = $false
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[int]$waited = 0
			[bool]$result = $false
			while ($waited -le $Timeout) {
				if ($waited -gt 0) {
					Start-Sleep -Seconds 1
				}
				$waited += 1
				if ($IsWql) {
					[bool]$result = Test-NxtProcessExists -ProcessName $ProcessName -IsWql
				}
				else {
					[bool]$result = Test-NxtProcessExists -ProcessName $ProcessName
				}
				
				if ($result) {
					Write-Output $true
					return
				}
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
#region Function Watch-NxtProcessIsStopped
function Watch-NxtProcessIsStopped {
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
		System.Boolean.
	.EXAMPLE
		Watch-NxtProcessIsStopped -ProcessName "Notepad.exe"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$ProcessName,
		[Parameter(Mandatory = $false)]
		[int]
		$Timeout = 60,
		[switch]
		$IsWql = $false
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[int]$waited = 0
			[bool]$result = $false
			while ($waited -le $Timeout) {
				if ($waited -gt 0) {
					Start-Sleep -Seconds 1
				}
				$waited += 1
				if ($IsWql) {
					[bool]$result = Test-NxtProcessExists -ProcessName $ProcessName -IsWql
				}
				else {
					[bool]$result = Test-NxtProcessExists -ProcessName $ProcessName
				}
				
				if ($false -eq $result) {
					Write-Output $true
					return
				}
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
#region Function Watch-NxtRegistryKey
function Watch-NxtRegistryKey {
	<#
	.DESCRIPTION
		Tests if a registry key exists in a given time.
	.PARAMETER RegistryKey
		Name of the registry key to watch.
	.PARAMETER Timeout
		Timeout in seconds that the function waits for the key.
		Defaults to 60.
	.OUTPUTS
		System.Boolean.
	.EXAMPLE
		Watch-NxtRegistryKey -RegistryKey "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]$RegistryKey,
		[Parameter()]
		[int]
		$Timeout = 60
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[int]$waited = 0
			while ($waited -le $Timeout) {
				if ($waited -gt 0) {
					Start-Sleep -Seconds 1
				}
				$waited += 1
				[string]$key = Get-RegistryKey -Key $RegistryKey -ReturnEmptyKeyIfExists
				if ($null -ne $key) {
					Write-Output $true
					return
				}
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
#region Function Watch-NxtRegistryKeyIsRemoved
function Watch-NxtRegistryKeyIsRemoved {
	<#
	.DESCRIPTION
		Tests if a registry key disappears in a given time.
	.PARAMETER RegistryKey
		Name of the registry key to watch.
	.PARAMETER Timeout
		Timeout in seconds the function waits for the key the disappear.
	.OUTPUTS
		System.Boolean.
	.EXAMPLE
		Watch-NxtRegistryKeyIsRemoved -RegistryKey "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]$RegistryKey,
		[Parameter()]
		[int]
		$Timeout = 60
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[int]$waited = 0
			while ($waited -le $Timeout) {
				if ($waited -gt 0) {
					Start-Sleep -Seconds 1
				}
				$waited += 1
				[string]$key = Get-RegistryKey -Key $RegistryKey -ReturnEmptyKeyIfExists
				if ($null -eq $key) {
					Write-Output $true
					return
				}
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
#region Function Write-NxtSingleXmlNode
function Write-NxtSingleXmlNode {
	<#
	.DESCRIPTION
		Writes single node to xml file.
	.PARAMETER XmlFilePath
		Path to the xml file.
	.PARAMETER SingleNodeName
		Node path. (https://www.w3schools.com/xml/xpath_syntax.asp).
	.PARAMETER Value
		Node value.
	.EXAMPLE
		Write-NxtSingleXmlNode -XmlFilePath "C:\Test\setup.xml" -SingleNodeName "//UserId" -Value "müller"
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$XmlFilePath,
		[Parameter(Mandatory = $true)]
		[string]
		$SingleNodeName,
		[Parameter(Mandatory = $true)]
		[string]
		$Value
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[System.Xml.XmlDocument]$xmlDoc = New-Object System.Xml.XmlDocument
			$xmlDoc.Load($XmlFilePath)
			[string]$xmlDoc.DocumentElement.SelectSingleNode($SingleNodeName).InnerText = $Value
			$xmlDoc.Save($XmlFilePath)
			Write-Log -Message "Write value '$Value' to single node '$SingleNodeName' in xml file '$XmlFilePath'." -Source ${cmdletName}
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
#region Function Write-NxtXmlNode
function Write-NxtXmlNode {
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
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$XmlFilePath,
		[Parameter(Mandatory = $true)]
		[PSADTNXT.XmlNodeModel]
		$Model
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[System.Xml.XmlDocument]$xmlDoc = New-Object System.Xml.XmlDocument
			$xmlDoc.Load($XmlFilePath)

			[scriptblock]$createXmlNode = { Param ([System.Xml.XmlDocument]$doc, [PSADTNXT.XmlNodeModel]$child) 
				[System.Xml.XmlNode]$xmlNode = $doc.CreateNode("element", $child.Name, "")

				for ([int]$i = 0; $i -lt $child.Attributes.count; $i++) {
					[System.Collections.Generic.KeyValuePair[string, string]]$attribute = [System.Linq.Enumerable]::ElementAt($child.Attributes, $i)
					[System.Xml.XmlAttribute]$xmlAttribute = $doc.CreateAttribute($attribute.Key, "http://www.w3.org/1999/XSL/Transform")
					[string]$xmlAttribute.Value = $attribute.Value
					[void]$xmlNode.Attributes.Append($xmlAttribute)
				}
			
				if ($false -eq [string]::IsNullOrEmpty($child.Value)) {
					[string]$xmlNode.InnerText = $child.Value
				}
				elseif ($null -ne $child.Child) {
					[System.Xml.XmlLinkedNode]$node = &$createXmlNode -Doc $doc -Child ($child.Child)
					[void]$xmlNode.AppendChild($node)
				}

				Write-Log -Message "Write a new node in xml file '$XmlFilePath'." -Source ${cmdletName}
				return $xmlNode
			}
			
			[System.Xml.XmlLinkedNode]$newNode = &$createXmlNode -Doc $xmlDoc -Child $Model
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
##*===============================================
##* END FUNCTION LISTINGS
##*===============================================

##*===============================================
##* SCRIPT BODY
##*===============================================

if ($scriptParentPath) {
	Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] dot-source invoked by [$(((Get-Variable -Name MyInvocation).Value).ScriptName)]" -Source $appDeployToolkitExtName
}
else {
	Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] invoked directly" -Source $appDeployToolkitExtName
}

##*===============================================
##* END SCRIPT BODY
##*===============================================
