function Initialize-NXTModule {
	<#
	.SYNOPSIS
	This function is called on initialization and adds the deployment specific hooks.
	#>
	[CmdletBinding()]
	param ()
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if ($script:Hooked) { return }
			$script:Hooked = $true

			[PSADTNXT.Foundation.NxtDeploymentSession]$adtSession = Get-ADTSession
			switch ($adtSession.NXT.DeploymentSystem) {
				'Empirum' {
					Write-ADTLogEntry -Message 'Activating [Empirum] based deployment logic for this session.'
					Initialize-NXTEmpirum

					Add-ADTModuleCallback -HookPoint PostOpen -Callback $script:CommandTable.'Invoke-NXTEmpirumPreAction'
					Add-ADTModuleCallback -HookPoint PostClose -Callback $script:CommandTable.'Invoke-NXTEmpirumPostAction'

					Add-NXTDeploymentCallback -HookPoint CustomInstallAndReinstallPreInstallAndReinstall -Callback $script:CommandTable.'Remove-NXTOldEmpirumApplication' -Prepend
					Add-NXTDeploymentCallback -HookPoint CustomInstallAndReinstallAndSoftMigrationEnd -Callback $script:CommandTable.'Remove-NXTOldEmpirumApplication' -Prepend
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

