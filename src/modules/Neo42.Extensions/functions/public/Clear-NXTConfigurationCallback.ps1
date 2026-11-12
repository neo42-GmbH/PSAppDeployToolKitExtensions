function Clear-NXTConfigurationCallback {
	<#
	.SYNOPSIS
	Clears all configuration callbacks of a hook point.
	.DESCRIPTION
	This function removes all callbacks that were previously added with Add-NXTConfigurationCallback from the specified hook points.
	.PARAMETER HookPoint
	The configuration hook points to clear.
	.EXAMPLE
	Clear-NXTConfigurationCallback -HookPoint SetupCfg

	Clears all callbacks attached to SetupCfg.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'No state change.')]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[PSADTNXT.Configuration.ConfigurationHookPoint[]]
		$HookPoint
	)
	$HookPoint | & { process { $script:ConfigurationCallbacks[$_].Clear() } }
}
