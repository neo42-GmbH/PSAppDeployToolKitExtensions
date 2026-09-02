function Add-NXTDeploymentCallback {
	<#
	.SYNOPSIS
	Add a custom hook that is run after a specific custom function.
	.DESCRIPTION
	The Add-NXTDeploymentCallback function adds a custom hook to the deployment session that is executed after the specified deployment hook point.
	.PARAMETER Callback
	The command information object representing the custom function to be executed as a hook.
	.PARAMETER HookPoint
	The name of the deployment hook point after which the custom hook should be executed.
	If this parameter is omitted, the name of the callback will be used to determine the hook point.
	.PARAMETER Prepend
	Add the hook to the to of the list.
	.EXAMPLE
	Add-NXTDeploymentCallback -HookPoint 'CustomInstallEnd' -Callback (Get-Command -Name 'My-CustomFunction')

	This example adds a custom hook that executes the 'My-CustomFunction' function after the 'CustomInstallEnd' deployment hook point.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Prepend', Justification = 'Parameter is used in script block.')]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[ValidateNotNull()]
		[System.Management.Automation.CommandInfo[]]
		$Callback,
		[PSADTNXT.Deployment.DeploymentHookPoint[]]
		$HookPoint,
		[System.Management.Automation.SwitchParameter]
		$Prepend
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if ($HookPoint) {
				$HookPoint | & {
					process {
						if ($Prepend) {
							$script:DeploymentCallbacks[$_].InsertRange(0, $Callback)
						}
						else {
							$script:DeploymentCallbacks[$_].AddRange($Callback)
						}
					}
				}
			}
			else {
				$Callback | & {
					process {
						if ($_.Name -notin [System.Enum]::GetNames([PSADTNXT.Deployment.DeploymentHookPoint])) {
							[System.Collections.Hashtable]$errorParams = @{
								Exception         = [System.InvalidOperationException]::new("There is no hook point to attach $($_.Name) to.")
								Category          = [System.Management.Automation.ErrorCategory]::NotImplemented
								ErrorId           = 'NoHookPointFound'
								RecommendedAction = 'Name your function like one of the available hook points or provide the argument.'
								TargetObject      = $_
							}
							throw (New-ADTErrorRecord @errorParams)
						}

						if ($Prepend) {
							$script:DeploymentCallbacks[[PSADTNXT.Deployment.DeploymentHookPoint]$_.Name].Insert(0, $_)
						}
						else {
							$script:DeploymentCallbacks[[PSADTNXT.Deployment.DeploymentHookPoint]$_.Name].Add($_)
						}
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
