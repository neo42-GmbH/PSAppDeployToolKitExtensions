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
					if (-not $script:Hooked) {
						Write-ADTLogEntry -Message 'Adding [Empirum] based deployment logic into module hooks.'
						Add-ADTModuleCallback -HookPoint PostClose -Callback $script:CommandTable.'Invoke-NXTEmpirumPostAction'
						Add-NXTDeploymentCallback -HookPoint CustomInstallAndReinstallPreInstallAndReinstall -Callback $script:CommandTable.'Remove-NXTOldEmpirumApplication' -Prepend
						Add-NXTDeploymentCallback -HookPoint CustomSoftMigrationEnd -Callback $script:CommandTable.'Remove-NXTOldEmpirumApplication' -Prepend
						Add-NXTDeploymentCallback -HookPoint CustomUninstallEnd -Callback $script:CommandTable.'Remove-NXTCurrentEmpirumEntry' -Prepend
					}

					# Usually initialized by the configuration callback already, but ensures the data is available for the deployment hooks
					Initialize-NXTEmpirum
				}
			}

			$script:Hooked = $true
		}
		catch {
			# Close the session directly, as errors in PostOpen callbacks would otherwise not result in a failing exit code
			Write-ADTLogEntry -Severity Error -Message (Resolve-ADTErrorRecord -ErrorRecord $_)
			$adtSession.NXT.ErrorMessage = $_.Exception.Message
			$adtSession.NXT.ErrorPhase = $adtSession.InstallPhase
			Close-ADTSession -ExitCode 60008
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}

