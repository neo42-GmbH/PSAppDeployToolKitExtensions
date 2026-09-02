function Restart-NXTDeployScript {
	<#
	.SYNOPSIS
	Restart the script if one of the conditions is met.
	.DESCRIPTION
	Designed as a helper script to remove as much logic as possible from the main script.
	Restart conditions can be specified with the defined switch parameters.
	.PARAMETER Invocation
	The invocation information of the current script.
	.PARAMETER When32on64Bit
	Restart the script if the current process is 32-bit on a 64-bit OS.
	.PARAMETER WhenTriggerDeployment
	Restart the script if the DeploymentType parameter is a trigger.
	.EXAMPLE
	Restart-NXTDeployScript -When32on64Bit -WhenTriggerDeployment

	Restart the script when the current process is 32-bit on a 64-bit OS or when the DeploymentType parameter is a trigger.
	.NOTES
	Be the script will run in a new process and the DeploymentType parameter will be cleared to avoid a trigger loop.
	The calling script will wait for the new process to finish and stop the execution with the exit code of the new process.
	Any logging to the console will be lost.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'No state change.')]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[System.Management.Automation.InvocationInfo]
		$Invocation,
		[System.Management.Automation.SwitchParameter]
		$When32on64Bit,
		[System.Management.Automation.SwitchParameter]
		$WhenTriggerDeployment
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if ($Invocation.MyCommand.CommandType -ne [System.Management.Automation.CommandTypes]::ExternalScript) {
				[System.Collections.Hashtable]$errorParams = @{
					Exception         = [System.InvalidOperationException]::new('Only script invocations can be restarted.')
					Category          = [System.Management.Automation.ErrorCategory]::InvalidOperation
					ErrorId           = 'NotFileInvocation'
					RecommendedAction = 'Ensure that this command is only used in a script context.'
					TargetObject      = $Invocation
				}
				throw (New-ADTErrorRecord @errorParams)
			}

			[System.Collections.Generic.Dictionary[System.String, System.Object]]$parameters = [System.Collections.Generic.Dictionary[System.String, System.Object]]::new($Invocation.BoundParameters)

			# Skip further execution if no condition is met
			[System.Boolean]$unconditional = -not $PSBoundParameters.ContainsKey('When32on64Bit') -and -not $PSBoundParameters.ContainsKey('WhenTriggerDeployment')
			if ($unconditional) { return }

			# Determine if restart conditions are met
			[System.Boolean]$isTrigger = $WhenTriggerDeployment -and $parameters.ContainsKey('DeploymentType') -and [PSADTNXT.Deployment.NxtDeploymentType]::new($parameters.DeploymentType).IsTrigger
			[System.Boolean]$is32on64 = $When32on64Bit -and [System.Environment]::Is64BitOperatingSystem -and -not [System.Environment]::Is64BitProcess

			if (-not ($isTrigger -or $is32on64)) { return }
			$PSCmdlet.WriteWarning('Restarting the script...')

			# Clear the DeploymentType parameter from the Trigger indicator
			if ($isTrigger) { $parameters.DeploymentType = $parameters.DeploymentType -replace '^Trigger', [System.String]::Empty }

			# Determine the best native PowerShell process path
			[System.String]$psProcessPath = Get-ADTPowerShellProcessPath
			if ($is32on64) {
				if ([System.IO.Path]::GetFileName($psProcessPath) -eq 'powershell.exe') {
					$psProcessPath = $psProcessPath -replace 'SysWOW64', 'SysNative'
				}
				else {
					[System.String]$nativePsProcessPath = $psProcessPath -replace [System.Text.RegularExpressions.Regex]::Escape('Program Files (x86)'), 'Program Files'
					if ([System.IO.File]::Exists($nativePsProcessPath)) {
						$psProcessPath = $nativePsProcessPath
					}
					else {
						$psProcessPath = [System.Environment]::GetFolderPath('Windows') + '\SysNative\WindowsPowerShell\v1.0\powershell.exe'
					}
				}
			}

			[System.Collections.Hashtable]$startProcessParams = @{
				WindowStyle      = 'Hidden'
				FilePath         = $psProcessPath
				WorkingDirectory = [System.IO.Path]::GetDirectoryName($Invocation.MyCommand.Path)
				ArgumentList     = (ConvertTo-NXTPsBinaryArgument -File $Invocation.MyCommand.Path -Arguments $parameters -UseLastExitCode)
				PassThru         = -not $isTrigger
			}

			if ($isTrigger) {
				$startProcessParams.NoWait = $true
			}
			else {
				$startProcessParams.ExitOnProcessFailure = $true
			}

			Start-ADTProcess @startProcessParams | & { process { exit $_.ExitCode } }
			exit 0
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
