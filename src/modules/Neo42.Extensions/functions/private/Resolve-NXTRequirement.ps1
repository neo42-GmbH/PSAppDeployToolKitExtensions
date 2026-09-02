function Resolve-NXTRequirement {
	<#
	.SYNOPSIS
	Resolves the dependent package states.
	#>
	[OutputType([PSADT.ProcessManagement.ProcessResult[]])]
	[CmdletBinding()]
	param (
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession)
	)

	try {
		if (-not $ADTSession.NXT.Requirements) { return }

		foreach ($requirement in $ADTSession.NXT.Requirements) {
			[PSADT.Types.InstalledApplication[]]$applications = @(Get-NXTApplication -Criteria $requirement.Criteria)
			if ($applications.Length -gt 1) {
				Write-ADTLogEntry -Severity Warning -Message "Multiple applications found matching requirement for [$($requirement.Criteria.Store)]. Running tests against all resolved applications."
			}

			if (($applications -and $applications.Count -gt 0) -eq ($requirement.DesiredState -eq [PSADTNXT.Deployment.RequirementState]::Present)) {
				Write-ADTLogEntry -Message "Requirement for application [$($requirement.Criteria.Store)] is met." -DebugMessage
				continue
			}

			switch ($requirement.OnConflict) {
				([PSADTNXT.Deployment.RequirementConflictAction]::Warn) {
					Write-ADTLogEntry -Severity Warning -Message $requirement.ErrorMessage
					break
				}
				([PSADTNXT.Deployment.RequirementConflictAction]::Fail) {
					$ADTSession.SetExitCode(69002)
					[System.Collections.Hashtable]$errorParams = @{
						Exception         = [System.OperationCanceledException]::new($requirement.ErrorMessage)
						Category          = [System.Management.Automation.ErrorCategory]::OperationStopped
						ErrorId           = 'RequirementNotMet'
						Reason            = 'A required application state was not met.'
						RecommendedAction = 'Install or uninstall the required application as needed.'
						TargetObject      = $requirement
					}
					throw (New-ADTErrorRecord @errorParams)
				}
				([PSADTNXT.Deployment.RequirementConflictAction]::Uninstall) {
					if (-not $applications) {
						[System.Collections.Hashtable]$errorParams = @{
							Exception         = [System.InvalidOperationException]::new('Cannot uninstall a non present application')
							Category          = [System.Management.Automation.ErrorCategory]::OperationStopped
							ErrorId           = 'ApplicationNotPresent'
							Reason            = 'No applications to uninstall are present in this combination.'
							RecommendedAction = 'Change the conflict action to a different mode.'
							TargetObject      = $requirement
						}
						throw (New-ADTErrorRecord @errorParams)
					}
					Show-NXTInstallationWelcome -ADTSession $ADTSession -DeploymentDefaults -NoBalloonTip
					foreach ($application in $applications) {
						Write-ADTLogEntry -Message "Uninstalling [$($application.DisplayName)] as per requirement."
						$ADTSession.NXT.ProcessResults.Add((Uninstall-NXTApplication -Application $application -ExitOnProcessFailure))
					}
				}
			}
		}

		Write-ADTLogEntry -Severity Success -Message 'Package dependencies resolved successfully.'
	}
	catch {
		Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
	}
}
