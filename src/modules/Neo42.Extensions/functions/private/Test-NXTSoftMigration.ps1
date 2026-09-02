function Test-NXTSoftMigration {
	<#
	.SYNOPSIS
	Test if the current state of the system is eligible for a Soft Migration.
	#>
	[OutputType([System.Boolean])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0)]
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession)
	)

	try {
		# Check if Soft Migration is enabled in the session
		[System.Collections.Generic.List[System.String]]$errors = [System.Collections.Generic.List[System.String]]::new()

		[System.String]$targetVersion = $null
		switch ($ADTSession.NXT.SoftMigration.Mode) {
			{ $_ -eq [PSADTNXT.Deployment.SoftMigrationDetectionMode]::Custom -or $null -ne $ADTSession.NXT.SoftMigration.Result } {
				Write-ADTLogEntry -Message 'Using custom Soft Migration result for detection.'
				if (-not $ADTSession.NXT.SoftMigration.Result) { $errors.Add('The [Custom] Soft Migration result is negative.') }
				break
			}
			([PSADTNXT.Deployment.SoftMigrationDetectionMode]::File) {
				Write-ADTLogEntry -Message 'Performing file-based Soft Migration detection...'
				if ([System.String]::IsNullOrWhiteSpace($ADTSession.NXT.SoftMigration.Target)) {
					[System.Collections.Hashtable]$errorParams = @{
						Exception    = [System.Management.Automation.ItemNotFoundException]::new('For Soft Migration detection mode [File], the target must be specified in the package configuration.')
						Category     = [System.Management.Automation.ErrorCategory]::InvalidData
						ErrorId      = 'SoftMigrationTargetNotSpecified'
						TargetObject = $ADTSession.NXT.SoftMigration
					}
					throw (New-ADTErrorRecord @errorParams)
				}

				if (-not [System.IO.File]::Exists($ADTSession.NXT.SoftMigration.Target)) {
					$errors.Add("The target file [$($ADTSession.NXT.SoftMigration.Target)] for Soft Migration does not exist.")
				}
				else {
					$targetVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($ADTSession.NXT.SoftMigration.Target).FileVersion
				}
			}
			([PSADTNXT.Deployment.SoftMigrationDetectionMode]::Detection) {
				Write-ADTLogEntry -Message 'Performing application detection based Soft Migration detection...'
				if (-not $ADTSession.NXT.Detection.Enabled) {
					[System.Collections.Hashtable]$errorParams = @{
						Exception    = [System.InvalidOperationException]::new('Application detection must be enabled for Soft Migration detection mode [Detection].')
						Category     = [System.Management.Automation.ErrorCategory]::InvalidOperation
						ErrorId      = 'SoftMigrationDetectionDependencyNotMet'
						TargetObject = $ADTSession.NXT.SoftMigration
					}
					throw (New-ADTErrorRecord @errorParams)
				}
				Update-NXTDetectionStatus -ADTSession $ADTSession
				if (-not $ADTSession.NXT.Detection.IsInstalled) {
					$errors.Add('The target application for Soft Migration is not installed.')
				}
				elseif ($ADTSession.NXT.Detection.Application) {
					$targetVersion = $ADTSession.NXT.Detection.Application.DisplayVersion
				}
			}
			default {
				[System.Collections.Hashtable]$errorParams = @{
					Exception    = [System.NotSupportedException]::new("The Soft Migration detection mode [$($ADTSession.NXT.SoftMigration.Mode)] is not supported.")
					Category     = [System.Management.Automation.ErrorCategory]::NotImplemented
					ErrorId      = 'SoftMigrationModeNotSupported'
					TargetObject = $ADTSession.NXT.SoftMigration
				}
				throw (New-ADTErrorRecord @errorParams)
			}
		}

		# If versions are available, compare them
		if (-not [System.String]::IsNullOrWhiteSpace($targetVersion) -and
			-not [System.String]::IsNullOrWhiteSpace($ADTSession.NXT.SoftMigration.Version) -and
			(Compare-NXTVersion -Version $ADTSession.NXT.SoftMigration.Version -Target $targetVersion) -eq [PSADTNXT.Application.VersionCompareResult]::Downgrade
		) {
			$errors.Add("The detected version [$targetVersion] is lower the required version [$($ADTSession.NXT.SoftMigration.Version)].")
		}

		# Due to legacy compatibility we need to check the SetupCfg Soft Migration value again, if it changed prior to this function being called.
		if ($ADTSession.NXT.SetupCfg['Options']['SoftMigration'] -ne '1') {
			$errors.Add('Soft Migration is disabled via SetupCfg option. Soft Migration is not possible. Please do not alter the SetupCfg options manually during the deployment process as it may lead to unexpected results.')
		}
		if (-not $ADTSession.NXT.SoftMigration.Enabled) {
			$errors.Add('Soft Migration is disabled via session configuration.')
		}
		if ($ADTSession.GetDeploymentStatus() -eq [PSADT.Module.DeploymentStatus]::Error) {
			$errors.Add("The deployment status [$($ADTSession.GetDeploymentStatus())] indicates that an error occurred.")
		}
		if ($ADTSession.DeploymentType -eq [PSADT.Module.DeploymentType]::Repair) {
			$errors.Add('Repair deployments are not eligible for Soft Migration.')
		}
		if ($ADTSession.NXT.ProcessResults.Count -gt 0) {
			$errors.Add("Already accumulated [$($ADTSession.NXT.ProcessResults.Count)] process results.")
		}

		# Output any errors that were found
		if ($errors.Count -gt 0) {
			Write-ADTLogEntry -Message 'The the following conditions prevent a Soft Migration:'
			$errors | & { process { Write-ADTLogEntry -Message " * $_" } }
			return $false
		}

		return $true
	}
	catch {
		Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
	}
}
