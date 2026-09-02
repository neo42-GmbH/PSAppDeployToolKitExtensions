function Clear-NXTDeploymentCallback {
	<#
	.SYNOPSIS
	Clears all custom hooks.
	.DESCRIPTION
	The Clear-NXTDeploymentCallback function removes a custom hook from the deployment session that was previously added with Add-NXTDeploymentCallback.
	.PARAMETER HookPoint
	The name of the deployment hook point after which the custom hook should be executed.
	.EXAMPLE
	Add-NXTDeploymentCallback -HookPoint 'CustomInstallEnd' -Callback (Get-Command -Name 'My-CustomFunction')

	This example adds a custom hook that executes the 'My-CustomFunction' function after the 'CustomInstallEnd' deployment hook point.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[PSADTNXT.Deployment.DeploymentHookPoint[]]
		$HookPoint
	)
	$HookPoint | & { process { $script:DeploymentCallBacks[$_].Clear() } }
}
