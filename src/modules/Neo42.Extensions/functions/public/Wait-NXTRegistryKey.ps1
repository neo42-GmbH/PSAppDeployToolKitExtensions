function Wait-NXTRegistryKey {
	<#
	.SYNOPSIS
	Watches a specified registry key for its existence or removal for a given duration.
	.DESCRIPTION
	This command monitors a specified registry key and checks for its existence or removal within a defined timeout period.
	It is useful for scenarios where the presence or absence of a registry key is required for certain processes or checks.
	.INPUTS
	Microsoft.Win32.RegistryKey - The registry key to monitor.
	.OUTPUTS
	System.Boolean - Returns true if the registry key exist within the timeout period, otherwise false.
	PSCustomObject - Returns the registry key values as custom object if PassThru was specified
	If the -IsRemoved switch is specified, the test will be inverted.
	.PARAMETER Key
	The path to the registry key to monitor.
	.Parameter Name
	The name of the registry key to monitor.
	.Parameter Value
	The value of the registry key to monitor.
	.PARAMETER Wow6432Node
	Specifies that the registry key is located in the Wow6432Node.
	.PARAMETER Timeout
	The maximum time to wait for the registry key to be created or removed.
	.PARAMETER Interval
	The interval at which to check for the registry key's presence or removal.
	.PARAMETER PassThru
	Instead of returning a boolean, return the object containing the properties.
	If no properties exist, the key itself is returned.
	.PARAMETER IsRemoved
	Instead of checking for the presence of the registry key, check for its removal.
	.EXAMPLE
	Wait-NXTRegistryKey -Key "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"

	This example monitors the specified registry key and waits up to 60 seconds to check its existence.
	.EXAMPLE
	Wait-NXTRegistryKey -Key "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams" -IsRemoved

	This example monitors the specified registry key and waits up to 60 seconds to check its existence has ended.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'The values will be used in scriptblocks.')]
	[OutputType([System.Boolean], [PSCustomObject], [Microsoft.Win32.RegistryKey])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('PSPath', 'Path')]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Key,
		[System.String]
		$Name,
		[System.String]
		$Value,
		[System.Management.Automation.SwitchParameter]
		$Wow6432Node,
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$Timeout = '00:01:00',
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$Interval = '00:00:01.000',
		[System.Management.Automation.SwitchParameter]
		$PassThru,
		[System.Management.Automation.SwitchParameter]
		$IsRemoved
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[System.String]$convertedKey = Convert-ADTRegistryPath -Key $Key -Wow6432Node:$Wow6432Node
			[System.Management.Automation.ScriptBlock]$getKey = {
				[System.Collections.Hashtable]$getKeyParam = @{
					Path                   = $convertedKey
					ReturnEmptyKeyIfExists = $true
					InformationAction      = 'SilentlyContinue'
					WarningAction          = 'SilentlyContinue'
					ErrorAction            = 'SilentlyContinue'
				}
				if (-not [System.String]::IsNullOrWhiteSpace($Name)) { $getKeyParam.Add('Name', $Name) }
				$keyObj = Get-ADTRegistryKey @getKeyParam
				if (-not [System.String]::IsNullOrWhiteSpace($Value)) {
					if ($keyObj) {
						return $Value -eq $keyObj
					}
					else {
						return $false
					}
				}
				return $null -ne $keyObj
			}
			if ($IsRemoved) {
				[System.Management.Automation.ScriptBlock]$waitWhile = { $getKey.Invoke() }
				[System.String]$successMessage = "The registry key [$convertedKey] was removed within the specified timeout of  [$Timeout]."
				[System.String]$failureMessage = "The registry key [$convertedKey] is still present after the specified timeout of [$Timeout]."
			}
			else {
				[System.Management.Automation.ScriptBlock]$waitWhile = { -not $getKey.Invoke() }
				[System.String]$successMessage = "The registry key [$convertedKey] was created within the specified timeout of [$Timeout]."
				[System.String]$failureMessage = "The registry key [$convertedKey] is still not created after the specified timeout of [$Timeout]."
			}
			[System.Boolean]$result = $true
			[System.String]$severity = 'Info'
			[System.String]$message = $successMessage
			[System.DateTime]$endTime = [System.DateTime]::Now.Add($Timeout)
			while ($waitWhile.Invoke()) {
				if ([System.DateTime]::Now -ge $endTime) {
					$result = $false
					$severity = 'Warning'
					$message = $failureMessage
					break
				}
				Start-Sleep -Milliseconds $Interval.TotalMilliseconds
			}
			Write-ADTLogEntry -Message $message -Severity $severity -DebugMessage
			if ($PassThru) {
				if ($IsRemoved) {
					return (if ($result) { $null } else { $getKey.Invoke() })
				}
				else {
					return (if ($result) { $getKey.Invoke() } else { $null })
				}
			}
			else {
				return $result
			}
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
