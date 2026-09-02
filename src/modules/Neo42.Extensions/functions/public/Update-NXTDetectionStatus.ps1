function Update-NXTDetectionStatus {
	<#
	.SYNOPSIS
	Invokes the session's application detection and updates the detection status accordingly.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'The state change is expected and desired when calling this function.')]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0)]
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession)
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if (-not $ADTSession.NXT.Detection.Enabled) {
				Write-ADTLogEntry -Severity Warning -Message 'Application detection is not enabled in the session. Skipping detection update.' -DebugMessage
				return
			}
			elseif ($ADTSession.NXT.Detection.Criteria) {
				Write-ADTLogEntry -Message 'Session has application detection configured. Performing detection...' -DebugMessage
				[PSADT.Types.InstalledApplication[]]$installedApps = @(Get-NXTApplication -Criteria $ADTSession.NXT.Detection.Criteria)
				if ($installedApps.Length -gt 1) {
					[System.Collections.Hashtable]$errorParams = @{
						Exception    = [System.ApplicationException]::new('Multiple applications matched the detection criteria. Please refine the detection settings.')
						Category     = [System.Management.Automation.ErrorCategory]::InvalidResult
						ErrorId      = 'MultipleApplicationsFound'
						TargetObject = $installedApps.DisplayName
					}
					throw (New-ADTErrorRecord @errorParams)
				}
				elseif ($installedApps.Count -eq 1) {
					Write-ADTLogEntry -Message "Application [$($installedApps[0].DisplayName)] found installed with version [$($installedApps[0].DisplayVersion)]."
					$ADTSession.NXT.Detection.IsInstalled = $true
					$ADTSession.NXT.Detection.Application = $installedApps[0]
					$ADTSession.NXT.Detection.VersionStatus = if ($ADTSession.NXT.Detection.TargetVersion) {
						Compare-NXTVersion -Version $installedApps[0].DisplayVersion -Target $ADTSession.NXT.Detection.TargetVersion
					}
					else {
						[PSADTNXT.Application.VersionCompareResult]::Equal
					}
				}
				else {
					Write-ADTLogEntry -Message 'The defined detection criteria did not match any installed application.'
					$ADTSession.NXT.Detection.IsInstalled = $false
					$ADTSession.NXT.Detection.Application = $null
					$ADTSession.NXT.Detection.VersionStatus = [PSADTNXT.Application.VersionCompareResult]::Equal
				}
			}
			else {
				Write-ADTLogEntry -Message 'No application detection configured in session. Relying solely on existing (custom) detection status.'
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
