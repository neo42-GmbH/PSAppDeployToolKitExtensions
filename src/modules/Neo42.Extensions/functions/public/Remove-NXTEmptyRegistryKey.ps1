function Remove-NXTEmptyRegistryKey {
	<#
	.SYNOPSIS
	Removes only empty registry keys
	.DESCRIPTION
	This function is designed to remove registry keys if and only if they are empty. If the specified registry contains any values or sub keys,
	the function continues without taking any action.
	.INPUTS
	Microsoft.Win32.RegistryKey[] - The registry key(s) to remove.
	.PARAMETER Key
	The registry key(s) to remove.
	.PARAMETER Wow6432Node
	Specifies whether to include the Wow6432Node on 64-bit systems.
	.PARAMETER Sid
	The SID of the user to use for the registry key in case of a user registry key.
	.EXAMPLE
	Remove-NxtEmptyRegistryKey -Key "HKLM:\Software\EmptyKey"

	This example removes the specified empty key located at "HKLM:\Software\EmptyKey".
	#>
	[CmdletBinding(SupportsShouldProcess)]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('PSPath', 'Name', 'Path')]
		[SupportsWildcards()][ValidateNotNullOrEmpty()]
		[System.String]
		$Key,
		[System.Management.Automation.SwitchParameter]
		$Wow6432Node,
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Sid
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			$null = $PSBoundParameters.Remove('Key')
			Get-ADTRegistryKey @PSBoundParameters -Key $Key -ReturnEmptyKeyIfExists -InformationAction SilentlyContinue | & {
				process {
					# Only if the key is empty, the function will return the key as [Microsoft.Win32.RegistryKey].
					if ($_ -is [Microsoft.Win32.RegistryKey] -and $_.GetSubKeyNames().Count -eq 0 -and $PSCmdlet.ShouldProcess($Key, 'Remove')) {
						Write-ADTLogEntry -Message "Removing empty registry key [$($_.Name)]" -DebugMessage
						Remove-ADTRegistryKey @PSBoundParameters -Key $_.Name
					}
					else {
						Write-ADTLogEntry -Message "The registry key [$($_.Name)] is not empty. Skipping removal." -DebugMessage
					}
				}
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
