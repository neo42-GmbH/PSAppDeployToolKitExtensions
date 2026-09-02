function Exit-NXTDeployment {
	<#
	.SYNOPSIS
	This a helper function that allows ending the deployment process.
	.DESCRIPTION
	This a helper function that allows ending the deployment process by throwing a NxtDeploymentCancelException.
	The exception is caught by the Invoke-NXTDeployment function and the deployment process will be ended.
	.PARAMETER ADTSession
	The deployment session object representing the current deployment.
	.PARAMETER Message
	The message to be displayed in the exception.
	.PARAMETER ExitCode
	The exit code to set for the deployment session.
	.PARAMETER Status
	Apply a predefined exit code and message representing the given status.
	.PARAMETER AbortReboot
	A quick access switch to set the exit code to 3010, NoRegistration to true and a predefined message.
	.PARAMETER NoRegistration
	Will set the Register property of the package to false.
	Additionally if the package is registered, it will be unregistered.
	This is useful for requiring a restart of the system before the package is considered deployed.
	.EXAMPLE
	Exit-NXTDeployment -Message "Deployment should stop here. No error was reported." -ExitCode 0

	This will halt the deployment process and will only run post-deployment tasks.
	.EXAMPLE
	Exit-NXTDeployment -Status 'Error'

	This will halt the deployment process and will only run post-deployment tasks and mark the deployment as failed.
	#>
	[CmdletBinding(DefaultParameterSetName = 'ExitCode')]
	param (
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession),
		[Parameter(Position = 1, ParameterSetName = 'ExitCode')]
		[System.Int32]
		$ExitCode = 0,
		[Parameter(ParameterSetName = 'Status', Mandatory)]
		[PSADT.Module.DeploymentStatus]
		$Status,
		[Parameter(ParameterSetName = 'AbortReboot', Mandatory)]
		[ValidateScript({ [System.Boolean]$_ })]
		[System.Management.Automation.SwitchParameter]
		$AbortReboot,
		[Parameter(Position = 0, ParameterSetName = 'ExitCode', Mandatory)]
		[Parameter(Position = 0, ParameterSetName = 'Status')]
		[Parameter(Position = 0, ParameterSetName = 'AbortReboot')]
		[System.String]
		$Message,
		[Parameter(ParameterSetName = 'ExitCode')]
		[Parameter(ParameterSetName = 'Status')]
		[System.Management.Automation.SwitchParameter]
		$NoRegistration
	)

	[System.Collections.Hashtable]$adtConfig = Get-ADTConfig
	[System.Management.Automation.CallStackFrame[]]$callStack = Get-PSCallStack

	# Check if the function is called from within a hook function inside Invoke-NXTDeployment.
	if ($callStack.FunctionName -notcontains 'Invoke-NXTDeployment<Process>') {
		[System.Collections.Hashtable]$errorParams = @{
			Exception         = [System.InvalidOperationException]::new('Invalid invocation context.')
			Category          = [System.Management.Automation.ErrorCategory]::InvalidOperation
			Reason            = 'This function can only be called from within a deployment hook function.'
			ErrorId           = 'InvalidContext'
			RecommendedAction = 'Call this function from within a deployment hook function.'
		}
		throw (New-ADTErrorRecord @errorParams)
	}

	# AbortReboot parameter set
	if ($PSCmdlet.ParameterSetName -eq 'AbortReboot') {
		if (-not $Message) { $Message = 'Package deployment was interrupted because a reboot was required before the package can be deployed.' }
		$ExitCode = 3010
		$NoRegistration = $true
	}
	# Status parameter set
	elseif ($PSCmdlet.ParameterSetName -eq 'Status') {
		switch ($Status) {
			([PSADT.Module.DeploymentStatus]::Complete) {
				if (-not $Message) { $Message = 'The package deployment has been completed successfully early.' }
				$ExitCode = 0
			}
			([PSADT.Module.DeploymentStatus]::Error) {
				if (-not $Message) { $Message = 'An error occurred during the package deployment.' }
				$ExitCode = 69001
			}
			([PSADT.Module.DeploymentStatus]::RestartRequired) {
				if (-not $Message) { $Message = 'The package deployment has been completed successfully early, but a restart is required.' }
				$ExitCode = 3010
			}
			([PSADT.Module.DeploymentStatus]::FastRetry) {
				if (-not $Message) { $Message = 'The package deployment has been cancelled with the request to retry the installation soon.' }
				$NoRegistration = $true
				$ExitCode = $adtConfig['UI']['DefaultExitCode']
			}
		}
	}

	# Apply the exit code to the deployment session.
	[System.Int32]$previousExitCode = $ADTSession.GetExitCode()
	$ADTSession.SetExitCode($ExitCode)

	# Translate the status to a severity level.
	[PSADT.Module.LogSeverity]$severity = @{
		[PSADT.Module.DeploymentStatus]::Complete        = [PSADT.Module.LogSeverity]::Success
		[PSADT.Module.DeploymentStatus]::Error           = [PSADT.Module.LogSeverity]::Error
		[PSADT.Module.DeploymentStatus]::RestartRequired = [PSADT.Module.LogSeverity]::Warning
		[PSADT.Module.DeploymentStatus]::FastRetry       = [PSADT.Module.LogSeverity]::Warning
	}[$ADTSession.GetDeploymentStatus()]

	# Log the message.
	if ($PSBoundParameters.ContainsKey('ExitCode')) {
		Write-ADTLogEntry -Severity $severity -Message "Hook applied custom exit code [${ExitCode}] with status [$($ADTSession.GetDeploymentStatus())] from previous [$previousExitCode]."
	}
	if (-not [System.String]::IsNullOrWhiteSpace($Message)) {
		Write-ADTLogEntry -Severity $severity -Message $Message
	}

	# Disable registration if the parameter is set.
	if ($NoRegistration) {
		# If the package is registered on install, remove the registration.
		if ($ADTSession.NXT.DeploymentType.IsInstall -and
			([PSADTNXT.Package.NxtRegisteredPackage]$package = $ADTSession.NXT.Package.GetRegisteredPackage())
		) {
			Remove-Item -LiteralPath $package.PSPath
		}
		$ADTSession.NXT.Package.Register = $false
	}

	# Throw the expected exception to stop the deployment process.
	$PSCmdlet.ThrowTerminatingError(
		[System.Management.Automation.ErrorRecord]::new(
			[PSADTNXT.Deployment.NxtDeploymentCancelException]::new($Message),
			$PSCmdlet.MyInvocation.MyCommand.Name,
			[System.Management.Automation.ErrorCategory]::OperationStopped,
			$null
		)
	)
}
