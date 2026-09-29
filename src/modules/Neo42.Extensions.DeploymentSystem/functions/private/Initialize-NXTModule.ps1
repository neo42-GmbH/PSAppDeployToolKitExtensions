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
					Write-ADTLogEntry -Message 'Activating [Empirum] based deployment logic for this session.'

					Add-ADTModuleCallback -HookPoint 'OnStart' -Callback $script:CommandTable.'Initialize-NXTModule'
					Add-ADTModuleCallback -HookPoint 'PostOpen' -Callback $script:CommandTable.'Invoke-NXTEmpirumPreAction'
					Add-ADTModuleCallback -HookPoint 'PostClose' -Callback $script:CommandTable.'Invoke-NXTEmpirumPostAction'

					Add-NXTDeploymentCallback -HookPoint 'CustomInstallAndReinstallAndSoftMigrationBegin' -Callback $script:CommandTable.'Remove-NXTOldEmpirumApplication'
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

