function Remove-NXTDeploymentCallback {
	<#
	.SYNOPSIS
	Removes a specific hook.
	.DESCRIPTION
	The Remove-NXTDeploymentCallback function removes a custom hook from the deployment session that was previously added with Add-NXTDeploymentCallback.
	.PARAMETER HookPoint
	The name of the deployment hook point after which the custom hook should be executed.
	.EXAMPLE
	Add-NXTDeploymentCallback -HookPoint 'CustomInstallEnd' -Callback (Get-Command -Name 'My-CustomFunction')

	This example adds a custom hook that executes the 'My-CustomFunction' function after the 'CustomInstallEnd' deployment hook point.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'No state change.')]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[ValidateNotNull()]
		[System.Management.Automation.CommandInfo[]]
		$Callback,
		[PSADTNXT.Deployment.DeploymentHookPoint[]]
		$HookPoint
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			foreach ($hook in $HookPoint) {
				foreach ($call in $Callback) {
					if (-not $script:DeploymentCallBacks[$hook].Remove($call)) {
						[System.Collections.Hashtable]$errorParams = @{
							Exception    = [System.InvalidOperationException]::new("There is callback [$($call.Name)] attached to hook point [$hook].")
							Category     = [System.Management.Automation.ErrorCategory]::InvalidArgument
							ErrorId      = 'HookNotInstalled'
							TargetObject = $call
						}
						throw (New-ADTErrorRecord @errorParams)
					}
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
