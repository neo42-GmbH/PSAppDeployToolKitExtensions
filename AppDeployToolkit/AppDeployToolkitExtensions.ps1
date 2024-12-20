﻿<#
.SYNOPSIS
	This script is a template that allows you to extend the toolkit with your own custom functions.
.DESCRIPTION
	The script is automatically dot-sourced by the AppDeployToolkitMain.ps1 script.
.NOTES
	This script has been extensively modified by neo42 GmbH, building upon the template provided by the PowerShell App Deployment Toolkit.
	The "*-Nxt*" function name pattern is used by "neo42 GmbH" to avoid naming conflicts with the built-in functions of the toolkit.

	# LICENSE #
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

	# ORIGINAL COPYRIGHT #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.

	# MODIFICATION COPYRIGHT #
	Copyright (c) 2024 neo42 GmbH, Germany.

	Version: ##REPLACEVERSION##
	ConfigVersion: 2024.11.13.1
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
if ($null -eq ([Management.Automation.PSTypeName]'PSADTNXT.Extensions').Type) {
	if ($true -eq (Test-Path -Path $extensionCsPath)) {
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
	.SYNOPSIS
		Appends a string to a text file.
	.DESCRIPTION
		The `Add-NxtContent` function appends a specified string to a text file. If the file does not exist, it will create one.
		The function can detect the encoding of the file and use the appropriate encoding to write the content. If the encoding
		cannot be detected, the function provides an option to use a default encoding.
	.PARAMETER Path
		Specifies the path to the file where the string will be appended.
	.PARAMETER Value
		Specifies the string that will be appended to the file.
	.PARAMETER Encoding
		Specifies the encoding that should be used to write the content. It defaults to the value obtained from `Get-NxtFileEncoding`.
		Possible values include: "Ascii", "Default", "UTF7", "BigEndianUnicode",
		"Oem", "Unicode", "UTF32", "UTF8".
	.PARAMETER DefaultEncoding
		Specifies the encoding that should be used if the `Get-NxtFileEncoding` function is unable to detect the file's encoding.
		Possible values include: "Ascii", "Default", "UTF7", "BigEndianUnicode",
		"Oem", "Unicode", "UTF32", "UTF8".
	.EXAMPLE
		Add-NxtContent -Path C:\Temp\testfile.txt -Value "Text to be appended to a file"
		This example appends the text "Text to be appended to a file" to the `testfile.txt` in the `C:\Temp` directory.
	.EXAMPLE
		Add-NxtContent -Path C:\Temp\testfile.txt -Value "Additional content" -Encoding "UTF8"
		This example appends the text "Additional content" to the `testfile.txt` in the `C:\Temp` directory using the UTF8 encoding.
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
		[ValidateSet("Ascii", "Default", "UTF7", "BigEndianUnicode", "Oem", "Unicode", "UTF32", "UTF8")]
		[String]
		$Encoding,
		[Parameter()]
		[ValidateSet("Ascii", "Default", "UTF7", "BigEndianUnicode", "Oem", "Unicode", "UTF32", "UTF8")]
		[String]
		$DefaultEncoding
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[String]$intEncoding = $Encoding
		if (($false -eq (Test-Path -Path $Path)) -and ($true -eq [String]::IsNullOrEmpty($intEncoding))) {
			[String]$intEncoding = "UTF8"
		}
		elseif (($false -eq (Test-Path -Path $Path)) -and ($true -eq [String]::IsNullOrEmpty($intEncoding))) {
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
	.SYNOPSIS
		Creates or updates a local group.
	.DESCRIPTION
		This function creates a local group with the given parameters. If the group already exists,
		it will only process the description parameter.
		Returns $true if the operation was successful, otherwise returns $false.
	.PARAMETER GroupName
		Name of the local group.
		This parameter is mandatory.
	.PARAMETER ComputerName
		Name of the computer where the group needs to be added or updated.
		If not specified, defaults to the current computer ($env:COMPUTERNAME).
	.PARAMETER Description
		Description for the new group or updated group.
	.EXAMPLE
		Add-NxtLocalGroup -GroupName "TestGroup"
		This will create or update a local group named "TestGroup" on the current computer.
	.EXAMPLE
		Add-NxtLocalGroup -GroupName "TestGroup" -ComputerName "Computer123" -Description "This is a test group."
		This will create or update a local group named "TestGroup" on "Computer123" with the provided description.
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
			[bool]$groupExists = Test-NxtLocalGroupExists -GroupName $GroupName -COMPUTERNAME $COMPUTERNAME
			if ($false -eq $groupExists) {
				[System.DirectoryServices.DirectoryEntry]$objGroup = $adsiObj.Create("Group", $GroupName)
				$objGroup.SetInfo() | Out-Null
			}
			else {
				[System.DirectoryServices.DirectoryEntry]$objGroup = [ADSI]"WinNT://$COMPUTERNAME/$GroupName,group"
			}
			if ($false -eq ([string]::IsNullOrEmpty($Description))) {
				$objGroup.Put("Description", $Description) | Out-Null
				$objGroup.SetInfo() | Out-Null
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
	.SYNOPSIS
		Adds a local member (either a user or a group) to a specified local group.
	.DESCRIPTION
		The Add-NxtLocalGroupMember function provides a way to add a local member (either a user or a group) to an existing local group.
		It requires the name of the target group, the name of the member to be added, and the type of the member (either "Group" or "User").
		Optionally, a computer name can be provided; otherwise, it defaults to the current computer.
		The function returns a boolean value indicating whether the operation was successful or not.
	.PARAMETER GroupName
		Name of the target group to which the member should be added.
		This parameter is mandatory.
	.PARAMETER MemberName
		Name of the member that needs to be added to the specified group.
		This parameter is mandatory.
	.PARAMETER Computername
		Specifies the name of the computer where the group exists. Defaults to the name of the current computer.
	.EXAMPLE
		Add-NxtLocalGroupMember -GroupName "Administrators" -MemberName "JohnDoe"
		This example adds the local user "JohnDoe" to the "Administrators" group.
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
			[bool]$groupExists = Test-NxtLocalGroupExists -GroupName $GroupName -COMPUTERNAME $COMPUTERNAME
			if ($false -eq $groupExists) {
				Write-Output $false
				return
			}
			[System.DirectoryServices.DirectoryEntry]$targetGroup = [ADSI]"WinNT://$COMPUTERNAME/$GroupName,group"
			[bool]$userExists = Test-NxtLocalUserExists -UserName $MemberName -ComputerName $COMPUTERNAME
			if ($false -eq $userExists ) {
				Write-Output $false
				return
			}
			[System.DirectoryServices.DirectoryEntry]$memberUser = [ADSI]"WinNT://$COMPUTERNAME/$MemberName,user"
			$targetGroup.psbase.Invoke("Add", $memberUser.path) | Out-Null
			Write-Output $true
			return
		}
		catch {
			Write-Log -Message "Failed to add $MemberName to $GroupName. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
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
	.SYNOPSIS
		Creates a new local user or updates an existing one with the specified parameters.
	.DESCRIPTION
		The `Add-NxtLocalUser` function is designed to create a new local user or update properties of an existing one based on the provided parameters.
		If the user already exists, only `FullName`, `Description`, `SetPwdExpired`, and `SetPwdNeverExpires` parameters will be processed.
		Returns $true if the operation was successful, otherwise returns $false.
	.PARAMETER UserName
		The name of the user.
		This parameter is mandatory.
	.PARAMETER Password
		Password for the new user.
		This parameter is mandatory.
	.PARAMETER FullName
		Full name of the user.
	.PARAMETER Description
		Description for the new user.
	.PARAMETER SetPwdExpired
		If set, the user will be prompted to change the password at the first logon.
	.PARAMETER SetPwdNeverExpires
		If set, the user's password will be configured to never expire.
	.PARAMETER COMPUTERNAME
		Specifies the name of the computer. If not provided, defaults to the current computer's name (`$env:COMPUTERNAME`).
	.EXAMPLE
		Add-NxtLocalUser -UserName "ServiceUser" -Password "123!abc" -Description "User to run service" -SetPwdNeverExpires
	.EXAMPLE
		Add-NxtLocalUser -UserName "JohnDoe" -Password "Secure$Pwd123" -FullName "John Doe" -Description "Backup admin account" -SetPwdExpired
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
			[bool]$userExists = Test-NxtLocalUserExists -UserName $UserName -ComputerName $COMPUTERNAME
			if ($false -eq $userExists) {
				[System.DirectoryServices.DirectoryEntry]$objUser = $adsiObj.Create("User", $UserName)
			}
			else {
				[System.DirectoryServices.DirectoryEntry]$objUser = [ADSI]"WinNT://$COMPUTERNAME/$UserName,user"
			}
			$objUser.SetPassword($Password) | Out-Null
			$objUser.SetInfo() | Out-Null
			if ($false -eq ([string]::IsNullOrEmpty($FullName))) {
				$objUser.Put("FullName", $FullName) | Out-Null
				$objUser.SetInfo() | Out-Null
			}
			if ($false -eq ([string]::IsNullOrEmpty($Description))) {
				$objUser.Put("Description", $Description) | Out-Null
				$objUser.SetInfo() | Out-Null
			}
			if ($true -eq $SetPwdExpired) {
				## Reset to normal account flag ADS_UF_NORMAL_ACCOUNT
				$objUser.UserFlags = 512
				$objUser.SetInfo() | Out-Null
				## Set password expired
				$objUser.Put("PasswordExpired", 1) | Out-Null
				$objUser.SetInfo() | Out-Null
			}
			if ($true -eq $SetPwdNeverExpires) {
				## Set flag ADS_UF_DONT_EXPIRE_PASSWD
				$objUser.UserFlags = 65536
				$objUser.SetInfo() | Out-Null
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
#region Function Add-NxtProcessPathVariable
function Add-NxtProcessPathVariable {
	<#
	.SYNOPSIS
		Adds a path to the processes PATH environment variable.
	.DESCRIPTION
		Adds a path to the processes PATH environment variable. If the path already exists, it will not be added again.
		Empty values will be removed.
	.PARAMETER Path
		Path to be added to the processes PATH environment variable.
		Has to be a valid path. The path value will automatically be expanded.
	.PARAMETER AddToBeginning
		If set to true, the path will be added to the beginning of the PATH environment variable, defaults to false.
	.EXAMPLE
		Add-NxtProcessPathVariable -Path "C:\Temp"
	.EXAMPLE
		Add-NxtProcessPathVariable -Path "C:\Temp" -AddToBeginning $true
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path,
		[Parameter(Mandatory = $false)]
		[bool]
		$AddToBeginning = $false
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[string[]]$pathEntries = @(((Get-NxtProcessEnvironmentVariable -Key 'PATH').Split(';') | Where-Object {
					$false -eq [string]::IsNullOrWhiteSpace($_)
				}))
		if ($false -eq [System.IO.Path]::IsPathRooted($Path)) {
			Write-Log -Message "The path [$($Path)] that was supposed be added is not rooted." -Severity 3 -Source ${cmdletName}
			throw "The path [$($Path)] that was supposed be added is not rooted."
		}
		try {
			[System.IO.DirectoryInfo]$dirInfo = [System.IO.DirectoryInfo]::new($Path)
		}
		catch {
			Write-Log -Message "The path [$($Path)] that was supposed be added is not a valid path." -Severity 3 -Source ${cmdletName}
			throw "The path [$($Path)] that was supposed be added is not a valid path."
		}
		if ($false -eq $dirInfo.Exists) {
			Write-Log "The path [$($dirInfo.FullName)] that will be added does not exist." -Severity 2 -Source ${cmdletName}
		}
		if ($pathEntries.Count -eq 0) {
			Set-NxtProcessEnvironmentVariable -Key "PATH" -Value ($dirInfo.FullName + ";")
			Write-Log "Added [$($Path.FullName)] to to an empty processes PATH variable." -Serverity 2 -Source ${cmdletName}
		}
		elseif ($pathEntries.TrimEnd('\') -inotcontains $dirInfo.FullName.TrimEnd('\')) {
			if ($false -eq $AddToBeginning) {
				$pathEntries = $pathEntries + @($dirInfo.FullName)
				Write-Log "Appending [$($dirInfo.FullName)] to the processes PATH variable." -Source ${cmdletName}
			}
			else {
				$pathEntries = @($dirInfo.FullName) + $pathEntries
				Write-Log "Prepending [$($dirInfo.FullName)] to the processes PATH variable." -Source ${cmdletName}
			}
			Set-NxtProcessEnvironmentVariable -Key "PATH" -Value (($pathEntries -join ";") + ";")
		}
		else {
			Write-Log "Path entry [$($dirInfo.FullName)] already exists in the PATH variable." -Severity 2 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Add-NxtSystemPathVariable
function Add-NxtSystemPathVariable {
	<#
	.SYNOPSIS
		Adds a path to the systems PATH environment variable.
	.DESCRIPTION
		Adds a path to the systems PATH environment variable. If the path already exists, it will not be added again.
		Empty values will be removed.
	.PARAMETER Path
		Path to be added to the systems PATH environment variable.
		Has to be a valid path. The path value will automatically be expanded.
	.PARAMETER AddToBeginning
		If set to true, the path will be added to the beginning of the PATH environment variable, defaults to false.
	.EXAMPLE
		Add-NxtSystemPathVariable -Path "C:\Temp"
	.EXAMPLE
		Add-NxtSystemPathVariable -Path "C:\Temp" -AddToBeginning $true
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path,
		[Parameter(Mandatory = $false)]
		[bool]
		$AddToBeginning = $false
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[string[]]$pathEntries = @(((Get-NxtSystemEnvironmentVariable -Key 'PATH').Split(';') | Where-Object {
					$false -eq [string]::IsNullOrWhiteSpace($_)
				}))
		if ($false -eq [System.IO.Path]::IsPathRooted($Path)) {
			Write-Log -Message "The path [$($Path)] that was supposed be added is not rooted." -Severity 3 -Source ${cmdletName}
			throw
		}
		try {
			[System.IO.DirectoryInfo]$dirInfo = [System.IO.DirectoryInfo]::new($Path)
		}
		catch {
			Write-Log -Message "The path [$($Path)] that was supposed be added is not a valid path." -Severity 3 -Source ${cmdletName}
			throw
		}
		if ($false -eq $dirInfo.Exists) {
			Write-Log "The path [$($dirInfo.FullName)] that will be added does not exist." -Severity 2 -Source ${cmdletName}
		}
		if ($pathEntries.Count -eq 0) {
			Set-NxtSystemEnvironmentVariable -Key "PATH" -Value ($dirInfo.FullName + ";")
			Write-Log "Added [$($dirInfo.FullName)] to an empty systems PATH variable." -Severity 2 -Source ${cmdletName}
		}
		elseif ($pathEntries.TrimEnd('\') -inotcontains $dirInfo.FullName.TrimEnd('\')) {
			if ($false -eq $AddToBeginning) {
				$pathEntries = $pathEntries + @($dirInfo.FullName)
				Write-Log "Appending [$($dirInfo.FullName)] to the systems PATH variable." -Source ${cmdletName}
			}
			else {
				$pathEntries = @($dirInfo.FullName) + $pathEntries
				Write-Log "Prepending [$($dirInfo.FullName)] to the systems PATH variable." -Source ${cmdletName}
			}
			Set-NxtSystemEnvironmentVariable -Key "PATH" -Value (($pathEntries -join ";") + ";")
		}
		else {
			Write-Log "Path entry [$($dirInfo.FullName)] already exists in the PATH variable." -Severity 2 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Add-NxtXmlNode
function Add-NxtXmlNode {
	<#
	.SYNOPSIS
		Adds a new node to an existing xml file
	.DESCRIPTION
		Adds a new node to an existing xml file. If the parent node does not exist, it will be created. Does not support adding multiple nodes at once. Does not support namespaces.
	.PARAMETER FilePath
		The path to the xml file
	.PARAMETER NodePath
		The path to the node to add
	.PARAMETER Attributes
		The attributes to add
	.PARAMETER InnerText
		The value to add to the node
	.PARAMETER Encoding
		Specifies the encoding that should be used to write the content. It defaults to the value obtained from `Get-NxtFileEncoding`.
		Possible values include: "Ascii", "Default", "UTF7", "BigEndianUnicode",
		"Oem", "Unicode", "UTF32", "UTF8", "UTF8withBom".
	.PARAMETER DefaultEncoding
		Specifies the encoding that should be used if the `Get-NxtFileEncoding` function is unable to detect the file's encoding.
		Possible values include: "Ascii", "Default", "UTF7", "BigEndianUnicode",
		"Oem", "Unicode", "UTF32", "UTF8", "UTF8withBom".
	.EXAMPLE
		Add-NxtXmlNode -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -Attributes @{"name"="NewNode2"} -InnerText "NewValue2"
		Adds a new node to the xml file xmlstuff.xml at the path /RootNode/Settings/Settings2/SubSubSetting3 with the attribute name=NewNode2 and the value NewValue2.
	.EXAMPLE
		Add-NxtXmlNode -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -Attributes @{"name"="NewNode2"}
		Adds a new node to the xml file xmlstuff.xml at the path /RootNode/Settings/Settings2/SubSubSetting3 with the attribute name=NewNode2.
	.EXAMPLE
		Add-NxtXmlNode -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3"
		Adds a new node to the xml file xmlstuff.xml at the path /RootNode/Settings/Settings2/SubSubSetting3.
	.EXAMPLE
		Add-NxtXmlNode -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -InnerText "NewValue2"
		Adds a new node to the xml file xmlstuff.xml at the path /RootNode/Settings/Settings2/SubSubSetting3 with the value NewValue2.
	.EXAMPLE
		Add-NxtXmlNode -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -Attributes @{"name"="NewNode2";"other"="1232"} -InnerText "NewValue2"
		Adds a new node to the xml file xmlstuff.xml at the path /RootNode/Settings/Settings2/SubSubSetting3 with the attributes name=NewNode2 and other=1232 and the value NewValue2.
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$FilePath,
		[Parameter(Mandatory = $true)]
		[string]
		$NodePath,
		[Parameter(Mandatory = $false)]
		[hashtable]
		$Attributes,
		[Parameter(Mandatory = $false)]
		[string]
		$InnerText,
		[Parameter(Mandatory = $false)]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[string]
		$Encoding,
		[Parameter(Mandatory = $false)]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[string]
		$DefaultEncoding
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			if ($false -eq (Test-Path -Path $FilePath)) {
				Write-Log -Message "File $FilePath does not exist" -Severity 3
				throw "File $FilePath does not exist"
			}
			[hashtable]$encodingParams = @{}
			if ($false -eq [string]::IsNullOrEmpty($Encoding)) {
				$encodingParams['Encoding'] = $Encoding
			}
			if ($false -eq [string]::IsNullOrEmpty($DefaultEncoding)) {
				$encodingParams['DefaultEncoding'] = $DefaultEncoding
			}
			[System.Xml.XmlDocument]$xml = Import-NxtXmlFile @encodingParams -Path $FilePath
			[string]$parentNodePath = $NodePath.Substring(0, $NodePath.LastIndexOf("/"))
			if ($true -eq ([string]::IsNullOrEmpty($parentNodePath))) {
				throw "The provided node root path $NodePath does not exist"
			}
			[string]$lastNodeChild = $NodePath.Substring($NodePath.LastIndexOf("/") + 1)
			# Test for Parent Node
			if ($false -eq (Test-NxtXmlNodeExists -FilePath $FilePath -NodePath $parentNodePath)) {
				Write-Log -Message "Parent node $parentNodePath does not exist. Creating it." -Source ${cmdletName}
				Add-NxtXmlNode @encodingParams -FilePath $FilePath -NodePath $parentNodePath
				[System.Xml.XmlDocument]$xml = [System.Xml.XmlDocument]::new()
				$xml = Import-NxtXmlFile @encodingParams -Path $FilePath
			}
			[string]$message = "Adding node $NodePath to $FilePath"
			# Create new node with the last part of the path
			[System.Xml.XmlLinkedNode]$newNode = $xml.CreateElement( $lastNodeChild )
			if ($false -eq [string]::IsNullOrEmpty($InnerText)) {
				$newNode.InnerText = $InnerText
				$message += " with innerText [$InnerText]"
			}
			if ($false -eq [string]::IsNullOrEmpty($Attributes)) {
				foreach ($attribute in $Attributes.GetEnumerator()) {
					$newNode.SetAttribute($attribute.Key, $attribute.Value)
					$message += " with attribute $($attribute.Key)=$($attribute.Value)"
				}
			}
			$message += "."
			Write-Log -Message $message -Source ${CmdletName}
			$xml.SelectSingleNode($parentNodePath).AppendChild($newNode) | Out-Null
			Save-NxtXmlFile @encodingParams -Xml $xml -Path $FilePath
		}
		catch {
			Write-Log -Message "Failed to add node $NodePath to $FilePath." -Severity 3 -Source ${cmdletName}
			throw $_
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Block-NxtAppExecution
function Block-NxtAppExecution {
	<#
	.SYNOPSIS
		Block the execution of an application(s)
	.DESCRIPTION
		1.  Makes a copy of this script in a temporary directory on the local machine.
		2.  Checks for an existing scheduled task from previous failed installation attempt where apps were blocked and if found, calls the Unblock-NxtAppExecution function to restore the original IFEO registry keys.
				This is to prevent the function from overriding the backup of the original IFEO options.
		3.  Creates a scheduled task to restore the IFEO registry key values in case the script is terminated uncleanly by calling the local temporary copy of this script with the parameter -CleanupBlockedApps.
		4.  Modifies the "Image File Execution Options" registry key for the specified process(s) to call this script with the parameter -ShowBlockedAppDialog.
		5.  When the script is called with those parameters, it will display a custom message to the user to indicate that execution of the application has been blocked while the installation is in progress.
				The text of this message can be customized in the XML configuration file.
	.PARAMETER ProcessName
		Name of the process or processes separated by commas.
	.PARAMETER BlockScriptLocation
		The location where the block script will be placed. Defaults to $global:PackageConfig.App.
	.PARAMETER ScriptDirectory
		The directory where the script is located. Defaults to $scriptDirectory.
	.PARAMETER RegKeyAppExecution
		The registry key where the application execution options are stored. Defaults to $regKeyAppExecution.
	.OUTPUTS
		none.
	.EXAMPLE
		Block-NxtAppExecution -ProcessName ('winword','excel')
	.NOTES
		This is an internal script function and should typically not be called directly.
		It is used when the -BlockExecution parameter is specified with the Show-NxtInstallationWelcome function to block applications.
	.LINK
		https://psappdeploytoolkit.com
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[string[]]$ProcessName,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]
		$BlockScriptLocation = $global:PackageConfig.App,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]
		$ScriptDirectory = $scriptDirectory,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]
		$RegKeyAppExecution = $regKeyAppExecution
	)
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		[string]$blockExecutionTempPath = Join-Path -Path $BlockScriptLocation -ChildPath 'BlockExecution'
		[string]$schTaskBlockedAppsName = $InstallName + '_BlockedApps'
		## Append .exe to match registry keys
		[string[]]$blockProcessNames = $ProcessName | ForEach-Object {
			($_ -replace "\.exe$") + '.exe'
		}
		if ($true -eq (Test-Path -LiteralPath $blockExecutionTempPath -PathType 'Container')) {
			Write-Log -Message "Previous block execution script folder found. Removing it." -Source ${CmdletName}
			Close-NxtBlockExecutionWindow
			Remove-Folder -Path $blockExecutionTempPath
		}
		try {
			New-NxtFolderWithPermissions -Path $blockExecutionTempPath -FullControlPermissions BuiltinAdministratorsSid,LocalSystemSid -ReadAndExecutePermissions BuiltinUsersSid -Owner BuiltinAdministratorsSid -ProtectRules $true | Out-Null
		}
		catch {
			Write-Log -Message "Unable to create [$blockExecutionTempPath]. Cannot securely place the Block-Execution script." -Severity 3 -Source ${CmdletName}
			throw "Unable to create [$blockExecutionTempPath]. Cannot securely place the Block-Execution script."
		}
		## Copy the block execution required files to the persistent location
		Copy-Item -Path "$ScriptDirectory\AppDeployToolkit\" -Destination "$blockExecutionTempPath\AppDeployToolkit\" -Exclude 'thumbs.db' -Recurse -Force -ErrorAction 'SilentlyContinue'
		Copy-Item -Path "$ScriptDirectory\DeployNxtApplication.exe" -Destination $blockExecutionTempPath -Force -ErrorAction 'SilentlyContinue'
		Copy-Item -Path "$ScriptDirectory\Setup.ico" -Destination $blockExecutionTempPath -Force -ErrorAction 'SilentlyContinue'
		## Enable block execution mode
		Set-Content -Path "$blockExecutionTempPath\DeployNxtApplication.exe.config" -Force -Value "<?xml version=`"1.0`" encoding=`"utf-8`" ?><configuration><appSettings><add key=`"OperationMode`" value=`"BlockExecution`"/><add key=`"BlockExecution_Title`" value=`"$installTitle`"/></appSettings></configuration>"
		## Create a scheduled task to run on startup to call this script and clean up blocked applications in case the installation is interrupted, e.g. user shuts down during installation"
		Write-Log -Message 'Creating scheduled task to cleanup blocked applications in case the installation is interrupted.' -Source ${CmdletName}
		try {
			## Specify the scheduled task configuration
			[CimInstance[]]$scheduledTaskTriggers = New-ScheduledTaskTrigger -AtStartup
			[CimInstance]$scheduledTaskSetting = New-ScheduledTaskSettingsSet -MultipleInstances "IgnoreNew" -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd -ExecutionTimeLimit (New-TimeSpan -Minutes 5) -Priority 7
			[CimInstance]$scheduledTaskPrincipal = New-ScheduledTaskPrincipal -UserId 'S-1-5-18' -LogonType ServiceAccount -RunLevel Highest
			[CimInstance[]]$scheduledTaskActions = @(
				## Remove the IFEO key
				foreach ($processName in $blockProcessNames) {
					New-ScheduledTaskAction -Execute "$env:SystemRoot\system32\reg.exe" -Argument "DELETE `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$processName`" /v Debugger /f"
				}
				## Remove the temp block exec folder
				New-ScheduledTaskAction -Execute "$env:windir\system32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-NonInteractive -NoProfile -Command `"Remove-Item -Recurse -Force -Path '$blockExecutionTempPath'`""
				## Remove the scheduled task
				New-ScheduledTaskAction -Execute "$env:SystemRoot\system32\schtasks.exe" -Argument "/delete /tn `"$schTaskBlockedAppsName`" /f"
			)
			[CimInstance]$scheduledTask = New-ScheduledTask -Trigger $scheduledTaskTriggers -Settings $scheduledTaskSetting -Principal $scheduledTaskPrincipal -Action $scheduledTaskActions
			Register-ScheduledTask -InputObject $scheduledTask -TaskName $schTaskBlockedAppsName -TaskPath '\' -ErrorAction 'Stop' -Force | Out-Null
		}
		catch {
			Write-Log -Message "Failed to create scheduled task to cleanup blocked applications. `n$(Resolve-Error)" -Severity 1 -Source ${CmdletName}
		}
		## Enumerate each process and set the debugger value to block application execution
		foreach ($blockProcess in $blockProcessNames) {
			Write-Log -Message "Setting the Image File Execution Option registry key to block execution of [$blockProcess]." -Source ${CmdletName}
			Set-RegistryKey -Key (Join-Path -Path $RegKeyAppExecution -ChildPath $blockProcess) -Name 'Debugger' -Value "$blockExecutionTempPath\DeployNxtApplication.exe" -ContinueOnError $true
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Close-NxtBlockExecutionWindow
function Close-NxtBlockExecutionWindow {
	<#
	.SYNOPSIS
		Closes Block-Execution dialogues generated by the current installation.
	.DESCRIPTION
		The Close-NxtBlockExecutionWindow function is designed to close any lingering information windows generated by block execution functionality.
		If these windows are not closed by the end of the script, embedded graphics files may remain in use, preventing a successful cleanup.
		This function helps to address this issue by ensuring these windows are properly closed.
	.EXAMPLE
		Close-NxtBlockExecutionWindow
		This example demonstrates how to call the function to close any active Block-Execution dialogues.
	.OUTPUTS
		none.
	.NOTES
		It is typically not recommended to call this function directly, as it's primarily intended for internal script operations.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[int[]]$blockexecutionWindowId = (Get-Process powershell | Where-Object {
			$_.MainWindowTitle -eq $installTitle}
		).Id
		if ($false -eq ([string]::IsNullOrEmpty($blockexecutionWindowId))) {
			Write-Log "The informational window of BlockExecution functionality will be closed now ..."
			Stop-NxtProcess -Id $blockexecutionWindowId
		}
		[int[]]$blockexecutionWindowId = (Get-Process powershell | Where-Object {
			$_.Path -like "*\BlockExecution\DeoployNxtApplication.exe"}
		).Id
		if ($false -eq ([string]::IsNullOrEmpty($blockexecutionWindowId))) {
			Write-Log "The background process of BlockExecution functionality will be closed now ..."
			Stop-NxtProcess -Id $blockexecutionWindowId
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Add-NxtParameterToCommand
function Add-NxtParameterToCommand {
	<#
	.SYNOPSIS
		Adds a parameter to a command.
	.DESCRIPTION
		Adds a parameter to a command. If Switch is set to true, only the switch parameter is added. If Switch is set to false, the parameter is added with the given value if the value is not empty.
	.PARAMETER Command
		Full command that will be returned.
	.PARAMETER Name
		Name of the switch parameter.
	.PARAMETER Switch
		Switch parameter value.
	.PARAMETER Value
		Value of the parameter.
	.OUTPUTS
		Full command as string.
	.EXAMPLE
		$command = Add-NxtParameterToCommand -Command $command -Name "AllowDefer" -Switch $true
	.EXAMPLE
		$command = Add-NxtParameterToCommand -Command $command -Name "AllowDefer" -Value "text"
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Command,
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		[Parameter(Mandatory = $true, ParameterSetName = 'Switch')]
		[bool]
		$Switch,
		[Parameter(Mandatory = $true, ParameterSetName = 'Value')]
		[string]
		[AllowEmptyString()]
		$Value
		)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ($true -eq $Switch) {
			$Command += " -$Name"
		}
		elseif ($false -eq [string]::IsNullOrEmpty($Value)) {
			$Command += " -$Name `"$Value`""
		}
		Write-Output $Command
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Compare-NxtVersion
function Compare-NxtVersion {
	<#
	.SYNOPSIS
		Compare two versions.
	.DESCRIPTION
		Compare two versions. A Version can contain up to 4 numbers separated by dots. If a version contains less than 4 numbers, the missing numbers are assumed to be 0. If a VersionPart contains non-numeric characters, the 	VersionPart is assumed to be a string. If there are more than 4 VersionParts, the subsequent VersionParts are ignored. HexMode can be used to compare VersionParts as hexadecimal numbers.
		Return values:
			Equal = 1
			Update = 2
			Downgrade = 3.
	.PARAMETER DetectedVersion
		The version that was detected.
	.PARAMETER TargetVersion
		The version that is targeted.
	.PARAMETER HexMode
		If set to true, the VersionParts are compared as hexadecimal numbers if possible.
		Default is false.
	.EXAMPLE
		Compare-NxtVersion -DetectedVersion "1.2.3.4" -TargetVersion "1.2.4.4"
		Will return "Update" because "3" is smaller than "4".
	.EXAMPLE
		Compare-NxtVersion -DetectedVersion "1.2.3" -TargetVersion "1.2.3"
		Will return "Equal" because all VersionParts are equal to the referencing value.
	.EXAMPLE
		Compare-NxtVersion -DetectedVersion "1.2.3" -TargetVersion "a.2.3"
		Will return "Update" because "1" is smaller than "a" in string comparison.
	.EXAMPLE
		Compare-NxtVersion -DetectedVersion "F43.1.A9" -TargetVersion "F43.1.A10" -HexMode $true
		Will return "Update" because "A9" is smaller than "A10" in hexadecimal mode.
	.EXAMPLE
		Compare-NxtVersion -DetectedVersion "F43.1.A9" -TargetVersion "F43.1.A10"
		Will return "Downgrade" because "A9" is greater than "A10" in string mode.
	.EXAMPLE
		Compare-NxtVersion -DetectedVersion "F43.1.a2" -TargetVersion "F43.1.A2"
		Will return "Equal" because "a2" is equal to "A2".
	.EXAMPLE
		Compare-NxtVersion -DetectedVersion "x" -TargetVersion "y"
		Will return "Update" because "x" is smaller than "y".
	.EXAMPLE
		Compare-NxtVersion -DetectedVersion "1.1.1.0.1" -TargetVersion "1.1.1.0.2"
		Will return "Equal" because because only the first 4 VersionParts are compared.
	.EXAMPLE
		Compare-NxtVersion -DetectedVersion "0001.2" -TargetVersion "1.2"
		Will return "Equal" because "0001" is equal to "1".
	.EXAMPLE
		Compare-NxtVersion -DetectedVersion "A.2" -TargetVersion "1A.2"
		Will return "Downgrade" because "A" is greater than "1A" in string mode.
	.EXAMPLE
		Compare-NxtVersion -DetectedVersion "A.2" -TargetVersion "1A.2" -HexMode $true
		Will return "Update" because "A" is smaller than "1A" in hexadecimal mode.
	.EXAMPLE
		Compare-NxtVersion -DetectedVersion "1.2" -TargetVersion "1"
		Will return "Downgrade" because "1.2" is greater than "1".
	.OUTPUTS
		PSADTNXT.VersionCompareResult.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter()]
		[String]
		$DetectedVersion,
		[Parameter()]
		[String]
		$TargetVersion,
		[Parameter()]
		[bool]
		$HexMode = $false
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[string[]]$detectedVersionParts = $DetectedVersion -split "\." | Select-Object -First 4
		[string[]]$targetVersionParts = $TargetVersion -split "\." | Select-Object -First 4
		[int]$versionPartCount = [Math]::Max([Math]::Max($detectedVersionParts.Count, $targetVersionParts.Count),4)
		[PSADTNXT.VersionCompareResult[]]$versionPartResult = (, [PSADTNXT.VersionCompareResult]::Equal) * 4
		for ($i = 0; $i -lt $versionPartCount; $i++) {
			[string]$detectedVersionPart = $detectedVersionParts | Select-Object -Index $i
			[string]$targetVersionPart = $targetVersionParts | Select-Object -Index $i
			$versionPartResult[$i] = Compare-NxtVersionPart -DetectedVersionPart $detectedVersionPart -TargetVersionPart $targetVersionPart -HexMode $HexMode
		}
		[PSADTNXT.VersionCompareResult]$result = [PSADTNXT.VersionCompareResult]::Equal
		## the first result that is not "Equal" is the result for the whole version
		foreach ($versionPart in $versionPartResult) {
			if ($versionPart -ne [PSADTNXT.VersionCompareResult]::Equal) {
				$result = $versionPart
				## stop the whole loop
				break
			}
		}
		Write-Log -Message "Compare version $DetectedVersion with $TargetVersion. Result: $result" -Source ${cmdletName}
		Write-Output $result
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Compare-NxtVersionPart
function Compare-NxtVersionPart {
	<#
	.SYNOPSIS
		Compare two version parts.
	.DESCRIPTION
		Compare two version parts. A VersionPart can be a number or a string. If a VersionPart contains non-numeric characters, the VersionPart is assumed to be a string.
		Return values:
		Equal = 1
		Update = 2
		Downgrade = 3
	.PARAMETER DetectedVersionPart
		The version part that was detected.
	.PARAMETER TargetVersionPart
		The version part that is targeted.
	.PARAMETER HexMode
		If set to true, the VersionParts are compared as hexadecimal numbers.
		Default is false.
	.EXAMPLE
		Compare-NxtVersionPart -DetectedVersionPart "1" -TargetVersionPart "2"
		Will return "Update" because "1" is smaller than "2".
	.EXAMPLE
		Compare-NxtVersionPart -DetectedVersionPart "1" -TargetVersionPart "1"
		Will return "Equal" because "1" is equal to "1".
	.EXAMPLE
		Compare-NxtVersionPart -DetectedVersionPart "1" -TargetVersionPart "a"
		Will return "Update" because "1" is smaller than "a" in string comparison.
	.EXAMPLE
		Compare-NxtVersionPart -DetectedVersionPart "1" -TargetVersionPart "b" -HexMode $true
		Will return "Update" because "1" is smaller than "b" in hexadecimal mode.
	.OUTPUTS
		PSADTNXT.VersionCompareResult.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter()]
		[string]
		$DetectedVersionPart,
		[Parameter()]
		[string]
		$TargetVersionPart,
		[Parameter()]
		[bool]
		$HexMode
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ($true -eq ([string]::IsNullOrEmpty($DetectedVersionPart))) {
			$DetectedVersionPart = "0"
		}
		if ($true -eq ([string]::IsNullOrEmpty($TargetVersionPart))) {
			$TargetVersionPart = "0"
		}
		[int]$detectedVersionPartInt = 0
		[int]$targetVersionPartInt = 0
		## Test if both VersionParts are numeric
		if (
			[int]::TryParse($DetectedVersionPart, [ref]$detectedVersionPartInt) -and
			[int]::TryParse($TargetVersionPart, [ref]$targetVersionPartInt)
			) {
			if ($detectedVersionPartInt -eq $targetVersionPartInt) {
				Write-Output ([PSADTNXT.VersionCompareResult]::Equal)
			}
			elseif ($detectedVersionPartInt -gt $targetVersionPartInt) {
				Write-Output ([PSADTNXT.VersionCompareResult]::Downgrade)
			}
			elseif ($detectedVersionPartInt -lt $targetVersionPartInt) {
				Write-Output ([PSADTNXT.VersionCompareResult]::Update)
			}
			return
		}
		if ($true -eq $HexMode) {
			## Test if any VersionParts contain non-hex parsable characters
			if (
				[int]::TryParse($DetectedVersionPart, [System.Globalization.NumberStyles]::HexNumber, $null, [ref]$detectedVersionPartInt) -and
				[int]::TryParse($TargetVersionPart, [System.Globalization.NumberStyles]::HexNumber, $null, [ref]$targetVersionPartInt)
			) {
				if ($detectedVersionPartInt -eq $targetVersionPartInt) {
					Write-Output ([PSADTNXT.VersionCompareResult]::Equal)
				}
				elseif ($detectedVersionPartInt -gt $targetVersionPartInt) {
					Write-Output ([PSADTNXT.VersionCompareResult]::Downgrade)
				}
				elseif ($detectedVersionPartInt -lt $targetVersionPartInt) {
					Write-Output ([PSADTNXT.VersionCompareResult]::Update)
				}
				return
			}
		}
		## do a string comparison if the VersionParts are not numeric or hex parsable
		if ($DetectedVersionPart -eq $TargetVersionPart) {
			Write-Output ([PSADTNXT.VersionCompareResult]::Equal)
		}
		elseif ($DetectedVersionPart -gt $TargetVersionPart) {
			Write-Output ([PSADTNXT.VersionCompareResult]::Downgrade)
		}
		elseif ($DetectedVersionPart -lt $TargetVersionPart) {
			Write-Output ([PSADTNXT.VersionCompareResult]::Update)
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
		Defines the required steps to finalize the installation of the current package
	.DESCRIPTION
		The Complete-NxtPackageInstallation function is designed to finalize the installation steps for a package.
		It primarily deals with various aspects like copying/removing desktop shortcuts, hiding uninstall keys,
		setting up active user setups, and ensuring the successful post-installation of a package.
		Always consider using the "CustomXXXX" entry points for script customization rather than modifying this function.
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
	.PARAMETER StartMenuShortcutsToCopyToDesktop
		Specifies the links from the start menu which should be copied to the desktop.
		Defaults to the CommonStartMenuShortcutsToCopyToCommonDesktop array defined in the neo42PackageConfig.json.
	.PARAMETER Desktop
		Determines the path to the Desktop, e.g., $envCommonDesktop or $envUserDesktop.
		Defaults to $envCommonDesktop.
	.PARAMETER StartMenu
		Defines the path to the Start Menu, e.g., $envCommonStartMenu or $envUserStartMenu.
		Defaults to $envCommonStartMenu.T
	.PARAMETER UserPartDir
		Defines the subpath to the UserPart directory.
		Defaults to $global:UserPartDir.
	.PARAMETER Wow6432Node
		Switches between 32/64 Bit Registry Keys.
		Defaults to the Variable $global:Wow6432Node populated by Set-NxtPackageArchitecture.
	.PARAMETER ScriptRoot
		Defines the parent directory of the script.
		Defaults to the Variable $scriptRoot populated by AppDeployToolkitMain.ps1.
	.PARAMETER AppName
		Defines the name of the application.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppVendor
		Defines the name of the application vendor.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER LegacyAppRoots
		Defines the legacy application roots.
		Defaults to $envProgramFiles and $envProgramFilesX86.
	.PARAMETER ExecutionPolicy
		Defines the execution policy of the active setup PowerShell script.
		Defaults to the corresponding value from the XML configuration file.
	.PARAMETER AppRootFolder
		Defines the root folder of the application package. This parameter is mandatory.
		Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Complete-NxtPackageInstallation
	.OUTPUTS
		none.
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
		[array]
		$StartMenuShortcutsToCopyToDesktop = $global:PackageConfig.CommonStartMenuShortcutsToCopyToCommonDesktop,
		[Parameter(Mandatory = $false)]
		[string[]]
		$DesktopShortcutsToDelete = $global:PackageConfig.CommonDesktopShortcutsToDelete,
		[Parameter(Mandatory = $false)]
		[string]
		$Desktop = $envCommonDesktop,
		[Parameter(Mandatory = $false)]
		[string]
		$StartMenu = $envCommonStartMenu,
		[Parameter(Mandatory = $false)]
		[string]
		$Wow6432Node = $global:Wow6432Node,
		[Parameter(Mandatory = $false)]
		[string]
		$UserPartDir = $global:UserPartDir,
		[Parameter(Mandatory = $false)]
		[string]
		$ScriptRoot = $scriptRoot,
		[Parameter(Mandatory = $false)]
		[string]
		$AppName = $global:PackageConfig.AppName,
		[Parameter(Mandatory = $false)]
		[string]
		$AppVendor = $global:PackageConfig.AppVendor,
		[Parameter(Mandatory = $false)]
		[string[]]
		$LegacyAppRoots= @("$envProgramFiles\neoPackages", "$envProgramFilesX86\neoPackages"),
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]
		$ExecutionPolicy = $xmlConfigFile.AppDeployToolkit_Config.NxtPowerShell_Options.NxtPowerShell_ExecutionPolicy,
		[Parameter(Mandatory = $false)]
		[string]
		$AppRootFolder = $global:PackageConfig.AppRootFolder
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		Remove-NxtDesktopShortcuts -DesktopShortcutsToDelete $DesktopShortcutsToDelete -Desktop $Desktop
		if ($true -eq $DesktopShortcut) {
			Copy-NxtDesktopShortcuts -StartMenuShortcutsToCopyToDesktop $StartMenuShortcutsToCopyToDesktop -Desktop $Desktop -StartMenu $StartMenu
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
				if ($true -eq $Is64Bit) {
					[bool]$thisUninstallKeyToHideIs64Bit = $true
				}
				## in case of $AppArch="*" and running on x86 system
				else {
					[bool]$thisUninstallKeyToHideIs64Bit = $false
				}
			}
			Write-Log -Message "Searching for uninstall key with KeyName [$($uninstallKeyToHide.KeyName)], Is64Bit [$thisUninstallKeyToHideIs64Bit], KeyNameIsDisplayName [$($uninstallKeyToHide.KeyNameIsDisplayName)], KeyNameContainsWildCards [$($uninstallKeyToHide.KeyNameContainsWildCards)] and DisplayNamesToExcludeFromHiding [$($uninstallKeyToHide.DisplayNamesToExcludeFromHiding -join "][")]..." -Source ${CmdletName}
			[array]$installedAppResults = Get-NxtInstalledApplication @hideNxtParams | Where-Object Is64BitApplication -eq $thisUninstallKeyToHideIs64Bit
			if ($installedAppResults.Count -eq 1) {
				Write-Log -Message "Hiding uninstall key with KeyName [$($installedAppResults.UninstallSubkey)]" -Source ${CmdletName}
				[string]$wowEntry = [string]::Empty
				if ($false -eq $thisUninstallKeyToHideIs64Bit -and $true -eq $Is64Bit) {
					[string]$wowEntry = "\Wow6432Node"
				}
				Set-RegistryKey -Key "HKLM:\Software$wowEntry\Microsoft\Windows\CurrentVersion\Uninstall\$($installedAppResults.UninstallSubkey)" -Name "SystemComponent" -Type "Dword" -Value "1"
			}
			else {
				Write-Log -Message "Uninstall key search resulted in $($installedAppResults.Count) findings. No uninstall key will be hidden because unique result is required." -Severity 2 -Source ${CmdletName}
			}
		}
		if ($true -eq $UserPartOnInstallation) {
			if ($true -eq ([string]::IsNullOrEmpty($UserPartRevision))) {
				Write-Log -Message "UserPartRevision is empty. Please define a UserPartRevision in your config. Aborting package completion." -Source ${CmdletName}
				throw "UserPartRevision is empty. Please define a UserPartRevision in your config. Aborting package completion."
			}
			## Userpart-Installation: Copy all needed files to "...\SupportFiles\$UserpartDir\" and add more needed tasks per user commands to the CustomInstallUserPart*-functions inside of main script.
			Set-ActiveSetup -PurgeActiveSetupKey -Key "$PackageGUID.uninstall"
			if ($true -eq (Test-Path -Path "$dirSupportFiles\$UserpartDir")) {
				Copy-File -Path "$dirSupportFiles\$UserpartDir\*" -Destination "$App\$UserpartDir\SupportFiles" -Recurse
			}
			else {
				New-Folder -Path "$App\$UserpartDir\SupportFiles"
			}
			Copy-File -Path "$ScriptRoot\$($xmlConfigFile.GetElementsByTagName('BannerIcon_Options').Icon_Filename)" -Destination "$App\$UserpartDir\"
			Copy-Item -Path "$scriptDirectory\*" -Exclude "Files", "SupportFiles" -Destination "$App\$UserpartDir\" -Recurse -Force -ErrorAction Continue | Out-Null
			if ($true -eq (Test-Path -Path "$App\neo42-Install\Setup.cfg")) {
				Copy-File -Path "$App\neo42-Install\Setup.cfg" -Destination "$App\$UserpartDir\"
			}
			Update-NxtXmlNode -FilePath "$App\$UserpartDir\$(Split-Path "$ScriptRoot" -Leaf)\$(Split-Path "$appDeployConfigFile" -Leaf)" -NodePath "/AppDeployToolkit_Config/Toolkit_Options/Toolkit_RequireAdmin" -InnerText "False"
			Update-NxtXmlNode -FilePath "$App\$UserpartDir\$(Split-Path "$ScriptRoot" -Leaf)\$(Split-Path "$appDeployConfigFile" -Leaf)" -NodePath "/AppDeployToolkit_Config/UI_Options/ShowBalloonNotifications" -InnerText "False"
			if ($true -eq (Test-Path "$App\$UserpartDir\DeployNxtApplication.exe")) {
				Set-ActiveSetup -StubExePath "$App\$UserpartDir\DeployNxtApplication.exe" -Arguments "TriggerInstallUserpart" -Version $UserPartRevision -Key "$PackageGUID"
			}
			else {
				Set-ActiveSetup -StubExePath "$env:Systemroot\System32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy $ExecutionPolicy -NonInteractive -NoProfile -File ""$App\$UserpartDir\Deploy-Application.ps1"" TriggerInstallUserpart" -Version $UserPartRevision -Key "$PackageGUID"
			}
		}
		foreach ($oldAppFolder in $((Get-ChildItem -Path (Get-Item -Path $App).Parent.FullName | Where-Object Name -ne (Get-Item -Path $App).Name).FullName)) {
			## note: we always use the script from current application package source folder (it is basically identical in each package)
			Copy-File -Path "$ScriptRoot\Clean-Neo42AppFolder.ps1" -Destination "$oldAppFolder\"
			Start-Sleep -Seconds 1
			[hashtable]$executeProcessSplat = @{
				Path = 'powershell.exe'
				Parameters = "-ExecutionPolicy $ExecutionPolicy -NonInteractive -File `"$oldAppFolder\Clean-Neo42AppFolder.ps1`""
				NoWait = $true
				WorkingDirectory = $env:TEMP
				ExitOnProcessFailure = $false
				PassThru = $true
			}
			## we use $env:temp es workingdirectory to avoid issues with locked directories
			if (
				$false -eq [string]::IsNullOrEmpty($AppRootFolder) -and
				$false -eq [string]::IsNullOrEmpty($AppVendor)
			) {
				$executeProcessSplat["Parameters"] = Add-NxtParameterToCommand -Command $executeProcessSplat["Parameters"] -Name "RootPathToRecurseUpTo" -Value "$AppRootFolder\$AppVendor"
			}
			Execute-Process @executeProcessSplat | Out-Null
		}
		## Cleanup legacy package folders
		foreach ($legacyAppRoot in $LegacyAppRoots) {
			if ($true -eq (Test-Path -Path $legacyAppRoot ) -and [System.IO.Path]::IsPathRooted($legacyAppRoot)) {
				if ($true -eq (Test-Path -Path $legacyAppRoot\$AppVendor)) {
					if ($true -eq (Test-Path -Path $legacyAppRoot\$AppVendor\$AppName)) {
						Write-Log -Message "Removing legacy application folder $legacyAppRoot\$AppVendor\$AppName" -Source ${CmdletName}
						Remove-Folder -Path $legacyAppRoot\$AppVendor\$AppName -ContinueOnError $true
					}
					Remove-NxtEmptyFolder -Path $legacyAppRoot\$AppVendor
				}
				Remove-NxtEmptyFolder -Path $legacyAppRoot
			}
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
		Completes the required steps to finalize the uninstallation of a package.
	.DESCRIPTION
		The Complete-NxtPackageUninstallation function performs the necessary actions to finalize the uninstallation of a given package.
		This includes removing desktop shortcuts and handling user-specific uninstallation tasks if specified.
		Always consider using the "CustomXXXX" entry points for script customization rather than modifying this function.
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
	.PARAMETER UserPartDir
		Defines the subpath to the UserPart directory.
		Defaults to $global:UserPartDir.
	.PARAMETER ScriptRoot
		Defines the parent directory of the script.
		Defaults to the Variable $scriptRoot populated by AppDeployToolkitMain.ps1.
	.PARAMETER DesktopShortcutsToDelete
		Specifies the desktop shortcuts that should be deleted.
		Defaults to the CommonDesktopShortcutsToDelete array defined in the neo42PackageConfig.json.
	.PARAMETER StartMenuShortcuts
		Specifies the links from the start menu which were copied to the desktop and should be deleted as well.
		Defaults to the CommonStartMenuShortcutsToCopyToCommonDesktop array defined in the neo42PackageConfig.json.
	.PARAMETER ExecutionPolicy
		Defines the execution policy of the active setup PowerShell script.
		Defaults to the corresponding value from the XML configuration file.
	.EXAMPLE
		Complete-NxtPackageUninstallation
	.EXAMPLE
		Complete-NxtPackageUninstallation -UserPartOnUninstallation $true -UserPartDir "UserDirectory"
	.OUTPUTS
		none.
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
		$UserPartRevision = $global:PackageConfig.UserPartRevision,
		[Parameter(Mandatory = $false)]
		[string]
		$UserPartDir = $global:UserPartDir,
		[Parameter(Mandatory = $false)]
		[string]
		$ScriptRoot = $scriptRoot,
		[Parameter(Mandatory = $false)]
		[string[]]
		$DesktopShortcutsToDelete = $global:PackageConfig.CommonDesktopShortcutsToDelete,
		[Parameter(Mandatory = $false)]
		[object[]]
		$StartMenuShortcuts = $global:PackageConfig.CommonStartMenuShortcutsToCopyToCommonDesktop,
		[Parameter(Mandatory = $false)]
		[string]
		$Desktop = $envCommonDesktop,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]
		$ExecutionPolicy = $xmlConfigFile.AppDeployToolkit_Config.NxtPowerShell_Options.NxtPowerShell_ExecutionPolicy
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		Remove-NxtDesktopShortcuts -DesktopShortcutsToDelete $DesktopShortcutsToDelete -Desktop $Desktop
		## Cleanup our shortcuts
		[string[]]$shortCutsFromCopyToDesktop = $StartMenuShortcuts | ForEach-Object {
			if ($false -eq [string]::IsNullOrEmpty($_.TargetName)) {
				Write-Output $_.TargetName
			}
			else {
				Write-Output (Split-Path -Path $_.Source -Leaf)
			}
		}
		Remove-NxtDesktopShortcuts -DesktopShortcutsToDelete $shortCutsFromCopyToDesktop -Desktop $Desktop
		Set-ActiveSetup -PurgeActiveSetupKey -Key "$PackageGUID"
		if ($true -eq $UserPartOnUninstallation) {
			if ($true -eq ([string]::IsNullOrEmpty($UserPartRevision))) {
				Write-Log -Message "UserPartRevision is empty. Please define a UserPartRevision in your config. Aborting package completion." -Source ${CmdletName}
				throw "UserPartRevision is empty. Please define a UserPartRevision in your config. Aborting package completion."
			}
			## Userpart-Uninstallation: Copy all needed files to "...\SupportFiles\$UserpartDir\" and add more needed tasks per user commands to the CustomUninstallUserPart*-functions inside of main script.
			if ($true -eq (Test-Path -Path "$dirSupportFiles\$UserpartDir")) {
				Copy-File -Path "$dirSupportFiles\$UserpartDir\*" -Destination "$App\$UserpartDir\SupportFiles" -Recurse
			}
			else {
				New-Folder -Path "$App\$UserpartDir\SupportFiles"
			}
			Copy-File -Path "$ScriptRoot\$($xmlConfigFile.GetElementsByTagName('BannerIcon_Options').Icon_Filename)" -Destination "$App\$UserpartDir\"
			Copy-Item -Path "$scriptDirectory\*" -Exclude "Files", "SupportFiles" -Destination "$App\$UserpartDir\" -Recurse -Force -ErrorAction Continue
			if ($true -eq (Test-Path -Path "$App\neo42-Install\Setup.cfg")) {
				Copy-File -Path "$App\neo42-Install\Setup.cfg" -Destination "$App\$UserpartDir\"
			}
			Update-NxtXmlNode -FilePath "$App\$UserpartDir\$(Split-Path "$ScriptRoot" -Leaf)\$(Split-Path "$appDeployConfigFile" -Leaf)" -NodePath "/AppDeployToolkit_Config/Toolkit_Options/Toolkit_RequireAdmin" -InnerText "False"
			Update-NxtXmlNode -FilePath "$App\$UserpartDir\$(Split-Path "$ScriptRoot" -Leaf)\$(Split-Path "$appDeployConfigFile" -Leaf)" -NodePath "/AppDeployToolkit_Config/UI_Options/ShowBalloonNotifications" -InnerText "False"
			if ($true -eq (Test-Path "$App\$UserpartDir\DeployNxtApplication.exe")) {
				Set-ActiveSetup -StubExePath "$App\$UserpartDir\DeployNxtApplication.exe" -Arguments "TriggerUninstallUserpart" -Version $UserPartRevision -Key "$PackageGUID.uninstall"
			}
			else {
				Set-ActiveSetup -StubExePath "$env:Systemroot\System32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy $ExecutionPolicy -NonInteractive -NoProfile -File `"$App\$UserpartDir\Deploy-Application.ps1`" TriggerUninstallUserpart" -Version $UserPartRevision -Key "$PackageGUID.uninstall"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function ConvertFrom-NxtEncodedObject
function ConvertFrom-NxtEncodedObject {
	<#
	.SYNOPSIS
		Converts a Base64-encoded and gzip-compressed JSON object string into a PowerShell object.
	.DESCRIPTION
		The ConvertFrom-NxtEncodedObject function decodes a given Base64-encoded and gzip-compressed string that represents a JSON-serialized object. It returns the decompressed and deserialized PowerShell object. This function is particularly useful in data transport scenarios where JSON objects have been serialized, compressed, and then encoded for safe transmission.
	.PARAMETER EncodedObject
		The Base64-encoded and gzip-compressed string that you want to convert back into a PowerShell object. This parameter is mandatory.
	.EXAMPLE
		$encodedObj = "H4sIAAAAAAAEAIuuVnLPLEvN80vMTVWyUvLKz8hT0lEKLi2CCrjkpyrV6qAq8k2sQFHjW1pcklqUm5iXp1QbCwCmtj3MUQAAAA=="
		$decodedObj = ConvertFrom-NxtEncodedObject -EncodedObject $encodedObj
		This example demonstrates how to decode a Base64-encoded and gzip-compressed JSON string into a PowerShell object.
	.OUTPUTS
		System.Object
	.NOTES
		Ensure that the EncodedObject parameter contains a valid, gzip-compressed and Base64-encoded string. Invalid or malformed input can result in errors.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[string]
		$EncodedObject
	)
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[byte[]]$decodedBytes = [Convert]::FromBase64String($EncodedObject)
			[System.IO.MemoryStream]$inputStream = New-Object System.IO.MemoryStream($decodedBytes, 0, $decodedBytes.Length)
			[System.IO.Compression.GZipStream]$gzipStream = New-Object System.IO.Compression.GZipStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)
			[System.IO.StreamReader]$reader = New-Object System.IO.StreamReader($gzipStream)
			[string]$decompressedString = $reader.ReadToEnd()
			$reader.Close()
			[System.Object]$psObject = $decompressedString | ConvertFrom-Json
			Write-Output $psObject
		}
		catch {
			Write-Log -Message "Failed to convert Base64-encoded string to PowerShell object. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			throw "Failed to convert Base64-encoded string to PowerShell object. `n$(Resolve-Error)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function ConvertFrom-NxtEscapedString
function ConvertFrom-NxtEscapedString {
	<#
	.SYNOPSIS
		Converts an escaped string into a list of components.
	.DESCRIPTION
		The ConvertFrom-NxtEscapedString function converts an escaped string into a list of string components split by whitespace characters.
		Helpful when you need specific parts of a string that are separated by whitespace characters and the string itself contains escaped characters.
	.PARAMETER InputString
		The escaped string that you want to convert into a list of components. This parameter is mandatory.
	.EXAMPLE
		ConvertFrom-NxtEscapedString -InputString 'C:\my\ program.exe -Argument1 "Value 1" -Argument2 ''Value 2'' -Argument3 Value\ 3'
	.OUTPUTS
		[string[]]
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[Alias('EscapedString')]
		[string]
		$InputString
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[string[]]$result = $InputString -split '(?<!\\) (?=(?:[^"]|"[^"]*")*$)(?=(?:[^'']|''[^'']*'')*$)'
			Write-Log "Converted escaped string to list of components with $($result.Count) members." -Source ${cmdletName}
			Write-Output ($result -replace '^[''"]|[''"]$', [string]::Empty -replace '\\ ', ' ')
		}
		catch {
			Write-Log -Message "Failed to convert escaped string to list of components. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
			throw "Failed to convert escaped string to list of components. `n$(Resolve-Error)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function ConvertFrom-NxtJsonC
function ConvertFrom-NxtJsonC {
	<#
	.SYNOPSIS
		Converts a JSON string with comments into a PowerShell object.
	.DESCRIPTION
		The ConvertFrom-NxtJsonC function converts a JSON string with comments into a PowerShell object.
		Comments are removed from the JSON string before conversion and are not included in the resulting object.
	.PARAMETER InputObject
		The JSON string with comments that you want to convert into a PowerShell object.
		This value can be piped to the function and is mandatory.
	.EXAMPLE
		"{
			// This is a comment
			"Name": "John",
			"Age": 30
		}" | ConvertFrom-NxtJsonC
	.OUTPUTS
		[System.Management.Automation.PSCustomObject]
	.NOTES
		Starting with PowerShell 6.0, the ConvertFrom-Json cmdlet supports JSON strings with comments.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[string]
		$InputObject
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			if ($PSVersionTable.PSVersion.Major -ge 6) {
				Write-Output ($InputObject | ConvertFrom-Json -ErrorAction Stop)
			}
			else {
				Write-Output ($InputObject -replace '("(\\.|[^\\"])*")|\/\*[\S\s]*?\*\/|\/\/.*', '$1' | ConvertFrom-Json -ErrorAction Stop)
			}
		}
		catch {
			Write-Log -Message "Failed to convert JSON string with comments to PowerShell object. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
			throw "Failed to convert JSON string with comments to PowerShell object. `n$(Resolve-Error)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function ConvertTo-NxtInstallerProductCode
function ConvertTo-NxtInstallerProductCode {
	<#
	.SYNOPSIS
		Converts a product GUID into an installer product code.
	.DESCRIPTION
		The ConvertTo-NxtInstallerProductCode function converts a product GUID into an installer product code.
		This function is useful when you need to retrieve the installer product code for a given product GUID.
	.PARAMETER ProductGuid
		The product GUID that you want to convert into an installer product code. This parameter is mandatory.
	.EXAMPLE
		$ProductCode = ConvertTo-NxtInstallerProductCode -ProductGuid "{12345678-1234-1234-1234-123456789012}"
	.OUTPUTS
		System.String
	.NOTES
		Ensure that the ProductGuid parameter contains a valid GUID. Invalid or malformed input can result in errors.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[guid]
		$ProductGuid
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name

		[int[]]$charIndex = 7,6,5,4,3,2,1,0,11,10,9,8,15,14,13,12,17,16,19,18,21,20,23,22,25,24,27,26,29,28,31,30
	}
	Process {
		[string]$productGuidChars = [regex]::replace($ProductGuid.Guid, "[^a-zA-Z0-9]", "")
		return (
			$charIndex | ForEach-Object {
				$productGuidChars[$_]
			}
		) -join [string]::Empty
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function ConvertTo-NxtEncodedObject
function ConvertTo-NxtEncodedObject {
	<#
	.SYNOPSIS
		Converts a PowerShell object into a Base64-encoded and gzip-compressed JSON object string.
	.DESCRIPTION
		The ConvertTo-NxtEncodedObject function takes a PowerShell object as input and performs three main operations:
		1. Serializes the object into a JSON string.
		2. Compresses the JSON string using gzip.
		3. Encodes the compressed data into a Base64 string.
		This function is useful for securely and efficiently transmitting PowerShell objects over a network or storing them.
		It is not as exact as Export-clixml but the output is much smaller and safe to transfer on a command line.
		It is not required to write the resulting string to a file as long as it does not exceed the maximum command line length.
	.PARAMETER Object
		The PowerShell object that you want to convert into a Base64-encoded and gzip-compressed string.
		This parameter is mandatory.
	.PARAMETER Depth
		The depth of object hierarchy to include in the JSON serialization. By default, this is set to 2.
		This parameter is optional.
	.EXAMPLE
		$psObject = [PSCustomObject]@{ Name = 'John'; Age = 30; }
		$encodedObj = ConvertTo-NxtEncodedObject -Object $psObject
		This example shows how to convert a simple PowerShell object into a Base64-encoded and gzip-compressed string.
	.EXAMPLE
		$nestedObject = @{
			Name = 'Jane'
			Details = @{
				Age = 25
				Occupation = 'Engineer'
			}
		}
		$encodedObj = ConvertTo-NxtEncodedObject -Object $nestedObject -Depth 3
		This example demonstrates how to convert a nested PowerShell object into a Base64-encoded and gzip-compressed string by specifying the depth parameter.
	.OUTPUTS
		System.String
	.NOTES
		The "Depth" parameter controls the depth of object hierarchy to include in JSON serialization. Be cautious when setting this to a large value as it may result in large strings.
	.LINK
		For more information, refer to [System.IO.Compression.GZipStream] and [ConvertTo-Json].
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[PSObject]
		$Object,
		[Parameter(Mandatory=$false)]
		[int]
		$Depth = 2
	)
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[string]$jsonString = $Object | ConvertTo-Json -Compress -Depth $Depth
			[System.IO.MemoryStream]$compressedData = New-Object System.IO.MemoryStream
			[System.IO.Compression.GZipStream]$gzipStream = New-Object System.IO.Compression.GZipStream($compressedData, [System.IO.Compression.CompressionMode]::Compress)
			[System.IO.StreamWriter]$writer = New-Object System.IO.StreamWriter($gzipStream)
			$writer.Write($jsonString)
			$writer.Close()
			[string]$encodedObject = [Convert]::ToBase64String($compressedData.ToArray())
			Write-Output $encodedObject
		}
		catch {
			Write-Log -Message "Failed to convert PowerShell object to Base64-encoded string. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			throw "Failed to convert PowerShell object to Base64-encoded string. `n$(Resolve-Error)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Copy-NxtDesktopShortcuts
function Copy-NxtDesktopShortcuts {
	<#
	.SYNOPSIS
		Copies specific shortcuts from the Start Menu to the Desktop.
	.DESCRIPTION
		The Copy-NxtDesktopShortcuts function copies the specified shortcuts from the Start Menu to the Desktop.
		This function is invoked after an installation or reinstallation when DESKTOPSHORTCUT=1 is specified in the Setup.cfg.
		By default it copies the shortcuts defined under "CommonStartMenuShortcutsToCopyToCommonDesktop" in the neo42PackageConfig.json to the common desktop.
	.PARAMETER StartMenuShortcutsToCopyToDesktop
		Specifies the links from the start menu which should be copied to the desktop.
		Defaults to the CommonStartMenuShortcutsToCopyToCommonDesktop array defined in the neo42PackageConfig.json.
	.PARAMETER Desktop
		Determines the path to the Desktop, e.g., $envCommonDesktop or $envUserDesktop.
		Defaults to $envCommonDesktop.
	.PARAMETER StartMenu
		Defines the path to the Start Menu, e.g., $envCommonStartMenu or $envUserStartMenu.
		Defaults to $envCommonStartMenu.
	.EXAMPLE
		Copy-NxtDesktopShortcuts
	.EXAMPLE
		Copy-NxtDesktopShortcuts -Desktop "$envUserDesktop" -StartMenu "$envUserStartMenu"
	.EXAMPLE
		Copy-NxtDesktopShortcuts -StartMenuShortcutsToCopyToDesktop @({'Source'='App.lnk'; 'TargetName'='App_Desktop.lnk'})
	.OUTPUTS
		none.
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
				if ($true -eq [string]::IsNullOrEmpty($value.Source)) {
					Write-Log -Message "Source is empty. Skipping copy of shortcut." -Severity 1 -Source ${cmdletName}
					continue
				}
				Write-Log -Message "Copying start menu shortcut '$StartMenu\$($value.Source)' to '$Desktop'..." -Source ${cmdletName}
				if ($true -eq $(Test-Path -Path "$StartMenu\$($value.Source)")) {
					Copy-File -Path "$StartMenu\$($value.Source)" -Destination "$Desktop\$($value.TargetName)"
					Write-Log -Message "Shortcut succesfully copied." -Source ${cmdletName}
				}
				else {
					Write-Log -Message "Shortcut '$StartMenu$($value.Source)' not found. Skipping copy." -Severity 2 -Source ${cmdletName}
				}
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
#region Function Clear-NxtTempFolder
function Clear-NxtTempFolder {
	<#
	.SYNOPSIS
		Cleans the specified temporary directory by removing files and folders older than a specified age. Also all paths in $script:NxtTempDirectories array will be deleted.
	.DESCRIPTION
		The Clear-NxtTempFolder function is designed to maintain cleanliness and manage space in a specified temporary directory and the paths in the $script:NxtTempDirectories array.
		It systematically scans the directory and deletes all files and folders that are older than a predefined number of hours, helping to prevent unnecessary data buildup and potential performance issues.
	.PARAMETER TempRootFolder
		The path to the temporary folder targeted for cleaning. To ensure that all internal processes work correctly it is highly recommended to keep the default value!
		Defaults to $env:SystemDrive\n42Tmp.
	.PARAMETER HoursToKeep
		The age threshold, in hours, for retaining files and folders in the temporary folder. Files and folders older than this threshold will be deleted.
		Defaults to 96 (4 days).
	.PARAMETER NxtTempDirectories
		An array of paths to folders which should be cleared even if the HoursToKeep are not reached.
		Defaults to $script:NxtTempDirectories.
	.EXAMPLE
		Clear-NxtTempFolder
		This example executes the function with default parameters, clearing files and folders older than 96 hours from the $env:SystemDrive\n42Tmp folder.
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$TempRootFolder = "$env:SystemDrive\n42Tmp",
		[Parameter(Mandatory = $false)]
		[int]
		$HoursToKeep = 96,
		[Parameter(Mandatory = $false)]
		[string[]]
		$NxtTempDirectories = $script:NxtTempDirectories
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ($true -eq [string]::IsNullOrEmpty($TempRootFolder)) {
			Write-Log -Message "TempRootFolder variable is empty. Aborting." -Severity 3 -Source ${cmdletName}
			throw "TempRootFolder variable is empty. Aborting."
		}
		if ($true -eq (Test-Path -Path $TempRootFolder)) {
			Write-Log -Message "Clearing temp folder [$TempRootFolder]..." -Source ${cmdletName}
		}
		else {
			Write-Log -Message "Temp folder [$TempRootFolder] does not exist. Skipping." -Source ${cmdletName}
			return
		}
		try {
			## Get the current date/time
			[datetime]$now = Get-Date
			## Get all files and folders in the temp folder
			[array]$items = Get-ChildItem -Path $TempRootFolder -Force
			## Loop through each file and folder
			foreach ($item in $items) {
				## Calculate the number of hours since the file/folder was last accessed
				[int]$hoursSinceLastAccess = ($now - $item.LastAccessTime).TotalHours
				## If the number of hours since the file/folder was last accessed is greater than the defined threshold or if the file/folder is listed in the NxtTempDirectories array, delete it.
				if ($hoursSinceLastAccess -gt $HoursToKeep -or ($NxtTempDirectories -contains $item.FullName)) {
					Write-Log -Message "Deleting file/folder '$($item.FullName)'..." -Source ${cmdletName}
					Remove-Item -Path $item.FullName -Force -Recurse
					Write-Log -Message "File/folder successfully deleted." -Source ${cmdletName}
				}
			}
			## Delete root folder also in case it is empty
			if ((Get-ChildItem -Path $TempRootFolder -Force).Count -eq 0) {
				Remove-NxtEmptyFolder -Path $TempRootFolder
			}
		}
		catch {
			Write-Log -Message "Failed to clear temp folder. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
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
	.PARAMETER AcceptedExitCodes
		Defines a list of exit codes or * for all exit codes that will be accepted for success by called setup execution.
	.PARAMETER ContinueOnError
		Continue if an error is encountered. Default is: $false.
	.PARAMETER XmlConfigNxtBitRockInstaller
		The Default Settings for BitRockInstaller.
		Defaults to $xmlConfig.NxtBitRockInstaller_Options.
	.PARAMETER DirFiles
		The Files directory specified in AppDeployToolkitMain.ps1, Defaults to $dirfiles.
	.PARAMETER AcceptedRebootCodes
		Defines a string with a comma separated list of exit codes that will be accepted for reboot by called setup execution.
	.PARAMETER UninsBackupPath
		Defines the path where uninstaller backups should be stored.
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
	.OUTPUTS
		none.
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
		$AcceptedExitCodes,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[bool]
		$ContinueOnError = $false,
		[Parameter(Mandatory = $false)]
		[Xml.XmlElement]
		$XmlConfigNxtBitRockInstaller = $xmlConfig.NxtBitRockInstaller_Options,
		[Parameter(Mandatory = $false)]
		[string]
		$DirFiles = $dirFiles,
		[Parameter(Mandatory = $false)]
		[string]
		$AcceptedRebootCodes,
		[Parameter(Mandatory = $false)]
		[string]
		$UninsBackupPath
	)
	Begin {
		## read config data from AppDeployToolkitConfig.xml
		[string]$configNxtBitRockInstallerInstallParams = $ExecutionContext.InvokeCommand.ExpandString($XmlConfigNxtBitRockInstaller.NxtBitRockInstaller_InstallParams)
		[string]$configNxtBitRockInstallerUninstallParams = $ExecutionContext.InvokeCommand.ExpandString($XmlConfigNxtBitRockInstaller.NxtBitRockInstaller_UninstallParams)

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
				if ($true -eq (Test-Path -LiteralPath (Join-Path -Path $DirFiles -ChildPath $Path -ErrorAction 'SilentlyContinue') -PathType 'Leaf' -ErrorAction 'SilentlyContinue')) {
					[string]$bitRockInstallerSetupPath = Join-Path -Path $DirFiles -ChildPath $Path
				}
				elseif ($true -eq (Test-Path -LiteralPath $Path -ErrorAction 'SilentlyContinue')) {
					[string]$bitRockInstallerSetupPath = (Get-Item -LiteralPath $Path).FullName
				}
				else {
					Write-Log -Message "Failed to find installation file [$Path]." -Severity 3 -Source ${CmdletName}
					if ($false -eq $ContinueOnError) {
						throw "Failed to find installation file [$Path]."
					}
					continue
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
				if ($true -eq ($bitRockInstallerUninstallString.StartsWith('"'))) {
					[string]$bitRockInstallerSetupPath = $bitRockInstallerUninstallString.Substring(1, $bitRockInstallerUninstallString.IndexOf('"', 1) - 1)
				}
				else {
					[string]$bitRockInstallerSetupPath = $bitRockInstallerUninstallString.Substring(0, $bitRockInstallerUninstallString.IndexOf('.exe', [System.StringComparison]::CurrentCultureIgnoreCase) + 4)
				}

				## Get parent folder and filename of the uninstallation file
				[string]$uninsFolder = Split-Path $bitRockInstallerSetupPath -Parent
				[string]$uninsFileName = Split-Path $bitRockInstallerSetupPath -Leaf

				## If the uninstall file does not exist, restore it from $UninsBackupPath, if it exists there
				if (($false -eq ([System.IO.File]::Exists($bitRockInstallerSetupPath))) -and ($true -eq (Test-Path -Path "$UninsBackupPath\$bitRockInstallerBackupSubfolderName\$uninsFileName"))) {
					Write-Log -Message "Uninstall file not found. Restoring it from backup..." -Source ${CmdletName}
					Copy-File -Path "$UninsBackupPath\$bitRockInstallerBackupSubfolderName\unins*.*" -Destination "$uninsFolder\"
				}

				## If $bitRockInstallerSetupPath is still unexistend, write Error to log and abort
				if ($false -eq ([System.IO.File]::Exists($bitRockInstallerSetupPath))) {
					Write-Log -Message "Uninstallation file could not be found nor restored." -Severity 3 -Source ${CmdletName}

					if ($true -eq $ContinueOnError) {
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
		if ($false -eq [string]::IsNullOrEmpty($Parameters)) {
			[string]$argsBitRockInstaller = $Parameters
		}
		## Append parameters to default parameters if specified.
		if ($false -eq [string]::IsNullOrEmpty($AddParameters)) {
			[string]$argsBitRockInstaller = "$argsBitRockInstaller $AddParameters"
		}

		[hashtable]$executeProcessSplat = @{
			Path					= $bitRockInstallerSetupPath
			Parameters				= $argsBitRockInstaller
			WindowStyle				= 'Normal'
			ExitOnProcessFailure	= $false
			PassThru				= $true
		}

		if ($true -eq $ContinueOnError) {
			$executeProcessSplat.Add('ContinueOnError', $ContinueOnError)
		}
		[string]$ignoreExitCodes = Merge-NxtExitCodes -ExitCodeString1 $AcceptedExitCodes -ExitCodeString2 $AcceptedRebootCodes
		if ($false -eq ([string]::IsNullOrEmpty($ignoreExitCodes))) {
			$executeProcessSplat.Add('IgnoreExitCodes', $ignoreExitCodes)
		}
		[psobject]$executeResult = Execute-Process @executeProcessSplat
		if ($executeResult.ExitCode -in ($AcceptedRebootCodes -split ',')) {
			Write-Log -Message "A custom reboot return code was detected '$($executeResult.ExitCode)' and is translated to return code '3010': Reboot required!" -Severity 2 -Source ${cmdletName}
			$executeResult.ExitCode = 3010
			Set-Variable -Name 'msiRebootDetected' -Value $true -Scope 'Script'
		}
		if ($Action -eq 'Uninstall') {
			## Wait until all uninstallation processes are terminated or write a warning to the log if the waiting period is exceeded
			Write-Log -Message "Wait while an uninstallation process is still running..." -Source ${CmdletName}
			## wait for process 5 times, BitRock uninstaller can close and reappear several times
			for ($i = 0; $i -lt 5; $i++) {
				[bool]$result_UninstallProcess = Watch-NxtProcessIsStopped -ProcessName "_Uninstall*" -Timeout 500
				Start-Sleep 1
			}
			if ($false -eq $result_UninstallProcess) {
				Write-Log -Message "Note: an uninstallation process was still running after the waiting period of at least 500s!" -Severity 2 -Source ${CmdletName}
			}
			else {
				Write-Log -Message "All uninstallation processes finished." -Source ${CmdletName}
			}
		}

		## Update the desktop (in case of changed or added enviroment variables)
		Update-Desktop

		## Copy uninstallation file from $uninsFolder to $UninsBackupPath after a successful installation
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
				if ($true -eq ($bitRockInstallerUninstallString.StartsWith('"'))) {
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
					Copy-File -Path "$uninsFolder\unins*.*" -Destination "$UninsBackupPath\$($InstalledAppResults.UninstallSubkey)\"
				}
				else {
					Write-Log -Message "Uninstall file not found. Skipping [copy of uninstallation file to backup]..." -Source ${CmdletName}
				}
			}
		}
	}
	End {
		Write-Output -InputObject $executeResult
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
		Log file name or full path including it's name and file format (eg. '-Log "InstLogFile"', '-Log "UninstLog.txt"' or '-Log "$configToolkitLogDir\Install.$($global:DeploymentTimestamp).log"')
		If only a name is specified the log path is taken from AppDeployToolkitConfig.xml (node "NxtInnoSetup_LogPath").
		If this parameter is not specified a log name is generated automatically and the log path is again taken from AppDeployToolkitConfig.xml (node "NxtInnoSetup_LogPath").
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
	.PARAMETER DirFiles
		The Files directory specified in AppDeployToolkitMain.ps1, Defaults to $dirfiles.
	.PARAMETER AcceptedRebootCodes
		Defines a string with a comma separated list of exit codes that will be accepted for reboot by called setup execution.
	.PARAMETER UninsBackupPath
		Defines the path where uninstaller backups should be stored.
	.EXAMPLE
		Execute-NxtInnoSetup -UninstallKey "This Application_is1" -Path "ThisAppSetup.exe" -AddParameters "/LOADINF=`"$dirSupportFiles\Comp.inf`"" -Log "InstallationLog"
	.EXAMPLE
		Execute-NxtInnoSetup -Action "Uninstall" -UninstallKey "This Application_is1" -Log "$configToolkitLogDir\Uninstall.$($global:deploymentTimestamp).log"
	.EXAMPLE
		Execute-NxtInnoSetup -Action "Uninstall" -UninstallKey "SomeApp - Version *" -UninstallKeyIsDisplayName $true -UninstallKeyContainsWildCards $true -DisplayNamesToExclude "SomeApp - Version 1.0","SomeApp - Version 1.1",$global:PackageConfig.UninstallDisplayName
	.EXAMPLE
		Execute-NxtInnoSetup -Action "Uninstall" -UninstallKey "***MySuperSparklingApp***" -UninstallKeyIsDisplayName $true -UninstallKeyContainsWildCards $false
	.NOTES
		AppDeployToolkit is required in order to run this function.
	.OUTPUTS
		none.
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
		[ValidatePattern("^[A-Za-z]\:\\.*\.(log|txt)$|^$|^[^\\/]+$")]
		[string]
		$Log,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$AcceptedExitCodes,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[bool]
		$ContinueOnError = $false,
		[Parameter(Mandatory = $false)]
		[string]
		$DeploymentTimestamp = $global:DeploymentTimestamp,
		[Parameter(Mandatory = $false)]
		[Xml.XmlElement]
		$XmlConfigNxtInnoSetup = $xmlConfig.NxtInnoSetup_Options,
		[Parameter(Mandatory = $false)]
		[string]
		$DirFiles = $dirFiles,
		[Parameter(Mandatory = $false)]
		[string]
		$AcceptedRebootCodes,
		[Parameter(Mandatory = $false)]
		[string]
		$UninsBackupPath
	)
	Begin {
		## read config data from AppDeployToolkitConfig.xml
		[string]$configNxtInnoSetupInstallParams = $ExecutionContext.InvokeCommand.ExpandString($XmlConfigNxtInnoSetup.NxtInnoSetup_InstallParams)
		[string]$configNxtInnoSetupUninstallParams = $ExecutionContext.InvokeCommand.ExpandString($XmlConfigNxtInnoSetup.NxtInnoSetup_UninstallParams)
		[string]$configNxtInnoSetupLogPath = $ExecutionContext.InvokeCommand.ExpandString($XmlConfigNxtInnoSetup.NxtInnoSetup_LogPath)

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
				if ($true -eq (Test-Path -LiteralPath (Join-Path -Path $DirFiles -ChildPath $path -ErrorAction 'SilentlyContinue') -PathType 'Leaf' -ErrorAction 'SilentlyContinue')) {
					[string]$innoSetupPath = Join-Path -Path $DirFiles -ChildPath $path
				}
				elseif ($true -eq (Test-Path -LiteralPath $Path -ErrorAction 'SilentlyContinue')) {
					[string]$innoSetupPath = (Get-Item -LiteralPath $Path).FullName
				}
				else {
					Write-Log -Message "Failed to find installation file [$path]." -Severity 3 -Source ${CmdletName}
					if ($false -eq $ContinueOnError) {
						throw "Failed to find installation file [$path]."
					}
					continue
				}
			}
			'Uninstall' {
				[string]$innoSetupDefaultParams = $configNxtInnoSetupUninstallParams
				[array]$installedAppResults = Get-NxtInstalledApplication -UninstallKey $innoUninstallKey -UninstallKeyIsDisplayName $innoUninstallKeyIsDisplayName -UninstallKeyContainsWildCards $innoUninstallKeyContainsWildCards -DisplayNamesToExclude $innoDisplayNamesToExclude
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
				if ($true -eq ($innoUninstallString.StartsWith('"'))) {
					[string]$innoSetupPath = $innoUninstallString.Substring(1, $innoUninstallString.IndexOf('"', 1) - 1)
				}
				else {
					[string]$innoSetupPath = $innoUninstallString.Substring(0, $innoUninstallString.IndexOf('.exe', [System.StringComparison]::CurrentCultureIgnoreCase) + 4)
				}

				## Get the parent folder of the uninstallation file
				[string]$uninsFolder = Split-Path $innoSetupPath -Parent

				## If the uninstall file does not exist, restore it from $UninsBackupPath, if it exists there
				if ( ($false -eq ([System.IO.File]::Exists($innoSetupPath))) -and ($true -eq (Test-Path -Path "$UninsBackupPath\$innoSetupBackupSubfolderName\unins[0-9][0-9][0-9].exe")) ) {
					Write-Log -Message "Uninstall file not found. Restoring it from backup..." -Source ${CmdletName}
					Remove-File -Path "$uninsFolder\unins*.*"
					Copy-File -Path "$UninsBackupPath\$innoSetupBackupSubfolderName\unins[0-9][0-9][0-9].*" -Destination "$uninsFolder\"
				}

				## If any "$uninsFolder\unins[0-9][0-9][0-9].exe" exists, use the one with the highest number
				if ($true -eq (Test-Path -Path "$uninsFolder\unins[0-9][0-9][0-9].exe")) {
					[string]$innoSetupPath = Get-Item "$uninsFolder\unins[0-9][0-9][0-9].exe" | Select-Object -last 1 -ExpandProperty FullName
					Write-Log -Message "Uninstall file set to: `"$innoSetupPath`"." -Source ${CmdletName}
				}

				## If $innoSetupPath is still unexistend, write Error to log and abort
				if ($false -eq ([System.IO.File]::Exists($innoSetupPath))) {
					Write-Log -Message "Uninstallation file could not be found nor restored." -Severity 3 -Source ${CmdletName}

					if ($true -eq $ContinueOnError) {
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
		if ($false -eq [string]::IsNullOrEmpty($Parameters)) {
			[string]$argsInnoSetup = $Parameters
		}
		## Append parameters to default parameters if specified.
		if ($false -eq [string]::IsNullOrEmpty($AddParameters)) {
			[string]$argsInnoSetup = "$argsInnoSetup $AddParameters"
		}

		## MergeTasks if parameters were not replaced
		if (($true -eq ([string]::IsNullOrEmpty($Parameters))) -and ($false -eq ([string]::IsNullOrWhiteSpace($MergeTasks)))) {
			[string]$argsInnoSetup += " /MERGETASKS=`"$MergeTasks`""
		}

		## Logging
		if ($true -eq ([string]::IsNullOrWhiteSpace($Log))) {
			## create Log file name if non is specified
			if ($Action -eq 'Install') {
				$Log = "Install_$(((Get-Item $innoSetupPath).Basename) -replace ' ', [string]::Empty)_$DeploymentTimestamp"
			}
			else {
				$Log = "Uninstall_$($InstalledAppResults.DisplayName -replace ' ', [string]::Empty)_$DeploymentTimestamp"
			}
		}

		## Append file extension if necessary
		[string]$logFileExtension = [System.IO.Path]::GetExtension($Log)
		if ($true -eq ([string]::IsNullOrEmpty($logFileExtension)) -or $logFileExtension -notin @('.log', '.txt')) {
			$Log = $Log + '.log'
		}
		## Determine full log path
		[string]$fullLogPath = [string]::Empty
		if ($true -eq ([System.IO.Path]::IsPathRooted($Log))) {
			$fullLogPath = $Log
		}
		else {
			$fullLogPath = Join-Path -Path $configNxtInnoSetupLogPath -ChildPath $($Log -replace ' ', [string]::Empty)
		}

		## Create log folder if necessary.
		[string]$logFolder = Split-Path -Path $fullLogPath -Parent
		if ($false -eq (Test-Path -Path $logFolder -PathType Container)) {
			New-Folder -Path $logFolder -ContinueOnError $false
		}
		[string]$argsInnoSetup = "$argsInnoSetup /LOG=`"$fullLogPath`""

		[hashtable]$executeProcessSplat = @{
			Path					= $innoSetupPath
			Parameters				= $argsInnoSetup
			WindowStyle				= 'Normal'
			ExitOnProcessFailure	= $false
			PassThru				= $true
		}

		if ($true -eq $ContinueOnError) {
			$executeProcessSplat.Add('ContinueOnError', $ContinueOnError)
		}
		[string]$ignoreExitCodes = Merge-NxtExitCodes -ExitCodeString1 $AcceptedExitCodes -ExitCodeString2 $AcceptedRebootCodes
		if ($false -eq ([string]::IsNullOrEmpty($ignoreExitCodes))) {
			$executeProcessSplat.Add('IgnoreExitCodes', $ignoreExitCodes)
		}
		[psobject]$executeResult = Execute-Process @executeProcessSplat
		if ($executeResult.ExitCode -in ($AcceptedRebootCodes -split ',')) {
			Write-Log -Message "A custom reboot return code was detected '$($executeResult.ExitCode)' and is translated to return code '3010': Reboot required!" -Severity 2 -Source ${cmdletName}
			$executeResult.ExitCode = 3010
			Set-Variable -Name 'msiRebootDetected' -Value $true -Scope 'Script'
		}
		## Update the desktop (in case of changed or added enviroment variables)
		Update-Desktop

		## Copy uninstallation file from $uninsfolder to $UninsBackupPath after a successful installation
		if ($Action -eq 'Install') {
			[array]$installedAppResults = Get-NxtInstalledApplication -UninstallKey $innoUninstallKey -UninstallKeyIsDisplayName $innoUninstallKeyIsDisplayName -UninstallKeyContainsWildCards $innoUninstallKeyContainsWildCards -DisplayNamesToExclude $innoDisplayNamesToExclude
			if ($installedAppResults.Count -eq 0) {
				Write-Log -Message "Found no Application with UninstallKey [$innoUninstallKey], UninstallKeyIsDisplayName [$innoUninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$innoUninstallKeyContainsWildCards] and DisplayNamesToExclude [$($innoDisplayNamesToExclude -join "][")]. Skipping [copy uninstallation file to backup]..." -Severity 2 -Source ${CmdletName}
			}
			elseif ($installedAppResults.Count -gt 1) {
				Write-Log -Message "Found more than one Application with UninstallKey [$innoUninstallKey], UninstallKeyIsDisplayName [$innoUninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$innoUninstallKeyContainsWildCards] and DisplayNamesToExclude [$($innoDisplayNamesToExclude -join "][")]. Skipping [copy uninstallation file to backup]..." -Severity 2 -Source ${CmdletName}
			}
			else {
				[string]$innoUninstallString = $InstalledAppResults.UninstallString

				## check for and remove quotation marks around the uninstall string
				if ($true -eq ($innoUninstallString.StartsWith('"'))) {
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
					Copy-File -Path "$uninsfolder\unins[0-9][0-9][0-9].*" -Destination "$UninsBackupPath\$($InstalledAppResults.UninstallSubkey)\"
				}
				else {
					Write-Log -Message "Uninstall file not found. Skipping [copy of uninstallation files to backup]..." -Source ${CmdletName}
				}
			}
		}
	}
	End {
		Write-Output -InputObject $executeResult
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
		Log file name or full path including it's name and file format (eg. '-Log "InstLogFile"', '-Log "UninstLog.txt"' or '-Log "$app\Install.$($global:DeploymentTimestamp).log"')
		If only a name is specified the log path is taken from AppDeployToolkitConfig.xml (node "MSI_LogPath").
		If this parameter is not specified a log name is generated automatically and the log path is again taken from AppDeployToolkitConfig.xml (node "MSI_LogPath").
	.PARAMETER WorkingDirectory
		Overrides the working directory. The working directory is set to the location of the MSI file.
	.PARAMETER SkipMSIAlreadyInstalledCheck
		Skips the check to determine if the MSI is already installed on the system. Default is: $false.
	.PARAMETER IncludeUpdatesAndHotfixes
		Include matches against updates and hotfixes in results.
	.PARAMETER NoWait
		Immediately continue after executing the process.
	.PARAMETER AcceptedExitCodes
		Defines a list of exit codes or * for all exit codes that will be accepted for success by called setup execution.
	.PARAMETER PriorityClass
		Specifies priority class for the process. Options: Idle, Normal, High, AboveNormal, BelowNormal, RealTime. Default: Normal
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
		[psobject]$ExecuteMSIResult = Execute-NxtMSI -Action 'Install' -Path 'Adobe_FlashPlayer_11.2.202.233_x64_EN.msi'
		Installs an MSI and stores the result of the execution into a variable.
	.EXAMPLE
		Execute-NxtMSI -Action 'Uninstall' -Path '{26923b43-4d38-484f-9b9e-de460746276c}'
		Uninstalls an MSI using a product code
	.EXAMPLE
		Execute-NxtMSI -Action 'Patch' -Path 'Adobe_Reader_11.0.3_EN.msp'
		Installs an MSP
	.OUTPUTS
		none.
	.NOTES
			AppDeployToolkit is required in order to run this function.
	.LINK
		http://psappdeploytoolkit.com
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[ValidateSet('Install', 'Uninstall', 'Patch', 'Repair', 'ActiveSetup')]
		[string]
		$Action = 'Install',
		[Parameter(Mandatory = $true, HelpMessage = 'Please enter either the path to the MSI/MSP file or the ProductCode')]
		[Alias('FilePath')]
		[string]
		$Path,
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
		[ValidatePattern("^[A-Za-z]\:\\.*\.(log|txt)$|^$|^[^\\/]+$")]
		[string]
		$Log,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Transform,
		[Parameter(Mandatory = $false)]
		[Alias('Arguments')]
		[string]
		$Parameters,
		[Parameter(Mandatory = $false)]
		[string]
		$AddParameters,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[switch]
		$SecureParameters = $false,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Patch,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$LoggingOptions,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$WorkingDirectory,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[switch]
		$SkipMSIAlreadyInstalledCheck = $false,
		[Parameter(Mandatory = $false)]
		[switch]
		$IncludeUpdatesAndHotfixes = $false,
		[Parameter(Mandatory = $false)]
		[switch]
		$NoWait = $false,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$AcceptedExitCodes,
		[Parameter(Mandatory = $false)]
		[ValidateSet('Idle', 'Normal', 'High', 'AboveNormal', 'BelowNormal', 'RealTime')]
		[Diagnostics.ProcessPriorityClass]
		$PriorityClass = 'Normal',
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[bool]
		$RepairFromSource = $false,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[bool]
		$ContinueOnError = $false,
		[Parameter(Mandatory = $false)]
		[string]
		$ConfigMSILogDir = $configMSILogDir,
		[Parameter(Mandatory = $false)]
		[string]
		$AcceptedRebootCodes
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
			"PriorityClass",
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
			"ConfigMSILogDir",
			"AcceptedExitCodes",
			"AcceptedRebootCodes"
		)
		foreach ($functionParameterToBeRemoved in $functionParametersToBeRemoved) {
			$PSBoundParameters.Remove($functionParameterToBeRemoved) | Out-Null
		}
	}
	Process {
		if (
			($UninstallKeyIsDisplayName -or $UninstallKeyContainsWildCards -or ($false -eq [string]::IsNullOrEmpty($DisplayNamesToExclude))) -and
			$Action -eq "Uninstall"
		) {
			[array]$installedAppResults = Get-NxtInstalledApplication -UninstallKey $Path -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -InstallMethod "MSI"
			if ($installedAppResults.Count -eq 0) {
				Write-Log -Message "Found no Application with UninstallKey [$Path], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Skipping action [$Action]..." -Severity 2 -Source ${CmdletName}
				return
			}
			elseif ($installedAppResults.Count -gt 1) {
				Write-Log -Message "Found more than one Application with UninstallKey [$Path], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Skipping action [$Action]..." -Severity 2 -Source ${CmdletName}
				return
			}
			elseif ($true -eq ([string]::IsNullOrEmpty($installedAppResults.ProductCode))) {
				Write-Log -Message "Found no MSI product code for the Application with UninstallKey [$Path], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Skipping action [$Action]..." -Severity 2 -Source ${CmdletName}
				return
			}
			else {
				$PSBoundParameters["Path"] = $installedAppResults.ProductCode
			}
		}
		[bool]$PSBoundParameters["PassThru"] = $true
		[bool]$PSBoundParameters["ExitOnProcessFailure"] = $false
		if ($true -eq ([string]::IsNullOrEmpty($Parameters))) {
			$PSBoundParameters.Remove('Parameters') | Out-Null
		}
		if ($true -eq ([string]::IsNullOrEmpty($AddParameters))) {
			$PSBoundParameters.Remove('AddParameters') | Out-Null
		}
		[string]$ignoreExitCodes = Merge-NxtExitCodes -ExitCodeString1 $AcceptedExitCodes -ExitCodeString2 $AcceptedRebootCodes
		if ($false -eq ([string]::IsNullOrEmpty($ignoreExitCodes))) {
			[string]$PSBoundParameters["IgnoreExitCodes"] = "$ignoreExitCodes"
		}
		if ($false -eq ([string]::IsNullOrEmpty($Log))) {
			[string]$msiLogName = ($Log | Split-Path -Leaf) -replace '\.log$|\.txt$', [string]::Empty
			$PSBoundParameters.add("LogName", $msiLogName )
		}
		[PSObject]$executeResult = Execute-MSI @PSBoundParameters
		## Move Logs to correct destination
		if ($true -eq ([System.IO.Path]::IsPathRooted($Log))) {
			[string]$msiActionLogName = "${msiLogName}_$($action).log"
			[string]$sourceLogPath = Join-Path -Path $xmlConfigMSIOptionsLogPath -ChildPath $msiActionLogName
			## Create log folder if necessary.
			[string]$logFolder = Split-Path -Path $Log -Parent
			if ($false -eq (Test-Path -Path $logFolder -PathType Container)) {
				New-Folder -Path $logFolder -ContinueOnError $false
			}
			if ($true -eq (Test-Path $sourceLogPath -PathType Leaf)) {
				Move-NxtItem $sourceLogPath -Destination $Log -Force
			}
			else {
				Write-Log -Message "Log file [$sourceLogPath] not found. Skipping move of log file..." -Source ${CmdletName}
			}
		}
		if ($executeResult.ExitCode -in ($AcceptedRebootCodes -split ',')) {
			Write-Log -Message "A custom reboot return code was detected '$($executeResult.ExitCode)' and is translated to return code '3010': Reboot required!" -Severity 2 -Source ${cmdletName}
			$executeResult.ExitCode = 3010
			Set-Variable -Name 'msiRebootDetected' -Value $true -Scope 'Script'
		}
	}
	End {
		Write-Output -InputObject $executeResult
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
	.PARAMETER AcceptedExitCodes
		Defines a list of exit codes or * for all exit codes that will be accepted for success by called setup execution.
	.PARAMETER ContinueOnError
		Continue if an error is encountered. Default is: $false.
	.PARAMETER XmlConfigNxtNullsoft
		The Default Settings for Nullsoftsetup.
		Defaults to $xmlConfig.NxtNullsoft_Options.
	.PARAMETER DirFiles
		The Files directory specified in AppDeployToolkitMain.ps1, Defaults to $dirfiles.
	.PARAMETER AcceptedRebootCodes
		Defines a string with a comma separated list of exit codes that will be accepted for reboot by called setup execution.
	.PARAMETER UninsBackupPath
		Defines the path where uninstaller backups should be stored.
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
	.OUTPUTS
		none.
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
		$AcceptedExitCodes,
		[Parameter(Mandatory = $false)]
		[bool]
		$ContinueOnError = $false,
		[Parameter(Mandatory = $false)]
		[Xml.XmlElement]
		$XmlConfigNxtNullsoft = $xmlConfig.NxtNullsoft_Options,
		[Parameter(Mandatory = $false)]
		[string]
		$DirFiles = $dirFiles,
		[Parameter(Mandatory = $false)]
		[string]
		$AcceptedRebootCodes,
		[Parameter(Mandatory = $false)]
		[string]
		$UninsBackupPath
	)
	Begin {
		## read config data from AppDeployToolkitConfig.xml
		[string]$configNxtNullsoftInstallParams = $ExecutionContext.InvokeCommand.ExpandString($XmlConfigNxtNullsoft.NxtNullsoft_InstallParams)
		[string]$configNxtNullsoftUninstallParams = $ExecutionContext.InvokeCommand.ExpandString($XmlConfigNxtNullsoft.NxtNullsoft_UninstallParams)

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
				if ($true -eq (Test-Path -LiteralPath (Join-Path -Path $DirFiles -ChildPath $path -ErrorAction 'SilentlyContinue') -PathType 'Leaf' -ErrorAction 'SilentlyContinue')) {
					[string]$nullsoftSetupPath = Join-Path -Path $DirFiles -ChildPath $path
				}
				elseif ($true -eq (Test-Path -LiteralPath $Path -ErrorAction 'SilentlyContinue')) {
					[string]$nullsoftSetupPath = (Get-Item -LiteralPath $Path).FullName
				}
				else {
					Write-Log -Message "Failed to find installation file [$path]." -Severity 3 -Source ${CmdletName}
					if ($false -eq $ContinueOnError) {
						throw "Failed to find installation file [$path]."
					}
					continue
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
				if ($true -eq ($nullsoftUninstallString.StartsWith('"'))) {
					[string]$nullsoftSetupPath = $nullsoftUninstallString.Substring(1, $nullsoftUninstallString.IndexOf('"', 1) - 1)
				}
				else {
					[string]$nullsoftSetupPath = $nullsoftUninstallString.Substring(0, $nullsoftUninstallString.IndexOf('.exe', [System.StringComparison]::CurrentCultureIgnoreCase) + 4)
				}

				## Get parent folder and filename of the uninstallation file
				[string]$uninsFolder = Split-Path $nullsoftSetupPath -Parent
				[string]$uninsFileName = Split-Path $nullsoftSetupPath -Leaf

				## If the uninstall file does not exist, restore it from $UninsBackupPath, if it exists there
				if ($false -eq ([System.IO.File]::Exists($nullsoftSetupPath)) -and ($true -eq (Test-Path -Path "$UninsBackupPath\$nullsoftBackupSubfolderName\$uninsFileName"))) {
					Write-Log -Message "Uninstall file not found. Restoring it from backup..." -Source ${CmdletName}
					Copy-File -Path "$UninsBackupPath\$nullsoftBackupSubfolderName\$uninsFileName" -Destination "$uninsFolder\"
				}

				## If $nullsoftSetupPath is still unexistend, write Error to log and abort
				if ($false -eq ([System.IO.File]::Exists($nullsoftSetupPath))) {
					Write-Log -Message "Uninstallation file could not be found nor restored." -Severity 3 -Source ${CmdletName}

					if ($true -eq $ContinueOnError) {
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
		if ($false -eq [string]::IsNullOrEmpty($Parameters)) {
			[string]$argsnullsoft = $Parameters
		}
		## Append parameters to default parameters if specified.
		if ($false -eq [string]::IsNullOrEmpty($AddParameters)) {
			[string]$argsnullsoft = "$argsnullsoft $AddParameters"
		}

		[hashtable]$executeProcessSplat = @{
			Path					= $nullsoftSetupPath
			Parameters				= $argsnullsoft
			WindowStyle				= 'Normal'
			ExitOnProcessFailure	= $false
			PassThru				= $true
		}

		if ($true -eq $ContinueOnError) {
			$executeProcessSplat.Add('ContinueOnError', $ContinueOnError)
		}
		[string]$ignoreExitCodes = Merge-NxtExitCodes -ExitCodeString1 $AcceptedExitCodes -ExitCodeString2 $AcceptedRebootCodes
		if ($false -eq ([string]::IsNullOrEmpty($ignoreExitCodes))) {
			$executeProcessSplat.Add('IgnoreExitCodes', $ignoreExitCodes)
		}
		[psobject]$executeResult = Execute-Process @executeProcessSplat
		if ($executeResult.ExitCode -in ($AcceptedRebootCodes -split ',')) {
			Write-Log -Message "A custom reboot return code was detected '$($executeResult.ExitCode)' and is translated to return code '3010': Reboot required!" -Severity 2 -Source ${cmdletName}
			$executeResult.ExitCode = 3010
			Set-Variable -Name 'msiRebootDetected' -Value $true -Scope 'Script'
		}
		if ($Action -eq 'Uninstall') {
			## Wait until all uninstallation processes hopefully terminated
			Write-Log -Message "Wait while one of the possible uninstallation processes is still running..." -Source ${CmdletName}
			[bool]$uninstallProcessDidNotTerminate = $false
			foreach ($process in @("AU_.exe", "Un_A.exe", "Un.exe")) {
				$uninstallProcessDidNotTerminate = $false -eq (Watch-NxtProcessIsStopped -ProcessName $process -Timeout "500")
				if ($true -eq $uninstallProcessDidNotTerminate) {
					break
				}
			}
			if ($true -eq $uninstallProcessDidNotTerminate) {
				Write-Log -Message "Note: an uninstallation process was still running after the waiting period of 500s!" -Severity 2 -Source ${CmdletName}
			}
			else {
				Write-Log -Message "All uninstallation processes finished." -Source ${CmdletName}
			}
		}

		## Update the desktop (in case of changed or added enviroment variables)
		Update-Desktop

		## Copy uninstallation file from $uninsFolder to $UninsBackupPath after a successful installation
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
				if ($true -eq ($nullsoftUninstallString.StartsWith('"'))) {
					[string]$nullsoftUninstallPath = $nullsoftUninstallString.Substring(1, $nullsoftUninstallString.IndexOf('"', 1) - 1)
				}
				else {
					[string]$nullsoftUninstallPath = $nullsoftUninstallString.Substring(0, $nullsoftUninstallString.IndexOf('.exe', [System.StringComparison]::CurrentCultureIgnoreCase) + 4)
				}

				## Actually copy the uninstallation file, if it exists
				if ($true -eq (Test-Path -Path "$nullsoftUninstallPath")) {
					Write-Log -Message "Copy uninstallation file to backup..." -Source ${CmdletName}
					Copy-File -Path "$nullsoftUninstallPath" -Destination "$UninsBackupPath\$($InstalledAppResults.UninstallSubkey)\"
				}
				else {
					Write-Log -Message "Uninstall file not found. Skipping [copy of uninstallation file to backup]..." -Source ${CmdletName}
				}
			}
		}
	}
	End {
		Write-Output -InputObject $executeResult
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
	.OUTPUTS
		none.
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
			foreach ($varThatMustNotBeEmpty in @("PackageMachineKey", "PackageUninstallKey")) {
				if ($true -eq ([string]::IsNullOrEmpty((Get-Variable -Name $varThatMustNotBeEmpty -ValueOnly)))) {
					Write-Log -Message "$varThatMustNotBeEmpty is empty. Skipping AbortReboot. Throwing error" -Severity 3 -Source ${CmdletName}
					throw "$varThatMustNotBeEmpty is empty. Skipping AbortReboot. Throwing error"
				}
			}
			Remove-RegistryKey -Key "HKLM:\Software\$PackageMachineKey" -Recurse
			Remove-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageUninstallKey" -Recurse
			if (
				(Test-Path -Path "HKLM:\Software\$EmpirumMachineKey") -and
				$false -eq [string]::IsNullOrEmpty($EmpirumMachineKey)
			) {
				Remove-RegistryKey -Key "HKLM:\Software\$EmpirumMachineKey" -Recurse
			}
			if (
				(Test-Path -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$EmpirumUninstallKey") -and
				$false -eq ([string]::IsNullOrEmpty($EmpirumUninstallKey))
			) {
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
	.PARAMETER RegisterPackage
		Specifies if package may be registered.
		Defaults to the corresponding global value.
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
	.PARAMETER TempRootFolder
		The path to the temporary folder targeted for cleaning. To ensure that all internal processes work correctly it is highly recommended to keep the default value!
		Defaults to $env:SystemDrive\n42Tmp.
	.PARAMETER HoursToKeep
		The age threshold, in hours, for retaining files and folders in the temporary folder. Files and folders older than this threshold will be deleted.
		Defaults to 96 (4 days).
	.PARAMETER ContinueOnError
		Continue if an error is encountered. Default is: $true.
	.PARAMETER NxtTempDirectories
		Defines a list of TempFolders to be cleared.
		Defaults to $script:NxtTempDirectories defined in the AppDeployToolkitMain.
	.PARAMETER DeploymentType
		Defines the DeploymentType. Used to determine the registry key to write the error entry to.
		Defaults to DeploymentType defined by the Deploy-Application param block.
	.PARAMETER BlockExecution
		Indicates if the execution of applications has been blocked. This function will only unblock applications if this variable is set to $true.
		Defaults to $Script:BlockExecution.
	.EXAMPLE
		Exit-NxtScriptWithError -ErrorMessage "The Installer returned the following Exit Code $someExitcode, installation failed!" -MainExitCode 69001 -PackageStatus "InternalInstallerError"
	.OUTPUTS
		none.
	.NOTES
		AppDeployToolkit is required in order to run this function.
	.LINK
		http://psappdeploytoolkit.com
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$RegisterPackage = $global:registerPackage,
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
		$UserPartOnUnInstallation = $global:PackageConfig.UserPartOnUnInstallation,
		[Parameter(Mandatory = $false)]
		[string]
		$TempRootFolder = "$env:SystemDrive\n42Tmp",
		[Parameter(Mandatory = $false)]
		[int]
		$HoursToKeep = 96,
		[Parameter(Mandatory = $false)]
		[string[]]
		$NxtTempDirectories = $script:NxtTempDirectories,
		[Parameter(Mandatory = $false)]
		[bool]
		$BlockExecution = $Script:BlockExecution,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$DeploymentType = $DeploymentType
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ($false -eq $RegisterPackage) {
			Write-Log -Message "RegisterPackage is set to 'false', skip writing '_Error' key in registry..." -Source ${cmdletName}
		}
		Write-Log -Message $ErrorMessage -Severity 3 -Source ${CmdletName}
		if ($DeploymentType -notin @('InstallUserPart', 'UninstallUserPart')) {
			$hive = "HKLM"
		}
		else {
			$hive = "HKCU"
		}
		try {
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'AppPath' -Value $App
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'DebugLogFile' -Value $DebugLogFile
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'DeploymentStartTime' -Value $DeploymentTimestamp
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'DeveloperName' -Value $AppVendor
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'ErrorTimeStamp' -Value $(Get-Date -format "yyyy-MM-dd_HH-mm-ss")
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'ErrorMessage' -Value $ErrorMessage
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'ErrorMessagePSADT' -Value $ErrorMessagePSADT
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'LastExitCode' -Value $MainExitCode
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'PackageArchitecture' -Value $AppArch
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'PackageStatus' -Value $PackageStatus
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'ProductName' -Value $AppName
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'Revision' -Value $AppRevision
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'SrcPath' -Value $ScriptParentPath
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'StartupProcessor_Architecture' -Value $EnvArchitecture
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'StartupProcessOwner' -Value $EnvUserDomain\$EnvUserName
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'StartupProcessOwnerSID' -Value $ProcessNTAccountSID
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'UninstallOld' -Type 'Dword' -Value $UninstallOld
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'UserPartOnInstallation' -Value $UserPartOnInstallation -Type 'DWord'
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'UserPartOnUninstallation' -Value $UserPartOnUnInstallation -Type 'DWord'
			Set-RegistryKey -Key "${hive}:\Software\$RegPackagesKey\$PackageGUID$("_Error")" -Name 'Version' -Value $AppVersion
		}
		catch {
			Write-Log -Message "Failed to create error key in registry. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
		if ($MainExitCode -in 0) {
			$MainExitCode = 70000
		}
		if ($DeploymentType -notin @('InstallUserPart', 'UninstallUserPart')) {
			Clear-NxtTempFolder -TempRootFolder $TempRootFolder -HoursToKeep $HoursToKeep -NxtTempDirectories $NxtTempDirectories
			Unblock-NxtAppExecution -BlockScriptLocation $App -BlockExecution $BlockExecution
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
	.SYNOPSIS
		Expands keys from the package config
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
		if ($false -eq [System.IO.Path]::IsPathRooted($global:PackageConfig.AppRootFolder)) {
			throw "AppRootFolder is not a valid path. Please check your PackageConfig."
		}
		[string]$global:PackageConfig.App = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.App)
		[string]$global:PackageConfig.UninstallDisplayName = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.UninstallDisplayName)
		[string]$global:PackageConfig.InstallLocation = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.InstallLocation)
		[string]$global:PackageConfig.InstLogFile = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.InstLogFile)
		[string]$global:PackageConfig.UninstLogFile = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.UninstLogFile)
		[string]$global:PackageConfig.InstFile = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.InstFile)
		[string]$global:PackageConfig.InstPara = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.InstPara)
		[string]$global:PackageConfig.UninstFile = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.UninstFile)
		[string]$global:PackageConfig.UninstPara = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.UninstPara)
		if ($true -eq $global:PackageConfig.UninstallKeyContainsExpandVariables) {
			[string]$global:PackageConfig.UninstallKey = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.UninstallKey)
		}
		[array]$global:PackageConfig.DisplayNamesToExcludeFromAppSearches = foreach ($displayNameToExcludeFromAppSearches in $global:PackageConfig.DisplayNamesToExcludeFromAppSearches) {
			$ExecutionContext.InvokeCommand.ExpandString($displayNameToExcludeFromAppSearches)
		}
		## the array must exist even if empty, to avoid errors in the validation functions
		if ($null -eq [array]$global:PackageConfig.DisplayNamesToExcludeFromAppSearches) {
			[array]$global:PackageConfig.DisplayNamesToExcludeFromAppSearches = @()
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
		[array]$global:PackageConfig.CommonDesktopShortcutsToDelete = foreach ($CommonDesktopShortcutToDelete in $global:PackageConfig.CommonDesktopShortcutsToDelete) {
			$ExecutionContext.InvokeCommand.ExpandString($CommonDesktopShortcutToDelete)
		}
		foreach ($CommonStartMenuShortcutToCopyToCommonDesktop in $global:PackageConfig.CommonStartMenuShortcutsToCopyToCommonDesktop) {
			$CommonStartMenuShortcutToCopyToCommonDesktop.Source = $ExecutionContext.InvokeCommand.ExpandString($CommonStartMenuShortcutToCopyToCommonDesktop.Source)
			if ($false -eq [string]::IsNullOrEmpty($CommonStartMenuShortcutToCopyToCommonDesktop.TargetName)) {
				$CommonStartMenuShortcutToCopyToCommonDesktop.TargetName = $ExecutionContext.InvokeCommand.ExpandString($CommonStartMenuShortcutToCopyToCommonDesktop.TargetName)
			}
		}
		[string]$global:PackageConfig.SoftMigration.File.FullNameToCheck = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.SoftMigration.File.FullNameToCheck)
		[string]$global:PackageConfig.SoftMigration.File.VersionToCheck = $ExecutionContext.InvokeCommand.ExpandString($PackageConfig.SoftMigration.File.VersionToCheck)
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Expand-NxtVariablesInFile
function Expand-NxtVariablesInFile {
	<#
	.SYNOPSIS
		Expands different variable types in a given text file.
	.DESCRIPTION
		The Expand-NxtVariablesInFile function is designed to expand a variety of variable types present in a text file.
		The function is equipped to handle local, script, $env:, $global: and common Windows environment variables.
		Upon execution, the function will update the target file by replacing all variable references with their actual values.
	.PARAMETER Path
		The full path to the file that contains the variables you want to expand.
		This parameter is mandatory.
	.EXAMPLE
		Expand-NxtVariablesInFile -Path C:\Temp\testfile.txt
		This will process the 'testfile.txt' file located in the C:\Temp directory, expanding all supported variable types present in the file.
	.OUTPUTS
		none.
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
					if ($true -eq ($globalVariableName.Contains('.'))) {
						[string]$tempVariableName = $globalVariableName.Split('.')[0]
						[PSObject]$tempVariableValue = (Get-Variable -Name $tempVariableName -Scope Global -ValueOnly -ErrorAction SilentlyContinue)
						## Variables with properties and/or subproperties won't be found
						if ($false -eq ([string]::IsNullOrEmpty($tempVariableValue))) {
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
					if ($true -eq ([string]::IsNullOrEmpty($globalVariableValue))) {
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

					[string]$envVariableValue = (Get-ChildItem env:* | Where-Object {
						$_.Name -EQ $envVariableName
					}).Value

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
					[string]$envVariableValue = (Get-ChildItem env:* | Where-Object {
						$_.Name -EQ $envVariableName
					}).Value

					[string]$line = $line.Replace($expressionMatch.Value, $envVariableValue)
				}
				[PSObject]$environmentMatches = $null

				## Replace PowerShell variable in brackets with its value
				[PSObject]$variableMatchesInBrackets = [regex]::Matches($line, '\$\(\$[A-Za-z_.][A-Za-z0-9_.\[\]]+\)')
				foreach ($expressionMatch in $variableMatchesInBrackets) {
					[string]$expression = $expressionMatch.Groups[0].Value
					[string]$cleanedExpression = $expression.TrimStart('$(').TrimEnd('")')
					if ($true -eq ($cleanedExpression.Contains('.'))) {
						[string]$tempVariableName = $cleanedExpression.Split('.')[0]
						[PSObject]$tempVariableValue = (Get-Variable -Name $tempVariableName -Scope Global -ValueOnly -ErrorAction SilentlyContinue)
						## Variables with properties and/or subproperties won't be found
						if ($false -eq ([string]::IsNullOrEmpty($tempVariableValue))) {
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
					if ($true -eq ($variableName.Contains('.'))) {
						[string]$tempVariableName = $variableName.Split('.')[0]
						[PSObject]$tempVariableValue = (Get-Variable -Name $tempVariableName -Scope Global -ValueOnly -ErrorAction SilentlyContinue)
						## Variables with properties and/or subproperties won't be found
						if ($false -eq ([string]::IsNullOrEmpty($tempVariableValue))) {
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
	.SYNOPSIS
		Formats the PackageSpecificVariables from PackageSpecificVariablesRaw in a given package configuration.
	.DESCRIPTION
		The Format-NxtPackageSpecificVariables function is designed to format the PackageSpecificVariables from the PackageSpecificVariablesRaw	property within the provided package configuration. After formatting, these variables can be accessed using the syntax:
		$global:PackageConfig.PackageSpecificVariables.CustomVariableName.
		Optionally, it can also expand variables if the ExpandVariables property is set to true within the PackageSpecificVariablesRaw.
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
		[System.Collections.Generic.Dictionary[string, string]]$packageSpecificVariableDictionary = [Collections.Generic.Dictionary[string, string]]::new( [StringComparer]::InvariantCultureIgnoreCase )
		foreach ($packageSpecificVariable in $PackageConfig.PackageSpecificVariablesRaw) {
			if ($null -ne $packageSpecificVariable.ExpandVariables) {
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
	.SYNOPSIS
		Retrieves the manufacturer name of the computer system.
	.DESCRIPTION
		The Get-NxtComputerManufacturer function fetches the manufacturer's name of the computer system by querying the Win32_ComputerSystem class.
		In the event of an error or inability to retrieve the manufacturer name, an error log will be written and the function will return an empty string.
	.EXAMPLE
		Get-NxtComputerManufacturer
		This will return the name of the computer system's manufacturer, e.g., "Dell" or "HP".
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
	.SYNOPSIS
		Retrieves the model of the computer system.
	.DESCRIPTION
		The Get-NxtComputerModel function fetches the model information of the computer system.
		It leverages the Win32_ComputerSystem WMI class to obtain this information.
		In the event of an error during the retrieval process, an appropriate log message is recorded.
	.EXAMPLE
		Get-NxtComputerModel
		This example retrieves the computer system's model.
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
	.PARAMETER InstallMethod
		Defines the installer type any applied installer specific logic. Currently only applicable for MSI installers.
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
		$DisplayNamesToExclude = $global:PackageConfig.DisplayNamesToExcludeFromAppSearches,
		[Parameter(Mandatory = $false)]
		[string]
		$InstallMethod
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ($true -eq ([string]::IsNullOrEmpty($UninstallKey))) {
			Write-Log -Message "Can't detect display version: No uninstallkey or display name defined." -Source ${CmdletName}
		}
		else {
			[PSADTNXT.NxtDisplayVersionResult]$displayVersionResult = New-Object -TypeName PSADTNXT.NxtDisplayVersionResult
			try {
				Write-Log -Message "Detect currently set DisplayVersion value of package application..." -Source ${CmdletName}
				[array]$installedAppResults = Get-NxtInstalledApplication -UninstallKey $UninstallKey -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -InstallMethod $InstallMethod
				if ($installedAppResults.Count -eq 0) {
					Write-Log -Message "Found no uninstall key with UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Skipped detecting a DisplayVersion." -Severity 2 -Source ${CmdletName}
					$displayVersionResult.DisplayVersion = [string]::Empty
					$displayVersionResult.UninstallKeyExists = $false
				}
				elseif ($installedAppResults.Count -gt 1) {
					Write-Log -Message "Found more than one uninstall key with UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Skipped detecting a DisplayVersion." -Severity 2 -Source ${CmdletName}
					$displayVersionResult.DisplayVersion = [string]::Empty
					$displayVersionResult.UninstallKeyExists = $false
				}
				elseif ($true -eq ([string]::IsNullOrEmpty($installedAppResults.DisplayVersion))) {
					Write-Log -Message "Detected no DisplayVersion for UninstallKey [$UninstallKey] with UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]." -Severity 2 -Source ${CmdletName}
					$displayVersionResult.DisplayVersion = [string]::Empty
					$displayVersionResult.UninstallKeyExists = $true
				}
				else {
					Write-Log -Message "Currently detected display version [$($installedAppResults.DisplayVersion)] for UninstallKey [$UninstallKey] with UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]." -Source ${CmdletName}
					$displayVersionResult.DisplayVersion = $installedAppResults.DisplayVersion
					$displayVersionResult.UninstallKeyExists = $true
				}
				Write-Output $displayVersionResult
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
	.SYNOPSIS
		Retrieves the free space of a specified drive.
	.DESCRIPTION
		The Get-NxtDriveFreeSpace function retrieves the available free space of a given drive in the specified unit.
		By default, it returns the free space in bytes. You can also specify other units such as KB, MB, GB, TB, or PB.
	.PARAMETER DriveName
		Specifies the name of the drive for which the free space needs to be determined.
		This parameter is mandatory.
	.PARAMETER Unit
		Specifies the unit in which the free space should be returned. Possible values are B (default), KB, MB, GB, TB, and PB.
	.EXAMPLE
		Get-NxtDriveFreeSpace -DriveName "c:"
		This example retrieves the free space of the C: drive in bytes.
	.EXAMPLE
		Get-NxtDriveFreeSpace -DriveName "d:" -Unit "GB"
		This example retrieves the free space of the D: drive in gigabytes.
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
			[long]$diskFreekSize = [math]::Floor(($disk.FreeSpace / "$("1$Unit" -replace "1B", "1D")"))
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
	.SYNOPSIS
		Retrieves the type of a specified drive.
	.DESCRIPTION
		The Get-NxtDriveType function determines the type of a given drive.
		The returned drive type can be one of several values, including Unknown, NoRootDirectory, Removable, Local, Network, Compact, and Ram.
		If the drive does not exist or an error occurs, the function returns the drive type as Unknown.
	.PARAMETER DriveName
		Specifies the name of the drive for which the type needs to be determined.
		This parameter is mandatory.
	.EXAMPLE
		Get-NxtDriveType -DriveName "c:"
		This example retrieves the type of the C: drive.
	.OUTPUTS
		PSADTNXT.DriveType
		The drive type is returned as one of the following values:
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
	.SYNOPSIS
		Gets the estimated encoding of a file based on BOM detection, or returns a specified default encoding.
	.DESCRIPTION
		The Get-NxtFileEncoding function returns the estimated encoding of a file based on Byte Order Mark (BOM) detection. If the encoding cannot
		be detected, it will default to the provided DefaultEncoding value or ASCII if no value is specified. This can be used to identify the
		proper encoding for further file operations like reading or writing.
		Returns the detected encoding or the specified default encoding if detection was not possible or file was not found.
	.PARAMETER Path
		Specifies the path to the file for which the encoding needs to be determined. This parameter is mandatory.
	.PARAMETER DefaultEncoding
		Specifies the encoding to be returned in case the encoding could not be detected. Valid options include "Ascii",
		"Default", "UTF7", "BigEndianUnicode", "Oem", "Unicode", "UTF32", "UTF8" and "UTF8withBOM".
	.EXAMPLE
		Get-NxtFileEncoding -Path C:\Temp\testfile.txt
		This example returns the estimated encoding of the file located at "C:\Temp\testfile.txt".
	.EXAMPLE
		Get-NxtFileEncoding -Path C:\Temp\testfile.txt -DefaultEncoding UTF8
		This example returns the estimated encoding of the file located at "C:\Temp\testfile.txt", or "UTF8" if the encoding cannot be detected.
	.OUTPUTS
		System.String.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[String]
		$Path,
		[Parameter()]
		[ValidateSet("Ascii", "Default", "UTF7", "BigEndianUnicode", "Oem", "Unicode", "UTF32", "UTF8", "UTF8withBOM")]
		[String]
		$DefaultEncoding
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ($false -eq (Test-Path -Path $Path)) {
			Write-Log -Message "File '$Path' does not exist." -Severity 2 -Source ${cmdletName}
			if ($true -eq ([string]::IsNullOrEmpty($DefaultEncoding))) {
				Write-Log -Message "No default encoding specified." -Severity 2 -Source ${cmdletName}
			}
			else {
				Write-Log -Message "Returning default encoding '$DefaultEncoding'." -Severity 2 -Source ${cmdletName}
				Write-Output $DefaultEncoding
			}
		}
		else {
			try {
				[string]$intEncoding = [PSADTNXT.Extensions]::GetEncoding($Path)
				if ($true -eq ([System.String]::IsNullOrEmpty($intEncoding))) {
					[string]$intEncoding = $DefaultEncoding
				}
				Write-Output $intEncoding
			}
			catch {
				Write-Log -Message "Failed to run the encoding detection `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
			}
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
	.SYNOPSIS
		Retrieves the version information of a specified file.
	.DESCRIPTION
		The Get-NxtFileVersion function retrieves the version information of a file specified by the FilePath parameter. The return value is the version object representing the file version.
	.PARAMETER FilePath
		Specifies the full path to the file for which the version information needs to be retrieved. This parameter is mandatory.
		Get-NxtFileVersion -FilePath "D:\setup.exe"
		This example retrieves the version information of the file located at "D:\setup.exe".
	.EXAMPLE
		Get-NxtFileVersion "D:\setup.exe"
	.EXAMPLE
		Get-NxtFileVersion "D:\Program Files\App\file.dll"
		This example retrieves the version information of the file located at "D:\Program Files\App\file.dll".
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
		$FilePath
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
	.SYNOPSIS
		Retrieves the size of the specified folder recursively, in the given unit.
	.DESCRIPTION
		The Get-NxtFolderSize function calculates the size of the specified folder, including all of its subfolders and files. It can return the size in different units such as bytes (B), kilobytes (KB), megabytes (MB), gigabytes (GB), terabytes (TB), or petabytes (PB).
	.PARAMETER FolderPath
		Path to the folder. This parameter is mandatory.
	.PARAMETER Unit
		Unit in which the folder size should be returned. Supported values are "B", "KB", "MB", "GB", "TB", "PB". The default value is "B".
	.EXAMPLE
		Get-NxtFolderSize "D:\setup\"
		Retrieves the size of the folder located at "D:\setup\" in bytes.
	.EXAMPLE
		Get-NxtFolderSize "C:\Users\User\Documents" -Unit "MB"
		Retrieves the size of the folder located at "C:\Users\User\Documents" in megabytes.
	.OUTPUTS
		System.Long.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$FolderPath,
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
			[System.IO.FileInfo[]]$files = [System.Linq.Enumerable]::Select([System.IO.Directory]::EnumerateFiles($FolderPath, "*.*", "AllDirectories"), [Func[string, System.IO.FileInfo]] {
				Param ($x) (New-Object -TypeName System.IO.FileInfo -ArgumentList $x)
			})
			[long]$result = [System.Linq.Enumerable]::Sum($files, [Func[System.IO.FileInfo, long]] {
				Param ($x) $x.Length
			})
			[long]$folderSize = [math]::round(($result / "$("1$Unit" -replace "1B", "1D")"))
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
		Wrapped function for Get-InstalledApplication from AppDeployToolkit.
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
		We recommend always adding "$global:PackageConfig.UninstallDisplayName" if used inside a package to exclude the current package itself, especially if combined with the "UninstallKeyContainsWildCards" parameter.
		Defaults to the "DisplayNamesToExcludeFromAppSearches" value from the PackageConfig object.
	.PARAMETER Is64Bit
		The operating system architecture to use for the search. Defaults to PSADT main script's $Is64Bit variable. This is not intended to be used directly.
		Defaults to PSADT Main Script's $Is64Bit variable.
	.PARAMETER InstallMethod
		Filter the results by the installer type. Currently only "MSI" is supported.
	.EXAMPLE
		Get-NxtInstalledApplication -UninstallKey "{12345678-A123-45B6-CD7E-12345FG6H78I}"
	.EXAMPLE
		Get-NxtInstalledApplication -UninstallKey "MyNewApp" -UninstallKeyIsDisplayName $true
	.EXAMPLE
		Get-NxtInstalledApplication -UninstallKey "SomeApp - Version *" -UninstallKeyIsDisplayName $true -UninstallKeyContainsWildCards $true -DisplayNamesToExclude "SomeApp - Version 1.0","SomeApp - Version 1.1",$global:PackageConfig.UninstallDisplayName
	.EXAMPLE
		Get-NxtInstalledApplication -UninstallKey "***MySuperSparklingApp***" -UninstallKeyIsDisplayName $true -UninstallKeyContainsWildCards $false
	.OUTPUTS
		PSObject
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
		[string[]]
		$DisplayNamesToExclude = $global:PackageConfig.DisplayNamesToExcludeFromAppSearches,
		[Parameter(Mandatory = $false, DontShow = $true)]
		[bool]
		$Is64Bit = $Is64Bit,
		[Parameter(Mandatory = $false)]
		[string]
		$InstallMethod
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ($true -eq ([string]::IsNullOrEmpty($UninstallKey))) {
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
				if ("MSI" -eq $InstallMethod) {
					$installedAppResults = $installedAppResults | Where-Object {
						[string]$productRegKeyPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\"
						if ($false -eq $_.Is64BitApplication -and $true -eq $Is64Bit) {
							$productRegKeyPath = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"
						}
						try {
							Write-Output ((Get-ItemProperty -Path ($productRegKeyPath + $_.UninstallSubkey) -ErrorAction Stop).WindowsInstaller -eq 1)
						}
						catch {
							Write-Log "Filtered [$($_.DisplayName)] due to not being an MSI installer." -Source ${cmdletName}
							Write-Output $false
						}
					}
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
	.SYNOPSIS
		Detects if a process is running with the system account or not.
	.DESCRIPTION
		Detects if a process is running with the system account or not by querying the process ID.
	.PARAMETER ProcessId
		Id of the process. This parameter is mandatory.
	.EXAMPLE
		Get-NxtIsSystemProcess -ProcessId 1004
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
		[System.Management.ManagementObject]$process = Get-WmiObject -Class Win32_Process -Filter "ProcessID = $ProcessId"
		if ($null -eq $process) {
			Write-Log -Message "Failed to get process with ID '$ProcessId'." -Severity 2 -Source ${cmdletName}
			Write-Output $false
		}
		else {
			[psobject]$owner = $process.GetOwner()
			if ($true -eq [string]::IsNullOrEmpty($owner.User)) {
				if ($ProcessId -eq 4 -and $process.Name -eq "System") {
					Write-Log -Message "Process with ID '$ProcessId' is the system process." -Source ${cmdletName}
					Write-Output $true
				}
				else {
					Write-Log -Message "Failed to get owner of process with ID '$ProcessId'." -Severity 2 -Source ${cmdletName}
					Write-Output $false
				}
			}
			else {
				[System.Security.Principal.NTAccount]$account = New-Object System.Security.Principal.NTAccount("$($owner.Domain)\$($owner.User)")
				Write-Output $($account.Translate([System.Security.Principal.SecurityIdentifier]).Value -eq "S-1-5-18")
			}
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
	.SYNOPSIS
		Retrieves the NetBIOS user name for a given Security Identifier (SID).
	.DESCRIPTION
		The Get-NxtNameBySid function takes a SID as input and returns the corresponding NetBIOS user name. If the SID is not found, the function returns $null. This can be useful for translating SIDs to recognizable names in various administrative tasks.
	.PARAMETER Sid
		The Security Identifier (SID) to search for. This parameter is mandatory.
	.EXAMPLE
		Get-NxtNameBySid -Sid "S-1-5-21-3072877179-2344900292-1557472252-500"
		This example retrieves the NetBIOS user name for the given SID.
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
	.SYNOPSIS
		Retrieves the Operating System Language as an LCID (Locale Identifier) code.
	.DESCRIPTION
		The Get-NxtOsLanguage function gets the Operating System Language as an LCID Code using the Get-Culture cmdlet.
		It returns the LCID code that represents the current culture settings on the system.
	.EXAMPLE
		Get-NxtOsLanguage
	.OUTPUTS
		System.Int32.
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
	.SYNOPSIS
		Parses a neo42PackageConfig.json file into the global variable $global:PackageConfig.
	.DESCRIPTION
		The Get-NxtPackageConfig function reads the contents of a neo42PackageConfig.json file and parses it into the $global:PackageConfig variable.
		This can be used to retrieve configuration details for a package.
	.PARAMETER Path
		Specifies the path to the Packageconfig.json file.
		Defaults to "$global:Neo42PackageConfigPath". This parameter is mandatory.
	.EXAMPLE
		Get-NxtPackageConfig
		This example parses the neo42PackageConfig.json file at the default path into the $global:PackageConfig variable.
	.EXAMPLE
		Get-NxtPackageConfig -Path "C:\path\to\Packageconfig.json"
		This example specifies a custom path to parse the neo42PackageConfig.json file into the $global:PackageConfig variable.
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
		if ((Get-NxtFileEncoding -Path $Path -DefaultEncoding "UTF8") -notin @("UTF8", "UTF8withBOM")) {
			throw "Failed to parse package configuration: File encoding is not UTF8."
		}
		[PSObject]$global:PackageConfig = Get-Content $Path -Raw -Encoding "UTF8" | ConvertFrom-Json
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
	.SYNOPSIS
		Retrieves the parent process of a given process ID.
	.DESCRIPTION
		The Get-NxtParentProcess function obtains the parent process of a specified child process ID.
		It can optionally retrieve the entire parent hierarchy by using the -Recurse switch.
	.PARAMETER Id
		Specifies the ID of the child process. This parameter is mandatory.
	.PARAMETER Recurse
		A switch that, if provided, continues to retrieve the parent of the parent process, and so on, up the hierarchy.
	.EXAMPLE
		Get-NxtParentProcess -Id 1234
		This example retrieves the parent process of the process with ID 1234.
	.EXAMPLE
		Get-NxtParentProcess -Id 1234 -Recurse
		This example retrieves the entire parent hierarchy of the process with ID 1234.
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
		$Recurse = $false,
		[Parameter(Mandatory=$false)]
		[int[]]
		$ProcessIdsToExcludeFromRecursion = @()
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[System.Management.ManagementBaseObject]$process = Get-WmiObject Win32_Process -filter "ProcessID ='$ID'"
		if ($null -eq $process) {
			Write-Log -Message "Failed to find process with pid '$Id'." -Severity 2 -Source ${cmdletName}
			return
		}
		elseif ($process.ProcessId -eq $process.ParentProcessId) {
			Write-Log -Message "Process with pid '$Id' references itself as parent." -Severity 2 -Source ${cmdletName}
			return
		}
		[System.Management.ManagementBaseObject]$parentProcess = Get-WmiObject Win32_Process -filter "ProcessID ='$($process.ParentProcessId)'"

		Write-Output $parentProcess
		if (
			$true -eq $Recurse -and
			$false -eq [string]::IsNullOrEmpty($parentProcess) -and
			$parentProcess.ParentProcessId -ne $Id -and
			$parentProcess.ParentProcessId -notin $ProcessIdsToExcludeFromRecursion
		) {
			$ProcessIdsToExcludeFromRecursion += $process.ProcessId
			Get-NxtParentProcess -Id ($process.ParentProcessId) -Recurse -ProcessIdsToExcludeFromRecursion $ProcessIdsToExcludeFromRecursion
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
	.SYNOPSIS
		Retrieves the value of a specified process environment variable.
	.DESCRIPTION
		The Get-NxtProcessEnvironmentVariable function retrieves the value of the environment variable available in the current process.
		The process environment variables are merged from the user and system environment variables.
		It returns the value of the environment variable as a System.String if the specified key exists, otherwise, an error will be logged.
	.PARAMETER Key
		Specifies the key of the variable you want to retrieve. This parameter is mandatory.
	.EXAMPLE
		Get-NxtProcessEnvironmentVariable -Key "USERNAME"
		This example retrieves the value of the USERNAME environment variable for the current process.
	.EXAMPLE
		Get-NxtProcessEnvironmentVariable -Key "PATH"
		This example retrieves the value of the PATH environment variable for the current process.
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
	.SYNOPSIS
		Retrieves the name of a process based on its process ID.
	.DESCRIPTION
		The Get-NxtProcessName function returns the name of the process that corresponds to the specified process ID. If the process ID does not exist, an error will
		be logged and the function will return an empty string.
	.PARAMETER ProcessId
		Specifies the ID of the process whose name you want to retrieve. This parameter is mandatory.
	.EXAMPLE
		Get-NxtProcessName -ProcessId 1004
		This example retrieves the name of the process with the ID of 1004.
	.EXAMPLE
		Get-NxtProcessName -ProcessId 5000
		This example attempts to retrieve the name of the process with the ID of 5000. If the process does not exist, it will return an empty string.
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
			[string]$result = (Get-Process -Id $ProcessId -ErrorAction Stop).Name
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
	.SYNOPSIS
		Retrieves the value of the environment variable $env:PROCESSOR_ARCHITEW6432.
	.DESCRIPTION
		The Get-NxtProcessorArchiteW6432 function retrieves the value of the environment variable $env:PROCESSOR_ARCHITEW6432, which is only set in a x86_32 process. It returns an empty string if run under a 64-bit process.
	.PARAMETER PROCESSOR_ARCHITEW6432
		Defines the string to be returned. Defaults to the value of $env:PROCESSOR_ARCHITEW6432.
	.EXAMPLE
		Get-NxtProcessorArchiteW6432
		This example retrieves the value of the $env:PROCESSOR_ARCHITEW6432 environment variable.
	.EXAMPLE
		Get-NxtProcessorArchiteW6432 -PROCESSOR_ARCHITEW6432 "AMD64"
		This example specifies the value "AMD64" for the PROCESSOR_ARCHITEW6432 parameter and returns it.
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
#region Function Get-NxtProcessTree
function Get-NxtProcessTree {
	<#
	.SYNOPSIS
		Get the process tree for a given process ID
	.DESCRIPTION
		This function gets the process tree for a given process ID.
		It uses WMI to get the process, its child processes and the parent processes.
	.PARAMETER ProcessId
		The process ID for which to get the process tree
	.PARAMETER IncludeChildProcesses
		Indicates if child processes should be included in the result.
		Defaults to $true.
	.PARAMETER IncludeParentProcesses
		Indicates if parent processes should be included in the result.
		Defaults to $true.
	.OUTPUTS
		System.Management.ManagementObject[]
	.EXAMPLE
		Get-NxtProcessTree -ProcessId 1234
		Gets the process tree for process with ID 1234 including child and parent processes.
	.EXAMPLE
		Get-NxtProcessTree -ProcessId 1234 -IncludeChildProcesses $false -IncludeParentProcesses $false
		Gets the process tree for process with ID 1234 without child nor parent processes.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	Param (
		[Parameter(Mandatory = $true)]
		[int]
		$ProcessId,
		[Parameter(Mandatory = $false)]
		[bool]
		$IncludeChildProcesses = $true,
		[Parameter(Mandatory = $false)]
		[bool]
		$IncludeParentProcesses = $true
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		## Cache all processes
		[System.Management.ManagementObject[]]$processes = Get-WmiObject -ClassName "Win32_Process"
		## Define script block to get related processes
		[scriptblock]$getRelatedProcesses = {
			Param (
				[System.Management.ManagementObject]
				$Root,
				[System.Management.ManagementObject[]]
				$ProcessTable,
				[switch]
				$Parents
			)
			## Get related processes
			[System.Management.ManagementObject[]]$relatedProcesses = @(
				$ProcessTable | Where-Object {
					$_.ProcessId -ne $Root.ProcessId -and (
						($true -eq $Parents -and $_.ProcessId -eq $Root.ParentProcessId) -or
						($false -eq $Parents -and $_.ParentProcessId -eq $Root.ProcessId)
					)
				}
			)
			## Recurse to get related processes of related processes
			foreach ($process in $relatedProcesses) {
				$relatedProcesses += & $getRelatedProcesses -Root $process -Parents:$Parents -ProcessTable @(
					$ProcessTable | Where-Object {
						$relatedProcesses.ProcessId -notcontains $_.ProcessId
					}
				)
			}
			Write-Output $relatedProcesses
		}
	}
	Process {
		[System.Management.ManagementObject]$rootProcess = $processes | Where-Object {
			$_.ProcessId -eq $ProcessId
		}
		if ($null -eq $rootProcess) {
			Write-Log "Process with ID [$ProcessId] not found." -Source ${cmdletName}
			return
		}
		[System.Management.ManagementObject[]]$processTree = @($rootProcess)
		if ($true -eq $IncludeChildProcesses) {
			$processTree += & $getRelatedProcesses -Root $rootProcess -ProcessTable $processes
		}
		if ($true -eq $IncludeParentProcesses) {
			$processTree += & $getRelatedProcesses -Root $rootProcess -ProcessTable $processes -Parents
		}
		Write-Output $processTree
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Get-NxtRebootRequirement
function Get-NxtRebootRequirement {
	<#
	.SYNOPSIS
		Sets $script:msiRebootDetected if a reboot is required.
	.DESCRIPTION
		Tests if a reboot is required based on $msiRebootDetected and Reboot from the packageconfig.
		To automatically apply the decision to the any call of Exit-Script use the -ApplyDecision switch.
	.PARAMETER MsiRebootDetected
		Defaults to $script:msiRebootDetected.
	.PARAMETER Reboot
		Indicates if a reboot is required by the script.
		0 = Decide based on $msiRebootDetected
		1 = Reboot required
		2 = Reboot not required.
		Defaults to $global:PackageConfig.Reboot.
	.OUTPUTS
		PSADTNXT.NxtRebootResult.
	.EXAMPLE
		Get-NxtRebootRequirement
		Tests RebootRequirement based on $msiRebootDetected and $Reboot.
	.EXAMPLE
		Get-NxtRebootRequirement -MsiRebootDetected $true -Reboot 0
		Gets MainExitCode 3010.
	.NOTES
		This is an internal script function and should typically not be called directly.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[bool]
		$MsiRebootDetected = $script:msiRebootDetected,
		[Parameter(Mandatory = $false)]
		[ValidateSet(0,1,2)]
		[int]
		$Reboot = $global:PackageConfig.Reboot
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[PSADTNXT.NxtRebootResult]$rebootResult = New-Object -TypeName PSADTNXT.NxtRebootResult
		switch ($Reboot) {
			0 {
				if ($true -eq $MsiRebootDetected) {
					Write-Log -Message "Detected Reboot required by an (un)installation" -Severity 1 -Source ${CmdletName}
					$rebootResult.MainExitCode = 3010
					$rebootResult.Message = "Found reboot required by an (un)installation"
				}
				else {
					Write-Log -Message "Found no reboot required by an (un)installation" -Severity 1 -Source ${CmdletName}
					$rebootResult.MainExitCode = 0
					$rebootResult.Message = "Found no reboot required by an (un)installation"
				}
			}
			1 {
				Write-Log -Message "Reboot required by script" -Severity 1 -Source ${CmdletName}
				$rebootResult.MainExitCode = 3010
				$rebootResult.Message = "Reboot required by script"
			}
			2 {
				Write-Log -Message "Reboot not required by script" -Severity 1 -Source ${CmdletName}
				$rebootResult.MainExitCode = 0
				$rebootResult.Message = "Reboot not required by script"
			}
			default {
				Write-Log -Message "Invalid value for parameter Reboot: $Reboot" -Severity 3 -Source ${CmdletName}
				throw "Invalid value for parameter Reboot: $Reboot"
			}
		}
		Write-Output $rebootResult
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
		"0" represents that the package is not installed.
		"1" represents that the package is installed.
	.PARAMETER RegPackagesKey
		Defines the name of the registry key keeping track of all packages delivered by this packaging framework.
		Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Get-NxtRegisteredPackage -PackageGUID "{12345678-1234-1234-1234-123456789012}"
		This example retrieves information about a specific package using its PackageGUID.
	.EXAMPLE
		Get-NxtRegisteredPackage -ProductGUID "{12345678-1234-1234-1234-123456789012}"
		This example retrieves information about a specific product using its ProductGUID.
	.EXAMPLE
		Get-NxtRegisteredPackage -ProductGUID "{12345678-1234-1234-1234-123456789012}" -InstalledState 1
		This example retrieves information about a specific product that is installed.
	.EXAMPLE
		Get-NxtRegisteredPackage -ProductGUID "{12345678-1234-1234-1234-123456789012}" -InstalledState 0
		This example retrieves information about a specific product that is registered but not installed.
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
			if ($true -eq ([string]::IsNullOrEmpty($PackageGUID))) {
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
		Detects if the target application is already installed and verifies conditions for a soft migration.
	.DESCRIPTION
		Uses registry values and various parameters to detect the application in target or higher versions, and verifies whether conditions are met for a soft migration.
		Soft migration refers to the process of determining if the application is already present and if it is, whether it is a higher version than the one being installed.
	.PARAMETER PackageRegisterPath
		Specifies the registry path used for the registered package entries.
		Defaults to the default location under "HKLM:\Software" constructed with corresponding values from the PackageConfig objects of 'RegPackagesKey' and 'PackageGUID'.
	.PARAMETER SoftMigration
		Specifies if a Software should be registered only if it already exists through a different installation.
		Defaults to the corresponding value from the Setup.cfg.
	.PARAMETER DisplayVersion
		Specifies the DisplayVersion of the software package.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKey
		Specifies the original UninstallKey set by the Installer in this Package.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER SoftMigrationFileName
		Specifies a file name depending a SoftMigration of the software package.
		Defaults to the corresponding value from the PackageConfig object $global:PackageConfig.SoftMigration.File.FullNameToCheck.
	.PARAMETER SoftMigrationFileVersion
		Specifies the file version of the file name specified depending a SoftMigration of the software package.
		Defaults to the corresponding value from the PackageConfig object $global:PackageConfig.SoftMigration.File.VersionToCheck.
	.PARAMETER SoftMigrationCustomResult
		Specifies the result of a custom check routine for a SoftMigration of the software package.
		Defaults to the corresponding value from the Deploy-Aplication.ps1 object $global:SoftMigrationCustomResult.
	.PARAMETER RegisterPackage
		Specifies if package may be registered.
		Defaults to the corresponding global value.
	.PARAMETER RemovePackagesWithSameProductGUID
		Defines wether to uninstall all found application packages with same ProductGUID (product membership) assigned.
		The uninstalled application packages stay registered, when removed during installation process of current application package.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyIsDisplayName
		Defines if the UninstallKey is the DisplayName of the application package.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyContainsWildCards
		Defines if the UninstallKey contains wildcards.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER DisplayNamesToExclude
		Defines an array of DisplayNames to exclude from the search.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER ProductGUID
		Specifies the ProductGUID of the software package.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegPackagesKey
		Defines the name of the registry key keeping track of all packages delivered by this packaging framework.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER InstallMethod
		Specifies the installation method of the software package.
		Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Get-NxtRegisterOnly
		This example detects if the target application is already installed and verifies conditions for a soft migration based on the values from the PackageConfig object.
	.EXAMPLE
		Get-NxtRegisterOnly -SoftMigrationFileName "C:\Program Files\MyApp\MyApp.exe" -RegisterPackage $true
		This example detects if the target application is already installed and verifies conditions for a soft migration based on the values from the PackageConfig object and the specified SoftMigrationFileName.
	.EXAMPLE
		Get-NxtRegisterOnly -SoftMigrationCustomResult $selfScriptedSoftmigrationConditionCheckResult -RegisterPackage $true
		This example detects if the target application is already installed and verifies conditions for a soft migration based on the values from the PackageConfig object and the specified SoftMigrationCustomResult.
	.OUTPUTS
		System.Boolean.
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
		$RemovePackagesWithSameProductGUID = $global:PackageConfig.RemovePackagesWithSameProductGUID,
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
		$ProductGUID = $global:PackageConfig.ProductGUID,
		[Parameter(Mandatory = $false)]
		[string]
		$RegPackagesKey = $global:PackageConfig.RegPackagesKey,
		[Parameter(Mandatory = $false)]
		[string]
		$AppVersion = $global:PackageConfig.AppVersion,
		[Parameter(Mandatory = $false)]
		[string]
		$InstallMethod = $global:PackageConfig.UninstallMethod
	)
	if ($false -eq $RegisterPackage) {
		Write-Log -Message 'Package should not be registered. Performing an (re)installation depending on found application state...' -Source ${cmdletName}
		Write-Output $false
	}
	elseif (
		($true -eq $SoftMigration) -and ($AppVersion -ne (Get-RegistryKey -Key $PackageRegisterPath -Value 'Version')) -and
			(
				((Get-NxtRegisteredPackage -ProductGUID $ProductGUID -RegPackagesKey $RegPackagesKey | Where-Object PackageGUID -ne $PackageGUID).count -eq 0) -or
				$false -eq $RemovePackagesWithSameProductGUID
			)
		) {
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
			[string]$currentlyDetectedDisplayVersion = (
					Get-NxtCurrentDisplayVersion -UninstallKey $UninstallKey -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -InstallMethod $InstallMethod
				).DisplayVersion
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
	elseif ( ($false -eq $SoftMigration) -and ($false -eq (Test-RegistryValue -Key $PackageRegisterPath -Value 'ProductName')) ) {
		Write-Log -Message 'SoftMigration is disabled. Performing an (re)installation depending on found application state...' -Source ${cmdletName}
		Write-Output $false
	}
	else {
		Write-Log -Message 'No valid conditions for SoftMigration present.' -Source ${cmdletName}
		Write-Output $false
	}
}
#endregion
#region Function Get-NxtRunningProcesses
function Get-NxtRunningProcesses {
	<#
	.SYNOPSIS
		Retrieves a list of running processes based on provided process objects, adding a 'ProcessDescription' property to each.
	.DESCRIPTION
		This function scans for running processes that match the names specified in the provided process objects.
		It enhances the output by appending a 'ProcessDescription' property to each identified process.
		This function is particularly useful for monitoring specific processes or applications.
	.PARAMETER ProcessObjects
		An array of custom objects, each representing a process to check for.
		These objects should contain at least a 'ProcessName' property. If not supplied, the function returns $null.
	.PARAMETER DisableLogging
		If specified, disables logging within the function, making its execution silent.
	.PARAMETER ProcessIdToIgnore
		An array of process IDs. Processes with these IDs, and their child processes, will be excluded from the search.
	.OUTPUTS
		Diagnostics.Process[]
		Returns a list of processes that match the conditions specified.
	.EXAMPLE
		Get-NxtRunningProcesses -ProcessObjects $ProcessObjects
	.NOTES
		This is an internal script function and should typically not be called directly.
	.NOTES
		This function is a modified version of Get-RunningProcesses from the PSAppDeployToolkit licensed under the LGPLv3.
	.LINK
		https://psappdeploytoolkit.com
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false, Position = 0)]
		[PSObject[]]
		$ProcessObjects,
		[Parameter(Mandatory = $false, Position = 1)]
		[Switch]
		$DisableLogging = $DisableLogging,
		[Parameter(Mandatory = $false)]
		[int[]]
		$ProcessIdsToIgnore
	)
	Begin {
		## Get the name of this function and write header
		[String]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		if ($processObjects -and $processObjects[0].ProcessName) {
			[string]$runningAppsCheck = $processObjects.ProcessName -join ','
			if ($false -eq $DisableLogging) {
				Write-Log -Message "Checking for running applications: [$runningAppsCheck]" -Source ${CmdletName}
			}
			[array]$wqlProcessObjects = $processObjects | Where-Object {
				$true -eq $_.IsWql
			}
			[array]$processesFromWmi = $(
				foreach ($wqlProcessObject in $wqlProcessObjects) {
					Get-WmiObject -Class Win32_Process -Filter $wqlProcessObject.ProcessName | Select-Object name,ProcessId,@{
						n = "QueryUsed"
						e = {
							$wqlProcessObject.ProcessName
						}
					}
				}
			)
			## Prepare a filter for Where-Object
			[ScriptBlock]$whereObjectFilter = {
				foreach ($processObject in $processObjects) {
					if ($ProcessIdsToIgnore -contains $_.Id) {
						continue
					}
					[bool]$processFound = $false
					if ($true -eq $processObject.IsWql) {
						[int]$processId = $_.Id
						[string]$queryUsed = $processObject.ProcessName
						if (($processesFromWmi | Where-Object {
							$_.ProcessId -eq $processId -and
							$_.QueryUsed -eq $queryUsed
						}).count -ne 0
							) {
							$processFound = $true
						}
					}
					elseif ($_.ProcessName -ieq $processObject.ProcessName) {
						$processFound = $true
					}
					if ($true -eq $processFound) {
						if ($false -eq [string]::IsNullOrEmpty($processObject.ProcessDescription)) {
							#  The description of the process provided as a parameter to the function, e.g. -ProcessName "winword=Microsoft Office Word".
							Add-Member -InputObject $_ -MemberType 'NoteProperty' -Name 'ProcessDescription' -Value $processObject.ProcessDescription -Force -PassThru -ErrorAction 'SilentlyContinue'
						}
						elseif ($false -eq [string]::IsNullOrEmpty($_.Description)) {
							#  If the process already has a description field specified, then use it
							Add-Member -InputObject $_ -MemberType 'NoteProperty' -Name 'ProcessDescription' -Value $_.Description -Force -PassThru -ErrorAction 'SilentlyContinue'
						}
						else {
							#  Fall back on the process name if no description is provided by the process or as a parameter to the function
							Add-Member -InputObject $_ -MemberType 'NoteProperty' -Name 'ProcessDescription' -Value $_.ProcessName -Force -PassThru -ErrorAction 'SilentlyContinue'
						}
						Write-Output -InputObject ($true)
						return
					}
				}

				Write-Output -InputObject ($false)
				return
			}
			## Get all running processes and escape special characters. Match against the process names to search for to find running processes.
			[Diagnostics.Process[]]$runningProcesses = Get-Process | Where-Object -FilterScript $whereObjectFilter | Sort-Object -Property 'ProcessName'

			if ($false -eq $DisableLogging) {
				if ($runningProcesses.Count -ne 0) {
					[String]$runningProcessList = ($runningProcesses.ProcessName | Select-Object -Unique) -join ','
					Write-Log -Message "The following processes are running: [$runningProcessList]." -Source ${CmdletName}
				}
				else {
					Write-Log -Message 'Specified applications are not running.' -Source ${CmdletName}
				}
			}
			Write-Output -InputObject ($runningProcesses)
		}
		else {
			Write-Output -InputObject ($null)
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Get-NxtServiceState
function Get-NxtServiceState {
	<#
	.SYNOPSIS
		Retrieves the state of a specified service on the system.
	.DESCRIPTION
		The Get-NxtServiceState function gets the current state of the service specified by the ServiceName parameter.
		The state can be one of the following values: "Running," "Stopped," "Paused," etc.
		If the specified service is not found, the function returns $null.
		Returns the current state of the specified service as a string.
	.PARAMETER ServiceName
		Specifies the name of the service to get the state for. This parameter is mandatory.
	.EXAMPLE
		Get-NxtServiceState "BITS"
		Retrieves the current state of the Background Intelligent Transfer Service (BITS).
	.OUTPUTS
		System.String
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
			if ($null -ne $service) {
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
	.SYNOPSIS
		Retrieves the Security Identifier (SID) for a specified user name.
	.DESCRIPTION
		The Get-NxtSidByName function fetches the SID corresponding to a given user name.
		It searches for the user on the system and returns the SID if the user is found.
		If the specified user is not found, the function returns $null.
		This function might be stressful for the domain controller, so use it with caution.
	.PARAMETER UserName
		Specifies the user name for which to fetch the SID. This parameter is mandatory.
	.EXAMPLE
		Get-NxtSidByName -UserName "Workgroup\Administrator"
		Retrieves the SID for the Administrator user in the Workgroup.
	.EXAMPLE
		Get-NxtSidByName -UserName "DOMAIN\User"
		Retrieves the SID for the User in the specified DOMAIN.
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
		$UserName
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[string]$sid = (Get-WmiObject -Query "Select SID from Win32_UserAccount Where Caption LIKE '$($UserName.Replace("\","\\").Replace("\\\\","\\"))'").Sid
			if ($true -eq ([string]::IsNullOrEmpty($sid))) {
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
	.SYNOPSIS
		Retrieves the value of a specified system environment variable.
	.DESCRIPTION
		The Get-NxtSystemEnvironmentVariable function retrieves the value of a system environment variable
		identified by the Key parameter. The value is read from the machine-level environment variables.
		Returns the value of the specified system environment variable as a string.
	.PARAMETER Key
		Specifies the key of the system environment variable to retrieve. This parameter is mandatory.
	.EXAMPLE
		Get-NxtSystemEnvironmentVariable "windir"
		Retrieves the value of the system environment variable for the Windows directory.
	.EXAMPLE
		Get-NxtSystemEnvironmentVariable "Path"
		Retrieves the value of the system Path environment variable.
	.OUTPUTS
		System.String.
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
	.SYNOPSIS
		Retrieves the UI Language as an LCID Code from the current UI Culture.
	.DESCRIPTION
		The Get-NxtUILanguage cmdlet obtains the UI Language as an LCID (Locale Identifier) Code by calling the Get-UICulture cmdlet.
		This can be useful in scenarios where you need to identify the specific language code associated with the user interface culture on the system.
	.EXAMPLE
		Get-NxtUILanguage
		Returns the LCID code representing the UI language of the current system.
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
		Gets environment variables set by the deployment system and overwrites the corresponding global variables.
	.DESCRIPTION
		The Get-NxtVariablesFromDeploymentSystem cmdlet retrieves environment variables set by the deployment system and assigns specific values to global variables. It should be called at the end of the variable definition section of any 'Deploy-Application.ps1'. Variables not set by the deployment system (or set to an unsuitable value) receive a default value. Variables set by the deployment system overwrite the values from the neo42PackageConfig.json.
	.PARAMETER RegisterPackage
		Value to set $global:RegisterPackage to.
		Defaults to $env:registerPackage.
		Usually, packages are registered. A value of "false" for the $env:registerPackage environmental variable prevents this step.
	.PARAMETER DeploymentType
		The type of deployment that is performed.
		Defaults to the corresponding call parameter of the Deploy-Application.ps1 script.
	.EXAMPLE
		Get-NxtVariablesFromDeploymentSystem
		Configures the global variables based on the corresponding environment variables.
	.OUTPUTS
		none.
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
		$DeploymentType = $DeploymentType
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
				Write-Log -Message "Package registration on installation will be prevented because the environment variable '`$env:PackageRegister' is set to 'false'." -Severity 2 -Source ${cmdletName}
			}
			else {
				[bool]$global:RegisterPackage = $true
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
	.SYNOPSIS
		Translates the environment variable $env:PROCESSOR_ARCHITECTURE from "x86" or "AMD64" to 32 or 64.
	.DESCRIPTION
		This function takes the environment variable $env:PROCESSOR_ARCHITECTURE and translates it to either 32 or 64 depending on whether the architecture is "x86" or "AMD64". This is useful for installing applications that have different installers for 32-bit and 64-bit systems.
	.PARAMETER ProcessorArchitecture
		Accepts the string "x86" or "AMD64".
		Defaults to $env:PROCESSOR_ARCHITECTURE.
	.EXAMPLE
		Get-NxtWindowsBits
		Returns 32 or 64 depending on the architecture of the system.
	.EXAMPLE
		Get-NxtWindowsBits -ProcessorArchitecture "AMD64"
		Returns 64.
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
	.SYNOPSIS
		Gets the Windows Version (CurrentVersion) from the Registry.
	.DESCRIPTION
		This function retrieves the current Windows Version from the system's registry. It queries the specific registry path to obtain the version of the installed Windows operating system.
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
		Imports an INI file into a PowerShell object.
	.DESCRIPTION
		This function reads the specified INI file and converts it into a PowerShell hashtable object. It handles various INI file structures and can read sections, and key-value pairs.
	.PARAMETER Path
		The path to the INI file. This parameter is mandatory.
	.PARAMETER ContinueOnError
		Specifies whether the function continues to execute if an error occurs. Accepts $true or $false. Defaults to $true.
	.EXAMPLE
		Import-NxtIniFile -Path C:\path\to\ini\file.ini
		This example reads the specified INI file and converts it into a PowerShell hashtable object.
	.EXAMPLE
		Import-NxtIniFile -Path C:\path\to\ini\file.ini -ContinueOnError $false
		This example reads the specified INI file and converts it into a PowerShell hashtable object. If an error occurs, the function stops executing and throws an error.
	.OUTPUTS
		System.Collections.Hashtable.
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
			[hashtable]$ini = [hashtable]::new([StringComparer]::OrdinalIgnoreCase)
			$ini.default = [hashtable]::new([StringComparer]::OrdinalIgnoreCase)
			[string]$section = 'default'
			[string[]]$content = Get-Content -Path $Path
			foreach ($line in $content) {
				if ($line -match '^\[(.+)\]$') {
					[string]$section = $matches[1]
					if ($false -eq ($ini.ContainsKey($section))) {
						[hashtable]$ini[$section] = [hashtable]::new([StringComparer]::OrdinalIgnoreCase)
					}
				}
				elseif ($line -match '^(;|#)') {
					continue
				}
				elseif ($line -match '^(.+?)\s*=\s*(.*)$') {
					[string]$variableName = $matches[1]
					[string]$value = $matches[2].Trim()
					[string]$ini[$section][$variableName] = $value
				}
			}
			if ($ini.default.count -eq 0) {
				$ini.Remove('default')
			}
			Write-Output $ini
			Write-Log -Message "Read ini file [$path]. " -Source ${CmdletName}
		}
		catch {
			Write-Log -Message "Failed to read ini file [$path]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			if ($false -eq $ContinueOnError) {
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
		Imports an INI file, including comments, into a PowerShell object.
	.DESCRIPTION
		This function reads the specified INI file and converts it into a PowerShell hashtable object, including comments. Sections, comments, and key-value pairs are structured into the hashtable, allowing easy access in PowerShell.
	.PARAMETER Path
		The path to the INI file. This parameter is mandatory.
	.PARAMETER ContinueOnError
		Specifies whether the function continues to execute if an error occurs. Accepts $true or $false. Defaults to $true.
	.EXAMPLE
		Import-NxtIniFileWithComments -Path C:\path\to\ini\file.ini
	.EXAMPLE
		Import-NxtIniFileWithComments -Path C:\path\to\ini\file.ini -ContinueOnError $false
	.OUTPUTS
		System.Collections.Hashtable.
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
			[hashtable]$ini = [hashtable]::new([StringComparer]::OrdinalIgnoreCase)
			$ini.default = [hashtable]::new([StringComparer]::OrdinalIgnoreCase)
			[string]$section = 'default'
			[string[]]$commentBuffer = @()
			[string[]]$content = Get-Content -Path $Path
			foreach ($line in $content) {
				if ($line -match '^\[(.+)\]$') {
					[string]$section = $matches[1]
					if ($false -eq $ini.ContainsKey($section)) {
						[hashtable]$ini[$section] = [hashtable]::new([StringComparer]::OrdinalIgnoreCase)
					}
				}
				elseif ($line -match '^(;|#)\s*(.*)') {
					[array]$commentBuffer += $matches[2].trim("; ")
				}
				elseif ($line -match '^(.+?)\s*=\s*(.*)$') {
					[string]$variableName = $matches[1]
					[string]$value = $matches[2].Trim()
					[hashtable]$ini[$section][$variableName] = [hashtable]::new([StringComparer]::OrdinalIgnoreCase)
					$ini[$section][$variableName]["Value"] = $value
					$ini[$section][$variableName]["Comments"] = $commentBuffer -join "`r`n"
					[array]$commentBuffer = @()
				}
			}
			if ($ini.default.count -eq 0) {
				$ini.Remove('default')
			}
			Write-Output $ini
			Write-Log -Message "Read ini file [$path]. " -Source ${CmdletName}
		}
		catch {
			if ($false -eq $ContinueOnError) {
				throw "Failed to read ini file [$path]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Import-NxtXmlFile
function Import-NxtXmlFile {
	<#
	.SYNOPSIS
		Imports an XML file into a PowerShell object.
	.DESCRIPTION
		This function reads the specified XML file and converts it into a PowerShell object.
	.PARAMETER Path
		The path to the XML file. This parameter is mandatory.
	.PARAMETER Encoding
		The encoding of the XML file.
	.PARAMETER DefaultEncoding
		The default encoding to use if the encoding of the XML file could not be determined.
		The best practice is to use UTF8 with BOM as the default encoding.
	.PARAMETER ContinueOnError
		Specifies whether the function continues to execute if an error occurs. Accepts $true or $false. Defaults to $true.
	.OUTPUTS
		System.Xml.XmlDocument.
	.EXAMPLE
		Import-NxtXmlFile -Path C:\path\to\xml\file.xml
		This example reads the specified XML file and converts it into a PowerShell object.
	.EXAMPLE
		Import-NxtXmlFile -Path C:\path\to\xml\file.xml -ContinueOnError $false
		This example reads the specified XML file and converts it into a PowerShell object. If an error occurs, the function stops executing and throws an error.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[string]
		$Path,
		[Parameter(Mandatory = $false)]
		[string]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		$Encoding,
		[Parameter(Mandatory = $false)]
		[string]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		$DefaultEncoding = 'UTF8withBom',
		[Parameter(Mandatory = $false)]
		[bool]
		$ContinueOnError = $true
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ($false -eq (Test-Path -Path $Path)) {
			Write-Log -Message "File [$Path] not found." -Severity 3 -Source ${cmdletName}
			if ($false -eq $ContinueOnError) {
				throw "File [$Path] not found."
			}
		}
		[String]$intEncoding = $Encoding
		if ($true -eq [string]::IsNullOrEmpty($intEncoding)) {
			try {
				[hashtable]$getFileEncodingParams = @{
					Path = $Path
				}
				if ($false -eq ([string]::IsNullOrEmpty($DefaultEncoding))) {
					[string]$getFileEncodingParams['DefaultEncoding'] = $DefaultEncoding
				}
				$intEncoding = (Get-NxtFileEncoding @getFileEncodingParams)
			}
			catch {
				$intEncoding = $DefaultEncoding
			}
		}
		switch ($intEncoding) {
			'UTF8' {
				[System.Text.Encoding]$fileEncoding = New-Object System.Text.UTF8Encoding($false)
			}
			'UTF8withBom' {
				[System.Text.Encoding]$fileEncoding = New-Object System.Text.UTF8Encoding($true)
			}
			default {
				[System.Text.Encoding]$fileEncoding = [System.Text.Encoding]::$intEncoding
			}
		}
		try {
			[System.IO.StreamReader]$streamReader = [System.IO.StreamReader]::new($Path, $fileEncoding)
			[string]$fileContent = $streamReader.ReadToEnd()
			$streamReader.Close()
		}
		catch {
			Write-Log -Message "Failed to read file content. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
			if ($false -eq $ContinueOnError) {
				throw "Failed to read file content."
			}
		}
		finally {
			$streamReader.Close()
		}
		try {
			[System.Xml.XmlDocument]$xml = [System.Xml.XmlDocument]::new()
			$xml.LoadXml($fileContent)
			Write-Output $xml
			Write-Log -Message "Read xml file [$path]. " -Source ${cmdletName}
		}
		catch {
			Write-Log -Message "Failed to read xml file [$path]. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
			if ($false -eq $ContinueOnError) {
				throw "Failed to read xml file [$path]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Initialize-NxtAppRootFolder
function Initialize-NxtAppRootFolder {
	<#
	.SYNOPSIS
		Sets up the App Root Folder and forces predefined permissions on the folder.
	.DESCRIPTION
		This function is designed to prepare the application root directory (AppRootFolder) by verifying paths, setting appropriate permissions, and creating necessary directories.
		It should be invoked by the 'Initialize-NxtEnvironment' function as part of a broader initialization process.
		The function ensures that the AppRootFolder is correctly configured.
	.PARAMETER BaseName
		The base name of the folder. This parameter is mandatory.
	.PARAMETER RegPackagesKey
		Defines the name of the registry key keeping track of all packages delivered by this packaging framework.
		Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Initialize-NxtAppRootFolder
	.OUTPUTS
		System.String
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$BaseName,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$RegPackagesKey
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[char[]]$invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
		[string]$invalidCharsRegex = "[$([regex]::Escape($invalidChars -join [string]::Empty))]"
		if ($BaseName -match $invalidCharsRegex) {
			throw "The '$BaseName' contains invalid characters."
		}
		## Get AppRootFolderNames we have claimed from the registry
		if ($true -eq (Test-RegistryValue -Key "HKLM:\Software\$RegPackagesKey" -Value "AppRootFolderNames")) {
			[string[]]$appRootFolderNames = Get-RegistryKey "HKLM:\Software\$RegPackagesKey" -Value "AppRootFolderNames"
		}
		else {
			[string[]]$appRootFolderNames = @()
		}
		[string]$appRootFolderName = foreach ($name in $appRootFolderNames) {
			if ($Name -eq $BaseName) {
				Write-Log -Message "AppRootFolderName with Name '$Name' found." -Source ${CmdletName}
				$Name
				break
			}
			if ($Name -match "^$BaseName.{8}$") {
				Write-Log -Message "AppRootFolderName with Name '$Name' found." -Source ${CmdletName}
				$Name
				break
			}
		}
		if ($true -eq ([string]::IsNullOrEmpty($appRootFolderName))) {
			## Claim an ApprootFolder
			if ($false -eq (Test-Path -Path $env:ProgramData\$BaseName)) {
				New-NxtFolderWithPermissions -Path $env:ProgramData\$BaseName -FullControlPermissions BuiltinAdministratorsSid,LocalSystemSid -ReadAndExecutePermissions BuiltinUsersSid -Owner BuiltinAdministratorsSid -ProtectRules $true | Out-Null
				$appRootFolderNames += $BaseName
				Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey" -Name "AppRootFolderNames" -Value $appRootFolderNames -Type MultiString -ContinueOnError $false
				$appRootFolderName = $BaseName
			}
			else {
				## use a foldername with a random suffix
				[string]$randomSuffix = [System.Guid]::NewGuid().ToString().Substring(0,8)
				New-NxtFolderWithPermissions -Path $env:ProgramData\$BaseName$randomSuffix -FullControlPermissions BuiltinAdministratorsSid,LocalSystemSid -ReadAndExecutePermissions BuiltinUsersSid -Owner BuiltinAdministratorsSid -ProtectRules $true | Out-Null
				$appRootFolderNames += "$BaseName$randomSuffix"
				Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey" -Name "AppRootFolderNames" -Value $appRootFolderNames -Type MultiString -ContinueOnError $false
				$appRootFolderName = "$BaseName$randomSuffix"
			}
		}
		if ($appRootFolderName.length -ne 0) {
			if ($false -eq (Test-Path -PathType Container "$env:ProgramData\$appRootFolderName")) {
				New-NxtFolderWithPermissions -Path $env:ProgramData\$appRootFolderName -FullControlPermissions BuiltinAdministratorsSid,LocalSystemSid -ReadAndExecutePermissions BuiltinUsersSid -Owner BuiltinAdministratorsSid -ProtectRules $true | Out-Null
				Write-Log -Message "Recreated AppRootFolder '$appRootFolderName' in $env:ProgramData\$appRootFolderName, this directory is required for software deployment and should not be deleted or altered." -Source ${CmdletName} -Severity 2
			}
			if ($false -eq (Test-Path -PathType Leaf "$env:ProgramData\$appRootFolderName\readme.txt")) {
				Set-Content -Path "$env:ProgramData\$appRootFolderName\readme.txt" -Value "This directory is required for software deployment and should not be deleted or altered." -Encoding "UTF8"
				Write-Log -Message "Created readme file in $env:ProgramData\$appRootFolderName" -Source ${CmdletName}
			}
			if ($false -eq (Test-Path -Path "HKLM:\Software\$RegPackagesKey\neo42APD")) {
				New-Item -Path "HKLM:\Software\$RegPackagesKey\neo42APD" -Force | Out-Null
				New-ItemProperty -Path "HKLM:\Software\$RegPackagesKey\neo42APD" -Name "CreationDate" -Value (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") -PropertyType String -Force | Out-Null
			}
			Write-Output "$env:ProgramData\$appRootFolderName"
		}
		else {
			throw "Failed to find or create AppRootFolderName"
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
	.SYNOPSIS
		Initializes all neo42 functions and variables for package deployment.
	.DESCRIPTION
		Initializes all neo42 functions and variables that are essential for deployment scripts.
		This includes parsing the neo42PackageConfig.json and setting global variables for package configuration.
		It should be called at the beginning of any 'Deploy-Application.ps1' script.
	.PARAMETER PackageConfigPath
		Defines the path to the Packageconfig.json to be loaded to the global packageconfig Variable.
		Defaults to "$global:Neo42PackageConfigPath".
	.PARAMETER SetupCfgPath
		Defines the path to the Setup.cfg to be loaded to the global setupcfg Variable.
		Defaults to "$global:SetupCfgPath".
	.PARAMETER CustomSetupCfgPath
		Defines the path to the Setup.cfg to be loaded to the global setupcfg Variable. If this parameter is set, the values from the found file will override the values from the Setup.cfg.
		Defaults to "$global:CustomSetupCfgPath".
	.PARAMETER SetupCfgPathOverride
		Defines the path to the Setup.cfg to be loaded to the global setupcfg Variable.
		Defaults to "$env:temp\$($global:Packageconfig.RegPackagesKey)\$($global:Packageconfig.PackageGUID)".
		This path is used to replace the Setup.cfg with a custom file in the $App Directory.
	.PARAMETER App
		This parameter can not be set manually for this function!
		Defines the path to a local persistent cache for installation files.
		Defaults to the corresponding value from the PackageConfig object after it has been set within this function.
	.PARAMETER DeploymentType
		The type of deployment that is performed.
		Defaults to the corresponding call parameter of the Deploy-Application.ps1 script.
	.OUTPUTS
		System.Int32.
	.EXAMPLE
		Initialize-NxtEnvironment
		Initializes all neo42 functions and variables that are essential for deployment scripts, using the default values.
	.EXAMPLE
		Initialize-NxtEnvironment -PackageConfigPath "C:\path\to\config.json" -SetupCfgPath "C:\path\to\setup.cfg"
		Initializes all neo42 functions and variables that are essential for deployment scripts, using the specified values.
	.OUTPUTS
		System.Int32.
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
		$SetupCfgPathOverride = "$env:SystemRoot\system32\config\systemprofile\AppData\Roaming\neo42\$($global:Packageconfig.RegPackagesKey)\$($global:Packageconfig.PackageGUID)",
		[Parameter(Mandatory = $false)]
		[string]
		$App = $ExecutionContext.InvokeCommand.ExpandString($global:PackageConfig.App),
		[Parameter(Mandatory = $false)]
		[string]
		$DeploymentType = $DeploymentType,
		[Parameter(Mandatory = $false)]
		[string]
		$ScriptRoot = $scriptroot
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		Get-NxtPackageConfig -Path $PackageConfigPath
		## $App and $SetupCfgPathOverride are not expanded at this point so we have to reset them after the Get-NxtPackageConfig.
		## $AppRootFolder and $RegPackagesKey have to be taken from the newly set $global:PackageConfig.
		if ($true -eq [string]::IsNullOrEmpty($global:PackageConfig.AppRootFolder)) {
			Write-Log -Message "Required parameter 'AppRootFolder' is not set. Please check your PackageConfig.json" -Severity 1 -Source ${CmdletName}
			throw "Required parameter 'AppRootFolder' is not set. Please check your PackageConfig.json"
		}
		[string]$global:PackageConfig.AppRootFolder = Initialize-NxtAppRootFolder -BaseName $global:PackageConfig.AppRootFolder -RegPackagesKey $global:PackageConfig.RegPackagesKey
		$App = $ExecutionContext.InvokeCommand.ExpandString($global:PackageConfig.App)
		$SetupCfgPathOverride = "$env:SystemRoot\system32\config\systemprofile\AppData\Roaming\neo42\$($global:Packageconfig.RegPackagesKey)\$($global:Packageconfig.PackageGUID)"
		## if $App still is not valid we have to throw an error.
		if ($false -eq [System.IO.Path]::IsPathRooted($App)) {
			Write-Log -Message "'$App' is not a valid path. Please check your PackageConfig.json" -Severity 1 -Source ${CmdletName}
			throw "'App' is not set correctly. Please check your PackageConfig.json"
		}
		if ($DeploymentType -notlike "*Userpart*") {
			if ($DeploymentType -eq "Install") {
				Write-Log -Message "Cleanup of possibly existing/outdated setup configuration files in folder '$App'..." -Source ${cmdletName}
				if (
					[System.IO.Path]::GetFullPath($SetupCfgPath) -ne
					[System.IO.Path]::GetFullPath("$App\neo42-Install\Setup.cfg")
				) {
					Remove-File -Path "$App\neo42-Install\Setup.cfg"
				}
				if (
					[System.IO.Path]::GetFullPath($CustomSetupCfgPath) -ne
					[System.IO.Path]::GetFullPath("$App\neo42-Install\CustomSetup.cfg")
				) {
					Remove-File -Path "$App\neo42-Install\CustomSetup.cfg"
				}
			}
			if ($true -eq (Test-Path -Path $SetupCfgPathOverride\setupOverride.cfg)) {
				Write-Log -Message "Found an externally provided setup configuration file..."-Source ${cmdletName}
				New-Item -Path "$App\neo42-Install" -ItemType Directory -Force | Out-Null
				Copy-File -Path $SetupCfgPathOverride\setupOverride.cfg -Destination "$App\neo42-Install\setup.cfg" -Recurse
			}
			elseif ($true -eq (Test-Path -Path $SetupCfgPath)) {
				Write-Log -Message "Found a default setup config file 'Setup.cfg'..."-Source ${cmdletName}
				if (
					[System.IO.Path]::GetFullPath($SetupCfgPath) -ne
					[System.IO.Path]::GetFullPath("$App\neo42-Install\Setup.cfg")
				) {
						Copy-File -Path "$SetupCfgPath" -Destination "$App\neo42-Install\"
				}
				else {
					Write-Log -Message "The setup config file is already at its correct location." -Source ${cmdletName}
				}
			}
			if ($true -eq (Test-Path -Path "$CustomSetupCfgPath")) {
				Write-Log -Message "Found a custom setup config file 'CustomSetup.cfg' too..."-Source ${cmdletName}
				if (
					[System.IO.Path]::GetFullPath($CustomSetupCfgPath) -ne
					[System.IO.Path]::GetFullPath("$App\neo42-Install\CustomSetup.cfg")
				) {
						Copy-File -Path "$CustomSetupCfgPath" -Destination "$App\neo42-Install\"
				}
				else {
					Write-Log -Message "The custom setup config file is already at its correct location." -Source ${cmdletName}
				}
			}
		}
		Set-NxtSetupCfg -Path "$App\neo42-Install\setup.cfg" -AddDefaultOptions $true -ContinueOnError $true
		Set-NxtCustomSetupCfg -Path "$App\neo42-Install\CustomSetup.cfg" -ContinueOnError $true
		if (0 -ne $(Set-NxtPackageArchitecture)) {
			throw "Error during setting package architecture variables."
		}
		[string]$global:DeploymentTimestamp = Get-Date -format "yyyy-MM-dd_HH-mm-ss"
		Expand-NxtPackageConfig -PackageConfig $global:PackageConfig
		Format-NxtPackageSpecificVariables -PackageConfig $global:PackageConfig
		## In Userpart deployments we don't want to show Balloon Notifications.
		if ($DeploymentType -notlike "*Userpart*") {
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
		Defines the required steps to prepare the uninstallation of the package.
	.DESCRIPTION
		Unhides all defined registry keys from a corresponding value in the PackageConfig object.
		Is only called in the Main function and should not be modified!
		To customize the script always use the "CustomXXXX" entry points.
	.PARAMETER UninstallKeysToHide
		Specifies a list of UninstallKeys set by the Installer(s) in this Package, which the function will hide from the user (e.g. under "Apps" and "Programs and Features").
		Defaults to the corresponding values from the PackageConfig object.
	.EXAMPLE
		Initialize-NxtUninstallApplication
	.EXAMPLE
		Initialize-NxtUninstallApplication -UninstallKeysToHide @{"KeyName"="MyApp"; "Is64Bit"=$false}
	.OUTPUTS
		none.
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
			[hashtable]$getInstalledApplicationSplatted = @{
				UninstallKey			= $uninstallKeyToHide.KeyName
				DisplayNamesToExclude	= $uninstallKeyToHide.DisplayNamesToExcludeFromHiding
			}
			if ($false -eq [string]::IsNullOrEmpty($uninstallKeyToHide.KeyNameIsDisplayName)) {
				$getInstalledApplicationSplatted["UninstallKeyIsDisplayName"] = $uninstallKeyToHide.KeyNameIsDisplayName
			}
			if ($false -eq [string]::IsNullOrEmpty($uninstallKeyToHide.KeyNameContainsWildCards)) {
				$getInstalledApplicationSplatted["UninstallKeyContainsWildCards"] = $uninstallKeyToHide.KeyNameContainsWildCards
			}
			[string[]]$currentKeyName = (Get-NxtInstalledApplication @getInstalledApplicationSplatted).UninstallSubkey
			if ($currentKeyName.Count -ne 1) {
				Write-Log -Message "Did not find unique uninstall registry key with name [$($uninstallKeyToHide.KeyName)]. Skipped unhiding the entry for this key." -Source ${CmdletName} -Severity 2
				continue
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
		Defines the required steps to install the application based on the target installer type.
	.DESCRIPTION
		The Install-NxtApplication function is responsible for managing the installation process for a given application. It supports various installer types like MSI, InnoSetup, Nullsoft, and BitRockInstaller. Utilizing the provided parameters, users can configure the uninstall registry keys, log files, installation files, installation parameters, and other related settings. The function is meant to be called within the main function and should not be modified.
	.PARAMETER AppName
		Specifies the Application Name used in the registry etc.
		Defaults to the corresponding value from the PackageConfig object.
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
	.PARAMETER AcceptedInstallRebootCodes
		Defines a list of reboot codes that will be accepted for requested reboot by called setup execution. A matching code will be translated to code '3010'.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER InstallMethod
		Defines the type of the installer used in this package.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallMethod
		Defines the type of the uninstaller used in this package. Used for filtering the correct uninstaller from the registry.
		Defaults to the corresponding value from the PackageConfig object.
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
		Installs the application applying the settings from the packageconfig.json.
	.EXAMPLE
		Install-NxtApplication -UninstallKey "{XXXXXXXX-XXXX-XXXXXXXX-XXXXXXXXXXXX}_is1" -UninstallKeyContainsWildCards $true
		Installs the application using the provided UninstallKey with WildCards interpretation. Caution: If you use this function in a custom function, you have to specify all parameters that should differ from the settings in the packageconfig.json for the installation to work properly.
	.OUTPUTS
		PSADTNXT.NxtApplicationResult.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$AppName = $global:PackageConfig.AppName,
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
		$AcceptedInstallRebootCodes = $global:PackageConfig.AcceptedInstallRebootCodes,
		[Parameter(Mandatory = $false)]
		[string]
		$InstallMethod = $global:PackageConfig.InstallMethod,
		[Parameter(Mandatory = $false)]
		[string]
		$UninstallMethod = $global:PackageConfig.UninstallMethod,
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
		$PreSuccessCheckRegkeysToWaitFor = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Install.RegkeysToWaitFor,
		[Parameter(Mandatory = $false)]
		[string]
		$UninsBackupPath = "$($global:packageConfig.App)\neo42-Source"
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
			[int]$logMessageSeverity = 1
			[hashtable]$executeNxtParams = @{
				Action							= 'Install'
				Path							= "$InstFile"
				UninstallKeyIsDisplayName		= $UninstallKeyIsDisplayName
				UninstallKeyContainsWildCards	= $UninstallKeyContainsWildCards
				DisplayNamesToExclude			= $DisplayNamesToExclude
			}
			if ($false -eq ([string]::IsNullOrEmpty($InstPara))) {
				if ($true -eq $AppendInstParaToDefaultParameters) {
					[string]$executeNxtParams["AddParameters"] = "$InstPara"
				}
				else {
					[string]$executeNxtParams["Parameters"] = "$InstPara"
				}
			}
			if ($true -eq ([string]::IsNullOrEmpty($UninstallKey))) {
				[string]$internalInstallerMethod = [string]::Empty
				Write-Log -Message "No 'UninstallKey' is set. Switch to use provided 'InstFile' ..." -Severity 2 -Source ${cmdletName}
			}
			else {
				[string]$internalInstallerMethod = $InstallMethod
			}
			if ($internalInstallerMethod -match "^Inno.*$|^Nullsoft$|^BitRock.*$|^MSI$") {
				if ($false -eq [string]::IsNullOrEmpty($AcceptedInstallExitCodes)) {
					[string]$executeNxtParams["AcceptedExitCodes"] = "$AcceptedInstallExitCodes"
				}
				if ($false -eq [string]::IsNullOrEmpty($AcceptedInstallRebootCodes)) {
					[string]$executeNxtParams["AcceptedRebootCodes"] = "$AcceptedInstallRebootCodes"
				}
			}
			switch -Wildcard ($internalInstallerMethod) {
				MSI {
					[PsObject]$executionResult = Execute-NxtMSI @executeNxtParams -Log "$InstLogFile"
				}
				"Inno*" {
					[PsObject]$executionResult = Execute-NxtInnoSetup @executeNxtParams -UninstallKey "$UninstallKey" -Log "$InstLogFile" -UninsBackupPath $UninsBackupPath
				}
				Nullsoft {
					[PsObject]$executionResult = Execute-NxtNullsoft @executeNxtParams -UninstallKey "$UninstallKey" -UninsBackupPath $UninsBackupPath
				}
				"BitRock*" {
					[PsObject]$executionResult = Execute-NxtBitRockInstaller @executeNxtParams -UninstallKey "$UninstallKey" -UninsBackupPath $UninsBackupPath
				}
				Default {
					[hashtable]$executeParams = @{
						Path					= "$InstFile"
						ExitOnProcessFailure	= $false
						PassThru				= $true
					}
					if ($false -eq ([string]::IsNullOrEmpty($InstPara))) {
						[string]$executeParams["Parameters"] = "$InstPara"
					}
					[string]$ignoreExitCodes = Merge-NxtExitCodes -ExitCodeString1 $AcceptedInstallExitCodes -ExitCodeString2 $AcceptedInstallRebootCodes
					if ($false -eq ([string]::IsNullOrEmpty($ignoreExitCodes))) {
						[string]$executeParams["IgnoreExitCodes"] = "$ignoreExitCodes"
					}
					[PsObject]$executionResult = Execute-Process @executeParams
					if ($($executionResult.ExitCode) -in ($AcceptedInstallRebootCodes -split ",")) {
						Write-Log -Message "A custom reboot return code was detected '$($executionResult.ExitCode)' and is translated to return code '3010': Reboot required!" -Severity 2 -Source ${cmdletName}
						Set-Variable -Name 'msiRebootDetected' -Value $true -Scope 'Script'
					}
				}
			}
			$installResult.ApplicationExitCode = $($executionResult.ExitCode)
			if ($executionResult.ExitCode -in ($AcceptedInstallRebootCodes -split ",")) {
				$installResult.MainExitCode = 3010
				$installResult.ErrorMessage = "Installation done with custom reboot return code '$($executionResult.ExitCode)'."
			}
			else {
				$installResult.MainExitCode = $executionResult.ExitCode
				$installResult.ErrorMessage = "Installation done with return code '$($executionResult.ExitCode)'."
			}
			if ($false -eq [string]::IsNullOrEmpty($executionResult.StdErr)) {
				$installResult.ErrorMessagePSADT = "$($executionResult.StdErr)"
			}
			## Delay for filehandle release etc. to occur.
			Start-Sleep -Seconds 5

			## Test for successfull installation (if UninstallKey value is set)
			if ($true -eq ([string]::IsNullOrEmpty($UninstallKey))) {
				$installResult.ErrorMessage = "UninstallKey value NOT set. Skipping test for successfull installation of '$AppName' via registry."
				$installResult.Success = $null
				[int]$logMessageSeverity = 2
			}
			else {
				if ( $false -eq (Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor $PreSuccessCheckTotalSecondsToWaitFor -ProcessOperator $PreSuccessCheckProcessOperator -ProcessesToWaitFor $PreSuccessCheckProcessesToWaitFor -RegKeyOperator $PreSuccessCheckRegKeyOperator -RegkeysToWaitFor $PreSuccessCheckRegkeysToWaitFor) ) {
					$installResult.ErrorMessage = "Installation RegistryAndProcessCondition of '$AppName' failed. ErrorLevel: $($installResult.ApplicationExitCode)"
					$installResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
					$installResult.Success = $false
					[int]$logMessageSeverity = 3
				}
				else {
					if ($false -eq $(Test-NxtAppIsInstalled -UninstallKey "$UninstallKey" -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -InstallMethod $UninstallMethod)) {
						$installResult.ErrorMessage = "Installation of '$AppName' failed. ErrorLevel: $($installResult.ApplicationExitCode)"
						$installResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
						$installResult.Success = $false
						[int]$logMessageSeverity = 3
					}
					else {
						$installResult.ErrorMessage = "Installation of '$AppName' was successful."
						$installResult.Success = $true
						[int]$logMessageSeverity = 1
					}
				}
			}
			if (
				($executionResult.ExitCode -notin ($AcceptedInstallExitCodes -split ",")) -and
				($executionResult.ExitCode -notin ($AcceptedInstallRebootCodes -split ",")) -and
				($executionResult.ExitCode -notin 0,1641,3010)
			) {
				$installResult.ErrorMessage = "Installation of '$AppName' failed. ErrorLevel: $($installResult.ApplicationExitCode)"
				$installResult.Success = $false
				[int]$logMessageSeverity = 3
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
#region Function Merge-NxtExitCodes
function Merge-NxtExitCodes {
	<#
	.SYNOPSIS
		Merges two exit code strings.
	.DESCRIPTION
		Merges two exit code strings. If one of the strings is "*" the result will be "*".
	.PARAMETER ExitCodeString1
		First exit code string.
	.PARAMETER ExitCodeString2
		Second exit code string.
	.EXAMPLE
		Merge-NxtExitCodes -ExitCodeString1 "129,1256" -ExitCodeString2 "129,34,55"
		Merges the two exit code strings to "129,1256,34,55".
	.EXAMPLE
		Merge-NxtExitCodes -ExitCodeString1 "129,1256" -ExitCodeString2 "*"
		Combines the two exit code strings to "*".
	.OUTPUTS
		System.String.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[string]
		$ExitCodeString1,
		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[string]
		$ExitCodeString2
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[array]$exitCodeObj = @()
		if ($ExitCodeString1 -eq "*" -or $ExitCodeString2 -eq "*") {
			[string]$exitCodeString = "*"
		}
		else {
			if ($false -eq ([string]::IsNullOrEmpty($ExitCodeString1))) {
				$exitCodeObj += $ExitCodeString1 -split ","
			}
			if ($false -eq ([string]::IsNullOrEmpty($ExitCodeString2))) {
				$exitCodeObj += $ExitCodeString2 -split ","
			}
			$exitCodeObj = $exitCodeObj | Select-Object -Unique
			[string]$exitCodeString = $exitCodeObj -join ","
		}
		Write-Output $exitCodeString
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Move-NxtItem
function Move-NxtItem {
	<#
	.SYNOPSIS
		Moves or renames a file or directory from a source path to a destination path with optional parameters to force overwrite and continue on error.
	.DESCRIPTION
		The Move-NxtItem function moves or renames a file or directory from the specified source path to the destination path.
		The operation can be forced to overwrite existing files, and it can be configured to continue if an error is encountered.
	.PARAMETER Path
		Source Path of the File or Directory. This parameter is mandatory.
	.PARAMETER Destination
		Destination Path for the File or Directory. This parameter is mandatory.
	.PARAMETER Force
		Overwrite existing file.
	.PARAMETER ContinueOnError
		Continue if an error is encountered. Default is: $true.
	.EXAMPLE
		Move-NxtItem -Path C:\Temp\Sources\Installer.exe -Destination C:\Temp\Sources\Installer_bak.exe
		Moves the "Installer.exe" file from the specified source path to the destination path.
	.EXAMPLE
		Move-NxtItem -Path C:\Temp\Sources\Installer.exe -Destination C:\Temp\Sources\Installer_bak.exe -Force
		Moves the "Installer.exe" file from the specified source path to the destination path, overwriting the existing file if it exists.
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
		[bool]
		$ContinueOnError = $true
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
				$PSBoundParameters.Remove($functionParameterToBeRemoved) | Out-Null
			}
			Write-Log -Message "Move '$path' to '$Destination'." -Source ${cmdletName}
			Move-Item @PSBoundParameters -ErrorAction Stop
		}
		catch {
			Write-Log -Message "Failed to move '$Path' to '$Destination'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
			if ($false -eq $ContinueOnError) {
				throw "Failed to move '$Path' to '$Destination'`: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function New-NxtFolderWithPermissions
function New-NxtFolderWithPermissions {
	<#
	.SYNOPSIS
		Creates a new folder and configures custom permissions and attributes.
	.DESCRIPTION
		The New-NxtFolderWithPermissions function creates a new directory at the specified path and allows for detailed control over permissions and attributes.
		It supports setting various permission levels (Full Control, Modify, Write, Read & Execute), custom owner, hidden attribute, and protection of access rules.
	.PARAMETER Path
		Specifies the full path of the new folder to be created.
	.PARAMETER FullControlPermissions
		Defines users or groups to be granted Full Control permission.
		Accepts an array of WellKnownSidTypes.
	.PARAMETER ReadAndExecutePermissions
		Defines users or groups to be granted ReadAndExecute Permissions permission.
		Accepts an array of WellKnownSidTypes.
	.PARAMETER WritePermissions
		Defines users or groups to be granted Write permission.
		Accepts an array of WellKnownSidTypes.
	.PARAMETER ModifyPermissions
		Defines users or groups to be granted Modify permission.
		Accepts an array of WellKnownSidTypes.
	.PARAMETER Owner
		Owner to set on the folder.
		Accepts a WellKnownSidType.
	.PARAMETER CustomDirectorySecurity
		Custom DirectorySecurity to set on the folder.
		Will be modified by the other parameters.
	.PARAMETER Hidden
		Defines if the folder should be hidden.
		Default is: $false.
	.EXAMPLE
		New-NxtFolderWithPermissions -Path "C:\Temp\MyFolder" -FullControlPermissions @([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid) -ReadAndExecutePermissions @([System.Security.Principal.WellKnownSidType]::BuiltinUsersSid) -Owner $([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid)
		Will create a folder "C:\Temp\MyFolder" with with full control for the buildin administrator group and read and execute permissions for the buildin users group.
		It will also set the owner of the folder to the buildin administrator group.
	.OUTPUTS
		System.IO.DirectoryInfo
		Returns a DirectoryInfo object representing the created folder.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$FullControlPermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$WritePermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$ModifyPermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$ReadAndExecutePermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType]
		$Owner,
		[Parameter(Mandatory = $false)]
		[System.Security.AccessControl.DirectorySecurity]
		$CustomDirectorySecurity,
		[Parameter(Mandatory = $false)]
		[bool]
		$Hidden,
		[Parameter(Mandatory = $false)]
		[bool]
		$ProtectRules = $true
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			if ($true -eq (Test-Path $Path)) {
				Write-Log -Message "Folder '$Path' already exists." -Source ${cmdletName} -Severity 3
				throw "Folder '$Path' already exists."
			}
			if ($null -ne $CustomDirectorySecurity) {
				[System.Security.AccessControl.DirectorySecurity]$directorySecurity = $CustomDirectorySecurity
			}
			else {
				[System.Security.AccessControl.DirectorySecurity]$directorySecurity = New-Object System.Security.AccessControl.DirectorySecurity
			}
			foreach ($permissionLevel in @("FullControl","Modify", "Write", "ReadAndExecute")) {
				foreach ($wellKnownSid in $(Get-Variable "$permissionLevel`Permissions" -ValueOnly)) {
					[System.Security.AccessControl.FileSystemAccessRule]$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
						(New-Object System.Security.Principal.SecurityIdentifier -ArgumentList ($wellKnownSid, $null)),
						"$permissionLevel",
						"ContainerInherit,ObjectInherit",
						"None",
						"Allow"
					)
					$directorySecurity.AddAccessRule($rule)
				}
			}
			if ($null -ne $Owner) {
				$directorySecurity.SetOwner((New-Object System.Security.Principal.SecurityIdentifier -ArgumentList ($Owner, $null)))
			}
			$directorySecurity.SetAccessRuleProtection($ProtectRules, $false)
			Write-Log -Message "Creating folder '$Path' with permissions." -Source ${cmdletName}
			[System.IO.DirectoryInfo]$directory = [System.IO.Directory]::CreateDirectory($Path, $directorySecurity)
			if ($false -eq (Test-NxtFolderPermissions -Path $Path -CustomDirectorySecurity $directorySecurity)) {
				Write-Log -Message "Failed to create folder '$Path' with permissions. `n" -Severity 3 -Source ${cmdletName}
				throw "Failed to create folder '$Path' with permissions. `n $($_.Exception.Message)"
			}
			if ($true -eq $Hidden) {
				$directory.Attributes = $directory.Attributes -bor [System.IO.FileAttributes]::Hidden
			}
			Write-Output $directory
		}
		catch {
			Write-Log -Message "Failed to create folder '$Path' with permissions." -Severity 3 -Source ${cmdletName}
			throw "Failed to create folder '$Path' with permissions. `n$ $($_.Exception.Message)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function New-NxtTemporaryFolder
function New-NxtTemporaryFolder {
	<#
	.SYNOPSIS
		Creates and configures a new temporary folder with predefined permissions.
	.DESCRIPTION
		This function generates a new temporary folder in a specified or default root path, ensuring the folder has specific security permissions set.
		If the provided root path doesn't exist or has incorrect permissions, it will be recreated accordingly. The function ensures unique naming for the temporary folder and outputs its path upon successful creation.
	.PARAMETER TempRootPath
		Parent path of the folder to create. To ensure that all internal processes work correctly it is highly recommended to keep the default value!
		Default is: "$env:SystemDrive\n42Tmp".
	.EXAMPLE
		New-NxtTemporaryFolder -TempPath "C:\Temp"
		Will create a new folder with the predefined permissions.
	.OUTPUTS
		String.
		Outputs the full path of the newly created temporary folder.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$TempRootPath = "$env:SystemDrive\n42Tmp"
	)
	[hashtable]$nxtTempRootFolderSplat = @{
			Path = "$TempRootPath"
			FullControlPermissions = @("BuiltinAdministratorsSid","LocalSystemSid")
			ReadAndExecutePermissions = @("BuiltinUsersSid")
			Owner = "BuiltinAdministratorsSid"
		}
	if ($false -eq (Test-Path -Path $TempRootPath)) {
		[System.IO.DirectoryInfo]$tempRootFolder = New-NxtFolderWithPermissions @nxtTempRootFolderSplat -Hidden $true
	}
	elseif ($false -eq (Test-NxtFolderPermissions @nxtTempRootFolderSplat)) {
		Write-Log -Message "Temp path '$TempRootPath' already exists. Recreating the folder to ensure predefined permissions!" -Severity 2 -Source ${CmdletName}
		Remove-Item -Path $TempRootPath -Recurse -Force
		[System.IO.DirectoryInfo]$tempRootFolder = New-NxtFolderWithPermissions @nxtTempRootFolderSplat -Hidden $true
	}
	[string]$foldername=(Get-Random -InputObject((48..57 + 65..90)) -Count 3 | ForEach-Object {
		[char]$_}
	) -join [string]::Empty
	[int]$countTries = 1
	while ($true -eq (Test-Path "$TempRootPath\$foldername") -and $countTries -lt 100) {
		$countTries++
		$foldername=(Get-Random -InputObject((48..57 + 65..90)) -Count 3 | ForEach-Object {
			[char]$_}
		) -join [string]::Empty
	}
	if ($countTries -ge 100) {
		Write-Log -Message "Failed to create temporary folder in '$TempRootPath'. Did not find an available name." -Severity 3 -Source ${cmdletName}
		throw "Failed to create temporary folder in '$TempRootPath'. Did not find an available name."
	}
	[hashtable]$nxtFolderWithPermissionsSplat = @{
		Path = "$TempRootPath\$foldername"
	}
	$nxtFolderWithPermissionsSplat["FullControlPermissions"] = @("BuiltinAdministratorsSid","LocalSystemSid")
	$nxtFolderWithPermissionsSplat["ReadAndExecutePermissions"] = @("BuiltinUsersSid")
	[string]$tempFolder = New-NxtFolderWithPermissions @nxtFolderWithPermissionsSplat | Select-Object -ExpandProperty FullName
	$script:NxtTempDirectories += $tempfolder
	Write-Output $tempfolder
}
#endregion
#region Function Read-NxtSingleXmlNode
function Read-NxtSingleXmlNode {
	<#
	.SYNOPSIS
		Reads the content of a single specified XML node from a given XML file.
	.DESCRIPTION
		The Read-NxtSingleXmlNode function reads the content of a specified XML node from an XML file.
		The node is identified by the path provided in the SingleNodeName parameter, and the XML file is specified by the XmlFilePath parameter.
	.PARAMETER XmlFilePath
		Path to the XML file. This parameter is mandatory.
	.PARAMETER SingleNodeName
		Node path following XPath syntax. (https://www.w3schools.com/xml/xpath_syntax.asp).
		This parameter is mandatory.
	.PARAMETER AttributeName
		Attribute name to be read from the node.
		Default is "Innertext".
	.PARAMETER Encoding
		Encoding of the XML file.
	.PARAMETER DefaultEncoding
		Default encoding of the XML file if the encoding is not specified or detected.
		Best practice is to use UTF8withBom.
	.EXAMPLE
		Read-NxtSingleXmlNode -XmlFilePath "C:\Test\setup.xml" -SingleNodeName "//UserId"
		Reads the content of the "UserId" node from the XML file located at "C:\Test\setup.xml."
	.EXAMPLE
		Read-NxtSingleXmlNode -XmlFilePath "C:\Config\settings.xml" -SingleNodeName "/Configuration/UserName"
		Reads the content of the specified node from the XML file
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
		$SingleNodeName,
		[Parameter(Mandatory = $false)]
		[string]
		$AttributeName = "Innertext",
		[Parameter(Mandatory = $false)]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[string]
		$Encoding,
		[Parameter(Mandatory = $false)]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[string]
		$DefaultEncoding
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[hashtable]$encodingParams = @{}
			if ($false -eq [string]::IsNullOrEmpty($Encoding)) {
				$encodingParams['Encoding'] = $Encoding
			}
			if ($false -eq [string]::IsNullOrEmpty($DefaultEncoding)) {
				$encodingParams['DefaultEncoding'] = $DefaultEncoding
			}
			[System.Xml.XmlDocument]$xmlDoc = Import-NxtXmlFile @encodingParams -Path $XmlFilePath
			[System.Xml.XmlNode]$selection = $xmlDoc.DocumentElement.SelectSingleNode($SingleNodeName)
			if ($selection.ChildNodes.count -gt 1) {
				Write-Log -Message "Found multiple child nodes for '$SingleNodeName'. Concated values will be returned." -Severity 3 -Source ${cmdletName}
			}
			Write-Output ($selection.$AttributeName)
		}
		catch {
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
		Defines wether to uninstall all found application packages with same ProductGUID (product membership) assigned.
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
	.PARAMETER ScriptRoot
		Defines the parent directory of the script.
		Defaults to the Variable $scriptRoot populated by AppDeployToolkitMain.ps1.
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
	.PARAMETER $UserPartDir
		Defines the subpath to the UserPart directory.
		Defaults to $global:UserPartDir.
	.PARAMETER SoftMigrationOccurred
		Defines if a SoftMigration occurred.
		Defaults to [string]::Empty.
	.PARAMETER ExecutionPolicy
		Defines the ExecutionPolicy of the UninstallString.
		Defaults to the value from the Toolkit_Options.Toolkit_ExecutionPolicy in the XML Config file.
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
		$ScriptRoot = $scriptRoot,
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
		$LastErrorMessage = $global:LastErrorMessage,
		[Parameter(Mandatory = $false)]
		[string]
		$UserPartDir = $global:UserPartDir,
		[Parameter(Mandatory = $false)]
		[string]
		$SoftMigrationOccurred = [string]::Empty,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]
		$ExecutionPolicy = $xmlConfigFile.AppDeployToolkit_Config.NxtPowerShell_Options.NxtPowerShell_ExecutionPolicy
	)

	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		Write-Log -Message "Registering package..." -Source ${cmdletName}
		Copy-File "$ScriptRoot" -Destination "$App\neo42-Install" -Recurse
		try {
			@(
				"$ScriptParentPath\Deploy-Application.ps1",
				"$ScriptParentPath\COPYING",
				"$ScriptParentPath\COPYING.lesser",
				"$ScriptParentPath\README.txt",
				"$global:Neo42PackageConfigPath",
				"$global:Neo42PackageConfigValidationPath",
				"$ScriptRoot\$($xmlConfigFile.GetElementsByTagName('BannerIcon_Options').Icon_Filename)"
			) | ForEach-Object {
				Copy-File -Path "$_" -Destination "$App\neo42-Install\"
			}
			if ($true -eq (Test-Path "$ScriptParentPath\DeployNxtApplication.exe")) {
				Copy-File -Path "$ScriptParentPath\DeployNxtApplication.exe" -Destination "$App\neo42-Install\" -ContinueOnError $true
			}

			Write-Log -message "Re-write all management registry entries for the application package..." -Source ${cmdletName}
			## to prevent obsolete entries from old VBS packages
			Remove-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID"
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'AppPath' -Value $App
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'Date' -Value (Get-Date -format "yyyy-MM-dd HH:mm:ss")
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'DebugLogFile' -Value $ConfigToolkitLogDir\$LogName
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'DeveloperName' -Value $AppVendor
			if ($false -eq ([string]::IsNullOrEmpty($LastErrorMessage))) {
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
			if ($true -eq (Test-Path "$App\neo42-Install\DeployNxtApplication.exe")) {
				Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'UninstallString' -Value ("""$App\neo42-Install\DeployNxtApplication.exe"" uninstall")
			}
			else {
				Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'UninstallString' -Value ("""$env:Systemroot\System32\WindowsPowerShell\v1.0\powershell.exe"" -ExecutionPolicy $ExecutionPolicy -NonInteractive -WindowStyle hidden -file ""$App\neo42-Install\Deploy-Application.ps1"" uninstall")
			}
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'UserPartOnInstallation' -Value $UserPartOnInstallation -Type 'DWord'
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'UserPartOnUninstallation' -Value $UserPartOnUnInstallation -Type 'DWord'
			if ($true -eq $UserPartOnInstallation) {
				Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'UserPartPath' -Value ('"' + $App + "\$UserpartDir" + '"')
				Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'UserPartUninstPath' -Value ('"%AppData%\neoPackages\' + $PackageGUID + '"')
				Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'UserPartRevision' -Value $UserPartRevision
			}
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'Version' -Value $AppVersion
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'ProductGUID' -Value $ProductGUID
			Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'RemovePackagesWithSameProductGUID' -Type 'Dword' -Value $RemovePackagesWithSameProductGUID

			Write-Log -message "Re-write all uninstall registry entries for the application package..." -Source ${cmdletName}
			## to prevent obsolete entries from old VBS packages
			Remove-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID"
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'DisplayIcon' -Value $App\neo42-Install\$(Split-Path "$ScriptRoot\$($xmlConfigFile.GetElementsByTagName('BannerIcon_Options').Icon_Filename)" -Leaf)
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'DisplayName' -Value $UninstallDisplayName
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'DisplayVersion' -Value $AppVersion
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'neoRegPackagesKeyRef' -Value $RegPackagesKey\$PackageGUID
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'NoModify' -Type 'Dword' -Value 1
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'NoRemove' -Type 'Dword' -Value $HidePackageUninstallButton
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'NoRepair' -Type 'Dword' -Value 1
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'PackageApplicationDir' -Value $App
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'PackageProductName' -Value $AppName
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'PackageRevision' -Value $AppRevision
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'PackageVersion' -Value $AppVersion
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'Publisher' -Value $AppVendor
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'SystemComponent' -Type 'Dword' -Value $HidePackageUninstallEntry
			if ($true -eq (Test-Path "$App\neo42-Install\DeployNxtApplication.exe")) {
				Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'UninstallString' -Type 'ExpandString' -Value ("""$App\neo42-Install\DeployNxtApplication.exe"" uninstall")
			}
			else {
				Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'UninstallString' -Type 'ExpandString' -Value ("""$env:Systemroot\System32\WindowsPowerShell\v1.0\powershell.exe"" -ExecutionPolicy $ExecutionPolicy -WindowStyle hidden -NonInteractive -File ""$App\neo42-Install\Deploy-Application.ps1"" uninstall")
			}
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'Installed' -Type 'Dword' -Value '1'
			if ($false -eq [string]::IsNullOrEmpty($SoftMigrationOccurred)) {
				Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'SoftMigrationOccurred' -Value $SoftMigrationOccurred
				Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'SoftMigrationOccurred' -Value $SoftMigrationOccurred
			}
			if ($true -eq (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")")) {
				Remove-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")"
			}
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
		Removes specified desktop shortcuts. By default, removes the shortcuts defined under "CommonDesktopShortcutsToDelete" in the neo42PackageConfig.json from the common desktop.
	.DESCRIPTION
		This function is called to remove desktop shortcuts after an installation or reinstallation if DESKTOPSHORTCUT=0 is defined in the Setup.cfg. It is also called before the uninstallation process. The function supports the removal of specified shortcuts or defaults to common shortcuts to delete.
	.PARAMETER DesktopShortcutsToDelete
		A list of desktop shortcuts that should be deleted.
		Defaults to the CommonDesktopShortcutsToDelete value from the PackageConfig object.
	.PARAMETER Desktop
		Specifies the path to the desktop (e.g., $envCommonDesktop or $envUserDesktop).
		Defaults to $envCommonDesktop defined in AppDeploymentToolkitMain.ps1.
	.EXAMPLE
		Remove-NxtDesktopShortcuts
		This example removes the desktop shortcuts defined under "CommonDesktopShortcutsToDelete" in the neo42PackageConfig.json from the common desktop.
	.EXAMPLE
		Remove-NxtDesktopShortcuts -DesktopShortcutsToDelete "SomeUserShortcut.lnk" -Desktop "$envUserDesktop"
		This example removes the specified "SomeUserShortcut.lnk" from the user desktop.
	.OUTPUTS
		none.
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
			foreach ($value in ($DesktopShortcutsToDelete | Where-Object {
						$false -eq [string]::IsNullOrWhiteSpace($_)
					})) {
				Write-Log -Message "Removing desktop shortcut '$Desktop\$value'..." -Source ${cmdletName}
				Remove-File -Path "$Desktop\$value"
				Write-Log -Message 'Desktop shortcut succesfully removed.' -Source ${cmdletName}
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
		This function is designed to remove folders if and only if they are empty. If the specified folder contains any files or other items, the function continues without taking any action.
	.PARAMETER Path
		Specifies the path to the empty folder to remove.
		This parameter is mandatory.
	.PARAMETER RootPathToRecurseUpTo
		Specifies the root path to recurse up to. If this parameter is not specified, the function will not recurse up.
		This parameter is optional. If specified, it must be a parent of the specified path or recursion will not be carried out.
	.EXAMPLE
		Remove-NxtEmptyFolder -Path "$installLocation\SomeEmptyFolder"
		This example removes the specified empty folder located at "$installLocation\SomeEmptyFolder".
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
		$Path,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$RootPathToRecurseUpTo
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		$Path = $Path.TrimEnd("\")
		if ($false -eq [string]::IsNullOrEmpty($RootPathToRecurseUpTo)) {
			$RootPathToRecurseUpTo = $RootPathToRecurseUpTo.TrimEnd("\")
		}
		Write-Log -Message "Check if [$Path] exists and is empty..." -Source ${CmdletName}
		[bool]$skipRecursion = $false
		if ($true -eq (Test-Path -LiteralPath $Path -PathType 'Container')) {
			try {
				if ( (Get-ChildItem $Path | Measure-Object).Count -eq 0) {
					Write-Log -Message "Delete empty folder [$Path]..." -Source ${CmdletName}
					Remove-Item -LiteralPath $Path -Force -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorRemoveFolder'
					if ($false -eq [string]::IsNullOrEmpty($ErrorRemoveFolder)) {
						Write-Log -Message "The following error(s) took place while deleting the empty folder [$Path]. `n$(Resolve-Error -ErrorRecord $ErrorRemoveFolder)" -Severity 2 -Source ${CmdletName}
					}
					else {
						Write-Log -Message "Empty folder [$Path] was deleted successfully..." -Source ${CmdletName}
					}
				}
				else {
					Write-Log -Message "Folder [$Path] is not empty, so it was not deleted..." -Source ${CmdletName}
					$skipRecursion = $true
				}
			}
			catch {
				Write-Log -Message "Failed to delete empty folder [$Path]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				if ($false -eq $ContinueOnError) {
					throw "Failed to delete empty folder [$Path]: $($_.Exception.Message)"
				}
			}
		}
		else {
			Write-Log -Message "Folder [$Path] does not exist..." -Source ${CmdletName}
		}
		if (
			$false -eq [string]::IsNullOrEmpty($RootPathToRecurseUpTo) -and
			$false -eq $skipRecursion
		) {
			## Resolve possible relative segments in the paths
			[string]$absolutePath = $Path | Split-Path -Parent
			[string]$absoluteRootPathToRecurseUpTo = [System.IO.Path]::GetFullPath(([System.IO.DirectoryInfo]::new($RootPathToRecurseUpTo)).FullName)
			if ($absolutePath -eq $absoluteRootPathToRecurseUpTo) {
				## We are at the root of the recursion, so we can stop recursing up
				Remove-NxtEmptyFolder -Path $absolutePath
			}
			else {
				## Ensure that $absoluteRootPathToRecurseUpTo is a valid path
				if ($false -eq [System.IO.Path]::IsPathRooted($absoluteRootPathToRecurseUpTo)) {
					Write-Log -Message "$absoluteRootPathToRecurseUpTo is not a valid path." -Severity 3 -Source ${CmdletName}
					throw "RootPathToRecurseUpTo is not a valid path."
				}
				## Ensure that $absoluteRootPathToRecurseUpTo is a parent of $absolutePath
				if ($false -eq $absolutePath.StartsWith($absoluteRootPathToRecurseUpTo, [System.StringComparison]::InvariantCultureIgnoreCase)) {
					Write-Log -Message "RootPathToRecurseUpTo '$absoluteRootPathToRecurseUpTo' is not a parent of '$absolutePath'." -Severity 3 -Source ${CmdletName}
					throw "RootPathToRecurseUpTo '$absoluteRootPathToRecurseUpTo' is not a parent of '$absolutePath'."
				}
				Remove-NxtEmptyFolder -Path $absolutePath -RootPathToRecurseUp $absoluteRootPathToRecurseUpTo
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Remove-NxtEmptyIniFile
function Remove-NxtEmptyIniFile {
	<#
	.SYNOPSIS
		Removes only empty INI files.
	.DESCRIPTION
		This function is designed to remove INI files if and only if they are empty. If the specified INI file contains any key-value pairs, the function continues without taking any action.
	.PARAMETER Path
		Specifies the path to the empty INI file to remove.
		This parameter is mandatory.
	.EXAMPLE
		Remove-NxtEmptyIniFile -Path "$installLocation\SomeEmptyIniFile.ini"
		This example removes the specified empty INI file located at "$installLocation\SomeEmptyIniFile.ini".
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.IO.FileInfo]
		$Path
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		Write-Log -Message "Check if [$Path] exists and is empty..." -Source ${cmdletName}
		if ($false -eq $Path.Exists) {
			Write-Log -Message "File [$Path] does not exist..." -Severity 1 -Source ${cmdletName}
			return
		}
		try {
			[hashtable]$content = Import-NxtIniFile -Path $Path
			## If any section exists that contains keys, the INI file is not considered empty
			foreach ($section in $content.GetEnumerator()) {
				if ($section.Value.Keys.Count -gt 0) {
					Write-Log -Message "INI file [$Path] is not empty, so it was not deleted..." -Severity 2 -Source ${cmdletName}
					return
				}
			}
			Remove-Item -Path $Path.FullName -Force -ErrorAction 'SilentlyContinue' -ErrorVariable '+errorRemoveIniFile'
			if ($false -eq [string]::IsNullOrEmpty($errorRemoveIniFile)) {
				Write-Log -Message "The following error(s) took place while deleting the empty INI file [$Path]. `n$(Resolve-Error -ErrorRecord $ErrorRemoveIniFile)" -Severity 1 -Source ${cmdletName}
			}
			else {
				Write-Log -Message "Empty INI file [$Path] was deleted successfully..." -Source ${cmdletName}
			}
		}
		catch {
			Write-Log -Message "Failed to import or delete INI file [$Path]. `n$(Resolve-Error)" -Severity 1 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Remove-NxtEmptyRegistryKey
function Remove-NxtEmptyRegistryKey {
	<#
	.SYNOPSIS
		Removes only empty registry keys
	.DESCRIPTION
		This function is designed to remove registry keys if and only if they are empty. If the specified registry contains any values or subkeys, the function continues without taking any action.
	.PARAMETER Path
		Specifies the path to the emptry registry key.
		This parameter is mandatory.
	.EXAMPLE
		Remove-NxtEmptyRegistryKey -Path "HKLM:\SOFTWARE\JavaSoft\Java Runtime Environment"
		This example removes the specified empty key located at "HKLM:\SOFTWARE\JavaSoft\Java Runtime Environment".
	.EXAMPLE
		Remove-NxtEmptyRegistryKey -Path "HKEY_CLASSES_ROOT\.7z"
		This example removes the specified empty key located at "HKCR:\.7z".
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
		$Path
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[hashtable]$hiveMap = @{
			"^HKLM:?" = "HKEY_LOCAL_MACHINE"
			"^HKCU:?" = "HKEY_CURRENT_USER"
			"^HKU:?" = "HKEY_USERS"
			"^HKCC:?" = "HKEY_CURRENT_CONFIG"
			"^HKCR:?" = "HKEY_CLASSES_ROOT"
			"^(Microsoft.PowerShell.Core\\)?Registry::" = [string]::Empty
		}
		foreach ($key in $hiveMap.Keys) {
			$Path = $Path -replace $key, $hiveMap[$key]
		}
		[Microsoft.Win32.RegistryKey[]]$keys = Get-Item -Path "Registry::$Path" -ErrorAction 'SilentlyContinue'
		if ($keys.Count -eq 0) {
			Write-Log -Message "Key [$Path] does not exist or is not a registry address..." -Source ${CmdletName} -Severity 2
			return
		}
		foreach ($key in $keys) {
			Write-Log -Message "Check if [$key] exists and is empty..." -Source ${CmdletName}
			try {
				if ( ((Get-ChildItem -LiteralPath $key.PSPath | Measure-Object).Count -eq 0) -and ($null -eq (Get-ItemProperty -LiteralPath $key.PSPath)) ) {
					Write-Log -Message "Delete empty key [$key]..." -Source ${CmdletName}
					Remove-Item -LiteralPath $key.PSPath -Force -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorRemoveKey'
					if ($false -eq [string]::IsNullOrEmpty($ErrorRemoveKey)) {
						Write-Log -Message "The following error(s) took place while deleting the empty key [$key]. `n$(Resolve-Error -ErrorRecord $ErrorRemoveKey)" -Severity 2 -Source ${CmdletName}
					}
					else {
						Write-Log -Message "Empty key [$key] was deleted successfully..." -Source ${CmdletName}
					}
				}
				else {
					Write-Log -Message "Key [$key] is not empty, so it was not deleted..." -Source ${CmdletName}
				}
			}
			catch {
				Write-Log -Message "Failed to delete empty key [$Path]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				throw
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Remove-NxtIniValue
function Remove-NxtIniValue {
	<#
	.SYNOPSIS
		Removes a specified key-value pair from a given section in an INI file.
	.DESCRIPTION
		The Remove-NxtIniValue function is designed to remove a specified key-value pair from a given section within an INI file located at the specified file path. The function logs the process and will either continue or terminate based on the value of the ContinueOnError parameter.
	.PARAMETER FilePath
		The full path of the INI file from which to remove the key-value pair.
		This parameter is mandatory.
	.PARAMETER Section
		The name of the section within the INI file from which to remove the key-value pair.
		This parameter is mandatory.
	.PARAMETER Key
		The key name within the section that needs to be removed from the INI file.
	This parameter is mandatory.
	.PARAMETER ContinueOnError
		When set to $true, the function will continue executing even if an error occurs. Default is $true.
	.EXAMPLE
		Remove-NxtIniValue -FilePath "C:\Config.ini" -Section "Settings" -Key "Username"
		Removes the key "Username" from the "Settings" section in the INI file located at "C:\Config.ini".
	.EXAMPLE
		Remove-NxtIniValue -FilePath "C:\Config.ini" -Section "Settings" -Key "Username" -ContinueOnError $false
		Removes the key "Username" from the "Settings" section in the INI file located at "C:\Config.ini" and stops execution if an error occurs.
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[String]
		$FilePath,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[String]
		$Section,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[String]
		$Key,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[bool]
		$ContinueOnError = $true
	)
	Begin {
		## Get the name of this function and write header
		[String]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			Write-Log -Message "Removing INI Key: [Section = $Section] [Key = $Key]." -Source ${CmdletName}
			if ($false -eq (Test-Path -LiteralPath $FilePath -PathType 'Leaf')) {
				throw "File [$filePath] could not be found."
			}
			[PSADTNXT.NxtIniFile]::RemoveIniValue($Section, $Key, $FilePath)
		}
		catch {
			Write-Log -Message "Failed to remove INI file key value. `r`n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			if ($false -eq $ContinueOnError) {
				throw "Failed to remove INI file key value: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Remove-NxtLocalGroup
function Remove-NxtLocalGroup {
	<#
	.SYNOPSIS
		Removes a specified local group from a computer.
	.DESCRIPTION
		The Remove-NxtLocalGroup function deletes a local group with the given name on the specified computer or on the local computer if no computer name is provided.
		Returns $true if the operation was successful, returns $false if the Group does not exist or if the operation failed.
	.PARAMETER GroupName
		Name of the group. This parameter is mandatory.
	.PARAMETER ComputerName
		Name of the computer where the local group should be removed. Defaults to the local computer name ($env:COMPUTERNAME).
	.EXAMPLE
		Remove-NxtLocalGroup -GroupName "TestGroup"
		Removes the local group named "TestGroup" from the local computer.
	.EXAMPLE
		Remove-NxtLocalGroup -GroupName "TestGroup" -ComputerName "Server01"
		Removes the local group named "TestGroup" from the remote computer named "Server01".
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
			[bool]$groupExists = Test-NxtLocalGroupExists -GroupName $GroupName -COMPUTERNAME $COMPUTERNAME
			if ($true -eq $groupExists) {
				[System.DirectoryServices.DirectoryEntry]$adsiObj = [ADSI]"WinNT://$COMPUTERNAME"
				$adsiObj.Delete("Group", $GroupName) | Out-Null
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
	.SYNOPSIS
		Removes a specific member or a type of member from a local group on a computer.
	.DESCRIPTION
		The Remove-NxtLocalGroupMember cmdlet removes a specific member, all users, all groups, or all members from a given group by name. It provides flexibility in defining the type of members to be removed. Returns the number of members removed.
		If the specified group is not found, the function will return $null.
	.PARAMETER GroupName
		Name of the Group from which to remove Members.
		This parameter is mandatory.
	.PARAMETER MemberName
		Name of the specific member to remove.
	.PARAMETER AllMember
		If this switch is defined, all members will be removed from the specified GroupName.
	.PARAMETER COMPUTERNAME
		Name of the Computer where the group resides. Defaults to the value of $env:COMPUTERNAME.
	.EXAMPLE
		Remove-NxtLocalGroupMember -GroupName "Users" -AllMember
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
			if ($true -eq $groupExists) {
				[System.DirectoryServices.DirectoryEntry]$group = [ADSI]"WinNT://$COMPUTERNAME/$GroupName,group"
				if ($true -eq $AllMember) {
					[int]$count = 0
					foreach ($member in $group.psbase.Invoke("Members")) {
						$group.Remove($($member.GetType().InvokeMember("Adspath", 'GetProperty', $Null, $member, $Null))) | Out-Null
						$count++
					}
					Write-Output $count
				}
				else {
					foreach ($member in $group.psbase.Invoke("Members")) {
						[string]$name = $member.GetType().InvokeMember("Name", 'GetProperty', $Null, $member, $Null)
						if ($name -eq $MemberName) {
							$group.Remove($($member.GetType().InvokeMember("Adspath", 'GetProperty', $Null, $member, $Null))) | Out-Null
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
	.SYNOPSIS
		Deletes a local user account by its username on a specified computer.
	.DESCRIPTION
		The Remove-NxtLocalUser cmdlet deletes a local user account from a computer. It first checks if the user exists and then proceeds to delete the account. If the user is not found or the deletion is unsuccessful, the operation returns $false.
	.PARAMETER UserName
		Name of the user account to delete.
		This parameter is mandatory.
	.PARAMETER COMPUTERNAME
		Name of the computer where the user account resides. Defaults to the value of $env:COMPUTERNAME.
	.EXAMPLE
		Remove-NxtLocalUser -UserName "Test"
	.EXAMPLE
		Remove-NxtLocalUser -UserName "JohnDoe" -COMPUTERNAME "Server01"
	.OUTPUTS
		System.Boolean.
		Returns $true if the operation was successful, otherwise returns $false.
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
			[bool]$userExists = Test-NxtLocalUserExists -UserName $UserName -ComputerName $COMPUTERNAME
			if ($true -eq $userExists) {
				[System.DirectoryServices.DirectoryEntry]$adsiObj = [ADSI]"WinNT://$COMPUTERNAME"
				$adsiObj.Delete("User", $UserName) | Out-Null
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
	.SYNOPSIS
		This function removes a specified process environment variable from the current session.
	.DESCRIPTION
		The Remove-NxtProcessEnvironmentVariable function deletes a process environment variable based on the provided key.
	.PARAMETER Key
		Specifies the key of the environment variable you want to remove.
		This parameter is mandatory.
	.EXAMPLE
		Remove-NxtProcessEnvironmentVariable -Key "TestVariable"
		This example will remove the process environment variable with the key "TestVariable" from the current session.
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
#region Function Remove-NxtProcessPathVariable
function Remove-NxtProcessPathVariable {
	<#
	.SYNOPSIS
		Removes a path to the processes PATH environment variable.
	.DESCRIPTION
		Removes a path to the processes PATH environment variable.
		Empty entries will be removed.
	.PARAMETER Path
		Path to be removed from the processes PATH environment variable.
	.EXAMPLE
		Remove-NxtProcessPathVariable -Path "C:\Temp"
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[string[]]$pathEntries = @(((Get-NxtProcessEnvironmentVariable -Key 'PATH').Split(';') |
			Where-Object {
				$false -eq [string]::IsNullOrEmpty($_) -and
				$_.ToLower().TrimEnd('\') -ne $Path.ToLower().TrimEnd('\')
			}))
		try {
			if ($pathEntries.Count -eq 0) {
				Set-NxtProcessEnvironmentVariable -Key "PATH" -Value ""
				Write-Log -Message "Removed all occurences of path '$Path' from PATH environment variable. Note: PATH environment variable is now empty." -Severity 2 -Source ${cmdletName}
			}
			[string]$pathString = ($pathEntries -join ";") + ";"
			Set-NxtProcessEnvironmentVariable -Key "PATH" -Value $pathString
			Write-Log -Message "Removed all occurences of path '$Path' from PATH environment variable."
		}
		catch {
			Write-Log -Message "Failed to remove path '$Path' from PATH environment variable." -Severity 3
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Remove-NxtSystemPathVariable
function Remove-NxtSystemPathVariable {
	<#
	.SYNOPSIS
		Removes a path to the systems PATH environment variable.
	.DESCRIPTION
		Removes a path to the systems PATH environment variable.
		Empty entries will be removed.
	.PARAMETER Path
		Path to be removed from the systems PATH environment variable.
	.EXAMPLE
		Remove-NxtSystemPathVariable -Path "C:\Temp"
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[string[]]$pathEntries = @(((Get-NxtSystemEnvironmentVariable -Key 'PATH').Split(';') |
			Where-Object {
				$false -eq [string]::IsNullOrEmpty($_) -and
				$_.TrimEnd('\') -ine $Path.TrimEnd('\')
			}))
		try {
			if ($pathEntries.Count -eq 0) {
				Set-NxtProcessEnvironmentVariable -Key "PATH" -Value ""
				Write-Log -Message "Removed all occurences of path '$Path' from PATH environment variable. Note: PATH environment variable is now empty." -Severity 2 -Source ${cmdletName}
			}
			[string]$pathString = ($pathEntries -join ";") + ";"
			Set-NxtSystemEnvironmentVariable -Key "PATH" -Value $pathString
			Write-Log -Message "Removed all occurences of path '$Path' from PATH environment variable."
		}
		catch {
			Write-Log -Message "Failed to remove path '$Path' from PATH environment variable." -Severity 3
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
		The Remove-NxtProductMember function is used for removing application packages that are registered and installed,
		and are members of a specific product identified by a ProductGUID.
		The function uses registry entries under the specified 'RegPackagesKey' to identify which application packages are
		members of the product.
	.PARAMETER ProductGUID
		Specifies the membership GUID for identifying the product to which an application package belongs.
		It can be found under "HKLM:\Software\<RegPackagesKey>\<PackageGUID>".
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RemovePackagesWithSameProductGUID
		Specifies whether to uninstall all application packages that have the same ProductGUID.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PackageGUID
		Specifies the registry key name used for the package's wrapper uninstall entry.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegPackagesKey
		Defines the registry key under which all packages are tracked by this packaging framework.
		Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Remove-NxtProductMember
		This example removes the installed and registered product member application packages based on the global configuration.
	.EXAMPLE
		Remove-NxtProductMember -ProductGUID "{042XXXXX-XXXX-XXXXXXXX-XXXXXXXXXXXX}" -PackageGUID "{042XXXXX-XXXX-XXXXXXXX-XXXXXXXXXXXX}"
		In this example, the function will remove the application packages with the specified ProductGUID and PackageGUID.
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
			(Get-NxtRegisteredPackage -ProductGUID $ProductGUID -InstalledState 1 -RegPackagesKey $RegPackagesKey).PackageGUID | Where-Object {
				$null -ne $($_)
			} | ForEach-Object {
				[string]$assignedPackageGUID = $_
				## we don't remove the current package inside this function
				if ($assignedPackageGUID -ne $PackageGUID) {
					[string]$assignedPackageUninstallString = $(Get-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$assignedPackageGUID" -Value 'UninstallString')
					Write-Log -Message "Processing product member application package with 'PackageGUID' [$assignedPackageGUID]..." -Source ${CmdletName}
					if ($false -eq ([string]::IsNullOrEmpty($assignedPackageUninstallString))) {
						Write-Log -Message "Removing package with uninstall call: '$assignedPackageUninstallString -SkipUnregister'." -Source ${CmdletName}
						cmd /c "$assignedPackageUninstallString -SkipUnregister"
						if ($LASTEXITCODE -ne 0) {
							Write-Log -Message "Removal of found product member application package failed with return code '$LASTEXITCODE'." -Severity 3 -Source ${CmdletName}
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
	.SYNOPSIS
		This function removes a specified system environment variable.
	.DESCRIPTION
		The Remove-NxtSystemEnvironmentVariable function deletes a system environment variable based on the given key. It uses .NET framework methods to perform the operation.
	.PARAMETER Key
		The name of the system environment variable you want to remove. This parameter is mandatory.
	.EXAMPLE
		Remove-NxtSystemEnvironmentVariable -Key "MyEnvironmentVariable"
		This example removes the system environment variable named "MyEnvironmentVariable".
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
		Repairs an MSI-based application by executing the necessary steps.
	.DESCRIPTION
		The Repair-NxtApplication function is designed to perform repair operations on an MSI-based application. It uses the MSI product code to identify the application to repair.
	.PARAMETER AppName
		Specifies the Application Name used in the registry etc.
		Defaults to the corresponding value from the PackageConfig object.
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
		Defaults to $global:PackageConfig.AcceptedInstallExitCodes.
	.PARAMETER AcceptedRepairRebootCodes
		Defines a list of reboot exit codes for all exit codes that will be accepted for reboot by called setup execution.
		Defaults to $global:PackageConfig.AcceptedInstallRebootCodes.
	.PARAMETER BackupRepairFile
		Defines the path to the MSI file that should be used for the repair if the registry method fails.
	.PARAMETER RepairLogPath
		Defines the path to the folder where the log file should be stored.
		Defaults to $configMSILogDir.
	.EXAMPLE
	Repair-NxtApplication -UninstallKey "{XXXXXXXX-XXXX-XXXXXXXX-XXXXXXXXXXXX}"
		This example repairs an application based on its specific uninstall registry key.
	.EXAMPLE
	Repair-NxtApplication -UninstallKey "My Application" -UninstallKeyIsDisplayName $true
		This example repairs an application based on its display name by setting UninstallKeyIsDisplayName to $true.
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
		$AcceptedRepairExitCodes = $global:PackageConfig.AcceptedInstallExitCodes,
		[Parameter(Mandatory = $false)]
		[string]
		$AcceptedRepairRebootCodes = $global:PackageConfig.AcceptedInstallRebootCodes,
		[Parameter(Mandatory = $false)]
		[string]
		$BackupRepairFile,
		[Parameter(Mandatory = $false)]
		[string]
		$RepairLogPath = $configMSILogDir
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[PSADTNXT.NxtApplicationResult]$repairResult = New-Object -TypeName PSADTNXT.NxtApplicationResult
		[int]$logMessageSeverity = 1
		[hashtable]$executeNxtParams = @{
			Action = 'Repair'
		}
		if ($true -eq ([string]::IsNullOrEmpty($UninstallKey))) {
			$repairResult.MainExitCode = 70001
			$repairResult.ErrorMessage = "No repair function executable - missing value for parameter 'UninstallKey'!"
			$repairResult.ErrorMessagePSADT = "expected function parameter 'UninstallKey' must not be empty"
			$repairResult.Success = $false
			[int]$logMessageSeverity = 3
		}
		else {
			$executeNxtParams["Path"] = (Get-NxtInstalledApplication -UninstallKey $UninstallKey -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -InstallMethod "MSI").ProductCode
			if ($true -eq ([string]::IsNullOrEmpty($executeNxtParams.Path))) {
				$repairResult.ErrorMessage = "Repair function could not run for provided parameter 'UninstallKey=$UninstallKey'. The expected msi setup of the application seems not to be installed on system!"
				$repairResult.Success = $null
				[int]$logMessageSeverity = 1
			}
			else {
				if ($false -eq ([string]::IsNullOrEmpty($RepairPara))) {
					if ($true -eq $AppendRepairParaToDefaultParameters) {
						[string]$executeNxtParams["AddParameters"] = "$RepairPara"
					}
					else {
						[string]$executeNxtParams["Parameters"] = "$RepairPara"
					}
				}
				if ($false -eq ([string]::IsNullOrEmpty($AcceptedRepairExitCodes))) {
					[string]$executeNxtParams["AcceptedExitCodes"] = "$AcceptedRepairExitCodes"
				}
				if ($false -eq ([string]::IsNullOrEmpty($AcceptedRepairRebootCodes))) {
					[string]$executeNxtParams["AcceptedRebootCodes"] = "$AcceptedRepairRebootCodes"
				}
				if ($true -eq ([string]::IsNullOrEmpty($RepairLogFile))) {
					## now set default path and name including retrieved ProductCode
					$RepairLogFile = Join-Path -Path $RepairLogPath -ChildPath ("Repair_$($executeNxtParams.Path).$DeploymentTimestamp.log")
				}
				## parameter -RepairFromSource $true runs 'msiexec /fvomus ...'
				[PsObject]$executionResult = Execute-NxtMSI @executeNxtParams -Log "$RepairLogFile" -RepairFromSource $true
				if ($executionResult.ExitCode -eq 1612 -and $false -eq [string]::IsNullOrEmpty($BackupRepairFile)) {
					Write-Log "Built-in repair mechanism failed with code [1612] due to missing sources. Trying installer from package." -Severity 2 -Source ${CmdletName}
					[string]$installerSourceRegPath = "Registry::HKEY_CLASSES_ROOT\Installer\Products\$(ConvertTo-NxtInstallerProductCode -ProductGuid $($executeNxtParams["Path"]))\SourceList"
					[string]$previousPackageName = Get-RegistryKey -Key $installerSourceRegPath -Value "PackageName"
					[string]$backupRepairFileName = Split-Path $BackupRepairFile -Leaf
					if (
						$false -eq [string]::IsNullOrEmpty($previousPackageName) -and
						$previousPackageName -ne $backupRepairFileName
					) {
						Write-Log "Found previously used source [$previousPackageName], that differs from package source [$backupRepairFileName]. Adjusting installer cache prior to repair." -Severity 2 -Source ${cmdletName}
						Set-RegistryKey -Key $installerSourceRegPath -Name "PackageName" -Value $backupRepairFileName
					}
					$executeNxtParams["Path"] = $BackupRepairFile
					$executionResult = Execute-NxtMSI @executeNxtParams -Log "$RepairLogFile" -RepairFromSource $true
				}
				$repairResult.ApplicationExitCode = $executionResult.ExitCode
				if ($executionResult.ExitCode -in ($AcceptedRepairRebootCodes -split ",")) {
					$repairResult.MainExitCode = 3010
					$repairResult.ErrorMessage = "Repair done with custom reboot return code '$($executionResult.ExitCode)'."
				}
				else {
					$repairResult.MainExitCode = $executionResult.ExitCode
					$repairResult.ErrorMessage = "Repair done with return code '$($executionResult.ExitCode)'."
				}
				if ($false -eq [string]::IsNullOrEmpty($executionResult.StdErr)) {
					$repairResult.ErrorMessagePSADT = "$($executionResult.StdErr)"
				}
				## Delay for filehandle release etc. to occur.
				Start-Sleep -Seconds 5
				if (
					(
						($executionResult.ExitCode -notin ($AcceptedInstallExitCodes -split ",")) -and
						($executionResult.ExitCode -notin ($AcceptedInstallRebootCodes -split ",")) -and
						($repairResult.MainExitCode -notin 0,1641,3010)
					) -or
					($false -eq $(Test-NxtAppIsInstalled -UninstallKey "$UninstallKey" -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -InstallMethod "MSI")) ) {
					$repairResult.ErrorMessage = "Repair of '$AppName' failed. ErrorLevel: $($repairResult.ApplicationExitCode)"
					$repairResult.Success = $false
					[int]$logMessageSeverity = 3
				}
				else {
					$repairResult.ErrorMessage = "Repair of '$AppName' was successful."
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
	.SYNOPSIS
		Resolves the installation status of dependent packages and performs actions based on their desired states.
	.DESCRIPTION
		The Resolve-NxtDependentPackage function checks if the specified dependent packages are installed or not.
		Based on their actual and desired states, it takes actions such as uninstalling or logging warnings.
		This function can operate using global package configuration or explicit parameter values.
	.PARAMETER DependentPackages
		An array of dependent packages to be checked.
		Requires a hash table with the following keys: GUID, DesiredState, OnConflict(Continue|Warn|Uninstall|Fail), ErrorMessage.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegPackagesKey
		The name of the Registry Key where all the packages are tracked.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PackageGUID
		Specifies the registry key name used for the package's wrapper uninstall entry.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER App
		Defines the path to a local persistent cache for installation files. This parameter is essential for locating and removing the actual application files. This parameter is mandatory. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppVendor
		Defines the name of the application vendor.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppRootFolder
		Defines the root folder of the application package. This parameter is mandatory. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER ScriptRoot
		Defines the parent directory of the script. It is essential for locating associated scripts and resources used during the uninstallation process. This parameter is mandatory. Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Resolve-NxtDependentPackages -DependentPackages $global:PackageConfig.DependentPackages
		This example resolves the installation status of dependent packages using the global package configuration.
	.EXAMPLE
		Resolve-NxtDependentPackage -DependentPackages @(@{GUID = "{042XXXXX-XXXX-XXXXXXXX-XXXXXXXXXXXX}";Errormessage = "abc missing"; DesiredState = "Present"; OnConflict = "Fail"})
		This example resolves the installation status of a dependent package with the specified GUID and desired state.
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
		$RegPackagesKey = $global:PackageConfig.RegPackagesKey,
		[Parameter(Mandatory = $false)]
		[string]
		$PackageGUID = $global:PackageConfig.PackageGUID,
		[Parameter(Mandatory = $false)]
		[string]
		$App = $global:PackageConfig.App,
		[Parameter(Mandatory = $false)]
		[string]
		$ScriptRoot = $scriptRoot,
		[Parameter(Mandatory = $false)]
		[string]
		$AppRootFolder = $global:PackageConfig.AppRootFolder,
		[Parameter(Mandatory = $false)]
		[string]
		$AppVendor = $global:PackageConfig.AppVendor
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		foreach ($dependentPackage in $DependentPackages) {
			[PSADTNXT.NxtRegisteredApplication]$registeredDependentPackage = Get-NxtRegisteredPackage -PackageGUID "$($dependentPackage.GUID)" -RegPackagesKey $RegPackagesKey
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
						Write-Log -Message "Removing dependent application package with uninstall call: '$dependentPackageUninstallString -SkipUnregister'." -Source ${CmdletName}
						cmd /c "$dependentPackageUninstallString -SkipUnregister"
						if ($LASTEXITCODE -ne 0) {
							Write-Log -Message "Removal of dependent application package failed with return code '$LASTEXITCODE'." -Severity 3 -Source ${CmdletName}
							throw "Removal of dependent application package failed."
						}
						## we must now explicitly unregister, because only an uninstall call with the '-SkipUnregister' parameter also prevents product member packages from being removed on recursive calls
						Unregister-NxtPackage -RemovePackagesWithSameProductGUID $false -PackageGUID "$($dependentPackage.GUID)" -RegPackagesKey "$RegPackagesKey" -ProductGUID $PackageGUID -App $App -ScriptRoot $ScriptRoot -AppRootFolder $AppRootFolder -AppVendor $AppVendor
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
#region Function Save-NxtXmlFile
function Save-NxtXmlFile {
	<#
	.SYNOPSIS
		Saves a xml Object to an XML file.
	.DESCRIPTION
		The Save-NxtXmlFile function saves a xml object to an XML file.
	.PARAMETER Path
		The full path of the XML file to be saved. This parameter is mandatory.
	.PARAMETER Xml
		The XML object to be saved. This parameter is mandatory.
	.PARAMETER Encoding
		The encoding to be used when saving the XML file.
	.PARAMETER DefaultEncoding
		The default encoding to be used when saving the XML file.
		Defaults to UTF8withBom, which is the best choice for most cases.
	.EXAMPLE
		Save-NxtXmlFile -Path "C:\path\to\file.xml" -Xml $xml
		This example saves the XML object to the specified file.
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path,
		[Parameter(Mandatory = $true)]
		[System.Xml.XmlDocument]
		$Xml,
		[Parameter(Mandatory = $false)]
		[string]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		$Encoding,
		[Parameter(Mandatory = $false)]
		[string]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		$DefaultEncoding = "UTF8withBom"
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[String]$intEncoding = $Encoding
		[bool]$fileExists = Test-Path -Path $Path
		if ($true -eq [string]::IsNullOrEmpty($intEncoding) ) {
			if ($false -eq $fileExists) {
				$intEncoding = $DefaultEncoding
			}
			else {
				try {
					[hashtable]$getFileEncodingParams = @{
						Path = $Path
					}
					if ($false -eq ([string]::IsNullOrEmpty($DefaultEncoding))) {
						[string]$getFileEncodingParams['DefaultEncoding'] = $DefaultEncoding
					}
					$intEncoding = (Get-NxtFileEncoding @getFileEncodingParams)
				}
				catch {
					$intEncoding = $DefaultEncoding
				}
			}
		}
		switch ($intEncoding) {
			'UTF8' {
				[System.Text.Encoding]$fileEncoding = New-Object System.Text.UTF8Encoding($false)
			}
			'UTF8withBom' {
				[System.Text.Encoding]$fileEncoding = New-Object System.Text.UTF8Encoding($true)
			}
			default {
				[System.Text.Encoding]$fileEncoding = [System.Text.Encoding]::$intEncoding
			}
		}
		try {
			[System.IO.StreamWriter]$stream = [System.IO.StreamWriter]::new($Path, $false, $fileEncoding)
			$Xml.Save($stream)
			Write-Log -Message "Saving XML Using encoding [$intEncoding]." -Source ${cmdletName}
		}
		catch {
			Write-Log -Message "Failed to save XML Document [$Path]. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
			throw "Failed to save XML Document [$Path]."
		}
		finally {
			$stream.Close()
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
		Sets the contents of the CustomSetup.cfg file to the global variable $global:CustomSetupCfg.
	.DESCRIPTION
		This function imports the settings from a CustomSetup.cfg file, which should be in INI format, into the global PowerShell variable $global:CustomSetupCfg.
	.PARAMETER Path
		The full path to the CustomSetup.cfg file that you wish to import. This includes both the directory path and the file name.
		This parameter is mandatory.
	.PARAMETER ContinueOnError
		Determines whether the function will continue to execute if an error is encountered.
		The default value is $true.
	.EXAMPLE
		Set-NxtCustomSetupCfg -Path "C:\path\to\customsetupcfg\CustomSetup.cfg" -ContinueOnError $false
		This example shows how to specify the path to the CustomSetup.cfg file and instructs the function to halt on any error.
	.NOTES
		The PSAppDeployToolkit is required to run this function.
	.LINK
		https://neo42.de/psappdeploytoolkit
	.OUTPUTS
		System.Boolean
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
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			[string]$customSetupCfgFileName = Split-Path -path "$Path" -Leaf
			Write-Log -Message "Checking for custom config file [$customSetupCfgFileName] under [$Path]..." -Source ${CmdletName}
			if ($true -eq (Test-Path -Path $Path)) {
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
#region Function Set-NxtFolderPermissions
function Set-NxtFolderPermissions {
	<#
	.SYNOPSIS
		Configures and applies custom access control permissions to a specified, existing folder.
	.DESCRIPTION
		The function allows granular control over the access permissions of a specified folder.
		It can assign specific permission levels (e.g., Full Control, Modify, Write, Read & Execute) to well-known security identifiers (SIDs).
		The function also provides options to set the owner, manage custom directory security settings, and control the inheritance of permissions.
		It is capable of applying these settings to both the target folder and its subfolders.
	.PARAMETER Path
		Specifies the full path of the folder whose permissions are to be configured.
	.PARAMETER FullControlPermissions
		An array of well-known SIDs to be granted Full Control permissions.
	.PARAMETER WritePermissions
		An array of well-known SIDs to be granted Write permissions.
	.PARAMETER ModifyPermissions
		An array of well-known SIDs to be granted Modify permissions.
	.PARAMETER ReadAndExecutePermissions
		An array of well-known SIDs to be granted Read & Execute permissions.
	.PARAMETER Owner
		The well-known SID of the user or group to be set as the owner of the folder.
	.PARAMETER CustomDirectorySecurity
		A DirectorySecurity object descrbing the permissions to be set on the folder.
	.PARAMETER BreakInheritance
		When set to $true, enforces inheritance of permissions on all subfolders.
		Default is $false.
	.EXAMPLE
		Set-NxtFolderPermissions -Path "C:\ActualFolder" -FullControlPermissions "BuiltinAdministrators" -Owner "BuiltinAdministrators"
		Sets the permissions and owner of "C:\ActualFolder" to the specified parameters.
	.EXAMPLE
		Set-NxtFolderPermissions -Path "C:\ActualFolder" -CustomDirectorySecurity $directorySecurity -EnforceInheritance $true
		Sets the permissions of "C:\ActualFolder" to the specified parameters. EnforceInheritance is set to $true.
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$FullControlPermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$WritePermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$ModifyPermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$ReadAndExecutePermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType]
		$Owner,
		[Parameter(Mandatory = $false)]
		[System.Security.AccessControl.DirectorySecurity]
		$CustomDirectorySecurity,
		[Parameter(Mandatory = $false)]
		[bool]
		$BreakInheritance = $true,
		[Parameter(Mandatory = $false)]
		[bool]
		$EnforceInheritanceOnSubFolders = $false
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ($false -eq (Test-Path -Path $Path)) {
			Write-Log -Message "Folder '$Path' does not exist!" -Source ${cmdletName} -Severity 3
			throw "Folder '$Path' does not exist!"
		}
		if ($false -eq [string]::IsNullOrEmpty($CustomDirectorySecurity)) {
			[System.Security.AccessControl.DirectorySecurity]$directorySecurity = $CustomDirectorySecurity
		}
		else {
			[System.Security.AccessControl.DirectorySecurity]$directorySecurity = New-Object System.Security.AccessControl.DirectorySecurity
		}
		foreach ($permissionLevel in @("FullControl","Modify", "Write", "ReadAndExecute")) {
			foreach ($wellKnownSid in $(Get-Variable "$permissionLevel`Permissions" -ValueOnly)) {
				[System.Security.AccessControl.FileSystemAccessRule]$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
					(New-Object System.Security.Principal.SecurityIdentifier -ArgumentList ($wellKnownSid, $null)),
					"$permissionLevel",
					"ContainerInherit,ObjectInherit",
					"None",
					"Allow"
				)
				$directorySecurity.AddAccessRule($rule) | Out-Null
			}
		}
		if ($null -ne $Owner) {
			$directorySecurity.SetOwner((New-Object System.Security.Principal.SecurityIdentifier -ArgumentList ($Owner, $null)))
		}
		$directorySecurity.SetAccessRuleProtection($BreakInheritance, $true)
		Set-Acl -Path $Path -AclObject $directorySecurity -ErrorAction Stop | Out-Null
		if ($true -eq $EnforceInheritanceOnSubFolders) {
			Write-Log -Message "Applying permissions to subfolders of '$Path'." -Source ${cmdletName}
			Get-ChildItem -Path $Path -Recurse | ForEach-Object {
				[psobject]$acl = Get-Acl -Path $_.FullName -ErrorAction Stop
				$acl.Access | Where-Object {
					$false -eq $_.IsInherited
				} | ForEach-Object {
					$acl.RemoveAccessRule($_) | Out-Null
				}
				# Enable inheritance
				$acl.SetAccessRuleProtection($false, $true) | Out-Null
				Set-Acl -Path $_.FullName -AclObject $acl -ErrorAction Stop | Out-Null
			}
		}
		if ($true -eq $BreakInheritance) {
			[bool]$testResult = Test-NxtFolderPermissions -Path $Path -CustomDirectorySecurity $directorySecurity
			if ($false -eq $testResult) {
				Write-Log -Message "Failed to set permissions" -Severity 3 -Source ${cmdletName}
				throw "Failed to set permissions on folder '$Path'"
			}
		}
		else {
			Write-Log -Message "BreakInheritance is set to `$False cannot test for correct permissions" -Severity 2
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
		Modifies or creates a specified INI file to set the value of a given section and key.
	.DESCRIPTION
		The Set-NxtIniValue function is used for opening or creating an INI file and setting the value for a specific section and key. The function has options to continue on errors and to create the file if it doesn't exist. The file, section, key, and value parameters are mandatory for the function to execute properly.
	.PARAMETER FilePath
		Path to the INI file you wish to modify or create. This parameter is mandatory.
	.PARAMETER Section
		Specifies the section within the INI file that you wish to modify or add. This parameter is mandatory.
	.PARAMETER Key
		Specifies the key within the selected section of the INI file that you wish to modify or add. This parameter is mandatory.
	.PARAMETER Value
		The value to be assigned to the specified key within the selected section of the INI file. To remove a value, set this parameter to $null. This parameter is mandatory.
	.PARAMETER ContinueOnError
		Boolean flag to continue executing the script even if an error is encountered. Default is: $true.
	.PARAMETER Create
		Boolean flag that determines whether or not to create the INI file if it does not already exist. Default is: $true.
	.EXAMPLE
		Set-NxtIniValue -FilePath "C:\ProgramFiles\Example\config.ini" -Section "General" -Key "LogLevel" -Value "Verbose"
		This example sets the value of "LogLevel" under the "General" section in the config.ini file to "Verbose".
	.EXAMPLE
		Set-NxtIniValue -FilePath "C:\ProgramFiles\Example\config.ini" -Section "Network" -Key "Port" -Value 8080 -Create $true
		This example sets the value of "Port" under the "Network" section in the config.ini file to 8080 and creates the file if it doesn't exist.
	.OUTPUTS
		none.
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
		$FilePath,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Section,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Key,
		# Don't strongly type this variable as [string] b/c PowerShell replaces [string]$Value = $null with an empty string
		[Parameter(Mandatory = $true)]
		[ValidateScript({
			if ($false -eq (($_.GetType().Name -eq "String") -or ($null -eq $_))) {
				throw "'$_' is not a string or null."
			}
			$true
		})]
		[AllowNull()]
		$Value,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[bool]
		$ContinueOnError = $true,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[bool]
		$Create = $true
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			if (($false -eq (Test-Path -Path $FilePath)) -and $Create) {
				New-Item -ItemType File -Path $FilePath -Force | Out-Null
			}
			if ($true -eq (Test-Path -Path $FilePath)) {
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
		Sets variables based on the application and system architecture.
	.DESCRIPTION
		This function sets various system variables based on the application architecture (AppArch) and the processor architecture.
		The variables set can include $ProgramFilesDir, $ProgramFilesDirx86, $System, $Wow6432Node, and others.
		It can adapt to x86, x64, and wildcard (*) AppArch settings.
	.PARAMETER AppArch
		Specifies the architecture of the application. Valid options are x86, x64, and *.
	.PARAMETER PROCESSOR_ARCHITECTURE
		Specifies the processor architecture of the system.
		Defaults to the system's $env:PROCESSOR_ARCHITECTURE.
	.PARAMETER ProgramFiles
		Specifies the Program Files directory.
		Defaults to the system's $env:ProgramFiles.
	.PARAMETER ProgramFiles(x86)
		Specifies the Program Files (x86) directory.
		Defaults to the system's $env:ProgramFiles(x86).
	.PARAMETER CommonProgramFiles
		Specifies the Common Program Files directory.
		Defaults to the system's $env:CommonProgramFiles.
	.PARAMETER CommonProgramFiles(x86)
		Specifies the Common Program Files (x86) directory.
		Defaults to the system's $env:CommonProgramFiles(x86).
	.PARAMETER SystemRoot
		Specifies the system root directory.
		Defaults to the system's $env:SystemRoot.
	.PARAMETER DeployAppScriptFriendlyName
		Specifies the friendly name of the script used for deploying applications.
		Defaults to $deployAppScriptFriendlyName definded in the DeployApplication.ps1.
	.EXAMPLE
		Set-NxtPackageArchitecture -AppArch "x64"
		Sets the architecture-specific variables based on a 64-bit application.
	.EXAMPLE
		Set-NxtPackageArchitecture -AppArch "x86" -ProgramFiles "C:\Program Files"
		Sets the architecture-specific variables for a 32-bit application and explicitly specifies the Program Files directory.
	.OUTPUTS
		System.Int32.
		Returns the function's exit code as an integer.
	.NOTES
		This function is intended to be executed during package initialization only.
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
				[string]$global:ProgramW6432 = [string]::Empty
				[string]$global:CommonFilesDir = $CommonProgramFiles
				[string]$global:CommonFilesDirx86 = $CommonProgramFiles
				[string]$global:CommonProgramW6432 = [string]::Empty
				[string]$global:System = "$SystemRoot\System32"
				[string]$global:Wow6432Node = [string]::Empty
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
				[string]$global:Wow6432Node = [string]::Empty
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
	.SYNOPSIS
		Sets a process environment variable.
	.DESCRIPTION
		This function sets an environment variable for the current PowerShell process. The variable will be accessible only for the duration of the process in which it was set.
	.PARAMETER Key
		The key name of the environment variable.
		This parameter is mandatory.
	.PARAMETER Value
		The value to be assigned to the environment variable.
		This parameter is mandatory.
	.EXAMPLE
		Set-NxtProcessEnvironmentVariable -Key "Test" -Value "Hello world"
		Sets an environment variable with key "Test" and value "Hello world" for the current process.
	.OUTPUTS
		none.
	.NOTES
		This function sets the variable for the current process only. The variable will not persist after the process terminates.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Key,
		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
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
			Write-Log -Message "Process the environment variable with key [$Key] and value [$Value]." -Source ${cmdletName}
		}
		catch {
			Write-Log -Message "Failed to set the process environment variable with key [$Key] and value [$Value]. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Set-NxtRebootVariable
function Set-NxtRebootVariable {
	<#
	.SYNOPSIS
		Sets $script:msiRebootDetected if a reboot is required.
	.DESCRIPTION
		Tests if a reboot is required based on $msiRebootDetected and Reboot from the packageconfig.
		To automatically apply the decision to the any call of Exit-Script use the -ApplyDecision switch.
	.PARAMETER MsiRebootDetected
		Defaults to $script:msiRebootDetected.
	.PARAMETER Reboot
		Indicates if a reboot is required by the script.
		0 = Decide based on $msiRebootDetected,
		1 = Reboot required,
		2 = Reboot not required.
		Default to $global:PackageConfig.Reboot.
	.OUTPUTS
		PSADTNXT.NxtRebootResult.
	.EXAMPLE
		Set-NxtRebootVariable
	.EXAMPLE
		Set-NxtRebootVariable -MsiRebootDetected $true -Reboot 0
		Sets $script:msiRebootDetected to $true.
	.NOTES
		This is an internal script function and should typically not be called directly.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[bool]
		$MsiRebootDetected = $script:msiRebootDetected,
		[Parameter(Mandatory = $false)]
		[ValidateSet(0,1,2)]
		[int]
		$Reboot = $global:PackageConfig.Reboot
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[PSADTNXT.NxtRebootResult]$rebootResult = Get-NxtRebootRequirement -MsiRebootDetected $MsiRebootDetected -Reboot $Reboot
		switch ($rebootResult.MainExitCode) {
			0 {
				Write-Log -Message "Setting `$msiRebootDetected from $script:msiRebootDetected to $false" -Severity 1 -Source ${CmdletName}
				$script:msiRebootDetected = $false
			}
			3010 {
				Write-Log -Message "Setting `$msiRebootDetected from $script:msiRebootDetected to $true" -Severity 1 -Source ${CmdletName}
				$script:msiRebootDetected = $true
			}
			Default {
				Write-Log -Message "Not Setting `$msiRebootDetected, ExitCode is not 0 or 3010" -Severity 1 -Source ${CmdletName}
			}
		}
		Write-Output $rebootResult
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
		Imports and sets the global configuration for a setup process from an INI file named Setup.cfg.
	.DESCRIPTION
		The Set-NxtSetupCfg function is designed to import configuration settings from an INI file, Setup.cfg, and store it into a global variable, $global:SetupCfg. It offers options to include default settings from the AppDeployToolkit (ADT) framework and continue running even when errors occur.
	.PARAMETER Path
		The full path to the Setup.cfg file you want to import. This parameter is mandatory.
	.PARAMETER AddDefaultOptions
		If set to $true, the function will also load all necessary default settings from the ADT framework configuration file if they are missing or undefined in the specified Setup.cfg file. The default value is $true.
	.PARAMETER ContinueOnError
		If set to $true, the function will continue running even when an error occurs during the import process. The default value is $true.
	.EXAMPLE
		Set-NxtSetupCfg -Path "C:\path\to\setupcfg\setup.cfg"
		Imports the Setup.cfg file from the specified path and uses the default settings for 'AddDefaultOptions' and 'ContinueOnError'.
	.EXAMPLE
		Set-NxtSetupCfg -Path "C:\path\to\setupcfg\setup.cfg" -AddDefaultOptions $false -ContinueOnError $false
		Imports the Setup.cfg file from the specified path but does not use any default settings from the PSADT framework and stops if an error occurs.
	.OUTPUTS
		none.
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
		$AddDefaultOptions = $true,
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
		if ($true -eq ([System.IO.File]::Exists($Path))) {
			if ($false -eq (Test-NxtSetupCfg -Path $Path)) {
				Write-Log -Message "Validating [$setupCfgFileName] failed." -Severity 3 -Source ${CmdletName}
				throw "Validating [$setupCfgFileName] failed."
			}
			[hashtable]$global:SetupCfg = Import-NxtIniFile -Path $Path -ContinueOnError $ContinueOnError
			Write-Log -Message "[$setupCfgFileName] was found and successfully parsed into global:SetupCfg object." -Source ${CmdletName}
		}
		else {
			Write-Log -Message "No [$setupCfgFileName] found. Skipped parsing values." -Severity 2 -Source ${CmdletName}
			[hashtable]$global:SetupCfg = $null
		}
		## provide all expected predefined values from ADT framework config file if they are missing/undefined in a default file 'setup.cfg' only
		if ($true -eq $AddDefaultOptions) {
			if ($null -eq $global:SetupCfg) {
				[hashtable]$global:SetupCfg = [hashtable]::new([StringComparer]::OrdinalIgnoreCase)
			}
			## note: xml nodes are case-sensitive
			foreach ( $xmlSection in ($xmlConfigFile.AppDeployToolkit_Config.SetupCfg_Parameters.ChildNodes.Name | Where-Object {
				$_ -ne "#comment"
			}) ) {
				foreach ( $xmlSectionSubValue in ($xmlConfigFile.AppDeployToolkit_Config.SetupCfg_Parameters.$xmlSection.ChildNodes.Name | Where-Object {
					$_ -ne "#comment"
				}) ) {
					if ($true -eq [string]::IsNullOrEmpty($global:SetupCfg.$xmlSection.$xmlSectionSubValue)) {
						if ($null -eq $global:SetupCfg.$xmlSection) {
							$global:SetupCfg.$xmlSection = [hashtable]::new([StringComparer]::OrdinalIgnoreCase)
						}
						if ($null -eq $global:SetupCfg.$xmlSection.$xmlSectionSubValue) {
							$global:SetupCfg.$xmlSection.add("$xmlSectionSubValue", "$($xmlConfigFile.AppDeployToolkit_Config.SetupCfg_Parameters.$xmlSection.$xmlSectionSubValue)")
						}
						else {
							$global:SetupCfg.$xmlSection.$xmlSectionSubValue = "$($xmlConfigFile.AppDeployToolkit_Config.SetupCfg_Parameters.$xmlSection.$xmlSectionSubValue)"
						}
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
	.SYNOPSIS
		Sets a system environment variable.
	.DESCRIPTION
		Sets a persistent system environment variable for the operating system.
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
		[AllowEmptyString()]
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
			Write-Log -Message "Set a system environment variable with key [$Key] and value [$Value]." -Source ${cmdletName}
		}
		catch {
			Write-Log -Message "Failed to set the system environment variable with key [$Key] and value [$Value]. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Set-NxtXmlNode
function Set-NxtXmlNode {
	<#
	.SYNOPSIS
		Sets or creates an XML node in a specified XML file.
	.DESCRIPTION
		The Set-NxtXmlNode function is used for setting the value and attributes of an existing XML node or creating a new one in a given XML file. The function takes parameters for the file path, node path, attributes, filter attributes, and inner text. If the node already exists, its value and attributes are updated based on the input parameters. If the node doesn't exist, it is created with the specified attributes and inner text.
	.PARAMETER FilePath
		The path to the XML file.
		This parameter is mandatory.
	.PARAMETER NodePath
		The XPath expression specifying the location of the node within the XML document. This parameter is mandatory.
	.PARAMETER Attributes
		A hashtable containing attributes to set or add to the XML node.
	.PARAMETER FilterAttributes
		A hashtable containing attributes to filter the XML node to be updated.
	.PARAMETER InnerText
		The text to set as the value of the XML node.
	.PARAMETER Encoding
		The encoding to be used when saving the XML file.
	.PARAMETER DefaultEncoding
		The default encoding to be used when saving the XML file.
		Defaults to UTF8withBom.
	.EXAMPLE
		Set-NxtXmlNode -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -Attributes @{"name"="NewNode2"} -InnerText "NewValue2"
		Sets the value of the node located at /RootNode/Settings/Settings2/SubSubSetting3 to "NewValue2" and adds the attribute name="NewNode2".
	.EXAMPLE
		Set-NxtXmlNode -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -InnerText "NewValue2"
		Sets the value of the node located at /RootNode/Settings/Settings2/SubSubSetting3 to "NewValue2", without altering or adding any attributes.
	.EXAMPLE
		Set-NxtXmlNode -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -InnerText [string]::Empty
		Sets the value of the node /RootNode/Settings/Settings2/SubSubSetting3 to an empty string.
	.EXAMPLE
		Set-NxtXmlNode -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -Attributes @{"name"="NewNode2"}
		Adds the attribute name="NewNode2" to the node /RootNode/Settings/Settings2/SubSubSetting3.
	.EXAMPLE
		Set-NxtXmlNode -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3"
		Creates the node /RootNode/Settings/Settings2/SubSubSetting3 without any attributes or value.
	.EXAMPLE
		Set-NxtXmlNode -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -FilterAttributes @{"name"="NewNode2"} -Attributes @{"Id"="NodeID"} -InnerText "NewValue2"
		Sets the value of the node /RootNode/Settings/Settings2/SubSubSetting3 to NewValue2 and adds the attribute Id="NodeID" if the node has the attribute name="NewNode2".
	.OUTPUTS
		none.
	.NOTES
		This function does not support XML namespaces.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$FilePath,
		[Parameter(Mandatory = $true)]
		[string]
		$NodePath,
		[Parameter(Mandatory = $false)]
		[hashtable]
		$Attributes,
		[Parameter(Mandatory = $false)]
		[hashtable]
		$FilterAttributes,
		[Parameter(Mandatory = $false)]
		[string]
		$InnerText,
		[Parameter(Mandatory = $false)]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[string]
		$Encoding,
		[Parameter(Mandatory = $false)]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[string]
		$DefaultEncoding = "UTF8withBom"

	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[hashtable]$testNxtXmlNodeParams = @{
			FilePath = $FilePath
			NodePath = $NodePath
		}
		if ($false -eq [string]::IsNullOrEmpty($FilterAttributes)) {
			$testNxtXmlNodeParams.Add("FilterAttributes", $FilterAttributes)
		}
		if ($false -eq (Test-Path -Path $FilePath)) {
			Write-Log -Message "File $FilePath does not exist" -Severity 3
			throw "File $FilePath does not exist"
		}
		# Test for Node
		if ($true -eq (Test-NxtXmlNodeExists @testNxtXmlNodeParams)) {
			[hashtable]$updateNxtXmlNodeParams = @{
				FilePath = $FilePath
				NodePath = $NodePath
			}
			if ($PSBoundParameters.Keys -contains "InnerText") {
				$updateNxtXmlNodeParams.Add("InnerText", $InnerText)
			}
			if ($false -eq [string]::IsNullOrEmpty($Attributes)) {
				$updateNxtXmlNodeParams.Add("Attributes", $Attributes)
			}
			if ($false -eq [string]::IsNullOrEmpty($FilterAttributes)) {
				$updateNxtXmlNodeParams.Add("FilterAttributes", $FilterAttributes)
			}
			if ($false -eq [string]::IsNullOrEmpty($Encoding)) {
				$updateNxtXmlNodeParams['Encoding'] = $Encoding
			}
			if ($false -eq [string]::IsNullOrEmpty($DefaultEncoding)) {
				$updateNxtXmlNodeParams['DefaultEncoding'] = $DefaultEncoding
			}
			Update-NxtXmlNode @updateNxtXmlNodeParams
		}
	else {
			[hashtable]$addNxtXmlNodeParams = @{
				FilePath = $FilePath
				NodePath = $NodePath
			}
			if ($PSBoundParameters.Keys -contains "InnerText") {
				$addNxtXmlNodeParams.Add("InnerText", $InnerText)
			}
			if ($false -eq [string]::IsNullOrEmpty($Attributes)) {
				$addNxtXmlNodeParams.Add("Attributes", $Attributes)
			}
			if ($false -eq [string]::IsNullOrEmpty($Encoding)) {
				$addNxtXmlNodeParams['Encoding'] = $Encoding
			}
			if ($false -eq [string]::IsNullOrEmpty($DefaultEncoding)) {
				$addNxtXmlNodeParams['DefaultEncoding'] = $DefaultEncoding
			}
			Add-NxtXmlNode @addNxtXmlNodeParams
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
	Displays a customizable welcome dialog for software installations, offering options like closing specified applications, deferring installation, and blocking application execution during installation.
	.DESCRIPTION
		Show-NxtInstallationWelcome is a versatile PowerShell function designed to interact with users during software installations. It provides a range of features:
			- Prompting users to close specified running applications.
			- Allowing installation deferral based on time or number of deferrals.
			- Providing countdowns for automatic application closure or installation deferral.
			- Blocking specified applications from running during installation.
		Additional functionalities include process description retrieval, customizable timeout for the dialog, and compatibility with different user session types.
	.PARAMETER Silent
		Closes specified applications without user prompt. Default value: $false. This parameter is optional.
	.PARAMETER CloseAppsCountdown
		Specifies a countdown in seconds before specified applications are automatically closed. The default value is specified in the setup.cfg. This parameter is optional.
	.PARAMETER ForceCloseAppsCountdown
		Forces application closure after a specified countdown, regardless of deferral settings. Default value: 0. This parameter is optional.
	.PARAMETER PromptToSave
		Allows prompting users to save work before closing applications. Not functional in SYSTEM context without specific launch conditions. Default value: $false. This parameter is optional.
	.PARAMETER PersistPrompt
		Makes the welcome prompt reappear periodically, ensuring user response. Effective when deferral is not allowed or expired. Default value: $false. This parameter is optional.
	.PARAMETER BlockExecution
		Prevents users from launching specified applications during installation. Defaults to the corresponding variable from $global:PackageConfig. This parameter is optional.
	.PARAMETER AllowDefer
		Enables deferral of installation. Default value: $false. This parameter is optional.
	.PARAMETER AllowDeferCloseApps
		Allows deferral only when specified applications are running. Implicitly enables AllowDefer. Default value: $false. This parameter is optional.
	.PARAMETER DeferTimes
		Sets the number of times installation can be deferred. Default value is determined by the global SetupCfg object. This parameter is optional.
	.PARAMETER DeferDays
		Defines the number of days since first run for allowing installation deferral. Default value is determined by the global SetupCfg object. This parameter is optional.
	.PARAMETER DeferDeadline
		Sets a deadline for installation deferral. Accepts date in local culture format or universal sortable format. Default value: Empty string. This parameter is optional.
	.PARAMETER MinimizeWindows
		Determines if other windows should be minimized when displaying the prompt. Default value is determined by the global SetupCfg object. This parameter is optional.
	.PARAMETER TopMost
		Sets the welcome window as the topmost window. Default value is determined by the global SetupCfg object. This parameter is optional.
	.PARAMETER ForceCountdown
		Specifies a countdown to automatically proceed with installation when deferral is enabled. Default value: 0. This parameter is optional.
	.PARAMETER CustomText
		Allows displaying custom messages defined in an XML file. Default value: $false. This parameter is optional.
	.PARAMETER IsInstall
		Indicates if the function is being used for installation or uninstallation. This parameter is mandatory.
	.PARAMETER ContinueType
		Defines behavior after dialog timeout. Influences further actions. Default value is determined by the global SetupCfg object. This parameter is optional.
	.PARAMETER UserCanCloseAll
		Allows users to close all specified applications. Default value is determined by the global SetupCfg object. This parameter is optional.
	.PARAMETER UserCanAbort
		Permits users to abort the installation process. Default value is determined by the global SetupCfg object. This parameter is optional.
	.PARAMETER ApplyContinueTypeOnError
		Determines if ContinueType should be applied in case of an error. Default value is determined by the global SetupCfg object. This parameter is optional.
	.PARAMETER ScriptRoot
		Defines the parent directory of the script. Defaults to the script root variable set by AppDeployToolkitMain.ps1. This parameter is optional.
	.PARAMETER ProcessIdToIgnore
		Specifies a process ID to ignore during operations. Defaults to the current process ID. This parameter is optional.
	.PARAMETER BlockScriptLocation
		Path to the BlockScriptLocation folder used to place the BlockExecution file. Defaults to the variable $global:PackageConfig.App. This parameter is optional.
	.EXAMPLE
		Show-NxtInstallationWelcome -AskKillProcessApps @([pscustomobject]@{Name = "iexplore"; Description = "Internet Explorer"}, [pscustomobject]@{Name = "winword"; Description = "Microsoft Word"}, [pscustomobject]@{Name = "excel"; Description = "Microsoft Excel"}) -CloseAppsCountdown 600 -Silent
		Silently closes Internet Explorer, Microsoft Word, and Microsoft Excel without user interaction, with a countdown of 10 minutes (600 seconds).

	.EXAMPLE
		Show-NxtInstallationWelcome -AskKillProcessApps @([pscustomobject]@{Name = "outlook"; Description = "Microsoft Outlook"}) -CloseAppsCountdown 300 -PersistPrompt -AllowDefer -DeferDays 5
		Displays a persistent prompt every few seconds to close Microsoft Outlook with a 5-minute countdown. Allows the user to defer the installation for up to 5 days.

	.EXAMPLE
		Show-NxtInstallationWelcome -AskKillProcessApps @([pscustomobject]@{Name = "chrome"; Description = "Google Chrome"}, [pscustomobject]@{Name = "firefox"; Description = "Mozilla Firefox"}) -BlockExecution -AllowDefer -DeferDeadline '25/08/2013'
		Blocks Google Chrome and Mozilla Firefox from executing during installation and allows the user to defer the installation until the specified deadline.

	.EXAMPLE
		Show-NxtInstallationWelcome -AskKillProcessApps @([pscustomobject]@{Name = "notepad"; Description = "Notepad"}) -PromptToSave -CustomText -MinimizeWindows
		Prompts the user to save work in Notepad before closing it with custom text, minimizing other windows when displaying the prompt.
	.OUTPUTS
		System.Int32. Returns an exit code based on the user's response or timeout occurrence.
	.NOTES
		The code of this function is mainly adopted from the PSAppDeployToolkit Show-InstallationWelcome function licensed under the LGPLv3.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		## Specify whether to prompt user or force close the applications
		[Parameter(Mandatory = $false)]
		[Switch]
		$Silent = $false,
		## Specify a countdown to display before automatically closing applications where deferral is not allowed or has expired
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Int32]
		$CloseAppsCountdown = $global:SetupCfg.AskKillProcesses.Timeout,
		## Specify a countdown to display before automatically closing applications whether or not deferral is allowed
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Int32]
		$ForceCloseAppsCountdown = 0,
		## Specify whether to prompt to save working documents when the user chooses to close applications by selecting the "Close Programs" button
		[Parameter(Mandatory = $false)]
		[Switch]
		$PromptToSave = $false,
		## Specify whether to make the prompt persist in the center of the screen every couple of seconds, specified in the AppDeployToolkitConfig.xml.
		[Parameter(Mandatory = $false)]
		[Switch]
		$PersistPrompt = $false,
		## Specify whether to block execution of the processes during installation
		[Parameter(Mandatory = $false)]
		[Switch]
		$BlockExecution = $($global:PackageConfig.BlockExecution),
		## Specify whether to enable the optional defer button on the dialog box
		[Parameter(Mandatory = $false)]
		[Switch]
		$AllowDefer = $false,
		## Specify whether to enable the optional defer button on the dialog box only if an app needs to be closed
		[Parameter(Mandatory = $false)]
		[Switch]
		$AllowDeferCloseApps = $false,
		## Specify the number of times the deferral is allowed
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Int32]
		$DeferTimes = $global:SetupCfg.AskKillProcesses.DeferTimes,
		## Specify the number of days since first run that the deferral is allowed
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Int32]
		$DeferDays = $global:SetupCfg.AskKillProcesses.DeferDays,
		## Specify the deadline (in format dd/mm/yyyy) for which deferral will expire as an option
		[Parameter(Mandatory = $false)]
		[String]
		$DeferDeadline = [string]::Empty,
		## Specify whether to minimize other windows when displaying prompt
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[bool]
		$MinimizeWindows = [System.Convert]::ToBoolean([System.Convert]::ToInt32($global:SetupCfg.AskKillProcesses.MINIMIZEALLWINDOWS)),
		## Specifies whether the window is the topmost window
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[bool]
		$TopMost = [System.Convert]::ToBoolean([System.Convert]::ToInt32($global:SetupCfg.AskKillProcesses.TOPMOSTWINDOW)),
		## Specify a countdown to display before automatically proceeding with the installation when a deferral is enabled
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Int32]
		$ForceCountdown = 0,
		## Specify whether to display a custom message specified in the XML file. Custom message must be populated for each language section in the XML.
		[Parameter(Mandatory = $false)]
		[Switch]
		$CustomText = $false,
		[Parameter(Mandatory = $true)]
		[bool]
		$IsInstall,
		[Parameter(Mandatory = $false)]
		[array]
		$AskKillProcessApps = $global:PackageConfig.AppKillProcesses,
		## this window is automatically closed after the timeout and the further behavior can be influenced with the ContinueType.
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[PSADTNXT.ContinueType]
		$ContinueType = $global:SetupCfg.AskKillProcesses.ContinueType,
		## Specifies if the user can close all applications
		[Parameter(Mandatory = $false)]
		[Switch]
		$UserCanCloseAll = [System.Convert]::ToBoolean([System.Convert]::ToInt32($global:SetupCfg.ASKKILLPROCESSES.USERCANCLOSEALL)),
		## Specifies if the user can abort the process
		[Parameter(Mandatory = $false)]
		[Switch]
		$UserCanAbort = [System.Convert]::ToBoolean([System.Convert]::ToInt32($global:SetupCfg.ASKKILLPROCESSES.ALLOWABORTBYUSER)),
		## Specifies if the ContinueType should be applied on error
		[Parameter(Mandatory = $false)]
		[Switch]
		$ApplyContinueTypeOnError = [System.Convert]::ToBoolean([System.Convert]::ToInt32($global:SetupCfg.ASKKILLPROCESSES.APPLYCONTINUETYPEONERROR)),
		## Specifies the script root path
		[Parameter(Mandatory = $false)]
		[string]
		$ScriptRoot = $scriptRoot,
		[Parameter(Mandatory = $false)]
		[int]
		$ProcessIdToIgnore = $PID,
		[Parameter(Mandatory = $false)]
		[string]
		$BlockScriptLocation = $global:PackageConfig.App
	)
	Begin {
		## Get the name of this function and write header
		[String]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		## To break the array references to the parent object we have to create new(copied) objects from the provided array.
		$AskKillProcessApps = $AskKillProcessApps | Select-Object *
		## override $DeferDays with 0 in Case of Uninstall
		if ($false -eq $IsInstall) {
			$DeferDays = 0
		}
		[string]$fileExtension = ".exe"
		[PSObject[]]$processObjects = @()
		foreach ( $processAppsItem in $AskKillProcessApps ) {
			if ( $processAppsItem.Name -match '^[\*\.]+((?:[^\*]exe)|)$|^\.exe$' ) {
				Write-Log -Message "Not supported app list entry '$($processAppsItem.Name)' for 'CloseApps' process collection found, please check the parameter for processes ask to kill in config file!" -Severity 3 -Source ${cmdletName}
				throw "Not supported app entry '$($processAppsItem.Name)' for 'CloseApps' process collection found, please check the parameter for processes ask to kill in config file!"
			}
			if ($true -eq ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($processAppsItem.Name))) {
				Write-Log -Message "Wildcard in list entry for 'CloseApps' process collection detected, retrieving all matching running processes for '$($processAppsItem.Name)' ..." -Source ${cmdletName}
				## Get-WmiObject Win32_Process always requires an extension, so we add one in case there is none
				[string]$query = $($($processAppsItem.Name -replace "\$fileExtension$", "") + $fileExtension).Replace("*","%")
				[System.Management.ManagementBaseObject[]]$processes = Get-WmiObject -Query "Select * from Win32_Process Where Name LIKE '$query'"
				[string[]]$processNames = $processes | Select-Object -ExpandProperty 'Name' -ErrorAction 'SilentlyContinue' | ForEach-Object {
					$_ -replace "\$fileExtension$", [string]::Empty
				} | Where-Object {
					$false -eq [string]::IsNullOrEmpty($_)
				} | Select-Object -Unique
				if ( $processNames.Count -eq 0 ) {
					Write-Log -Message "... no processes found." -Source ${cmdletName}
				}
				else {
					Write-Log -Message "... found processes (with file extensions removed): $processNames" -Source ${cmdletName}
					foreach ( $processName in $processNames ) {
						$processObjects += New-Object -TypeName 'PSObject' -Property @{
							ProcessName			= $processName
							ProcessDescription	= [string]::Empty
							IsWql				= $false
						}
					}
				}
				## be sure there is no description to add in case of process name with wildcards
				[string]$processAppsItem.Description = [string]::Empty
			}
			else {
				## default item improvement: for later calling of ADT CMDlet no file extension is allowed (remove extension if exist)
				[string]$processAppsItem.Name = $processAppsItem.Name -replace "\$fileExtension$", [string]::Empty

				if ($true -eq ($processAppsItem.Name.Contains('='))) {
					[String[]]$processSplit = $processAppsItem.Name -split '='
					$processObjects += New-Object -TypeName 'PSObject' -Property @{
						ProcessName			= $processSplit[0]
						ProcessDescription	= $processSplit[1]
						IsWql				= $false
					}
				}
				else {
					$processObjects += New-Object -TypeName 'PSObject' -Property @{
						ProcessName			= $processAppsItem.Name
						ProcessDescription	= $processAppsItem.Description
						IsWql				= [bool]$processAppsItem.IsWQL
					}
				}
			}
		}
		if ($false -eq [string]::IsNullOrEmpty($defaultMsiExecutablesList)) {
			foreach ($defaultMsiExecutable in ($defaultMsiExecutablesList -split ",")) {
				$processObjects += New-Object -TypeName 'PSObject' -Property @{
					ProcessName			= $defaultMsiExecutable
					ProcessDescription	= [string]::Empty
					IsWql				= $false
				}
			}
		}

		## prevent BlockExecution function if there is no process to kill
		if ($true -eq [string]::IsNullOrEmpty($defaultMsiExecutablesList) -and $processObjects.Count -eq 0) {
			$BlockExecution = $false
		}

		## Check Deferral history and calculate remaining deferrals
		if (($true -eq $AllowDefer) -or ($true -eq $AllowDeferCloseApps)) {
			#  Set $AllowDefer to true if $AllowDeferCloseApps is true
			$AllowDefer = $true

			#  Get the deferral history from the registry
			[psobject]$deferHistory = Get-DeferHistory
			[psobject]$deferHistoryTimes = $deferHistory | Select-Object -ExpandProperty 'DeferTimesRemaining' -ErrorAction 'SilentlyContinue'
			[psobject]$deferHistoryDeadline = $deferHistory | Select-Object -ExpandProperty 'DeferDeadline' -ErrorAction 'SilentlyContinue'

			#  Reset Switches
			[bool]$checkDeferDays = $false
			[bool]$checkDeferDeadline = $false
			if ($DeferDays -ne 0) {
				[bool]$checkDeferDays = $true
			}
			if ($true -eq $DeferDeadline) {
				[bool]$checkDeferDeadline = $true
			}
			if ($DeferTimes -ne 0) {
				if ($deferHistoryTimes -ge 0) {
					Write-Log -Message "Defer history shows [$($deferHistory.DeferTimesRemaining)] deferrals remaining." -Source ${CmdletName}
					$DeferTimes = $deferHistory.DeferTimesRemaining - 1
				}
				else {
					$DeferTimes = $DeferTimes - 1
				}
				Write-Log -Message "The user has [$deferTimes] deferrals remaining." -Source ${CmdletName}
				if ($DeferTimes -lt 0) {
					Write-Log -Message 'Deferral has expired.' -Source ${CmdletName}
					$AllowDefer = $false
				}
			}
			else {
				if ($true -eq (Test-Path -LiteralPath 'variable:deferTimes')) {
					Remove-Variable -Name 'deferTimes'
				}
				$DeferTimes = $null
			}
			if (($true -eq $checkDeferDays) -and ($true -eq $AllowDefer)) {
				if ($null -ne $deferHistoryDeadline) {
					Write-Log -Message "Defer history shows a deadline date of [$deferHistoryDeadline]." -Source ${CmdletName}
					[String]$deferDeadlineUniversal = Get-UniversalDate -DateTime $deferHistoryDeadline
				}
				else {
					[String]$deferDeadlineUniversal = Get-UniversalDate -DateTime (Get-Date -Date ((Get-Date).AddDays($deferDays)) -Format ($culture).DateTimeFormat.UniversalDateTimePattern).ToString()
				}
				Write-Log -Message "The user has until [$deferDeadlineUniversal] before deferral expires." -Source ${CmdletName}
				if ((Get-UniversalDate) -gt $deferDeadlineUniversal) {
					Write-Log -Message 'Deferral has expired.' -Source ${CmdletName}
					$AllowDefer = $false
				}
			}
			if (($true -eq $checkDeferDeadline) -and ($true -eq $AllowDefer)) {
				#  Validate Date
				try {
					[String]$deferDeadlineUniversal = Get-UniversalDate -DateTime $deferDeadline -ErrorAction 'Stop'
				}
				catch {
					Write-Log -Message "Date is not in the correct format for the current culture. Type the date in the current locale format, such as 20/08/2014 (Europe) or 08/20/2014 (United States). If the script is intended for multiple cultures, specify the date in the universal sortable date/time format, e.g. '2013-08-22 11:51:52Z'. `r`n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
					throw "Date is not in the correct format for the current culture. Type the date in the current locale format, such as 20/08/2014 (Europe) or 08/20/2014 (United States). If the script is intended for multiple cultures, specify the date in the universal sortable date/time format, e.g. '2013-08-22 11:51:52Z': $($_.Exception.Message)"
				}
				Write-Log -Message "The user has until [$deferDeadlineUniversal] remaining." -Source ${CmdletName}
				if ((Get-UniversalDate) -gt $deferDeadlineUniversal) {
					Write-Log -Message 'Deferral has expired.' -Source ${CmdletName}
					$AllowDefer = $false
				}
			}
		}
		if (($deferTimes -lt 0) -and ($false -eq $deferDeadlineUniversal)) {
			$AllowDefer = $false
		}
		[string]$promptResult = [string]::Empty
		## Prompt the user to close running applications and optionally defer if enabled
		if ($false -eq $silent) {
			if ($forceCloseAppsCountdown -gt 0) {
				#  Keep the same variable for countdown to simplify the code:
				[int]$closeAppsCountdown = $forceCloseAppsCountdown
				#  Change this variable to a boolean now to switch the countdown on even with deferral
				[bool]$forceCloseAppsCountdown = $true
			}
			elseif ($forceCountdown -gt 0) {
				#  Keep the same variable for countdown to simplify the code:
				[int]$closeAppsCountdown = $forceCountdown
				#  Change this variable to a boolean now to switch the countdown on
				[bool]$forceCountdown = $true
			}
			Set-Variable -Name 'closeAppsCountdownGlobal' -Value $closeAppsCountdown -Scope 'Script'
			[int[]]$processIdsToIgnore = @()
			if ($processIdToIgnore -gt 0) {
				[int[]]$processIdsToIgnore = (Get-NxtProcessTree -ProcessId $processIdToIgnore -IncludeParentProcesses $true -IncludeChildProcesses $true).ProcessId
			}
			while ((Get-NxtRunningProcesses -ProcessObjects $processObjects -OutVariable 'runningProcesses' -ProcessIdsToIgnore $processIdsToIgnore) -or (($false -eq ($promptResult.Contains('Defer'))) -and ($false -eq ($promptResult.Contains('Close'))))) {
				[String]$runningProcessDescriptions = ($runningProcesses | Where-Object {
					$false -eq [string]::IsNullOrEmpty($_.ProcessDescription)
				} | Select-Object -ExpandProperty 'ProcessDescription') -join ','
				#  If no proccesses are running close
				if ($true -eq ([string]::IsNullOrEmpty($runningProcessDescriptions))) {
					break
				}
				if ($CloseAppsCountdown -gt 0) {
					#  Check if we need to prompt the user to defer, to defer and close apps, or not to prompt them at all
					if (($true -eq $AllowDefer) -and (($false -eq ($promptResult.Contains('Close'))) -or (($runningProcessDescriptions) -and ($false -eq ($promptResult.Contains('Continue')))))) {
						$promptResult = Show-NxtWelcomePrompt -ProcessObjects $processObjects -ProcessDescriptions $runningProcessDescriptions -CloseAppsCountdown $closeAppsCountdownGlobal -PersistPrompt $PersistPrompt -AllowDefer -DeferTimes $deferTimes -DeferDeadline $deferDeadlineUniversal -MinimizeWindows $MinimizeWindows -CustomText:$CustomText -TopMost $TopMost -ContinueType $ContinueType -UserCanCloseAll:$UserCanCloseAll -UserCanAbort:$UserCanAbort -ApplyContinueTypeOnError:$ApplyContinueTypeOnError -ProcessIdToIgnore $ProcessIdToIgnore
					}
					#  If there is no deferral and processes are running, prompt the user to close running processes with no deferral option
					elseif (($true -eq $runningProcessDescriptions) -or ($true -eq $forceCountdown)) {
						$promptResult = Show-NxtWelcomePrompt -ProcessObjects $processObjects -ProcessDescriptions $runningProcessDescriptions -CloseAppsCountdown $closeAppsCountdownGlobal -PersistPrompt $PersistPrompt -MinimizeWindows $minimizeWindows -CustomText:$CustomText -TopMost $TopMost -ContinueType $ContinueType -UserCanCloseAll:$UserCanCloseAll -UserCanAbort:$UserCanAbort -ApplyContinueTypeOnError:$ApplyContinueTypeOnError -ProcessIdToIgnore $ProcessIdToIgnore
					}
					#  If there is no deferral and no processes running, break the while loop
					else {
						break
					}
				}
				else {
					# These results are equivalent the results of Show-NxtWelcomePrompt
					if ($ContinueType -eq [PSADTNXT.ContinueType]::Abort) {
						$promptResult = 'Cancel'
					}
					else {
						$promptResult = 'Close'
					}
				}
				if ($true -eq ($promptResult.Contains('Cancel'))) {
					Write-Log -Message 'The user selected to cancel or grace period to wait for closing processes was over...' -Source ${CmdletName}

					#  Restore minimized windows
					$shellApp.UndoMinimizeAll() | Out-Null

					Write-Output $configInstallationUIExitCode
					return
				}
				#  If the user has clicked OK, wait a few seconds for the process to terminate before evaluating the running processes again
				if ($true -eq ($promptResult.Contains('Continue'))) {
					Write-Log -Message 'The user selected to continue...' -Source ${CmdletName}
					Start-Sleep -Seconds 2

					#  Break the while loop if there are no processes to close and the user has clicked OK to continue
					if ($false -eq $runningProcesses) {
						break
					}
				}
				#  Force the applications to close
				elseif ($true -eq ($promptResult.Contains('Close'))) {
					Write-Log -Message 'The user selected to force the application(s) to close or timeout was reached with ContinueType set to Continue...' -Source ${CmdletName}
					if (($true -eq $PromptToSave) -and (($true -eq $SessionZero) -and ($false -eq $IsProcessUserInteractive))) {
						Write-Log -Message 'Specified [-PromptToSave] option will not be available, because current process is running in session zero and is not interactive.' -Severity 2 -Source ${CmdletName}
					}
					# Update the process list right before closing, in case it changed
					if ($processIdToIgnore -gt 0) {
						[int[]]$processIdsToIgnore = (Get-NxtProcessTree -ProcessId $processIdToIgnore).ProcessId
					}
					[System.Diagnostics.Process[]]$runningProcesses = Get-NxtRunningProcesses -ProcessObjects $processObjects -ProcessIdsToIgnore $processIdsToIgnore
					# Close running processes
					foreach ($runningProcess in $runningProcesses) {
						[PSObject[]]$allOpenWindowsForRunningProcess = Get-WindowTitle -GetAllWindowTitles -DisableFunctionLogging | Where-Object {
							$_.ParentProcess -eq $runningProcess.ProcessName
						}
						#  If the PromptToSave parameter was specified and the process has a window open, then prompt the user to save work if there is work to be saved when closing window
						if (($true -eq $PromptToSave) -and ($true -eq $IsProcessUserInteractive) -and ($true -eq $allOpenWindowsForRunningProcess) -and ($runningProcess.MainWindowHandle -ne [IntPtr]::Zero)) {
							[Timespan]$promptToSaveTimeout = New-TimeSpan -Seconds $configInstallationPromptToSave
							[Diagnostics.StopWatch]$promptToSaveStopWatch = [Diagnostics.StopWatch]::StartNew()
							$promptToSaveStopWatch.Reset()
							foreach ($openWindow in $allOpenWindowsForRunningProcess) {
								try {
									Write-Log -Message "Stopping process [$($runningProcess.ProcessName)] with window title [$($openWindow.WindowTitle)] and prompt to save if there is work to be saved (timeout in [$configInstallationPromptToSave] seconds)..." -Source ${CmdletName}
									[PSADT.UiAutomation]::BringWindowToFront($openWindow.WindowHandle) | Out-Null
									[bool]$isCloseWindowCallSuccess = $runningProcess.CloseMainWindow()
									if ($false -eq $isCloseWindowCallSuccess) {
										Write-Log -Message "Failed to call the CloseMainWindow() method on process [$($runningProcess.ProcessName)] with window title [$($openWindow.WindowTitle)] because the main window may be disabled due to a modal dialog being shown." -Severity 3 -Source ${CmdletName}
									}
									else {
										$promptToSaveStopWatch.Start()
										do {
											[bool]$isWindowOpen = [bool](Get-WindowTitle -GetAllWindowTitles -DisableFunctionLogging | Where-Object {
												$_.WindowHandle -eq $openWindow.WindowHandle
											})
											if ($false -eq $isWindowOpen) {
												break
											}
											Start-Sleep -Seconds 3
										}
										while (($true -eq $isWindowOpen) -and ($promptToSaveStopWatch.Elapsed -lt $promptToSaveTimeout))
										$promptToSaveStopWatch.Reset()
										if ($true -eq $isWindowOpen) {
											Write-Log -Message "Exceeded the [$configInstallationPromptToSave] seconds timeout value for the user to save work associated with process [$($runningProcess.ProcessName)] with window title [$($openWindow.WindowTitle)]." -Severity 2 -Source ${CmdletName}
										}
										else {
											Write-Log -Message "Window [$($openWindow.WindowTitle)] for process [$($runningProcess.ProcessName)] was successfully closed." -Source ${CmdletName}
										}
									}
								}
								catch {
									Write-Log -Message "Failed to close window [$($openWindow.WindowTitle)] for process [$($runningProcess.ProcessName)]. `r`n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
									continue
								}
								finally {
									$runningProcess.Refresh()
								}
							}
						}
						else {
							Write-Log -Message "Stopping process $($runningProcess.ProcessName)..." -Source ${CmdletName}
							Stop-NxtProcess -Name $runningProcess.ProcessName
						}
					}
					if ($processIdToIgnore -gt 0) {
						[int[]]$processIdsToIgnore = (Get-NxtProcessTree -ProcessId $processIdToIgnore).ProcessId
					}
					if ($runningProcesses = Get-NxtRunningProcesses -ProcessObjects $processObjects -DisableLogging -ProcessIdsToIgnore $processIdsToIgnore) {
						# Apps are still running, give them 2s to close. If they are still running, the Welcome Window will be displayed again
						Write-Log -Message 'Sleeping for 2 seconds because the processes are still not closed...' -Source ${CmdletName}
						Start-Sleep -Seconds 2
					}
				}
				#  Stop the script (if not actioned before the timeout value)
				elseif ($true -eq ($promptResult.Contains('Timeout'))) {
					Write-Log -Message 'Installation not actioned before the timeout value.' -Source ${CmdletName}
					$BlockExecution = $false

					if (($deferTimes -ge 0) -or ($deferDeadlineUniversal)) {
						Set-DeferHistory -DeferTimesRemaining $DeferTimes -DeferDeadline $deferDeadlineUniversal
					}
					## Dispose the welcome prompt timer here because if we dispose it within the Show-WelcomePrompt function we risk resetting the timer and missing the specified timeout period
					if ($null -ne $script:welcomeTimer) {
						try {
							$script:welcomeTimer.Dispose()
							$script:welcomeTimer = $null
						}
						catch {
						}
					}
					#  Restore minimized windows
					$shellApp.UndoMinimizeAll() | Out-Null
					Write-Output $configInstallationUIExitCode
					return
				}
				#  Stop the script (user chose to defer)
				elseif ($true -eq ($promptResult.Contains('Defer'))) {
					Write-Log -Message 'Installation deferred by the user.' -Source ${CmdletName}
					$BlockExecution = $false

					Set-DeferHistory -DeferTimesRemaining $DeferTimes -DeferDeadline $deferDeadlineUniversal

					#  Restore minimized windows
					$shellApp.UndoMinimizeAll() | Out-Null

					Write-Output $configInstallationDeferExitCode
					return
				}
			}
		}

		## Force the processes to close silently, without prompting the user
		if ( (($true -eq $Silent) -or ($true -eq $deployModeSilent)) -and ($processObjects.Count -ne 0) ) {
			[Array]$runningProcesses = $null
			[Array]$runningProcesses = Get-NxtRunningProcesses $processObjects
			if ($runningProcesses.Count -ne 0) {
				[String]$runningProcessDescriptions = ($runningProcesses | Where-Object {
					$false -eq [string]::IsNullOrEmpty($_.ProcessDescription)
				} | Select-Object -ExpandProperty 'ProcessDescription') -join ','
				Write-Log -Message "Force closing application(s) [$($runningProcessDescriptions)] without prompting user." -Source ${CmdletName}
				$runningProcesses.ProcessName | ForEach-Object -Process {
					Stop-NxtProcess -Name $_
				}
				Start-Sleep -Seconds 2
			}
		}

		## Force nsd.exe to stop if Notes is one of the required applications to close
		if (($processObjects | Select-Object -ExpandProperty 'ProcessName') -contains 'notes') {
			## Get the path where Notes is installed
			[String]$notesPath = Get-Item -LiteralPath $regKeyLotusNotes -ErrorAction 'SilentlyContinue' | Get-ItemProperty | Select-Object -ExpandProperty 'Path'

			## Ensure we aren't running as a Local System Account and Notes install directory was found
			if (($false -eq $IsLocalSystemAccount) -and ($notesPath)) {
				#  Get a list of all the executables in the Notes folder
				[string[]]$notesPathExes = Get-ChildItem -LiteralPath $notesPath -Filter '*.exe' -Recurse | Select-Object -ExpandProperty 'BaseName' | Sort-Object
				## Check for running Notes executables and run NSD if any are found
				$notesPathExes | ForEach-Object {
					if ((Get-Process | Select-Object -ExpandProperty 'Name') -contains $_) {
						[String]$notesNSDExecutable = Join-Path -Path $notesPath -ChildPath 'NSD.exe'
						try {
							if ($true -eq (Test-Path -LiteralPath $notesNSDExecutable -PathType 'Leaf' -ErrorAction 'Stop')) {
								Write-Log -Message "Executing [$notesNSDExecutable] with the -kill argument..." -Source ${CmdletName}
								[Diagnostics.Process]$notesNSDProcess = Start-Process -FilePath $notesNSDExecutable -ArgumentList '-kill' -WindowStyle 'Hidden' -PassThru -ErrorAction 'SilentlyContinue'

								if ($false -eq $notesNSDProcess.WaitForExit(10000)) {
									Write-Log -Message "[$notesNSDExecutable] did not end in a timely manner. Force terminate process." -Source ${CmdletName}
									Stop-NxtProcess -Name 'NSD' -Force -ErrorAction 'SilentlyContinue'
								}
							}
						}
						catch {
							Write-Log -Message "Failed to launch [$notesNSDExecutable]. `r`n$(Resolve-Error)" -Source ${CmdletName}
						}

						Write-Log -Message "[$notesNSDExecutable] returned exit code [$($notesNSDProcess.ExitCode)]." -Source ${CmdletName}

						#  Force NSD process to stop in case the previous command was not successful
						Stop-NxtProcess -Name 'NSD'
					}
				}
			}

			#  Strip all Notes processes from the process list except notes.exe, because the other notes processes (e.g. notes2.exe) may be invoked by the Notes installation, so we don't want to block their execution.
			if ($notesPathExes.Count -ne 0) {
				[Array]$processesIgnoringNotesExceptions = Compare-Object -ReferenceObject ($processObjects | Select-Object -ExpandProperty 'ProcessName' | Sort-Object) -DifferenceObject $notesPathExes -IncludeEqual | Where-Object {
					($_.SideIndicator -eq '<=') -or ($_.InputObject -eq 'notes')
				} | Select-Object -ExpandProperty 'InputObject'
				[Array]$processObjects = $processObjects | Where-Object {
					$processesIgnoringNotesExceptions -contains $_.ProcessName
				}
			}
		}

		## If block execution switch is true, call the function to block execution of these processes
		if ($true -eq $BlockExecution) {
			#  Make this variable globally available so we can check whether we need to call Unblock-NxtAppExecution
			Set-Variable -Name 'BlockExecution' -Value $BlockExecution -Scope 'Script'
			Write-Log -Message '[-BlockExecution] parameter specified.' -Source ${CmdletName}
			[Array]$blockableProcesses = ($processObjects | Where-Object {
				$true -ne $_.IsWql
			})
			if ($blockableProcesses.count -gt 0) {
				Write-Log -Message "Blocking execution of the following processes: $($blockableProcesses.ProcessName)" -Source ${CmdletName}
				Block-NxtAppExecution -ProcessName $blockableProcesses.ProcessName -BlockScriptLocation $BlockScriptLocation
				if ($true -eq (Test-Path -Path "$BlockScriptLocation\BlockExecution\$(Split-Path "$AppDeployConfigFile" -Leaf)")) {
					## In case of showing a message for a blocked application by ADT there has to be a valid application icon in copied temporary ADT framework
					Copy-File -Path "$ScriptRoot\$($xmlConfigFile.GetElementsByTagName('BannerIcon_Options').Icon_Filename)" -Destination "$BlockScriptLocation\BlockExecution\AppDeployToolkitLogo.ico"
					Update-NxtXmlNode -FilePath "$BlockScriptLocation\BlockExecution\$(Split-Path "$AppDeployConfigFile" -Leaf)" -NodePath "/AppDeployToolkit_Config/BannerIcon_Options/Icon_Filename" -InnerText "AppDeployToolkitLogo.ico" -Encoding UTF8withBom
				}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Show-NxtWelcomePrompt
function Show-NxtWelcomePrompt {
	<#
	.SYNOPSIS
		Called by Show-InstallationWelcome to prompt the user to optionally do the following:
			1) Close the specified running applications.
			2) Provide an option to defer the installation.
			3) Show a countdown before applications are automatically closed.
		This function is based on the PSAppDeployToolkit Show-InstallationWelcome function from the PSAppDeployToolkit licensed under the LGPLv3 license.
	.DESCRIPTION
		Show-NxtWelcomePrompt presents a dialog for managing application installations. Features include closing specified applications, deferring installation, and handling installation timeouts. Customization options for the prompt appearance and behavior are available.
	.PARAMETER ProcessObjects
		Custom objects containing process find conditions and descriptions. This parameter is mandatory.
	.PARAMETER ProcessDescriptions
		Descriptive names of applications that need to be closed for installation. This parameter is mandatory.
	.PARAMETER CloseAppsCountdown
		Time in seconds before automatically closing applications or defer the installation.
	.PARAMETER PersistPrompt
		Keeps the prompt persistent on the screen, reappearing every few seconds as specified in the AppDeployToolkitConfig.xml. Default: $false.
	.PARAMETER AllowDefer
		Enables the option for users to defer installation. Default: $false.
	.PARAMETER DeferTimes
		Specifies how many times a user can defer the installation.
	.PARAMETER DeferDeadline
		Sets a deadline date for deferring the installation.
	.PARAMETER MinimizeWindows
		Minimizes other windows when displaying the prompt. Default: $true.
	.PARAMETER TopMost
		Keeps the prompt window as the topmost window. Default: $true.
	.PARAMETER CustomText
		Displays a custom message from the XML file for different languages. Default: $false.
	.PARAMETER ContinueType
		Determines the action after timeout: Continue or Abort. Default: Abort.
	.PARAMETER UserCanCloseAll
		Allows users to close all applications through the prompt. Default: $false.
	.PARAMETER UserCanAbort
		Allows users to abort the installation process. Default: $false.
	.PARAMETER DeploymentType
		Specifies the type of deployment, defaulting to the Deploy-Application.ps1 script's parameter.
	.PARAMETER InstallTitle
		Title of the installation, defaulting to the Deploy-Application.ps1 script's parameter.
	.PARAMETER AppDeployLogoBanner
		Logo banner for the prompt, defaulting to the Deploy-Application.ps1 script's parameter.
	.PARAMETER AppDeployLogoBannerDark
		Dark theme logo banner for the prompt, defaulting to the Deploy-Application.ps1 script's parameter.
	.PARAMETER EnvProgramData
		Path to the ProgramData folder, defaulting to the Deploy-Application.ps1 script's parameter.
	.PARAMETER AppVendor
		Vendor of the application, defaulting to the Deploy-Application.ps1 script's parameter.
	.PARAMETER AppName
		Name of the application, defaulting to the Deploy-Application.ps1 script's parameter.
	.PARAMETER AppVersion
		Version of the application, defaulting to the Deploy-Application.ps1 script's parameter.
	.PARAMETER Logname
		Name of the log file, defaulting to the Deploy-Application.ps1 script's parameter.
	.PARAMETER ProcessIdToIgnore
		Process ID to ignore, defaulting to the current process ID $PID.
	.PARAMETER ExecutionPolicy
		Execution policy for the script, defaulting to the value in the AppDeployToolkitConfig.xml.
	.EXAMPLE
		Show-NxtWelcomePrompt -ProcessDescriptions "Notepad, Calculator" -CloseAppsCountdown 300 -AllowDefer $true
		This example shows a prompt to close Notepad and Calculator, with a 5-minute countdown and the option to defer.
	.EXAMPLE
		Show-NxtWelcomePrompt -ProcessDescriptions "Word, Excel" -CustomText $true -TopMost $true
		Demonstrates a prompt with custom text, set to remain as the topmost window, targeting Word and Excel.
	.OUTPUTS
		System.String
		Returns the user's selection.
	.NOTES
		This function should not be called directly in most cases. It is designed for internal script use, adapting from the PSAppDeployToolkit.
		The code of this function is mainly adopted from the PSAppDeployToolkit Show-InstallationWelcome function licensed under the LGPLv3 license.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[PSCustomObject[]]
		$ProcessObjects,
		[Parameter(Mandatory = $true)]
		[String]
		$ProcessDescriptions,
		[Parameter(Mandatory = $false)]
		[Int32]
		$CloseAppsCountdown,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[bool]
		$PersistPrompt = $false,
		[Parameter(Mandatory = $false)]
		[Switch]
		$AllowDefer = $false,
		[Parameter(Mandatory = $false)]
		[String]
		$DeferTimes,
		[Parameter(Mandatory = $false)]
		[String]
		$DeferDeadline,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[bool]
		$MinimizeWindows = $true,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[bool]
		$TopMost = $true,
		[Parameter(Mandatory = $false)]
		[Switch]
		$CustomText = $false,
		[Parameter(Mandatory = $false)]
		[PSADTNXT.ContinueType]
		$ContinueType = [PSADTNXT.ContinueType]::Abort,
		[Parameter(Mandatory = $false)]
		[Switch]
		$ApplyContinueTypeOnError = $false,
		[Parameter(Mandatory = $false)]
		[Switch]
		$UserCanCloseAll = $false,
		[Parameter(Mandatory = $false)]
		[Switch]
		$UserCanAbort = $false,
		[Parameter(Mandatory = $false)]
		[string]
		$DeploymentType = $DeploymentType,
		[Parameter(Mandatory = $false)]
		[string]
		$InstallTitle = $installTitle,
		[Parameter(Mandatory = $false)]
		[string]
		$AppDeployLogoBanner = $appDeployLogoBanner,
		[Parameter(Mandatory = $false)]
		[string]
		$AppDeployLogoBannerDark = $appDeployLogoBannerDark,
		[Parameter(Mandatory = $false)]
		[string]
		$EnvProgramData = $envProgramData,
		[Parameter(Mandatory = $false)]
		[string]
		$AppVendor = $appVendor,
		[Parameter(Mandatory = $false)]
		[string]
		$AppName = $appName,
		[Parameter(Mandatory = $false)]
		[string]
		$AppVersion = $appVersion,
		[Parameter(Mandatory = $false)]
		[string]
		$Logname = $logName,
		[Parameter(Mandatory = $false)]
		[int]
		$ProcessIdToIgnore,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]
		$ExecutionPolicy = $xmlConfigFile.AppDeployToolkit_Config.NxtPowerShell_Options.NxtPowerShell_ExecutionPolicy
	)

	Begin {
		## Get the name of this function and write header
		[String]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		[int]$contiuneTypeValue = $ContinueType
		# Convert to JSON in compressed form
		[string]$processObjectsEncoded = ConvertTo-NxtEncodedObject -Object $ProcessObjects
		[string]$toolkitUiPath = "$scriptRoot\CustomAppDeployToolkitUi.ps1"
		[string]$powershellCommand = "-ExecutionPolicy $ExecutionPolicy -NonInteractive -File `"$toolkitUiPath`" -ProcessDescriptions `"$ProcessDescriptions`" -ProcessObjectsEncoded `"$processObjectsEncoded`""
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "DeferTimes" -Value $DeferTimes
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "DeferDeadline" -Value $DeferDeadline
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "ContinueType" -Value $contiuneTypeValue
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "CloseAppsCountdown" -Value $CloseAppsCountdown
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "PersistPrompt" -Switch $PersistPrompt
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "AllowDefer" -Switch $AllowDefer
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "MinimizeWindows" -Switch $MinimizeWindows
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "TopMost" -Switch $TopMost
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "CustomText" -Switch $CustomText
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "UserCanCloseAll" -Switch $UserCanCloseAll
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "UserCanAbort" -Switch $UserCanAbort
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "DeploymentType" -Value $DeploymentType
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "InstallTitle" -Value $InstallTitle
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "AppDeployLogoBanner" -Value $AppDeployLogoBanner
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "AppDeployLogoBannerDark" -Value $AppDeployLogoBannerDark
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "EnvProgramData" -Value $envProgramData
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "AppVendor" -Value $appVendor
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "AppName" -Value $appName
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "AppVersion" -Value $appVersion
		$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "Logname" -Value $logName
		if ($ProcessIdToIgnore -gt 0) {
			$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "ProcessIdToIgnore" -Value $ProcessIdToIgnore
		}
		Write-Log "Searching for Sessions..." -Source ${CmdletName}
		[int]$welcomeExitCode = 1618
		[PsObject]$activeSessions = Get-LoggedOnUser
		if ((Get-Process -Id $PID).SessionId -eq 0) {
			if ($activeSessions.Count -gt 0) {
				try {
					[UInt32[]]$sessionIds = $activeSessions | Select-Object -ExpandProperty SessionId
					Write-Log "Start AskKillProcessesUI for sessions $sessionIds"
					[PSADTNXT.NxtAskKillProcessesResult]$askKillProcessesResult = [PSADTNXT.SessionHelper]::StartProcessAndWaitForExitCode($powershellCommand, $sessionIds)
					[int]$welcomeExitCode = $askKillProcessesResult.ExitCode
					[string]$logDomainName = $activeSessions | Where-Object sessionid -eq $askKillProcessesResult.SessionId | Select-Object -ExpandProperty DomainName
					[string]$logUserName = $activeSessions | Where-Object sessionid -eq $askKillProcessesResult.SessionId | Select-Object -ExpandProperty UserName
					Write-Log "ExitCode from CustomAppDeployToolkitUi.ps1:: $welcomeExitCode, User: $logDomainName\$logUserName"
				}
				catch {
					if ($true -eq $ApplyContinueTypeOnError) {
						Write-Log -Message "Failed to start CustomAppDeployToolkitUi.ps1. Applying ContinueType $contiuneTypeValue" -Severity 3 -Source ${CmdletName}
						if ($contiuneTypeValue -eq [PSADTNXT.ContinueType]::Abort) {
							[int]$welcomeExitCode = 1002
						}
						elseif ($contiuneTypeValue -eq [PSADTNXT.ContinueType]::Continue) {
							[int]$welcomeExitCode = 1001
						}
					}
					else {
						Write-Log -Message "Failed to start CustomAppDeployToolkitUi.ps1. Not Applying ContinueType $contiuneTypeValue `r`n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
						throw $_
					}
				}
			}
		}
		else {
			[int]$welcomeExitCode = [PSADTNXT.Extensions]::StartPowershellScriptAndWaitForExitCode($powershellCommand)
			Write-Log "ExitCode from CustomAppDeployToolkitUi.ps1:: $welcomeExitCode, User: $env:USERNAME\$env:USERDOMAIN"
		}

		[string]$returnCode = [string]::Empty

		switch ($welcomeExitCode) {
			1001
			{
				$returnCode = 'Close'
			}
			1002
			{
				$returnCode = 'Cancel'
			}
			1003
			{
				$returnCode = 'Defer'
			}
			1004
			{
				$returnCode = 'Timeout'
			}
			1005
			{
				$returnCode = 'Continue'
			}
			default
			{
				Write-Log "CustomAppDeployToolkitUi.ps1 returned an unknown exit code: $welcomeExitCode. Defaulting to 'Continue'..." -Severity 3 -Source ${CmdletName}
				$returnCode = 'Continue'
			}
		}
		Write-Output -InputObject ($returnCode)
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
		Stops a specified process using either its name or a WQL query.
	.DESCRIPTION
		The Stop-NxtProcess function is a wrapper for the Stop-Process cmdlet, allowing users to terminate processes by name. It supports WQL query syntax for advanced process selection. The function requires the process name to be specified and optionally accepts a WQL Filter against the Win32_Process class.
	.PARAMETER Name
		The name of the process to stop. This parameter is mandatory. It is interpreted as a WQL query if the IsWql parameter is set to $true.
	.PARAMETER IsWql
		Indicates if the 'Name' parameter should be interpreted as a WQL query. Default is $false.
	.PARAMETER Id
		The process ID to stop. This parameter is an alternative to the 'Name' parameter and cannot be used with IsWql
	.EXAMPLE
		Stop-NxtProcess -Name "Notepad"
		This example stops all instances of Notepad.
	.EXAMPLE
		Stop-NxtProcess -Name "name like '%chrome%'" -IsWql $true
		This example uses a WQL query to stop all processes with 'chrome' in their name.
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding(DefaultParameterSetName = 'Name')]
	Param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
		[ValidateNotNullOrEmpty()]
		[string]
		$Name,
		[Parameter(Mandatory = $false, ParameterSetName = 'Name')]
		[bool]
		$IsWql,
		[Parameter(Mandatory = $true, ParameterSetName = 'Id')]
		[Alias('ProcessId')]
		[int]
		$Id
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ($PSCmdlet.ParameterSetName -eq 'Id') {
			[string]$processQuery = "ProcessId = `"$Id`""
		}
		elseif ($PSCmdlet.ParameterSetName -eq 'Name' -and $false -eq $IsWql) {
			[string]$processQuery = "Name = `"$(${Name} -replace "\.exe$", [string]::Empty).exe`""
		}
		else {
			[string]$processQuery = "$Name"
		}

		Write-Log -Message "Stopping process that match query [$processQuery]" -Source ${cmdletName}
		try {
			[ciminstance[]]$processes = Get-CimInstance -Class Win32_Process -Filter $processQuery -ErrorAction Stop
		}
		catch {
			Write-Log -Message "Failed to retrieve process(es) with query [$processQuery]. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
			return
		}
		if ($processes.Count -gt 0) {
			Write-Log -Message "Found [$($processes.Count)] process(es) matching query [$processQuery]." -Source ${cmdletName}
		}
		else {
			Write-Log -Message "No process(es) found matching query [$processQuery]." -Source ${cmdletName}
			return
		}
		$processes | ForEach-Object {
			[ciminstance]$process = $_
			try {
				Invoke-CimMethod -InputObject $process -MethodName 'Terminate' -ErrorAction Stop | Out-Null
			}
			catch {
				# Not found is not an error in this case as the process might have been stopped by another process
				if ($_.Exception -is [Microsoft.Management.Infrastructure.CimException] -and $_.Exception.NativeErrorCode -eq "NotFound") {
					return
				}
				else {
					Write-Log -Message "Failed to stop process with ID [$($process.ProcessId)]. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
				}
			}
		}
		if ($null -ne (Get-Process -Id $processes.ProcessId -ErrorAction SilentlyContinue | Where-Object {
					$false -eq $_.HasExited
				})
		) {
			Write-Log -Message "Found running process(es) after sending stop signal."
		}
		else {
			Write-Log -Message "[$($processes.Count)] process(es) were successfully stopped." -Source ${cmdletName}
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
		Switches the ReinstallMode of an MSI setup based on a comparison of the exact DisplayVersion of the target application.
	.DESCRIPTION
		This function adjusts the ReinstallMode for an MSI package based on the comparison of the DisplayVersion if the application is already installed. It is designed specifically for MSI installers and uses various parameters to identify the uninstall registry key, display names to exclude, and the expected display version.
	.PARAMETER UninstallKey
		The uninstall registry key name of the application. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyIsDisplayName
		Indicates if the UninstallKey should be interpreted as a display name. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyContainsWildCards
		Determines if UninstallKey includes wildcards. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER DisplayNamesToExclude
		List of display names to exclude from the search. Defaults to the "DisplayNamesToExcludeFromAppSearches" value from the PackageConfig object.
	.PARAMETER DisplayVersion
		The expected version of the installed MSI application. Defaults to the 'DisplayVersion' from the PackageConfig object.
	.PARAMETER UninstallMethod
		Method used to uninstall the application. Used to filter the correct application form the registry. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER ReinstallMode
		Defines how a reinstallation should be performed. Defaults to the corresponding value from the PackageConfig object. Especially for msi setups this might be switched after display version check inside of this function
	.PARAMETER MSIInplaceUpgradeable
		Defines if the MSI setup allows in-place upgrades. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER MSIDowngradeable
		Indicates if the MSI setup allows downgrades. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER DeploymentType
		The type of deployment being performed. Defaults to the corresponding call parameter of the Deploy-Application.ps1 script.
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
		$UninstallMethod = $global:PackageConfig.UninstallMethod,
		[Parameter(Mandatory = $false)]
		[string]
		$ReinstallMode = $global:PackageConfig.ReinstallMode,
		[Parameter(Mandatory = $false)]
		[bool]
		$MSIInplaceUpgradeable = $global:PackageConfig.MSIInplaceUpgradeable,
		[Parameter(Mandatory = $false)]
		[bool]
		$MSIDowngradeable = $global:PackageConfig.MSIDowngradeable,
		[Parameter(Mandatory = $false)]
		[string]
		$DeploymentType = $DeploymentType
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ("MSI" -eq $UninstallMethod) {
			if ($true -eq ([string]::IsNullOrEmpty($DisplayVersion))) {
				Write-Log -Message "No 'DisplayVersion' provided. Processing msi setup without double check ReinstallMode for an expected msi display version!. Returning [$ReinstallMode]." -Severity 2 -Source ${cmdletName}
			}
			else {
				[PSADTNXT.NxtDisplayVersionResult]$displayVersionResult = Get-NxtCurrentDisplayVersion -UninstallKey $UninstallKey -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -InstallMethod $UninstallMethod
				if ($false -eq $displayVersionResult.UninstallKeyExists) {
					Write-Log -Message "No installed application was found and no 'DisplayVersion' was detectable!" -Source ${cmdletName}
					throw "No repair function executable under current conditions!"
				}
				elseif ($true -eq [string]::IsNullOrEmpty($displayVersionResult.DisplayVersion)) {
					### Note: By default an empty value 'DisplayVersion' for an installed msi setup may not be possible unless it was manipulated manually.
					Write-Log -Message "Detected 'DisplayVersion' is empty. Wrong installation results may be possible." -Severity 2 -Source ${cmdletName}
					Write-Log -Message "Exact check for an installed msi application not possible! But found application matching UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Returning [$ReinstallMode]." -Source ${cmdletName}
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
								if ($true -eq $MSIInplaceUpgradeable) {
									[string]$infoMessage += " Doing an msi inplace upgrade ..."
									$ReinstallMode = "Install"
								}
								else {
									$ReinstallMode = "Reinstall"
								}
							}
							Write-Log -Message "$infoMessage Returning [$ReinstallMode]." -Severity 2 -Source ${cmdletName}
						}
						"Downgrade" {
							[string]$infoMessage = "Found a higher target display version than expected."
							## check just for sure
							if ($DeploymentType -eq "Install") {
								## in this case the defined reinstall mode set by PackageConfig.json has to change
								if ($true -eq $MSIDowngradeable) {
									[string]$infoMessage += " Doing a msi downgrade ..."
									$ReinstallMode = "Install"
								}
								else {
									$ReinstallMode = "Reinstall"
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
		Checks whether a specific application is installed on the system.
	.DESCRIPTION
		This function searches the system registry Uninstall Key to determine if a given application is installed. It provides various parameters to specify the search criteria, including the name of the uninstall registry key, whether the key should be interpreted as a display name, and if wildcards are used in the key. It also allows excluding certain display names from the search.
	.PARAMETER UninstallKey
		Specifies the uninstall registry key name of the application to check. This parameter is mandatory. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyIsDisplayName
		Indicates whether the UninstallKey should be treated as a display name. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallKeyContainsWildCards
		Specifies whether the UninstallKey includes wildcards. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER DisplayNamesToExclude
		Lists the display names to be excluded from the search. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER InstallMethod
		Defines the installer type any applied installer specific logic. Currently only applicable for MSI installers.
	.EXAMPLE
		Test-NxtAppIsInstalled -UninstallKey "This Application_is1"
		Checks if an application with the uninstall key "This Application_is1" is installed. The values not specified explicitly are taken from the PackageConfig.json.
	.EXAMPLE
		Test-NxtAppIsInstalled -UninstallKey "*paper*" -DisplayNamesToExclude @() -UninstallKeyContainsWildCards $true -UninstallKeyIsDisplayName $false -InstallMethod Setup
		Searches for any installed application with a display name containing s"paper" using wildcards.
	.OUTPUTS
		System.Boolean.
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
		$InstallMethod
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		Write-Log -Message "Checking if application is installed..." -Source ${CmdletName}
		[PSCustomObject[]]$installedAppResults = Get-NxtInstalledApplication -UninstallKey $UninstallKey -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -InstallMethod $InstallMethod
		if ($installedAppResults.Count -eq 0) {
			[bool]$approvedResult = $false
			Write-Log -Message "Found no application matching UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Returning [$approvedResult]." -Source ${CmdletName}
		}
		elseif ($installedAppResults.Count -gt 1) {
			if ("MSI" -eq $InstallMethod) {
				## This case maybe resolved with a foreach-loop in future.
				[bool]$approvedResult = $false
				Write-Log -Message "Found more than one application matching UninstallKey [$UninstallKey], UninstallKeyIsDisplayName [$UninstallKeyIsDisplayName], UninstallKeyContainsWildCards [$UninstallKeyContainsWildCards] and DisplayNamesToExclude [$($DisplayNamesToExclude -join "][")]. Returning [$approvedResult]." -Severity 3 -Source ${CmdletName}
				throw "Processing multiple found msi installations is not supported yet! Abort."
			}
			else {
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
#region Function Test-NxtConfigVersionCompatibility
function Test-NxtConfigVersionCompatibility {
	<#
	.SYNOPSIS
		Validates the compatibility of ConfigVersion between PackageConfig.json, Deploy-Application.ps1, and AppDeployToolkitExtensions.ps1.
	.DESCRIPTION
		This function compares the ConfigVersion in PackageConfig.json with the versions in Deploy-Application.ps1 and AppDeployToolkitExtensions.ps1. It ensures consistency across these configurations and throws an error if there is a version mismatch.
	.PARAMETER ConfigVersion
		The version number of the configuration file. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER DeployApplicationPath
		The file path to Deploy-Application.ps1. Defaults to $global:DeployApplicationPath.
	.PARAMETER AppDeployToolkitExtensionsPath
		The file path to AppDeployToolkitExtensions.ps1. Defaults to $global:AppDeployToolkitExtensionsPath.
	.EXAMPLE
		Test-NxtConfigVersionCompatibility
		Tests the version compatibility using the default ConfigVersion and file paths.
	.EXAMPLE
		Test-NxtConfigVersionCompatibility -ConfigVersion 2023.12.31.1 -DeployApplicationPath "C:\temp\packagepath\Deploy-Application.ps1" -AppDeployToolkitExtensionsPath "C:\temp\packagepath\AppDeployToolkitExtensions.ps1"
		Tests the version compatibility using specified ConfigVersion and custom file paths.
	.OUTPUTS
		None.
	.NOTES
		This is an internal function designed to ensure version consistency within deployment scripts.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]
		$ConfigVersion = $global:PackageConfig.ConfigVersion,
		[Parameter(Mandatory = $false)]
		[string]
		$DeployApplicationPath = $global:DeployApplicationPath,
		[Parameter(Mandatory = $false)]
		[string]
		$AppDeployToolkitExtensionsPath = $global:AppDeployToolkitExtensionsPath
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[string[]]$deployApplicationContent = Get-Content -Path $DeployApplicationPath
		[string]$deployApplicationConfigVersion = $deployApplicationContent | Select-String -Pattern "ConfigVersion: $ConfigVersion$"
		if ($true -eq ([string]::IsNullOrEmpty($deployApplicationConfigVersion))) {
			Write-Log -Message "ConfigVersion: $ConfigVersion not found in $DeployApplicationPath. Please use a Deploy-Application.ps1 that matches the ConfigVersion from Packageconfig" -Severity 3 -Source ${cmdletName}
			throw "ConfigVersion: $ConfigVersion not found in $DeployApplicationPath. Please use a Deploy-Application.ps1 that matches the ConfigVersion from Packageconfig"
		}
		[string[]]$appDeployToolkitExtensionsContent = Get-Content -Path $AppDeployToolkitExtensionsPath
		[string]$appDeployToolkitExtensionsConfigVersion = $appDeployToolkitExtensionsContent | Select-String -Pattern "ConfigVersion: $ConfigVersion`$"
		if ($true -eq ([string]::IsNullOrEmpty($appDeployToolkitExtensionsConfigVersion))) {
			Write-Log -Message "ConfigVersion: $ConfigVersion not found in $AppDeployToolkitExtensionsPath. Please use an AppDeployToolkit Folder that matches the ConfigVersion from Packageconfig" -Severity 3 -Source ${cmdletName}
			throw "ConfigVersion: $ConfigVersion not found in $AppDeployToolkitExtensionsPath. Please use an AppDeployToolkit Folder that matches the ConfigVersion from Packageconfig"
		}
		Write-Log -Message "ConfigVersion: $ConfigVersion" -Severity 1 -Source ${cmdletName}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Test-NxtLocalGroupExists
function Test-NxtLocalGroupExists {
	<#
	.SYNOPSIS
		Checks for the existence of a local group on a specified or default computer.
	.DESCRIPTION
		This function verifies if a specified local group exists on a computer. It requires the name of the group and can optionally target a specific computer; otherwise, it defaults to the local system.
	.PARAMETER GroupName
		The name of the local group to check. This parameter is mandatory.
	.PARAMETER ComputerName
		Specifies the name of the computer to check for the group. If not provided, it defaults to the name of the local computer.
	.EXAMPLE
		Test-NxtLocalGroupExists -GroupName "Administrators"
		Checks if the "Administrators" group exists on the local computer.
	.EXAMPLE
		Test-NxtLocalGroupExists -GroupName "Users" -ComputerName "Server01"
		Checks if the "Users" group exists on the computer named "Server01".
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
	.SYNOPSIS
		Checks for the existence of a local user on a specified or default computer.
	.DESCRIPTION
		This function determines if a specified local user exists on a computer. It requires the name of the user and can optionally target a specific computer; otherwise, it defaults to the local system.
	.PARAMETER UserName
		The name of the local user to check. This parameter is mandatory.
	.PARAMETER ComputerName
		Specifies the name of the computer to check for the user. If not provided, it defaults to the name of the local computer.
	.EXAMPLE
		Test-NxtLocalUserExists -UserName "Administrator"
		Determines if the "Administrator" user exists on the local computer.
	.EXAMPLE
		Test-NxtLocalUserExists -UserName "JohnDoe" -ComputerName "Workstation01"
		Determines if the user "JohnDoe" exists on the computer named "Workstation01".
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
		Validates the configuration of a given object using specified rules.
	.DESCRIPTION
		This function checks a given object against predefined validation rules to ensure it meets certain criteria. The validation can be customized based on the provided rules and the nature of the object.
	.PARAMETER ValidationRule
		Specifies the validation rules to be applied. This parameter is mandatory.
	.PARAMETER ObjectToValidate
		The object to be validated. This parameter is mandatory.
	.PARAMETER ContainsDirectValues
		Indicates whether the object contains direct values. Default is $false.
	.PARAMETER ParentObjectName
		Specifies the name of the parent object for context in validation.
	.PARAMETER ContinueOnError
		Determines if the validation should continue after encountering an error.
	.EXAMPLE
		Check the neo42PackageConfig.json and its validationrules file as startingpoint.
		Test-NxtObjectValidation -ValidationRule $ValidationRule -ObjectToValidate $ObjectToValidate
	.EXAMPLE
		Test-NxtObjectValidation -ValidationRule $ValidationRule -ObjectToValidate $ObjectToValidate -ContinueOnError $true
	.OUTPUTS
		none.
	.NOTES
		Ensure that the validation rules are properly defined and relevant to the object being validated.
	.LINK
		private
	#>
	[CmdletBinding()]
	Param (
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
		Process {
			## ckeck for missing mandatory parameters
			foreach ($validationRuleKey in ($ValidationRule | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty name)) {
				if ($true -eq $ValidationRule.$validationRuleKey.Mandatory) {
					if ($false -eq ([bool]($ObjectToValidate.psobject.Properties.Name -contains $validationRuleKey))) {
						Write-Log -Message "The mandatory variable '$ParentObjectName $validationRuleKey' is missing." -severity 3
					}
					else {
						Write-Verbose "[${cmdletName}] The variable '$ParentObjectName $validationRuleKey' is present."
					}
				}
				## check for allowed object types and trigger the validation function for sub objects
				switch ($ValidationRule.$validationRuleKey.Type) {
					"System.Array" {
						if ($true -eq ([bool]($ValidationRule.$validationRuleKey.Type -match [Regex]::Escape($ObjectToValidate.$validationRuleKey.GetType().BaseType.FullName)))) {
							Write-Verbose "[${cmdletName}] The variable '$ParentObjectName $validationRuleKey' is of the allowed type $($ObjectToValidate.$validationRuleKey.GetType().BaseType.FullName)"
						}
						else {
							Write-Log -Message "The variable '$ParentObjectName $validationRuleKey' is not of the allowed type $($ValidationRule.$validationRuleKey.Type) in the package configuration object."-severity 3
							if ($false -eq $ContinueOnError) {
								throw "The variable '$ParentObjectName $validationRuleKey' is not of the allowed type $($ValidationRule.$validationRuleKey.Type) in the package configuration object. $($ValidationRule.$validationRuleKey.HelpText)"
							}
						}
						## check for sub objects
						foreach ($arrayItem in $ObjectToValidate.$validationRuleKey) {
							[hashtable]$testNxtObjectValidationParams = @{
								"ValidationRule" = $ValidationRule.$validationRuleKey.SubKeys
								"ObjectToValidate" = $arrayItem
								"ContinueOnError" = $ContinueOnError
								"ParentObjectName" = $validationRuleKey
							}
							if ($true -eq $ValidationRule.$validationRuleKey.ContainsDirectValues) {
								$testNxtObjectValidationParams["ContainsDirectValues"] = $true
							}
							Test-NxtObjectValidation @testNxtObjectValidationParams
						}
					}
					"System.Management.Automation.PSCustomObject" {
						if ($true -eq ([bool]($ValidationRule.$validationRuleKey.Type -match $ObjectToValidate.$validationRuleKey.GetType().FullName))) {
							Write-Verbose "[${cmdletName}] The variable '$ParentObjectName $validationRuleKey' is of the allowed type $($ObjectToValidate.$validationRuleKey.GetType().FullName)"
						}
						else {
							Write-Log -Message "The variable '$ParentObjectName $validationRuleKey' is not of the allowed type $($ValidationRule.$validationRuleKey.Type) in the package configuration object." -severity 3
							if ($false -eq $ContinueOnError) {
								throw "The variable '$ParentObjectName $validationRuleKey' is not of the allowed type $($ValidationRule.$validationRuleKey.Type) in the package configuration object. $($ValidationRule.$validationRuleKey.HelpText)"
							}
						}
						## check for sub objects
						foreach ($subkey in $ValidationRule.$validationRuleKey.SubKeys.PSObject.Properties.Name) {
							Test-NxtObjectValidation -ValidationRule $ValidationRule.$validationRuleKey.SubKeys.$subkey.SubKeys -ObjectToValidate $ObjectToValidate.$validationRuleKey.$subkey -ParentObjectName $validationRuleKey -ContinueOnError $ContinueOnError
						}
					}
					{
						$true -eq $ContainsDirectValues
					}{
						## cast the object to an array in case it is a single value
						foreach ($directValue in [array]$ObjectToValidate) {
							Test-NxtObjectValidationHelper -ValidationRule $ValidationRule.$ValidationRuleKey -ObjectToValidate $directValue -ValidationRuleKey $validationRuleKey -ParentObjectName $ParentObjectName -ContinueOnError $ContinueOnError
						}
					}
					Default {
						Test-NxtObjectValidationHelper -ValidationRule $ValidationRule.$ValidationRuleKey -ObjectToValidate $ObjectToValidate.$validationRuleKey -ValidationRuleKey $validationRuleKey -ParentObjectName $ParentObjectName -ContinueOnError $ContinueOnError
					}
				}
			}
		}
		End {

		}
}
#endregion
#region Function Test-NxtObjectValidationHelper
function Test-NxtObjectValidationHelper {
	<#
	.SYNOPSIS
		Assists in validating objects with specific rules, including regex and set validation.
	.DESCRIPTION
		This helper function is used in conjunction with Test-NxtObjectValidation to perform detailed validations on objects. It includes checks for regex patterns, validate sets, and allows handling empty values based on the defined rules.
	.PARAMETER ValidationRule
		The specific validation rule applied to the object. This parameter is mandatory.
	.PARAMETER ObjectToValidate
		The object that is being validated. This parameter is mandatory.
	.PARAMETER ValidationRuleKey
		The key associated with the validation rule, used for logging purposes.
	.PARAMETER ParentObjectName
		Name of the parent object, used for contextual logging.
	.PARAMETER ContinueOnError
		If set to true, the function continues executing even after encountering an error.
	.EXAMPLE
		Test-NxtObjectValidationHelper -ValidationRule $ValidationRule.$ValidationRuleKey -ObjectToValidate $ObjectToValidate.$validationRuleKey -ValidationRuleKey $validationRuleKey -ContinueOnError $ContinueOnError
	.OUTPUTS
		none.
	.NOTES
		Use this function as part of a larger validation process, particularly when detailed checks are required for specific object properties.
	.LINK
		private
	#>
	[CmdletBinding()]
	Param (
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
		if ($true -eq [bool]($ValidationRule.Type -match $ObjectToValidate.GetType().FullName)) {
			Write-Verbose "[${cmdletName}]The variable '$ParentObjectName $ValidationRuleKey' is of the allowed type $($ObjectToValidate.GetType().FullName)"
		}
		else {
			Write-Log -Message "The variable '$ParentObjectName $ValidationRuleKey' is not of the allowed type $($ValidationRule.Type) in the package configuration object." -severity 3
			if ($false -eq $ContinueOnError) {
				throw "The variable '$ParentObjectName $ValidationRuleKey' is not of the allowed type $($ValidationRule.Type) in the package configuration object. $($ValidationRule.HelpText)"
			}
		}
		if (
			$true -eq $ValidationRule.AllowEmpty -and
			[string]::IsNullOrEmpty($ObjectToValidate)
		) {
			Write-Verbose "[${cmdletName}]'$ParentObjectName $ValidationRuleKey' is allowed to be empty"
		}
		elseif ($true -eq ([string]::IsNullOrEmpty($ObjectToValidate)) ) {
			Write-Log -Message "The variable '$ParentObjectName $ValidationRuleKey' is not allowed to be empty in the package configuration object." -severity 3
			if ($false -eq $ContinueOnError) {
				throw "The variable '$ParentObjectName $ValidationRuleKey' is not allowed to be empty in the package configuration object. $($ValidationRule.HelpText)"
			}
		}
		else {
			## regex
			## CheckInvalidFileNameChars
			if ($true -eq $ValidationRule.Regex.CheckInvalidFileNameChars) {
				if ($ObjectToValidate.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0) {
					Write-Log -Message "The variable '$ParentObjectName $ValidationRuleKey' contains invalid characters in the package configuration object. $($ValidationRule.HelpText)" -severity 3
					if ($false -eq $ContinueOnError) {
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
			if ($ValidationRule.Regex.Operator -eq "match") {
				## validate regex pattern
				if ($true -eq ([bool]($ObjectToValidate -match $ValidationRule.Regex.Pattern))) {
					Write-Verbose "[${cmdletName}] The variable '$ParentObjectName $ValidationRuleKey' matches the regex $($ValidationRule.Regex.Pattern)"
				}
				else {
					Write-Log -Message "The variable '$ParentObjectName $ValidationRuleKey' does not match the regex $($ValidationRule.Regex.Pattern) in the package configuration object." -severity 3
					if ($false -eq $ContinueOnError) {
						throw "The variable '$ParentObjectName $ValidationRuleKey' does not match the regex $($ValidationRule.Regex.Pattern) in the package configuration object. $($ValidationRule.HelpText)"
					}
				}
			}
			## ValidateSet
			if ($false -eq [string]::IsNullOrEmpty($ValidationRule.ValidateSet)) {
				if ($true -eq ([bool]($ValidationRule.ValidateSet -contains $ObjectToValidate))) {
					Write-Verbose "[${cmdletName}] The variable '$ParentObjectName $ValidationRuleKey' is in the allowed set $($ValidationRule.ValidateSet)"
				}
				else {
					Write-Log -Message "The variable '$ParentObjectName $ValidationRuleKey' is not in the allowed set $($ValidationRule.ValidateSet) in the package configuration object." -severity 3
					if ($false -eq $ContinueOnError) {
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
		Validates the package configuration using custom validation rules.
	.DESCRIPTION
		This function validates a package configuration object based on specified rules. It should be called within the Main function and not be modified externally.
	.PARAMETER PackageConfig
		The package configuration object to be validated. Default is $global:PackageConfig.
	.PARAMETER ContinueOnError
		Specifies whether to continue execution upon encountering an error. Default is $false.
	.EXAMPLE
		Test-NxtPackageConfig
		Validates the package configuration using the default PackageConfig object.
	.EXAMPLE
		Test-NxtPackageConfig -PackageConfig $global:PackageConfig -ContinueOnError $true
		Validates the package configuration using the specified PackageConfig object and continues execution upon encountering an error.
	.OUTPUTS
		System.Boolean.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
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
		[PSCustomObject]$validationRules = Get-Content $ValidationRulePath -Raw | ConvertFrom-Json
	}
	Process {
		Test-NxtObjectValidation -ValidationRule $validationRules -Object $PackageConfig -ContinueOnError $ContinueOnError -ParentObjectName "PackageConfig"
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Test-NxtFolderPermissions
function Test-NxtFolderPermissions {
	<#
	.SYNOPSIS
		Checks and compares the actual permissions of a specified folder against expected permissions.
	.DESCRIPTION
		Test-NxtFolderPermissions evaluates a folder's security settings by comparing its actual permissions, owner, and other security attributes against predefined expectations. It's useful for ensuring folder permissions align with security policies or compliance standards.
	.PARAMETER Path
		Specifies the full path of the folder whose permissions are to be tested. This parameter is mandatory.
	.PARAMETER FullControlPermissions
		Defines the expected Full Control permissions to compare against the folder's actual Full Control permissions.
	.PARAMETER WritePermissions
		Specifies the expected Write permissions to compare with the folder's actual Write permissions.
	.PARAMETER ModifyPermissions
		Indicates the expected Modify permissions to compare with the folder's actual Modify permissions.
	.PARAMETER ReadAndExecutePermissions
		Specifies the expected Read and Execute permissions to compare with the folder's actual Read and Execute permissions.
	.PARAMETER Owner
		Defines the expected owner of the folder as a WellKnownSidType, compared with the folder's actual owner.
	.PARAMETER CustomDirectorySecurity
		Allows providing a custom DirectorySecurity object for advanced comparison. Modified if other parameters are specified.
	.PARAMETER CheckIsInherited
		Indicates if the IsInherited property should be checked.
	.PARAMETER IsInherited
		Specifies if the IsInherited property should be set to true or false.
	.EXAMPLE
		Test-NxtFolderPermissions -Path "C:\Temp\MyFolder" -FullControlPermissions @([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid) -ReadAndExecutePermissions @([System.Security.Principal.WellKnownSidType]::BuiltinUsersSid) -Owner $([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid)
		This example compares the permissions and owner of "C:\Temp\MyFolder" with specified parameters.
	.EXAMPLE
		Test-NxtFolderPermissions -Path "D:\Data" -ModifyPermissions @([System.Security.Principal.WellKnownSidType]::NetworkServiceSid) -Owner $([System.Security.Principal.WellKnownSidType]::LocalSystemSid)
		This example checks if "D:\Data" has the specified Modify permissions and owner.
	.OUTPUTS
		System.Boolean.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$FullControlPermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$WritePermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$ModifyPermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$ReadAndExecutePermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType]
		$Owner,
		[Parameter(Mandatory = $false)]
		[System.Security.AccessControl.DirectorySecurity]
		$CustomDirectorySecurity,
		[Parameter(Mandatory = $false)]
		[bool]
		$CheckIsInherited,
		[Parameter(Mandatory = $false)]
		[bool]
		$IsInherited
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ($null -ne $CustomDirectorySecurity) {
			[System.Security.AccessControl.DirectorySecurity]$directorySecurity = $CustomDirectorySecurity
		}
		else {
			[System.Security.AccessControl.DirectorySecurity]$directorySecurity = New-Object System.Security.AccessControl.DirectorySecurity
		}
		foreach ($permissionLevel in @("FullControl","Modify", "Write", "ReadAndExecute")) {
			foreach ($wellKnownSid in $(Get-Variable "$permissionLevel`Permissions" -ValueOnly)) {
				[System.Security.AccessControl.FileSystemAccessRule]$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
					(New-Object System.Security.Principal.SecurityIdentifier -ArgumentList ($wellKnownSid, $null)),
					"$permissionLevel",
					"ContainerInherit,ObjectInherit",
					"None",
					"Allow"
				)
				$directorySecurity.AddAccessRule($rule)
			}
		}
		if ($null -ne $Owner) {
			$directorySecurity.SetOwner((New-Object System.Security.Principal.SecurityIdentifier -ArgumentList ($Owner, $null)))
		}
		[System.Security.AccessControl.DirectorySecurity]$actualAcl = Get-Acl -Path $Path -ErrorAction Stop
		[string[]]$propertiesToCheck = @(
			"FileSystemRights",
			"AccessControlType",
			"IdentityReference",
			"InheritanceFlags",
			"PropagationFlags"
		)
		if ($true -eq $CheckIsInherited) {
			$propertiesToCheck += "IsInherited"
		}
		[PSCustomObject]$diffs = Compare-Object @($actualAcl.Access) $(
			if ($true -eq $IsInherited) {
				@($directorySecurity.Access) | Select-Object -Property FileSystemRights,AccessControlType,IdentityReference,InheritanceFlags,PropagationFlags,@{
					n="IsInherited"
					e={
						$true
					}
				}
			}
			else {
				@($directorySecurity.Access) | Select-Object -Property FileSystemRights,AccessControlType,IdentityReference,InheritanceFlags,PropagationFlags,@{
					n="IsInherited"
					e={
						$false
					}
				}
			}
			) -Property $propertiesToCheck
		[array]$results = @()
		foreach ($diff in $diffs) {
			$results += [PSCustomObject]@{
				'Rule'			= $diff | Select-Object -Property $propertiesToCheck
				'SideIndicator' = $diff.SideIndicator
				'Resulttype'	= 'Permission'
			}
		}
		if ($null -ne $directorySecurity.Owner) {
			[System.Security.Principal.SecurityIdentifier]$actualOwnerSid = (New-Object System.Security.Principal.NTAccount($actualAcl.Owner)).Translate([System.Security.Principal.SecurityIdentifier])
			[System.Security.Principal.SecurityIdentifier]$expectedOwnerSid = (New-Object System.Security.Principal.NTAccount($directorySecurity.Owner)).Translate([System.Security.Principal.SecurityIdentifier])
			if ($actualOwnerSid.Value -ne $expectedOwnerSid.Value) {
				Write-Log -Message "Expected owner to be $Owner but found $($actualAcl.Owner)." -Severity 2
				$results += [PSCustomObject]@{
					'Rule'			= "$($actualAcl.Owner)"
					'SideIndicator' = "<="
					'Resulttype'	= 'Owner'
				}
			}
		}
		if ($results.Count -eq 0) {
			Write-Output $true
		}
		else {
			foreach ($result in $results) {
				switch ($result.Resulttype) {
					'Permission' {
						if ($result.SideIndicator -eq "<=") {
							Write-Log -Message "Found unexpected permission $($result.Rule) on $Path." -Severity 2
						}
						elseif ($result.SideIndicator -eq "=>") {
							Write-Log -Message "Missing permission $($result.Rule) on $Path." -Severity 2
						}
						else {
							Write-Log -Message "Found unexpected permission $($result.Rule) on $Path." -Severity 2
						}
					}
					'Owner' {
						Write-Log -Message "Found unexpected owner $($result.Rule) instead of $Owner on $Path." -Severity 2
					}
				}
			}
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
	.SYNOPSIS
		Tests for the existence of a process by name or custom WQL query.
	.DESCRIPTION
		The Test-NxtProcessExists function checks if a specified process is currently running on the system. It can search for a process by its name or use a custom WQL query for more advanced searching.
	.PARAMETER ProcessName
		The name of the process to search for, or a WQL search string. This parameter is mandatory.
		Must include the full file name, including its extension.
		Supports the use of wildcard characters, such as * and %.
	.PARAMETER IsWql
		Indicates whether the ProcessName is a WQL search string.
		This parameter is not mandatory and defaults to $false.
	.EXAMPLE
		Test-NxtProcessExists "Notepad.exe"
		Checks if the process 'Notepad.exe' is currently running.
	.EXAMPLE
		Test-NxtProcessExists -ProcessName "Name LIKE '%chrome%'" -IsWql:$true
		Uses a WQL query to check if any process with 'chrome' in its name is running.
	.OUTPUTS
		System.Boolean.
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
			if ($true -eq $IsWql) {
				[string]$wqlString = $ProcessName
			}
			else {
				[string]$wqlString = "Name LIKE '$($ProcessName.Replace("*","%"))'"
			}
			[System.Management.ManagementBaseObject]$process = Get-WmiObject -Query "Select * from Win32_Process Where $($wqlString)" -ErrorAction Stop | Select-Object -First 1
			if ($null -ne $process) {
				Write-Output $true
			}
			else {
				Write-Output $false
			}
		}
		catch {
			Write-Log -Message "Failed to get processes for '$ProcessName'. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
			throw "Failed to get processes for '$ProcessName'. `n$(Resolve-Error)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Test-NxtSetupCfg
function Test-NxtSetupCfg {
	<#
	.SYNOPSIS
		Tests a Setup.cfg file if all parameters meet the metadata requirements.
	.DESCRIPTION
		This function analyzes the Setup.cfg and evaluates the parameter comment for metadata requirements and validates the parameter values.
	.PARAMETER Path
		The path to the Setup.cfg file. This parameter is mandatory.
	.EXAMPLE
		Test-NxtSetupCfg -Path C:\path\to\Setup.cfg
	.OUTPUTS
		System.Boolean.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[System.IO.FileInfo]
		$Path
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name

		function Get-MetaDataPropertyFromComment {
			Param(
				[Parameter(Mandatory = $true)]
				[string]
				$Comment,
				[Parameter(Mandatory = $true)]
				[string]
				$Property
			)
			Process {
				[regex]$propertyRegex = [regex]::new("$([Regex]::Escape(${Property}))\s*=[^\S\r\n]*(?<Value>.*)")
				[System.Text.RegularExpressions.Group]$matchedGroup = $propertyRegex.Match($Comment, [System.Text.RegularExpressions.RegexOptions]::Multiline).Groups | Where-Object {
					$_.Name -eq "Value"
				} | Select-Object -First 1
				if ($null -ne $matchedGroup) {
					Write-Output $matchedGroup.Value.Trim()
				}
			}
		}
	}
	Process {
		try {
			[hashtable]$ini = Import-NxtIniFileWithComments -Path $Path -ContinueOnError $false
		}
		catch {
			Write-Log "Failed to read setup.cfg file [$path]`n$(Resolve-Error)" -Source ${cmdletName} -Severity 3
			Write-Output $false
			return
		}
		if ($ini.Keys -notcontains "Options" -or $ini.Keys -notcontains "AskKillProcesses") {
			Write-Log "Setup.cfg file [$path] is missing required sections." -Source ${cmdletName} -Severity 3
			Write-Output $false
			return
		}
		foreach ($section in $ini.GetEnumerator()) {
			foreach ($parameter in $section.Value.GetEnumerator()) {
				if (
					$true -eq [string]::IsNullOrEmpty($parameter.Value.Value) -and
					$null -ne $xmlConfigFile.AppDeployToolkit_Config.SetupCfg_Parameters.$($section.Key).$($parameter.Key)
				) {
					Write-Log "Parameter [$($parameter.Key)] in section [$($section.Key)] has no value. Skipping validation due to default value present in XML." -Source ${cmdletName} -Severity 2
					continue
				}
				if ($true -eq [string]::IsNullOrEmpty($parameter.Value.Comments)) {
					Write-Log "Parameter [$($parameter.Key)] in section [$($section.Key)] has no validation metadata. Skipping validation." -Source ${cmdletName} -Severity 2
					continue
				}
				[string]$type = Get-MetaDataPropertyFromComment -Comment $parameter.Value.Comments -Property "Type"
				[string]$valuesString = Get-MetaDataPropertyFromComment -Comment $parameter.Value.Comments -Property "Values"
				[string[]]$values = @()
				if ($false -eq [string]::IsNullOrEmpty($valuesString)) {
					$values = $valuesString.Split(",").Trim() | Where-Object {
						$_ -ne [string]::Empty
					}
				}
				switch ($type) {
					"Int" {
						if ($false -eq [int]::TryParse($parameter.Value.Value, [ref]$null)) {
							Write-Log "Parameter [$($parameter.Key)] in section [$($section.Key)] has an invalid value [$($parameter.Value.Value)]. Expected type: [Integer]" -Source ${cmdletName} -Severity 3
							Write-Output $false
							return
						}
					}
				}
				if ($values.Count -gt 0) {
					if ($values -notcontains $parameter.Value.Value) {
						Write-Log "Parameter [$($parameter.Key)] in section [$($section.Key)] has an invalid value [$($parameter.Value.Value)]. Valid values are: $($values -join ", ")." -Source ${cmdletName} -Severity 3
						Write-Output $false
						return
					}
				}
			}
		}
		Write-Log -Message "Setup.cfg file [$path] is valid." -Source ${CmdletName}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Test-NxtStringInFile
function Test-NxtStringInFile {
	<#
	.SYNOPSIS
		Searches for a specified string or regex pattern within a file.
	.DESCRIPTION
		The Test-NxtStringInFile function searches for a specified string or regex pattern within a file and returns a Boolean result. It supports regular expression searches, case-insensitive searches, and can handle different file encodings.
	.PARAMETER Path
		The file path where the search is to be performed. This parameter is mandatory.
	.PARAMETER SearchString
		The string or regex pattern to search for in the file. This parameter is mandatory.
	.PARAMETER ContainsRegex
		Indicates whether the SearchString is a regular expression. Defaults to $false.
	.PARAMETER IgnoreCase
		Specifies if the search should be case insensitive. Defaults to $true.
	.PARAMETER Encoding
		Specifies the encoding of the file. Optional parameter.
	.PARAMETER DefaultEncoding
		Specifies the default encoding to use if the file's encoding cannot be auto-detected. Optional parameter.
	.EXAMPLE
		Test-NxtStringInFile -Path "C:\temp\test.txt" -SearchString "test"
		Searches for the string "test" in the file located at "C:\temp\test.txt".
	.EXAMPLE
		Test-NxtStringInFile -Path "C:\temp\test.txt" -ContainsRegex $true -SearchString "test.*"
		Uses a regular expression to search for any string starting with "test" in the file located at "C:\temp\test.txt".
	.OUTPUTS
		System.Boolean.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path,
		[Parameter(Mandatory = $true)]
		[string]
		$SearchString,
		[Parameter(Mandatory = $false)]
		[bool]
		$ContainsRegex = $false,
		[Parameter(Mandatory = $false)]
		[bool]
		$IgnoreCase = $true,
		[Parameter()]
		[ValidateSet("Ascii", "Default", "UTF7", "BigEndianUnicode", "Oem", "Unicode", "UTF32", "UTF8")]
		[String]
		$Encoding,
		[Parameter()]
		[ValidateSet("Ascii", "Default", "UTF7", "BigEndianUnicode", "Oem", "Unicode", "UTF32", "UTF8")]
		[String]
		$DefaultEncoding
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		#return false if the file does not exist
		if ($false -eq (Test-Path -Path $Path)) {
			Write-Log -Severity 3 -Message "File $Path does not exist" -Source ${cmdletName}
			throw "File $Path does not exist"
		}
		[string]$intEncoding = $Encoding
		if (($false -eq (Test-Path -Path $Path)) -and ($true -eq ([String]::IsNullOrEmpty($intEncoding)))) {
			[string]$intEncoding = "UTF8"
		}
		elseif (($true -eq (Test-Path -Path $Path)) -and ($true -eq ([String]::IsNullOrEmpty($intEncoding)))) {
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
		[hashtable]$contentParams = @{
			Path = $Path
		}
		if ($false -eq [string]::IsNullOrEmpty($intEncoding)) {
			[string]$contentParams['Encoding'] = $intEncoding
		}
		# Specifically cast into string to catch case where content is $null
		[string]$content = "$(Get-Content @contentParams -Raw)"
		[regex]$pattern = if ($true -eq $ContainsRegex) {
			[regex]::new($SearchString)
		}
		else {
			[regex]::new([regex]::Escape($SearchString))
		}
		if ($true -eq $IgnoreCase) {
			[System.Text.RegularExpressions.RegexOptions]$options = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
		}
		else {
			[System.Text.RegularExpressions.RegexOptions]$options = [System.Text.RegularExpressions.RegexOptions]::None
		}
		[array]$regexMatches = [regex]::Matches($content, $pattern, $options)
		if ($regexMatches.Count -gt 0) {
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
#region Function Test-NxtXmlNodeExists
function Test-NxtXmlNodeExists {
	<#
	.SYNOPSIS
		Checks for the existence of a specified XML node in an XML file.
	.DESCRIPTION
		The Test-NxtXmlNodeExists function verifies the existence of a node in an XML file. It supports filtering nodes based on specified attributes but does not handle XML namespaces. This function is useful for XML file manipulation and data verification in scripts.
	.PARAMETER FilePath
		The path to the XML file. This parameter is mandatory.
	.PARAMETER NodePath
		The XPath to the node that needs to be tested for existence. This parameter is mandatory.
	.PARAMETER FilterAttributes
		A hashtable of attributes to filter the node. Optional parameter.
	.PARAMETER Encoding
		The encoding of the XML file. Optional parameter.
	.PARAMETER DefaultEncoding
		The default encoding to use if the file's encoding cannot be auto-detected. Optional parameter.
	.EXAMPLE
		Test-NxtXmlNodeExists -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3"
		Tests for the existence of a node at the specified XPath in 'xmlstuff.xml'.
	.EXAMPLE
		Test-NxtXmlNodeExists -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -FilterAttributes @{name="NewNode2"}
		Tests for a node with a specific attribute value in 'xmlstuff.xml'.
	.EXAMPLE
		Test-NxtXmlNodeExists -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -FilterAttributes @{name="NewNode2"; "other=1232"}
		Tests for a node with multiple attribute filters in 'xmlstuff.xml'.
	.OUTPUTS
		System.Boolean.
		Returns $true if the node exists with the specified attributes, otherwise returns $false.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$FilePath,
		[Parameter(Mandatory = $true)]
		[string]
		$NodePath,
		[Parameter(Mandatory = $false)]
		[hashtable]
		$FilterAttributes,
		[Parameter(Mandatory = $false)]
		[ValidateSet("Ascii", "Default", "UTF7", "BigEndianUnicode", "Oem", "Unicode", "UTF32", "UTF8")]
		[string]
		$Encoding,
		[Parameter(Mandatory = $false)]
		[ValidateSet("Ascii", "Default", "UTF7", "BigEndianUnicode", "Oem", "Unicode", "UTF32", "UTF8")]
		[string]
		$DefaultEncoding
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		if ($false -eq (Test-Path -Path $FilePath)) {
			Write-Log -Message "File $FilePath does not exist" -Severity 3
			throw "File $FilePath does not exist"
		}
		[hashtable]$encodingParams = @{}
		if ($false -eq [string]::IsNullOrEmpty($Encoding)) {
			$encodingParams["Encoding"] = $Encoding
		}
		if ($false -eq [string]::IsNullOrEmpty($DefaultEncoding)) {
			$encodingParams["DefaultEncoding"] = $DefaultEncoding
		}
		[System.Xml.XmlDocument]$xml = Import-NxtXmlFile @encodingParams -Path $FilePath
		[System.Xml.XmlNodeList]$nodes = $xml.SelectNodes($nodePath)
		if ($false -eq [string]::IsNullOrEmpty($FilterAttributes)) {
			if ( @($nodes | Where-Object {
					[psobject]$filterNode = $_
						$false -notin ($FilterAttributes.GetEnumerator() | ForEach-Object {
								$filterNode.GetAttribute($_.Key) -eq $_.Value
							})
					}).Count -gt 0 ) {
				Write-Output $true
			}
			else {
				Write-Output $false
			}
		}
		else {
			if ($false -eq [string]::IsNullOrEmpty($nodes)) {
				Write-Output $true
			}
			else {
				Write-Output $false
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Unblock-NxtAppExecution
function Unblock-NxtAppExecution {
	<#
	.SYNOPSIS
		Unblocks the execution of applications performed by the Block-NxtAppExecution function
	.DESCRIPTION
		This function is called by the Exit-Script function or when the script itself is called with the parameters -CleanupBlockedApps
	.OUTPUTS
		none.
	.EXAMPLE
		Unblock-NxtAppExecution
	.PARAMETER BlockScriptLocation
		The location where the block script was placed.
		Defaults to $global:PackageConfig.App.
	.PARAMETER BlockExecution
		Indicates if the execution of applications has been blocked. This function will only unblock applications if this variable is set to $true.
		Defaults to $Script:BlockExecution.
	.PARAMETER RegKeyAppExecution
		The registry key used to block the execution of applications. Defaults to $regKeyAppExecution.
	.NOTES
		This is an internal script function and should typically not be called directly.
		It is used when the -BlockExecution parameter is specified with the Show-InstallationWelcome function to undo the actions performed by Block-NxtAppExecution.
	.LINK
		https://psappdeploytoolkit.com
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]
		$BlockScriptLocation = $global:PackageConfig.App,
		[Parameter(Mandatory = $false)]
		[bool]
		$BlockExecution = $Script:BlockExecution,
		[Parameter(Mandatory = $false)]
		[string]
		$RegKeyAppExecution = $regKeyAppExecution
	)
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		## Bypass if no admin rights
		if ($false -eq $configToolkitRequireAdmin) {
			Write-Log -Message "Bypassing function [${CmdletName}], because [RequireAdmin: $configToolkitRequireAdmin]." -Source ${CmdletName}
			return
		}
		if ($false -eq $BlockExecution) {
			Write-Log -Message "Bypassing function [${CmdletName}], because [BlockExecution: $BlockExecution]." -Source ${CmdletName}
			return
		}
		## Close the Block-NxtAppExecution message box
		Close-NxtBlockExecutionWindow
		## Remove Debugger values to unblock processes
		[PSObject[]]$unblockProcesses = $null
		$unblockProcesses += (
			Get-ChildItem -LiteralPath $RegKeyAppExecution -Recurse -ErrorAction 'SilentlyContinue' |
			ForEach-Object {
				Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction 'SilentlyContinue'
			}
		)
		foreach ($unblockProcess in ($unblockProcesses | Where-Object {
			$_.Debugger -match '.*AppDeployToolkit_BlockAppExecutionMessage.*|.*DeployNxtApplication.*'
		})) {
			Write-Log -Message "Removing the Image File Execution Options registry key to unblock execution of [$($unblockProcess.PSChildName)]." -Source ${CmdletName}
			$unblockProcess | Remove-ItemProperty -Name 'Debugger' -ErrorAction 'SilentlyContinue'
		}
		##  Make this variable globally available so we can check whether we need to call Unblock-NxtAppExecution
		Set-Variable -Name 'BlockExecution' -Value $false -Scope 'Script'
		## Remove the scheduled task if it exists
		[string]$schTaskBlockedAppsName = $installName + '_BlockedApps'
		try {
			Unregister-ScheduledTask -TaskPath '\' -TaskName $schTaskBlockedAppsName -Confirm:$false -ErrorAction Stop
		}
		catch {
			if ( $_.CategoryInfo.Category -eq "ObjectNotFound" ) {
				Write-Log -Message "Scheduled task [$schTaskBlockedAppsName] not found." -Source ${CmdletName}
			}
			else {
				Write-Log -Message "Error retrieving/deleting scheduled task.`r`n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			}
		}
		## Remove BlockAppExection temporary directory
		[string]$blockExecutionTempPath = Join-Path -Path $BlockScriptLocation -ChildPath 'BlockExecution'
		if ($true -eq (Test-Path -LiteralPath $blockExecutionTempPath -PathType 'Container')) {
			Remove-Folder -Path $blockExecutionTempPath | Out-Null
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Uninstall-NxtApplication
function Uninstall-NxtApplication {
	<#
	.SYNOPSIS
		Uninstalls an application based on the specified uninstallation parameters.
	.DESCRIPTION
		The Uninstall-NxtApplication function is designed to automate the uninstallation process of an application. It covers various uninstallation methods and handles complex scenarios, including the use of wildcards in uninstall keys, log file generation, and acceptance of specific exit codes.
	.PARAMETER AppName
		The name of the application to be uninstalled. Defaults to the AppName from the PackageConfig object.
	.PARAMETER UninstallKey
		The uninstallation key set by the installer. Defaults to the UninstallKey from the PackageConfig object.
	.PARAMETER UninstallKeyIsDisplayName
		Specifies if the UninstallKey should be treated as a display name. Defaults to the UninstallKeyIsDisplayName from the PackageConfig object.
	.PARAMETER UninstallKeyContainsWildCards
		Indicates if the UninstallKey contains wildcards. Defaults to the UninstallKeyContainsWildCards from the PackageConfig object.
	.PARAMETER DisplayNamesToExclude
		Specifies display names to exclude during uninstallation. Defaults to the DisplayNamesToExcludeFromAppSearches from the PackageConfig object.
	.PARAMETER UninstLogFile
		The path to the uninstallation log file. Defaults to the UninstLogFile from the PackageConfig object.
	.PARAMETER UninstFile
		The path to the uninstallation executable file. Defaults to the UninstFile from the PackageConfig object.
	.PARAMETER UninstPara
		The parameters for the uninstallation command line. Defaults to the UninstPara from the PackageConfig object.
	.PARAMETER AppendUninstParaToDefaultParameters
		Determines if UninstPara should be appended to the default parameters. Defaults to the AppendUninstParaToDefaultParameters from the PackageConfig object.
	.PARAMETER AcceptedUninstallExitCodes
		List of exit codes accepted as successful uninstallation. Defaults to the AcceptedUninstallExitCodes from the PackageConfig object.
	.PARAMETER AcceptedUninstallRebootCodes
		List of reboot codes accepted for a requested reboot. Defaults to the AcceptedUninstallRebootCodes from the PackageConfig object.
	.PARAMETER UninstallMethod
		The type of the uninstaller used. Defaults to the UninstallMethod from the PackageConfig object.
	.PARAMETER PreSuccessCheckTotalSecondsToWaitFor
		Timeout in seconds to wait for a successful condition to occur. Defaults to the PreSuccessCheckTotalSecondsToWaitFor from the PackageConfig object.
	.PARAMETER PreSuccessCheckProcessOperator
		Operator defining process condition requirements. Defaults to the PreSuccessCheckProcessOperator from the PackageConfig object.
	.PARAMETER PreSuccessCheckProcessesToWaitFor
		Array of process conditions to check. Defaults to the PreSuccessCheckProcessesToWaitFor from the PackageConfig object.
	.PARAMETER PreSuccessCheckRegKeyOperator
		Operator defining regkey condition requirements. Defaults to the PreSuccessCheckRegKeyOperator from the PackageConfig object.
	.PARAMETER PreSuccessCheckRegkeysToWaitFor
		Array of regkey conditions to check. Defaults to the PreSuccessCheckRegkeysToWaitFor from the PackageConfig object.
	.PARAMETER DirFiles
		The directory where the files are located. Defaults to $dirFiles.
	.PARAMETER UninsBackupPath
		The directory for backup files. Optional parameter.
	.EXAMPLE
		Uninstall-NxtApplication
		Executes the uninstallation process with the default parameters defined in the PackageConfig object.
	.OUTPUTS
		PSADTNXT.NxtApplicationResult.
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
		$AcceptedUninstallRebootCodes = $global:PackageConfig.AcceptedUninstallRebootCodes,
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
		$PreSuccessCheckRegkeysToWaitFor = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Uninstall.RegkeysToWaitFor,
		[Parameter(Mandatory = $false)]
		[string]
		$DirFiles = $dirFiles,
		[Parameter(Mandatory = $false)]
		[string]
		$UninsBackupPath = "$($global:packageConfig.App)\neo42-Source"
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[PSADTNXT.NxtApplicationResult]$uninstallResult = New-Object -TypeName PSADTNXT.NxtApplicationResult
		if ($UninstallMethod -eq "none") {
			$uninstallResult.ErrorMessage = "An uninstallation method was NOT set. Skipping a default process execution."
			$uninstallResult.Success = $null
			[int]$logMessageSeverity = 1
		}
		else {
			[int]$logMessageSeverity = 1
			if ($true -eq [string]::IsNullOrEmpty($UninstallKey)) {
				Write-Log -Message "UninstallKey value NOT set. Skipping test for installed application via registry. Checking for UninstFile instead..." -Source ${CmdletName}
				if ($true -eq [string]::IsNullOrEmpty($UninstFile)) {
					$uninstallResult.ErrorMessage = "Value 'UninstFile' NOT set. Uninstallation NOT executed."
					[int]$logMessageSeverity = 2
				}
				else {
					if ($false -eq [System.IO.Path]::IsPathRooted($UninstFile)) {
						$UninstFile = Join-Path -Path $DirFiles -ChildPath $UninstFile
					}
					if ($true -eq [System.IO.File]::Exists($UninstFile)) {
						Write-Log -Message "File for running an uninstallation found: '$UninstFile'. Executing the uninstallation..." -Source ${CmdletName}
					}
					else {
						$uninstallResult.MainExitCode = 70001
						## 2 for ERROR_FILE_NOT_FOUND
						$uninstallResult.ApplicationExitCode = 2
						$uninstallResult.ErrorMessage = "Expected file for running an uninstallation NOT found: '$UninstFile'. Uninstallation NOT executed. Possibly the expected application is not installed on system anymore!"
						$uninstallResult.ErrorMessagePSADT = "ERROR_FILE_NOT_FOUND: The system cannot find the file specified."
						$uninstallResult.Success = $false
						[int]$logMessageSeverity = 2
					}
				}
			}
			else {
				if ($true -eq $(Test-NxtAppIsInstalled -UninstallKey "$UninstallKey" -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -InstallMethod $UninstallMethod) ) {
					[bool]$appIsInstalled=$true
				}
				else {
					[bool]$appIsInstalled=$false
					$uninstallResult.ErrorMessage = "Uninstall function could not run for provided parameter 'UninstallKey=$UninstallKey'. The expected application seems not to be installed on system!"
					$uninstallResult.Success = $null
					[int]$logMessageSeverity = 1
				}
			}
			if ($true -eq ([System.IO.File]::Exists($UninstFile)) -or ($true -eq $appIsInstalled) ) {

				[hashtable]$executeNxtParams = @{
					Action							= 'Uninstall'
					UninstallKeyIsDisplayName		= $UninstallKeyIsDisplayName
					UninstallKeyContainsWildCards	= $UninstallKeyContainsWildCards
					DisplayNamesToExclude			= $DisplayNamesToExclude
				}
				if ($false -eq [string]::IsNullOrEmpty($UninstPara)) {
					if ($true -eq $AppendUninstParaToDefaultParameters) {
						[string]$executeNxtParams["AddParameters"] = "$UninstPara"
					}
					else {
						[string]$executeNxtParams["Parameters"] = "$UninstPara"
					}
				}
				if ($true -eq [string]::IsNullOrEmpty($UninstallKey)) {
					[string]$internalInstallerMethod = [string]::Empty
					Write-Log -Message "No 'UninstallKey' is set. Switch to use provided 'UninstFile' ..." -Severity 2 -Source ${cmdletName}
				}
				else {
					[string]$internalInstallerMethod = $UninstallMethod
				}
				if ($internalInstallerMethod -match "^Inno.*$|^Nullsoft$|^BitRock.*$|^MSI$") {
					if ($false -eq [string]::IsNullOrEmpty($AcceptedUninstallExitCodes)) {
						[string]$executeNxtParams["AcceptedExitCodes"] = "$AcceptedUninstallExitCodes"
					}
					if ($false -eq [string]::IsNullOrEmpty($AcceptedUninstallRebootCodes)) {
						[string]$executeNxtParams["AcceptedRebootCodes"] = "$AcceptedUninstallRebootCodes"
					}
				}
				switch -Wildcard ($internalInstallerMethod) {
					MSI {
						[PsObject]$executionResult = Execute-NxtMSI @executeNxtParams -Path "$UninstallKey" -Log "$UninstLogFile"
					}
					"Inno*" {
						[PsObject]$executionResult = Execute-NxtInnoSetup @executeNxtParams -UninstallKey "$UninstallKey" -Log "$UninstLogFile" -UninsBackupPath $UninsBackupPath
					}
					Nullsoft {
						[PsObject]$executionResult = Execute-NxtNullsoft @executeNxtParams -UninstallKey "$UninstallKey" -UninsBackupPath $UninsBackupPath
					}
					"BitRock*" {
						[PsObject]$executionResult = Execute-NxtBitRockInstaller @executeNxtParams -UninstallKey "$UninstallKey" -UninsBackupPath $UninsBackupPath
					}
					default {
						[hashtable]$executeParams = @{
							Path					= "$UninstFile"
							ExitOnProcessFailure	= $false
							PassThru				= $true
						}
						if ($false -eq [string]::IsNullOrEmpty($UninstPara)) {
							[string]$executeParams["Parameters"] = "$UninstPara"
						}
							[string]$ignoreExitCodes = Merge-NxtExitCodes -ExitCodeString1 $AcceptedUninstallExitCodes -ExitCodeString2 $AcceptedUninstallRebootCodes
						if ($false -eq [string]::IsNullOrEmpty($ignoreExitCodes)) {
							[string]$executeParams["IgnoreExitCodes"] = "$ignoreExitCodes"
						}
						[PsObject]$executionResult = Execute-Process @executeParams
						if ($($executionResult.ExitCode) -in ($AcceptedUninstallRebootCodes -split ",")) {
							Write-Log -Message "A custom reboot return code was detected '$($executionResult.ExitCode)' and is translated to return code '3010': Reboot required!" -Severity 2 -Source ${cmdletName}
							Set-Variable -Name 'msiRebootDetected' -Value $true -Scope 'Script'
						}
					}
				}
				$uninstallResult.ApplicationExitCode = $executionResult.ExitCode
				if ($($executionResult.ExitCode) -in ($AcceptedUninstallRebootCodes -split ",")) {
					$uninstallResult.MainExitCode = 3010
					$uninstallResult.ErrorMessage = "Uninstallation done with custom reboot return code '$($executionResult.ExitCode)'."
				}
				else {
					$uninstallResult.MainExitCode = $executionResult.ExitCode
					$uninstallResult.ErrorMessage = "Uninstallation done with return code '$($executionResult.ExitCode)'."
				}
				if ($false -eq [string]::IsNullOrEmpty($executionResult.StdErr)) {
					$uninstallResult.ErrorMessagePSADT = "$($executionResult.StdErr)"
				}
				## Delay for filehandle release etc. to occur.
				Start-Sleep -Seconds 5

				## Test successfull uninstallation
				if ($true -eq [string]::IsNullOrEmpty($UninstallKey)) {
					$uninstallResult.ErrorMessage = "UninstallKey value NOT set. Skipping test for successfull uninstallation of '$AppName' via registry."
					$uninstallResult.Success = $null
					[int]$logMessageSeverity = 2
				}
				else {
					if ($false -eq (Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor $PreSuccessCheckTotalSecondsToWaitFor -ProcessOperator $PreSuccessCheckProcessOperator -ProcessesToWaitFor $PreSuccessCheckProcessesToWaitFor -RegKeyOperator $PreSuccessCheckRegKeyOperator -RegkeysToWaitFor $PreSuccessCheckRegkeysToWaitFor)) {
						$uninstallResult.ErrorMessage = "Uninstallation RegistryAndProcessCondition of '$AppName' failed. ErrorLevel: $($uninstallResult.ApplicationExitCode)"
						$uninstallResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
						$uninstallResult.Success = $false
						[int]$logMessageSeverity = 3
					}
					else {
						if ($true -eq $(Test-NxtAppIsInstalled -UninstallKey "$UninstallKey" -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -InstallMethod $internalInstallerMethod)) {
							$uninstallResult.ErrorMessage = "Uninstallation of '$AppName' failed. ErrorLevel: $($uninstallResult.ApplicationExitCode)"
							$uninstallResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
							$uninstallResult.Success = $false
							[int]$logMessageSeverity = 3
						}
						else {
							$uninstallResult.ErrorMessage = "Uninstallation of '$AppName' was successful."
							$uninstallResult.ErrorMessagePSADT = [string]::Empty
							$uninstallResult.Success = $true
							[int]$logMessageSeverity = 1
						}
					}
				}
				if (
					($executionResult.ExitCode -notin ($AcceptedUninstallExitCodes -split ",")) -and
					($executionResult.ExitCode -notin ($AcceptedUninstallRebootCodes -split ",")) -and
					($executionResult.ExitCode -notin 0, 1641, 3010)
				) {
					$uninstallResult.ErrorMessage = "Uninstallation of '$AppName' failed. ErrorLevel: $($uninstallResult.ApplicationExitCode)"
					$uninstallResult.Success = $false
					[int]$logMessageSeverity = 3
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
		Uninstalls old package versions based on the specified parameters and PackageConfig object settings.
	.DESCRIPTION
		The Uninstall-NxtOld function uninstalls older versions of a software package when the UninstallOld parameter is set to $true. It utilizes the PackageConfig object to determine the application's name, vendor, version, and package GUID. The function checks the registry for previous package versions and performs uninstallation if required.
	.PARAMETER AppName
		Specifies the Application Name used in the registry etc. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppVendor
		Specifies the Application Vendor used in the registry etc. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppVersion
		Specifies the Application Version used in the registry etc. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PackageGUID
		Specifies the registry key name used for the packages wrapper uninstall entry. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegPackagesKey
		Defines the name of the registry key keeping track of all packages delivered by this packaging framework. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallOld
		Will uninstall previous Versions before Installation if set to $true. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER DeploymentSystem
		Defines the deployment system used for the deployment. Defaults to the corresponding value of the DeployApplication.ps1 parameter.
	.PARAMETER AppLang
		Defines the language of the application. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RemovePackagesWithSameProductGUID
		Defines if packages with the same ProductGUID should be removed. Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Uninstall-NxtOld -UninstallOld $true
		Uninstalls old versions of the package based on the settings in the PackageConfig object.
	.EXAMPLE
		Uninstall-NxtOld -UninstallOld $false -AppName "MyApp" -AppVendor "VendorX" -AppVersion "1.0" -PackageGUID "12345" -RegPackagesKey "Software\MyPackages"
		Checks for old versions but does not uninstall, specifying custom values for the parameters.
	.OUTPUTS
		PSADTNXT.NxtApplicationResult.
		Returns an object containing information about the uninstallation operation.
		- ApplicationExitCode: The exit code of the application uninstallation process.
		- MainExitCode: The exit code of the main function. 70001 indicates an error during uninstallation.
		- ErrorMessage: A message indicating the success or failure of the uninstallation process.
		- ErrorMessagePSADT: Additional error message specific to PSAppDeployToolkit.
		- Success: $true if the operation was successful, otherwise returns $false.
	.NOTES
		Should be executed during package Initialization only.
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
		$DeploymentSystem = $global:DeploymentSystem,
		[Parameter(Mandatory = $false)]
		[string]
		$AppLang = $global:PackageConfig.AppLang,
		[Parameter(Mandatory = $false)]
		[bool]
		$RemovePackagesWithSameProductGUID = $global:PackageConfig.RemovePackagesWithSameProductGUID
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[PSADTNXT.NxtApplicationResult]$uninstallOldResult = New-Object -TypeName PSADTNXT.NxtApplicationResult
		if ($false -eq $UninstallOld) {
			Write-Output $uninstallOldResult
			return
		}
		Write-Log -Message "Checking for old package installed..." -Source ${cmdletName}
		try {
			[bool]$returnWithError = $false
			## Necessary for old "neoLanguage"-packages
			if ($true -eq $RemovePackagesWithSameProductGUID) {
				[string]$appNameWithoutAppLang = "$(($AppName -Replace (" $([Regex]::Escape($AppLang))$",[string]::Empty)).TrimEnd())"
			}
			else {
				[string]$appNameWithoutAppLang = $AppName
			}
			## Check for Empirum packages under "HKLM:\Software\WOW6432Node\"
			if ($true -eq (Test-Path -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor")) {
				if ($true -eq (Test-Path -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$appNameWithoutAppLang")) {
					[Microsoft.Win32.RegistryKey[]]$appEmpirumPackageVersions = Get-ChildItem "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$appNameWithoutAppLang"
					if (($appEmpirumPackageVersions).Count -eq 0) {
						Remove-Item -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$appNameWithoutAppLang"
						Write-Log -Message "Deleted an empty Empirum application key: HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$appNameWithoutAppLang" -Source ${cmdletName}
					}
					else {
						foreach ($appEmpirumPackageVersion in $appEmpirumPackageVersions) {
							if ($true -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'PackageGUID')) {
								[string]$appEmpirumPackageGUID = Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'PackageGUID'
							}
							if ( ($false -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'PackageGUID')) -or ($appEmpirumPackageGUID -ne $PackageGUID) ) {
								Write-Log -Message "Found an old Empirum package version key: $($appEmpirumPackageVersion.name)" -Source ${cmdletName}
								if ($true -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString')) {
									try {
										[string]$appendAW = [string]::Empty
										if ((Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'MachineSetup') -eq "1") {
											[string]$appendAW = " /AW"
										}
										[string]$appEmpUninstallString = Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString'
										[string]$pattern = '^\"(?<SETUPEXE>[^"]*)\" +\"(?<SETUPINF>[^"]*)\" *(?<PARAMETER>.+)?$'
										[regex]$regex = [System.Text.RegularExpressions.Regex]::new($pattern)
										[System.Text.RegularExpressions.Match]$match = $regex.Match($appEmpUninstallString)
										if ($true -eq $match.Success -and $true -eq (Test-Path -Path $match.Groups["SETUPEXE"].Value) -and $true -eq (Test-Path -Path $match.Groups["SETUPINF"].Value)) {
											[string]$appEmpLogPath = Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'AppPath'
											[string]$appEmpLogDate = $currentDateTime | Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
											cmd /c "$appEmpUninstallString /X8 /S0$appendAW /F /E+`"$appEmpLogPath\$appEmpLogDate.log`"" | Out-Null
											$uninstallOldResult.ApplicationExitCode = $LastExitCode
										}
										else {
											Write-Log -Message "Setup.exe or Setup.inf not found. Skip uninstall of '$($appEmpirumPackageVersion.name)'" -Source ${cmdletName}
										}
									}
									catch {
									}
									if (
										$true -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString') -or
										$true -eq (Test-Path -Path "$($appEmpirumPackageVersion.PSPath)\Setup\Options") -or
										$true -eq (Test-Path -Path "$($appEmpirumPackageVersion.PSPath)\Setup\Sections")
									) {
										$uninstallOldResult.MainExitCode = 70001
										$uninstallOldResult.ErrorMessage = "Uninstallation of found Empirum package '$($appEmpirumPackageVersion.name)' failed."
										$uninstallOldResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
										$uninstallOldResult.Success = $false
										$returnWithError = $true
										Write-Log -Message $($uninstallOldResult.ErrorMessage) -Severity 3 -Source ${cmdletName}
										break
									}
									else {
										## Remove the rest of the keys that are not cleaned up by the uninstaller (can be empty so no display no error...)
										$appEmpirumPackageVersion | Remove-Item -Recurse -ErrorAction SilentlyContinue
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
						if ( ($false -eq $returnWithError) -and (($appEmpirumPackageVersions).Count -eq 0) -and ($true -eq (Test-Path -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$appNameWithoutAppLang")) ) {
							Remove-Item -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$appNameWithoutAppLang"
							$uninstallOldResult.ErrorMessage = "Deleted the now empty Empirum application key: HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$appNameWithoutAppLang"
							$uninstallOldResult.Success = $null
							Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
						}
					}
				}
				if ( ($false -eq $returnWithError) -and ($true -eq (Test-Path -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor")) -and ((Get-ChildItem "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor").Count -eq 0) ) {
					Remove-Item -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor"
					$uninstallOldResult.ErrorMessage = "Deleted empty Empirum vendor key: HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor"
					$uninstallOldResult.Success = $null
					Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
				}
			}
			## Check for Empirum packages under "HKLM:\Software\"
			if ( ($false -eq $returnWithError) -and ($true -eq (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$AppVendor")) ) {
				if ($true -eq (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$AppVendor\$appNameWithoutAppLang")) {
					[Microsoft.Win32.RegistryKey[]]$appEmpirumPackageVersions = Get-ChildItem "HKLM:\Software\$RegPackagesKey\$AppVendor\$appNameWithoutAppLang"
					if (($appEmpirumPackageVersions).Count -eq 0) {
						Remove-Item -Path "HKLM:\Software\$RegPackagesKey\$AppVendor\$appNameWithoutAppLang"
						Write-Log -Message "Deleted an empty Empirum application key: HKLM:\Software\$RegPackagesKey\$AppVendor\$appNameWithoutAppLang" -Source ${cmdletName}
					}
					else {
						foreach ($appEmpirumPackageVersion in $appEmpirumPackageVersions) {
							if ($true -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'PackageGUID')) {
								[string]$appEmpirumPackageGUID = Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'PackageGUID'
							}
							if (($false -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'PackageGUID')) -or ($appEmpirumPackageGUID -ne $PackageGUID) ) {
								Write-Log -Message "Found an old Empirum package version key: $($appEmpirumPackageVersion.name)" -Source ${cmdletName}
								if ($true -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString')) {
									try {
										[string]$appendAW = [string]::Empty
										if ((Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'MachineSetup') -eq "1") {
											[string]$appendAW = " /AW"
										}
										[string]$appEmpUninstallString = Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString'
										[string]$pattern = '^\"(?<SETUPEXE>[^"]*)\" +\"(?<SETUPINF>[^"]*)\" *(?<PARAMETER>.+)?$'
										[regex]$regex = [System.Text.RegularExpressions.Regex]::new($pattern)
										[System.Text.RegularExpressions.Match]$match = $regex.Match($appEmpUninstallString)
										if ($true -eq $match.Success -and $true -eq (Test-Path -Path $match.Groups["SETUPEXE"].Value) -and $true -eq (Test-Path -Path $match.Groups["SETUPINF"].Value)) {
											[string]$appEmpLogPath = Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'AppPath'
											[string]$appEmpLogDate = $currentDateTime | Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
											cmd /c "$appEmpUninstallString /X8 /S0$appendAW /F /E+`"$appEmpLogPath\$appEmpLogDate.log`"" | Out-Null
											$uninstallOldResult.ApplicationExitCode = $LastExitCode
										}
										else {
											Write-Log -Message "Setup.exe or Setup.inf not found. Skip uninstall of '$($appEmpirumPackageVersion.name)'" -Source ${cmdletName}
										}
									}
									catch {
									}
									if (
										$true -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString') -or
										$true -eq (Test-Path -Path "$($appEmpirumPackageVersion.PSPath)\Setup\Options") -or
										$true -eq (Test-Path -Path "$($appEmpirumPackageVersion.PSPath)\Setup\Sections")
									) {
										$uninstallOldResult.MainExitCode = 70001
										$uninstallOldResult.ErrorMessage = "Uninstallation of found Empirum package '$($appEmpirumPackageVersion.name)' failed."
										$uninstallOldResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
										$uninstallOldResult.Success = $false
										Write-Log -Message $($uninstallOldResult.ErrorMessage) -Severity 3 -Source ${cmdletName}
										$returnWithError = $true
										break
									}
									else {
										## Remove the rest of the keys that are not cleaned up by the uninstaller (can be empty so no display no error...)
										$appEmpirumPackageVersion | Remove-Item -Recurse -ErrorAction SilentlyContinue
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
						if ( ($false -eq $returnWithError) -and (($appEmpirumPackageVersions).Count -eq 0) -and ($true -eq (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$AppVendor\$appNameWithoutAppLang")) ) {
							Remove-Item -Path "HKLM:\Software\$RegPackagesKey\$AppVendor\$appNameWithoutAppLang"
							$uninstallOldResult.ErrorMessage = "Deleted the now empty Empirum application key: HKLM:\Software\$RegPackagesKey\$AppVendor\$appNameWithoutAppLang"
							$uninstallOldResult.Success = $null
							Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
						}
					}
				}
				if ( ($false -eq $returnWithError) -and ($true -eq (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$AppVendor")) -and ((Get-ChildItem "HKLM:\Software\$RegPackagesKey\$AppVendor").Count -eq 0) ) {
					Remove-Item -Path "HKLM:\Software\$RegPackagesKey\$AppVendor"
					$uninstallOldResult.ErrorMessage = "Deleted empty Empirum vendor key: HKLM:\Software\$RegPackagesKey\$AppVendor"
					$uninstallOldResult.Success = $null
					Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
				}
			}
			if ($false -eq $returnWithError) {
				[string]$regPackageGUID = $null
				## Check for VBS or PSADT packages
				if ($true -eq (Test-RegistryValue -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Value 'UninstallString')) {
					[string]$regPackageGUID = "HKLM:\Software\$RegPackagesKey\$PackageGUID"
				}
				elseif ($true -eq (Test-RegistryValue -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$PackageGUID" -Value 'UninstallString')) {
					[string]$regPackageGUID = "HKLM:\Software\Wow6432Node\$RegPackagesKey\$PackageGUID"
				}
				if ($false -eq [string]::IsNullOrEmpty($regPackageGUID)) {
					## Check if the installed package's version is lower than the current one's (else we don't remove old package)
					if ("$(Compare-NxtVersion -DetectedVersion "$(Get-RegistryKey -Key "$regPackageGUID" -Value 'Version')" -TargetVersion "$AppVersion")" -ne "Update") {
						[string]$regPackageGUID = $null
					}
				}
				else {
					## Check for old VBS product member package (only here: old $PackageFamilyGUID is stored in $ProductGUID)
					if ($true -eq (Test-RegistryValue -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$ProductGUID" -Value 'UninstallString')) {
						[string]$regPackageGUID = "HKLM:\Software\Wow6432Node\$RegPackagesKey\$ProductGUID"
					}
					elseif ($true -eq (Test-RegistryValue -Key "HKLM:\Software\$RegPackagesKey\$ProductGUID" -Value 'UninstallString')) {
						[string]$regPackageGUID = "HKLM:\Software\$RegPackagesKey\$ProductGUID"
					}
					if ($false -eq [string]::IsNullOrEmpty($regPackageGUID)) {
						Write-Log -Message "A former product member application package was found." -Source ${cmdletName}
					}
				}
				## if the current package is a new ADT package, but is actually only registered because it is a product member package, we cannot uninstall it again now
				if ((Get-NxtRegisteredPackage -ProductGUID "$ProductGUID" -InstalledState 0 -RegPackagesKey $RegPackagesKey).PackageGUID -contains "$PackageGUID") {
					[string]$regPackageGUID = $null
				}
				if ($false -eq [string]::IsNullOrEmpty($regPackageGUID)) {
					Write-Log -Message "Parameter 'UninstallOld' is set to true and an old package version was found: Uninstalling old package with PackageGUID [$(Split-Path -Path `"$regPackageGUID`" -Leaf)]..." -Source ${cmdletName}
					cmd /c (Get-RegistryKey -Key "$regPackageGUID" -Value 'UninstallString') | Out-Null
					$uninstallOldResult.ApplicationExitCode = $LastExitCode
					if ($true -eq (Test-RegistryValue -Key "$regPackageGUID" -Value 'UninstallString')) {
						$uninstallOldResult.MainExitCode = 70001
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
			$uninstallOldResult.MainExitCode = 70001
			$uninstallOldResult.ErrorMessage = "The function '${cmdletName}' threw an error."
			$uninstallOldResult.ErrorMessagePSADT = $($Error[0].Exception.Message)
			$uninstallOldResult.Success = $false
			Write-Log -Message "$($uninstallOldResult.ErrorMessage)`n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
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
		Unregisters old versions of a package without uninstalling them, based on PackageConfig object settings.
	.DESCRIPTION
		The Unregister-NxtOld function is used to unregister older versions of a software package without uninstalling them, applicable when the UninstallOld parameter is set to $false. It identifies older package versions using ProductGUID and PackageGUID from the registry and removes their registration information.
	.PARAMETER ProductGUID
		Specifies a membership GUID for a product of an application package. Can be found under "HKLM:\Software\<RegPackagesKey>\<PackageGUID>" for an application package with product membership. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PackageGUID
		Specifies the registry key name used for the package's wrapper uninstall entry. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegPackagesKey
		Defines the name of the registry key for tracking all packages delivered by the packaging framework. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER UninstallOld
		If set to $false, previous versions will be unregistered before installation. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppName
		Specifies the Application Name used in the registry etc. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppVendor
		Specifies the Application Vendor used in the registry etc. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppLang
		Defines the language of the application. Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Unregister-NxtOld
		Executes the function with default parameters from the PackageConfig object to unregister old package versions.
	.OUTPUTS
		none.
	.NOTES
		Should be executed during package Initialization only.
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
		[string]
		$AppName = $global:PackageConfig.AppName,
		[Parameter(Mandatory = $false)]
		[string]
		$AppVendor = $global:PackageConfig.AppVendor,
		[Parameter(Mandatory = $false)]
		[string]
		$AppLang = $global:PackageConfig.AppLang,
		[Parameter(Mandatory = $false)]
		[bool]
		$UninstallOld = $global:PackageConfig.UninstallOld
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		## Only unregister old packages if UninstallOld is set to $false
		if ($true -eq $UninstallOld) {
			return
		}
		Write-Log -Message "Checking for old package registered..." -Source ${cmdletName}
		[string]$currentGUID = [string]::Empty
		## process an old application package
		if (
			$true -eq (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$PackageGUID" -PathType 'Container') -or
			$true -eq (Test-Path -Path "HKLM:\Software\Wow6432Node\$RegPackagesKey\$PackageGUID" -PathType 'Container') -or
			$true -eq (Test-Path -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -PathType 'Container') -or
			$true -eq (Test-Path -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -PathType 'Container')
		) {
			[string]$currentGUID = $PackageGUID
			if (
				$true -eq (Test-Path -Path "HKLM:\Software\Wow6432Node\$RegPackagesKey\$PackageGUID" -PathType 'Container') -and
				("$(Compare-NxtVersion -DetectedVersion "$(Get-RegistryKey -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID" -Value 'Version')" -TargetVersion "$AppVersion")") -eq "Update" -and
				$true -eq (Test-RegistryValue -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID" -Value 'AppPath')
			) {
				[string]$currentAppPath = (Get-RegistryKey -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID" -Value 'AppPath')
			}
			elseif (
				$true -eq (Test-Path -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -PathType 'Container') -and
				("$(Compare-NxtVersion -DetectedVersion "$(Get-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$currentGUID" -Value 'Version')" -TargetVersion "$AppVersion")") -eq "Update" -and
				$true -eq (Test-RegistryValue -Key "HKLM:\Software\$RegPackagesKey\$currentGUID" -Value 'AppPath')
			) {
				[string]$currentAppPath = (Get-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$currentGUID" -Value 'AppPath')
			}
			else {
				[string]$currentGUID = [string]::Empty
			}
		}
		## process old product group member
		elseif (
			$true -eq (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$ProductGUID" -PathType 'Container') -or
			$true -eq (Test-Path -Path "HKLM:\Software\Wow6432Node\$RegPackagesKey\$ProductGUID" -PathType 'Container') -or
			$true -eq (Test-Path -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$ProductGUID" -PathType 'Container') -or
			$true -eq (Test-Path -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$ProductGUID" -PathType 'Container')
		) {
			[string]$currentGUID = $ProductGUID
			## retrieve AppPath for former VBS package (only here: old $PackageFamilyGUID is stored in $ProductGUID)
			if ($true -eq (Test-RegistryValue -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID" -Value 'AppPath')) {
				[string]$currentAppPath = (Get-RegistryKey -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID" -Value 'AppPath')
				if ($true -eq [string]::IsNullOrEmpty($currentAppPath)) {
					[string]$currentAppPath = (Get-RegistryKey -Key "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$currentGUID" -Value 'PackageApplicationDir')
				}
			}
			elseif ($true -eq (Test-RegistryValue -Key "HKLM:\Software\$RegPackagesKey\$currentGUID" -Value 'AppPath')) {
				[string]$currentAppPath = (Get-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$currentGUID" -Value 'AppPath')
				if ($true -eq [string]::IsNullOrEmpty($currentAppPath)) {
					[string]$currentAppPath = (Get-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$currentGUID" -Value 'PackageApplicationDir')
				}
				## for an old product member we always remove these registry keys (in case of x86 packages we do it later anyway)
				Remove-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$currentGUID"
				Remove-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$currentGUID"
			}
			else {
				[string]$currentGUID = [string]::Empty
			}
		}
		## note: the x64 uninstall registry keys are still the same as for old package and remains there if the old package should not to be uninstalled (not true for old product member packages, see above!)
		if ($false -eq [string]::IsNullOrEmpty($currentGUID)) {
			Remove-RegistryKey -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID"
			Remove-RegistryKey -Key "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$currentGUID"
			if (
				$true -eq (Test-Path -Path "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID" -PathType 'Container') -or
				$true -eq (Test-Path -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$currentGUID" -PathType 'Container') -or
				$true -eq (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$currentGUID" -PathType 'Container') -or
				$true -eq (Test-Path -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$currentGUID" -PathType 'Container')
			) {
				Write-Log -Message "Unregister of old package was incomplete! Note: Some orphaned registry keys might remain on the client." -Severity 2 -Source ${cmdletName}
			}
		}
		## cleanup registry of traditional Empirum package
		[string]$appNameWithoutAppLang = "$(($AppName -Replace (" $([Regex]::Escape($AppLang))$",[string]::Empty)).TrimEnd())"
		[string[]]$appNameList = @(($appNameWithoutAppLang, $AppName) | Sort-Object -Unique)
		foreach ($regPackageRoot in @("HKLM:\Software\Wow6432Node", "HKLM:\Software")) {
			foreach ($appName in $appNameList) {
				[Microsoft.Win32.RegistryKey]$regProductKey = Get-Item -Path "$regPackageRoot\$RegPackagesKey\$AppVendor\$appName" -ErrorAction SilentlyContinue
				if ($null -eq $regProductKey) {
					continue
				}
				[Microsoft.Win32.RegistryKey[]]$regVersionKeys = Get-ChildItem -Path $regProductKey.PSPath -ErrorAction SilentlyContinue
				if ($regVersionKeys.Count -eq 0) {
					Remove-NxtEmptyRegistryKey -Path $regProductKey.Name
					Remove-NxtEmptyRegistryKey -Path (Split-Path -Parent -Path $regProductKey.Name)
					continue
				}
				[Microsoft.Win32.RegistryKey[]]$regVersionKeysOfNonADTPackages = $regVersionKeys | Where-Object {
					$true -eq [string]::IsNullOrEmpty($_.GetValue("PackageGUID"))
				}
				Write-Log -Message "Detected $($regVersionKeysOfNonADTPackages.Count) old Empirum installation(s) of '$appName'." -Source ${cmdletName}
				foreach ($regVersionKey in $regVersionKeysOfNonADTPackages) {
					[Microsoft.Win32.RegistryKey]$regSetupKey = Get-Item -Path (Join-Path $regVersionKey.PSPath "Setup")
					## Remove this entry if the setup information is not available
					if (($null -eq $regSetupKey) -or ($true -eq [string]::IsNullOrEmpty($regSetupKey.GetValue("Version")))) {
						Write-Log "The setup information for the package '$appName' could not be found. Removing old entry." -Source ${CmdletName} -Severity 2
						Remove-Item -Path $regVersionKey.PSPath -Recurse
						Remove-NxtEmptyRegistryKey -Path (Split-Path -Parent -Path $regVersionKey.Name)
						continue
					}
					[string]$packageVersion = $regSetupKey.GetValue("Version")
					## Obtain the uninstall key for the package
					[Microsoft.Win32.RegistryKey]$regUninstallKey = Get-Item -Path "$regPackageRoot\Microsoft\Windows\CurrentVersion\Uninstall\neoPackage $AppVendor $appName $packageVersion" -ErrorAction SilentlyContinue
					if ($null -ne $regUninstallKey) {
						Write-Log -Message "Removing the uninstall key for the package '$appName' with version '$packageVersion'." -Source ${CmdletName}
						Remove-Item -Path $regUninstallKey.PSPath
					}
					else {
						Write-Log -Message "The uninstall key for the package '$appName' with version '$packageVersion' could not be found." -Source ${CmdletName} -Severity 2
					}
					Remove-Item -Path $regVersionKey.PSPath -Recurse
					Remove-NxtEmptyRegistryKey -Path $regProductKey.Name
					Remove-NxtEmptyRegistryKey -Path (Split-Path -Parent -Path $regProductKey.Name)
				}
			}
		}
		## cleanup Empirum specific install key
		@(
			## Get all keys on which detection should be performed (x86 and x64)
			Get-ChildItem -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" -ErrorAction SilentlyContinue
			Get-ChildItem -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\" -ErrorAction SilentlyContinue
		) | Where-Object {
			## Only check keys that match the vendor
			$_.PSChildName -like "neoPackage $AppVendor $AppName*" -and
			## Only get keys that match GUID or AppVendor\AppName
			(
				$_.GetValue("MachineKeyName") -eq "$RegPackagesKey\$ProductGuid" -or
				$_.GetValue("MachineKeyName") -like "$RegPackagesKey\$AppVendor\$AppName\*"
			) -and
			## Only get keys that dont have the same version
			$_.GetValue("DisplayVersion") -ne $AppVersion
		} | ForEach-Object {
			Write-Log "Removing the Empirum specific uninstall key '$($_.PSChildName)' with version '$($_.GetValue('DisplayVersion'))'." -Source ${CmdletName}
			Remove-RegistryKey $_.Name
		}
		## Remove the old package cache
		if ($false -eq [string]::IsNullOrEmpty($currentAppPath)) {
			if ($true -eq (Test-Path -Path "$currentAppPath")) {
				Remove-Folder -Path "$currentAppPath\neoInstall"
				Remove-Folder -Path "$currentAppPath\neoSource"
				if ( ($true -eq (Test-Path -Path "$currentAppPath\neoInstall")) -or ($true -eq (Test-Path -Path "$currentAppPath\neoSource")) ) {
					Write-Log -Message "Unregister of old package was incomplete! Note: Some orphaned files and folders might remain on the client." -Severity 2 -Source ${cmdletName}
				}
			}
		}
		else {
			Write-Log -Message "No need to cleanup old package cached app folder." -Source ${cmdletName}
		}
		# Remove legacy x86 package container key if it exists and is empty
		Remove-NxtEmptyRegistryKey -Path "HKLM:\Software\WOW6432Node\neoPackages"
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
		Unregisters an application package by removing its package files and registry entries.
	.DESCRIPTION
		The Unregister-NxtPackage function is designed to remove an application package by deleting its package files from a specified folder and its registry entries. It targets the package's files located in the "$APP\" directory and removes registry keys found under "HKLM:\Software\$regPackagesKey\$PackageGUID" and "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID". This function is particularly useful for maintaining a clean system state by ensuring that remnants of uninstalled packages are properly cleaned up.
	.PARAMETER ProductGUID
		Specifies the GUID of the product associated with the application package. This GUID is used to identify the package in the system registry. This parameter is mandatory. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RemovePackagesWithSameProductGUID
		If set to true, the function will uninstall all packages with the same ProductGUID. It is important for managing multiple versions or instances of an application package. This parameter is mandatory. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER PackageGUID
		Indicates the specific registry key name associated with the package's uninstall entry. This is critical for accurately targeting and removing the correct registry entries. This parameter is mandatory. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegPackagesKey
		Names the registry key that tracks all packages delivered by the packaging framework. This parameter helps in pinpointing the exact location in the registry where the package information is stored. This parameter is mandatory. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER App
		Defines the path to a local persistent cache for installation files. This parameter is essential for locating and removing the actual application files. This parameter is mandatory. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER ScriptRoot
		Defines the parent directory of the script. It is essential for locating associated scripts and resources used during the uninstallation process. This parameter is mandatory. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppRootFolder
		Defines the root folder of the application package, used for determining the scope of file removal. This parameter is mandatory. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppVendor
		Identifies the vendor of the application package, which can be used for logging or reporting purposes. This parameter is mandatory. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER ExecutionPolicy
		Defines the execution policy for the PowerShell script. Defaults to the corresponding value from the AppDeployToolkit_Config.xml file.
	.EXAMPLE
		Unregister-NxtPackage -ProductGUID "{12345678-90ab-cdef-1234-567890abcdef}" -RemovePackagesWithSameProductGUID $true -PackageGUID "{abcdefgh-1234-5678-90ab-cdef012345678}" -RegPackagesKey "MyPackages" -App "C:\Apps\MyApp" -ScriptRoot "C:\Scripts" -AppRootFolder "C:\Apps" -AppVendor "MyCompany"
		This example unregisters a package with the specified GUID, removing all related files and registry entries.
	.EXAMPLE
		Unregister-NxtPackage -ProductGUID "87654321-fedc-ba09-8765-4321fedcba09" -RemovePackagesWithSameProductGUID $false -PackageGUID "mnopqrst-5678-1234-cdef-abcdefghijkl" -RegPackagesKey "OtherPackages" -App "D:\OtherApps\AnotherApp" -ScriptRoot "D:\Scripts" -AppRootFolder "D:\OtherApps" -AppVendor "AnotherCompany"
		In this example, the function is used to unregister a different package, demonstrating the flexibility of the parameters.
	.OUTPUTS
		none.
	.NOTES
		Should be executed at the end of each neo42-package uninstallation only.
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
		$ScriptRoot = $scriptRoot,
		[Parameter(Mandatory = $false)]
		[string]
		$AppRootFolder = $global:PackageConfig.AppRootFolder,
		[Parameter(Mandatory = $false)]
		[string]
		$AppVendor = $global:PackageConfig.AppVendor,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]
		$ExecutionPolicy = $xmlConfigFile.AppDeployToolkit_Config.NxtPowerShell_Options.NxtPowerShell_ExecutionPolicy
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
				if ($false -eq [string]::IsNullOrEmpty($ProductGUID)) {
					Write-Log -Message "Cleanup registry entries and folder of assigned product member application packages with 'ProductGUID' [$ProductGUID]..." -Source ${CmdletName}
					(Get-NxtRegisteredPackage -ProductGUID $ProductGUID -RegPackagesKey $RegPackagesKey).PackageGUID | Where-Object {
						$null -ne $($_)
					} | ForEach-Object {
						[string]$assignedPackageGUID = $_
						Write-Log -Message "Processing tasks for product member application package with PackageGUID [$assignedPackageGUID]..."  -Source ${CmdletName}
						[string]$assignedPackageGUIDAppPath = (Get-Registrykey -Key "HKLM:\Software\$RegPackagesKey\$assignedPackageGUID").AppPath
						if ($false -eq ([string]::IsNullOrEmpty($assignedPackageGUIDAppPath))) {
							if ($true -eq (Test-Path -Path "$assignedPackageGUIDAppPath")) {
								## note: we always use the script from current application package source folder (it is basically identical in each package)
								Copy-File -Path "$ScriptRoot\Clean-Neo42AppFolder.ps1" -Destination "$assignedPackageGUIDAppPath\"
								Start-Sleep -Seconds 1
								[hashtable]$executeProcessSplat = @{
									Path = 'powershell.exe'
									Parameters = "-ExecutionPolicy $ExecutionPolicy -NonInteractive -File `"$assignedPackageGUIDAppPath\Clean-Neo42AppFolder.ps1`""
									NoWait = $true
									WorkingDirectory = $env:TEMP
									ExitOnProcessFailure = $false
									PassThru = $true
								}
								## we use $env:TEMP es workingdirectory to avoid issues with locked directories
								if (
									$false -eq [string]::IsNullOrEmpty($AppRootFolder) -and
									$false -eq [string]::IsNullOrEmpty($AppVendor)
								) {
									$executeProcessSplat["Parameters"] = Add-NxtParameterToCommand -Command $executeProcessSplat["Parameters"] -Name "RootPathToRecurseUpTo" -Value "$AppRootFolder\$AppVendor"
								}
								Execute-Process @executeProcessSplat | Out-Null
								$removalCounter += 1
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
						if ($true -eq (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$assignedPackageGUID$("_Error")")) {
							Remove-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$assignedPackageGUID$("_Error")"
						}
					}
					Write-Log -Message "All folder and registry entries of assigned product member application packages with 'ProductGUID' [$ProductGUID] are cleaned." -Source ${CmdletName}
					if ($removalCounter -eq 0) {
						Write-Log -Message "No application packages assigned to a product found for removal." -Source ${CmdletName}
					}
				}
				else {
					Write-Log -Message "No ProductGUID was provided. Cleanup for application packages assigned to a product skipped." -Severity 2 -Source ${CmdletName}
				}
			}
			else {
				Write-Log -Message "Cleanup registry entries and folder of package with 'PackageGUID' [$PackageGUID] only..." -Source ${cmdletName}
				if ($PackageGUID -ne $global:PackageConfig.PackageGUID) {
					$App = (Get-Registrykey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID").AppPath
				}
				if ($false -eq [string]::IsNullOrEmpty($App)) {
					if ($true -eq (Test-Path -Path "$App")) {
						## note: we always use the script from current application package source folder (it is basically identical in each package)
						Copy-File -Path "$ScriptRoot\Clean-Neo42AppFolder.ps1" -Destination "$App\"
						Start-Sleep -Seconds 1
						[hashtable]$executeSplat = @{
							Path = 'powershell.exe'
							Parameters = "-ExecutionPolicy $ExecutionPolicy -NonInteractive -File `"$App\Clean-Neo42AppFolder.ps1`""
							NoWait = $true
							WorkingDirectory = $env:TEMP
							ExitOnProcessFailure = $false
							PassThru = $true
						}
						## we use $env:TEMP es workingdirectory to avoid issues with locked directories
						if (
							$false -eq [string]::IsNullOrEmpty($AppRootFolder) -and
							$false -eq [string]::IsNullOrEmpty($AppVendor)
							) {
							$executeSplat["Parameters"] = Add-NxtParameterToCommand -Command $executeSplat["Parameters"] -Name "RootPathToRecurseUpTo" -Value "$AppRootFolder\$AppVendor"
						}
						Execute-Process @executeSplat | Out-Null
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
				if ($true -eq (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")")) {
					Remove-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID$("_Error")"
				}
				Write-Log -Message "Package unregistration successful." -Source ${cmdletName}
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
	.SYNOPSIS
		Updates text within a file by replacing specified strings.
	.DESCRIPTION
		This cmdlet allows you to replace specific text in a file. It searches for a given string and replaces it with another string. The function can target a specific number of occurrences and use various encoding options.
	.PARAMETER Path
		Specifies the path to the file that needs text replacement. This parameter is mandatory.
	.PARAMETER SearchString
		Defines the string to be searched for in the file. This parameter is mandatory.
	.PARAMETER ReplaceString
		Specifies the string that will replace the found occurrences in the file. This parameter is mandatory.
	.PARAMETER Count
		Determines the number of occurrences to replace. If not specified, all occurrences are replaced.
	.PARAMETER Encoding
		Defines the encoding of the file. If not specified, it defaults to the encoding returned by Get-NxtFileEncoding.
	.PARAMETER DefaultEncoding
		Specifies the encoding to be used if the file's encoding cannot be detected.
	.EXAMPLE
		Update-NxtTextInFile -Path "C:\Temp\testfile.txt" -SearchString "Hello" -ReplaceString "Hi"
		This example replaces all occurrences of "Hello" with "Hi" in the specified file.
	.EXAMPLE
		Update-NxtTextInFile -Path "C:\Temp\testfile.txt" -SearchString "old text" -ReplaceString "new text" -Count 2
		This example replaces the first two occurrences of "old text" with "new text" in the specified file.
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
		[AllowEmptyString()]
		[String]
		$ReplaceString,
		[Parameter()]
		[Int]
		$Count = [int]::MaxValue,
		[Parameter()]
		[ValidateSet('Ascii', 'Default', 'UTF7', 'BigEndianUnicode', 'Oem', 'Unicode', 'UTF32', 'UTF8')]
		[String]
		$Encoding,
		[Parameter()]
		[ValidateSet('Ascii', 'Default', 'UTF7', 'BigEndianUnicode', 'Oem', 'Unicode', 'UTF32', 'UTF8')]
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
		if (($false -eq (Test-Path -Path $Path)) -and ($true -eq ([String]::IsNullOrEmpty($intEncoding)))) {
			[string]$intEncoding = 'UTF8'
		}
		elseif (($true -eq (Test-Path -Path $Path)) -and ($true -eq ([String]::IsNullOrEmpty($intEncoding)))) {
			try {
				[hashtable]$getFileEncodingParams = @{
					Path = $Path
				}
				if ($false -eq ([string]::IsNullOrEmpty($DefaultEncoding))) {
					[string]$getFileEncodingParams['DefaultEncoding'] = $DefaultEncoding
				}
				[string]$intEncoding = (Get-NxtFileEncoding @getFileEncodingParams)
				if ($intEncoding -eq 'UTF8') {
					[bool]$noBOMDetected = $true
				}
				elseif ($intEncoding -eq 'UTF8withBom') {
					[bool]$noBOMDetected = $false
					[string]$intEncoding = 'UTF8'
				}
			}
			catch {
				[string]$intEncoding = 'UTF8'
			}
		}
		try {
			[hashtable]$contentParams = @{
				Path = $Path
			}
			if ($false -eq [string]::IsNullOrEmpty($intEncoding)) {
				[string]$contentParams['Encoding'] = $intEncoding
			}
			[string]$content = Get-Content @contentParams -Raw
			[regex]$pattern = $SearchString
			[array]$regexMatches = $pattern.Matches($content) | Select-Object -First $Count
			if ($regexMatches.count -eq 0) {
				Write-Log -Message "Did not find anything to replace in file [$Path]."
				return
			}
			else {
				Write-Log -Message "Found $($regexMatches.Count) instances of search string [$SearchString] in file [$Path]."
			}
			[array]::Reverse($regexMatches)
			foreach ($match in $regexMatches) {
				$content = $content.Remove($match.index, $match.Length).Insert($match.index, $ReplaceString)
				Write-Log -Message "Replaced [$($match.Value)] with [$ReplaceString] at index $($match.Index)"
			}
			if ($noBOMDetected -and ($intEncoding -eq 'UTF8')) {
				[System.IO.File]::WriteAllLines($Path, $content)
			}
			else {
				$content | Set-Content @contentParams -NoNewline
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
#region Function Update-NxtXmlNode
function Update-NxtXmlNode {
	<#
	.SYNOPSIS
		Updates an existing XML node in a specified file.
	.DESCRIPTION
		This cmdlet updates an existing node in an XML file. It allows setting or changing node attributes and inner text. The operation fails if the specified node does not exist. Namespaces are not supported in this cmdlet.
	.PARAMETER FilePath
		The path to the XML file where the node update is to be performed. This parameter is mandatory.
	.PARAMETER NodePath
		XPath to the node in the XML file that is to be updated. This parameter is mandatory.
	.PARAMETER FilterAttributes
		Attributes used to filter and identify the specific node to update.
	.PARAMETER Attributes
		A hashtable of attributes to set or update on the selected node.
	.PARAMETER InnerText
		The text value to be set for the node.
	.PARAMETER Encoding
		Specifies the encoding of the file. Optional parameter.
	.PARAMETER DefaultEncoding
		Specifies the default encoding to use if the file's encoding cannot be auto-detected. Optional parameter.
	.EXAMPLE
		Update-NxtXmlNode -FilePath ".\xmlstuff.xml" -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -Attributes @{"name"="NewNode2"} -InnerText "NewValue2"
		This updates the node's inner text to "NewValue2" and sets the attribute "name" to "NewNode2".
	.EXAMPLE
		Update-NxtXmlNode -FilePath ".\xmlstuff.xml" -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -FilterAttributes @{"name"="NewNode2"} -Attributes @{"name"="NewNode3"}
		This updates the node which has an attribute "name" with the value "NewNode2", changing this attribute to "name"="NewNode3".
	.OUTPUTS
		None.
	.NOTES
		Ensure the correct file path, node path, and attributes are provided to avoid errors or unintended modifications.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$FilePath,
		[Parameter(Mandatory = $true)]
		[string]
		$NodePath,
		[Parameter(Mandatory = $false)]
		[hashtable]
		$Attributes,
		[Parameter(Mandatory = $false)]
		[hashtable]
		$FilterAttributes,
		[Parameter(Mandatory = $false)]
		[string]
		$InnerText,
		[Parameter()]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[String]
		$Encoding,
		[Parameter()]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[String]
		$DefaultEncoding = 'UTF8withBom'
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		# Test for Node
		[hashtable]$testNxtXmlNodeExistsParams = @{
			FilePath = $FilePath
			NodePath = $NodePath
		}
		if ($false -eq [string]::IsNullOrEmpty($FilterAttributes)) {
			$testNxtXmlNodeExistsParams.Add("FilterAttributes", $FilterAttributes)
		}
		if ($false -eq (Test-Path -Path $FilePath)) {
			Write-Log -Message "File $FilePath does not exist" -Severity 3
			throw "File $FilePath does not exist"
		}
		if ($true -eq (Test-NxtXmlNodeExists @testNxtXmlNodeExistsParams)) {
			[hashtable]$encodingParams = @{}
			if ($false -eq [string]::IsNullOrEmpty($Encoding)) {
				$encodingParams["Encoding"] = $Encoding
			}
			if ($false -eq [string]::IsNullOrEmpty($DefaultEncoding)) {
				$encodingParams["DefaultEncoding"] = $DefaultEncoding
			}
			[System.Xml.XmlDocument]$xml = Import-NxtXmlFile @encodingParams -Path $FilePath
			[psobject]$nodes = $xml.SelectNodes($NodePath)
			if ($false -eq [string]::IsNullOrEmpty($FilterAttributes)) {
				$nodes = $nodes | Where-Object {
					[psobject]$filterNode = $_
					$false -notin ($FilterAttributes.GetEnumerator() | ForEach-Object {
							$filterNode.GetAttribute($_.Key) -eq $_.Value
						})
				}
			}
			## Ensure we only have one node
			if ($nodes.count -gt 1) {
				Write-Log -Message "More than one node found for $NodePath" -Severity 3
				throw "More than one node found for $NodePath"
			}
			[psobject]$node = $nodes | Select-Object -First 1
			## build message text
			[string]$message = "Updating file [$FilePath] node [$NodePath]"
			if ($PSBoundParameters.Keys -contains "InnerText") {
				$node.InnerText = $InnerText
				$message += " with innerText [$InnerText]"
			}
			if ($null -ne $Attributes) {
				foreach ($attribute in $Attributes.GetEnumerator()) {
					$node.SetAttribute($attribute.Key, $attribute.Value)
					$message += " and attribute [$($attribute.Key)] with value [$($attribute.Value)]"
				}
			}
			[hashtable]$saveNxtXmlFileParams = @{
				Xml = $xml
				Path = $FilePath
			}
			if ($false -eq [string]::IsNullOrEmpty($Encoding)) {
				$saveNxtXmlFileParams["Encoding"] = $Encoding
			}
			if ($false -eq [string]::IsNullOrEmpty($DefaultEncoding)) {
				$saveNxtXmlFileParams["DefaultEncoding"] = $DefaultEncoding
			}
			Save-NxtXmlFile @saveNxtXmlFileParams
			$message += "."
			Write-Log -Message $message -Source ${cmdletName}
		}
		else {
			Write-Log -Message "Node $NodePath does not exist" -Severity 3
			throw "Node $NodePath does not exist"
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
		Waits for specified process and registry key conditions during installation or uninstallation.
	.DESCRIPTION
		This cmdlet monitors and waits for specified process and registry key conditions to be met during installation or uninstallation processes. It is integrated with Install-NxtApplication and Uninstall-Nxtapplication. The cmdlet supports setting a timeout and defining conditions with operators.
	.PARAMETER TotalSecondsToWaitFor
		Specifies the timeout duration in seconds. The function waits for this duration for the condition to occur. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER ProcessOperator
		Defines the logical operator ("And", "Or") to evaluate multiple process conditions. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER ProcessesToWaitFor
		An array of process names to wait for, based on the defined conditions. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegKeyOperator
		Specifies the logical operator ("And", "Or") to evaluate multiple registry key conditions. Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER RegkeysToWaitFor
		An array of registry key conditions to monitor. Defaults to the corresponding value from the PackageConfig object.
	.EXAMPLE
		Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor 300 -ProcessOperator "Or" -ProcessesToWaitFor  @([PSCustomObject]@{"Name"="notepad.exe"; "ShouldExist"=$true}, [PSCustomObject]@{"Name"="process2.exe"; "ShouldExist"=$true}) -RegKeyOperator "And" -RegkeysToWaitFor @([PSCustomObject]@{"KeyPath"="HKLM:\Software\MySoftware"; "ShouldExist"=$true})
		This example waits up to 300 seconds for either process "process1" or "process2" to exist (as per the "Or" operator) and for the registry key "HKCU:\Software\MySoftware" to exist.
	.OUTPUTS
		System.Boolean.
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
		[array]$ProcessesToWaitFor = $ProcessesToWaitFor | Select-Object *, @{
			n = "success"
			e = {
				$false
			}
		}
		[array]$RegkeysToWaitFor = $RegkeysToWaitFor | Select-Object *, @{
			n = "success"
			e = {
				$false
			}
		}
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
			$false -eq (($true -eq $processesFinished) -and ($true -eq $regKeysFinished))
		) {
			if ($false -eq $firstRun) {
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
				[bool]$processesFinished = $true -in ($ProcessesToWaitFor | Select-Object -ExpandProperty success)
			}
			elseif ($ProcessOperator -eq "And") {
				[bool]$processesFinished = $false -notin ($ProcessesToWaitFor | Select-Object -ExpandProperty success)
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
				if ($false -eq [string]::IsNullOrEmpty($regkeyToWaitFor.KeyPath)) {
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
							($false -eq [string]::IsNullOrEmpty($_.ValueName)) -and
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
							($false -eq [string]::IsNullOrEmpty($_.ValueName)) -and
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
							($false -eq [string]::IsNullOrEmpty($_.ValueName)) -and
							($false -eq [string]::IsNullOrEmpty($_.ValueData) ) -and
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
							($false -eq [string]::IsNullOrEmpty($_.ValueName)) -and
							($false -eq [string]::IsNullOrEmpty($_.ValueData) ) -and
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
				[bool]$regkeysFinished = $true -in ($RegkeysToWaitFor | Select-Object -ExpandProperty success)
			}
			elseif ($RegkeyOperator -eq "And") {
				[bool]$regkeysFinished = $false -notin ($RegkeysToWaitFor | Select-Object -ExpandProperty success)
			}
			[bool]$firstRun = $false
		}
		if (($true -eq $processesFinished) -and ($true -eq $regKeysFinished)) {
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
	.SYNOPSIS
		Monitors the presence of a specified file within a set timeout period.
	.DESCRIPTION
		This function checks for the existence of a specified file within a given time frame.
		It continuously checks for the file's existence until the timeout is reached.
		The function supports resolution of CMD environment variables in the file path.
	.PARAMETER FileName
		The file path to monitor. This parameter is mandatory.
	.PARAMETER Timeout
		The duration (in seconds) to wait for the file to appear. The default is 60 seconds.
	.EXAMPLE
		Watch-NxtFile -FileName "C:\Temp\Sources\Installer.exe"
		Monitors for 'Installer.exe' in the specified directory. Returns $true if the file appears within the default timeout period.
	.EXAMPLE
		Watch-NxtFile -FileName "C:\Temp\Sources\Installer.exe" -Timeout 120
		Monitors for 'Installer.exe' in the specified directory and waits up to 120 seconds for it to appear.
	.OUTPUTS
		System.Boolean.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$FileName,
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
				if ($true -eq $result) {
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
	.SYNOPSIS
		Monitors the removal of a specified file within a set timeout period.
	.DESCRIPTION
		This function checks for the disappearance of a specified file within a given time frame.
		It continuously monitors the file's presence until the file is removed or the timeout is reached.
		The function also supports the resolution of CMD environment variables in the file path.
	.PARAMETER FileName
		The file path to monitor for removal. This parameter is mandatory.
	.PARAMETER Timeout
		The duration (in seconds) to wait for the file to be removed. The default is 60 seconds.
	.EXAMPLE
		Watch-NxtFileIsRemoved -FileName "C:\Temp\Sources\Installer.exe"
		Monitors for the removal of 'Installer.exe' in the specified directory. Returns $true if the file is removed within the default timeout period.
	.EXAMPLE
		Watch-NxtFileIsRemoved -FileName "C:\Temp\Sources\Installer.exe" -Timeout 120
		Monitors for the removal of 'Installer.exe' in the specified directory and waits up to 120 seconds for its removal.
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
	.SYNOPSIS
		Monitors the startup of a specified process within a set timeout period, with support for WQL queries.
	.DESCRIPTION
		This function checks for the startup of a process, either by name or using a WQL query, within a specified time frame.
		It allows for custom WQL queries or simple process name monitoring, supporting wildcard characters.
		The function continuously checks for the process's presence until it starts or the timeout is reached.
	.PARAMETER ProcessName
		The name of the process or a WQL query string (a filter statement on Win32_Process) to monitor. Must include the full file name with extension.
		This parameter is mandatory. Supports wildcard characters like * and %.
	.PARAMETER Timeout
		The duration (in seconds) to wait for the process to start. The default is 60 seconds.
	.PARAMETER IsWql
		Indicates whether the ProcessName is a WQL search string. Defaults to false.
	.EXAMPLE
		Watch-NxtProcess -ProcessName "Notepad.exe"
		Monitors for the startup of Notepad.exe. Returns $true if the process starts within the default timeout period.
	.EXAMPLE
		Watch-NxtProcess -ProcessName "winword.exe" -Timeout 120
		Monitors for the startup of Microsoft Word and waits up to 120 seconds for it to start.
	.EXAMPLE
		Watch-NxtProcess -ProcessName "commandline like '%chrome.exe%'" -IsWql
		Uses a WQL query to monitor for the startup of Chrome browser.
	.OUTPUTS
		System.Boolean.
	.NOTES
		This function is part of the PSAppDeployToolkit.
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
				[bool]$result = Test-NxtProcessExists -ProcessName $ProcessName -IsWql:$IsWql

				if ($true -eq $result) {
					Write-Output $true
					return
				}
			}
			Write-Output $false
		}
		catch {
			Write-Log -Message "Failed to wait until process '$ProcessName' is started. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
			throw "Failed to wait until process '$ProcessName' is started. `n$(Resolve-Error)"
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
	.SYNOPSIS
		Monitors the termination of a specified process within a set timeout period, with support for WQL queries.
	.DESCRIPTION
		This function checks for the termination of a process, either by name or using a WQL query, within a specified time frame.
		It supports custom WQL queries (a filter statement on Win32_Process) or simple process name monitoring, including wildcard characters.
		The function continuously monitors the process's presence until it stops or the timeout is reached.
	.PARAMETER ProcessName
		The name of the process or a WQL query string to monitor for termination. Must include the full file name with extension.
		This parameter is mandatory. Supports wildcard characters like * and %.
	.PARAMETER Timeout
		The duration (in seconds) to wait for the process to stop. The default is 60 seconds.
	.PARAMETER IsWql
		Indicates whether the ProcessName is a WQL search string. Defaults to false.
	.EXAMPLE
		Watch-NxtProcessIsStopped -ProcessName "Notepad.exe"
		Monitors for the termination of Notepad.exe. Returns $true if the process stops within the default timeout period.
	.EXAMPLE
		Watch-NxtProcessIsStopped -ProcessName "winword.exe" -Timeout 120
		Monitors for the termination of Microsoft Word and waits up to 120 seconds for it to stop.
	.EXAMPLE
		Watch-NxtProcessIsStopped -ProcessName "Name = 'chrome.exe'" -IsWql
		Uses a WQL query to monitor for the termination of Chrome browser.
	.OUTPUTS
		System.Boolean.
	.NOTES
		This function is part of the PSAppDeployToolkit.
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
				[bool]$result = Test-NxtProcessExists -ProcessName $ProcessName -IsWql:$IsWql

				if ($false -eq $result) {
					Write-Output $true
					return
				}
			}
			Write-Output $false
		}
		catch {
			Write-Log -Message "Failed to wait until process '$ProcessName' is stopped. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
			throw "Failed to wait until process '$ProcessName' is stopped. `n$(Resolve-Error)"
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
	.SYNOPSIS
		Watches a specified registry key for a given duration.
	.DESCRIPTION
		This command monitors a specified registry key and checks for its existence within a defined timeout period. It is useful for scenarios where the presence of a registry key is required for certain processes or checks.
	.PARAMETER RegistryKey
		Specifies the registry key to be monitored. This parameter is mandatory.
	.PARAMETER Timeout
		Defines the timeout duration in seconds to wait for the registry key. If not specified, defaults to 60 seconds.
	.EXAMPLE
		Watch-NxtRegistryKey -RegistryKey "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
		This example monitors the specified registry key and waits up to 60 seconds to check its existence.
	.EXAMPLE
		Watch-NxtRegistryKey -RegistryKey "HKEY_CURRENT_USER\Software\MySoftware" -Timeout 120
		This example monitors the specified registry key and waits up to 120 seconds to check its existence.
	.OUTPUTS
		System.Boolean.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$RegistryKey,
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
				if ($false -eq [string]::IsNullOrEmpty($key)) {
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
	.SYNOPSIS
		Monitors the removal of a specified registry key within a set time frame.
	.DESCRIPTION
		This command checks for the disappearance of a specified registry key over a defined period. It is particularly useful in scenarios where the deletion of a registry key is a required step in a process or procedure.
	.PARAMETER RegistryKey
		Specifies the registry key to be monitored for removal. This parameter is mandatory.
	.PARAMETER Timeout
		Sets the timeout duration in seconds during which the function waits for the registry key to disappear. Defaults to 60 seconds if not specified.
	.EXAMPLE
		Watch-NxtRegistryKeyIsRemoved -RegistryKey "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
	This example waits for up to 60 seconds to check if the specified registry key is removed.
	.EXAMPLE
		Watch-NxtRegistryKeyIsRemoved -RegistryKey "HKEY_CURRENT_USER\Software\MySoftware" -Timeout 120
	In this example, the function waits for up to 120 seconds to check if the specified registry key is removed.
	.OUTPUTS
		System.Boolean.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$RegistryKey,
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
				if ($true -eq [string]::IsNullOrEmpty($key)) {
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
#region Function Write-NxtXmlNode
function Write-NxtXmlNode {
	<#
	.SYNOPSIS
	Adds a new XML node with attributes and values to an existing XML file.
	.DESCRIPTION
	This command is used to insert a new XML node, including its attributes and values, into an existing XML file. It is useful for dynamically modifying XML structures during scripting and automation processes.
	.PARAMETER XmlFilePath
	Specifies the path to the XML file where the node will be added. This parameter is mandatory.
	.PARAMETER Model
	Defines the model of the XML node to be added, including its name, attributes, and child nodes. This parameter is mandatory.
	.PARAMETER Encoding
		Specifies the encoding of the file. Optional parameter.
	.PARAMETER DefaultEncoding
		Specifies the default encoding to use if the file's encoding cannot be auto-detected. Optional parameter.
		Default value is 'UTF8withBom'.
	.EXAMPLE
	$newNode = New-Object PSADTNXT.XmlNodeModel
	$newNode.name = "item"
	$newNode.AddAttribute("oor:path", "/org.openoffice.Setup/Office/Factories/org.openoffice.Setup:Factory[com.sun.star.presentation.PresentationDocument]")
	$newNode.Child = New-Object PSADTNXT.XmlNodeModel
	$newNode.Child.name = "prop"
	$newNode.Child.AddAttribute("oor:name", "ooSetupFactoryDefaultFilter")
	$newNode.Child.AddAttribute("oor:op", "fuse")
	$newNode.Child.Child = New-Object PSADTNXT.XmlNodeModel
	$newNode.Child.Child.name = "value"
	$newNode.Child.Child.value = "Impress MS PowerPoint 2007 XML"

	Write-NxtXmlNode -XmlFilePath "C:\Test\setup.xml" -Model $newNode
	This example creates and adds a new XML node to the specified XML file like this:
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
		$Model,
		[Parameter(Mandatory = $false)]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[string]
		$Encoding,
		[Parameter(Mandatory = $false)]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[string]
		$DefaultEncoding = 'UTF8withBom'
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[hashtable]$encodingParams = @{}
			if ($false -eq [string]::IsNullOrEmpty($Encoding)) {
				$encodingParams['Encoding'] = $Encoding
			}
			if ($false -eq [string]::IsNullOrEmpty($DefaultEncoding)) {
				$encodingParams['DefaultEncoding'] = $DefaultEncoding
			}
			[System.Xml.XmlDocument]$xmlDoc = Import-NxtXmlFile @encodingParams -Path $XmlFilePath

			[scriptblock]$createXmlNode = { Param ([System.Xml.XmlDocument]$doc, [PSADTNXT.XmlNodeModel]$child)
				[System.Xml.XmlNode]$xmlNode = $doc.CreateNode("element", $child.Name, [string]::Empty)

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
				Write-Output $xmlNode
			}

			[System.Xml.XmlLinkedNode]$newNode = &$createXmlNode -Doc $xmlDoc -Child $Model
			[void]$xmlDoc.DocumentElement.AppendChild($newNode)
			Save-NxtXmlFile @encodingParams -Xml $xmlDoc -Path $XmlFilePath
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

if ($false -eq [string]::IsNullOrEmpty($scriptParentPath)) {
	Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] dot-source invoked by [$(((Get-Variable -Name MyInvocation).Value).ScriptName)]" -Source $appDeployToolkitExtName
}
else {
	Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] invoked directly" -Source $appDeployToolkitExtName
}

##*===============================================
##* END SCRIPT BODY
##*===============================================
