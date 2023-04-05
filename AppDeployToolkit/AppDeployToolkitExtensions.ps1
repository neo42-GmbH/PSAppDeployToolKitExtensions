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
			if (![string]::IsNullOrEmpty($intEncoding)) {
				[string]$contentParams['Encoding'] = $intEncoding 
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Compare-NxtVersion "1.7" "1.7.2"
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
	.PARAMETER PackageFamilyGUID
		Specifies the Registry Key Name used for the Packages Wrapper Uninstall entry
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
		$PackageFamilyGUID = $global:PackageConfig.PackageFamilyGUID,
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
		[string]$cmdletName = $MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Header
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
				Set-RegistryKey -Key "HKLM\Software$wowEntry\Microsoft\Windows\CurrentVersion\Uninstall\$($installedAppResults.UninstallSubkey)" -Name "SystemComponent" -Type "Dword" -Value "1"
			}
		}
		if ($true -eq $UserPartOnInstallation) {
			## Userpart-Installation: Copy all needed files to "...\SupportFiles\neo42-Userpart\" and add more needed tasks per user commands to the CustomInstallUserPart*-functions inside of main script.
			Set-ActiveSetup -PurgeActiveSetupKey -Key "$PackageFamilyGUID.uninstall"
			Copy-File -Path "$dirSupportFiles\neo42-Userpart\*" -Destination "$App\neo42-Userpart\SupportFiles" -Recurse
			Copy-File -Path "$scriptRoot\$($xmlConfigFile.GetElementsByTagName('BannerIcon_Options').Icon_Filename)" -Destination "$App\neo42-Userpart\"
			Copy-item -Path "$scriptDirectory\*" -Exclude "Files", "SupportFiles" -Destination "$App\neo42-Userpart\" -Recurse -Force -ErrorAction Continue
			Write-NxtSingleXmlNode -XmlFilePath "$App\neo42-Userpart\$(Split-Path "$scriptRoot" -Leaf)\$(Split-Path "$appDeployConfigFile" -Leaf)" -SingleNodeName "//Toolkit_RequireAdmin" -Value "False"
			Write-NxtSingleXmlNode -XmlFilePath "$App\neo42-Userpart\$(Split-Path "$scriptRoot" -Leaf)\$(Split-Path "$appDeployConfigFile" -Leaf)" -SingleNodeName "//ShowBalloonNotifications" -Value "False"
			Set-ActiveSetup -StubExePath "$global:System\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Bypass -NoProfile -File ""$App\neo42-Userpart\Deploy-Application.ps1"" TriggerInstallUserpart" -Version $UserPartRevision -Key "$PackageFamilyGUID"
		}
		foreach ($oldAppFolder in $((Get-ChildItem (get-item $App).Parent.FullName | Where-Object Name -ne (get-item $App).Name).FullName)) {
			Copy-File -Path "$scriptRoot\Clean-Neo42AppFolder.ps1" -Destination "$oldAppFolder\"
			Start-Sleep -Seconds 1
			Execute-Process -Path powershell.exe -Parameters "-File `"$oldAppFolder\Clean-Neo42AppFolder.ps1`"" -NoWait
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
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$App = $global:PackageConfig.App,
		[Parameter(Mandatory = $false)]
		[string]
		$PackageFamilyGUID = $global:PackageConfig.PackageFamilyGUID,
		[Parameter(Mandatory = $false)]
		[bool]
		$UserPartOnUninstallation = $global:PackageConfig.UserPartOnUninstallation,
		[Parameter(Mandatory = $false)]
		[string]
		$UserPartRevision = $global:PackageConfig.UserPartRevision
	)
	Begin {
		[string]$cmdletName = $MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Header
	}
	Process {
		Remove-NxtDesktopShortcuts
		Set-ActiveSetup -PurgeActiveSetupKey -Key "$PackageFamilyGUID"
		if ($true -eq $UserPartOnUninstallation) {
			## Userpart-Uninstallation: Copy all needed files to "...\SupportFiles\neo42-Userpart\" and add more needed tasks per user commands to the CustomUninstallUserPart*-functions inside of main script.
			Copy-File -Path "$dirSupportFiles\neo42-Userpart\*" -Destination "$App\neo42-Userpart\SupportFiles" -Recurse
			Copy-File -Path "$scriptRoot\$($xmlConfigFile.GetElementsByTagName('BannerIcon_Options').Icon_Filename)" -Destination "$App\neo42-Userpart\"
			Copy-item -Path "$scriptDirectory\*" -Exclude "Files", "SupportFiles" -Destination "$App\neo42-Userpart\" -Recurse -Force -ErrorAction Continue
			Write-NxtSingleXmlNode -XmlFilePath "$App\neo42-Userpart\$(Split-Path "$scriptRoot" -Leaf)\$(Split-Path "$appDeployConfigFile" -Leaf)" -SingleNodeName "//Toolkit_RequireAdmin" -Value "False"
			Write-NxtSingleXmlNode -XmlFilePath "$App\neo42-Userpart\$(Split-Path "$scriptRoot" -Leaf)\$(Split-Path "$appDeployConfigFile" -Leaf)" -SingleNodeName "//ShowBalloonNotifications" -Value "False"
			Set-ActiveSetup -StubExePath "$global:System\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Bypass -NoProfile -File `"$App\neo42-Userpart\Deploy-Application.ps1`" TriggerUninstallUserpart" -Version $UserPartRevision -Key "$PackageFamilyGUID.uninstall"
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Can be found under "HKLM\SOFTWARE\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\".
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
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
				if (![System.IO.File]::Exists($bitRockInstallerSetupPath) -and ($true -eq (Get-Item "$configNxtBitRockInstallerUninsBackupPath\$bitRockInstallerUninstallKey\$uninsFileName"))) {
					Write-Log -Message "Uninstall file not found. Restoring it from backup..." -Source ${CmdletName}
					Copy-File -Path "$configNxtBitRockInstallerUninsBackupPath\$bitRockInstallerUninstallKey\unins*.*" -Destination "$uninsFolder\"	
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
			## Wait until all uninstallation processes terminated
			Write-Log -Message "Wait while uninstallation process is still running..." -Source ${CmdletName}
			Start-Sleep -Seconds 1
			Watch-NxtProcessIsStopped -ProcessName "_Uninstall*" -Timeout "500"
			Start-Sleep -Seconds 1
			Watch-NxtProcessIsStopped -ProcessName "_Uninstall*" -Timeout "500"
			Start-Sleep -Seconds 1
			Watch-NxtProcessIsStopped -ProcessName "_Uninstall*" -Timeout "500"
			Start-Sleep -Seconds 1
			Watch-NxtProcessIsStopped -ProcessName "_Uninstall*" -Timeout "500"
			Write-Log -Message "Uninstallation process finished." -Source ${CmdletName}
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
				if ($true -eq (Get-Item "$bitRockInstallerUninstallPath")) {
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
		Can be found under "HKLM\SOFTWARE\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\".
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
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
				if (![System.IO.File]::Exists($innoSetupPath) -and ($true -eq (Get-Item "$configNxtInnoSetupUninsBackupPath\$innoUninstallKey\unins[0-9][0-9][0-9].exe"))) {
					Write-Log -Message "Uninstall file not found. Restoring it from backup..." -Source ${CmdletName}
					Remove-File -Path "$uninsFolder\unins*.*"
					Copy-File -Path "$configNxtInnoSetupUninsBackupPath\$innoUninstallKey\unins[0-9][0-9][0-9].*" -Destination "$uninsFolder\"	
				}

				## If any "$uninsFolder\unins[0-9][0-9][0-9].exe" exists, use the one with the highest number
				if ($true -eq (Get-Item "$uninsFolder\unins[0-9][0-9][0-9].exe")) {
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
				if ($true -eq (Get-Item "$uninsfolder\unins[0-9][0-9][0-9].exe")) {
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
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Can be found under "HKLM\SOFTWARE\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\".
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
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
				if (![System.IO.File]::Exists($nullsoftSetupPath) -and ($true -eq (Get-Item "$configNxtNullsoftUninsBackupPath\$nullsoftUninstallKey\$uninsFileName"))) {
					Write-Log -Message "Uninstall file not found. Restoring it from backup..." -Source ${CmdletName}
					Copy-File -Path "$configNxtNullsoftUninsBackupPath\$nullsoftUninstallKey\$uninsFileName" -Destination "$uninsFolder\"	
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
			## Wait until all uninstallation processes terminated
			Write-Log -Message "Wait while one of the possible uninstallation processes is still running..." -Source ${CmdletName}
			Watch-NxtProcessIsStopped -ProcessName "AU_.exe" -Timeout "500"
			Watch-NxtProcessIsStopped -ProcessName "Un_A.exe" -Timeout "500"
			Write-Log -Message "All uninstallation processes finished." -Source ${CmdletName}
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
				if ($true -eq (Get-Item "$nullsoftUninstallPath")) {
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
		Deletes the package machine key under "HKLM\Software\", which defaults to the PackageFamilyGUID under the RegPackagesKey value from the neo42PackageConfig.json.
		Deletes the package uninstallkey under "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\", which defaults to the PackageFamilyGUID value from the neo42PackageConfig.json.
		Writes an "error" message to the package log and an error entry to the registry, which defaults to "Uninstall of $installTitle requires a reboot before proceeding with the installation. AbortReboot!"
		Exits the script with a return code to trigger a system reboot, which defaults to "3010".
		Also deletes corresponding Empirum registry keys, if the pacakge was deployed with Matrix42 Empirum.
	.PARAMETER PackageMachineKey
		Path to the the package machine key under "HKLM\Software\".
		Defaults to "$($global:PackageConfig.RegPackagesKey)\$($global:PackageConfig.PackageFamilyGUID)".
	.PARAMETER PackageUninstallKey
		Name of the the package uninstallkey under "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\".
		Defaults to the PackageFamilyGUID value from the PackageConfig object.
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
		Path to the Empirum package machine key under "HKLM\Software\".
		Defaults to "$($global:PackageConfig.RegPackagesKey)\$AppVendor\$AppName\$appVersion".
	.PARAMETER EmpirumUninstallKey
		Name of the the Empirum package uninstallkey under "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\".
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
		$PackageMachineKey = "$($global:PackageConfig.RegPackagesKey)\$($global:PackageConfig.PackageFamilyGUID)",
		[Parameter(Mandatory = $false)]
		[string]
		$PackageUninstallKey = $global:PackageConfig.PackageFamilyGUID,
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
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Write-Log -Message "Initiating AbortReboot..." -Source ${CmdletName}
		try {
			Remove-RegistryKey -Key "HKLM\Software\$PackageMachineKey" -Recurse
			Remove-RegistryKey -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageUninstallKey" -Recurse
			if (Test-Path -Path "HKLM:Software\$EmpirumMachineKey") {
				Remove-RegistryKey -Key "HKLM\Software\$EmpirumMachineKey" -Recurse
			}
			if (Test-Path -Path "HKLM:Software\Microsoft\Windows\CurrentVersion\Uninstall\$EmpirumUninstallKey") {
				Remove-RegistryKey -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$EmpirumUninstallKey" -Recurse
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
	.PARAMETER RegPackagesKey
		Defines the Name of the Registry Key keeping track of all Packages delivered by this Packaging Framework.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PackageFamilyGUID
		Specifies the Registry Key Name used for the Packages Wrapper Uninstall entry.
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
		$RegPackagesKey = $global:PackageConfig.RegPackagesKey,
		[Parameter(Mandatory = $false)]
		[string]
		$PackageFamilyGUID = $global:PackageConfig.PackageFamilyGUID,
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
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			Write-Log -Message $ErrorMessage -Severity 3 -Source ${CmdletName}
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'AppPath' -Value $App
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'DebugLogFile' -Value $DebugLogFile
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'DeploymentStartTime' -Value $DeploymentTimestamp
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'DeveloperName' -Value $AppVendor
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'ErrorTimeStamp' -Value $(Get-Date -format "yyyy-MM-dd_HH-mm-ss")
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'ErrorMessage' -Value $ErrorMessage
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'ErrorMessagePSADT' -Value $ErrorMessagePSADT
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'LastExitCode' -Value $MainExitCode
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'PackageArchitecture' -Value $AppArch
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'PackageStatus' -Value $PackageStatus
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'ProductName' -Value $AppName
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'Revision' -Value $AppRevision
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'SrcPath' -Value $ScriptParentPath
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'StartupProcessor_Architecture' -Value $EnvArchitecture
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'StartupProcessOwner' -Value $EnvUserDomain\$EnvUserName
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'StartupProcessOwnerSID' -Value $ProcessNTAccountSID
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'UninstallOld' -Type 'Dword' -Value $UninstallOld
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'UserPartOnInstallation' -Value $UserPartOnInstallation -Type 'DWord'
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'UserPartOnUninstallation' -Value $UserPartOnUnInstallation -Type 'DWord'
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error") -Name 'Version' -Value $AppVersion
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Can be found under "HKLM\SOFTWARE\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\".
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
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		[PSObject]$global:PackageConfig = Get-Content $Path | Out-String | ConvertFrom-Json
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
#region Function Get-NxtRegisterOnly
function Get-NxtRegisterOnly {
	<#
	.SYNOPSIS
		Detects if the target application is already installed
	.DESCRIPTION
		Uses registry values to detect the application in target or higher versions
	.PARAMETER PackageFamilyGUID
		Specifies the Registry Key Name used for the Packages Wrapper Uninstall entry.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER SoftMigration
		Specifies if a Software should be registered only if it already exists through a different installation.
		Defaults to the corresponding value from the Setup.cfg.
	.PARAMETER DisplayVersion
		Specifies the DisplayVersion of the Software Package.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKey
		Specifies the original UninstallKey set by the Installer in this Package.
		Defaults to the corresponding value from the PackageConfig object.
	.Parameter DetectedDisplayVersion
		Specifies the Detected Displayversion of an installed predecessor App Version.
		Defaults to the corresponding Variable set in the App Global Variables.
	.EXAMPLE
		Get-NxtRegisterOnly
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$PackageFamilyGUID = $global:PackageConfig.PackageFamilyGUID,
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
		$DetectedDisplayVersion = $global:DetectedDisplayVersion
	
	)
	if ($true -eq $SoftMigration) {
		if ([string]::IsNullOrEmpty($DisplayVersion)) {
			Write-Log -Message 'DisplayVersion is $null or empty. SoftMigration not possible.'
			Write-Output $false
			return
		}
		if ([string]::IsNullOrEmpty($DetectedDisplayVersion)) {
			Write-Log -Message 'DetectedDisplayVersion is $null or empty. SoftMigration not possible.'
			Write-Output $false
			return
		}
		if (
			(Compare-NxtVersion -DetectedVersion $DetectedDisplayVersion -TargetVersion $DisplayVersion) -ne "Update" -and
			-not (Test-RegistryValue -Key HKLM\Software\neoPackages\$PackageFamilyGUID -Value 'ProductName')
		) {
			Write-Log -Message 'Application is already present. Installation is not executed. Only package files are copied and package is registered. Performing SoftMigration ...'
			Write-Output $true
			return
		}
	}
	Write-Output $false
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
#region Function Get-NxtVariablesFromDeploymentSystem
function Get-NxtVariablesFromDeploymentSystem {
	<#
	.SYNOPSIS
		Gets environment variables set by the deployment system
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
		[Parameter(Mandatory = $false)]
		[string]
		$registerPackage = $env:registerPackage,
		[Parameter(Mandatory = $false)]
		[string]
		$uninstallOld = $env:uninstallOld,
		[Parameter(Mandatory = $false)]
		[string]
		$Reboot = $env:Reboot
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Write-Log -Message "Getting environment variables set by the deployment system..." -Source ${cmdletName}
		try {
			if ("false" -eq $registerPackage) {
				[bool]$global:registerPackage = $false 
			} 
			else { 
				[bool]$global:registerPackage = $true
			}
			if ("false" -eq $uninstallOld) {
				[bool]$global:uninstallOld = $false
			}
			if ($null -ne $Reboot) {
				[int]$global:reboot = $Reboot
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
	.PARAMETER PROCESSOR_ARCHITEW6432
		Accepts the string "x86" or "x64".
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
		$PROCESSOR_ARCHITECTURE = $env:PROCESSOR_ARCHITECTURE
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			switch ($PROCESSOR_ARCHITECTURE) {
				"AMD64" { 
					Write-Output 64
				}
				"x86" {
					Write-Output 32
				}
				Default {
					Write-Error "$($PROCESSOR_ARCHITECTURE) could not be translated to CPU bitness 'WindowsBits'"
				}
			}
		}
		catch {
			Write-Log -Message "Failed to translate $($PROCESSOR_ARCHITECTURE) variable. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
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
#region Function Import-NxtIniFile
function Import-NxtIniFile {
	<#
	.SYNOPSIS
		Imports an Ini file into Powershell Object.
	.DESCRIPTION
		Imports an Ini file into Powershell Object.
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
			[hashtable]$ini = @{}
			[string]$section = 'default'
			switch -Regex -File $Path {
				'^\[(.+)\]$' {
					[string]$section = $matches[1]
					if (!$ini.ContainsKey($section)) {
						[hashtable]$ini[$section] = @{}
					}
				}
				'^([^\s]+)\s*=\s*(.+)$' {
					[string]$ini[$section][$matches[1]] = $matches[2]
				}
			}
			Write-Output $ini
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
#region Function Initialize-NxtEnvironment
function Initialize-NxtEnvironment {
	<#
	.DESCRIPTION
		Initializes all neo42 functions and variables.
		Should be called on top of any 'Deploy-Application.ps1'.
		parses the neo42PackageConfig.json
	.PARAMETER ExtensionCsPath
		Provides the Path to the AppDeployToolkitExtensions.cs containing c# to be used in the extension functions
		Defaults to "$scriptRoot\AppDeployToolkitExtensions.cs"
	.PARAMETER SetupCfgPath
		Defines the path to the Setup.cfg to be loaded to the global setupcfg Variable.
		Defaults to the "$global:SetupCfgPath".
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
		$ExtensionCsPath = "$scriptRoot\AppDeployToolkitExtensions.cs",
		[Parameter(Mandatory = $false)]
		[string]
		$SetupCfgPath = "$global:SetupCfgPath"
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		if (-not ([Management.Automation.PSTypeName]'PSADTNXT.Extensions').Type) {
			if (Test-Path -Path $ExtensionCsPath) {
				Add-Type -Path $ExtensionCsPath -IgnoreWarnings -ErrorAction 'Stop'
			}
			else {
				throw "File not found: $ExtensionCsPath"
			}
		}
		Get-NxtPackageConfig
		Set-NxtSetupCfg -Path $SetupCfgPath
		if (0 -ne $(Set-NxtPackageArchitecture)) {
			throw "Error during setting package architecture variables."
		}
		[string]$global:DeploymentTimestamp = Get-Date -format "yyyy-MM-dd_HH-mm-ss"
		Expand-NxtPackageConfig
		Format-NxtPackageSpecificVariables
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
			if (Get-RegistryKey -Key HKLM\Software$wowEntry\Microsoft\Windows\CurrentVersion\Uninstall\$currentKeyName -Value SystemComponent) {
				Remove-RegistryKey -Key HKLM\Software$wowEntry\Microsoft\Windows\CurrentVersion\Uninstall\$currentKeyName -Name 'SystemComponent'
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
		Can be found under "HKLM\SOFTWARE\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\".
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
	.PARAMETER DisplayVersion
		Expected version of installed application from a msi setup.
		Only applies to MSI Installer and is necessary when MSI product code is not independent (i.e. ProductCode depends on OS language).
		Defaults to the corresponding value 'DisplayVersion' from the PackageConfig object.
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
	.PARAMETER PreSuccessCheckProcesListToWaitFor
		An array of process conditions to check for.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PreSuccessCheckRegKeyOperator
		Operator to define regkey condition requirements.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PreSuccessCheckRegkeyListToWaitFor
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
		[string]
		$DisplayVersion = $global:PackageConfig.DisplayVersion,
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		[PSADTNXT.NxtApplicationResult]$installResult = New-Object -TypeName PSADTNXT.NxtApplicationResult
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
			none {
				$installResult.ErrorMessage = "An installation method was NOT set. Skipping a default process execution."
				$installResult.Success = $null
				[int]$logMessageSeverity = 2
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
		## if nothing was to execute herein just finish
		if ($internalInstallerMethod -ne "none") {

			$installResult.ApplicationExitCode = $LastExitCode
			$installResult.MainExitCode = $mainExitCode
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
				$installResult.ErrorMessage =  "Installation RegistryAndProcessCondition of '$appName' failed. ErrorLevel: $($installResult.ApplicationExitCode)"
				$installResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
				$installResult.Success = $false
				[int]$logMessageSeverity = 3
			}
			else {
				if ($false -eq $(Test-NxtAppIsInstalled -UninstallKey "$UninstallKey" -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude)) {
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			[array]$functionParametersToBeRemoved = (
				"ContinueOnError"
			)
			foreach ($functionParameterToBeRemoved in $functionParametersToBeRemoved) {
				$null = $PSBoundParameters.Remove($functionParameterToBeRemoved)
			}
			Write-Log -Message "Move $path to $Destination." -Source ${cmdletName}
			Move-Item @PSBoundParameters -ErrorAction Stop
		}
		catch {
			Write-Log -Message "Failed to move $Path to $Destination. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
			if (-not $ContinueOnError) {
				throw "Failed to move $Path to $Destination`: $($_.Exception.Message)"
			}
		}
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
#region Function Register-NxtPackage
function Register-NxtPackage {
	<#
	.SYNOPSIS
		Copies package files and registers the package in the registry.
	.DESCRIPTION
		Copies the package files to the local store and writes the package's registry keys under "HKLM\Software\$regPackagesKey\$PackageFamilyGUID" and "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageFamilyGUID".
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
	.PARAMETER PackageFamilyGUID
		Specifies the Registry Key Name used for the Packages Wrapper Uninstall entry.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegPackagesKey
		Defines the Name of the Registry Key keeping track of all Packages delivered by this Packaging Framework.
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
		[string]
		$PackageFamilyGUID = $global:PackageConfig.PackageFamilyGUID,
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
		$LastErrorMessage = $global:LastErrorMessage
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Write-Log -Message "Registering package..." -Source ${cmdletName}
		try {
			Copy-File -Path "$scriptRoot" -Destination "$App\neo42-Install\" -Recurse
			Copy-File -Path "$ScriptParentPath\Deploy-Application.ps1" -Destination "$App\neo42-Install\"
			Copy-File -Path "$global:Neo42PackageConfigPath" -Destination "$App\neo42-Install\"
			Copy-File -Path "$ScriptParentPath\Setup.cfg" -Destination "$App\neo42-Install\"
			Copy-File -Path "$scriptRoot\$($xmlConfigFile.GetElementsByTagName('BannerIcon_Options').Icon_Filename)" -Destination "$App\neo42-Userpart\"
	
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'AppPath' -Value $App
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'Date' -Value (Get-Date -format "yyyy-MM-dd HH:mm:ss")
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'DebugLogFile' -Value $ConfigToolkitLogDir\$LogName
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'DeveloperName' -Value $AppVendor
			if (![string]::IsNullOrEmpty($LastErrorMessage)) {
				Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'LastErrorMessage' -Value $LastErrorMessage
			}
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'LastExitCode' -Value $MainExitCode
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'PackageArchitecture' -Value $AppArch
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'PackageStatus' -Value $PackageStatus
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'ProductName' -Value $AppName
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'Revision' -Value $AppRevision
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'SrcPath' -Value $ScriptParentPath
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'StartupProcessor_Architecture' -Value $EnvArchitecture
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'StartupProcessOwner' -Value $EnvUserDomain\$EnvUserName
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'StartupProcessOwnerSID' -Value $ProcessNTAccountSID
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'UninstallOld' -Type 'Dword' -Value $UninstallOld
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'UninstallString' -Value ("""$global:System\WindowsPowerShell\v1.0\powershell.exe"" -ex bypass -WindowStyle hidden -file ""$App\neo42-Install\Deploy-Application.ps1"" uninstall")
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'UserPartOnInstallation' -Value $UserPartOnInstallation -Type 'DWord'
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'UserPartOnUninstallation' -Value $UserPartOnUnInstallation -Type 'DWord'
			if ($true -eq $UserPartOnInstallation) {
				Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'UserPartPath' -Value ('"' + $App + '\neo42-Userpart"')
				Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'UserPartUninstPath' -Value ('"%AppData%\neoPackages\' + $PackageFamilyGUID + '"')
				Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'UserPartRevision' -Value $UserPartRevision
			}
			Set-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID -Name 'Version' -Value $AppVersion

			Set-RegistryKey -Key HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageFamilyGUID -Name 'DisplayIcon' -Value $App\neo42-Install\$(Split-Path "$scriptRoot\$($xmlConfigFile.GetElementsByTagName('BannerIcon_Options').Icon_Filename)" -Leaf)
			Set-RegistryKey -Key HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageFamilyGUID -Name 'DisplayName' -Value $UninstallDisplayName
			Set-RegistryKey -Key HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageFamilyGUID -Name 'DisplayVersion' -Value $AppVersion
			Set-RegistryKey -Key HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageFamilyGUID -Name 'MachineKeyName' -Value $RegPackagesKey\$PackageFamilyGUID
			Set-RegistryKey -Key HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageFamilyGUID -Name 'NoModify' -Type 'Dword' -Value 1
			Set-RegistryKey -Key HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageFamilyGUID -Name 'NoRemove' -Type 'Dword' -Value $HidePackageUninstallButton
			Set-RegistryKey -Key HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageFamilyGUID -Name 'NoRepair' -Type 'Dword' -Value 1
			Set-RegistryKey -Key HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageFamilyGUID -Name 'PackageApplicationDir' -Value $App
			Set-RegistryKey -Key HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageFamilyGUID -Name 'PackageProductName' -Value $AppName
			Set-RegistryKey -Key HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageFamilyGUID -Name 'PackageRevision' -Value $AppRevision
			Set-RegistryKey -Key HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageFamilyGUID -Name 'DisplayVersion' -Value $DisplayVersion
			Set-RegistryKey -Key HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageFamilyGUID -Name 'Publisher' -Value $AppVendor
			Set-RegistryKey -Key HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageFamilyGUID -Name 'SystemComponent' -Type 'Dword' -Value $HidePackageUninstallEntry
			Set-RegistryKey -Key HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageFamilyGUID -Name 'UninstallString' -Type 'ExpandString' -Value ("""$global:System\WindowsPowerShell\v1.0\powershell.exe"" -ex bypass -WindowStyle hidden -file ""$App\neo42-Install\Deploy-Application.ps1"" uninstall")
			Remove-RegistryKey HKLM\Software\$RegPackagesKey\$PackageFamilyGUID$("_Error")
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
#region Function Remove-NxtRegistryKeyForAllUsers
function Remove-NxtRegistryKeyForAllUsers {
	<#
	.DESCRIPTION
		Removes a regkey from all user registries.
	.PARAMETER Path
		Path to the regkey in HKCU.
	.EXAMPLE
		Remove-NxtRegistryKeyForAllUsers -Path "HKCU:Software\TestKey"
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
    param(
        [Parameter(Mandatory=$true)]
		[ValidatePattern("^HKCU:*\\*")]
        [string]
        $Key,
		[Parameter(Mandatory=$false)]
        [switch]
        $Recurse
    )
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process{
		if ($true -eq $Recurse){
			[ScriptBlock]$hKCURegistrySettings = {
				if($true -eq (Test-Path -Path $Key) ){
        			Remove-RegistryKey -Key $Key -SID $UserProfile.SID -ContinueOnError $true -Recurse
				}
    		}
		}else{
			[ScriptBlock]$hKCURegistrySettings = {
				if(Test-Path -Path $Key){
					if((Get-ChildItem -Path $Key).count -eq 0){
        				Remove-RegistryKey -Key $Key -SID $UserProfile.SID -ContinueOnError $true
					}
				}
    		}
		}
    Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $HKCURegistrySettings
	}
    End{
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
#region Function Repair-NxtApplication
function Repair-NxtApplication {
	<#
	.SYNOPSIS
		Defines the required steps to repair an MSI based application.
	.DESCRIPTION
		Is only called in the Main function and should not be modified!
		To customize the script always use the "CustomXXXX" entry points.
	.PARAMETER UninstallKey
		Either the applications uninstallregistrykey or the applications displayname, searched for in the regvalue "Displayname" below all uninstallkeys (e.g. "{XXXXXXXX-XXXX-XXXXXXXX-XXXXXXXXXXXX}" or "an application display name").
		Using a displayname value requires to set the parameter -UninstallKeyIsDisplayName to $true.
		Can be found under "HKLM\SOFTWARE\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\" (basically this matches with the entry 'ProductCode' in property table inside of source msi file, therefore the InstFile is not provided as parameter for this function).
	.PARAMETER UninstallKeyIsDisplayName
		Determines if the value given as UninstallKey should be interpreted as a displayname.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER DisplayVersion
		Expected version of installed application from a msi setup.
		Only applies to MSI Installer and is necessary when MSI product code is not independent (i.e. ProductCode depends on OS language).
		Defaults to the corresponding value 'DisplayVersion' from the PackageConfig object.
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
		$UninstallKey = $global:PackageConfig.UninstallKey,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallKeyIsDisplayName = $global:PackageConfig.UninstallKeyIsDisplayName,
		[Parameter(Mandatory = $false)]
		[string]
		$DisplayVersion = $global:PackageConfig.DisplayVersion,
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
				if (![string]::IsNullOrEmpty($InstPara)) {
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

				if ( (0 -ne $repairResult.ApplicationExitCode) -or ($false -eq $(Test-NxtAppIsInstalled -UninstallKey "$UninstallKey" -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName)) ) {
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
#region Function Set-NxtDetectedDisplayVersion
function Set-NxtDetectedDisplayVersion {
	<#
	.SYNOPSIS
		Sets the value of $global:DetectedDisplayVersion from the display version of an application.
	.DESCRIPTION
		Sets the display version of an application from the registry depending on the name of its uninstallkey or its display name, based on exact values only or with WildCards if specified.
	.PARAMETER UninstallKey
		Name of the uninstall registry key of the application (e.g. "ThisApplication").
		Can be found under "HKLM\SOFTWARE\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\".
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
		Set-NxtDetectedDisplayVersion -UninstallKey "{12345678-A123-45B6-CD7E-12345FG6H78I}"
	.EXAMPLE
		Set-NxtDetectedDisplayVersion -UninstallKey "MyNewApp" -UninstallKeyIsDisplayName $true
	.EXAMPLE
		Set-NxtDetectedDisplayVersion -UninstallKey "SomeApp - Version *" -UninstallKeyIsDisplayName $true -UninstallKeyContainsWildCards $true -DisplayNamesToExclude "SomeApp - Version 1.0","SomeApp - Version 1.1",$global:PackageConfig.UninstallDisplayName
	.EXAMPLE
		Set-NxtDetectedDisplayVersion -UninstallKey "***MySuperSparklingApp***" -UninstallKeyIsDisplayName $true -UninstallKeyContainsWildCards $false
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
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		if ([string]::IsNullOrEmpty($UninstallKey)) {
			Write-Log -Message "Can't detect display version: No uninstallkey or display name defined." -Source ${CmdletName}
		}
		else {
			try {
				$global:DetectedDisplayVersion = $null
				Write-Log -Message "Setting DetectedDisplayVersion value..." -Source ${CmdletName}
				[array]$installedAppResults = Get-NxtInstalledApplication -UninstallKey $UninstallKey -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude
				if ($installedAppResults.Count -eq 0) {
					Write-Log -Message "Found no uninstall key with UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Skipped setting DetectedDisplayVersion." -Severity 2 -Source ${CmdletName}
				}
				elseif ($installedAppResults.Count -gt 1) {
					Write-Log -Message "Found more than one uninstall key with UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Skipped setting DetectedDisplayVersion." -Severity 2 -Source ${CmdletName}
				}
				elseif ([string]::IsNullOrEmpty($installedAppResults.DisplayVersion)) {
					Write-Log -Message "Detected no DisplayVersion for UninstallKey [$UninstallKey] with UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]." -Severity 2 -Source ${CmdletName}
				}
				else {
					[string]$global:DetectedDisplayVersion = $installedAppResults.DisplayVersion
					Write-Log -Message "Detected display version [$global:DetectedDisplayVersion] for UninstallKey [$UninstallKey] with UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]." -Source ${CmdletName}
				}
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
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
				Write-Log -Message "INI file $FilePath does not exist!" -Source ${CmdletName}
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
#region Function Set-NxtSetupCfg
function Set-NxtSetupCfg {
	<#
	.SYNOPSIS
		Set the contents from Setup.cfg to $global:SetupCfg.
	.DESCRIPTION
		Imports a Setup.cfg file in Ini format.
	.PARAMETER Path
		The path to the Setup.cfg file.
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
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Write-Log -Message "Checking for setup.cfg under [$path]..." -Source ${CmdletName}
		if ([System.IO.File]::Exists($Path)) {
			[hashtable]$global:SetupCfg = Import-NxtIniFile -Path $Path -ContinueOnError $ContinueOnError
			Write-Log -Message "Setup.cfg found and successfully parsed into global:setupCfg object." -Source ${CmdletName}
		}
		else {
			Write-Log -Message "No Setup.cfg found. Skipped parsing of setup.cfg." -Severity 2 -Source ${CmdletName}
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
#region Function Show-NxtInstallationWelcome
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
		Defaults to the corresponding value from the Setup.cfg.
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
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[bool]
		$IsInstall,
		[Parameter(Mandatory = $false)]
		[int]
		$DeferDays = $global:SetupCfg.AskKillProcesses.DeferDays,
		[Parameter(Mandatory = $false)]
		[array]
		$AskKillProcessApps = $($global:PackageConfig.AppKillProcesses),
		[Parameter(Mandatory = $false)]
		[string]
		$CloseAppsCountdown = $global:SetupCfg.AskKillProcesses.Timeout,
		[Parameter(Mandatory = $false)]
		[ValidateSet("ABORT", "CONTINUE")]
		[string]
		$ContinueType = $global:SetupCfg.AskKillProcesses.ContinueType,
		[Parameter(Mandatory = $false)]
		[bool]
		$BlockExecution = $($global:PackageConfig.BlockExecution)
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		## To break the array references to the parent object we have to create new(copied) objects from the provided array.
		[array]$AskKillProcessApps = $AskKillProcessApps | Select-Object *
		## override $DeferDays with 0 in Case of Uninstall
		if (!$IsInstall) {
			[int]$DeferDays = 0
		}
		[string]$closeAppsList = $null
		[string]$fileExtension = ".exe"
		if ($AskKillProcessApps.count -ne 0) {
			foreach ( $processAppsItem in $AskKillProcessApps ) {
				if ( "*$fileExtension" -eq "$($processAppsItem.Name)" ) {
					Write-Log -Message "Not supported list entry '*.exe' for 'CloseApps' process collection found, please the check parameter for processes ask to kill in config file!" -Severity 3 -Source ${cmdletName}
					throw "Not supported list entry '*.exe' for 'CloseApps' process collection found, please the check parameter for processes ask to kill in config file!"
				}
				elseif ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($processAppsItem.Name)) {				
					Write-Log -Message "Wildcard in list entry for 'CloseApps' process collection detected, retrieving all matching running processes for '$($processAppsItem.Name)' ..." -Source ${cmdletName}
					[string]$processAppsItem.Name = (($(Get-WmiObject -Query "Select * from Win32_Process Where Name LIKE '$(($processAppsItem.Name).Replace("*","%"))'").name) -replace "\$fileExtension", "") -join ","
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
			[string]$closeAppsList = ($AskKillProcessApps | Where-Object -property 'Name' -ne '').Name -join ","
			if (!([string]::IsNullOrEmpty($closeAppsList))) {
				switch ($ContinueType.ToUppper()) {
					"ABORT" {
						Show-InstallationWelcome -CloseApps $closeAppsList -CloseAppsCountdown $CloseAppsCountdown -PersistPrompt -BlockExecution:$BlockExecution -AllowDeferCloseApps -DeferDays $DeferDays -CheckDiskSpace
					}
					"CONTINUE" {
						Show-InstallationWelcome -CloseApps $closeAppsList -ForceCloseAppsCountdown $CloseAppsCountdown -PersistPrompt -BlockExecution:$BlockExecution -AllowDeferCloseApps -DeferDays $DeferDays -CheckDiskSpace
					}		
				}
				if (($true -eq $BlockExecution) -and ($true -eq (Test-Path -Path "$dirAppDeployTemp\BlockExecution\$(Split-Path "$AppDeployConfigFile" -Leaf)"))) {
					## in case of showing a message for a blocked application by ADT there has to be a valid application icon in copied temporary ADT framework
					Copy-File -Path "$scriptRoot\$($xmlConfigFile.GetElementsByTagName('BannerIcon_Options').Icon_Filename)" -Destination "$dirAppDeployTemp\BlockExecution\AppDeployToolkitLogo.ico"
					Write-NxtSingleXmlNode -XmlFilePath "$dirAppDeployTemp\BlockExecution\$(Split-Path "$AppDeployConfigFile" -Leaf)" -SingleNodeName "//Icon_Filename" -Value "AppDeployToolkitLogo.ico"
				}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
#region Function Test-NxtAppIsInstalled
function Test-NxtAppIsInstalled {
	<#
	.SYNOPSIS
		Detects if the target application is installed.
	.DESCRIPTION
		Uses the registry Uninstall Key to detect if the application is present.
	.PARAMETER UninstallKey
		Name of the uninstall registry key of the application (e.g. "This Application_is1" or "{XXXXXXXX-XXXX-XXXXXXXX-XXXXXXXXXXXX}").
		Can be found under "HKLM\SOFTWARE\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall\".
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
	.PARAMETER DisplayVersion
		Expected version of installed application from a msi setup.
		Only applies to MSI Installer and is necessary when MSI product code is not independent (i.e. ProductCode depends on OS language).
		Defaults to the corresponding value 'DisplayVersion' from the PackageConfig object.
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
		$DeploymentMethod,
		[Parameter(Mandatory = $false)]
		[string]
		$DisplayVersion = $global:PackageConfig.DisplayVersion
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Write-Log -Message "Checking if application is installed..." -Source ${CmdletName}
		[array]$installedAppResults = Get-NxtInstalledApplication -UninstallKey $UninstallKey -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude
		if ($installedAppResults.Count -eq 0) {
			[bool]$approvedResult = $false
			Write-Log -Message "Found no application matching UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Returning [$approvedResult]." -Source ${CmdletName}
		}
		elseif ("MSI" -eq $DeploymentMethod) {
			if ($installedAppResults.Count -gt 1) {
				## This case maybe resolved with a foreach-loop in future.
				[bool]$approvedResult = $false
				Write-Log -Message "Found more than one application matching UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Returning [$approvedResult]." -Severity 3 -Source ${CmdletName}
				throw "Processing multiple found msi installations is not supported yet! Abort."
			}
			else {
				if ([string]::IsNullOrEmpty($DisplayVersion)) {
					## Note: Especially in case of msi uninstallation it may be necessary to run it against all found versions!
					Write-Log -Message "No 'DisplayVersion' provided. Processing msi setup without double check for an expected msi display version!" -Severity 2 -Source ${cmdletName}
					[bool]$approvedResult = $true
				}
				else {
					if ([string]::IsNullOrEmpty($installedAppResults.DisplayVersion)) {
						### Note: By default an empty value 'DisplayVersion' for an installed msi setup may not be possible unless it was manipulated manually.
						Write-Log -Message "Detected 'DisplayVersion' is $null or empty. Wrong installation results may be possible." -Severity 2 -Source ${cmdletName}
						[bool]$approvedResult = $false
						Write-Log -Message "Exact check for an installed msi application not possible! But found application matching UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Returning [$approvedResult]." -Source ${CmdletName}
					}
					else {
						Write-Log -Message "Processing msi setup: double check for expected msi display version [$DisplayVersion]." -Source ${cmdletName}
						switch ($(Compare-NxtVersion -DetectedVersion $installedAppResults.DisplayVersion -TargetVersion $DisplayVersion)) {
							"Equal" { 
								Write-Log -Message "Found the expected display version." -Source ${cmdletName}
								[bool]$approvedResult = $true
								Write-Log -Message "Found one application matching UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Returning [$approvedResult]." -Source ${CmdletName}
							}
							"Update" {
								[string]$returnErrorMessage = "Found a lower target display version than expected."
								if ($DeploymentType -eq "Install") {
									[string]$returnErrorMessage += " This leads to trying to do an msi inplace upgrade ..."
								}
								Write-Log -Message "$returnErrorMessage" -Severity 2 -Source ${cmdletName}
								[bool]$approvedResult = $false
								Write-Log -Message "Found one application matching UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Returning [$approvedResult]." -Source ${CmdletName}
							}
							"Downgrade" {
								[string]$returnErrorMessage = "Found a higher target display version than expected."
								if ($DeploymentType -eq "Install") {
									[string]$returnErrorMessage += " This leads to trying to do a msi downgrade (if supported) ..."
								}
								Write-Log -Message "$returnErrorMessage" -Severity 2 -Source ${cmdletName}
								[bool]$approvedResult = $false
								Write-Log -Message "Found one application matching UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Returning [$approvedResult]." -Source ${CmdletName}
							}
							default {
								Write-Log -Message "Unsupported compare result at this point: '$_'" -Severity 3 -Source ${cmdletName}
								[bool]$approvedResult = $false
							}
						}
					}
				}
			}
		}
		elseif ($installedAppResults.Count -gt 1) {
			## for all other types of installer (more than one search result)
			[bool]$approvedResult = $true
			Write-Log -Message "Found more than one application matching UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Returning [$approvedResult]." -Severity 2 -Source ${CmdletName}
		}
		else {
			## for all other types of installer (just 1 search result)
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
	.PARAMETER DisplayVersion
		Expected version of installed application from a msi setup.
		Only applies to MSI Installer and is necessary when MSI product code is not independent (i.e. ProductCode depends on OS language).
		Defaults to the corresponding value 'DisplayVersion' from the PackageConfig object.
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
	.PARAMETER UninstallKeysToHide
		Specifies a list of UninstallKeys set by the Installer(s) in this Package, which the function will hide from the user (e.g. under "Apps" and "Programs and Features").
		Defaults to the corresponding values from the PackageConfig object.
	.PARAMETER Wow6432Node
		Switches between 32/64 Bit Registry Keys.
		Defaults to the Variable $global:Wow6432Node populated by Set-NxtPackageArchitecture.
	.PARAMETER PreSuccessCheckTotalSecondsToWaitFor
		Timeout in seconds the function waits and checks for the condition to occur.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PreSuccessCheckProcessOperator
		Operator to define process condition requirements.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PreSuccessCheckProcesListToWaitFor
		An array of process conditions to check for.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PreSuccessCheckRegKeyOperator
		Operator to define regkey condition requirements.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PreSuccessCheckRegkeyListToWaitFor
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
		$DisplayVersion = $global:PackageConfig.DisplayVersion,
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
		[PSCustomObject]
		$UninstallKeysToHide = $global:PackageConfig.UninstallKeysToHide,
		[Parameter(Mandatory = $false)]
		[string]
		$Wow6432Node = $global:Wow6432Node,
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		[PSADTNXT.NxtApplicationResult]$uninstallResult = New-Object -TypeName PSADTNXT.NxtApplicationResult
		$uninstallResult.Success = $false
		[int]$logMessageSeverity = 1
		if ([string]::IsNullOrEmpty($UninstallKey)) {
			Write-Log -Message "UninstallKey value NOT set. Skipping test for installed application via registry. Checking for UninstFile instead..." -Source ${CmdletName}
			$uninstallResult.Success = $null
			if ([string]::IsNullOrEmpty($UninstFile)) {
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
			if ($true -eq $(Test-NxtAppIsInstalled -UninstallKey "$UninstallKey" -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -DisplayVersion $DisplayVersion -DeploymentMethod $UninstallMethod)) {

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
					none {
						$uninstallResult.ErrorMessage = "An uninstallation method was NOT set. Skipping a default process execution."
						$uninstallResult.Success = $null
						[int]$logMessageSeverity = 1
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
				## if nothing was to execute herein just finish
				if ($internalInstallerMethod -ne "none") {

					$uninstallResult.ApplicationExitCode = $LastExitCode
					$uninstallResult.MainExitCode = $mainExitCode
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
							if ($true -eq $(Test-NxtAppIsInstalled -UninstallKey "$UninstallKey" -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude)) {
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
			}
			else {
				$uninstallResult.ErrorMessage = "Uninstall function could not run for provided parameter 'UninstallKey=$UninstallKey'. The expected application seems not to be installed on system!"
				$uninstallResult.Success = $null
				[int]$logMessageSeverity = 1
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
		Uninstalls old package versions if "UninstallOld": true.
	.DESCRIPTION
		If $UninstallOld is set to true, the function checks for old versions of the same package / $PackageFamilyGUID and uninstalls them.
	.PARAMETER AppName
		Specifies the Application Name used in the registry etc.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppVendor
		Specifies the Application Vendor used in the registry etc.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppVersion
		Specifies the Application Version used in the registry etc.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PackageFamilyGUID
		Specifies the Registry Key Name used for the Packages Wrapper Uninstall entry
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegPackagesKey
		Defines the Name of the Registry Key keeping track of all Packages delivered by this Packaging Framework.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallOld
		Will uninstall previous Versions before Installation if set to $true.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER DeployAppScriptFriendlyName
		The friendly name of the script used for deploying applications.
		Defaults to $deployAppScriptFriendlyName definded in the DeployApplication.ps1.
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
		$PackageFamilyGUID = $global:PackageConfig.PackageFamilyGUID,
		[Parameter(Mandatory = $false)]
		[string]
		$RegPackagesKey = $global:PackageConfig.RegPackagesKey,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallOld = $global:PackageConfig.UninstallOld,
		[Parameter(Mandatory = $false)]
		[string]
		$DeployAppScriptFriendlyName = $deployAppScriptFriendlyName,
		[Parameter(Mandatory = $false)]
		[string]
		$DeploymentSystem = $global:DeploymentSystem
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		[PSADTNXT.NxtApplicationResult]$uninstallOldResult = New-Object -TypeName PSADTNXT.NxtApplicationResult
        if ($true -eq $UninstallOld) {
            ## deleting from the registry can have severe impact on the system, so we make sure all neccesary parameters are not null or empty.
            if (
                [string]::IsNullOrEmpty($RegPackagesKey) -or
                [string]::IsNullOrEmpty($AppVendor) -or
                [string]::IsNullOrEmpty($AppName) -or
                [string]::IsNullOrEmpty($AppVersion)
            ) {
                throw "One of the parameters RegPackagesKey, AppVendor, AppName or AppVersion is empty"
            }
            Write-Log -Message "Checking for old packages..." -Source ${cmdletName}
            try {
                ## Check for Empirum packages under "HKLM:SOFTWARE\WOW6432Node\"
                if (Test-Path -Path "HKLM:SOFTWARE\WOW6432Node\$RegPackagesKey\$AppVendor") {
                    if (Test-Path -Path "HKLM:SOFTWARE\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName") {
                        [array]$appEmpirumPackageVersions = Get-ChildItem "HKLM:SOFTWARE\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName"
                        if (($appEmpirumPackageVersions).Count -eq 0) {
                            Remove-RegistryKey -Key "HKLM:SOFTWARE\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName" -Recurse
                            Remove-NxtRegistryKeyForAllUsers -Key "HKCU:SOFTWARE\$RegPackagesKey\$AppVendor\$AppName" -Recurse
                            Write-Log -Message "Deleted an empty Empirum application key: HKLM:SOFTWARE\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName" -Source ${cmdletName}
                        }
                        else {
                            foreach ($appEmpirumPackageVersion in $appEmpirumPackageVersions) {
                                Write-Log -Message "Found an old Empirum package version key: $($appEmpirumPackageVersion.name)" -Source ${cmdletName}
                                if (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString') {
                                    try {
                                        [string]$appendAW = [string]::Empty
                                        if ((Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'MachineSetup') -eq "1") {
                                            $appendAW = " /AW"
                                        }
                                        cmd /c "$(Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString') /X8 /S0$appendAW"
                                    }
                                    Catch {
										Write-Log -Message "Received an Error uninstalling $($appEmpirumPackageVersion.name)" -Source ${cmdletName}
                                    }
                                    if (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString') {
                                        [int32]$mainExitCode = 70001
                                        $uninstallOldResult.MainExitCode = $mainExitCode
                                        $uninstallOldResult.ErrorMessage = "Uninstallation of the found Empirum package '$($appEmpirumPackageVersion.name)' failed."
                                        $uninstallOldResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
                                        $uninstallOldResult.Success = $false
                                        [bool]$ReturnWithError = $true
                                        Write-Log -Message $($uninstallOldResult.ErrorMessage) -Severity 3 -Source ${cmdletName}
                                        break
                                    }
                                    else {
										$uninstallOldResult.ErrorMessage = "Uninstallation of the found Empirum package: '$($appEmpirumPackageVersion.name)' was successful."
										$uninstallOldResult.Success = $true
										Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
										Remove-NxtRegistryKeyForAllUsers -Key "$($appEmpirumPackageVersion.name -replace "^HKEY_LOCAL_MACHINE\\","HKCU:" -replace "\Wow6432Node",'')" -Recurse
										Remove-NxtRegistryKeyForAllUsers -Key "HKCU:SOFTWARE\$RegPackagesKey\$AppVendor\$AppName" -Recurse
                                    }
                                }
                                else {
                                    $appEmpirumPackageVersion | Foreach-Object {
                                        Remove-RegistryKey -Key $_.Name -Recurse
                                        Remove-NxtRegistryKeyForAllUsers -Key "$($_.Name -replace "^HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node","HKCU:SOFTWARE" -replace "^HKEY_LOCAL_MACHINE\\","HKCU:")" -Recurse
                                        
                                    }
                                    $uninstallOldResult.ErrorMessage = "This key contained no value 'UninstallString' and was deleted: $($appEmpirumPackageVersion.name)"
                                    $uninstallOldResult.Success = $null
                                    Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
								}
							}
							if ($true -eq (Test-Path -Path "HKLM:SOFTWARE\$RegPackagesKey\$AppVendor\$AppName")) {
								[array]$appEmpirumPackageVersions = Get-ChildItem "HKLM:SOFTWARE\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName"
								if ( $false -eq $ReturnWithError -and (($appEmpirumPackageVersions).Count -eq 0)) {
									Remove-RegistryKey -Key "HKLM:SOFTWARE\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName" -Recurse
									Remove-NxtRegistryKeyForAllUsers -Key "HKCU:SOFTWARE\$RegPackagesKey\$AppVendor\$AppName" -Recurse
									$uninstallOldResult.ErrorMessage = "Deleted the now empty Empirum application key: HKLM:SOFTWARE\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName"
									$uninstallOldResult.Success = $null
									Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
								}
							}
							## delete empty parent Registry Keys up to the RegPackagesKey
							Remove-NxtRegistryKeyForAllUsers -Key "HKCU:SOFTWARE\$RegPackagesKey\$AppVendor\$AppName" -Recurse
							Remove-NxtRegistryKeyForAllUsers -Key "HKCU:SOFTWARE\$RegPackagesKey\$AppVendor"
							Remove-NxtRegistryKeyForAllUsers -Key "HKCU:SOFTWARE\$RegPackagesKey"
							## delete empty parent Registry Keys up to the RegPackagesKey
							"HKLM:SOFTWARE\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName",
							"HKLM:SOFTWARE\WOW6432Node\$RegPackagesKey\$AppVendor",
							"HKLM:SOFTWARE\WOW6432Node\$RegPackagesKey" | ForEach-Object {
								if($true -eq (Test-Path -Path $_)){
									if((Get-ChildItem -Path $_).count -eq 0){
										Remove-RegistryKey -Key $_
									}
								}
							}
                        }
                    }
					if (Test-Path -Path "HKLM:SOFTWARE\WOW6432Node\$RegPackagesKey\$AppVendor") {
						if ( !$ReturnWithError -and ((Get-ChildItem "HKLM:SOFTWARE\WOW6432Node\$RegPackagesKey\$AppVendor").Count -eq 0) ) {
							Remove-RegistryKey -Key "HKLM:SOFTWARE\WOW6432Node\$RegPackagesKey\$AppVendor" -Recurse
							Remove-NxtRegistryKeyForAllUsers -Key "HKCU:SOFTWARE\$RegPackagesKey\$AppVendor" -Recurse
							$uninstallOldResult.ErrorMessage = "Deleted empty Empirum vendor key: HKLM:SOFTWARE\WOW6432Node\$RegPackagesKey\$AppVendor"
							$uninstallOldResult.Success = $null
							Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
						}
					}
                }
                ## Check for Empirum packages under "HKLM:SOFTWARE\"
                if ( !$ReturnWithError -and (Test-Path -Path "HKLM:SOFTWARE\$RegPackagesKey\$AppVendor") ) {
                    if (Test-Path -Path "HKLM:SOFTWARE\$RegPackagesKey\$AppVendor\$AppName") {
                        [array]$appEmpirumPackageVersions = Get-ChildItem "HKLM:SOFTWARE\$RegPackagesKey\$AppVendor\$AppName"
                        if (($appEmpirumPackageVersions).Count -eq 0) {
                            Remove-RegistryKey -Key "HKLM:SOFTWARE\$RegPackagesKey\$AppVendor\$AppName" -Recurse
                            Remove-NxtRegistryKeyForAllUsers -Key "HKCU:SOFTWARE\$RegPackagesKey\$AppVendor\$AppName" -Recurse
                            Write-Log -Message "Deleted an empty Empirum application key: HKLM:SOFTWARE\$RegPackagesKey\$AppVendor\$AppName" -Source ${cmdletName}
                        }
                        else {
                            foreach ($appEmpirumPackageVersion in $appEmpirumPackageVersions) {
                                Write-Log -Message "Found an old Empirum package version key: $($appEmpirumPackageVersion.name)" -Source ${cmdletName}
                                if (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString') {
                                    try {
                                        [string]$appendAW = [string]::Empty
                                        if ((Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'MachineSetup') -eq "1") {
                                            $appendAW = " /AW"
                                        }
                                        cmd /c "$(Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString') /X8 /S0$appendAW"
                                    }
                                    Catch {
										Write-Log -Message "Received an Error uninstalling $($appEmpirumPackageVersion.name)" -Source ${cmdletName}
                                    }
                                    if (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString') {
                                        [int32]$mainExitCode = 70001
                                        $uninstallOldResult.MainExitCode = $mainExitCode
                                        $uninstallOldResult.ErrorMessage = "Uninstallation of the found Empirum package '$($appEmpirumPackageVersion.name)' failed."
                                        $uninstallOldResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
                                        $uninstallOldResult.Success = $false
                                        Write-Log -Message $($uninstallOldResult.ErrorMessage) -Severity 3 -Source ${cmdletName}
                                        [bool]$ReturnWithError = $true
                                        break
                                    }
                                    else {
                                        $uninstallOldResult.ErrorMessage = "Uninstallation of the found Empirum package '$($appEmpirumPackageVersion.name)' was successful."
                                        $uninstallOldResult.Success = $true
                                        Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
                                        Remove-RegistryKey -Key $appEmpirumPackageVersion.name -Recurse
                                        Remove-NxtRegistryKeyForAllUsers -Key "$($appEmpirumPackageVersion.name -replace "^HKEY_LOCAL_MACHINE\\","HKCU:")" -Recurse
										Remove-NxtRegistryKeyForAllUsers -Key "HKCU:SOFTWARE\$RegPackagesKey\$AppVendor\$AppName" -Recurse
                                    }
                                }
                                else {
                                    $appEmpirumPackageVersion | ForEach-Object {
                                        Remove-RegistryKey -Key $_.name -Recurse
                                        Remove-NxtRegistryKeyForAllUsers -Key "$($_.name -replace "^HKEY_LOCAL_MACHINE\\","HKCU:")" -Recurse
                                    }
                                    $uninstallOldResult.ErrorMessage = "This key contained no value 'UninstallString' and was deleted: $($appEmpirumPackageVersion.name)"
                                    $uninstallOldResult.Success = $null
                                    Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
                                }
                            }
							if (Test-Path -Path "HKLM:SOFTWARE\$RegPackagesKey\$AppVendor\$AppName") {
								[array]$appEmpirumPackageVersions = Get-ChildItem "HKLM:SOFTWARE\$RegPackagesKey\$AppVendor\$AppName"
	                            if ($false -eq $ReturnWithError -and (($appEmpirumPackageVersions).Count -eq 0) ) {
	                                Remove-RegistryKey -Key "HKLM:SOFTWARE\$RegPackagesKey\$AppVendor\$AppName" -Recurse
	                                Remove-NxtRegistryKeyForAllUsers -Key "HKCU:SOFTWARE\$RegPackagesKey\$AppVendor\$AppName" -Recurse
	                                $uninstallOldResult.ErrorMessage = "Deleted the now empty Empirum application key: HKLM:SOFTWARE\$RegPackagesKey\$AppVendor\$AppName"
	                                $uninstallOldResult.Success = $null
	                                Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
	                            }
							}
							## delete empty parent Registry Keys up to the RegPackagesKey
							Remove-NxtRegistryKeyForAllUsers -Key "HKCU:SOFTWARE\$RegPackagesKey\$AppVendor\AppName" -Recurse
							Remove-NxtRegistryKeyForAllUsers -Key "HKCU:SOFTWARE\$RegPackagesKey\$AppVendor"
							Remove-NxtRegistryKeyForAllUsers -Key "HKCU:SOFTWARE\$RegPackagesKey"
							## also cleanup keys under HKLM
							Remove-RegistryKey -Key "$($appEmpirumPackageVersion.name)" -Recurse
							## delete empty parent Registry Keys up to the RegPackagesKey
							"HKLM:SOFTWARE\$RegPackagesKey\$AppVendor\$AppName",
							"HKLM:SOFTWARE\$RegPackagesKey\$AppVendor",
							"HKLM:SOFTWARE\$RegPackagesKey"	| ForEach-Object {
								if($true -eq (Test-Path -Path $_)){
									if((Get-ChildItem -Path $_).count -eq 0){
										Remove-RegistryKey -Key $_
									}
								}
							}
                        }
                    }
                    if ($true -eq (Test-Path -Path "HKLM:SOFTWARE\$RegPackagesKey\$AppVendor")) {
						if (!$ReturnWithError -and ((Get-ChildItem "HKLM:SOFTWARE\$RegPackagesKey\$AppVendor").Count -eq 0)) {
	                        Remove-RegistryKey -Key "HKLM:SOFTWARE\$RegPackagesKey\$AppVendor" -Recurse
	                        Remove-NxtRegistryKeyForAllUsers -Key "HKCU:SOFTWARE\$RegPackagesKey\$AppVendor" -Recurse
	                        $uninstallOldResult.ErrorMessage = "Deleted empty Empirum vendor key: HKLM:SOFTWARE\$RegPackagesKey\$AppVendor"
	                        $uninstallOldResult.Success = $null
	                        Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
	                    }
					}
                }
				if (!$ReturnWithError) {
					## Check for VBS or PSADT packages
					if (Test-RegistryValue -Key HKLM\Software\Wow6432Node\$RegPackagesKey\$PackageFamilyGUID -Value 'UninstallString') {
						[string]$regPackageFamilyGUID = "HKLM\Software\Wow6432Node\$RegPackagesKey\$PackageFamilyGUID"
					}
					else {
						[string]$regPackageFamilyGUID = "HKLM\Software\$RegPackagesKey\$PackageFamilyGUID"
					}
					## Check if the installed package's version is lower than the current one's and if the UninstallString entry exists
					if ((Get-RegistryKey -Key $regPackageFamilyGUID -Value 'Version') -lt $AppVersion -and (Test-RegistryValue -Key $regPackageFamilyGUID -Value 'UninstallString')) {
						Write-Log -Message "Parameter 'UninstallOld' is set to true and an old package version was found: Uninstalling old package..." -Source ${cmdletName}
						cmd /c (Get-RegistryKey -Key $regPackageFamilyGUID -Value 'UninstallString')
						if (Test-RegistryValue -Key $regPackageFamilyGUID -Value 'UninstallString') {
							[int32]$mainExitCode = 70001
							$uninstallOldResult.MainExitCode = $mainExitCode
							$uninstallOldResult.ErrorMessage = "ERROR: Uninstallation of old package failed. Abort!"
							$uninstallOldResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
							$uninstallOldResult.Success = $false
							Write-Log -Message $($uninstallOldResult.ErrorMessage) -Severity 3 -Source $DeployAppScriptFriendlyName
							Show-DialogBox -Text $($uninstallOldResult.ErrorMessage) -Icon 'Stop'
						}
						else {
							Write-Log -Message  -Source ${cmdletName}
							$uninstallOldResult.ErrorMessage = "Uninstallation of old package successful."
							$uninstallOldResult.Success = $true
							Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
						}
					}
					else {
						$uninstallOldResult.ErrorMessage = "No need to uninstall old packages."
						$uninstallOldResult.Success = $null
						Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
					}
				}
			}
			Catch {
				$uninstallOldResult.ErrorMessage = "The Uninstall-Old function threw an error."
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
#region Function Unregister-NxtPackage
function Unregister-NxtPackage {
	<#
	.SYNOPSIS
		Removes package files and unregisters the package in the registry.
	.DESCRIPTION
		Removes the package files from "$APP\" and deletes the package's registry keys under "HKLM\Software\$regPackagesKey\$PackageFamilyGUID" and "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageFamilyGUID".
	.PARAMETER PackageFamilyGUID
		Specifies the Registry Key Name used for the Packages Wrapper Uninstall entry.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegPackagesKey
		Defines the Name of the Registry Key keeping track of all Packages delivered by this Packaging Framework.
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
		[string]
		$PackageFamilyGUID = $global:PackageConfig.PackageFamilyGUID,
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Write-Log -Message "Unregistering package..." -Source ${cmdletName}
		try {
			Copy-File -Path "$ScriptRoot\Clean-Neo42AppFolder.ps1" -Destination "$App\" 
			Start-Sleep -Seconds 1
			Execute-Process -Path powershell.exe -Parameters "-File `"$App\Clean-Neo42AppFolder.ps1`"" -NoWait
			Remove-RegistryKey -Key HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageFamilyGUID
			Remove-RegistryKey -Key HKLM\Software\$RegPackagesKey\$PackageFamilyGUID
			Write-Log -Message "Package unregistration successful." -Source ${cmdletName}
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
			Write-Log -Message "Failed to add content to the file $Path'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			[System.Xml.XmlDocument]$xmlDoc = New-Object System.Xml.XmlDocument
			$xmlDoc.Load($XmlFilePath)
			[string]$xmlDoc.DocumentElement.SelectSingleNode($SingleNodeName).InnerText = $Value
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
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
