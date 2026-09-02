function Test-NXTUiLightTheme {
	<#
	.SYNOPSIS
	Checks if the current UI theme is light.
	.DESCRIPTION
	Checks if the current UI theme is light by checking the registry keys for the light theme settings.
	Will try to read the 'AppsUseLightTheme' and 'SystemUsesLightTheme' registry values.
	.PARAMETER Identity
	The Identifier (e.g. Sid) of the user to check the theme for. If not specified, the current user will be used.
	.EXAMPLE
	Test-NXTUiLightTheme

	Checks if the current UI theme is light and returns a boolean value.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidLongLines', '', Justification = 'Line length is acceptable for readability')]
	[OutputType([System.Boolean])]
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Alias('SID')]
		[PSADTNXT.Attributes.IdentityReferenceTransformation()]
		[System.Security.Principal.IdentityReference]
		$Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[Microsoft.Win32.RegistryKey]$registryKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
				[Microsoft.Win32.RegistryHive]::Users,
				[Microsoft.Win32.RegistryView]::Registry64
			).OpenSubKey(
				"$($Identity.Translate([System.Security.Principal.SecurityIdentifier]).Value)\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
			)

			if (-not $registryKey) {
				return $true
			}
			if ($null -ne ([System.Nullable[System.Int32]]$app = $registryKey.GetValue('AppsUseLightTheme'))) {
				return $app -eq 1
			}
			elseif ($null -ne ([System.Nullable[System.Int32]]$system = $registryKey.GetValue('SystemUsesLightTheme'))) {
				return $system -eq 1
			}
			else {
				# Fallback to default light theme
				return $true
			}
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
		finally {
			if ($registryKey) {
				$registryKey.Close()
			}
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
