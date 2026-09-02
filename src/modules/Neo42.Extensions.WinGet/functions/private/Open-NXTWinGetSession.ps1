function Open-NXTWinGetSession {
	<#
	.SYNOPSIS
	This function is called on the first call of the Open-ADTSession function.
	#>
	[CmdletBinding()]
	param ()
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[PSADT.Module.DeploymentSession]$adtSession = Get-ADTSession

			# Validate we are in a WinGet compatible environment
			if ($adtSession -isnot [PSADTNXT.Foundation.NxtDeploymentSession]) {
				Write-ADTLogEntry -Severity Error -Message 'The WinGet module is only compatible with a [NxtDeploymentSession] session class.'
				return
			}

			[System.IO.FileInfo]$installerManifest = [System.IO.Path]::Combine($adtSession.NXT.DeployAppScript.Directory.FullName, 'neo42WingetConfig.json')
			if (-not $installerManifest.Exists) {
				Write-ADTLogEntry -Severity Error -Message "The WinGet module could not find an appropriate manifest at [$($installerManifest.FullName)]. This module is only intended to be used by neo42 WinGet packages."
				return
			}

			# Read the WinGet manifest file and update the session information accordingly
			[PSADTNXT.WinGet.Configuration.WinGetConfigModel]$installerModel = [PSADTNXT.WinGet.Configuration.WinGetConfigModel]::Create($installerManifest.FullName)

			# Test if the current device meets the minimum OS version requirement specified in the manifest, if any.
			[System.Version]$minimumOSVersion = $null
			if (-not [System.String]::IsNullOrWhiteSpace($installerModel.MinimumOSVersion) -and
				[System.Version]::TryParse($installerModel.MinimumOSVersion, [ref]$minimumOSVersion) -and
				[PSADT.DeviceManagement.OperatingSystemInfo]::Current.Version -lt $minimumOSVersion
			) {
				[System.Collections.Hashtable]$errorParams = @{
					Exception         = [System.InvalidOperationException]::new("The application requires a minimum OS version of [$($installerModel.MinimumOSVersion)], but the device is running [$([PSADT.DeviceManagement.OperatingSystemInfo]::Current.Version)].")
					Category          = [System.Management.Automation.ErrorCategory]::InvalidOperation
					ErrorId           = 'MinimumOSVersionNotMet'
					RecommendedAction = 'Use a compatible device or application version.'
					TargetObject      = $installerModel
				}
				throw (New-ADTErrorRecord @errorParams)
			}

			# Get the full path to the install target, which may be a relative path from the session files directory or an absolute path.
			[System.IO.FileInfo]$installerTarget = if ([System.IO.Path]::IsPathRooted($adtSession.NXT.Install.Target)) {
				$adtSession.NXT.Install.Target
			}
			else {
				[System.IO.Path]::Combine($adtSession.DirFiles, $adtSession.NXT.Install.Target)
			}

			# Create detection criteria base on manifest information
			# Set detection criteria if the installer type is detectable in an application store
			if (($adtSession.NXT.Detection.Enabled = Test-NXTDetectableApplication -DeploymentMethod $adtSession.NXT.Install.Method)) {
				$adtSession.NXT.Detection.Criteria = ConvertTo-NXTDetectionCriteria -Model $installerModel -DeploymentMethod $adtSession.NXT.Install.Method -Name $adtSession.AppName -Vendor $adtSession.AppVendor -Installer $installerTarget
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
