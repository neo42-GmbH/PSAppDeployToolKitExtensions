function Invoke-NXTEmpirumPostAction {
	<#
	.SYNOPSIS
	Invokes Empirum specific post session tasks.
	#>
	[CmdletBinding()]
	param ()
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[PSADTNXT.Foundation.NxtDeploymentSession]$adtSession = Get-ADTSession
			if ($adtSession.NXT.DeploymentSystem -ne 'Empirum') { return }

			# Copy failed installation logs to the SetupErrorLog directory
			if ($adtSession.GetDeploymentStatus() -eq [PSADT.Module.DeploymentStatus]::Error -and
				$script:EMP.SetupErrorLog.Directory.Exists
			) {
				Write-ADTLogEntry -Message "Writing error messages to [$($script:EMP.SetupErrorLog.FullName)]."
				Add-Content -Path $script:EMP.SetupErrorLog.FullName -Value ([System.String]::Join([System.Environment]::NewLine, @($adtSession.GetLogBuffer() | & { process { if ($_.Severity -ge 2) { $_.Message } } })))
			}

			# Use Empirum's reboot action if the Empirum module is loaded and the session status is RestartRequired
			if ($adtSession.GetDeploymentStatus() -eq [PSADT.Module.DeploymentStatus]::RestartRequired) {
				if ($script:EMP.Module) {
					Write-ADTLogEntry -Message 'Reboot action will be transferred to the Empirum agent.'
					& $script:EMP.Module.ExportedCommands.'Set-EmpirumReboot' -RebootType RebootNeeded
					$adtSession.SetExitCode(0)
				}
				else {
					Write-ADTLogEntry -Message 'Cannot perform Empirum reboot action. The Matrix42 Empirum module is not loaded. (This is to be expected if the SetupInf wrapper is used)'
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
