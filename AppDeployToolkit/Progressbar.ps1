<#
.SYNOPSIS
    Displays a progress bar with customizable options.
.DESCRIPTION
    Displays a progress bar with the specified package name, title, header text, window hide behavior, icon path, and icon alignment.

.PARAMETER PackageName
    Specifies the name of the package. This parameter is mandatory.
.PARAMETER Title
    Specifies the title of the progress bar window. This parameter is optional.
.PARAMETER HeaderText
    Specifies the header text displayed in the progress bar window. This parameter is optional.
.PARAMETER WinHide
    Specifies the behavior of the window when minimized. This parameter is optional.
.PARAMETER IconPath
    Specifies the path to the icon displayed in the progress bar window. This parameter is optional.
.PARAMETER IconAlignment
    Specifies the alignment of the icon within the progress bar window. Valid values are "Left", "Center", or "Right". Default is "Left".
.PARAMETER TopMost
    Indicates whether the progress bar window is displayed as the topmost window. Default is $false.
.PARAMETER End
    Indicates whether the progress bar represents the end of a process. Default is $false.
.PARAMETER Kill
    Indicates whether to forcefully terminate the progress bar window. Default is $false.
.INPUTS
	None
	You cannot pipe objects to this function.
.OUTPUTS
	None
.EXAMPLE
    Display-ProgressBar -PackageName "Google Chrome 116.4.3" -Title "Progress" -HeaderText "Processing Files" -IconPath "C:\Icons\progress.ico" -IconAlignment "Center"

.NOTES
    This function is used to display a customizable progress bar. It provides flexibility in specifying various parameters to tailor the appearance and behavior of the progress bar.

    # LICENSE #
    This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

    # ORIGINAL COPYRIGHT #
    PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
    Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.

    # MODIFICATION COPYRIGHT #
    Copyright (c) 2024 neo42 GmbH, Germany.
