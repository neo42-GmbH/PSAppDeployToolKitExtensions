function Remove-NXTCurrentEmpirumEntry {
	<#
	.SYNOPSIS
	Remove the current empirum registry on uninstall, if it has been manually invoked
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This is an internal function.')]
	[CmdletBinding()]
	param ()
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[PSADTNXT.Foundation.NxtDeploymentSession]$adtSession = Get-ADTSession

			if (([System.Diagnostics.Process[]]$parents = Get-NXTParentProcess -Id $PID -Recurse) -and $parents.ProcessName -like 'Setup*') {
				Write-ADTLogEntry -DebugMessage -Message 'We are running as a sub process of Setup.exe. Cleanup will be handled by it.'
				return
			}

			Write-ADTLogEntry -Message 'Detected manual cleanup of Empirum context application. Cleanup up Empirum entry.'

			[System.String]$regPackageKey = $adtSession.NXT.Package.RegistryKey.Split('\')[1]
			[System.String]$keyRef = "SOFTWARE\$($regPackageKey)\$($adtSession.AppVendor)\$($adtSession.AppName)\$($adtSession.AppVersion)"

			[Microsoft.Win32.RegistryKey]$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
			if ([Microsoft.Win32.RegistryKey]$empKey = $baseKey.OpenSubKey($keyRef)) {
				[PSADTNXT.Extensions.NxtRegistryExtensions]::DeleteTree($empKey)
				[Microsoft.Win32.RegistryKey]$empAppKey = [PSADTNXT.Extensions.NxtRegistryExtensions]::GetParent($empKey)
				Remove-NXTEmptyRegistryKey -Key $empAppKey.Name
				[Microsoft.Win32.RegistryKey]$empVendorKey = [PSADTNXT.Extensions.NxtRegistryExtensions]::GetParent($empAppKey)
				$empAppKey.Close()
				Remove-NXTEmptyRegistryKey -Key $empVendorKey.Name
				$empVendorKey.Close()
			}
			$baseKey.Close()

			Invoke-ADTAllUsersRegistryAction -UserProfiles (Get-ADTUserProfiles -ExcludeDefaultUser -InformationAction SilentlyContinue) -InformationAction SilentlyContinue -ScriptBlock {
				[System.String]$sidValue = $_.SID.Value
				[Microsoft.Win32.RegistryKey]$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::Users, [Microsoft.Win32.RegistryView]::Registry64)
				if ([Microsoft.Win32.RegistryKey]$empKey = $baseKey.OpenSubKey("$sidValue\$keyRef")) {
					[PSADTNXT.Extensions.NxtRegistryExtensions]::DeleteTree($empKey)
					[Microsoft.Win32.RegistryKey]$empAppKey = [PSADTNXT.Extensions.NxtRegistryExtensions]::GetParent($empKey)
					Remove-NXTEmptyRegistryKey -Key $empAppKey.Name
					[Microsoft.Win32.RegistryKey]$empVendorKey = [PSADTNXT.Extensions.NxtRegistryExtensions]::GetParent($empAppKey)
					$empAppKey.Close()
					Remove-NXTEmptyRegistryKey -Key $empVendorKey.Name
					$empVendorKey.Close()
				}
				$baseKey.Close()
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
