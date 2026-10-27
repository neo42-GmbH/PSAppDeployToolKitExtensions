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
			[PSADTNXT.Foundation.NxtDeploymentSession]$adtSession = Get-ADTSession
			switch ($adtSession.NXT.DeploymentSystem) {
				'Empirum' {
					Initialize-NXTEmpirum
					Invoke-NXTEmpirumPreAction

					if ($script:Hooked) { return }
					Write-ADTLogEntry -Message 'Adding [Empirum] based deployment logic into module hooks.'
					Add-ADTModuleCallback -HookPoint PostClose -Callback $script:CommandTable.'Invoke-NXTEmpirumPostAction'
					Add-NXTDeploymentCallback -HookPoint CustomInstallAndReinstallPreInstallAndReinstall -Callback $script:CommandTable.'Remove-NXTOldEmpirumApplication' -Prepend
					Add-NXTDeploymentCallback -HookPoint CustomSoftMigrationEnd -Callback $script:CommandTable.'Remove-NXTOldEmpirumApplication' -Prepend
					Add-NXTDeploymentCallback -HookPoint CustomUninstallEnd -Callback $script:CommandTable.'Remove-NXTCurrentEmpirumEntry' -Prepend
				}
			}

			$script:Hooked = $true
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}

