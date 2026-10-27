function Clear-NXTDeploymentCallback {
	<#
	.SYNOPSIS
	Clears all custom hooks.
	.DESCRIPTION
	This function removes a custom hook from the deployment session that was previously added.
	.PARAMETER HookPoint
	The name of the deployment hook point after which the custom hook should be executed.
	.EXAMPLE
	Clear-NXTDeploymentCallback -HookPoint CustomInstallEnd

	Clears all callbacks attached to CustomInstallEnd
	#>
	[CmdletBinding()]
	param (
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory)]
		[PSADTNXT.Deployment.DeploymentHookPoint[]]
		$HookPoint
	)
	$HookPoint | & { process { $script:DeploymentCallBacks[$_].Clear() } }
}
