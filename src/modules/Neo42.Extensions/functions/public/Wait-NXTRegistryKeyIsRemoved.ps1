
function Wait-NXTRegistryKeyIsRemoved {
	<#
	.SYNOPSIS
	Watches a specified registry key for a given duration.
	.DESCRIPTION
	This command monitors a specified registry key and checks for its existence within a defined timeout period.
	It is useful for scenarios where the presence of a registry key is required for certain processes or checks.
	.INPUTS
	Microsoft.Win32.RegistryKey - The registry key to monitor.
	.OUTPUTS
	System.Boolean - Returns true if the registry key(s) exist within the timeout period, otherwise false.
	.PARAMETER Key
	The path to the registry key(s) to monitor. Can be a single key or an array of keys.
	.PARAMETER Wow6432Node
	Specifies that the registry key is located in the Wow6432Node.
	.PARAMETER Timeout
	The maximum time to wait for the registry key(s) to be created.
	.EXAMPLE
	Wait-NXTRegistryKeyIsRemoved -Path "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"

	This example monitors the specified registry key and waits up to 60 seconds to check its existence has ended.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Wow6432Node', Justification = 'The parameter is used in the function body.')]
	[OutputType([System.Boolean])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('PSPath', 'Name')]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Key,
		[System.Management.Automation.SwitchParameter]
		$Wow6432Node,
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$Timeout = '00:01:00'
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[System.String]$convertedKey = Convert-ADTRegistryPath -Key $Key -Wow6432Node:$Wow6432Node
			[System.DateTime]$endTime = [System.DateTime]::Now.Add($Timeout)
			while (Test-Path -LiteralPath $convertedKey) {
				if ([System.DateTime]::Now -ge $endTime) {
					Write-ADTLogEntry -Severity Warning -Message "The specified registry key is still present after [$Timeout]." -DebugMessage
					return $false
				}
				Start-Sleep -Seconds 1
			}
			Write-ADTLogEntry -Message "The registry key was removed after [$Timeout]." -DebugMessage
			return $true
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
