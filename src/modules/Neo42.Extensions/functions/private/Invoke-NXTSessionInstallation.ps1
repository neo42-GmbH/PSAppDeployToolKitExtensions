function Invoke-NXTSessionInstallation {
	<#
	.SYNOPSIS
	The logic to translate the session object into a installation operation.
	#>
	[OutputType([PSADT.ProcessManagement.ProcessResult])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0)]
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession)
	)

	try {
		if ($null -eq $ADTSession.NXT.Install.Method) {
			Write-ADTLogEntry -Message 'An installation method was not set. Skipping a default process execution.'
			return [PSADT.ProcessManagement.ProcessResult]::new(0)
		}
		[System.Collections.Hashtable]$invokeInstallParams = @{
			Method         = $ADTSession.NXT.Install.Method
			Target         = $ADTSession.NXT.Install.Target
			CacheDirectory = $ADTSession.NXT.Package.Directory
		}

		if (-not [System.String]::IsNullOrWhiteSpace($ADTSession.NXT.Install.LogName)) {
			$invokeInstallParams['LogFileName'] = $ADTSession.NXT.Install.LogName
		}

		if ($ADTSession.NXT.Install.IgnoreExitCodes) {
			$invokeInstallParams['IgnoreExitCodes'] = $true
		}
		else {
			$invokeInstallParams['SuccessExitCodes'] = $ADTSession.NXT.Install.SuccessCodes
			$invokeInstallParams['RebootExitCodes'] = $ADTSession.NXT.Install.RebootCodes
		}

		if ($ADTSession.NXT.Install.Defaults) {
			$invokeInstallParams['AdditionalArgumentList'] = $ADTSession.NXT.Install.Arguments
		}
		else {
			$invokeInstallParams['ArgumentList'] = $ADTSession.NXT.Install.Arguments
		}

		if ($ADTSession.NXT.Detection.Criteria) {
			$invokeInstallParams['Criteria'] = $ADTSession.NXT.Detection.Criteria
		}

		if ($ADTSession.NXT.Install.Awaiters) {
			$invokeInstallParams['Awaiter'] = $ADTSession.NXT.Install.Awaiters
		}

		[PSADT.ProcessManagement.ProcessResult]$result = Install-NXTApplication @invokeInstallParams
		return $result
	}
	catch {
		Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
	}
}
