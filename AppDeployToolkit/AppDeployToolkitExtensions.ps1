<#
.SYNOPSIS
	This script is a template that allows you to extend the toolkit with your own custom functions.
.DESCRIPTION
	The script is automatically dot-sourced by the AppDeployToolkitMain.ps1 script.
.NOTES
	Version: ##REPLACEVERSION##
	ConfigVersion: 2023.10.31.1
    Toolkit Exit Code Ranges:
    60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
    69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
    70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.NOTES
	This script has been extensively modified by neo42 GmbH, building upon the template provided by the PowerShell App Deployment Toolkit.
	The "*-Nxt*" function name pattern is used by "neo42 GmbH" to avoid naming conflicts with the built-in functions of the toolkit.
.NOTES
	# LICENSE #
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

	# ORIGINAL COPYRIGHT #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.

	# MODIFICATION COPYRIGHT #
	Copyright (c) 2023 neo42 GmbH, Germany.
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
		Possible values include: "Ascii", "BigEndianUTF32", "Default", "String", "Default", "Unknown", "UTF7", "BigEndianUnicode", 
		"Byte", "Oem", "Unicode", "UTF32", "UTF8".
	.PARAMETER DefaultEncoding
		Specifies the encoding that should be used if the `Get-NxtFileEncoding` function is unable to detect the file's encoding.
		Possible values include: "Ascii", "BigEndianUTF32", "Default", "String", "Default", "Unknown", "UTF7", "BigEndianUnicode", 
		"Byte", "Oem", "Unicode", "UTF32", "UTF8".
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
			[bool]$groupExists = Test-NxtLocalGroupExists -GroupName $GroupName
			if ($false -eq $groupExists) {
				[System.DirectoryServices.DirectoryEntry]$objGroup = $adsiObj.Create("Group", $GroupName)
				$objGroup.SetInfo() | Out-Null
			}
			else {
				[System.DirectoryServices.DirectoryEntry]$objGroup = [ADSI]"WinNT://$COMPUTERNAME/$GroupName,group"
			}
			if (-NOT [string]::IsNullOrEmpty($Description)) {
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
	.PARAMETER MemberType
		Defines the type of the member. Valid options are "Group" or "User".
		This parameter is mandatory.
	.PARAMETER Computername
		Specifies the name of the computer where the group exists. Defaults to the name of the current computer.
	.EXAMPLE
		Add-NxtLocalGroupMember -GroupName "Administrators" -MemberName "JohnDoe" -MemberType "User"
		This example adds the local user "JohnDoe" to the "Administrators" group.
	.EXAMPLE
		Add-NxtLocalGroupMember -GroupName "Administrators" -MemberName "Managers" -MemberType "Group"
		This example adds the local group "Managers" to the "Administrators" group.
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
			[bool]$userExists = Test-NxtLocalUserExists -UserName $UserName
			if ($false -eq $userExists) {
				[System.DirectoryServices.DirectoryEntry]$objUser = $adsiObj.Create("User", $UserName)
				$objUser.SetInfo() | Out-Null
			}
			else {
				[System.DirectoryServices.DirectoryEntry]$objUser = [ADSI]"WinNT://$COMPUTERNAME/$UserName,user"
			}
			$objUser.setpassword($Password) | Out-Null
			if (-NOT [string]::IsNullOrEmpty($FullName)) {
				$objUser.Put("FullName", $FullName) | Out-Null
				$objUser.SetInfo() | Out-Null
			}
			if (-NOT [string]::IsNullOrEmpty($Description)) {
				$objUser.Put("Description", $Description) | Out-Null
				$objUser.SetInfo() | Out-Null
			}
			if ($SetPwdExpired) {
				## Reset to normal account flag ADS_UF_NORMAL_ACCOUNT
				$objUser.UserFlags = 512
				$objUser.SetInfo() | Out-Null
				## Set password expired
				$objUser.Put("PasswordExpired", 1) | Out-Null
				$objUser.SetInfo() | Out-Null
			} 
			if ($SetPwdNeverExpires) {
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
	param (
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
		$InnerText
	)
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			if ($false -eq (Test-Path -Path $FilePath)) {
				Write-Log -Message "File $FilePath does not exist" -Severity 3
				throw "File $FilePath does not exist"
			}
			[xml]$xml = [xml]::new()
			$xml.Load($FilePath)
			[string]$parentNodePath = $NodePath.Substring(0, $NodePath.LastIndexOf("/"))
			if ([string]::IsNullOrEmpty($parentNodePath)) {
				throw "The provided node root path $NodePath does not exist"
			}
			[string]$lastNodeChild = $NodePath.Substring($NodePath.LastIndexOf("/") + 1)
			# Test for Parent Node
			if ($false -eq (Test-NxtXmlNodeExists -FilePath $FilePath -NodePath $parentNodePath)) {
				Add-NxtXmlNode -FilePath $FilePath -NodePath $parentNodePath
				[xml]$xml = [xml]::new()
				$xml.Load($FilePath)
			}
			[string]$message = "Adding node $NodePath to $FilePath"
			# Create new node with the last part of the path
			[System.Xml.XmlLinkedNode]$newNode = $xml.CreateElement( $LastNodeChild )
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
			$null = $xml.SelectSingleNode($parentNodePath).AppendChild($newNode)
			$xml.Save("$FilePath")
		}
		catch {
			Write-Log -Message "Failed to add node $NodePath to $FilePath." -Severity 3 -Source ${CmdletName}
			throw $_
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion
#region Function Close-BlockExecutionWindow
function Close-BlockExecutionWindow {
	<#
	.SYNOPSIS
		Closes Block-Execution dialogues generated by the current installation.
	.DESCRIPTION
		The Close-BlockExecutionWindow function is designed to close any lingering information windows generated by block execution functionality. 
		If these windows are not closed by the end of the script, embedded graphics files may remain in use, preventing a successful cleanup. 
		This function helps to address this issue by ensuring these windows are properly closed.
	.EXAMPLE
		Close-BlockExecutionWindow
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
		$blockexecutionWindowId = (Get-Process powershell | Where-Object {"$(($_).MainWindowTitle)" -eq "$installTitle"}).Id
		if (-not [string]::IsNullOrEmpty($blockexecutionWindowId)) {
			Write-Log "The informational window of BlockExecution functionality will be closed now ..."
			## Stop-NxtProcess does not yet support Id as Parameter
			Stop-Process -Id $blockexecutionWindowId -Force
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Add-NxtParameterToCommand
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
	param (
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
		if ($Switch) {
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
	param (
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
	param (
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
		if ([string]::IsNullOrEmpty($DetectedVersionPart)) {
			$DetectedVersionPart = "0"
		}
		if ([string]::IsNullOrEmpty($TargetVersionPart)) {
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
	.PARAMETER $UserPartDir
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
		$LegacyAppRoots= @("$envProgramFiles\neoPackages", "$envProgramFilesX86\neoPackages")
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
				if ($true -eq $Is64Bit) {
                    [bool]$thisUninstallKeyToHideIs64Bit = $true
                }
                ## in case of $AppArch="*" and running on x86 system
                else {
                    [bool]$thisUninstallKeyToHideIs64Bit = $false
                }
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
			if ([string]::IsNullOrEmpty($UserPartRevision)) {
				Write-Log -Message "UserPartRevision is empty. Please define a UserPartRevision in your config. Aborting package completion." -Source ${CmdletName}
				Throw "UserPartRevision is empty. Please define a UserPartRevision in your config. Aborting package completion."
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
			$null = Copy-item -Path "$scriptDirectory\*" -Exclude "Files", "SupportFiles" -Destination "$App\$UserpartDir\" -Recurse -Force -ErrorAction Continue
			if ($true -eq (Test-Path -Path "$App\neo42-Install\Setup.cfg")){
				Copy-File -Path "$App\neo42-Install\Setup.cfg" -Destination "$App\$UserpartDir\"
			}
			Update-NxtXmlNode -FilePath "$App\$UserpartDir\$(Split-Path "$ScriptRoot" -Leaf)\$(Split-Path "$appDeployConfigFile" -Leaf)" -NodePath "/AppDeployToolkit_Config/Toolkit_Options/Toolkit_RequireAdmin" -InnerText "False"
			Update-NxtXmlNode -FilePath "$App\$UserpartDir\$(Split-Path "$ScriptRoot" -Leaf)\$(Split-Path "$appDeployConfigFile" -Leaf)" -NodePath "/AppDeployToolkit_Config/UI_Options/ShowBalloonNotifications" -InnerText "False"
			if ($true -eq (Test-Path "$App\$UserpartDir\DeployNxtApplication.exe")){
				Set-ActiveSetup -StubExePath "$App\$UserpartDir\DeployNxtApplication.exe" -Arguments "TriggerInstallUserpart" -Version $UserPartRevision -Key "$PackageGUID"
			}
			else{
				Set-ActiveSetup -StubExePath "$env:Systemroot\System32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Bypass -NoProfile -File ""$App\$UserpartDir\Deploy-Application.ps1"" TriggerInstallUserpart" -Version $UserPartRevision -Key "$PackageGUID"
			}
		}
		foreach ($oldAppFolder in $((Get-ChildItem -Path (Get-Item -Path $App).Parent.FullName | Where-Object Name -ne (Get-Item -Path $App).Name).FullName)) {
			## note: we always use the script from current application package source folder (it is basically identical in each package)
			Copy-File -Path "$ScriptRoot\Clean-Neo42AppFolder.ps1" -Destination "$oldAppFolder\"
			Start-Sleep -Seconds 1
			Execute-Process -Path powershell.exe -Parameters "-File `"$oldAppFolder\Clean-Neo42AppFolder.ps1`"" -WorkingDirectory "$oldAppFolder" -NoWait
		}
		## Cleanup legacy package folders
		foreach ($legacyAppRoot in $LegacyAppRoots){
			if ($true -eq (Test-Path -Path $legacyAppRoot ) -and [System.IO.Path]::IsPathRooted($legacyAppRoot)){
				if (Test-Path -Path $legacyAppRoot\$AppVendor){
					if (Test-Path -Path $legacyAppRoot\$AppVendor\$AppName){
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
	.PARAMETER $UserPartDir
		Defines the subpath to the UserPart directory.
		Defaults to $global:UserPartDir.
	.PARAMETER ScriptRoot
		Defines the parent directory of the script.
		Defaults to the Variable $scriptRoot populated by AppDeployToolkitMain.ps1.
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
		$ScriptRoot = $scriptRoot
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		Remove-NxtDesktopShortcuts
		Set-ActiveSetup -PurgeActiveSetupKey -Key "$PackageGUID"
		if ($true -eq $UserPartOnUninstallation) {
			if ([string]::IsNullOrEmpty($UserPartRevision)) {
				Write-Log -Message "UserPartRevision is empty. Please define a UserPartRevision in your config. Aborting package completion." -Source ${CmdletName}
				Throw "UserPartRevision is empty. Please define a UserPartRevision in your config. Aborting package completion."
			}
			## Userpart-Uninstallation: Copy all needed files to "...\SupportFiles\$UserpartDir\" and add more needed tasks per user commands to the CustomUninstallUserPart*-functions inside of main script.
			if ($true -eq (Test-Path -Path "$dirSupportFiles\$UserpartDir")) {
				Copy-File -Path "$dirSupportFiles\$UserpartDir\*" -Destination "$App\$UserpartDir\SupportFiles" -Recurse
			 }
			 else {
				 New-Folder -Path "$App\$UserpartDir\SupportFiles"
			 }
			Copy-File -Path "$ScriptRoot\$($xmlConfigFile.GetElementsByTagName('BannerIcon_Options').Icon_Filename)" -Destination "$App\$UserpartDir\"
			Copy-item -Path "$scriptDirectory\*" -Exclude "Files", "SupportFiles" -Destination "$App\$UserpartDir\" -Recurse -Force -ErrorAction Continue
			if ($true -eq (Test-Path -Path "$App\neo42-Install\Setup.cfg")){
				Copy-File -Path "$App\neo42-Install\Setup.cfg" -Destination "$App\$UserpartDir\"
			}
			Update-NxtXmlNode -FilePath "$App\$UserpartDir\$(Split-Path "$ScriptRoot" -Leaf)\$(Split-Path "$appDeployConfigFile" -Leaf)" -NodePath "/AppDeployToolkit_Config/Toolkit_Options/Toolkit_RequireAdmin" -InnerText "False"
			Update-NxtXmlNode -FilePath "$App\$UserpartDir\$(Split-Path "$ScriptRoot" -Leaf)\$(Split-Path "$appDeployConfigFile" -Leaf)" -NodePath "/AppDeployToolkit_Config/UI_Options/ShowBalloonNotifications" -InnerText "False"
			if ($true -eq (Test-Path "$App\$UserpartDir\DeployNxtApplication.exe")){
				Set-ActiveSetup -StubExePath "$App\$UserpartDir\DeployNxtApplication.exe" -Arguments "TriggerUninstallUserpart" -Version $UserPartRevision -Key "$PackageGUID.uninstall"
			}
			else{
				Set-ActiveSetup -StubExePath "$env:Systemroot\System32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Bypass -NoProfile -File `"$App\$UserpartDir\Deploy-Application.ps1`" TriggerUninstallUserpart" -Version $UserPartRevision -Key "$PackageGUID.uninstall"
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
	param (
		[Parameter(Mandatory=$true)]
		[string]$EncodedObject
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
			return $psObject
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
			Name = 'Jane';
			Details = @{
				Age = 25;
				Occupation = 'Engineer';
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
    param (
        [Parameter(Mandatory=$true)]
        [PSObject]$Object,
		[Parameter(Mandatory=$false)]
		[int]$Depth = 2
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
			return $encodedObject
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
		Defaults to the CommonStartMenuShortcutsToCopyToCommonDesktop array defined in the eo42PackageConfig.json.
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
		if ($true -eq [string]::IsNullOrEmpty($TempRootFolder)){
			Write-Log -Message "TempRootFolder variable is empty. Aborting." -Severity 3 -Source ${cmdletName}
			Throw "TempRootFolder variable is empty. Aborting."
		}
		if ($true -eq (Test-Path -Path $TempRootFolder)){
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
			if ((Get-ChildItem -Path $TempRootFolder -Force).Count -eq 0){
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
		[boolean]
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

				## If the uninstall file does not exist, restore it from $UninsBackupPath, if it exists there
				if (![System.IO.File]::Exists($bitRockInstallerSetupPath) -and ($true -eq (Test-Path -Path "$UninsBackupPath\$bitRockInstallerBackupSubfolderName\$uninsFileName"))) {
					Write-Log -Message "Uninstall file not found. Restoring it from backup..." -Source ${CmdletName}
					Copy-File -Path "$UninsBackupPath\$bitRockInstallerBackupSubfolderName\unins*.*" -Destination "$uninsFolder\"	
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
 
		[hashtable]$executeProcessSplat = @{
			Path                 = $bitRockInstallerSetupPath
			Parameters           = $argsBitRockInstaller
			WindowStyle          = 'Normal'
			ExitOnProcessFailure = $false
			PassThru             = $true
		}
        
		if ($ContinueOnError) {
			$executeProcessSplat.Add('ContinueOnError', $ContinueOnError)
		}
		[string]$ignoreExitCodes = Merge-NxtExitCodes -ExitCodeString1 $AcceptedExitCodes -ExitCodeString2 $AcceptedRebootCodes
		if (![string]::IsNullOrEmpty($ignoreExitCodes)) {
			$executeProcessSplat.Add('IgnoreExitCodes', $ignoreExitCodes)
		}
		[psobject]$executeResult = Execute-Process @executeProcessSplat
		if ($executeResult.ExitCode -in ($AcceptedRebootCodes -split ',')){
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
			If ($false -eq $result_UninstallProcess) {
				Write-Log -Message "Note: an uninstallation process was still running after the waiting period of at least 500s!" -Severity 2 -Source ${CmdletName}
			} else {
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
		Log file name or full path including it's name and file format (eg. '-Log "InstLogFile"', '-Log "UninstLog.txt"' or '-Log "$app\Install.$($global:DeploymentTimestamp).log"')
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

				## If the uninstall file does not exist, restore it from $UninsBackupPath, if it exists there
				if ( (![System.IO.File]::Exists($innoSetupPath)) -and ($true -eq (Test-Path -Path "$UninsBackupPath\$innoSetupBackupSubfolderName\unins[0-9][0-9][0-9].exe")) ) {
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
				[string]$Log = "Install_$(((Get-Item $innoSetupPath).Basename) -replace ' ',[string]::Empty)_$DeploymentTimestamp"
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
    
		[hashtable]$executeProcessSplat = @{
			Path                 = $innoSetupPath
			Parameters           = $argsInnoSetup
			WindowStyle          = 'Normal'
			ExitOnProcessFailure = $false
			PassThru             = $true
		}
        
		if ($ContinueOnError) {
			$executeProcessSplat.Add('ContinueOnError', $ContinueOnError)
		}
		[string]$ignoreExitCodes = Merge-NxtExitCodes -ExitCodeString1 $AcceptedExitCodes -ExitCodeString2 $AcceptedRebootCodes
		if (![string]::IsNullOrEmpty($ignoreExitCodes)) {
			$executeProcessSplat.Add('IgnoreExitCodes', $ignoreExitCodes)
		}
		[psobject]$executeResult = Execute-Process @executeProcessSplat
		if ($executeResult.ExitCode -in ($AcceptedRebootCodes -split ',')){
			Write-Log -Message "A custom reboot return code was detected '$($executeResult.ExitCode)' and is translated to return code '3010': Reboot required!" -Severity 2 -Source ${cmdletName}
			$executeResult.ExitCode = 3010
			Set-Variable -Name 'msiRebootDetected' -Value $true -Scope 'Script'
		}
		## Update the desktop (in case of changed or added enviroment variables)
		Update-Desktop

		## Copy uninstallation file from $uninsfolder to $UninsBackupPath after a successful installation
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
		Sets the Log Path either as Full Path or as logname
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
		[string]$AcceptedExitCodes,
		[Parameter(Mandatory = $false)]
		[ValidateSet('Idle', 'Normal', 'High', 'AboveNormal', 'BelowNormal', 'RealTime')]
		[Diagnostics.ProcessPriorityClass]$PriorityClass = 'Normal',
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$RepairFromSource = $false,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $false,
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
		[bool]$PSBoundParameters["PassThru"] = $true
		[bool]$PSBoundParameters["ExitOnProcessFailure"] = $false
		if ([string]::IsNullOrEmpty($Parameters)) {
			$null = $PSBoundParameters.Remove('Parameters')
		}
		if ([string]::IsNullOrEmpty($AddParameters)) {
			$null = $PSBoundParameters.Remove('AddParameters')
		}
		[string]$ignoreExitCodes = Merge-NxtExitCodes -ExitCodeString1 $AcceptedExitCodes -ExitCodeString2 $AcceptedRebootCodes
		if (![string]::IsNullOrEmpty($ignoreExitCodes)) {
			[string]$PSBoundParameters["IgnoreExitCodes"] = "$ignoreExitCodes"
		}
		if (![string]::IsNullOrEmpty($Log)) {
			[string]$msiLogName = ($Log | Split-Path -Leaf) -replace '\.log$',[string]::Empty
			$PSBoundParameters.add("LogName", $msiLogName )
		}
		[PSObject]$executeResult = Execute-MSI @PSBoundParameters
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
		if ($executeResult.ExitCode -in ($AcceptedRebootCodes -split ',')){
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
		[boolean]
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

				## If the uninstall file does not exist, restore it from $UninsBackupPath, if it exists there
				if (![System.IO.File]::Exists($nullsoftSetupPath) -and ($true -eq (Test-Path -Path "$UninsBackupPath\$nullsoftBackupSubfolderName\$uninsFileName"))) {
					Write-Log -Message "Uninstall file not found. Restoring it from backup..." -Source ${CmdletName}
					Copy-File -Path "$UninsBackupPath\$nullsoftBackupSubfolderName\$uninsFileName" -Destination "$uninsFolder\"	
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
 
		[hashtable]$executeProcessSplat = @{
			Path                 = $nullsoftSetupPath
			Parameters           = $argsnullsoft
			WindowStyle          = 'Normal'
			ExitOnProcessFailure = $false
			PassThru             = $true
		}
        
		if ($ContinueOnError) {
			$executeProcessSplat.Add('ContinueOnError', $ContinueOnError)
		}
		[string]$ignoreExitCodes = Merge-NxtExitCodes -ExitCodeString1 $AcceptedExitCodes -ExitCodeString2 $AcceptedRebootCodes
		if (![string]::IsNullOrEmpty($ignoreExitCodes)) {
			$executeProcessSplat.Add('IgnoreExitCodes', $ignoreExitCodes)
		}
		[psobject]$executeResult = Execute-Process @executeProcessSplat
		if ($executeResult.ExitCode -in ($AcceptedRebootCodes -split ',')){
			Write-Log -Message "A custom reboot return code was detected '$($executeResult.ExitCode)' and is translated to return code '3010': Reboot required!" -Severity 2 -Source ${cmdletName}
			$executeResult.ExitCode = 3010
			Set-Variable -Name 'msiRebootDetected' -Value $true -Scope 'Script'
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
				if ($nullsoftUninstallString.StartsWith('"')) {
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
			foreach ($varThatMustNotBeEmpty in @("PackageMachineKey", "PackageUninstallKey")){
				if ([string]::IsNullOrEmpty((Get-Variable -Name $varThatMustNotBeEmpty -ValueOnly))) {
					Write-Log -Message "$varThatMustNotBeEmpty is empty. Skipping AbortReboot. Throwing error" -Severity 3 -Source ${CmdletName}
					throw "$varThatMustNotBeEmpty is empty. Skipping AbortReboot. Throwing error"
				}
			}
			Remove-RegistryKey -Key "HKLM:\Software\$PackageMachineKey" -Recurse
			Remove-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageUninstallKey" -Recurse
			if (
				(Test-Path -Path "HKLM:Software\$EmpirumMachineKey") -and
				-not [string]::IsNullOrEmpty($EmpirumMachineKey)
				) {
				Remove-RegistryKey -Key "HKLM:\Software\$EmpirumMachineKey" -Recurse
			}
			if (
				(Test-Path -Path "HKLM:Software\Microsoft\Windows\CurrentVersion\Uninstall\$EmpirumUninstallKey") -and
				-not ([string]::IsNullOrEmpty($EmpirumUninstallKey))
				) {
				Remove-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$EmpirumUninstallKey" -Recurse
			}
			Close-BlockExecutionWindow
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
	.PARAMETER ContinueOnError
		Continue if an error is encountered. Default is: $true.
	.PARAMETER NxtTempDirectories
		Defines a list of TempFolders to be cleared.
		Defaults to $script:NxtTempDirectories defined in the AppDeployToolkitMain.
	.EXAMPLE
		Exit-NxtScriptWithError -ErrorMessage "The Installer returned the following Exit Code $someExitcode, installation failed!" -MainExitCode 69001 -PackageStatus "InternalInstallerError"
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
		$SetupCfgPathOverride = "$env:temp\$($global:Packageconfig.RegPackagesKey)\$($global:Packageconfig.PackageGUID)",
		[Parameter(Mandatory = $false)]
		[string[]]
		$NxtTempDirectories = $script:NxtTempDirectories
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
		try {
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
		if ($MainExitCode -in 0,1641,3010) {
			[int32]$MainExitCode = 70000
		}
		Clear-NxtTempFolder
		Close-BlockExecutionWindow
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
		if ($false -eq [System.IO.Path]::IsPathRooted($global:PackageConfig.AppRootFolder)){
			Throw "AppRootFolder is not a valid path. Please check your PackageConfig."
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
			if ($false -eq [string]::IsNullOrEmpty($CommonStartMenuShortcutToCopyToCommonDesktop.TargetName)){
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
		Returns the detected encoding or the specified default encoding if detection was not possible.
	.PARAMETER Path
		Specifies the path to the file for which the encoding needs to be determined. This parameter is mandatory.
	.PARAMETER DefaultEncoding
		Specifies the encoding to be returned in case the encoding could not be detected. Valid options include "Ascii", "BigEndianUTF32",
		"Default", "String", "Default", "Unknown", "UTF7", "BigEndianUnicode", "Byte", "Oem", "Unicode", "UTF32", and "UTF8".
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
		if ($null -eq $process){
			Write-Log -Message "Failed to find process with pid '$Id'." -Severity 2 -Source ${cmdletName}
			return
		} elseif ($process.ProcessId -eq $process.ParentProcessId){
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
	.PARAMETER ProcessIdsToExcludeFromRecursion
		Process IDs to exclude from the recursion. Internal use only.
	.OUTPUTS
		System.Management.ManagementObject
	.EXAMPLE
		Get-NxtProcessTree -ProcessId 1234
		Gets the process tree for process with ID 1234 including child and parent processes.
	.EXAMPLE
		Get-NxtProcessTree -ProcessId 1234 -IncludeChildProcesses $false -IncludeParentProcesses $false
		Gets the process tree for process with ID 1234 without child nor parent processes.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
    param (
        [Parameter(Mandatory=$true)]
        [int]
		$ProcessId,
        [Parameter(Mandatory=$false)]
        [bool]
		$IncludeChildProcesses = $true,
        [Parameter(Mandatory=$false)]
        [bool]
		$IncludeParentProcesses = $true,
		[Parameter(Mandatory=$false)]
		[AllowNull()]
		[int[]]
		$ProcessIdsToExcludeFromRecursion
    )
    [System.Management.ManagementObject]$process = Get-WmiObject -Query "SELECT * FROM Win32_Process WHERE ProcessId = $processId"
    if ($null -ne $process) {
        Write-Output $process
        if ($IncludeChildProcesses) {
            $childProcesses = Get-WmiObject -Query "SELECT * FROM Win32_Process WHERE ParentProcessId = $($process.ProcessId)"
            foreach ($child in $childProcesses) {
                if (
					$child.ProcessId -eq $process.ProcessId -and
					$child.ProcessId -notin $ProcessIdsToExcludeFromRecursion
				){
                    return
                }
				$ProcessIdsToExcludeFromRecursion += $process.ProcessId
                Get-NxtProcessTree $child.ProcessId -IncludeParentProcesses $false -IncludeChildProcesses $IncludeChildProcesses -ProcessIdsToExcludeFromRecursion $ProcessIdsToExcludeFromRecursion
            }
        }
        if (
			($process.ParentProcessId -ne $ProcessId) -and
			$IncludeParentProcesses -and
			$process.ParentProcessId -notin $ProcessIdsToExcludeFromRecursion
		) {
			$ProcessIdsToExcludeFromRecursion += $process.ProcessId
            Get-NxtProcessTree $process.ParentProcessId -IncludeChildProcesses $false -IncludeParentProcesses $IncludeParentProcesses -ProcessIdsToExcludeFromRecursion $ProcessIdsToExcludeFromRecursion
        }
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
				if ($MsiRebootDetected) {
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
		$ProductGUID = $global:PackageConfig.ProductGUID
	)
	if ($false -eq $RegisterPackage) {
		Write-Log -Message 'Package should not be registered. Performing an (re)installation depending on found application state...' -Source ${cmdletName}
		Write-Output $false
	}
	elseif ( 
		($true -eq $SoftMigration) -and
		-not (Test-RegistryValue -Key $PackageRegisterPath -Value 'ProductName') -and
			(
				((Get-NxtRegisteredPackage -ProductGUID $ProductGUID).count -eq 0) -or
				-not $RemovePackagesWithSameProductGUID
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
					Get-NxtCurrentDisplayVersion -UninstallKey $UninstallKey -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude
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
        [PSObject[]]$ProcessObjects,
        [Parameter(Mandatory = $false, Position = 1)]
        [Switch]$DisableLogging,
        [Parameter(Mandatory = $false)]
        [int[]]$ProcessIdsToIgnore
    )
    Begin {
        ## Get the name of this function and write header
        [String]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
    }
    Process {
        if ($processObjects -and $processObjects[0].ProcessName) {
            [string]$runningAppsCheck = $processObjects.ProcessName -join ','
            if (-not $DisableLogging) {
                Write-Log -Message "Checking for running applications: [$runningAppsCheck]" -Source ${CmdletName}
            }
			[array]$wqlProcessObjects = $processObjects | Where-Object { $_.IsWql -eq $true }
			[array]$processesFromWmi = $(
				foreach ($wqlProcessObject in $wqlProcessObjects) {
					Get-WmiObject -Class Win32_Process -Filter $wqlProcessObject.ProcessName | Select-Object name,ProcessId,@{
						n = "QueryUsed"
						e = { $wqlProcessObject.ProcessName }
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
					if ($processObject.IsWql) {
						[int]$processId = $_.Id
						[string]$queryUsed = $processObject.ProcessName
						if (($processesFromWmi | Where-Object {
							$_.ProcessId -eq $processId -and
							$_.QueryUsed -eq $queryUsed
						}).count -ne 0
							){
							$processFound = $true
						}
					}
                    elseif ($_.ProcessName -ieq $processObject.ProcessName) {
						$processFound = $true
					}
					if ($true -eq $processFound) {
                        if ($processObject.ProcessDescription) {
                            #  The description of the process provided as a parameter to the function, e.g. -ProcessName "winword=Microsoft Office Word".
                            Add-Member -InputObject $_ -MemberType 'NoteProperty' -Name 'ProcessDescription' -Value $processObject.ProcessDescription -Force -PassThru -ErrorAction 'SilentlyContinue'
                        }
                        elseif ($_.Description) {
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

            if (-not $DisableLogging) {
                if ($runningProcesses) {
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
			[hashtable]$ini = @{default=@{}}
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
			[hashtable]$ini = @{default=@{}}
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
						Value    = $value
						Comments = $commentBuffer -join "`r`n"
					}
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
#region Function Initialize-NxtAppRootFolder
function Initialize-NxtAppRootFolder {
	<#
	.SYNOPSIS
		Sets up the App Root Folder and forces predefined permissions on the folder.
	.DESCRIPTION
		This function is designed to prepare the application root directory (AppRootFolder) by verifying paths, setting appropriate permissions, and creating necessary directories. 
		It should be invoked by the 'Initialize-NxtEnvironment' function as part of a broader initialization process. 
		The function ensures that the AppRootFolder is correctly configured.

	.EXAMPLE
		Initialize-NxtAppRootFolder
		.OUPUTS
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
		[string]$invalidCharsRegex = "[$([regex]::Escape($invalidChars -join ''))]"
		if ($BaseName -match $invalidCharsRegex) {
			throw "The '$BaseName' contains invalid characters."
		}
		## Get AppRootFolderNames we have claimed from the registry
		if (Test-RegistryValue -Key "HKLM:\Software\$RegPackagesKey" -Value "AppRootFolderNames") {
			[string[]]$AppRootFolderNames = Get-RegistryKey "HKLM:\Software\$RegPackagesKey" -Value "AppRootFolderNames"
		}
		else {
			[string[]]$AppRootFolderNames = @()
		}
		[string]$appRootFolderName = foreach ($name in $AppRootFolderNames) {
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
		if ([string]::IsNullOrEmpty($appRootFolderName)){
			## Claim an ApprootFolder
			if ($false -eq (Test-Path -Path $env:ProgramData\$BaseName)) {
				New-NxtFolderWithPermissions -Path $env:ProgramData\$BaseName -FullControlPermissions BuiltinAdministratorsSid,LocalSystemSid -ReadAndExecutePermissions BuiltinUsersSid -Owner BuiltinAdministratorsSid | Out-Null
				$AppRootFolderNames += $BaseName
				Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey" -Name "AppRootFolderNames" -Value $AppRootFolderNames -Type MultiString -ContinueOnError $false
				$appRootFolderName = $BaseName
			}
			else {
				## use a foldername with a random suffix
				$randomSuffix = [System.Guid]::NewGuid().ToString().Substring(0,8)
				New-NxtFolderWithPermissions -Path $env:ProgramData\$BaseName$randomSuffix -FullControlPermissions BuiltinAdministratorsSid,LocalSystemSid -ReadAndExecutePermissions BuiltinUsersSid -Owner BuiltinAdministratorsSid | Out-Null
				$AppRootFolderNames += "$BaseName$randomSuffix"
				Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey" -Name "AppRootFolderNames" -Value $AppRootFolderNames -Type MultiString -ContinueOnError $false
				$appRootFolderName = "$BaseName$randomSuffix"
			}
		}
		if ($appRootFolderName.length -ne 0){
			Write-Output "$env:ProgramData\$appRootFolderName"
		}
		else {
			Throw "Failed to find or create AppRootFolderName"
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
		$SetupCfgPathOverride = "$env:temp\$($global:Packageconfig.RegPackagesKey)\$($global:Packageconfig.PackageGUID)",
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
		[string]$global:PackageConfig.AppRootFolder = Initialize-NxtAppRootFolder -BaseName $global:PackageConfig.AppRootFolder -RegPackagesKey $global:PackageConfig.RegPackagesKey
		$App = $ExecutionContext.InvokeCommand.ExpandString($global:PackageConfig.App)
		$SetupCfgPathOverride = "$env:temp\$($global:Packageconfig.RegPackagesKey)\$($global:Packageconfig.PackageGUID)"
		## if $App still is not valid we have to throw an error.
		if ($false -eq [System.IO.Path]::IsPathRooted($App)) {
			Write-Log -Message "$App is not a valid path. Please check your PackageConfig.json" -Severity 3 -Source ${CmdletName}
			throw "App is not set correctly. Please check your PackageConfig.json"
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
				$null = New-Item -Path "$App\neo42-Install" -ItemType Directory -Force
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
		Set-NxtSetupCfg -Path "$App\neo42-Install\setup.cfg"
		Set-NxtCustomSetupCfg -Path "$App\neo42-Install\CustomSetup.cfg"
		if (0 -ne $(Set-NxtPackageArchitecture)) {
			throw "Error during setting package architecture variables."
		}
		[string]$global:DeploymentTimestamp = Get-Date -format "yyyy-MM-dd_HH-mm-ss"
		Expand-NxtPackageConfig
		Format-NxtPackageSpecificVariables
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
				Action                        = 'Install'
				Path                          = "$InstFile"
				UninstallKeyIsDisplayName     = $UninstallKeyIsDisplayName
				UninstallKeyContainsWildCards = $UninstallKeyContainsWildCards
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
			if ([string]::IsNullOrEmpty($UninstallKey)) {
				[string]$internalInstallerMethod = [string]::Empty
				Write-Log -Message "No 'UninstallKey is set. Switch to use provided 'InstallFile' ..." -Severity 2 -Source ${cmdletName}
			}
			else {
				[string]$internalInstallerMethod = $InstallMethod
			}
			if($internalInstallerMethod -match "^Inno.*$|^Nullsoft$|^BitRock.*$|^MSI$") {
				if ($false -eq [string]::IsNullOrEmpty($AcceptedInstallExitCodes)) {
					[string]$executeNxtParams["AcceptedExitCodes"] = "$AcceptedInstallExitCodes"
				}
				if ($false -eq [string]::IsNullOrEmpty($AcceptedInstallRebootCodes))  {
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
						Path	             = "$InstFile"
						ExitOnProcessFailure = $false
						PassThru             = $true
					}
					if (![string]::IsNullOrEmpty($InstPara)) {
						[string]$executeParams["Parameters"] = "$InstPara"
					}
					[string]$ignoreExitCodes = Merge-NxtExitCodes -ExitCodeString1 $AcceptedInstallExitCodes -ExitCodeString2 $AcceptedInstallRebootCodes
					if (![string]::IsNullOrEmpty($ignoreExitCodes)) {
						[string]$ExecuteParams["IgnoreExitCodes"] = "$ignoreExitCodes"
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
			if ([string]::IsNullOrEmpty($UninstallKey)) {
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
					if ($false -eq $(Test-NxtAppIsInstalled -UninstallKey "$UninstallKey" -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -DeploymentMethod $internalInstallerMethod)) {
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
	param (
		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[string]$ExitCodeString1,
		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[string]$ExitCodeString2
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[array]$ExitCodeObj = @()
		if ($ExitCodeString1 -eq "*" -or $ExitCodeString2 -eq "*") {
			[string]$ExitCodeString = "*"
		}
		else {
			if (-not [string]::IsNullOrEmpty($ExitCodeString1)) { 
				$ExitCodeObj += $ExitCodeString1 -split ","
			}
			if (-not [string]::IsNullOrEmpty($ExitCodeString2)) { 
				$ExitCodeObj += $ExitCodeString2 -split ","
			}
			$ExitCodeObj = $ExitCodeObj | Select-Object -Unique
			[string]$ExitCodeString = $ExitCodeObj -join ","
		}
		return $ExitCodeString
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
			if (Test-Path $Path){
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
			if ($false -eq (Test-NxtFolderPermissions -Path $Path -CustomDirectorySecurity $directorySecurity)){
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
	if ($false -eq (Test-Path -Path $TempRootPath)){
		[System.IO.DirectoryInfo]$tempRootFolder = New-NxtFolderWithPermissions @nxtTempRootFolderSplat -Hidden $true
	}
	elseif($false -eq (Test-NxtFolderPermissions @nxtTempRootFolderSplat)){
		Write-Log -Message "Temp path '$TempRootPath' already exists. Recreating the folder to ensure predefined permissions!" -Severity 2 -Source ${CmdletName}
		Remove-Item -Path $TempRootPath -Recurse -Force
		[System.IO.DirectoryInfo]$tempRootFolder = New-NxtFolderWithPermissions @nxtTempRootFolderSplat -Hidden $true
	}
	$foldername=(Get-Random -InputObject((48..57 + 65..90)) -Count 3 | ForEach-Object{
		[char]$_}
	) -join ""
	[int]$countTries = 1
	while ($true -eq (Test-Path "$TempRootPath\$foldername") -and $countTries -lt 100) {
		$countTries++
		$foldername=(Get-Random -InputObject((48..57 + 65..90)) -Count 3 | ForEach-Object{
			[char]$_}
		) -join ""
	}
	if ($countTries -ge 100) {
		Write-Log -Message "Failed to create temporary folder in '$TempRootPath'. Did not find an available name." -Severity 3 -Source ${cmdletName}
		Throw "Failed to create temporary folder in '$TempRootPath'. Did not find an available name."
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
		$AttributeName = "Innertext"
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[System.Xml.XmlDocument]$xmlDoc = New-Object System.Xml.XmlDocument
			$xmlDoc.Load($XmlFilePath)
			[System.Xml.XmlNode]$selection = $xmlDoc.DocumentElement.SelectSingleNode($SingleNodeName)
			if ($selection.ChildNodes.count -gt 1){
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
		$SoftMigrationOccurred = [string]::Empty
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		Write-Log -Message "Registering package..." -Source ${cmdletName}
		try {
			Copy-File -Path "$ScriptRoot" -Destination "$App\neo42-Install\" -Recurse
			Copy-File -Path "$ScriptParentPath\Deploy-Application.ps1" -Destination "$App\neo42-Install\"
			if ($true -eq (Test-Path "$ScriptParentPath\DeployNxtApplication.exe")) {
				Copy-File -Path "$ScriptParentPath\DeployNxtApplication.exe" -Destination "$App\neo42-Install\" -ContinueOnError $true
			}
			Copy-File -Path "$global:Neo42PackageConfigPath" -Destination "$App\neo42-Install\"
			Copy-File -Path "$global:Neo42PackageConfigValidationPath" -Destination "$App\neo42-Install\"
			Copy-File -Path "$ScriptRoot\$($xmlConfigFile.GetElementsByTagName('BannerIcon_Options').Icon_Filename)" -Destination "$App\neo42-Install\"
	
			Write-Log -message "Re-write all management registry entries for the application package..." -Source ${cmdletName}
			## to prevent obsolete entries from old VBS packages
			Remove-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID"
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
			if ($true -eq (Test-Path "$App\neo42-Install\DeployNxtApplication.exe")){
				Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'UninstallString' -Value ("""$App\neo42-Install\DeployNxtApplication.exe"" uninstall")
			}
			else {
				Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'UninstallString' -Value ("""$env:Systemroot\System32\WindowsPowerShell\v1.0\powershell.exe"" -ex bypass -WindowStyle hidden -file ""$App\neo42-Install\Deploy-Application.ps1"" uninstall")
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
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'MachineKeyName' -Value $RegPackagesKey\$PackageGUID
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'NoModify' -Type 'Dword' -Value 1
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'NoRemove' -Type 'Dword' -Value $HidePackageUninstallButton
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'NoRepair' -Type 'Dword' -Value 1
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'PackageApplicationDir' -Value $App
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'PackageProductName' -Value $AppName
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'PackageRevision' -Value $AppRevision
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'PackageVersion' -Value $AppVersion
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'Publisher' -Value $AppVendor
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'SystemComponent' -Type 'Dword' -Value $HidePackageUninstallEntry
			if ($true -eq (Test-Path "$App\neo42-Install\DeployNxtApplication.exe")){
				Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'UninstallString' -Type 'ExpandString' -Value ("""$App\neo42-Install\DeployNxtApplication.exe"" uninstall")
			}
			else {
				Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'UninstallString' -Type 'ExpandString' -Value ("""$env:Systemroot\System32\WindowsPowerShell\v1.0\powershell.exe"" -ex bypass -WindowStyle hidden -file ""$App\neo42-Install\Deploy-Application.ps1"" uninstall")
			}
			Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'Installed' -Type 'Dword' -Value '1'
			if ($false -eq [string]::IsNullOrEmpty($SoftMigrationOccurred)) {
				Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -Name 'SoftMigrationOccurred' -Value $SoftMigrationOccurred
				Set-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID" -Name 'SoftMigrationOccurred' -Value $SoftMigrationOccurred
			}
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
					$skipRecursion = $true
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
		if (
			$false -eq [string]::IsNullOrEmpty($RootPathToRecurseUpTo) -and
			$false -eq $skipRecursion
		) {
			## Resolve possible relative segments in the paths 
			[string]$absolutePath = $Path | Split-Path -Parent
			[string]$absoluteRootPathToRecurseUpTo = [System.IO.Path]::GetFullPath(([System.IO.DirectoryInfo]::new($RootPathToRecurseUpTo)).FullName)
			if ($absolutePath -eq $absoluteRootPathToRecurseUpTo){
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
#region Function Remove-NxtIniValue
Function Remove-NxtIniValue {
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
        [String]$FilePath,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Section,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Key,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [Boolean]$ContinueOnError = $true
    )
    Begin {
        ## Get the name of this function and write header
        [String]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
    }
    Process {
        Try {
            Write-Log -Message "Removing INI Key: [Section = $Section] [Key = $Key]." -Source ${CmdletName}
            If (-not (Test-Path -LiteralPath $FilePath -PathType 'Leaf')) {
                Throw "File [$filePath] could not be found."
            }
            [PSADTNXT.NxtIniFile]::RemoveIniValue($Section, $Key, $FilePath)
        }
        Catch {
            Write-Log -Message "Failed to remove INI file key value. `r`n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
            If (-not $ContinueOnError) {
                Throw "Failed to remove INI file key value: $($_.Exception.Message)"
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
			[bool]$groupExists = Test-NxtLocalGroupExists -GroupName $GroupName
			if ($groupExists) {
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
	.PARAMETER AllUsers
		If this switch is defined, all users will be removed from the specified GroupName.
	.PARAMETER AllGroups
		If this switch is defined, all groups will be removed from the specified GroupName.
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
			[bool]$userExists = Test-NxtLocalUserExists -UserName $UserName
			if ($userExists) {
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
			(Get-NxtRegisteredPackage -ProductGUID $ProductGUID -InstalledState 1).PackageGUID | Where-Object {$null -ne $($_)} | ForEach-Object {
				[string]$assignedPackageGUID = $_
				## we don't remove the current package inside this function
				if ($assignedPackageGUID -ne $PackageGUID) {
					[string]$assignedPackageUninstallString = $(Get-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$assignedPackageGUID" -Value 'UninstallString')
					Write-Log -Message "Processing product member application package with 'PackageGUID' [$assignedPackageGUID]..." -Source ${CmdletName}
					if (![string]::IsNullOrEmpty($assignedPackageUninstallString)) {
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
			Action	             = 'Repair'
		}
		if ([string]::IsNullOrEmpty($UninstallKey)) {
			$repairResult.MainExitCode = 70001
			$repairResult.ErrorMessage = "No repair function executable - missing value for parameter 'UninstallKey'!"
			$repairResult.ErrorMessagePSADT = "expected function parameter 'UninstallKey' must not be empty"
			$repairResult.Success = $false
			[int]$logMessageSeverity = 3
		}
		else {
			$executeNxtParams["Path"] = (Get-NxtInstalledApplication -UninstallKey $UninstallKey -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName).ProductCode
			if ([string]::IsNullOrEmpty($executeNxtParams.Path)) {
				$repairResult.ErrorMessage = "Repair function could not run for provided parameter 'UninstallKey=$UninstallKey'. The expected msi setup of the application seems not to be installed on system!"
				$repairResult.Success = $null
				[int]$logMessageSeverity = 1
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
					[string]$executeNxtParams["AcceptedExitCodes"] = "$AcceptedRepairExitCodes"
				}
				if ($false -eq [string]::IsNullOrEmpty($AcceptedRepairRebootCodes))  {
					[string]$executeNxtParams["AcceptedRebootCodes"] = "$AcceptedRepairRebootCodes"
				}
				if ([string]::IsNullOrEmpty($RepairLogFile)) {
					## now set default path and name including retrieved ProductCode
					[string]$RepairLogFile = Join-Path -Path $RepairLogPath -ChildPath ("Repair_$($executeNxtParams.Path).$DeploymentTimestamp.log")
				}
				## parameter -RepairFromSource $true runs 'msiexec /fvomus ...'
				[PsObject]$executionResult = Execute-NxtMSI @executeNxtParams -Log "$RepairLogFile" -RepairFromSource $true
				$repairResult.ApplicationExitCode = $executionResult.ExitCode
				if ($($executionResult.ExitCode) -in ($AcceptedRepairRebootCodes -split ",")) {
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
					($false -eq $(Test-NxtAppIsInstalled -UninstallKey "$UninstallKey" -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -DeploymentMethod "MSI")) ) {
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
						Write-Log -Message "Removing dependent application package with uninstall call: '$dependentPackageUninstallString -SkipUnregister'." -Source ${CmdletName}
						cmd /c "$dependentPackageUninstallString -SkipUnregister"
						if ($LASTEXITCODE -ne 0) {
							Write-Log -Message "Removal of dependent application package failed with return code '$LASTEXITCODE'." -Severity 3 -Source ${CmdletName}
							throw "Removal of dependent application package failed."
						}
						## we must now explicitly unregister, because only an uninstall call with the '-SkipUnregister' parameter also prevents product member packages from being removed on recursive calls
						Unregister-NxtPackage -RemovePackagesWithSameProductGUID $false -PackageGUID "$($dependentPackage.GUID)" -RegPackagesKey "$RegPackagesKey"
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
			Throw "Folder '$Path' does not exist!"
		}
		if ($false -eq [string]::IsNullOrEmpty($CustomDirectorySecurity)) {
			[System.Security.AccessControl.DirectorySecurity]$directorySecurity = $CustomDirectorySecurity
		}else {
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
				$acl = Get-Acl -Path $_.FullName -ErrorAction Stop
				$acl.Access | Where-Object { !$_.IsInherited } | ForEach-Object {
					$acl.RemoveAccessRule($_) | Out-Null
				}
				# Enable inheritance
				$acl.SetAccessRuleProtection($false, $true) | Out-Null
				Set-Acl -Path $_.FullName -AclObject $acl -ErrorAction Stop | Out-Null
			}
		}
		if ($true -eq $BreakInheritance) {
			$testResult = Test-NxtFolderPermissions -Path $Path -CustomDirectorySecurity $directorySecurity
			if ($false -eq $testResult){
				Write-Log -Message "Failed to set permissions" -Severity 3 -Source ${cmdletName}
				Throw "Failed to set permissions on folder '$Path'"
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
				New-Item -ItemType File -Path $FilePath -Force | Out-Null
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
		[String]$Path,
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
		if ([System.IO.File]::Exists($Path)) {
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
	param (
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
		$InnerText
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
			Add-NxtXmlNode @addNxtXmlNodeParams
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
		This function is based on the Show-InstallationWelcome function from the PowerShell App Deployment Toolkit. It is modified to be able to show the dialogs even from session 0.
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
	.PARAMETER ApplyContinueTypeOnError
		Specifies if the ContinueType should be applied on error.
		Defaults to the corresponding value from the $global:SetupCfg object.
	.PARAMETER ScriptRoot
		Defines the parent directory of the script.
		Defaults to the Variable $scriptRoot populated by AppDeployToolkitMain.ps1.
	.PARAMETER ProcessIdToIgnore
		Defines a process id to ignore.
		Defaults to $PID
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
	.OUTPUTS
		System.Int32.
		Exit code depending on the user's response or the timeout.
	.NOTES
		The code of this function is mainly adopted from the PSAppDeployToolkit Show-InstallationWelcome function licensed under the LGPLv3.
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
		[Boolean]$MinimizeWindows = [System.Convert]::ToBoolean([System.Convert]::ToInt32($global:SetupCfg.AskKillProcesses.MINIMIZEALLWINDOWS)),
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
		[Switch]$UserCanAbort = [System.Convert]::ToBoolean([System.Convert]::ToInt32($global:SetupCfg.ASKKILLPROCESSES.ALLOWABORTBYUSER)),
		## Specifies if the ContinueType should be applied on error
		[Parameter(Mandatory = $false)]
		[Switch]$ApplyContinueTypeOnError = [System.Convert]::ToBoolean([System.Convert]::ToInt32($global:SetupCfg.ASKKILLPROCESSES.APPLYCONTINUETYPEONERROR)),
		## Specifies the script root path
		[Parameter(Mandatory = $false)]
		[string]$ScriptRoot = $scriptRoot,
		[Parameter(Mandatory = $false)]
		[int]$ProcessIdToIgnore = $PID
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
			}
		}
		if ($true -eq [string]::IsNullOrEmpty($defaultMsiExecutablesList) -and $AskKillProcessApps.Count -eq 0) {
			## prevent BlockExecution function if there is no process to kill
			$BlockExecution = $false
		}
		else {
			## Create a Process object with custom descriptions where they are provided (split on an '=' sign)
			[PSObject[]]$processObjects = @()
			foreach ($AskKillProcessApp in $AskKillProcessApps) {
				if ($AskKillProcessApp.IsWQL) {
					$processObjects += New-Object -TypeName 'PSObject' -Property @{
						ProcessName			= $AskKillProcessApp.Name
						ProcessDescription	= $AskKillProcessApp.Description
						IsWql				= $true
					}
				}
				elseif ($AskKillProcessApp.Name.Contains('=')) {
					[String[]]$ProcessSplit = $AskKillProcessApp.Name -split '='
					$processObjects += New-Object -TypeName 'PSObject' -Property @{
						ProcessName			= $ProcessSplit[0]
						ProcessDescription	= $ProcessSplit[1]
						IsWql				= $false
					}
				}
				else {
					$processObjects += New-Object -TypeName 'PSObject' -Property @{
						ProcessName        = $AskKillProcessApp.Name
						ProcessDescription = $AskKillProcessApp.Description
						IsWql				= $false
					}
				}
			}
			if ($false -eq [string]::IsNullOrEmpty($defaultMsiExecutablesList)){
				foreach ($defaultMsiExecutable in ($defaultMsiExecutablesList -split ",")) {
					$processObjects += New-Object -TypeName 'PSObject' -Property @{
						ProcessName        = $defaultMsiExecutable
						ProcessDescription = ''
						IsWql				= $false
					}
				}
			}
			
		}
		## Check Deferral history and calculate remaining deferrals
		if (($allowDefer) -or ($AllowDeferCloseApps)) {
			#  Set $allowDefer to true if $AllowDeferCloseApps is true
			$allowDefer = $true

			#  Get the deferral history from the registry
			$deferHistory = Get-DeferHistory
			$deferHistoryTimes = $deferHistory | Select-Object -ExpandProperty 'DeferTimesRemaining' -ErrorAction 'SilentlyContinue'
			$deferHistoryDeadline = $deferHistory | Select-Object -ExpandProperty 'DeferDeadline' -ErrorAction 'SilentlyContinue'

			#  Reset Switches
			$checkDeferDays = $false
			$checkDeferDeadline = $false
			if ($DeferDays -ne 0) {
				$checkDeferDays = $true
			}
			if ($DeferDeadline) {
				$checkDeferDeadline = $true
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
				if (Test-Path -LiteralPath 'variable:deferTimes') {
					Remove-Variable -Name 'deferTimes'
				}
				$DeferTimes = $null
			}
			if ($checkDeferDays -and $allowDefer) {
				if ($deferHistoryDeadline) {
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
			if ($checkDeferDeadline -and $allowDefer) {
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
		if (($deferTimes -lt 0) -and (-not $deferDeadlineUniversal)) {
			$AllowDefer = $false
		}

		[string]$promptResult = [string]::Empty
		## Prompt the user to close running applications and optionally defer if enabled
		if (-not $silent) {
			if ($forceCloseAppsCountdown -gt 0) {
				#  Keep the same variable for countdown to simplify the code:
				$closeAppsCountdown = $forceCloseAppsCountdown
				#  Change this variable to a boolean now to switch the countdown on even with deferral
				[Boolean]$forceCloseAppsCountdown = $true
			}
			elseif ($forceCountdown -gt 0) {
				#  Keep the same variable for countdown to simplify the code:
				$closeAppsCountdown = $forceCountdown
				#  Change this variable to a boolean now to switch the countdown on
				[Boolean]$forceCountdown = $true
			}
			Set-Variable -Name 'closeAppsCountdownGlobal' -Value $closeAppsCountdown -Scope 'Script'
			[int[]]$processIdsToIgnore = @()
			if ($processIdToIgnore -gt 0) {
				$processIdsToIgnore = (Get-NxtProcessTree -ProcessId $processIdToIgnore).ProcessId
			}
			while ((Get-NxtRunningProcesses -ProcessObjects $processObjects -OutVariable 'runningProcesses' -ProcessIdsToIgnore $processIdsToIgnore) -or ((-not $promptResult.Contains('Defer')) -and (-not $promptResult.Contains('Close')))) {
				[String]$runningProcessDescriptions = ($runningProcesses | Where-Object { $_.ProcessDescription } | Select-Object -ExpandProperty 'ProcessDescription') -join ','
				#  If no proccesses are running close
				if ([string]::IsNullOrEmpty($runningProcessDescriptions)) {
					break
				}
				#  Check if we need to prompt the user to defer, to defer and close apps, or not to prompt them at all
				if ($allowDefer) {
					#  If there is deferral and closing apps is allowed but there are no apps to be closed, break the while loop
					if ($AllowDeferCloseApps -and (-not $runningProcessDescriptions)) {
						break
					}
					#  Otherwise, as long as the user has not selected to close the apps or the processes are still running and the user has not selected to continue, prompt user to close running processes with deferral
					elseif ((-not $promptResult.Contains('Close')) -or (($runningProcessDescriptions) -and (-not $promptResult.Contains('Continue')))) {
						[String]$promptResult = Show-NxtWelcomePrompt -ProcessDescriptions $runningProcessDescriptions -CloseAppsCountdown $closeAppsCountdownGlobal -PersistPrompt $PersistPrompt -AllowDefer -DeferTimes $deferTimes -DeferDeadline $deferDeadlineUniversal -MinimizeWindows $MinimizeWindows -CustomText:$CustomText -TopMost $TopMost -ContinueType $ContinueType -UserCanCloseAll:$UserCanCloseAll -UserCanAbort:$UserCanAbort -ApplyContinueTypeOnError:$ApplyContinueTypeOnError -ProcessIdToIgnore $ProcessIdToIgnore
					}
				}
				#  If there is no deferral and processes are running, prompt the user to close running processes with no deferral option
				elseif (($runningProcessDescriptions) -or ($forceCountdown)) {
					[String]$promptResult = Show-NxtWelcomePrompt -ProcessDescriptions $runningProcessDescriptions -CloseAppsCountdown $closeAppsCountdownGlobal -PersistPrompt $PersistPrompt -MinimizeWindows $minimizeWindows -CustomText:$CustomText -TopMost $TopMost -ContinueType $ContinueType -UserCanCloseAll:$UserCanCloseAll -UserCanAbort:$UserCanAbort -ApplyContinueTypeOnError:$ApplyContinueTypeOnError -ProcessIdToIgnore $ProcessIdToIgnore
				}
				#  If there is no deferral and no processes running, break the while loop
				else {
					break
				}

				if ($promptResult.Contains('Cancel')) {
					Write-Log -Message 'The user selected to cancel or grace period to wait for closing processes was over...' -Source ${CmdletName}
                    
					#  Restore minimized windows
					$null = $shellApp.UndoMinimizeAll()

					Write-Output $configInstallationUIExitCode
					return
				}

				#  If the user has clicked OK, wait a few seconds for the process to terminate before evaluating the running processes again
				if ($promptResult.Contains('Continue')) {
					Write-Log -Message 'The user selected to continue...' -Source ${CmdletName}
					Start-Sleep -Seconds 2

					#  Break the while loop if there are no processes to close and the user has clicked OK to continue
					if (-not $runningProcesses) {
						break
					}
				}
				#  Force the applications to close
				elseif ($promptResult.Contains('Close')) {
					Write-Log -Message 'The user selected to force the application(s) to close...' -Source ${CmdletName}
					if (($PromptToSave) -and ($SessionZero -and (-not $IsProcessUserInteractive))) {
						Write-Log -Message 'Specified [-PromptToSave] option will not be available, because current process is running in session zero and is not interactive.' -Severity 2 -Source ${CmdletName}
					}
					# Update the process list right before closing, in case it changed
					if ($processIdToIgnore -gt 0) {
						$processIdsToIgnore = (Get-NxtProcessTree -ProcessId $processIdToIgnore).ProcessId
					}
					$runningProcesses = Get-NxtRunningProcesses -ProcessObjects $processObjects -ProcessIdsToIgnore $processIdsToIgnore
					# Close running processes
					foreach ($runningProcess in $runningProcesses) {
						[PSObject[]]$AllOpenWindowsForRunningProcess = Get-WindowTitle -GetAllWindowTitles -DisableFunctionLogging | Where-Object { $_.ParentProcess -eq $runningProcess.ProcessName }
						#  If the PromptToSave parameter was specified and the process has a window open, then prompt the user to save work if there is work to be saved when closing window
						if (($PromptToSave) -and (-not ((-not $IsProcessUserInteractive))) -and ($AllOpenWindowsForRunningProcess) -and ($runningProcess.MainWindowHandle -ne [IntPtr]::Zero)) {
							[Timespan]$PromptToSaveTimeout = New-TimeSpan -Seconds $configInstallationPromptToSave
							[Diagnostics.StopWatch]$PromptToSaveStopWatch = [Diagnostics.StopWatch]::StartNew()
							$PromptToSaveStopWatch.Reset()
							foreach ($OpenWindow in $AllOpenWindowsForRunningProcess) {
								try {
									Write-Log -Message "Stopping process [$($runningProcess.ProcessName)] with window title [$($OpenWindow.WindowTitle)] and prompt to save if there is work to be saved (timeout in [$configInstallationPromptToSave] seconds)..." -Source ${CmdletName}
									[Boolean]$IsBringWindowToFrontSuccess = [PSADT.UiAutomation]::BringWindowToFront($OpenWindow.WindowHandle)
									[Boolean]$IsCloseWindowCallSuccess = $runningProcess.CloseMainWindow()
									if (-not $IsCloseWindowCallSuccess) {
										Write-Log -Message "Failed to call the CloseMainWindow() method on process [$($runningProcess.ProcessName)] with window title [$($OpenWindow.WindowTitle)] because the main window may be disabled due to a modal dialog being shown." -Severity 3 -Source ${CmdletName}
									}
									else {
										$PromptToSaveStopWatch.Start()
										do {
											[Boolean]$IsWindowOpen = [Boolean](Get-WindowTitle -GetAllWindowTitles -DisableFunctionLogging | Where-Object { $_.WindowHandle -eq $OpenWindow.WindowHandle })
											if (-not $IsWindowOpen) {
												break
											}
											Start-Sleep -Seconds 3
										} while (($IsWindowOpen) -and ($PromptToSaveStopWatch.Elapsed -lt $PromptToSaveTimeout))
										$PromptToSaveStopWatch.Reset()
										if ($IsWindowOpen) {
											Write-Log -Message "Exceeded the [$configInstallationPromptToSave] seconds timeout value for the user to save work associated with process [$($runningProcess.ProcessName)] with window title [$($OpenWindow.WindowTitle)]." -Severity 2 -Source ${CmdletName}
										}
										else {
											Write-Log -Message "Window [$($OpenWindow.WindowTitle)] for process [$($runningProcess.ProcessName)] was successfully closed." -Source ${CmdletName}
										}
									}
								}
								catch {
									Write-Log -Message "Failed to close window [$($OpenWindow.WindowTitle)] for process [$($runningProcess.ProcessName)]. `r`n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
									continue
								}
								finally {
									$runningProcess.Refresh()
								}
							}
						}
						else {
							Write-Log -Message "Stopping process $($runningProcess.ProcessName)..." -Source ${CmdletName}
							Stop-Process -Name $runningProcess.ProcessName -Force -ErrorAction 'SilentlyContinue'
						}
					}
					if ($processIdToIgnore -gt 0) {
						$processIdsToIgnore = (Get-NxtProcessTree -ProcessId $processIdToIgnore).ProcessId
					}
					if ($runningProcesses = Get-NxtRunningProcesses -ProcessObjects $processObjects -DisableLogging -ProcessIdsToIgnore $processIdsToIgnore) {
						# Apps are still running, give them 2s to close. If they are still running, the Welcome Window will be displayed again
						Write-Log -Message 'Sleeping for 2 seconds because the processes are still not closed...' -Source ${CmdletName}
						Start-Sleep -Seconds 2
					}
				}
				#  Stop the script (if not actioned before the timeout value)
				elseif ($promptResult.Contains('Timeout')) {
					Write-Log -Message 'Installation not actioned before the timeout value.' -Source ${CmdletName}
					$BlockExecution = $false

					if (($deferTimes -ge 0) -or ($deferDeadlineUniversal)) {
						Set-DeferHistory -DeferTimesRemaining $DeferTimes -DeferDeadline $deferDeadlineUniversal
					}
					## Dispose the welcome prompt timer here because if we dispose it within the Show-WelcomePrompt function we risk resetting the timer and missing the specified timeout period
					if ($script:welcomeTimer) {
						try {
							$script:welcomeTimer.Dispose()
							$script:welcomeTimer = $null
						}
						catch {
						}
					}

					#  Restore minimized windows
					$null = $shellApp.UndoMinimizeAll()

					Write-Output $configInstallationUIExitCode
					return
				}
				#  Stop the script (user chose to defer)
				elseif ($promptResult.Contains('Defer')) {
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
		if ( ($Silent -or $deployModeSilent) -and ($processObjects.Count -ne 0) ) {
			[Array]$runningProcesses = $null
			[Array]$runningProcesses = Get-NxtRunningProcesses $processObjects
			if ($runningProcesses) {
				[String]$runningProcessDescriptions = ($runningProcesses | Where-Object { $_.ProcessDescription } | Select-Object -ExpandProperty 'ProcessDescription') -join ','
				Write-Log -Message "Force closing application(s) [$($runningProcessDescriptions)] without prompting user." -Source ${CmdletName}
				$runningProcesses.ProcessName | ForEach-Object -Process { Stop-Process -Name $_ -Force -ErrorAction 'SilentlyContinue' }
				Start-Sleep -Seconds 2
			}
		}

		## Force nsd.exe to stop if Notes is one of the required applications to close
		if (($processObjects | Select-Object -ExpandProperty 'ProcessName') -contains 'notes') {
			## Get the path where Notes is installed
			[String]$notesPath = Get-Item -LiteralPath $regKeyLotusNotes -ErrorAction 'SilentlyContinue' | Get-ItemProperty | Select-Object -ExpandProperty 'Path'

			## Ensure we aren't running as a Local System Account and Notes install directory was found
			if ((-not $IsLocalSystemAccount) -and ($notesPath)) {
				#  Get a list of all the executables in the Notes folder
				[string[]]$notesPathExes = Get-ChildItem -LiteralPath $notesPath -Filter '*.exe' -Recurse | Select-Object -ExpandProperty 'BaseName' | Sort-Object
				## Check for running Notes executables and run NSD if any are found
				$notesPathExes | ForEach-Object {
					if ((Get-Process | Select-Object -ExpandProperty 'Name') -contains $_) {
						[String]$notesNSDExecutable = Join-Path -Path $notesPath -ChildPath 'NSD.exe'
						try {
							if (Test-Path -LiteralPath $notesNSDExecutable -PathType 'Leaf' -ErrorAction 'Stop') {
								Write-Log -Message "Executing [$notesNSDExecutable] with the -kill argument..." -Source ${CmdletName}
								[Diagnostics.Process]$notesNSDProcess = Start-Process -FilePath $notesNSDExecutable -ArgumentList '-kill' -WindowStyle 'Hidden' -PassThru -ErrorAction 'SilentlyContinue'

								if (-not $notesNSDProcess.WaitForExit(10000)) {
									Write-Log -Message "[$notesNSDExecutable] did not end in a timely manner. Force terminate process." -Source ${CmdletName}
									Stop-Process -Name 'NSD' -Force -ErrorAction 'SilentlyContinue'
								}
							}
						}
						catch {
							Write-Log -Message "Failed to launch [$notesNSDExecutable]. `r`n$(Resolve-Error)" -Source ${CmdletName}
						}

						Write-Log -Message "[$notesNSDExecutable] returned exit code [$($notesNSDProcess.ExitCode)]." -Source ${CmdletName}

						#  Force NSD process to stop in case the previous command was not successful
						Stop-Process -Name 'NSD' -Force -ErrorAction 'SilentlyContinue'
					}
				}
			}

			#  Strip all Notes processes from the process list except notes.exe, because the other notes processes (e.g. notes2.exe) may be invoked by the Notes installation, so we don't want to block their execution.
			if ($notesPathExes) {
				[Array]$processesIgnoringNotesExceptions = Compare-Object -ReferenceObject ($processObjects | Select-Object -ExpandProperty 'ProcessName' | Sort-Object) -DifferenceObject $notesPathExes -IncludeEqual | Where-Object { ($_.SideIndicator -eq '<=') -or ($_.InputObject -eq 'notes') } | Select-Object -ExpandProperty 'InputObject'
				[Array]$processObjects = $processObjects | Where-Object { $processesIgnoringNotesExceptions -contains $_.ProcessName }
			}
		}

		## If block execution switch is true, call the function to block execution of these processes
		if ($true -eq $BlockExecution) {
			#  Make this variable globally available so we can check whether we need to call Unblock-AppExecution
			Set-Variable -Name 'BlockExecution' -Value $BlockExecution -Scope 'Script'
			Write-Log -Message '[-BlockExecution] parameter specified.' -Source ${CmdletName}
			if (($processObjects | Where-Object {$_.IsWql -ne $true} | Select-Object -ExpandProperty 'ProcessName').count -gt 0) {
				Write-Log -Message "Blocking execution of the following processes: $($processObjects | Where-Object {$_.IsWql -ne $true} | Select-Object -ExpandProperty 'ProcessName')" -Source ${CmdletName}
				Block-AppExecution -ProcessName ($processObjects | Where-Object {$_.IsWql -ne $true} | Select-Object -ExpandProperty 'ProcessName')
				if ($true -eq (Test-Path -Path "$dirAppDeployTemp\BlockExecution\$(Split-Path "$AppDeployConfigFile" -Leaf)")) {
					## In case of showing a message for a blocked application by ADT there has to be a valid application icon in copied temporary ADT framework
					Copy-File -Path "$ScriptRoot\$($xmlConfigFile.GetElementsByTagName('BannerIcon_Options').Icon_Filename)" -Destination "$dirAppDeployTemp\BlockExecution\AppDeployToolkitLogo.ico"
					Update-NxtXmlNode -FilePath "$dirAppDeployTemp\BlockExecution\$(Split-Path "$AppDeployConfigFile" -Leaf)" -NodePath "/AppDeployToolkit_Config/BannerIcon_Options/Icon_Filename" -InnerText "AppDeployToolkitLogo.ico"
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
Function Show-NxtWelcomePrompt {
    <#
	.SYNOPSIS
		Called by Show-InstallationWelcome to prompt the user to optionally do the following:
			1) Close the specified running applications.
			2) Provide an option to defer the installation.
			3) Show a countdown before applications are automatically closed.
        This function is based on the PSAppDeployToolkit Show-InstallationWelcome function from the PSAppDeployToolkit licensed under the LGPLv3 license.
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
		Specifies whether the window is the topmost window. Default: $true.
	.PARAMETER CustomText
		Specify whether to display a custom message specified in the XML file. Custom message must be populated for each language section in the XML.
	.PARAMETER ContinueType
		Specify if the window is automatically closed after the timeout and the further behavior can be influenced with the ContinueType.
	.PARAMETER UserCanCloseAll
		Specifies if the user can close all applications. Default: $false.
	.PARAMETER UserCanAbort
		Specifies if the user can abort the process. Default: $false.
	.PARAMETER DeploymentType
		The type of deployment that is performed.
		Defaults to the corresponding call parameter of the Deploy-Application.ps1 script.
	.PARAMETER ApplyContinueTypeOnError
		Specifies if the ContinueType should be applied in case of an error. Default: $false.
	.PARAMETER InstallTitle
		The title of the installation.
		Defaults to the corresponding call parameter of the Deploy-Application.ps1 script.
	.PARAMETER AppDeployLogoBanner
		The logo banner to display in the prompt.
		Defaults to the corresponding call parameter of the Deploy-Application.ps1 script.
	.PARAMETER AppDeployLogoBannerDark
		The dark logo banner to display in the prompt.
		Defaults to the corresponding call parameter of the Deploy-Application.ps1 script.
	.PARAMETER EnvProgramData
		The path to the ProgramData folder.
		Defaults to the corresponding call parameter of the Deploy-Application.ps1 script.
	.PARAMETER AppVendor
		The vendor of the application.
		Defaults to the corresponding call parameter of the Deploy-Application.ps1 script.
	.PARAMETER AppName
		The name of the application.
		Defaults to the corresponding call parameter of the Deploy-Application.ps1 script.
	.PARAMETER AppVersion
		The version of the application.
		Defaults to the corresponding call parameter of the Deploy-Application.ps1 script.
	.PARAMETER Logname
		The name of the log file.
		Defaults to the corresponding call parameter of the Deploy-Application.ps1 script.
	.PARAMETER ProcessIdToIgnore
		The process ID to ignore.
		Defaults to the ID of the current process $PID.
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
		The code of this function is mainly adopted from the PSAppDeployToolkit Show-InstallationWelcome function licensed under the LGPLv3 license.
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
		[Switch]$ApplyContinueTypeOnError = $false,
        [Parameter(Mandatory = $false)]
        [Switch]$UserCanCloseAll = $false,
        [Parameter(Mandatory = $false)]
        [Switch]$UserCanAbort = $false,
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
		$ProcessIdToIgnore
    )

    Begin {
        ## Get the name of this function and write header
        [String]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
    }
    Process {
		
		$contiuneTypeValue = [int]$ContinueType;
		# Convert to JSON in compressed form
		[string]$processObjectsEncoded = ConvertTo-NxtEncodedObject -Object $processObjects
		$toolkitUiPath = "$scriptRoot\CustomAppDeployToolkitUi.ps1"
		$powershellCommand = "-File `"$toolkitUiPath`" -ProcessDescriptions `"$ProcessDescriptions`" -ProcessObjectsEncoded `"$processObjectsEncoded`""
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
		if ($ProcessIdToIgnore -gt 0){
			$powershellCommand = Add-NxtParameterToCommand -Command $powershellCommand -Name "ProcessIdToIgnore" -Value $ProcessIdToIgnore
		}
		Write-Log "Searching for Sessions..." -Source ${CmdletName}
		[int]$welcomeExitCode = 1618;
		[PsObject]$activeSessions = Get-LoggedOnUser
		if((Get-Process -Id $PID).SessionId -eq 0)
		{
			if ($activeSessions.Count -gt 0)
			{
				try {
					[UInt32[]]$sessionIds = $activeSessions | ForEach-Object { $_.SessionId }
					Write-Log "Start AskKillProcessesUI for sessions $sessionIds"
					[PSADTNXT.NxtAskKillProcessesResult]$askKillProcessesResult = [PSADTNXT.SessionHelper]::StartProcessAndWaitForExitCode($powershellCommand, $sessionIds);
					$welcomeExitCode = $askKillProcessesResult.ExitCode
					[string]$logDomainName = $activeSessions | Where-Object sessionid -eq $askKillProcessesResult.SessionId | Select-Object -ExpandProperty DomainName
					[string]$logUserName = $activeSessions | Where-Object sessionid -eq $askKillProcessesResult.SessionId | Select-Object -ExpandProperty UserName
					Write-Log "ExitCode from CustomAppDeployToolkitUi.ps1:: $welcomeExitCode, User: $logDomainName\$logUserName"
				}
				catch {
					if ($true -eq $ApplyContinueTypeOnError) {
						Write-Log -Message "Failed to start CustomAppDeployToolkitUi.ps1. Applying ContinueType $contiuneTypeValue" -Severity 3 -Source ${CmdletName}
						if ($contiuneTypeValue -eq [PSADTNXT.ContinueType]::Abort) {
							$welcomeExitCode = 1002
						}
						elseif ($contiuneTypeValue -eq [PSADTNXT.ContinueType]::Continue) {
							$welcomeExitCode = 1001
						}
					}
					else {
						Write-Log -Message "Failed to start CustomAppDeployToolkitUi.ps1. Not Applying ContinueType $contiuneTypeValue `r`n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
						Throw $_
					}
				}
			}
		}
		else
		{
			$welcomeExitCode = [PSADTNXT.Extensions]::StartPowershellScriptAndWaitForExitCode($powershellCommand);
			Write-Log "ExitCode from CustomAppDeployToolkitUi.ps1:: $welcomeExitCode, User: $env:USERNAME\$env:USERDOMAIN"
		}

		[string]$returnCode = [string]::Empty

		switch ($welcomeExitCode)
		{
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
		Stops a process by name.
	.DESCRIPTION
		Wrapper of the native Stop-Process cmdlet.
	.PARAMETER Name
		Name of the process.
	.PARAMETER IsWql
		Name should be interpreted as a WQL query.
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
		[string]$Name,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[bool]$IsWql
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		Write-Log -Message "Stopping process with '$Name'..." -Source ${cmdletName}
		try {
			if ( $false -eq $IsWql ){
				[System.Diagnostics.Process[]]$processes = Get-Process -Name $Name -ErrorAction SilentlyContinue
				[int]$processCountForLogging = $processes.Count
				if ($processes.Count -ne 0) {
					Stop-Process -Name $Name -Force
				}
				## Test after 10ms if the process(es) is/are still running, if it is still in the list it is ok if it has exited
				Start-Sleep -Milliseconds 10
				$processes = Get-Process -Name $Name -ErrorAction SilentlyContinue | Where-Object { $false -eq $_.HasExited }
				if ($processes.Count -ne 0) {
					Write-Log -Message "Failed to stop process. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
				}
				else {
					Write-Log -Message "$processCountForLogging processes were successfully stopped." -Source ${cmdletName}
				}
			}
			else {
				[System.Diagnostics.Process[]]$processes = Get-CimInstance -Class Win32_Process -Filter $Name -ErrorAction Stop| ForEach-Object {
					Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue
				}
				[int]$processCountForLogging = $processes.Count
				if ($processes.Count -ne 0) {
					$processes | Stop-Process -Force
				}
				## Test after 1s if the process(es) are still running, if it is still in the list it is ok if it has exited.
				Start-Sleep -Milliseconds 10
				[System.Diagnostics.Process[]]$processes = Get-CimInstance -Class Win32_Process -Filter $Name -ErrorAction Stop | ForEach-Object {
					Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue
				} | Where-Object { $false -eq $_.HasExited }
				if ($processes.Count -ne 0) {
					Write-Log -Message "Failed to stop process. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
				}
				else {
					Write-Log -Message "$processCountForLogging processes were successfully stopped." -Source ${cmdletName}
				}
			}
		}
		catch {
			Write-Log -Message "Failed to stop process(es) with $Name. `n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
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
	.PARAMETER DeploymentType
		The type of deployment that is performed.
		Defaults to the corresponding call parameter of the Deploy-Application.ps1 script.
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
		if ("MSI" -eq $InstallMethod) {
			if ([string]::IsNullOrEmpty($DisplayVersion)) {
				Write-Log -Message "No 'DisplayVersion' provided. Processing msi setup without double check ReinstallMode for an expected msi display version!. Returning [$ReinstallMode]." -Severity 2 -Source ${cmdletName}
			}
			else {
				[PSADTNXT.NxtDisplayVersionResult]$displayVersionResult = Get-NxtCurrentDisplayVersion -UninstallKey $UninstallKey -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude
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
#region Function Test-NxtConfigVersionCompatibility
function Test-NxtConfigVersionCompatibility {
	<#
	.SYNOPSIS
		Tests if the ConfigVersion of the PackageConfig.json is equal to Deploy-Application.ps1 and AppDeployToolkitExtensions.ps1.
	.DESCRIPTION
		Tests if the ConfigVersion of the PackageConfig.json is equal to Deploy-Application.ps1 and AppDeployToolkitExtensions.ps1. Throws an error if the versions are not equal.
	.PARAMETER ConfigVersion
		Version of the config file.
		Defaults to $global:PackageConfig.ConfigVersion.
	.PARAMETER DeployApplicationPath
		Path to the Deploy-Application.ps1 file.
		Defaults to $global:DeployApplicationPath.
	.PARAMETER AppDeployToolkitExtensionsPath
		Path to the AppDeployToolkitExtensionsPath.ps1 file.
		Defaults to $global:AppDeployToolkitExtensionsPath.
	.OUTPUTS
		none.
	.EXAMPLE
		Test-NxtConfigVersionCompatibility
		Use the default values to test the version compatibility.
	.EXAMPLE
		Test-NxtConfigVersionCompatibility -ConfigVersion 2023.12.31.1 -DeployApplicationPath "C:\temp\packagepath\Deploy-Application.ps1" -AppDeployToolkitExtensionsPath "C:\temp\packagepath\AppDeploymentToolkit\AppDeployToolkitExtensions.ps1"
		Use custom values to test the version compatibility.
	.NOTES
		This is an internal function.
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
		$deployApplicationContent = Get-Content -Path $DeployApplicationPath
		$deployApplicationConfigVersion = $deployApplicationContent | Select-String -Pattern "ConfigVersion: $ConfigVersion$"
		if ([string]::IsNullOrEmpty($deployApplicationConfigVersion)) {
			Write-Log -Message "ConfigVersion: $ConfigVersion not found in $DeployApplicationPath. Please use a Deploy-Application.ps1 that matches the ConfigVersion from Packageconfig" -Severity 3 -Source ${cmdletName}
			throw "ConfigVersion: $ConfigVersion not found in $DeployApplicationPath. Please use a Deploy-Application.ps1 that matches the ConfigVersion from Packageconfig"
		}
		$appDeployToolkitExtensionsContent = Get-Content -Path $AppDeployToolkitExtensionsPath
		$appDeployToolkitExtensionsConfigVersion = $appDeployToolkitExtensionsContent | Select-String -Pattern "ConfigVersion: $ConfigVersion`$"
		if ([string]::IsNullOrEmpty($appDeployToolkitExtensionsConfigVersion)) {
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
						foreach ($subkey in $ValidationRule.$validationRuleKey.SubKeys.PSObject.Properties.Name){
							Test-NxtObjectValidation -ValidationRule $ValidationRule.$validationRuleKey.SubKeys.$subkey.SubKeys -ObjectToValidate $ObjectToValidate.$validationRuleKey.$subkey -ParentObjectName $validationRuleKey -ContinueOnError $ContinueOnError
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
#region Function Test-NxtFolderPermissions
function Test-NxtFolderPermissions {
    <#
    .SYNOPSIS
        Checks and compares the actual permissions of a specified folder against expected permissions.
    .DESCRIPTION
        The function is designed to evaluate a folder's security settings by comparing its actual permissions, owner, and other security attributes with predefined expectations.
		This function is particularly useful for anyone who need to ensure that folder permissions align with security policies or compliance standards.
    .PARAMETER Path
        Specifies the full path of the folder whose permissions are to be tested.
		This parameter is mandatory.
    .PARAMETER FullControlPermissions
        Defines the expected Full Control permissions. 
		These are compared against the actual Full Control permissions of the folder.
    .PARAMETER WritePermissions
        Specifies the expected Write permissions.
		These are compared with the folder's actual Write permissions.
    .PARAMETER ModifyPermissions
        Indicates the expected Modify permissions that the folder should have. 
		These are compared with the folder's actual Modify permissions.
    .PARAMETER ReadAndExecutePermissions
        Specifies the expected Read and Execute permissions.
		These are compared with the folder's actual Read and Execute permissions.
    .PARAMETER Owner
        Defines the expected owner of the folder as a WellKnownSidType. 
		This is compared with the actual owner of the folder.
	.PARAMETER CustomDirectorySecurity
		Allows for providing a custom DirectorySecurity object for advanced comparison. 
		If other parameters are specified, this object will be modified accordingly.
	.PARAMETER CheckIsInherited
		Indicates if the IsInherited property should be checked.
	.PARAMETER IsInherited
		Indicates if the IsInherited property should be set to true or false.
    .EXAMPLE
        Test-NxtFolderPermissions -Path "C:\Temp\MyFolder" -FullControlPermissions @([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid) -ReadAndExecutePermissions @([System.Security.Principal.WellKnownSidType]::BuiltinUsersSid) -Owner $([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid) 
        Compares the permissions and owner of "C:\Temp\MyFolder" with the specified parameters.
    .OUTPUTS
        System.Boolean.
        Returns 'True' if the folder's permissions and owner match the specified criteria. Returns 'False' if discrepancies are found.
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
		}else {
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
				@($directorySecurity.Access)|Select-Object -Property FileSystemRights,AccessControlType,IdentityReference,InheritanceFlags,PropagationFlags,@{n="IsInherited";e={$true}}
			} else {
				@($directorySecurity.Access)|Select-Object -Property FileSystemRights,AccessControlType,IdentityReference,InheritanceFlags,PropagationFlags,@{n="IsInherited";e={$false}}
			}
			) -Property $propertiesToCheck
        [array]$results = @()
        foreach ($diff in $diffs) {
            $results += [PSCustomObject]@{
                'Rule'          = $diff | Select-Object -Property $propertiesToCheck
                'SideIndicator' = $diff.SideIndicator
				'Resulttype'	= 'Permission'
            }
        }
        if ($null -ne $directorySecurity.Owner) {
            [System.Security.Principal.SecurityIdentifier]$actualOwnerSid = (New-Object System.Security.Principal.NTAccount($actualAcl.Owner)).Translate([System.Security.Principal.SecurityIdentifier])
			[System.Security.Principal.SecurityIdentifier]$expectedOwnerSid = (New-Object System.Security.Principal.NTAccount($directorySecurity.Owner)).Translate([System.Security.Principal.SecurityIdentifier])
            if ($actualOwnerSid.Value -ne $expectedOwnerSid.Value) {
                Write-Warning "Expected owner to be $Owner but found $($actualAcl.Owner)."
                $results += [PSCustomObject]@{
                    'Rule'          = "$($actualAcl.Owner)"
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
						if ($result.SideIndicator -eq "<="){
							Write-Log -Message "Found unexpected permission $($result.Rule) on $Path." -Severity 2
						}
						elseif($result.SideIndicator -eq "=>") {
							Write-Log -Message "Missing permission $($result.Rule) on $Path." -Severity 2
						}else{
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
	.DESCRIPTION
		Tests if a process exists by name or custom WQL query.
	.PARAMETER ProcessName
		Name of the process or WQL search string. 
		Must include full file name including extension.
		Supports wildcard character * and %.
	.PARAMETER IsWql
		Defines if the given ProcessName is a WQL search string.
		Defaults to $false.
	.OUTPUTS
		System.Boolean.
	.EXAMPLE
		Test-NxtProcessExists "Notepad.exe"
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
			[System.Management.ManagementBaseObject]$processes = Get-WmiObject -Query "Select * from Win32_Process Where $($wqlString)" -ErrorAction Stop | Select-Object -First 1
			if ($processes) {
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
#region Function Test-NxtStringInFile
function Test-NxtStringInFile {
	<#
    .SYNOPSIS
        Tests if a string exists in a file.
	.DESCRIPTION
		Tests if a string exists in a file. Returns $true if the string is found, $false if not.
    .PARAMETER Path
		The path to the file.
	.PARAMETER SearchString
		The string to search for. May contain a regex if ContainsRegex is set to $true.
	.PARAMETER ContainsRegex
		Indicates if the string is a regex.
		Defaults to $false.
	.PARAMETER IgnoreCase
		Indicates if the search should be case insensitive.
		Defaults to $true.
	.PARAMETER Encoding
		The encoding of the file can explicitly be set here.
	.PARAMETER DefaultEncoding
		The default encoding of the file if auto detection fails.
	.OUTPUTS
		System.Boolean.
	.EXAMPLE
		Test-NxtStringInFile -Path "C:\temp\test.txt" -SearchString "test"
		Searches for a string.
	.EXAMPLE
		Test-NxtStringInFile -Path "C:\temp\test.txt" -ContainsRegex $true -SearchString "test.*"
		Searches for a regex.
	.LINK
		https://neo42.de/psappdeploytoolkit
    #>
	param (
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
		#return false if the file does not exist
		if ($false -eq (Test-Path -Path $Path)) {
			Write-Log -Severity 3 -Message "File $Path does not exist" -Source ${cmdletName}
			throw "File $Path does not exist"
		}
		[string]$intEncoding = $Encoding
		if (!(Test-Path -Path $Path) -and ([String]::IsNullOrEmpty($intEncoding))) {
			[string]$intEncoding = "UTF8"
		}
		elseif ((Test-Path -Path $Path) -and ([String]::IsNullOrEmpty($intEncoding))) {
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
		[bool]$textFound = $false
		[hashtable]$contentParams = @{
			Path = $Path
		}
		if (![string]::IsNullOrEmpty($intEncoding)) {
			[string]$contentParams['Encoding'] = $intEncoding
		}
		[string]$content = Get-Content @contentParams -Raw
		[regex]$pattern = if ($true -eq $ContainsRegex) {
			[regex]::new($SearchString)
		}
		else {
			[regex]::new([regex]::Escape($SearchString))
		}
		if ($true -eq $IgnoreCase){
			[System.Text.RegularExpressions.RegexOptions]$options = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
		}
		else {
			[System.Text.RegularExpressions.RegexOptions]$options = [System.Text.RegularExpressions.RegexOptions]::None
		}
		[array]$regexMatches = [regex]::Matches($content, $pattern, $options)
		if ($regexMatches.Count -gt 0) {
			[bool]$textFound = $true
		}
		Write-Output $textFound
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
        Tests if a node exists in an xml file.
	.DESCRIPTION
		Tests if a node exists in an xml file, does not support xml namespaces.
    .PARAMETER FilePath
        The path to the xml file.
    .PARAMETER NodePath
        The path to the node to test.
    .PARAMETER FilterAttributes
        The attributes to Filter the node.
    .EXAMPLE
        Test-NxtXmlNodeExists -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -FilterAttributes @("name=NewNode2")
    .EXAMPLE
        Test-NxtXmlNodeExists -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3"
    .EXAMPLE
        Test-NxtXmlNodeExists -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -FilterAttributes @("name=NewNode2","other=1232")
	.OUTPUTS
		System.Boolean.
	.LINK
		https://neo42.de/psappdeploytoolkit
    #>
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$FilePath,
		[Parameter(Mandatory = $true)]
		[string]
		$NodePath,
		[Parameter(Mandatory = $false)]
		[hashtable]
		$FilterAttributes
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
		[xml]$xml = [xml]::new()
		$xml.Load($FilePath)
		[System.Xml.XmlNodeList]$nodes = $xml.SelectNodes($nodePath)
		if ($false -eq [string]::IsNullOrEmpty($FilterAttributes)) {
			foreach ($filterAttribute in $FilterAttributes.GetEnumerator()) {
				if ([string]::IsNullOrEmpty(($nodes | Where-Object { $_.GetAttribute($filterAttribute.Key) -eq $filterAttribute.Value } ))) {
					return $false
				}
			}
			return $true
		}
		else {
			if ($false -eq [string]::IsNullOrEmpty($nodes)) {
				return $true
			}
			else {
				return $false
			}
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
	.PARAMETER AppName
        Specifies the Application Name used in the registry etc.
        Defaults to the corresponding value from the PackageConfig object.
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
	.PARAMETER AcceptedUninstallRebootCodes
		Defines a list of reboot codes that will be accepted for requested reboot by called setup execution. A matching code will be translated to code '3010'.
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
	.PARAMETER DirFiles
		The directory where the files are located.
		Defaults to $dirFiles.
	.PARAMETER UninsBackupPath
		The directory where the backup files are located.
	.EXAMPLE
		Uninstall-NxtApplication
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
			if ([string]::IsNullOrEmpty($UninstallKey)) {
				Write-Log -Message "UninstallKey value NOT set. Skipping test for installed application via registry. Checking for UninstFile instead..." -Source ${CmdletName}
				if ([string]::IsNullOrEmpty($UninstFile)) {
					$uninstallResult.ErrorMessage = "Value 'UninstFile' NOT set. Uninstallation NOT executed."
					[int]$logMessageSeverity = 2
				}
				else {
					if ($false -eq [System.IO.Path]::IsPathRooted($UninstFile)){
						[string]$UninstFile = Join-Path -Path $DirFiles -ChildPath $UninstFile
					}
					if ([System.IO.File]::Exists($UninstFile)) {
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
				if ($true -eq $(Test-NxtAppIsInstalled -UninstallKey "$UninstallKey" -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -DeploymentMethod $UninstallMethod) ) {
					[bool]$appIsInstalled=$true
				}
				else {
					[bool]$appIsInstalled=$false
					$uninstallResult.ErrorMessage = "Uninstall function could not run for provided parameter 'UninstallKey=$UninstallKey'. The expected application seems not to be installed on system!"
					$uninstallResult.Success = $null
					[int]$logMessageSeverity = 1
				}
			}
			if ( ([System.IO.File]::Exists($UninstFile)) -or ($true -eq $appIsInstalled) ) {

				[hashtable]$executeNxtParams = @{
					Action                        = 'Uninstall'
					UninstallKeyIsDisplayName     = $UninstallKeyIsDisplayName
					UninstallKeyContainsWildCards = $UninstallKeyContainsWildCards
					DisplayNamesToExclude         = $DisplayNamesToExclude
				}
				if ($false -eq [string]::IsNullOrEmpty($UninstPara)) {
					if ($AppendUninstParaToDefaultParameters) {
						[string]$executeNxtParams["AddParameters"] = "$UninstPara"
					}
					else {
						[string]$executeNxtParams["Parameters"] = "$UninstPara"
					}
				}
				if ([string]::IsNullOrEmpty($UninstallKey)) {
					[string]$internalInstallerMethod = [string]::Empty
					Write-Log -Message "No 'UninstallKey is set. Switch to use provided 'InstallFile' ..." -Severity 2 -Source ${cmdletName}
				}
				else {
					[string]$internalInstallerMethod = $UninstallMethod
				}
				if($internalInstallerMethod -match "^Inno.*$|^Nullsoft$|^BitRock.*$|^MSI$") {
					if ($false -eq [string]::IsNullOrEmpty($AcceptedUninstallExitCodes)) {
						[string]$executeNxtParams["AcceptedExitCodes"] = "$AcceptedUninstallExitCodes"
					}
					if ($false -eq [string]::IsNullOrEmpty($AcceptedUninstallRebootCodes))  {
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
							Path	             = "$UninstFile"
							ExitOnProcessFailure = $false
							PassThru             = $true
						}
						if (![string]::IsNullOrEmpty($UninstPara)) {
							[string]$executeParams["Parameters"] = "$UninstPara"
						}
							[string]$ignoreExitCodes = Merge-NxtExitCodes -ExitCodeString1 $AcceptedUninstallExitCodes -ExitCodeString2 $AcceptedUninstallRebootCodes
						if (![string]::IsNullOrEmpty($ignoreExitCodes)) {
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
				if ([string]::IsNullOrEmpty($UninstallKey)) {
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
						if ($true -eq $(Test-NxtAppIsInstalled -UninstallKey "$UninstallKey" -UninstallKeyIsDisplayName $UninstallKeyIsDisplayName -UninstallKeyContainsWildCards $UninstallKeyContainsWildCards -DisplayNamesToExclude $DisplayNamesToExclude -DeploymentMethod $internalInstallerMethod)) {
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
		if ($true -eq $UninstallOld) {
			Write-Log -Message "Checking for old package installed..." -Source ${cmdletName}
			try {
				[bool]$ReturnWithError = $false
				## Check for Empirum packages under "HKLM:\Software\WOW6432Node\"
				if ($true -eq (Test-Path -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor")) {
					if ($true -eq (Test-Path -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName")) {
						[array]$appEmpirumPackageVersions = Get-ChildItem "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName"
						if (($appEmpirumPackageVersions).Count -eq 0) {
							Remove-Item -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName"
							Write-Log -Message "Deleted an empty Empirum application key: HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName" -Source ${cmdletName}
						}
						else {
							foreach ($appEmpirumPackageVersion in $appEmpirumPackageVersions) {
								if ($true -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'PackageGUID')) {
									[string]$appEmpirumPackageGUID = Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'PackageGUID'
								}
								If ( ($false -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'PackageGUID')) -or ($appEmpirumPackageGUID -ne $PackageGUID) ) {
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
											$uninstallOldResult.ApplicationExitCode = $LastExitCode
										}
										catch {
										}
										if ($true -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString')) {
											$uninstallOldResult.MainExitCode = 70001
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
							if ( ($false -eq $ReturnWithError) -and (($appEmpirumPackageVersions).Count -eq 0) -and ($true -eq (Test-Path -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName")) ) {
								Remove-Item -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName"
								$uninstallOldResult.ErrorMessage = "Deleted the now empty Empirum application key: HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor\$AppName"
								$uninstallOldResult.Success = $null
								Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
							}
						}
					}
					if ( ($false -eq $ReturnWithError) -and ((Get-ChildItem "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor").Count -eq 0) ) {
						Remove-Item -Path "HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor"
						$uninstallOldResult.ErrorMessage = "Deleted empty Empirum vendor key: HKLM:\Software\WOW6432Node\$RegPackagesKey\$AppVendor"
						$uninstallOldResult.Success = $null
						Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
					}
				}
				## Check for Empirum packages under "HKLM:\Software\"
				if ( ($false -eq $ReturnWithError) -and ($true -eq (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$AppVendor")) ) {
					if ($true -eq (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$AppVendor\$AppName")) {
						[array]$appEmpirumPackageVersions = Get-ChildItem "HKLM:\Software\$RegPackagesKey\$AppVendor\$AppName"
						if (($appEmpirumPackageVersions).Count -eq 0) {
							Remove-Item -Path "HKLM:\Software\$RegPackagesKey\$AppVendor\$AppName"
							Write-Log -Message "Deleted an empty Empirum application key: HKLM:\Software\$RegPackagesKey\$AppVendor\$AppName" -Source ${cmdletName}
						}
						else {
							foreach ($appEmpirumPackageVersion in $appEmpirumPackageVersions) {
								if ($true -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'PackageGUID')) {
									[string]$appEmpirumPackageGUID = Get-RegistryKey -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'PackageGUID'
								}
								If (($false -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'PackageGUID')) -or ($appEmpirumPackageGUID -ne $PackageGUID) ) {
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
											$uninstallOldResult.ApplicationExitCode = $LastExitCode
										}
										catch {
										}
										if ($true -eq (Test-RegistryValue -Key "$($appEmpirumPackageVersion.name)\Setup" -Value 'UninstallString')) {
											$uninstallOldResult.MainExitCode = 70001
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
							if ( ($false -eq $ReturnWithError) -and (($appEmpirumPackageVersions).Count -eq 0) -and ($true -eq (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$AppVendor\$AppName")) ) {
								Remove-Item -Path "HKLM:\Software\$RegPackagesKey\$AppVendor\$AppName"
								$uninstallOldResult.ErrorMessage = "Deleted the now empty Empirum application key: HKLM:\Software\$RegPackagesKey\$AppVendor\$AppName"
								$uninstallOldResult.Success = $null
								Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
							}
						}
					}
					if ( ($false -eq $ReturnWithError) -and ((Get-ChildItem "HKLM:\Software\$RegPackagesKey\$AppVendor").Count -eq 0) ) {
						Remove-Item -Path "HKLM:\Software\$RegPackagesKey\$AppVendor"
						$uninstallOldResult.ErrorMessage = "Deleted empty Empirum vendor key: HKLM:\Software\$RegPackagesKey\$AppVendor"
						$uninstallOldResult.Success = $null
						Write-Log -Message $($uninstallOldResult.ErrorMessage) -Source ${cmdletName}
					}
				}
				if ($false -eq $ReturnWithError) {
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
					} else {
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
					if ((Get-NxtRegisteredPackage -ProductGUID "$ProductGUID" -InstalledState 0).PackageGUID -contains "$PackageGUID") {
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
			[string]$currentGUID = [string]::Empty
			## process an old application package
			if ( ($true -eq (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$PackageGUID" -PathType 'Container')) -or
			($true -eq (Test-Path -Path "HKLM:\Software\Wow6432Node\$RegPackagesKey\$PackageGUID" -PathType 'Container')) -or
			($true -eq (Test-Path -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -PathType 'Container')) -or
			($true -eq (Test-Path -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -PathType 'Container')) ) {
				[string]$currentGUID = $PackageGUID
				if ( ($true -eq (Test-Path -Path "HKLM:\Software\Wow6432Node\$RegPackagesKey\$PackageGUID" -PathType 'Container')) -and
				(("$(Compare-NxtVersion -DetectedVersion "$(Get-RegistryKey -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID" -Value 'Version')" -TargetVersion "$AppVersion")") -eq "Update") -and
				($true -eq (Test-RegistryValue -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID" -Value 'AppPath')) ) {
					[string]$currentAppPath = (Get-RegistryKey -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID" -Value 'AppPath')
				}
				elseif ( ($true -eq (Test-Path -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$PackageGUID" -PathType 'Container')) -and
				(("$(Compare-NxtVersion -DetectedVersion "$(Get-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$currentGUID" -Value 'Version')" -TargetVersion "$AppVersion")") -eq "Update") -and
				($true -eq (Test-RegistryValue -Key "HKLM:\Software\$RegPackagesKey\$currentGUID" -Value 'AppPath')) ) {
					[string]$currentAppPath = (Get-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$currentGUID" -Value 'AppPath')
				}
				else {
					[string]$currentGUID = [string]::Empty
				}
			}
			## process old product group member
			elseif ( ($true -eq (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$ProductGUID" -PathType 'Container')) -or
			($true -eq (Test-Path -Path "HKLM:\Software\Wow6432Node\$RegPackagesKey\$ProductGUID" -PathType 'Container')) -or
			($true -eq (Test-Path -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$ProductGUID" -PathType 'Container')) -or
			($true -eq (Test-Path -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$ProductGUID" -PathType 'Container')) ) {
				[string]$currentGUID = $ProductGUID
				## retrieve AppPath for former VBS package (only here: old $PackageFamilyGUID is stored in $ProductGUID)
				if ($true -eq (Test-RegistryValue -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID" -Value 'AppPath')) {
					[string]$currentAppPath = (Get-RegistryKey -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID" -Value 'AppPath')
					if ([string]::IsNullOrEmpty($currentAppPath)) {
						[string]$currentAppPath = (Get-RegistryKey -Key "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$currentGUID" -Value 'PackageApplicationDir')
					}
				}
				elseif ($true -eq (Test-RegistryValue -Key "HKLM:\Software\$RegPackagesKey\$currentGUID" -Value 'AppPath')) {
					[string]$currentAppPath = (Get-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$currentGUID" -Value 'AppPath')
					if ([string]::IsNullOrEmpty($currentAppPath)) {
						[string]$currentAppPath = (Get-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$currentGUIDv" -Value 'PackageApplicationDir')
					}
					## for an old product member we always remove these registry keys (in case of x86 packages we do it later anyway)
					Remove-RegistryKey -Key "HKLM:\Software\$RegPackagesKey\$currentGUID"
					Remove-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$currentGUID"
				}
				else {
					[string]$currentGUID = [string]::Empty
				}
			}
			if ($false -eq [string]::IsNullOrEmpty($currentGUID)) {
				## note: the x64 uninstall registry keys are still the same as for old package and remains there if the old package should not to be uninstalled (not true for old product member packages, see above!)
				Remove-RegistryKey -Key "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID"
				Remove-RegistryKey -Key "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$currentGUID"
				if ( ($true -eq (Test-Path -Path "HKLM:\Software\Wow6432Node\$RegPackagesKey\$currentGUID" -PathType 'Container')) -or
				($true -eq (Test-Path -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$currentGUID" -PathType 'Container')) -or
				($true -eq (Test-Path -Path "HKLM:\Software\$RegPackagesKey\$currentGUID" -PathType 'Container')) -or
				($true -eq (Test-Path -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$currentGUID" -PathType 'Container')) ) {
					Write-Log -Message "Unregister of old package was incomplete! Some orphaned registry keys remain on the client." -Severity 2 -Source ${cmdletName}
				}
			}
			else {
				Write-Log -Message "No need to cleanup old package registration." -Source ${cmdletName}
			}
			if ($false -eq [string]::IsNullOrEmpty($currentAppPath)) {
				if ($true -eq (Test-Path -Path "$currentAppPath")) {
					Remove-Folder -Path "$currentAppPath\neoInstall"
					Remove-Folder -Path "$currentAppPath\neoSource"
					if ( ($true -eq (Test-Path -Path "$currentAppPath\neoInstall")) -or ($true -eq (Test-Path -Path "$currentAppPath\neoSource")) ) {
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
		Defines wether to uninstall all found application packages with same ProductGUID (product membership) assigned.
		The uninstalled application packages stay registered, when removed during installation process of current application package.
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
	.PARAMETER AppRootFolder
		Defines the root folder of the application package.
		Defaults to the corresponding value from the PackageConfig object.
	.PARAMETER AppVendor
		Defines the vendor of the application package.
		Defaults to the corresponding value from the PackageConfig object.
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
		$ScriptRoot = $scriptRoot,
		[Parameter(Mandatory = $false)]
		[string]
		$AppRootFolder = $global:PackageConfig.AppRootFolder,
		[Parameter(Mandatory = $false)]
		[string]
		$AppDeveloper = $global:PackageConfig.AppVendor
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
								Copy-File -Path "$ScriptRoot\Clean-Neo42AppFolder.ps1" -Destination "$assignedPackageGUIDAppPath\"
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
				Write-Log -Message "Cleanup registry entries and folder of package with 'PackageGUID' [$PackageGUID] only..." -Source ${cmdletName}
				if ($PackageGUID -ne $global:PackageConfig.PackageGUID) {
					[string]$App = (Get-Registrykey -Key "HKLM:\Software\$RegPackagesKey\$PackageGUID").AppPath
				}
				if (![string]::IsNullOrEmpty($App)) {
					if ($true -eq (Test-Path -Path "$App")) {
						## note: we always use the script from current application package source folder (it is basically identical in each package)
						Copy-File -Path "$ScriptRoot\Clean-Neo42AppFolder.ps1" -Destination "$App\"
						Start-Sleep -Seconds 1
						[hashtable]$executeProcessSplat = @{
							Path = 'powershell.exe'
							Parameters = "-File `"$App\Clean-Neo42AppFolder.ps1`""
							NoWait = $true
							WorkingDirectory = $env:TEMP
						}
						## we use temp es workingdirectory to avoid issues with locked directories
						if (
							$false -eq [string]::IsNullOrEmpty($AppRootFolder) -and
							$false -eq [string]::IsNullOrEmpty($AppVendor)
							){
							$executeProcessSplat["Parameters"] = Add-NxtParameterToCommand -Command $executeProcessSplat["Parameters"] -Name "RootPathToRecurseUpTo" -Value "$AppRootFolder\$AppVendor"
						}
						Execute-Process @executeProcessSplat
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
#region Function Update-NxtProcessPathVariable
function Update-NxtProcessPathVariable {
	<#
  	.DESCRIPTION
		Adds or removes a path to the processes PATH environment variable.
  	.PARAMETER AddPath
		Path to be added to the processes PATH environment variable.
  	.PARAMETER Position
		Position where the path should be added, defaults to "End".
	.PARAMETER Force
		Adds the path to the environment variable even if it already exists.
  	.PARAMETER RemovePath
		Path to be removed from the processes PATH environment variable.
  	.PARAMETER RemoveOccurences
		Defines which occurrences of the path should be removed, defaults to "All".
  	.EXAMPLE
		Update-NxtProcessPathVariable -AddPath "C:\Temp"
	.EXAMPLE
		Update-NxtProcessPathVariable -AddPath "C:\Temp" -Position "Start"
	.EXAMPLE
		Update-NxtProcessPathVariable -AddPath "C:\Temp" -Force
	.EXAMPLE
		Update-NxtProcessPathVariable -RemovePath "C:\Temp"
	.EXAMPLE
		Update-NxtProcessPathVariable -RemovePath "C:\Temp" -RemoveOccurences "First" 
	.OUTPUTS
		none.
  	.LINK
		https://neo42.de/psappdeploytoolkit
  	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Add')]
		[String]
		$AddPath,
		[Parameter(Mandatory = $false, ParameterSetName = 'Add')]
		[ValidateSet("End","Start")]
		[String]
		$Position = "End",
		[Parameter(Mandatory = $false, ParameterSetName = 'Add')]
		[switch]
		$Force = $false,
		[Parameter(Mandatory = $true, ParameterSetName = 'Remove')]
		[String]
		$RemovePath,
		[Parameter(Mandatory = $false, ParameterSetName = 'Remove')]
		[ValidateSet("All","First","Last")]
		[String]
		$RemoveOccurences = "All"
  	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		[System.Collections.ArrayList]$pathEntries = (Get-NxtProcessEnvironmentVariable -Key 'PATH').Split(';')
		if ($true -eq $AddPath){
			if ($false -eq (Test-Path -Path $AddPath)){
				Write-Log "The path '$AddPath' that will be added does not exist." -Severity 2 -Source ${cmdletName}
			}
			if ($pathEntries.toLower().TrimEnd('\') -notcontains $AddPath.ToLower().TrimEnd('\') -or $true -eq $Force){
				if ($Position -eq "End"){
					$pathEntries.Add("$AddPath")
					Write-Log "Appended '$AddPath' to the processes PATH variable." -Source ${cmdletName}
				}elseif ($Position -eq "Start"){
					$pathEntries.Reverse()
					$pathEntries.Add("$AddPath")
					$pathEntries.Reverse()
					Write-Log "Prepended '$AddPath' to the processes PATH variable." -Source ${cmdletName}
				}
				Set-NxtProcessEnvironmentVariable -Key "PATH" -Value ($pathEntries -join ";")
			} else {
				Write-Log "Path entry '$AddPath' already exists in the PATH variable. Use -Force to add it anyway." -Severity 2 -Source ${cmdletName}
			}
		} elseif ($true -eq $RemovePath){
			if ($pathEntries.toLower().TrimEnd('\') -contains $RemovePath.ToLower().TrimEnd('\')){
				if ($RemoveOccurences -eq "All"){
					[System.Collections.ArrayList]$pathEntries = $pathEntries | Where-Object { 
						$_.ToLower().TrimEnd('\') -ne $RemovePath.ToLower().TrimEnd('\') 
					}
					Write-Log "Removed all occurences of '$RemovePath' in the processes PATH variable." -Source ${cmdletName}
				} elseif($RemoveOccurences -eq "First"){
					foreach ($pathEntry in $pathEntries){
						if ($pathEntry.ToLower().TrimEnd('\') -eq $RemovePath.ToLower().TrimEnd('\')){
							$pathEntries.Remove($pathEntry)
							break
						}
					}
					Write-Log "Removed first occurence of '$RemovePath' in the processes PATH variable." -Source ${cmdletName}
				} elseif($RemoveOccurences -eq "Last"){
					$pathEntries.Reverse()
					foreach ($pathEntry in $pathEntries){
						if ($pathEntry.ToLower().TrimEnd('\') -eq $RemovePath.ToLower().TrimEnd('\')){
							$pathEntries.Remove($pathEntry)
							break
						}
					}
					$pathEntries.Reverse()
					Write-Log "Removed last occurence of '$RemovePath' in the processes PATH variable." -Source ${cmdletName}
				}
				Set-NxtProcessEnvironmentVariable -Key "PATH" -Value ($pathEntries -join ";")
			} else {
				Write-Log "Path entry '$RemovePath' does not exist in the PATH variable." -Severity 2 -Source ${cmdletName}
			}
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
		[AllowEmptyString()]
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
		if (!(Test-Path -Path $Path) -and ([String]::IsNullOrEmpty($intEncoding))) {
			[string]$intEncoding = "UTF8"
		}
		elseif ((Test-Path -Path $Path) -and ([String]::IsNullOrEmpty($intEncoding))) {
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
#region Function Update-NxtXmlNode
function Update-NxtXmlNode {
	<#
	.SYNOPSIS
		Updates an existing node
	.DESCRIPTION
		Updates an existing node in an xml file. Fails if the node does not exist. Does not support namespaces.
	.PARAMETER FilePath
		The path to the xml file
	.PARAMETER NodePath
		The path to the node to update
	.PARAMETER FilterAttributes
		The attributes to Filter the node with
	.PARAMETER Attributes
		The attributes to update
	.PARAMETER InnerText
		The value to update the node with
	.EXAMPLE
		Update-NxtXmlNode -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -Attributes @{"name"="NewNode2"} -InnerText "NewValue2"
		Sets the value of the node to "NewValue2" and the attribute "name" to "NewNode2".
	.EXAMPLE
		Update-NxtXmlNode -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -Attributes @{"name"="NewNode2"}
		Sets the attribute "name" to "NewNode2".
	.EXAMPLE
		Update-NxtXmlNode -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -Attributes @{"name"="NewNode2"} -InnerText [string]::Empty
		Sets the attribute "name" to "NewNode2" and the value of the node to an empty string.
	.EXAMPLE
		Update-NxtXmlNode -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3"
		Does nothing.
	.EXAMPLE
		Update-NxtXmlNode -FilePath .\xmlstuff.xml -NodePath "/RootNode/Settings/Settings2/SubSubSetting3" -FilterAttributes @{"name"="NewNode2"} -Attributes @{"name"="NewNode3"}
		Updates the node with the attribute "name" set to "NewNode2" to the attribute "name" set to "NewNode3".
	.OUTPUTS
		none.
  	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	param (
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
		$InnerText
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
			[xml]$xml = [xml]::new()
			$xml.Load($FilePath)
			[psobject]$nodes = $xml.SelectNodes($NodePath)
			if ($false -eq [string]::IsNullOrEmpty($FilterAttributes)) {
				foreach ($filterAttribute in $FilterAttributes.GetEnumerator()) {
					$nodes = $nodes | Where-Object { $_.GetAttribute($filterAttribute.Key) -eq $filterAttribute.Value }
				}
				Clear-Variable filterAttribute
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
			$message += "."
			Write-Log -Message $message -Source ${cmdletName}
			$xml.Save("$FilePath")
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
		Must include full file name including extension.
		Supports wildcard character * and %.
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
	.DESCRIPTION
		Checks whether a process ends within a given time based on the name or a custom WQL query.
	.PARAMETER ProcessName
		Name of the process or WQL search string.
		Must include full file name including extension.
		Supports wildcard character * and %.
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
