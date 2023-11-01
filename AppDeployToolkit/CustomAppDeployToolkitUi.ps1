<#
	.SYNOPSIS
		Called by Show-NxtInstallationWelcome to prompt the user to optionally do the following:
			1) Close the specified running applications.
			2) Provide an option to defer the installation.
			3) Show a countdown before applications are automatically closed.
        This script is based on the PSAppDeployToolkit Show-InstallationWelcome function.
        Necessary changes to make it work with the NxtDeploymentToolkit in session 0 have been made.
        This script includes mainly extracted and modified code from the PSAppDeployToolkit Licensed under LGPLv3.
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
		Specifies whether to minimize other windows when displaying prompt.
        Default: $true.
	.PARAMETER TopMost
		Specifies whether the windows is the topmost window.
        Default: $true.
	.PARAMETER CustomText
		Specify whether to display a custom message specified in the XML file. Custom message must be populated for each language section in the XML.
	.PARAMETER ContinueType
		Specify if the window is automatically closed after the timeout and the further behavior can be influenced with the ContinueType.
	.PARAMETER UserCanCloseAll
		Specifies if the user can close all applications.
        Default: $false.
	.PARAMETER UserCanAbort
		Specifies if the user can abort the process.
        Default: $false.
    .PARAMETER ProcessObjectsEncoded
        The Base64-encoded and gzip-compressed string that represents a JSON-serialized object containing the process objects to search for.
    .PARAMETER DeploymentType
        The deployment type of the application.
        Default: 'Install'.
    .PARAMETER InstallTitle
        The title of the installation.
        Default: 'Installation'.
    .PARAMETER AppDeployLogoBanner
        The logo banner displayed in the prompt.
        Default: 'AppDeployToolkitBanner.png'.
    .PARAMETER AppDeployLogoBannerDark
        The dark logo banner displayed in the prompt.
        Default: 'AppDeployToolkitBannerDark.png'.
    .PARAMETER AppVendor
        The vendor of the application.
        Default: 'Application Vendor'.
    .PARAMETER AppName
        The name of the application.
        Default: 'Application Name'.
    .PARAMETER AppVersion
        The version of the application.
        Default: 'Application Version'.
    .PARAMETER EnvProgramData
        The ProgramData environment variable.
    .PARAMETER LogName
        The name of the log file.
    .PARAMETER ProcessIdToIgnore
        The process ID to ignore the complete tree for.

	.INPUTS
		None
		You cannot pipe objects to this function.
	.OUTPUTS
		System.String
		Returns the user's selection.
	.EXAMPLE
		Show-WelcomePrompt -ProcessDescriptions 'Lotus Notes, Microsoft Word' -CloseAppsCountdown 600 -AllowDefer -DeferTimes 10 -ProcessObjectsNames "code" -ProcessObjectsDescriptions "visual studio code"
	.NOTES
		This is an internal script function and should typically not be called directly. It is used by the Show-NxtInstallationWelcome prompt to display a custom prompt.
		The code of this function is mainly adopted from the PSAppDeployToolkit https://psappdeploytoolkit.com.
		
		--- LGPL NOTICE ---
		This software includes code derived from the PSAppDeployToolkit, which is licensed under the GNU Lesser General Public License (LGPL). A copy of the LGPL should be included with this software. If not, you can access it at <http://www.gnu.org/licenses/>.
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
    [Switch]$PersistPrompt = $false,
    [Parameter(Mandatory = $false)]
    [Switch]$AllowDefer = $false,
    [Parameter(Mandatory = $false)]
    [String]$DeferTimes,
    [Parameter(Mandatory = $false)]
    [String]$DeferDeadline,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullorEmpty()]
    [Switch]$MinimizeWindows = $false,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullorEmpty()]
    [Switch]$TopMost = $false,
    [Parameter(Mandatory = $false)]
    [Switch]$CustomText = $false,
    [Parameter(Mandatory = $false)]
    [Int32]$ContinueType = 0,
    [Parameter(Mandatory = $false)]
    [Switch]$UserCanCloseAll = $false,
    [Parameter(Mandatory = $false)]
    [Switch]$UserCanAbort = $false,
    [Parameter(Mandatory = $true)]
    [string]$ProcessObjectsEncoded,
    [Parameter(Mandatory = $false)]
    [string]
    $DeploymentType,
    [Parameter(Mandatory = $false)]
    [string]
    $InstallTitle,
    [Parameter(Mandatory = $false)]
    [string]
    $AppDeployLogoBanner,
    [Parameter(Mandatory = $false)]
    [string]
    $AppDeployLogoBannerDark,
    [Parameter(Mandatory = $true)]
    [string]
    $AppVendor,
    [Parameter(Mandatory = $true)]
    [string]
    $AppName,
    [Parameter(Mandatory = $true)]
    [string]
    $AppVersion,
    [Parameter(Mandatory = $true)]
    [string]
    $EnvProgramData,
    [Parameter(Mandatory = $true)]
    [string]
    $LogName,
    [Parameter(Mandatory = $false)]
    [int]
    $ProcessIdToIgnore
)
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
#region Function Convert-RegistryPath
Function Convert-RegistryPath {
    <#
    .SYNOPSIS
        Converts the specified registry key path to a format that is compatible with built-in PowerShell cmdlets.
    .DESCRIPTION
        Converts the specified registry key path to a format that is compatible with built-in PowerShell cmdlets.
        Converts registry key hives to their full paths. Example: HKLM is converted to "Registry::HKEY_LOCAL_MACHINE".
    .PARAMETER Key
        Path to the registry key to convert (can be a registry hive or fully qualified path)
    .PARAMETER SID
        The security identifier (SID) for a user. Specifying this parameter will convert a HKEY_CURRENT_USER registry key to the HKEY_USERS\$SID format.
        Specify this parameter from the Invoke-HKCURegistrySettingsForAllUsers function to read/edit HKCU registry settings for all users on the system.
    .PARAMETER DisableFunctionLogging
        Disables logging of this function. Default: $true
    .INPUTS
        None
        You cannot pipe objects to this function.
    .OUTPUTS
        System.String
        Returns the converted registry key path.
    .EXAMPLE
        Convert-RegistryPath -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{1AD147D0-BE0E-3D6C-AC11-64F6DC4163F1}'
    .EXAMPLE
        Convert-RegistryPath -Key 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{1AD147D0-BE0E-3D6C-AC11-64F6DC4163F1}'
    .LINK
        https://psappdeploytoolkit.com
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Key,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [String]$SID,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [Boolean]$DisableFunctionLogging = $true
    )

    Begin {
        ## Get the name of this function and write header
        [String]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
    }
    Process {
        ## Convert the registry key hive to the full path, only match if at the beginning of the line
        If ($Key -match '^HKLM') {
            $Key = $Key -replace '^HKLM:\\', 'HKEY_LOCAL_MACHINE\' -replace '^HKLM:', 'HKEY_LOCAL_MACHINE\' -replace '^HKLM\\', 'HKEY_LOCAL_MACHINE\'
        }
        ElseIf ($Key -match '^HKCR') {
            $Key = $Key -replace '^HKCR:\\', 'HKEY_CLASSES_ROOT\' -replace '^HKCR:', 'HKEY_CLASSES_ROOT\' -replace '^HKCR\\', 'HKEY_CLASSES_ROOT\'
        }
        ElseIf ($Key -match '^HKCU') {
            $Key = $Key -replace '^HKCU:\\', 'HKEY_CURRENT_USER\' -replace '^HKCU:', 'HKEY_CURRENT_USER\' -replace '^HKCU\\', 'HKEY_CURRENT_USER\'
        }
        ElseIf ($Key -match '^HKU') {
            $Key = $Key -replace '^HKU:\\', 'HKEY_USERS\' -replace '^HKU:', 'HKEY_USERS\' -replace '^HKU\\', 'HKEY_USERS\'
        }
        ElseIf ($Key -match '^HKCC') {
            $Key = $Key -replace '^HKCC:\\', 'HKEY_CURRENT_CONFIG\' -replace '^HKCC:', 'HKEY_CURRENT_CONFIG\' -replace '^HKCC\\', 'HKEY_CURRENT_CONFIG\'
        }
        ElseIf ($Key -match '^HKPD') {
            $Key = $Key -replace '^HKPD:\\', 'HKEY_PERFORMANCE_DATA\' -replace '^HKPD:', 'HKEY_PERFORMANCE_DATA\' -replace '^HKPD\\', 'HKEY_PERFORMANCE_DATA\'
        }

        ## Append the PowerShell provider to the registry key path
        If ($key -notmatch '^Registry::') {
            [String]$key = "Registry::$key"
        }

        If ($PSBoundParameters.ContainsKey('SID')) {
            ## If the SID variable is specified, then convert all HKEY_CURRENT_USER key's to HKEY_USERS\$SID
            If ($key -match '^Registry::HKEY_CURRENT_USER\\') {
                $key = $key -replace '^Registry::HKEY_CURRENT_USER\\', "Registry::HKEY_USERS\$SID\"
            }
            ElseIf (-not $DisableFunctionLogging) {
                Write-Log -Message 'SID parameter specified but the registry hive of the key is not HKEY_CURRENT_USER.' -Source ${CmdletName} -Severity 2
            }
        }

        If ($Key -match '^Registry::HKEY_LOCAL_MACHINE|^Registry::HKEY_CLASSES_ROOT|^Registry::HKEY_CURRENT_USER|^Registry::HKEY_USERS|^Registry::HKEY_CURRENT_CONFIG|^Registry::HKEY_PERFORMANCE_DATA') {
            ## Check for expected key string format
            If (-not $DisableFunctionLogging) {
                Write-Log -Message "Return fully qualified registry key path [$key]." -Source ${CmdletName}
            }
            Write-Output -InputObject ($key)
        }
        Else {
            #  If key string is not properly formatted, throw an error
            Throw "Unable to detect target registry hive in string [$key]."
        }
    }
    End {
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
    }
}
#endregion
#region Function Get-LoggedOnUser
Function Get-LoggedOnUser {
    <#
.SYNOPSIS

Get session details for all local and RDP logged on users.

.DESCRIPTION

Get session details for all local and RDP logged on users using Win32 APIs. Get the following session details:
    NTAccount, SID, UserName, DomainName, SessionId, SessionName, ConnectState, IsCurrentSession, IsConsoleSession, IsUserSession, IsActiveUserSession
    IsRdpSession, IsLocalAdmin, LogonTime, IdleTime, DisconnectTime, ClientName, ClientProtocolType, ClientDirectory, ClientBuildNumber

.INPUTS

None

You cannot pipe objects to this function.

.OUTPUTS

None

This function does not return any objects.

.EXAMPLE

Get-LoggedOnUser

.NOTES

Description of ConnectState property:

Value        Description
-----        -----------
Active       A user is logged on to the session.
ConnectQuery The session is in the process of connecting to a client.
Connected    A client is connected to the session.
Disconnected The session is active, but the client has disconnected from it.
Down         The session is down due to an error.
Idle         The session is waiting for a client to connect.
Initializing The session is initializing.
Listening    The session is listening for connections.
Reset        The session is being reset.
Shadowing    This session is shadowing another session.

Description of IsActiveUserSession property:

- If a console user exists, then that will be the active user session.
- If no console user exists but users are logged in, such as on terminal servers, then the first logged-in non-console user that has ConnectState either 'Active' or 'Connected' is the active user.

Description of IsRdpSession property:
- Gets a value indicating whether the user is associated with an RDP client session.

Description of IsLocalAdmin property:
- Checks whether the user is a member of the Administrators group

.LINK

https://psappdeploytoolkit.com
#>
    [CmdletBinding()]
    Param (
    )

    Begin {
        ## Get the name of this function and write header
        [String]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
    }
    Process {
        Try {
            Write-Log -Message 'Getting session information for all logged on users.' -Source ${CmdletName}
            Write-Output -InputObject ([PSADT.QueryUser]::GetUserSessionInfo("$env:ComputerName"))
        }
        Catch {
            Write-Log -Message "Failed to get session information for all logged on users. `r`n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
        }
    }
    End {
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
    }
}
#endregion
#region Function Get-RegistryKey
Function Get-RegistryKey {
    <#
    .SYNOPSIS
        Retrieves value names and value data for a specified registry key or optionally, a specific value.
    .DESCRIPTION
        Retrieves value names and value data for a specified registry key or optionally, a specific value.
        If the registry key does not exist or contain any values, the function will return $null by default. To test for existence of a registry key path, use built-in Test-Path cmdlet.
    .PARAMETER Key
        Path of the registry key.
    .PARAMETER Value
        Value to retrieve (optional).
    .PARAMETER SID
        The security identifier (SID) for a user. Specifying this parameter will convert a HKEY_CURRENT_USER registry key to the HKEY_USERS\$SID format.
        Specify this parameter from the Invoke-HKCURegistrySettingsForAllUsers function to read/edit HKCU registry settings for all users on the system.
    .PARAMETER ReturnEmptyKeyIfExists
        Return the registry key if it exists but it has no property/value pairs underneath it. Default is: $false.
    .PARAMETER DoNotExpandEnvironmentNames
        Return unexpanded REG_EXPAND_SZ values. Default is: $false.
    .PARAMETER ContinueOnError
        Continue if an error is encountered. Default is: $true.
    .INPUTS
        None
        You cannot pipe objects to this function.
    .OUTPUTS
        System.String
        Returns the value of the registry key or value.
    .EXAMPLE
        Get-RegistryKey -Key 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{1AD147D0-BE0E-3D6C-AC11-64F6DC4163F1}'
    .EXAMPLE
        Get-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\iexplore.exe'
    .EXAMPLE
        Get-RegistryKey -Key 'HKLM:Software\Wow6432Node\Microsoft\Microsoft SQL Server Compact Edition\v3.5' -Value 'Version'
    .EXAMPLE
        Get-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Value 'Path' -DoNotExpandEnvironmentNames
        Returns %ProgramFiles%\Java instead of C:\Program Files\Java
    .EXAMPLE
        Get-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Example' -Value '(Default)'
    .LINK
        https://psappdeploytoolkit.com
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Key,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$Value,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [String]$SID,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [Switch]$ReturnEmptyKeyIfExists = $false,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [Switch]$DoNotExpandEnvironmentNames = $false,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Boolean]$ContinueOnError = $true
    )

    Begin {
        ## Get the name of this function and write header
        [String]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
    }
    Process {
        Try {
            ## If the SID variable is specified, then convert all HKEY_CURRENT_USER key's to HKEY_USERS\$SID
            If ($PSBoundParameters.ContainsKey('SID')) {
                [String]$key = Convert-RegistryPath -Key $key -SID $SID
            }
            Else {
                [String]$key = Convert-RegistryPath -Key $key
            }

            ## Check if the registry key exists
            If (-not (Test-Path -LiteralPath $key -ErrorAction 'Stop')) {
                Write-Log -Message "Registry key [$key] does not exist. Return `$null." -Severity 2 -Source ${CmdletName}
                $regKeyValue = $null
            }
            Else {
                If ($PSBoundParameters.ContainsKey('Value')) {
                    Write-Log -Message "Getting registry key [$key] value [$value]." -Source ${CmdletName}
                }
                Else {
                    Write-Log -Message "Getting registry key [$key] and all property values." -Source ${CmdletName}
                }

                ## Get all property values for registry key
                $regKeyValue = Get-ItemProperty -LiteralPath $key -ErrorAction 'Stop'
                [Int32]$regKeyValuePropertyCount = $regKeyValue | Measure-Object | Select-Object -ExpandProperty 'Count'

                ## Select requested property
                If ($PSBoundParameters.ContainsKey('Value')) {
                    #  Check if registry value exists
                    [Boolean]$IsRegistryValueExists = $false
                    If ($regKeyValuePropertyCount -gt 0) {
                        Try {
                            [string[]]$PathProperties = Get-Item -LiteralPath $Key -ErrorAction 'Stop' | Select-Object -ExpandProperty 'Property' -ErrorAction 'Stop'
                            If ($PathProperties -contains $Value) {
                                $IsRegistryValueExists = $true
                            }
                        }
                        Catch {
                        }
                    }

                    #  Get the Value (do not make a strongly typed variable because it depends entirely on what kind of value is being read)
                    If ($IsRegistryValueExists) {
                        If ($DoNotExpandEnvironmentNames) {
                            #Only useful on 'ExpandString' values
                            If ($Value -like '(Default)') {
                                $regKeyValue = $(Get-Item -LiteralPath $key -ErrorAction 'Stop').GetValue($null, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                            }
                            Else {
                                $regKeyValue = $(Get-Item -LiteralPath $key -ErrorAction 'Stop').GetValue($Value, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                            }
                        }
                        ElseIf ($Value -like '(Default)') {
                            $regKeyValue = $(Get-Item -LiteralPath $key -ErrorAction 'Stop').GetValue($null)
                        }
                        Else {
                            $regKeyValue = $regKeyValue | Select-Object -ExpandProperty $Value -ErrorAction 'SilentlyContinue'
                        }
                    }
                    Else {
                        Write-Log -Message "Registry key value [$Key] [$Value] does not exist. Return `$null." -Source ${CmdletName}
                        $regKeyValue = $null
                    }
                }
                ## Select all properties or return empty key object
                Else {
                    If ($regKeyValuePropertyCount -eq 0) {
                        If ($ReturnEmptyKeyIfExists) {
                            Write-Log -Message "No property values found for registry key. Return empty registry key object [$key]." -Source ${CmdletName}
                            $regKeyValue = Get-Item -LiteralPath $key -Force -ErrorAction 'Stop'
                        }
                        Else {
                            Write-Log -Message "No property values found for registry key. Return `$null." -Source ${CmdletName}
                            $regKeyValue = $null
                        }
                    }
                }
            }
            Write-Output -InputObject ($regKeyValue)
        }
        Catch {
            If (-not $Value) {
                Write-Log -Message "Failed to read registry key [$key]. `r`n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
                If (-not $ContinueOnError) {
                    Throw "Failed to read registry key [$key]: $($_.Exception.Message)"
                }
            }
            Else {
                Write-Log -Message "Failed to read registry key [$key] value [$value]. `r`n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
                If (-not $ContinueOnError) {
                    Throw "Failed to read registry key [$key] value [$value]: $($_.Exception.Message)"
                }
            }
        }
    }
    End {
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
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
        [int]$ProcessId,
        [Parameter(Mandatory=$false)]
        [bool]$IncludeChildProcesses = $true,
        [Parameter(Mandatory=$false)]
        [bool]$IncludeParentProcesses = $true
    )
    [System.Management.ManagementObject]$process = Get-WmiObject -Query "SELECT * FROM Win32_Process WHERE ProcessId = $processId"
    if ($null -ne $process) {
        Write-Output $process
        if ($IncludeChildProcesses) {
            $childProcesses = Get-WmiObject -Query "SELECT * FROM Win32_Process WHERE ParentProcessId = $($process.ProcessId)"
            foreach ($child in $childProcesses) {
                Get-NxtProcessTree $child.ProcessId -IncludeParentProcesses $false -IncludeChildProcesses $IncludeChildProcesses
            }
        }
        if ($process.ParentProcessId -gt 0 -and $IncludeParentProcesses) {
            Get-NxtProcessTree $process.ParentProcessId -IncludeChildProcesses $false -IncludeParentProcesses $IncludeParentProcesses
        }
    }
}
#endregion
#region Function Get-NxtRunningProcesses
Function Get-NxtRunningProcesses {
    <#
    .SYNOPSIS
        Gets the processes that are running from a custom list of process objects and also adds a property called ProcessDescription.
    .DESCRIPTION
        Gets the processes that are running from a custom list of process objects and also adds a property called ProcessDescription.
    .PARAMETER ProcessObjects
        Custom object containing the process objects to search for. If not supplied, the function just returns $null
    .PARAMETER DisableLogging
        Disables function logging
	.PARAMETER ProcessIdsToIgnore
        The process ID to ignore the complete tree for.
    .INPUTS
        None
        You cannot pipe objects to this function.
    .OUTPUTS
        Syste.Boolean.
        Rettuns $true if the process is running, otherwise $false.
    .EXAMPLE
        Get-NxtRunningProcesses -ProcessObjects $ProcessObjects
    .NOTES
        This is an internal script function and should typically not be called directly.
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
        If ($processObjects -and $processObjects[0].ProcessName) {
            [String]$runningAppsCheck = $processObjects.ProcessName -join ','
            If (-not $DisableLogging) {
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
                ForEach ($processObject in $processObjects) {
					[bool]$processFound = $false
                    if ($ProcessIdsToIgnore -contains $_.Id) {
                        continue
                    }
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
                    elseIf ($_.ProcessName -ieq $processObject.ProcessName) {
						$processFound = $true
					}
					if ($true -eq $processFound) {
                        If ($processObject.ProcessDescription) {
                            #  The description of the process provided as a Parameter to the function, e.g. -ProcessName "winword=Microsoft Office Word".
                            Add-Member -InputObject $_ -MemberType 'NoteProperty' -Name 'ProcessDescription' -Value $processObject.ProcessDescription -Force -PassThru -ErrorAction 'SilentlyContinue'
                        }
                        ElseIf ($_.Description) {
                            #  If the process already has a description field specified, then use it
                            Add-Member -InputObject $_ -MemberType 'NoteProperty' -Name 'ProcessDescription' -Value $_.Description -Force -PassThru -ErrorAction 'SilentlyContinue'
                        }
                        Else {
                            #  Fall back on the process name if no description is provided by the process or as a parameter to the function
                            Add-Member -InputObject $_ -MemberType 'NoteProperty' -Name 'ProcessDescription' -Value $_.ProcessName -Force -PassThru -ErrorAction 'SilentlyContinue'
                        }
                        Write-Output -InputObject ($true)
                        Return
                    }
                }

                Write-Output -InputObject ($false)
                Return
            }
            ## Get all running processes and escape special characters. Match against the process names to search for to find running processes.
            [Diagnostics.Process[]]$runningProcesses = Get-Process | Where-Object -FilterScript $whereObjectFilter | Sort-Object -Property 'ProcessName'

            If (-not $DisableLogging) {
                If ($runningProcesses) {
                    [String]$runningProcessList = ($runningProcesses.ProcessName | Select-Object -Unique) -join ','
                    Write-Log -Message "The following processes are running: [$runningProcessList]." -Source ${CmdletName}
                }
                Else {
                    Write-Log -Message 'Specified applications are not running.' -Source ${CmdletName}
                }
            }
            Write-Output -InputObject ($runningProcesses)
        }
        Else {
            Write-Output -InputObject ($null)
        }
    }
    End {
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
    }
}
#endregion
#region Function Get-WindowTitle
Function Get-WindowTitle {
    <#
    .SYNOPSIS
        Search for an open window title and return details about the window.
    .DESCRIPTION
        Search for a window title. If window title searched for returns more than one result, then details for each window will be displayed.
        Returns the following properties for each window: WindowTitle, WindowHandle, ParentProcess, ParentProcessMainWindowHandle, ParentProcessId.
        Function does not work in SYSTEM context unless launched with "psexec.exe -s -i" to run it as an interactive process under the SYSTEM account.
    .PARAMETER WindowTitle
        The title of the application window to search for using regex matching.
    .PARAMETER GetAllWindowTitles
        Get titles for all open windows on the system.
    .PARAMETER DisableFunctionLogging
        Disables logging messages to the script log file.
    .INPUTS
        None
        You cannot pipe objects to this function.
    .OUTPUTS
        System.Management.Automation.PSObject
        Returns a PSObject with the following properties: WindowTitle, WindowHandle, ParentProcess, ParentProcessMainWindowHandle, ParentProcessId.
    .EXAMPLE
        Get-WindowTitle -WindowTitle 'Microsoft Word'
        Gets details for each window that has the words "Microsoft Word" in the title.
    .EXAMPLE
        Get-WindowTitle -GetAllWindowTitles
        Gets details for all windows with a title.
    .EXAMPLE
        Get-WindowTitle -GetAllWindowTitles | Where-Object { $_.ParentProcess -eq 'WINWORD' }
        Get details for all windows belonging to Microsoft Word process with name "WINWORD".
    .LINK
        https://psappdeploytoolkit.com
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = 'SearchWinTitle')]
        [AllowEmptyString()]
        [String]$WindowTitle,
        [Parameter(Mandatory = $true, ParameterSetName = 'GetAllWinTitles')]
        [ValidateNotNullorEmpty()]
        [Switch]$GetAllWindowTitles = $false
    )

    Begin {
        ## Get the name of this function and write header
        [String]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
    }
    Process {
        Try {
            If ($PSCmdlet.ParameterSetName -eq 'SearchWinTitle') {
                If (-not $DisableFunctionLogging) {
                    Write-Log -Message "Finding open window title(s) [$WindowTitle] using regex matching." -Source ${CmdletName}
                }
            }
            ElseIf ($PSCmdlet.ParameterSetName -eq 'GetAllWinTitles') {
                If (-not $DisableFunctionLogging) {
                    Write-Log -Message 'Finding all open window title(s).' -Source ${CmdletName}
                }
            }

            ## Get all window handles for visible windows
            [IntPtr[]]$VisibleWindowHandles = [PSADT.UiAutomation]::EnumWindows() | Where-Object { [PSADT.UiAutomation]::IsWindowVisible($_) }

            ## Discover details about each visible window that was discovered
            ForEach ($VisibleWindowHandle in $VisibleWindowHandles) {
                If (-not $VisibleWindowHandle) {
                    Continue
                }
                ## Get the window title
                [String]$VisibleWindowTitle = [PSADT.UiAutomation]::GetWindowText($VisibleWindowHandle)
                If ($VisibleWindowTitle) {
                    ## Get the process that spawned the window
                    [Diagnostics.Process]$Process = Get-Process -ErrorAction 'Stop' | Where-Object { $_.Id -eq [PSADT.UiAutomation]::GetWindowThreadProcessId($VisibleWindowHandle) }
                    If ($Process) {
                        ## Build custom object with details about the window and the process
                        [PSObject]$VisibleWindow = New-Object -TypeName 'PSObject' -Property @{
                            WindowTitle                   = $VisibleWindowTitle
                            WindowHandle                  = $VisibleWindowHandle
                            ParentProcess                 = $Process.ProcessName
                            ParentProcessMainWindowHandle = $Process.MainWindowHandle
                            ParentProcessId               = $Process.Id
                        }

                        ## Only save/return the window and process details which match the search criteria
                        If ($PSCmdlet.ParameterSetName -eq 'SearchWinTitle') {
                            $MatchResult = $VisibleWindow.WindowTitle -match $WindowTitle
                            If ($MatchResult) {
                                [PSObject[]]$VisibleWindows += $VisibleWindow
                            }
                        }
                        ElseIf ($PSCmdlet.ParameterSetName -eq 'GetAllWinTitles') {
                            [PSObject[]]$VisibleWindows += $VisibleWindow
                        }
                    }
                }
            }
        }
        Catch {
            If (-not $DisableFunctionLogging) {
                Write-Log -Message "Failed to get requested window title(s). `r`n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
            }
        }
    }
    End {
        Write-Output -InputObject ($VisibleWindows)
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
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
#region Function Resolve-Error
Function Resolve-Error {
    <#
    .SYNOPSIS
        Enumerate error record details.
    .DESCRIPTION
        Enumerate an error record, or a collection of error record, properties. By default, the details for the last error will be enumerated.
    .PARAMETER ErrorRecord
        The error record to resolve. The default error record is the latest one: $global:Error[0]. This parameter will also accept an array of error records.
    .PARAMETER Property
        The list of properties to display from the error record. Use "*" to display all properties.
    D   efault list of error properties is: Message, FullyQualifiedErrorId, ScriptStackTrace, PositionMessage, InnerException
    .PARAMETER GetErrorRecord
        Get error record details as represented by $_.
    .PARAMETER GetErrorInvocation
        Get error record invocation information as represented by $_.InvocationInfo.
    .PARAMETER GetErrorException
        Get error record exception details as represented by $_.Exception.
    .PARAMETER GetErrorInnerException
        Get error record inner exception details as represented by $_.Exception.InnerException. Will retrieve all inner exceptions if there is more than one.
    .INPUTS
        System.Array.
        Accepts an array of error records.
       .OUTPUTS
        System.String
        Displays the error record details.
    .EXAMPLE
        Resolve-Error
    .EXAMPLE
        Resolve-Error -Property *
    .EXAMPLE
        Resolve-Error -Property InnerException
    .EXAMPLE
        Resolve-Error -GetErrorInvocation:$false
    .LINK
        https://psappdeploytoolkit.com
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyCollection()]
        [Array]$ErrorRecord,
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNullorEmpty()]
        [String[]]$Property = ('Message', 'InnerException', 'FullyQualifiedErrorId', 'ScriptStackTrace', 'PositionMessage'),
        [Parameter(Mandatory = $false, Position = 2)]
        [Switch]$GetErrorRecord = $true,
        [Parameter(Mandatory = $false, Position = 3)]
        [Switch]$GetErrorInvocation = $true,
        [Parameter(Mandatory = $false, Position = 4)]
        [Switch]$GetErrorException = $true,
        [Parameter(Mandatory = $false, Position = 5)]
        [Switch]$GetErrorInnerException = $true
    )

    Begin {
        ## If function was called without specifying an error record, then choose the latest error that occurred
        If (-not $ErrorRecord) {
            If ($global:Error.Count -eq 0) {
                #Write-Warning -Message "The `$Error collection is empty"
                Return
            }
            Else {
                [Array]$ErrorRecord = $global:Error[0]
            }
        }

        ## Allows selecting and filtering the properties on the error object if they exist
        [ScriptBlock]$SelectProperty = {
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullorEmpty()]
                $InputObject,
                [Parameter(Mandatory = $true)]
                [ValidateNotNullorEmpty()]
                [String[]]$Property
            )

            [String[]]$ObjectProperty = $InputObject | Get-Member -MemberType '*Property' | Select-Object -ExpandProperty 'Name'
            ForEach ($Prop in $Property) {
                If ($Prop -eq '*') {
                    [String[]]$PropertySelection = $ObjectProperty
                    Break
                }
                ElseIf ($ObjectProperty -contains $Prop) {
                    [String[]]$PropertySelection += $Prop
                }
            }
            Write-Output -InputObject ($PropertySelection)
        }

        #  Initialize variables to avoid error if 'Set-StrictMode' is set
        $LogErrorRecordMsg = $null
        $LogErrorInvocationMsg = $null
        $LogErrorExceptionMsg = $null
        $LogErrorMessageTmp = $null
        $LogInnerMessage = $null
    }
    Process {
        If (-not $ErrorRecord) {
            Return
        }
        ForEach ($ErrRecord in $ErrorRecord) {
            ## Capture Error Record
            If ($GetErrorRecord) {
                [String[]]$SelectedProperties = & $SelectProperty -InputObject $ErrRecord -Property $Property
                $LogErrorRecordMsg = $ErrRecord | Select-Object -Property $SelectedProperties
            }

            ## Error Invocation Information
            If ($GetErrorInvocation) {
                If ($ErrRecord.InvocationInfo) {
                    [String[]]$SelectedProperties = & $SelectProperty -InputObject $ErrRecord.InvocationInfo -Property $Property
                    $LogErrorInvocationMsg = $ErrRecord.InvocationInfo | Select-Object -Property $SelectedProperties
                }
            }

            ## Capture Error Exception
            If ($GetErrorException) {
                If ($ErrRecord.Exception) {
                    [String[]]$SelectedProperties = & $SelectProperty -InputObject $ErrRecord.Exception -Property $Property
                    $LogErrorExceptionMsg = $ErrRecord.Exception | Select-Object -Property $SelectedProperties
                }
            }

            ## Display properties in the correct order
            If ($Property -eq '*') {
                #  If all properties were chosen for display, then arrange them in the order the error object displays them by default.
                If ($LogErrorRecordMsg) {
                    [Array]$LogErrorMessageTmp += $LogErrorRecordMsg
                }
                If ($LogErrorInvocationMsg) {
                    [Array]$LogErrorMessageTmp += $LogErrorInvocationMsg
                }
                If ($LogErrorExceptionMsg) {
                    [Array]$LogErrorMessageTmp += $LogErrorExceptionMsg
                }
            }
            Else {
                #  Display selected properties in our custom order
                If ($LogErrorExceptionMsg) {
                    [Array]$LogErrorMessageTmp += $LogErrorExceptionMsg
                }
                If ($LogErrorRecordMsg) {
                    [Array]$LogErrorMessageTmp += $LogErrorRecordMsg
                }
                If ($LogErrorInvocationMsg) {
                    [Array]$LogErrorMessageTmp += $LogErrorInvocationMsg
                }
            }

            If ($LogErrorMessageTmp) {
                $LogErrorMessage = 'Error Record:'
                $LogErrorMessage += "`n-------------"
                $LogErrorMsg = $LogErrorMessageTmp | Format-List | Out-String
                $LogErrorMessage += $LogErrorMsg
            }

            ## Capture Error Inner Exception(s)
            If ($GetErrorInnerException) {
                If ($ErrRecord.Exception -and $ErrRecord.Exception.InnerException) {
                    $LogInnerMessage = 'Error Inner Exception(s):'
                    $LogInnerMessage += "`n-------------------------"

                    $ErrorInnerException = $ErrRecord.Exception.InnerException
                    $Count = 0

                    While ($ErrorInnerException) {
                        [String]$InnerExceptionSeperator = '~' * 40

                        [String[]]$SelectedProperties = & $SelectProperty -InputObject $ErrorInnerException -Property $Property
                        $LogErrorInnerExceptionMsg = $ErrorInnerException | Select-Object -Property $SelectedProperties | Format-List | Out-String

                        If ($Count -gt 0) {
                            $LogInnerMessage += $InnerExceptionSeperator
                        }
                        $LogInnerMessage += $LogErrorInnerExceptionMsg

                        $Count++
                        $ErrorInnerException = $ErrorInnerException.InnerException
                    }
                }
            }

            If ($LogErrorMessage) {
                $Output = $LogErrorMessage
            }
            If ($LogInnerMessage) {
                $Output += $LogInnerMessage
            }

            Write-Output -InputObject $Output

            If (Test-Path -LiteralPath 'variable:Output') {
                Clear-Variable -Name 'Output'
            }
            If (Test-Path -LiteralPath 'variable:LogErrorMessage') {
                Clear-Variable -Name 'LogErrorMessage'
            }
            If (Test-Path -LiteralPath 'variable:LogInnerMessage') {
                Clear-Variable -Name 'LogInnerMessage'
            }
            If (Test-Path -LiteralPath 'variable:LogErrorMessageTmp') {
                Clear-Variable -Name 'LogErrorMessageTmp'
            }
        }
    }
    End {
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
        [PSObject[]]$LoggedOnUserSessions = Get-LoggedOnUser
        [String[]]$usersLoggedOn = $LoggedOnUserSessions | ForEach-Object { $_.NTAccount }
        [String]$sid = (New-Object System.Security.Principal.NTAccount($usersLoggedOn)).Translate([System.Security.Principal.SecurityIdentifier]).Value               
        [bool]$lightThemeResult = $true
        if ($true -eq (Test-RegistryValue -Key "HKU:\$sid\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Value "AppsUseLightTheme")) {
            if ((Get-RegistryKey -Key "HKU:\$sid\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Value "AppsUseLightTheme") -eq 1) {
                [bool]$lightThemeResult = $true
            } 
            else {
                [bool]$lightThemeResult = $false
            }
        } 
        else {
            if ($true -eq (Test-RegistryValue -Key "HKU:\$sid\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Value "SystemUsesLightTheme")) {
                if ((Get-RegistryKey -Key "HKU:\$sid\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Value "SystemUsesLightTheme") -eq 1) {
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
#region function Write-FunctionHeaderOrFooter
Function Write-FunctionHeaderOrFooter {
    <#
    .SYNOPSIS
        Write the function header or footer to the log upon first entering or exiting a function.
    .DESCRIPTION
        Write the "Function Start" message, the bound parameters the function was invoked with, or the "Function End" message when entering or exiting a function.
        Messages are debug messages so will only be logged if LogDebugMessage option is enabled in XML config file.
    .PARAMETER CmdletName
        The name of the function this function is invoked from.
    .PARAMETER CmdletBoundParameters
        The bound parameters of the function this function is invoked from.
    .PARAMETER Header
        Write the function header.
    .PARAMETER Footer
        Write the function footer.
    .INPUTS
        None
        You cannot pipe objects to this function.
    .OUTPUTS
        None
    This function does not generate any output.
    .EXAMPLE
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
    .EXAMPLE
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
    .NOTES
        This is an internal script function and should typically not be called directly.
    .LINK
        https://psappdeploytoolkit.com
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [String]$CmdletName,
        [Parameter(Mandatory = $true, ParameterSetName = 'Header')]
        [AllowEmptyCollection()]
        [Hashtable]$CmdletBoundParameters,
        [Parameter(Mandatory = $true, ParameterSetName = 'Header')]
        [Switch]$Header,
        [Parameter(Mandatory = $true, ParameterSetName = 'Footer')]
        [Switch]$Footer
    )

    If ($Header) {
        Write-Log -Message 'Function Start' -Source ${CmdletName} -DebugMessage

        ## Get the parameters that the calling function was invoked with
        [String]$CmdletBoundParameters = $CmdletBoundParameters | Format-Table -Property @{ Label = 'Parameter'; Expression = { "[-$($_.Key)]" } }, @{ Label = 'Value'; Expression = { $_.Value }; Alignment = 'Left' }, @{ Label = 'Type'; Expression = { $_.Value.GetType().Name }; Alignment = 'Left' } -AutoSize -Wrap | Out-String
        If ($CmdletBoundParameters) {
            Write-Log -Message "Function invoked with bound parameter(s): `r`n$CmdletBoundParameters" -Source ${CmdletName} -DebugMessage
        }
        Else {
            Write-Log -Message 'Function invoked without any bound parameters.' -Source ${CmdletName} -DebugMessage
        }
    }
    ElseIf ($Footer) {
        Write-Log -Message 'Function End' -Source ${CmdletName} -DebugMessage
    }
}
#endregion
#region Function Write-Log
function Write-Log {
    <#
    .SYNOPSIS
        Write messages to a log file in CMTrace.exe compatible format or Legacy text file format.
    .DESCRIPTION
        Write messages to a log file in CMTrace.exe compatible format or Legacy text file format and optionally display in the console.
    .PARAMETER Message
        The message to write to the log file or output to the console.
    .PARAMETER Source
        The source of the message being logged.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyCollection()]
        [Alias('Text')]
        [String[]]$Message,
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateRange(1, 3)]
        [Int16]$Severity = 1,
        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateNotNull()]
        [String]$Source = $([String]$parentFunctionName = [IO.Path]::GetFileNameWithoutExtension((Get-Variable -Name 'MyInvocation' -Scope 1 -ErrorAction 'SilentlyContinue').Value.MyCommand.Name); If ($parentFunctionName) {
                $parentFunctionName
            }
            Else {
                'Unknown'
            }),
        [Parameter(Mandatory = $false, Position = 3)]
        [ValidateNotNullorEmpty()]
        [String]$ScriptSection = $script:installPhase,
        [Parameter(Mandatory = $false, Position = 4)]
        [ValidateSet('CMTrace', 'Legacy')]
        [String]$LogType = $configToolkitLogStyle,
        [Parameter(Mandatory = $false, Position = 5)]
        [ValidateNotNullorEmpty()]
        [String]$LogFileDirectory = $configToolkitLogDir,
        [Parameter(Mandatory = $false, Position = 6)]
        [ValidateNotNullorEmpty()]
        [String]$LogFileName = $LogName,
        [Parameter(Mandatory = $false, Position = 7)]
        [ValidateNotNullorEmpty()]
        [Decimal]$MaxLogFileSizeMB = $configToolkitLogMaxSize,
        [Parameter(Mandatory = $false, Position = 8)]
        [ValidateNotNullorEmpty()]
        [Boolean]$WriteHost = $configToolkitLogWriteToHost,
        [Parameter(Mandatory = $false, Position = 9)]
        [ValidateNotNullorEmpty()]
        [Boolean]$ContinueOnError = $true,
        [Parameter(Mandatory = $false, Position = 10)]
        [Switch]$PassThru = $false,
        [Parameter(Mandatory = $false, Position = 11)]
        [Switch]$DebugMessage = $false,
        [Parameter(Mandatory = $false, Position = 12)]
        [Boolean]$LogDebugMessage = $configToolkitLogDebugMessage
    )
    Begin {
        ## Get the name of this function
        [String]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name

        ## Logging Variables
        #  Log file date/time
        [DateTime]$DateTimeNow = Get-Date
        [String]$LogTime = $DateTimeNow.ToString('HH\:mm\:ss.fff')
        [String]$LogDate = $DateTimeNow.ToString('MM-dd-yyyy')
        If (-not (Test-Path -LiteralPath 'variable:LogTimeZoneBias')) {
            [Int32]$script:LogTimeZoneBias = [TimeZone]::CurrentTimeZone.GetUtcOffset($DateTimeNow).TotalMinutes
        }
        [String]$LogTimePlusBias = $LogTime + $script:LogTimeZoneBias
        #  Initialize variables
        [Boolean]$ExitLoggingFunction = $false
        If (-not (Test-Path -LiteralPath 'variable:DisableLogging')) {
            $DisableLogging = $false
        }
        #  Check if the script section is defined
        [Boolean]$ScriptSectionDefined = [Boolean](-not [String]::IsNullOrEmpty($ScriptSection))
        #  Get the file name of the source script
        Try {
            If ($script:MyInvocation.Value.ScriptName) {
                [String]$ScriptSource = Split-Path -Path $script:MyInvocation.Value.ScriptName -Leaf -ErrorAction 'Stop'
            }
            Else {
                [String]$ScriptSource = Split-Path -Path $script:MyInvocation.MyCommand.Definition -Leaf -ErrorAction 'Stop'
            }
        }
        Catch {
            $ScriptSource = ''
        }

        ## Create script block for generating CMTrace.exe compatible log entry
        [ScriptBlock]$CMTraceLogString = {
            Param (
                [String]$lMessage,
                [String]$lSource,
                [Int16]$lSeverity
            )
            "<![LOG[$lMessage]LOG]!>" + "<time=`"$LogTimePlusBias`" " + "date=`"$LogDate`" " + "component=`"$lSource`" " + "context=`"$([Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " + "type=`"$lSeverity`" " + "thread=`"$PID`" " + "file=`"$ScriptSource`">"
        }

        ## Create script block for writing log entry to the console
        [ScriptBlock]$WriteLogLineToHost = {
            Param (
                [String]$lTextLogLine,
                [Int16]$lSeverity
            )
            If ($WriteHost) {
                #  Only output using color options if running in a host which supports colors.
                If ($Host.UI.RawUI.ForegroundColor) {
                    Switch ($lSeverity) {
                        3 {
                            Write-Host -Object $lTextLogLine -ForegroundColor 'Red' -BackgroundColor 'Black'
                        }
                        2 {
                            Write-Host -Object $lTextLogLine -ForegroundColor 'Yellow' -BackgroundColor 'Black'
                        }
                        1 {
                            Write-Host -Object $lTextLogLine
                        }
                    }
                }
                #  If executing "powershell.exe -File <filename>.ps1 > log.txt", then all the Write-Host calls are converted to Write-Output calls so that they are included in the text log.
                Else {
                    Write-Output -InputObject ($lTextLogLine)
                }
            }
        }

        ## Exit function if it is a debug message and logging debug messages is not enabled in the config XML file
        If (($DebugMessage) -and (-not $LogDebugMessage)) {
            [Boolean]$ExitLoggingFunction = $true; Return
        }
        ## Exit function if logging to file is disabled and logging to console host is disabled
        If (($DisableLogging) -and (-not $WriteHost)) {
            [Boolean]$ExitLoggingFunction = $true; Return
        }
        ## Exit Begin block if logging is disabled
        If ($DisableLogging) {
            Return
        }
        ## Exit function function if it is an [Initialization] message and the toolkit has been relaunched
        If (($AsyncToolkitLaunch) -and ($ScriptSection -eq 'Initialization')) {
            [Boolean]$ExitLoggingFunction = $true; Return
        }

        ## Create the directory where the log file will be saved
        If (-not (Test-Path -LiteralPath $LogFileDirectory -PathType 'Container')) {
            Try {
                $null = New-Item -Path $LogFileDirectory -Type 'Directory' -Force -ErrorAction 'Stop'
            }
            Catch {
                [Boolean]$ExitLoggingFunction = $true
                #  If error creating directory, write message to console
                If (-not $ContinueOnError) {
                    Write-Host -Object "[$LogDate $LogTime] [${CmdletName}] $ScriptSection :: Failed to create the log directory [$LogFileDirectory]. `r`n$(Resolve-Error)" -ForegroundColor 'Red'
                }
                Return
            }
        }

        ## Assemble the fully qualified path to the log file
        [String]$LogFilePath = Join-Path -Path $LogFileDirectory -ChildPath $LogFileName
    }
    Process {
        ## Exit function if logging is disabled
        If ($ExitLoggingFunction) {
            Return
        }

        ForEach ($Msg in $Message) {
            ## If the message is not $null or empty, create the log entry for the different logging methods
            [String]$CMTraceMsg = ''
            [String]$ConsoleLogLine = ''
            [String]$LegacyTextLogLine = ''
            If ($Msg) {
                #  Create the CMTrace log message
                If ($ScriptSectionDefined) {
                    [String]$CMTraceMsg = "[$ScriptSection] :: $Msg"
                }

                #  Create a Console and Legacy "text" log entry
                [String]$LegacyMsg = "[$LogDate $LogTime]"
                If ($ScriptSectionDefined) {
                    [String]$LegacyMsg += " [$ScriptSection]"
                }
                If ($Source) {
                    [String]$ConsoleLogLine = "$LegacyMsg [$Source] :: $Msg"
                    Switch ($Severity) {
                        3 {
                            [String]$LegacyTextLogLine = "$LegacyMsg [$Source] [Error] :: $Msg"
                        }
                        2 {
                            [String]$LegacyTextLogLine = "$LegacyMsg [$Source] [Warning] :: $Msg"
                        }
                        1 {
                            [String]$LegacyTextLogLine = "$LegacyMsg [$Source] [Info] :: $Msg"
                        }
                    }
                }
                Else {
                    [String]$ConsoleLogLine = "$LegacyMsg :: $Msg"
                    Switch ($Severity) {
                        3 {
                            [String]$LegacyTextLogLine = "$LegacyMsg [Error] :: $Msg"
                        }
                        2 {
                            [String]$LegacyTextLogLine = "$LegacyMsg [Warning] :: $Msg"
                        }
                        1 {
                            [String]$LegacyTextLogLine = "$LegacyMsg [Info] :: $Msg"
                        }
                    }
                }
            }

            ## Execute script block to create the CMTrace.exe compatible log entry
            [String]$CMTraceLogLine = & $CMTraceLogString -lMessage $CMTraceMsg -lSource $Source -lSeverity $Severity

            ## Choose which log type to write to file
            If ($LogType -ieq 'CMTrace') {
                [String]$LogLine = $CMTraceLogLine
            }
            Else {
                [String]$LogLine = $LegacyTextLogLine
            }

            ## Write the log entry to the log file if logging is not currently disabled
            If (-not $DisableLogging) {
                Try {
                    $LogLine | Out-File -FilePath $LogFilePath -Append -NoClobber -Force -Encoding 'UTF8' -ErrorAction 'Stop'
                }
                Catch {
                    If (-not $ContinueOnError) {
                        Write-Host -Object "[$LogDate $LogTime] [$ScriptSection] [${CmdletName}] :: Failed to write message [$Msg] to the log file [$LogFilePath]. `r`n$(Resolve-Error)" -ForegroundColor 'Red'
                    }
                }
            }

            ## Execute script block to write the log entry to the console if $WriteHost is $true
            & $WriteLogLineToHost -lTextLogLine $ConsoleLogLine -lSeverity $Severity
        }
    }
    End {
        ## Archive log file if size is greater than $MaxLogFileSizeMB and $MaxLogFileSizeMB > 0
        Try {
            If ((-not $ExitLoggingFunction) -and (-not $DisableLogging)) {
                [IO.FileInfo]$LogFile = Get-ChildItem -LiteralPath $LogFilePath -ErrorAction 'Stop'
                [Decimal]$LogFileSizeMB = $LogFile.Length / 1MB
                If (($LogFileSizeMB -gt $MaxLogFileSizeMB) -and ($MaxLogFileSizeMB -gt 0)) {
                    ## Change the file extension to "lo_"
                    [String]$ArchivedOutLogFile = [IO.Path]::ChangeExtension($LogFilePath, 'lo_')
                    [Hashtable]$ArchiveLogParams = @{ ScriptSection = $ScriptSection; Source = ${CmdletName}; Severity = 2; LogFileDirectory = $LogFileDirectory; LogFileName = $LogFileName; LogType = $LogType; MaxLogFileSizeMB = 0; WriteHost = $WriteHost; ContinueOnError = $ContinueOnError; PassThru = $false }

                    ## Log message about archiving the log file
                    $ArchiveLogMessage = "Maximum log file size [$MaxLogFileSizeMB MB] reached. Rename log file to [$ArchivedOutLogFile]."
                    Write-Log -Message $ArchiveLogMessage @ArchiveLogParams

                    ## Archive existing log file from <filename>.log to <filename>.lo_. Overwrites any existing <filename>.lo_ file. This is the same method SCCM uses for log files.
                    Move-Item -LiteralPath $LogFilePath -Destination $ArchivedOutLogFile -Force -ErrorAction 'Stop'

                    ## Start new log file and Log message about archiving the old log file
                    $NewLogMessage = "Previous log file was renamed to [$ArchivedOutLogFile] because maximum log file size of [$MaxLogFileSizeMB MB] was reached."
                    Write-Log -Message $NewLogMessage @ArchiveLogParams
                }
            }
        }
        Catch {
            ## If renaming of file fails, script will continue writing to log file even if size goes over the max file size
        }
        Finally {
            If ($PassThru) {
                Write-Output -InputObject ($Message)
            }
        }
    }
}
#endregion
#region Function Test-RegistryValue
Function Test-RegistryValue {
    <#
        .SYNOPSIS
        Test if a registry value exists.
        .DESCRIPTION
        Checks a registry key path to see if it has a value with a given name. Can correctly handle cases where a value simply has an empty or null value.
        .PARAMETER Key
        Path of the registry key.
        .PARAMETER Value
        Specify the registry key value to check the existence of.
        .PARAMETER SID
        The security identifier (SID) for a user. Specifying this parameter will convert a HKEY_CURRENT_USER registry key to the HKEY_USERS\$SID format.
        Specify this parameter from the Invoke-HKCURegistrySettingsForAllUsers function to read/edit HKCU registry settings for all users on the system.
        .INPUTS
        System.String
        Accepts a string value for the registry key path.
        .OUTPUTS
        System.String
        Returns $true if the registry value exists, $false if it does not.
        .EXAMPLE
        Test-RegistryValue -Key 'HKLM:SYSTEM\CurrentControlSet\Control\Session Manager' -Value 'PendingFileRenameOperations'
        .NOTES
        To test if registry key exists, use Test-Path function like so:
        Test-Path -Path $Key -PathType 'Container'
        .LINK
        https://psappdeploytoolkit.com
    #>
    Param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]$Key,
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]$Value,
        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateNotNullorEmpty()]
        [String]$SID
    )

    Begin {
        ## Get the name of this function and write header
        [String]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
    }
    Process {
        ## If the SID variable is specified, then convert all HKEY_CURRENT_USER key's to HKEY_USERS\$SID
        Try {
            If ($PSBoundParameters.ContainsKey('SID')) {
                [String]$Key = Convert-RegistryPath -Key $Key -SID $SID
            }
            Else {
                [String]$Key = Convert-RegistryPath -Key $Key
            }
        }
        Catch {
            Throw
        }
        [Boolean]$IsRegistryValueExists = $false
        Try {
            If (Test-Path -LiteralPath $Key -ErrorAction 'Stop') {
                [String[]]$PathProperties = Get-Item -LiteralPath $Key -ErrorAction 'Stop' | Select-Object -ExpandProperty 'Property' -ErrorAction 'Stop'
                If ($PathProperties -contains $Value) {
                    $IsRegistryValueExists = $true
                }
            }
        }
        Catch {
        }

        If ($IsRegistryValueExists) {
            Write-Log -Message "Registry key value [$Key] [$Value] does exist." -Source ${CmdletName}
        }
        Else {
            Write-Log -Message "Registry key value [$Key] [$Value] does not exist." -Source ${CmdletName}
        }
        Write-Output -InputObject ($IsRegistryValueExists)
    }
    End {
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
    }
}
#endregion
[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
$script:installPhase = "AskKillProcesses"
[String]$scriptPath = $MyInvocation.MyCommand.Definition
[String]$scriptRoot = Split-Path -Path $scriptPath -Parent
[String]$appDeployConfigFile = Join-Path -Path $scriptRoot -ChildPath 'AppDeployToolkitConfig.xml'
[Xml.XmlDocument]$xmlConfigFile = Get-Content -LiteralPath $AppDeployConfigFile -Encoding 'UTF8'
[Xml.XmlElement]$xmlConfig = $xmlConfigFile.AppDeployToolkit_Config
#  Get Toolkit Options
[Xml.XmlElement]$xmlToolkitOptions = $xmlConfig.Toolkit_Options
[String]$configToolkitLogDir = $ExecutionContext.InvokeCommand.ExpandString($xmlToolkitOptions.Toolkit_LogPathNoAdminRights)
[String]$configToolkitLogStyle = $xmlToolkitOptions.Toolkit_LogStyle
[Double]$configToolkitLogMaxSize = $xmlToolkitOptions.Toolkit_LogMaxSize
[Boolean]$configToolkitLogWriteToHost = [Boolean]::Parse($xmlToolkitOptions.Toolkit_LogWriteToHost)
[Boolean]$configToolkitLogDebugMessage = [Boolean]::Parse($xmlToolkitOptions.Toolkit_LogDebugMessage)
[String]$appDeployCustomTypesSourceCode = Join-Path -Path $scriptRoot -ChildPath 'AppDeployToolkitMain.cs'
If (-not (Test-Path -LiteralPath $appDeployConfigFile -PathType 'Leaf')) {
    Throw 'App Deploy XML configuration file not found.'
}
If (-not (Test-Path -LiteralPath $appDeployCustomTypesSourceCode -PathType 'Leaf')) {
    Throw 'App Deploy custom types source code file not found.'
}

## Add the custom types required for the toolkit
If (-not ([Management.Automation.PSTypeName]'PSADT.UiAutomation').Type) {
    [String[]]$ReferencedAssemblies = 'System.Drawing', 'System.Windows.Forms', 'System.DirectoryServices'
    Add-Type -Path $appDeployCustomTypesSourceCode -ReferencedAssemblies $ReferencedAssemblies -IgnoreWarnings -ErrorAction 'Stop'
}
  
#  Get UI Options
[Xml.XmlElement]$xmlConfigUIOptions = $xmlConfig.UI_Options
[Int32]$configInstallationUITimeout = $xmlConfigUIOptions.InstallationUI_Timeout
[Int32]$configInstallationPersistInterval = $xmlConfigUIOptions.InstallationPrompt_PersistInterval
[Boolean]$configInstallationWelcomePromptDynamicRunningProcessEvaluation = [Boolean]::Parse($xmlConfigUIOptions.InstallationWelcomePrompt_DynamicRunningProcessEvaluation)
[Int32]$configInstallationWelcomePromptDynamicRunningProcessEvaluationInterval = $xmlConfigUIOptions.InstallationWelcomePrompt_DynamicRunningProcessEvaluationInterval
## Reset switches
[bool]$showCloseApps = $false
[bool]$showDefer = $false

Set-Variable -Name 'closeAppsCountdownGlobal' -Value $CloseAppsCountdown -Scope 'Script'
## Check if the countdown was specified
If ($CloseAppsCountdown -and ($CloseAppsCountdown -gt $configInstallationUITimeout)) {
    Throw 'The close applications countdown time cannot be longer than the timeout specified in the XML configuration for installation UI dialogs to timeout.'
}
[PSObject[]]$processObjects = ConvertFrom-NxtEncodedObject -EncodedObject $ProcessObjectsEncoded
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
Write-Log -Message "Close applications countdown has [$CloseAppsCountdown] seconds remaining." -Source ${CmdletName}
## If deferral is being shown and 'close apps countdown' or 'persist prompt' was specified, enable those features.
If (-not $showDefer) {
    If ($CloseAppsCountdown -gt 0) {
        Write-Log -Message "Close applications countdown has [$CloseAppsCountdown] seconds remaining." -Source ${CmdletName}
    }
}
if ($CloseAppsCountdown -gt 0) {
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
[System.Windows.Controls.TextBlock]$control_DeferTimerText = $control.FindName('DeferTimerText')
[System.Windows.Controls.TextBlock]$control_DeferTextTwo = $control.FindName('DeferTextTwo')
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

[Boolean]$IsLightTheme = Test-NxtPersonalizationLightTheme
            
if ($IsLightTheme) {
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

    $control_Banner.Source = $AppDeployLogoBanner
}
else {
    $control_Banner.Source = $appDeployLogoBannerDark
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
        if ($ContinueType -eq 0) {
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
        if ($ContinueType -eq 0) {
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
        if ($ContinueType -eq 0) {
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
if ($ProcessIdToIgnore -gt 0){
    [int[]]$ProcessIdsToIgnore = Get-NxtProcessTree -ProcessId $ProcessIdToIgnore | Select-Object -ExpandProperty ProcessId
}else{
    [int[]]$ProcessIdsToIgnore = @()
}
[PSObject[]]$runningProcesses = foreach ($processObject in $processObjects) {
    Get-NxtRunningProcesses -ProcessObjects $processObject -ProcessIdsToIgnore $ProcessIdsToIgnore | Where-Object { $false -eq [string]::IsNullOrEmpty($_.id) }
}
[ScriptBlock]$FillCloseApplicationList = {
    param($runningProcessesParam)
    $control_CloseApplicationList.Items.Clear()
    ForEach ($runningProcessItem in $runningProcessesParam) {
        Get-WmiObject -Class Win32_Process -Filter "ProcessID = '$($runningProcessItem.Id)'" | ForEach-Object {
            $item = New-Object PSObject -Property @{
                Name      = $runningProcessItem.ProcessDescription
                StartedBy = $null
            }
            if ($_.GetOwner().User -eq $null) {
                $item.StartedBy = "N/A"
            }else{
                $item.StartedBy = $_.GetOwner().Domain + "\" + $_.GetOwner().User
            }
            $control_CloseApplicationList.Items.Add($item) | Out-Null
        }
    }
}
& $FillCloseApplicationList $runningProcesses

[string]$names = $runningProcesses | Select-Object -ExpandProperty Name
$control_PopupListText.Text = $names.Trim()
        
[Int32]$OutNumber = $null

If ([Int32]::TryParse($DeferTimes, [ref]$OutNumber) -and $DeferTimes -ge 0) {
    $control_DeferTimerText.Text = $xmlUIMessages.NxtWelcomePrompt_RemainingDefferals -f $([Int32]$DeferTimes + 1)
}
If ($DeferDeadline) {
    $control_DeferDeadlineText.Text = $xmlUIMessages.DeferPrompt_Deadline + " " + $DeferDeadline
}

if ($true -eq [string]::IsNullOrEmpty($control_DeferTimerText.Text)) {
    $control_DeferTextOne.Visibility = "Collapsed"
    $control_DeferTextTwo.Visibility = "Collapsed"
    $control_DeferButton.Visibility = "Collapsed"
    $control_DeferDeadlineText.Visibility = "Collapsed"         
}
else {  
    $control_DeferTextOne.Visibility = "Visible"
    $control_DeferTextTwo.Visibility = "Visible"
    $control_DeferButton.Visibility = "Visible"
    If ($DeferDeadline) {
        $control_DeferDeadlineText.Visibility = "Visible"
    }
    else {
        $control_DeferDeadlineText.Visibility = "Collapsed"
    }
}

if (-not $UserCanCloseAll) {
    $control_CloseButton.Visibility = "Collapsed"
}

if (-not $UserCanAbort) {
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
    If ($showCountdown) {
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
            if ($showCountdown) {
                if ($ContinueType -eq 0) {
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
    [int]$tickCounter = 0
    [ScriptBlock]$timerRunningProcesses_Tick = {
        Try {
            if ([math]::DivRem($tickCounter,10,[ref]$null) -eq 1){
                # As this is performance intensive, only run it every 10 Ticks
                [int[]]$processIdsToIgnore = Get-NxtProcessTree -ProcessId $ProcessIdToIgnore | Select-Object -ExpandProperty ProcessId
            }
            $tickCounter++
            [PSObject[]]$dynamicRunningProcesses = $null
            $dynamicRunningProcesses = Get-NxtRunningProcesses -ProcessObjects $processObjects -DisableLogging -ProcessIdsToIgnore $processIdsToIgnore
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
[__ComObject]$ShellApp = New-Object -ComObject 'Shell.Application' -ErrorAction 'SilentlyContinue'
If ($MinimizeWindows) {
    $shellApp.MinimizeAll()
}

# Open dialog and Wait
$control_MainWindow.ShowDialog() | Out-Null
              
If ($configInstallationWelcomePromptDynamicRunningProcessEvaluation) {
    $timerRunningProcesses.Stop()
}
switch ($control_MainWindow.Tag) {
    'Close' {
        Write-Log -Message 'The user chose to close the applications.' -Source ${CmdletName} -Severity 1
        Exit 1001
    }
    'Cancel' {
        Write-Log -Message 'The user chose to cancel the installation.' -Source ${CmdletName} -Severity 1
        Exit 1002
    }
    'Defer' {
        Write-Log -Message 'The user chose to defer the installation.' -Source ${CmdletName} -Severity 1
        Exit 1003
    }
    'Timeout' {
        Write-Log -Message 'The installation timed out.' -Source ${CmdletName} -Severity 1
        Exit 1004
    }
    'Continue' {
        Write-Log -Message 'The user chose to continue the installation.' -Source ${CmdletName} -Severity 1
        Exit 1005
    }
    default {
        Exit 1005
    }
}
#endregion

