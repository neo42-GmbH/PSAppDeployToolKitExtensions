function Complete-NXTDeployment {
	<#
	.SYNOPSIS
	Post deployment tasks for NXT deployment sessions.
	#>
	param (
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession),
		[System.String]
		$ErrorMessage
	)
	try {
		$ADTSession.InstallPhase = "$($ADTSession.NXT.DeploymentType):Completion"

		if ($ADTSession.GetDeploymentStatus() -eq [PSADT.Module.DeploymentStatus]::Error) {
			Register-NXTPackage -ADTSession $ADTSession -AsError -ErrorMessage $ErrorMessage
			return
		}

		if ($ADTSession.NXT.DeploymentType.IsInstall) {
			if ($ADTSession.NXT.Package.Register) {
				Write-ADTLogEntry -Message 'Copying package to cache.'
				Copy-NXTPackageToCache -ADTSession $ADTSession
			}

			Invoke-NXTShortcutOperation -ADTSession $ADTSession -Purge:$($ADTSession.NXT.SetupCfg['Options']['DESKTOPSHORTCUT'] -ne '1')

			Invoke-NXTArpKeyOperation -ADTSession $ADTSession

			Invoke-NXTUserPart -ADTSession $ADTSession

			Register-NXTPackage -ADTSession $ADTSession

			Write-ADTLogEntry -Severity Success -Message 'Post installation logic completed successfully.'
		}
		else {
			Invoke-NXTShortcutOperation -ADTSession $ADTSession -Purge

			Invoke-NXTUserPart -ADTSession $ADTSession

			Remove-NXTPackageDirectory -ADTSession $ADTSession

			[Microsoft.Win32.RegistryKey]$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
			Write-ADTLogEntry -Message "Unregistering package [$($ADTSession.NXT.Package.GUID)]."
			$baseKey.DeleteSubKeyTree($ADTSession.NXT.Package.RegistryKey, $false)
			$baseKey.DeleteSubKeyTree("$($ADTSession.NXT.Package.RegistryKey)_Error", $false)
			$baseKey.DeleteSubKeyTree("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($ADTSession.NXT.Package.GUID)", $false)
			$baseKey.Close()

			Write-ADTLogEntry -Severity Success -Message 'Post uninstallation logic completed successfully.'
		}
	}
	catch {
		Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
	}
}