.LINK
	https://neo42.de/psappdeploytoolkit
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory = $true)]
	[ValidateNotNullorEmpty()]
	[string]
	$Packagename,
	[Parameter(Mandatory = $false)]
	[string]
	$Title,
	[Parameter(Mandatory = $false)]
	[string]
	$HeaderText,
	[Parameter(Mandatory = $false)]
	[string]
	$WinHide,
	[Parameter(Mandatory = $false)]
	[string]
	$IconPath,
	[Parameter(Mandatory = $false)]
	[ValidateSet('Left', 'Center', 'Right')]
	[string]
	$IconAlignment = 'Left',
	[Parameter(Mandatory = $false)]
	[Switch]
	$TopMost = $false,
	[Parameter(Mandatory = $false)]
	[Switch]
	$End = $false,
	[Parameter(Mandatory = $false)]
	[Switch]
	$Kill = $false
)
#region Function Convert-RegistryPath
function Convert-RegistryPath {
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
		.NOTES
			This function is a modified version of Convert-RegistryPath from the PSAppDeployToolkit licensed under the LGPLv3.
		.LINK
			https://psappdeploytoolkit.com
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[string]
		$Key,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]
		$SID,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[bool]
		$DisableFunctionLogging = $true
	)

	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		## Convert the registry key hive to the full path, only match if at the beginning of the line
		if ($Key -match '^HKLM') {
			$Key = $Key -replace '^HKLM:\\', 'HKEY_LOCAL_MACHINE\' -replace '^HKLM:', 'HKEY_LOCAL_MACHINE\' -replace '^HKLM\\', 'HKEY_LOCAL_MACHINE\'
		}
		elseif ($Key -match '^HKCR') {
			$Key = $Key -replace '^HKCR:\\', 'HKEY_CLASSES_ROOT\' -replace '^HKCR:', 'HKEY_CLASSES_ROOT\' -replace '^HKCR\\', 'HKEY_CLASSES_ROOT\'
		}
		elseif ($Key -match '^HKCU') {
			$Key = $Key -replace '^HKCU:\\', 'HKEY_CURRENT_USER\' -replace '^HKCU:', 'HKEY_CURRENT_USER\' -replace '^HKCU\\', 'HKEY_CURRENT_USER\'
		}
		elseif ($Key -match '^HKU') {
			$Key = $Key -replace '^HKU:\\', 'HKEY_USERS\' -replace '^HKU:', 'HKEY_USERS\' -replace '^HKU\\', 'HKEY_USERS\'
		}
		elseif ($Key -match '^HKCC') {
			$Key = $Key -replace '^HKCC:\\', 'HKEY_CURRENT_CONFIG\' -replace '^HKCC:', 'HKEY_CURRENT_CONFIG\' -replace '^HKCC\\', 'HKEY_CURRENT_CONFIG\'
		}
		elseif ($Key -match '^HKPD') {
			$Key = $Key -replace '^HKPD:\\', 'HKEY_PERFORMANCE_DATA\' -replace '^HKPD:', 'HKEY_PERFORMANCE_DATA\' -replace '^HKPD\\', 'HKEY_PERFORMANCE_DATA\'
		}

		## Append the PowerShell provider to the registry key path
		if ($Key -notmatch '^Registry::') {
			$Key = "Registry::$Key"
		}

		if ($true -eq ($PSBoundParameters.ContainsKey('SID'))) {
			## If the SID variable is specified, then convert all HKEY_CURRENT_USER key's to HKEY_USERS\$SID
			if ($Key -match '^Registry::HKEY_CURRENT_USER\\') {
				$Key = $Key -replace '^Registry::HKEY_CURRENT_USER\\', "Registry::HKEY_USERS\$SID\"
			}
			elseif ($false -eq $DisableFunctionLogging) {
				Write-Log -Message 'SID parameter specified but the registry hive of the key is not HKEY_CURRENT_USER.' -Source ${cmdletName} -Severity 2
			}
		}

		if ($Key -match '^Registry::HKEY_LOCAL_MACHINE|^Registry::HKEY_CLASSES_ROOT|^Registry::HKEY_CURRENT_USER|^Registry::HKEY_USERS|^Registry::HKEY_CURRENT_CONFIG|^Registry::HKEY_PERFORMANCE_DATA') {
			## Check for expected key string format
			if ($false -eq $DisableFunctionLogging) {
				Write-Log -Message "Return fully qualified registry key path [$Key]." -Source ${cmdletName}
			}
			Write-Output -InputObject ($key)
		}
		else {
			#  If key string is not properly formatted, throw an error
			throw "Unable to detect target registry hive in string [$Key]."
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Get-LoggedOnUser
function Get-LoggedOnUser {
	<#
		.SYNOPSIS
			Get session details for all local and RDP logged on users.
		.DESCRIPTION
			Get session details for all local and RDP logged on users using Win32 APIs. Get the following session details:
				NTAccount, SID, UserName, DomainName, SessionId, SessionName, ConnectState, IsCurrentSession, IsConsoleSession, IsUserSession, IsActiveUserSession
				IsRdpSession, IsLocalAdmin, LogonTime, IdleTime, DisconnectTime, ClientName, ClientProtocolType, ClientDirectory, ClientBuildNumber
		.INPUTS
			None
		.OUTPUTS
			PSADT.QueryUser
		.EXAMPLE
			Get-LoggedOnUser
		.NOTES
			Description of ConnectState property:

			Value		Description
			-----		-----------
			Active	   A user is logged on to the session.
			ConnectQuery The session is in the process of connecting to a client.
			Connected	A client is connected to the session.
			Disconnected The session is active, but the client has disconnected from it.
			Down		 The session is down due to an error.
			Idle		 The session is waiting for a client to connect.
			Initializing The session is initializing.
			Listening	The session is listening for connections.
			Reset		The session is being reset.
			Shadowing	This session is shadowing another session.

			Description of IsActiveUserSession property:

			- If a console user exists, then that will be the active user session.
			- If no console user exists but users are logged in, such as on terminal servers, then the first logged-in non-console user that has ConnectState either 'Active' or 'Connected' is the active user.

			Description of IsRdpSession property:
			- Gets a value indicating whether the user is associated with an RDP client session.

			Description of IsLocalAdmin property:
			- Checks whether the user is a member of the Administrators group
		.NOTES
			This function is a modified version of Convert-RegistryPath from the PSAppDeployToolkit licensed under the LGPLv3.
		.LINK
			https://psappdeploytoolkit.com
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
		try {
			Write-Log -Message 'Getting session information for all logged on users.' -Source ${cmdletName}
			Write-Output -InputObject ([PSADT.QueryUser]::GetUserSessionInfo("$env:ComputerName"))
		}
		catch {
			Write-Log -Message "Failed to get session information for all logged on users. `r`n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Get-RegistryKey
function Get-RegistryKey {
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
		.NOTES
			This function is a modified version of Convert-RegistryPath from the PSAppDeployToolkit licensed under the LGPLv3.
		.LINK
			https://psappdeploytoolkit.com
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[string]
		$Key,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Value,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]
		$SID,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Switch]
		$ReturnEmptyKeyIfExists = $false,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Switch]
		$DoNotExpandEnvironmentNames = $false,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[bool]
		$ContinueOnError = $true
	)

	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		try {
			## If the SID variable is specified, then convert all HKEY_CURRENT_USER key's to HKEY_USERS\$SID
			if ($true -eq ($PSBoundParameters.ContainsKey('SID'))) {
				[string]$key = Convert-RegistryPath -Key $key -SID $SID
			}
			else {
				[string]$key = Convert-RegistryPath -Key $key
			}

			## Check if the registry key exists
			if ($false -eq (Test-Path -LiteralPath $key -ErrorAction 'Stop')) {
				Write-Log -Message "Registry key [$key] does not exist. Return `$null." -Severity 2 -Source ${cmdletName}
				$regKeyValue = $null
			}
			else {
				if ($true -eq ($PSBoundParameters.ContainsKey('Value'))) {
					Write-Log -Message "Getting registry key [$key] value [$value]." -Source ${cmdletName}
				}
				else {
					Write-Log -Message "Getting registry key [$key] and all property values." -Source ${cmdletName}
				}

				## Get all property values for registry key
				$regKeyValue = Get-ItemProperty -LiteralPath $key -ErrorAction 'Stop'
				[Int32]$regKeyValuePropertyCount = $regKeyValue | Measure-Object | Select-Object -ExpandProperty 'Count'

				## Select requested property
				if ($true -eq ($PSBoundParameters.ContainsKey('Value'))) {
					#  Check if registry value exists
					[bool]$isRegistryValueExists = $false
					if ($regKeyValuePropertyCount -gt 0) {
						try {
							[string[]]$pathProperties = Get-Item -LiteralPath $Key -ErrorAction 'Stop' | Select-Object -ExpandProperty 'Property' -ErrorAction 'Stop'
							if ($pathProperties -contains $Value) {
								[bool]$isRegistryValueExists = $true
							}
						}
						catch {
						}
					}

					#  Get the Value (do not make a strongly typed variable because it depends entirely on what kind of value is being read)
					if ($true -eq $isRegistryValueExists) {
						if ($true -eq $DoNotExpandEnvironmentNames) {
							#Only useful on 'ExpandString' values
							if ($Value -like '(Default)') {
								$regKeyValue = $(Get-Item -LiteralPath $key -ErrorAction 'Stop').GetValue($null, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
							}
							else {
								$regKeyValue = $(Get-Item -LiteralPath $key -ErrorAction 'Stop').GetValue($Value, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
							}
						}
						elseif ($Value -like '(Default)') {
							$regKeyValue = $(Get-Item -LiteralPath $key -ErrorAction 'Stop').GetValue($null)
						}
						else {
							$regKeyValue = $regKeyValue | Select-Object -ExpandProperty $Value -ErrorAction 'SilentlyContinue'
						}
					}
					else {
						Write-Log -Message "Registry key value [$Key] [$Value] does not exist. Return `$null." -Source ${cmdletName}
						$regKeyValue = $null
					}
				}
				## Select all properties or return empty key object
				else {
					if ($regKeyValuePropertyCount -eq 0) {
						if ($true -eq $ReturnEmptyKeyIfExists) {
							Write-Log -Message "No property values found for registry key. Return empty registry key object [$key]." -Source ${cmdletName}
							$regKeyValue = Get-Item -LiteralPath $key -Force -ErrorAction 'Stop'
						}
						else {
							Write-Log -Message "No property values found for registry key. Return `$null." -Source ${cmdletName}
							$regKeyValue = $null
						}
					}
				}
			}
			Write-Output -InputObject ($regKeyValue)
		}
		catch {
			if ($true -eq [string]::IsNullOrEmpty($Value)) {
				Write-Log -Message "Failed to read registry key [$key]. `r`n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
				if ($false -eq $ContinueOnError) {
					throw "Failed to read registry key [$key]: $($_.Exception.Message)"
				}
			}
			else {
				Write-Log -Message "Failed to read registry key [$key] value [$value]. `r`n$(Resolve-Error)" -Severity 3 -Source ${cmdletName}
				if ($false -eq $ContinueOnError) {
					throw "Failed to read registry key [$key] value [$value]: $($_.Exception.Message)"
				}
			}
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
		ciminstance
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
		$IncludeParentProcesses = $true,
		[Parameter(Mandatory = $false)]
		[AllowNull()]
		[int[]]
		$ProcessIdsToExcludeFromRecursion
	)
	[ciminstance]$process = Get-CimInstance -Query "SELECT * FROM Win32_Process WHERE ProcessId = $processId"
	if ($null -ne $process) {
		Write-Output $process
		if ($true -eq $IncludeChildProcesses) {
			[ciminstance[]]$childProcesses = Get-CimInstance -Query "SELECT * FROM Win32_Process WHERE ParentProcessId = $($process.ProcessId)"
			foreach ($child in $childProcesses) {
				if (
					$child.ProcessId -eq $process.ProcessId -and
					$child.ProcessId -notin $ProcessIdsToExcludeFromRecursion
				) {
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
#region Function Hide-Windows
function Hide-Windows {
	<#
        .SYNOPSIS
            Hide windows associated with specified process names.
        .DESCRIPTION
            Hide windows associated with specified process names by their process name.
        .PARAMETER ProcessNames
            Specifies a string containing process names separated by commas.
        .EXAMPLE
            Hide-Windows -ProcessNames "notepad"
        .LINK
            https://psappdeploytoolkit.com
    #>
	Param (
		[string]
		$ProcessNames
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		# Define the process names to hide
		$processNamesArray = $ProcessNames -split ','

		# Load User32.dll to access the ShowWindow function
		Add-Type @'
			using System;
			using System.Runtime.InteropServices;

			public static class User32 {
				[DllImport("user32.dll")]
				public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
			}
'@

		# Get processes and hide their windows
		if ($processNamesArray) {
			$processesToHide = Get-Process | Where-Object { $processNamesArray -contains $_.ProcessName }
			foreach ($processToHide in $processesToHide) {
				$handles = $processToHide.MainWindowHandle
				foreach ($handle in $handles) {
					if ($handle -ne [System.IntPtr]::Zero) {
						[User32]::ShowWindow($handle, 2)  # Hide the window
					}
					else {
						Write-Host 'No main window handle found for process.'
					}
				}
			}
		}
		else {
			Write-Host 'No process names provided.'
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
	.SYNOPSIS
		Creates a WPF control.
	.DESCRIPTION
		Creates a WPF control using an xml as input.
	.PARAMETER InputXml
		Xml input that is converted to a WPF control.
	.EXAMPLE
		New-NxtWpfControl -InputXml $inputXml
	.OUTPUTS
		System.Windows.Window
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
		$InputXml = $InputXml -replace 'mc:Ignorable="d"', [string]::Empty -replace 'x:N', 'N' -replace '^<Win.*', '<Window'
		#Read XAML
		[xml]$xaml = $InputXml
		[System.Xml.XmlNodeReader]$reader = (New-Object System.Xml.XmlNodeReader $xaml)
		try {
			[System.Windows.Window]$control = [Windows.Markup.XamlReader]::Load($reader)
		}
		catch {
			Write-Log 'Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed.' -Severity 3
			throw 'Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed.'
		}
		return $control
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Stop-ProgressbarByProcessTree

function Stop-AllProgressbars {
	<#
        .SYNOPSIS
            Stops all progress bars currently running.
        .DESCRIPTION
            This function stops all progress bars currently running in the PowerShell environment.
        .EXAMPLE
            Stop-AllProgressbars
        .LINK
            https://psappdeploytoolkit.com
    #>
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		$powershellProcessNames = @('powershell.exe', 'powershell_ise.exe', 'pwsh.exe')

		$powershellProcesses = Get-CimInstance Win32_Process -Filter "Name = '$($powershellProcessNames -join "' OR Name = '")'" | Select-Object ProcessId, CommandLine

		foreach ($powershellProcess in $powershellProcesses) {
			if ($powershellProcess.CommandLine -like '*ProgressBar.ps1*') {
				Stop-Process -Id $powershellProcess.ProcessId -Force
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#region Function Stop-ProgressbarByProcessTree
function Stop-ProgressbarByProcessTree {
	<#
        .SYNOPSIS
            Stops the progress bar associated with the current process.
        .DESCRIPTION
            This function stops the progress bar associated with the current process by searching the process tree.
        .EXAMPLE
            Stop-ProgressbarByProcessTree
        .LINK
            https://psappdeploytoolkit.com
    #>
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		if ($Keyword) {
			$currentProcess = [System.Diagnostics.Process]::GetCurrentProcess()
			$currentProcessId = [int]$currentProcess.Id
			$processTree = Get-NxtProcessTree $currentProcessId
			foreach ($process in $processTree) {
				if ($process.CommandLine -like '*neo42ProgressBar.ps1') {
					Stop-Process -Id $process.ProcessId -Force
				}
			}
		}
		else {
			Write-Host 'No keyword provided.'
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
#region Function Resolve-Error
function Resolve-Error {
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
	.NOTES
		This function is a modified version of Convert-RegistryPath from the PSAppDeployToolkit licensed under the LGPLv3.
	.LINK
		https://psappdeploytoolkit.com
	#>
	[CmdletBinding()]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidDefaultValueSwitchParameter', '', Justification = "This is a PSAppDeployToolkit function.")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('neo42PSCapatalizedVariablesNeedToOriginateFromParamBlock', '', Justification = "This is a PSAppDeployToolkit function.")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('neo42PSParamBlockVariablesShouldBeTyped', '', Justification = 'This is a PSAppDeployToolkit function.')]
	Param (
		[Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyCollection()]
		[Array]
		$ErrorRecord,
		[Parameter(Mandatory = $false, Position = 1)]
		[ValidateNotNullorEmpty()]
		[String[]]
		$Property = ('Message', 'InnerException', 'FullyQualifiedErrorId', 'ScriptStackTrace', 'PositionMessage'),
		[Parameter(Mandatory = $false, Position = 2)]
		[Switch]
		$GetErrorRecord = $true,
		[Parameter(Mandatory = $false, Position = 3)]
		[Switch]
		$GetErrorInvocation = $true,
		[Parameter(Mandatory = $false, Position = 4)]
		[Switch]
		$GetErrorException = $true,
		[Parameter(Mandatory = $false, Position = 5)]
		[Switch]
		$GetErrorInnerException = $true
	)

	Begin {
		## If function was called without specifying an error record, then choose the latest error that occurred
		if ($ErrorRecord.Count -eq 0) {
			if ($global:Error.Count -eq 0) {
				#Write-Warning -Message "The `$Error collection is empty"
				return
			}
			else {
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
			foreach ($Prop in $Property) {
				if ($Prop -eq '*') {
					[String[]]$PropertySelection = $ObjectProperty
					break
				}
				elseif ($ObjectProperty -contains $Prop) {
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
		if ($ErrorRecord.Count -eq 0) {
			return
		}
		foreach ($ErrRecord in $ErrorRecord) {
			## Capture Error Record
			if ($true -eq $GetErrorRecord) {
				[String[]]$SelectedProperties = & $SelectProperty -InputObject $ErrRecord -Property $Property
				$LogErrorRecordMsg = $ErrRecord | Select-Object -Property $SelectedProperties
			}

			## Error Invocation Information
			if ($true -eq $GetErrorInvocation) {
				if ($null -ne $ErrRecord.InvocationInfo) {
					[String[]]$SelectedProperties = & $SelectProperty -InputObject $ErrRecord.InvocationInfo -Property $Property
					$LogErrorInvocationMsg = $ErrRecord.InvocationInfo | Select-Object -Property $SelectedProperties
				}
			}

			## Capture Error Exception
			if ($true -eq $GetErrorException) {
				if ($null -ne $ErrRecord.Exception) {
					[String[]]$SelectedProperties = & $SelectProperty -InputObject $ErrRecord.Exception -Property $Property
					$LogErrorExceptionMsg = $ErrRecord.Exception | Select-Object -Property $SelectedProperties
				}
			}

			## Display properties in the correct order
			if ($Property -eq '*') {
				#  If all properties were chosen for display, then arrange them in the order the error object displays them by default.
				if ($false -eq [string]::IsNullOrEmpty($LogErrorRecordMsg)) {
					[Array]$LogErrorMessageTmp += $LogErrorRecordMsg
				}
				if ($false -eq [string]::IsNullOrEmpty($LogErrorInvocationMsg)) {
					[Array]$LogErrorMessageTmp += $LogErrorInvocationMsg
				}
				if ($false -eq [string]::IsNullOrEmpty($LogErrorExceptionMsg)) {
					[Array]$LogErrorMessageTmp += $LogErrorExceptionMsg
				}
			}
			else {
				#  Display selected properties in our custom order
				if ($false -eq [string]::IsNullOrEmpty($LogErrorExceptionMsg)) {
					[Array]$LogErrorMessageTmp += $LogErrorExceptionMsg
				}
				if ($false -eq [string]::IsNullOrEmpty($LogErrorRecordMsg)) {
					[Array]$LogErrorMessageTmp += $LogErrorRecordMsg
				}
				if ($false -eq [string]::IsNullOrEmpty($LogErrorInvocationMsg)) {
					[Array]$LogErrorMessageTmp += $LogErrorInvocationMsg
				}
			}

			if ($false -eq [string]::IsNullOrEmpty($LogErrorMessageTmp)) {
				$LogErrorMessage = 'Error Record:'
				$LogErrorMessage += "`n-------------"
				$LogErrorMsg = $LogErrorMessageTmp | Format-List | Out-String
				$LogErrorMessage += $LogErrorMsg
			}

			## Capture Error Inner Exception(s)
			if ($true -eq $GetErrorInnerException) {
				if ($ErrRecord.Exception -and $ErrRecord.Exception.InnerException) {
					$LogInnerMessage = 'Error Inner Exception(s):'
					$LogInnerMessage += "`n-------------------------"

					$ErrorInnerException = $ErrRecord.Exception.InnerException
					[int]$Count = 0

					while ($null -ne $ErrorInnerException) {
						[string]$InnerExceptionSeperator = '~' * 40

						[String[]]$SelectedProperties = & $SelectProperty -InputObject $ErrorInnerException -Property $Property
						$LogErrorInnerExceptionMsg = $ErrorInnerException | Select-Object -Property $SelectedProperties | Format-List | Out-String

						if ($Count -gt 0) {
							$LogInnerMessage += $InnerExceptionSeperator
						}
						$LogInnerMessage += $LogErrorInnerExceptionMsg

						$Count++
						$ErrorInnerException = $ErrorInnerException.InnerException
					}
				}
			}

			if ($false -eq [string]::IsNullOrEmpty($LogErrorMessage)) {
				$Output = $LogErrorMessage
			}
			if ($false -eq [string]::IsNullOrEmpty($LogInnerMessage)) {
				$Output += $LogInnerMessage
			}

			Write-Output -InputObject $Output

			if ($true -eq (Test-Path -LiteralPath 'variable:Output')) {
				Clear-Variable -Name 'Output'
			}
			if ($true -eq (Test-Path -LiteralPath 'variable:LogErrorMessage')) {
				Clear-Variable -Name 'LogErrorMessage'
			}
			if ($true -eq (Test-Path -LiteralPath 'variable:LogInnerMessage')) {
				Clear-Variable -Name 'LogInnerMessage'
			}
			if ($true -eq (Test-Path -LiteralPath 'variable:LogErrorMessageTmp')) {
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
	.SYNOPSIS
		Tests if a user has the light theme enabled.
	.DESCRIPTION
		Tests if a user has the light theme enabled by checking the system configuration
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
		[int]$ownSessionId = (Get-Process -Id $PID).SessionId
		[PSObject[]]$currentSessionUser = Get-LoggedOnUser | Where-Object {
			$_.SessionId -eq $ownSessionId
		}
		[string]$sid = $currentSessionUser.SID
		[bool]$lightThemeResult = $true
		if ($true -eq [string]::IsNullOrEmpty($sid)) {
			Write-Log -Message 'Failed to get SID of current sessions user, skipping theme check and using lighttheme.' -Source ${cmdletName} -Severity 2
			[bool]$lightThemeResult = $true
		}
		else {
			if ($true -eq (Test-RegistryValue -Key "HKU:\$sid\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Value 'AppsUseLightTheme')) {
				[bool]$lightThemeResult = (Get-RegistryKey -Key "HKU:\$sid\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Value 'AppsUseLightTheme') -eq 1
			}
			elseif ($true -eq (Test-RegistryValue -Key "HKU:\$sid\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Value 'SystemUsesLightTheme')) {
				[bool]$lightThemeResult = (Get-RegistryKey -Key "HKU:\$sid\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Value 'SystemUsesLightTheme') -eq 1
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
function Write-FunctionHeaderOrFooter {
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
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	.EXAMPLE
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	.NOTES
		This is an internal script function and should typically not be called directly.
	.NOTES
		This function is a modified version of Convert-RegistryPath from the PSAppDeployToolkit licensed under the LGPLv3.
	.LINK
		https://psappdeploytoolkit.com
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[string]
		$CmdletName,
		[Parameter(Mandatory = $true, ParameterSetName = 'Header')]
		[AllowEmptyCollection()]
		[Hashtable]
		$CmdletBoundParameters,
		[Parameter(Mandatory = $true, ParameterSetName = 'Header')]
		[Switch]
		$Header,
		[Parameter(Mandatory = $true, ParameterSetName = 'Footer')]
		[Switch]
		$Footer
	)

	if ($true -eq $Header) {
		Write-Log -Message 'Function Start' -Source ${cmdletName} -DebugMessage

		## Get the parameters that the calling function was invoked with
		[string]$CmdletBoundParameters = $CmdletBoundParameters | Format-Table -Property @{
			Label      = 'Parameter'
			Expression = {
				"[-$($_.Key)]"
			}
		},
		@{
			Label      = 'Value'
			Expression = {
				$_.Value
			}
			Alignment  = 'Left'
		},
		@{
			Label      = 'Type'
			Expression = {
				$_.Value.GetType().Name
			}
			Alignment  = 'Left'
		} -AutoSize -Wrap | Out-String
		if ($false -eq [string]::IsNullOrEmpty($CmdletBoundParameters)) {
			Write-Log -Message "Function invoked with bound parameter(s): `r`n$CmdletBoundParameters" -Source ${cmdletName} -DebugMessage
		}
		else {
			Write-Log -Message 'Function invoked without any bound parameters.' -Source ${cmdletName} -DebugMessage
		}
	}
	elseif ($true -eq $Footer) {
		Write-Log -Message 'Function End' -Source ${cmdletName} -DebugMessage
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
	.OUTPUTS
		none.
	.NOTES
		This function is a modified version of Convert-RegistryPath from the PSAppDeployToolkit licensed under the LGPLv3.
	#>
	[CmdletBinding()]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidDefaultValueSwitchParameter', '', Justification = 'This is a PSAppDeployToolkit function.')]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('neo42PSCapatalizedVariablesNeedToOriginateFromParamBlock', '', Justification = 'This is a PSAppDeployToolkit function.')]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('neo42PSParamBlockVariablesShouldBeTyped', '', Justification = 'This is a PSAppDeployToolkit function.')]
	Param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyCollection()]
		[Alias('Text')]
		[String[]]
		$Message,
		[Parameter(Mandatory = $false, Position = 1)]
		[ValidateRange(1, 3)]
		[Int16]
		$Severity = 1,
		[Parameter(Mandatory = $false, Position = 2)]
		[ValidateNotNull()]
		[string]
		$Source = $([string]$parentFunctionName = [IO.Path]::GetFileNameWithoutExtension(
			(Get-Variable -Name 'MyInvocation' -Scope 1 -ErrorAction 'SilentlyContinue').Value.MyCommand.Name)
			if ($false -eq [string]::IsNullOrEmpty($parentFunctionName)) {
				$parentFunctionName
			}
			else {
				'Unknown'
			}
		),
		[Parameter(Mandatory = $false, Position = 3)]
		[ValidateNotNullorEmpty()]
		[string]
		$ScriptSection = $script:installPhase,
		[Parameter(Mandatory = $false, Position = 4)]
		[ValidateSet('CMTrace', 'Legacy')]
		[string]
		$LogType = $configToolkitLogStyle,
		[Parameter(Mandatory = $false, Position = 5)]
		[ValidateNotNullorEmpty()]
		[string]
		$LogFileDirectory = $configToolkitLogDir,
		[Parameter(Mandatory = $false, Position = 6)]
		[ValidateNotNullorEmpty()]
		[string]
		$LogFileName = $LogName,
		[Parameter(Mandatory = $false, Position = 7)]
		[ValidateNotNullorEmpty()]
		[Decimal]
		$MaxLogFileSizeMB = $configToolkitLogMaxSize,
		[Parameter(Mandatory = $false, Position = 8)]
		[ValidateNotNullorEmpty()]
		[bool]
		$WriteHost = $configToolkitLogWriteToHost,
		[Parameter(Mandatory = $false, Position = 9)]
		[ValidateNotNullorEmpty()]
		[bool]
		$ContinueOnError = $true,
		[Parameter(Mandatory = $false, Position = 10)]
		[Switch]
		$PassThru = $false,
		[Parameter(Mandatory = $false, Position = 11)]
		[Switch]
		$DebugMessage = $false,
		[Parameter(Mandatory = $false, Position = 12)]
		[bool]
		$LogDebugMessage = $configToolkitLogDebugMessage
	)
	Begin {
		## Get the name of this function
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name

		## Logging Variables
		#  Log file date/time
		[DateTime]$DateTimeNow = Get-Date
		[string]$LogTime = $DateTimeNow.ToString('HH\:mm\:ss.fff')
		[string]$LogDate = $DateTimeNow.ToString('MM-dd-yyyy')
		if ($false -eq (Test-Path -LiteralPath 'variable:LogTimeZoneBias')) {
			[Int32]$script:LogTimeZoneBias = [TimeZone]::CurrentTimeZone.GetUtcOffset($DateTimeNow).TotalMinutes
		}
		[string]$LogTimePlusBias = $LogTime + $script:LogTimeZoneBias
		#  Initialize variables
		[bool]$ExitLoggingFunction = $false
		if ($false -eq (Test-Path -LiteralPath 'variable:DisableLogging')) {
			[bool]$DisableLogging = $false
		}
		#  Check if the script section is defined
		[bool]$ScriptSectionDefined = [bool]($false -eq [string]::IsNullOrEmpty($ScriptSection))
		#  Get the file name of the source script
		try {
			if ($false -eq [string]::IsNullOrEmpty($script:MyInvocation.Value.ScriptName)) {
				[string]$ScriptSource = Split-Path -Path $script:MyInvocation.Value.ScriptName -Leaf -ErrorAction 'Stop'
			}
			else {
				[string]$ScriptSource = Split-Path -Path $script:MyInvocation.MyCommand.Definition -Leaf -ErrorAction 'Stop'
			}
		}
		catch {
			[string]$ScriptSource = [string]::Empty
		}

		## Create script block for generating CMTrace.exe compatible log entry
		[ScriptBlock]$CMTraceLogString = {
			Param (
				[string]$lMessage,
				[string]$lSource,
				[Int16]$lSeverity
			)
			"<![LOG[$lMessage]LOG]!>" + "<time=`"$LogTimePlusBias`" " + "date=`"$LogDate`" " + "component=`"$lSource`" " + "context=`"$([Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " + "type=`"$lSeverity`" " + "thread=`"$PID`" " + "file=`"$ScriptSource`">"
		}

		## Create script block for writing log entry to the console
		[ScriptBlock]$WriteLogLineToHost = {
			Param (
				[string]$lTextLogLine,
				[Int16]$lSeverity
			)
			if ($true -eq $WriteHost) {
				#  Only output using color options if running in a host which supports colors.
				if ($null -ne $Host.UI.RawUI.ForegroundColor) {
					switch ($lSeverity) {
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
				else {
					Write-Output -InputObject ($lTextLogLine)
				}
			}
		}

		## Exit function if it is a debug message and logging debug messages is not enabled in the config XML file
		if (($true -eq $DebugMessage) -and ($false -eq $LogDebugMessage)) {
			[bool]$ExitLoggingFunction = $true
			return
		}
		## Exit function if logging to file is disabled and logging to console host is disabled
		if (($true -eq $DisableLogging) -and ($false -eq $WriteHost)) {
			[bool]$ExitLoggingFunction = $true
			return
		}
		## Exit Begin block if logging is disabled
		if ($true -eq $DisableLogging) {
			return
		}
		## Exit function function if it is an [Initialization] message and the toolkit has been relaunched
		if (($AsyncToolkitLaunch) -and ($ScriptSection -eq 'Initialization')) {
			[bool]$ExitLoggingFunction = $true
			return
		}

		## Create the directory where the log file will be saved
		if ($false -eq (Test-Path -LiteralPath $LogFileDirectory -PathType 'Container')) {
			try {
				New-Item -Path $LogFileDirectory -Type 'Directory' -Force -ErrorAction 'Stop' | Out-Null
			}
			catch {
				[bool]$ExitLoggingFunction = $true
				#  If error creating directory, write message to console
				if ($false -eq $ContinueOnError) {
					Write-Host -Object "[$LogDate $LogTime] [${cmdletName}] $ScriptSection :: Failed to create the log directory [$LogFileDirectory]. `r`n$(Resolve-Error)" -ForegroundColor 'Red'
				}
				return
			}
		}

		## Assemble the fully qualified path to the log file
		[string]$LogFilePath = Join-Path -Path $LogFileDirectory -ChildPath $LogFileName
	}
	Process {
		## Exit function if logging is disabled
		if ($true -eq $ExitLoggingFunction) {
			return
		}

		foreach ($Msg in $Message) {
			## If the message is not $null or empty, create the log entry for the different logging methods
			[string]$CMTraceMsg = [string]::Empty
			[string]$ConsoleLogLine = [string]::Empty
			[string]$LegacyTextLogLine = [string]::Empty
			if ($false -eq [string]::IsNullOrEmpty($Msg)) {
				#  Create the CMTrace log message
				if ($true -eq $ScriptSectionDefined) {
					[string]$CMTraceMsg = "[$ScriptSection] :: $Msg"
				}

				#  Create a Console and Legacy "text" log entry
				[string]$LegacyMsg = "[$LogDate $LogTime]"
				if ($true -eq $ScriptSectionDefined) {
					[string]$LegacyMsg += " [$ScriptSection]"
				}
				if ($false -eq [string]::IsNullOrEmpty($Source)) {
					[string]$ConsoleLogLine = "$LegacyMsg [$Source] :: $Msg"
					switch ($Severity) {
						3 {
							[string]$LegacyTextLogLine = "$LegacyMsg [$Source] [Error] :: $Msg"
						}
						2 {
							[string]$LegacyTextLogLine = "$LegacyMsg [$Source] [Warning] :: $Msg"
						}
						1 {
							[string]$LegacyTextLogLine = "$LegacyMsg [$Source] [Info] :: $Msg"
						}
					}
				}
				else {
					[string]$ConsoleLogLine = "$LegacyMsg :: $Msg"
					switch ($Severity) {
						3 {
							[string]$LegacyTextLogLine = "$LegacyMsg [Error] :: $Msg"
						}
						2 {
							[string]$LegacyTextLogLine = "$LegacyMsg [Warning] :: $Msg"
						}
						1 {
							[string]$LegacyTextLogLine = "$LegacyMsg [Info] :: $Msg"
						}
					}
				}
			}

			## Execute script block to create the CMTrace.exe compatible log entry
			[string]$CMTraceLogLine = & $CMTraceLogString -lMessage $CMTraceMsg -lSource $Source -lSeverity $Severity

			## Choose which log type to write to file
			if ($LogType -ieq 'CMTrace') {
				[string]$LogLine = $CMTraceLogLine
			}
			else {
				[string]$LogLine = $LegacyTextLogLine
			}

			## Write the log entry to the log file if logging is not currently disabled
			if ($false -eq $DisableLogging) {
				try {
					$LogLine | Out-File -FilePath $LogFilePath -Append -NoClobber -Force -Encoding 'UTF8' -ErrorAction 'Stop'
				}
				catch {
					if ($false -eq $ContinueOnError) {
						Write-Host -Object "[$LogDate $LogTime] [$ScriptSection] [${cmdletName}] :: Failed to write message [$Msg] to the log file [$LogFilePath]. `r`n$(Resolve-Error)" -ForegroundColor 'Red'
					}
				}
			}

			## Execute script block to write the log entry to the console if $WriteHost is $true
			& $WriteLogLineToHost -lTextLogLine $ConsoleLogLine -lSeverity $Severity
		}
	}
	End {
		## Archive log file if size is greater than $MaxLogFileSizeMB and $MaxLogFileSizeMB > 0
		try {
			if (($false -eq $ExitLoggingFunction) -and ($false -eq $DisableLogging)) {
				[IO.FileInfo]$LogFile = Get-ChildItem -LiteralPath $LogFilePath -ErrorAction 'Stop'
				[Decimal]$LogFileSizeMB = $LogFile.Length / 1MB
				if (($LogFileSizeMB -gt $MaxLogFileSizeMB) -and ($MaxLogFileSizeMB -gt 0)) {
					## Change the file extension to "lo_"
					[string]$ArchivedOutLogFile = [IO.Path]::ChangeExtension($LogFilePath, 'lo_')
					[Hashtable]$ArchiveLogParams = @{
						ScriptSection    = $ScriptSection
						Source           = ${cmdletName}
						Severity         = 2
						LogFileDirectory = $LogFileDirectory
						LogFileName      = $LogFileName
						LogType          = $LogType
						MaxLogFileSizeMB = 0
						WriteHost        = $WriteHost
						ContinueOnError  = $ContinueOnError
						PassThru         = $false
					}

					## Log message about archiving the log file
					[string]$ArchiveLogMessage = "Maximum log file size [$MaxLogFileSizeMB MB] reached. Rename log file to [$ArchivedOutLogFile]."
					Write-Log -Message $ArchiveLogMessage @ArchiveLogParams

					## Archive existing log file from <filename>.log to <filename>.lo_. Overwrites any existing <filename>.lo_ file. This is the same method SCCM uses for log files.
					Move-Item -LiteralPath $LogFilePath -Destination $ArchivedOutLogFile -Force -ErrorAction 'Stop'

					## Start new log file and Log message about archiving the old log file
					[string]$NewLogMessage = "Previous log file was renamed to [$ArchivedOutLogFile] because maximum log file size of [$MaxLogFileSizeMB MB] was reached."
					Write-Log -Message $NewLogMessage @ArchiveLogParams
				}
			}
		}
		catch {
			## If renaming of file fails, script will continue writing to log file even if size goes over the max file size
		}
		finally {
			if ($true -eq $PassThru) {
				Write-Output -InputObject ($Message)
			}
		}
	}
}
#endregion
#region Function Test-RegistryValue
function Test-RegistryValue {
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
		[ValidateNotNullOrEmpty()]
		[string]
		$Key,
		[Parameter(Mandatory = $true, Position = 1)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Value,
		[Parameter(Mandatory = $false, Position = 2)]
		[ValidateNotNullorEmpty()]
		[string]
		$SID
	)

	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		## If the SID variable is specified, then convert all HKEY_CURRENT_USER key's to HKEY_USERS\$SID
		try {
			if ($true -eq ($PSBoundParameters.ContainsKey('SID'))) {
				[string]$Key = Convert-RegistryPath -Key $Key -SID $SID
			}
			else {
				[string]$Key = Convert-RegistryPath -Key $Key
			}
		}
		catch {
			throw
		}
		[bool]$isRegistryValueExists = $false
		try {
			if ($true -eq (Test-Path -LiteralPath $Key -ErrorAction 'Stop')) {
				[String[]]$pathProperties = Get-Item -LiteralPath $Key -ErrorAction 'Stop' | Select-Object -ExpandProperty 'Property' -ErrorAction 'Stop'
				if ($pathProperties -contains $Value) {
					$isRegistryValueExists = $true
				}
			}
		}
		catch {
		}

		if ($true -eq $isRegistryValueExists) {
			Write-Log -Message "Registry key value [$Key] [$Value] does exist." -Source ${cmdletName}
		}
		else {
			Write-Log -Message "Registry key value [$Key] [$Value] does not exist." -Source ${cmdletName}
		}
		Write-Output -InputObject ($isRegistryValueExists)
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${cmdletName} -Footer
	}
}
#endregion
## global default variables
[string]$global:Neo42PackageConfigPath = "$PSScriptRoot\..\neo42PackageConfig.json"
## Several PSADT-functions do not work, if these variables are not set here.
$tempLoadPackageConfig = (Get-Content "$global:Neo42PackageConfigPath" -Raw ) | ConvertFrom-Json
[string]$appVendor = $tempLoadPackageConfig.AppVendor
[string]$appName = $tempLoadPackageConfig.AppName
[string]$appVersion = $tempLoadPackageConfig.AppVersion
[string]$global:AppLogFolder = "$env:ProgramData\$($tempLoadPackageConfig.AppRootFolder)Logs\$appVendor\$appName\$appVersion"
Remove-Variable -Name tempLoadPackageConfig

[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
[string]$scriptPath = $MyInvocation.MyCommand.Definition
[string]$scriptRoot = Split-Path -Path $scriptPath -Parent
[string]$appDeployConfigFile = Join-Path -Path $scriptRoot -ChildPath 'AppDeployToolkitConfig.xml'
[Xml.XmlDocument]$xmlConfigFile = Get-Content -LiteralPath $appDeployConfigFile -Encoding 'UTF8'
[Xml.XmlElement]$xmlConfig = $xmlConfigFile.AppDeployToolkit_Config
#  Get Toolkit Options
[Xml.XmlElement]$xmlToolkitOptions = $xmlConfig.Toolkit_Options
[string]$configToolkitLogDir = $ExecutionContext.InvokeCommand.ExpandString($xmlToolkitOptions.Toolkit_LogPathNoAdminRights)
[string]$configToolkitLogStyle = $xmlToolkitOptions.Toolkit_LogStyle
[Double]$configToolkitLogMaxSize = $xmlToolkitOptions.Toolkit_LogMaxSize
[bool]$configToolkitLogWriteToHost = [bool]::Parse($xmlToolkitOptions.Toolkit_LogWriteToHost)
[bool]$configToolkitLogDebugMessage = [bool]::Parse($xmlToolkitOptions.Toolkit_LogDebugMessage)
[string]$appDeployCustomTypesSourceCode = Join-Path -Path $scriptRoot -ChildPath 'AppDeployToolkitMain.cs'
if ($false -eq (Test-Path -LiteralPath $appDeployConfigFile -PathType 'Leaf')) {
	throw 'App Deploy XML configuration file not found.'
}
if ($false -eq (Test-Path -LiteralPath $appDeployCustomTypesSourceCode -PathType 'Leaf')) {
	throw 'App Deploy custom types source code file not found.'
}

## Add the custom types required for the toolkit
if ($null -eq ([Management.Automation.PSTypeName]'PSADT.UiAutomation').Type) {
	[String[]]$referencedAssemblies = 'System.Drawing', 'System.Windows.Forms', 'System.DirectoryServices'
	Add-Type -Path $appDeployCustomTypesSourceCode -ReferencedAssemblies $referencedAssemblies -IgnoreWarnings -ErrorAction 'Stop'
}

[string]$inputXML = @'
<Window x:Class="Neo42.Progressbar.MainWindow"
		xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
		xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		xmlns:d="http://schemas.microsoft.com/expression/blend/2008" Background="Red"
		xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" WindowStartupLocation="CenterScreen"
		ResizeMode="NoResize" WindowStyle="None"
		mc:Ignorable="d" SizeToContent="Height" x:Name="ProgressBarMainWindow"
		Width="500">
    <Window.Resources>
        <Color x:Key="ErrorColor" A="255" R="236" G="105" B="53" ></Color>
        <SolidColorBrush x:Key="ErrorColorBrush" Color="{DynamicResource ErrorColor}"></SolidColorBrush>
        <Color x:Key="MainColor" A="255" R="227" G="0" B="15" ></Color>
        <SolidColorBrush x:Key="MainColorBrush" Color="{DynamicResource MainColor}"></SolidColorBrush>
        <Color x:Key="BackColor" A="255" R="40" G="40" B="39" />
        <SolidColorBrush x:Key="BackColorBrush" Color="{DynamicResource BackColor}"></SolidColorBrush>
        <Color x:Key="BackLightColor" A="255" R="87" G="86" B="86" />
        <SolidColorBrush x:Key="BackLightColorBrush" Color="{DynamicResource BackLightColor}"></SolidColorBrush>
        <Color x:Key="ForeColor" A="255" R="255" G="255" B="255" />
        <SolidColorBrush x:Key="ForeColorBrush" Color="{DynamicResource ForeColor}"></SolidColorBrush>
        <Color x:Key="MouseHoverColor" A="255" R="200" G="200" B="200" />
        <SolidColorBrush x:Key="MouseHoverColorBrush" Color="{DynamicResource MouseHoverColor}"></SolidColorBrush>
        <Color x:Key="PressedColor" A="255" R="87" G="86" B="86" />
        <SolidColorBrush x:Key="PressedBrush" Color="{DynamicResource PressedColor}"></SolidColorBrush>
        <Style TargetType="TextBlock">
            <Setter Property="Margin" Value="5"></Setter>
            <Setter Property="FontSize" Value="12"></Setter>
            <Setter Property="Foreground" Value="{DynamicResource ForeColorBrush}"></Setter>
        </Style>
    </Window.Resources>
    <DockPanel x:Name="MainPanel" Background="{DynamicResource BackColorBrush}">
		<DockPanel x:Name="HeaderPanel" HorizontalAlignment="Stretch" Height="30" DockPanel.Dock="Top" Background="{DynamicResource BackColorBrush}">
			<TextBlock DockPanel.Dock="Left" x:Name="TitleText" VerticalAlignment="Center" Text="[will be replaced later]" FontWeight="Bold" FontSize="14" />
		</DockPanel>
        <StackPanel DockPanel.Dock="Top" Margin="0,10,0,0">
            <TextBlock x:Name="HeaderText" TextAlignment="Center" TextWrapping="Wrap" Text="[will be replaced later]" HorizontalAlignment="Left" ></TextBlock>
			<Image x:Name="Icon" Width="32" Height="32" HorizontalAlignment="Left" Margin="5"/>
			<ProgressBar Height="30" IsIndeterminate="True" Background="{DynamicResource PressedBrush}" Foreground="{DynamicResource MainColorBrush}" Margin="5" BorderThickness="0"/>
        </StackPanel>
    </DockPanel>
</Window>
'@

[System.Windows.Window]$control = New-NxtWpfControl $inputXML

[System.Windows.Media.Color]$backColor = $control.Resources['BackColor']
[System.Windows.Media.Color]$backLightColor = $control.Resources['BackLightColor']
[System.Windows.Media.Color]$foreColor = $control.Resources['ForeColor']
[System.Windows.Media.Color]$mouseHoverColor = $control.Resources['MouseHoverColor']
[System.Windows.Media.Color]$pressedColor = $control.Resources['PressedColor']

[System.Windows.Window]$control_MainWindow = $control.FindName('ProgressBarMainWindow')
[System.Windows.Controls.TextBlock]$control_TitleText = $control.FindName('TitleText')
[System.Windows.Controls.TextBlock]$control_HeaderText = $control.FindName('HeaderText')
[System.Windows.Controls.Image]$control_Icon = $control.FindName('Icon')
[System.Windows.Controls.DockPanel]$control_HeaderPanel = $control.FindName('HeaderPanel')

$control_MainWindow.TopMost = $TopMost

[ScriptBlock]$windowLeftButtonDownHandler = {
	# Check if the left mouse button is pressed
	if ($_.ChangedButton -eq [System.Windows.Input.MouseButton]::Left) {
		# Call the DragMove method to allow the user to move the window
		$control_MainWindow.DragMove()
	}
}

$control_HeaderPanel.add_MouseLeftButtonDown($windowLeftButtonDownHandler)

[ScriptBlock]$mainWindowClosed = {
	try {
		$control_HeaderPanel.remove_MouseLeftButtonDown($windowLeftButtonDownHandler)
		$control_MainWindow.remove_Closed($mainWindowClosed)
	}
	catch {
	}
}

$control_MainWindow.Add_Closed($mainWindowClosed)

[bool]$isLightTheme = Test-NxtPersonalizationLightTheme

if ($true -eq $isLightTheme) {
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
}
## try to find the correct language for the current sessions user
[int]$ownSessionId = (Get-Process -Id $PID).SessionId
[PSObject]$runAsActiveUser = Get-LoggedOnUser | Where-Object {
	$_.SessionId -eq $ownSessionId
}
## Get current sessions UI language
## Get primary UI language for current sessions user (even if running as system)
if ($null -ne $runAsActiveUser) {
	#  Read language defined by Group Policy
	if ($true -eq [string]::IsNullOrEmpty($hKULanguages)) {
		[string[]]$hKULanguages = Get-RegistryKey -Key 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\MUI\Settings' -Value 'PreferredUILanguages'
	}
	if ($true -eq [string]::IsNullOrEmpty($hKULanguages)) {
		[string[]]$hKULanguages = Get-RegistryKey -Key 'Registry::HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Control Panel\Desktop' -Value 'PreferredUILanguages' -SID $runAsActiveUser.SID
	}
	#  Read language for Win Vista & higher machines
	if ($true -eq [string]::IsNullOrEmpty($hKULanguages)) {
		[string[]]$hKULanguages = Get-RegistryKey -Key 'Registry::HKEY_CURRENT_USER\Control Panel\Desktop' -Value 'PreferredUILanguages' -SID $runAsActiveUser.SID
	}
	if ($true -eq [string]::IsNullOrEmpty($hKULanguages)) {
		[string[]]$hKULanguages = Get-RegistryKey -Key 'Registry::HKEY_CURRENT_USER\Control Panel\Desktop\MuiCached' -Value 'MachinePreferredUILanguages' -SID $runAsActiveUser.SID
	}
	if ($true -eq [string]::IsNullOrEmpty($hKULanguages)) {
		[string[]]$hKULanguages = Get-RegistryKey -Key 'Registry::HKEY_CURRENT_USER\Control Panel\International' -Value 'LocaleName' -SID $runAsActiveUser.SID
	}
	#  Read language for Win XP machines
	if ($true -eq [string]::IsNullOrEmpty($hKULanguages)) {
		[string]$hKULocale = Get-RegistryKey -Key 'Registry::HKEY_CURRENT_USER\Control Panel\International' -Value 'Locale' -SID $runAsActiveUser.SID
		if ($false -eq [string]::IsNullOrEmpty($hKULocale)) {
			[Int32]$hKULocale = [Convert]::ToInt32('0x' + $hKULocale, 16)
			[string[]]$hKULanguages = ([Globalization.CultureInfo]($hKULocale)).Name
		}
	}
	if ($hKULanguages.Count -gt 0 -and ($false -eq [string]::IsNullOrWhiteSpace($hKULanguages[0]))) {
		[Globalization.CultureInfo]$primaryWindowsUILanguage = [Globalization.CultureInfo]($hKULanguages[0])
		[string]$hKUPrimaryLanguageShort = $primaryWindowsUILanguage.TwoLetterISOLanguageName.ToUpper()
		#  If the detected language is Chinese, determine if it is simplified or traditional Chinese
		if ($hKUPrimaryLanguageShort -eq 'ZH') {
			if ($primaryWindowsUILanguage.EnglishName -match 'Simplified') {
				[string]$hKUPrimaryLanguageShort = 'ZH-Hans'
			}
			if ($primaryWindowsUILanguage.EnglishName -match 'Traditional') {
				[string]$hKUPrimaryLanguageShort = 'ZH-Hant'
			}
		}
		#  If the detected language is Portuguese, determine if it is Brazilian Portuguese
		if ($hKUPrimaryLanguageShort -eq 'PT') {
			if ($primaryWindowsUILanguage.ThreeLetterWindowsLanguageName -eq 'PTB') {
				[string]$hKUPrimaryLanguageShort = 'PT-BR'
			}
		}
	}
}
if ($false -eq [string]::IsNullOrEmpty($hKUPrimaryLanguageShort)) {
	#  Use the primary UI language of the current sessions user
	[string]$xmlUIMessageLanguage = "UI_Messages_$hKUPrimaryLanguageShort"
}
else {
	#  Default to UI language of the account executing current process (even if it is the SYSTEM account)
	[string]$xmlUIMessageLanguage = "UI_Messages_$currentLanguage"
}
#  Default to English if the detected UI language is not available in the XMl config file
if ($null -eq $xmlConfig.$xmlUIMessageLanguage) {
	[string]$xmlUIMessageLanguage = 'UI_Messages_EN'
}
##  Also default to English if the detected UI language has no nxt messages
if (($xmlConfig.$xmlUIMessageLanguage.ChildNodes.Name -imatch '^NxtWelcomePrompt_.*').Count -eq 0) {
	[string]$xmlUIMessageLanguage = 'UI_Messages_EN'
}
#  Override the detected language if the override option was specified in the XML config file
if ($false -eq [string]::IsNullOrEmpty($configInstallationUILanguageOverride)) {
	[string]$xmlUIMessageLanguage = "UI_Messages_$configInstallationUILanguageOverride"
}
[Xml.XmlElement]$xmlUIMessages = $xmlConfig.$xmlUIMessageLanguage

if ([string]::IsNullOrEmpty($Title)) {
	$control_TitleText.Text = $Packagename
}
else {
	$control_TitleText.Text = $Title
}

if ([string]::IsNullOrEmpty($HeaderText)) {
	$control_HeaderText.Text = $xmlUIMessages.NxtProgressbar_HeaderText -f $Packagename
}
else {
	$control_HeaderText.Text = $HeaderText
}

if ([string]::IsNullOrEmpty($IconPath)) {
	$IconPath = Join-Path -Path (Split-Path -Path $scriptRoot -Parent) -ChildPath 'Setup.ico'
}

if (Test-Path $IconPath) {
	$control_Icon.Source = $IconPath
}

switch ($IconAlignment) {
	'Left' {
		$control_Icon.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
	}
	'Center' {
		$control_Icon.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
	}
	'Right' {
		$control_Icon.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
	}
	Default {
		$control_Icon.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
	}
}

if ($WinHide -ne $null) {
	Hide-Windows -ProcessNames $WinHide
}

if ($true -eq $End) {
	Stop-ProgressbarByProcessTree
}

if ($true -eq $Kill) {
	Stop-AllProgressbars
}

# Open dialog and Wait
if ($false -eq $End -and $false -eq $Kill) {
	$control_MainWindow.ShowDialog() | Out-Null
}

exit
#endregion

