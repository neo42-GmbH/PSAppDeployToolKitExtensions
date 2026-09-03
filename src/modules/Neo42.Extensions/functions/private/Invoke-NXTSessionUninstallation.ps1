function Invoke-NXTSessionUninstallation {
	<#
	.SYNOPSIS
	The logic to translate the session object into a uninstallation operation.
	#>
	[OutputType([PSADT.ProcessManagement.ProcessResult])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0)]
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession)
	)

	try {
		if ($null -eq $ADTSession.NXT.Uninstall.Method) {
			Write-ADTLogEntry -Message 'An uninstallation method was not set. Skipping a default process execution.'
			return [PSADT.ProcessManagement.ProcessResult]::new(0)
		}

		[System.Collections.Hashtable]$invokeUninstallParams = @{
			Method         = $ADTSession.NXT.Uninstall.Method
			CacheDirectory = $ADTSession.NXT.Package.Directory
			UninstallKey   = if ($ADTSession.NXT.Detection.Application) { $ADTSession.NXT.Detection.Application.PSPath } else { $null }
		}

		if (-not [System.String]::IsNullOrWhiteSpace($ADTSession.NXT.Uninstall.LogName)) {
			$invokeUninstallParams['LogFileName'] = $ADTSession.NXT.Uninstall.LogName
		}

		$invokeUninstallParams['Target'] = if (-not [System.String]::IsNullOrWhiteSpace($ADTSession.NXT.Uninstall.Target)) {
			$ADTSession.NXT.Uninstall.Target
		}
		elseif ($ADTSession.NXT.Detection.Application) {
			if ($ADTSession.NXT.Uninstall.Method -in @([PSADTNXT.Deployment.DeploymentMethod]::MSI, [PSADTNXT.Deployment.DeploymentMethod]::AppX)) {
				$ADTSession.NXT.Detection.Application.PSChildName
			}
			else {
				[PSADTNXT.Shell.NxtCommandLine]::SearchPath(
					$(
						if (-not [System.String]::IsNullOrWhiteSpace($ADTSession.NXT.Detection.Application.QuietUninstallStringFilePath)) {
							$ADTSession.NXT.Detection.Application.QuietUninstallStringFilePath
						}
						else {
							$ADTSession.NXT.Detection.Application.UninstallStringFilePath
						}
					),
					[System.EnvironmentVariableTarget]::Machine
				)
			}
		}
		else {
			[System.Collections.Hashtable]$errorParams = @{
				Exception = [System.ApplicationException]::new('No valid target found for uninstallation in the session.')
				Category  = [System.Management.Automation.ErrorCategory]::InvalidArgument
				ErrorId   = 'NoUninstallTarget'
			}
			throw (New-ADTErrorRecord @errorParams)
		}

		if ($ADTSession.NXT.Uninstall.IgnoreExitCodes) {
			$invokeUninstallParams['IgnoreExitCodes'] = $true
		}
		else {
			$invokeUninstallParams['SuccessExitCodes'] = $ADTSession.NXT.Uninstall.SuccessCodes
			$invokeUninstallParams['RebootExitCodes'] = $ADTSession.NXT.Uninstall.RebootCodes
		}

		if ($ADTSession.NXT.Uninstall.Defaults) {
			$invokeUninstallParams['AdditionalArgumentList'] = $ADTSession.NXT.Uninstall.Arguments
		}
		else {
			$invokeUninstallParams['ArgumentList'] = $ADTSession.NXT.Uninstall.Arguments
		}

		if ($ADTSession.NXT.Uninstall.Awaiters) {
			$invokeUninstallParams['Awaiter'] = $ADTSession.NXT.Uninstall.Awaiters
		}

		Write-ADTLogEntry "Invoking session based [$($invokeUninstallParams.Method)] uninstallation logic."
		[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication @invokeUninstallParams
		return $result
	}
	catch {
		Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
	}
}
