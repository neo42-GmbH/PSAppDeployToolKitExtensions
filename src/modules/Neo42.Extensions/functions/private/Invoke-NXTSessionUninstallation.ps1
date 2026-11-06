function Invoke-NXTSessionUninstallation {
	<#
	.SYNOPSIS
	The logic to translate the session object into a uninstallation operation.
	#>
	[OutputType([PSADT.ProcessManagement.ProcessResult])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0)]
		[ValidateNotNull()]
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession)
	)

	try {
		if ($null -eq $ADTSession.NXT.Uninstall.Method) {
			Write-ADTLogEntry -Message 'An uninstallation method was not set. Skipping a default process execution.'
			return [PSADT.ProcessManagement.ProcessResult]::new(0)
		}

		Write-ADTLogEntry -Message "Invoking session based [$($ADTSession.NXT.Uninstall.Method)] uninstallation logic."

		[System.Collections.Hashtable]$invokeUninstallParams = @{
			Method         = $ADTSession.NXT.Uninstall.Method
			CacheDirectory = $ADTSession.NXT.Package.Directory
		}

		if (-not [System.String]::IsNullOrWhiteSpace($ADTSession.NXT.Uninstall.LogName)) {
			$invokeUninstallParams['LogFileName'] = $ADTSession.NXT.Uninstall.LogName
		}

		if (-not [System.String]::IsNullOrWhiteSpace($ADTSession.NXT.Uninstall.Target)) {
			$invokeUninstallParams['Target'] = $ADTSession.NXT.Uninstall.Target
			if ($ADTSession.NXT.Detection.Criteria) {
				$invokeUninstallParams['Criteria'] = $ADTSession.NXT.Detection.Criteria
			}
		}
		elseif ($ADTSession.NXT.Detection.Application) {
			# Pass the application object to resolve the target and the uninstall string arguments from it.
			Write-ADTLogEntry -Message 'No target was specified, but detection resolved an application. Using its data for uninstallation.'
			$invokeUninstallParams['Application'] = $ADTSession.NXT.Detection.Application
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

		if ($ADTSession.NXT.Uninstall.AwaitChildren) {
			$invokeUninstallParams['WaitForChildProcesses'] = $true
		}

		if ($ADTSession.NXT.Uninstall.Awaiters) {
			$invokeUninstallParams['Awaiter'] = $ADTSession.NXT.Uninstall.Awaiters
		}

		return (Uninstall-NXTApplication @invokeUninstallParams)
	}
	catch {
		Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
	}
}
