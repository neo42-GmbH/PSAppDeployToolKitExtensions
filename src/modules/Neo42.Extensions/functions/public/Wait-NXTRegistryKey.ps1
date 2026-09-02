
function Wait-NXTRegistryKey {
	<#
	.SYNOPSIS
	Watches a specified registry key for a given duration.
	.DESCRIPTION
	This command monitors a specified registry key and checks for its existence within a defined timeout period.
	It is useful for scenarios where the presence of a registry key is required for certain processes or checks.
	.INPUTS
	Microsoft.Win32.RegistryKey - The registry key to monitor.
	.OUTPUTS
	System.Boolean - Returns true if the registry key exist within the timeout period, otherwise false.

	Microsoft.Win32.RegistryKey - Returns the registry key if PassThru was specified
	.PARAMETER Key
	The path to the registry key to monitor.
	.PARAMETER Wow6432Node
	Specifies that the registry key is located in the Wow6432Node.
	.PARAMETER Timeout
	The maximum time to wait for the registry key to be created.
	.PARAMETER PassThru
	Instead of returning a boolean, return the object.
	.EXAMPLE
	Wait-NXTRegistryKey -Key "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"

	This example monitors the specified registry key and waits up to 60 seconds to check its existence.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'The parameter is used in the function body.')]
	[OutputType([System.Boolean], [Microsoft.Win32.RegistryKey])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('PSPath', 'Name')]
		[SupportsWildcards()][ValidateNotNullOrEmpty()]
		[System.String[]]
		$Key,
		[System.Management.Automation.SwitchParameter]
		$Wow6432Node,
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$Timeout = '00:01:00',
		[System.Management.Automation.SwitchParameter]
		$PassThru
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[System.String]$convertedKey = Convert-ADTRegistryPath -Key $Key -Wow6432Node:$Wow6432Node
			[System.DateTime]$endTime = [System.DateTime]::Now.Add($Timeout)
			while (-not ([Microsoft.Win32.RegistryKey]$keyObj = Get-ADTRegistryKey -Key $convertedKey -WarningAction SilentlyContinue -InformationAction SilentlyContinue)) {
				if ([System.DateTime]::Now -ge $endTime) {
					Write-ADTLogEntry -Severity Warning -Message "Tthe specified registry key is still not created after [$Timeout]." -DebugMessage
					if ($PassThru) {
						return $null
					}
					else {
						return $false
					}
				}
				Start-Sleep -Seconds 1
			}
			Write-ADTLogEntry -Message "The registry key were created after [$Timeout]." -DebugMessage
			if ($PassThru) {
				return $keyObj
			}
			else {
				return $true
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
