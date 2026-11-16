function Add-NXTConfigurationCallback {
	<#
	.SYNOPSIS
	Adds a callback that is invoked during the session configuration, before a deployment session is opened.
	.DESCRIPTION
	The Add-NXTConfigurationCallback function registers a command that is invoked by New-NXTSessionParameter at the specified configuration hook point.
	This allows extension modules to alter the configuration before the session is opened:
	- SetupCfg: The Setup.cfg can be changed before the toolkit overrides are applied and the package configuration is constructed from it.
	The callback is invoked with a single parameter named Context of type [PSADTNXT.Configuration.NxtConfigurationContext].
	As no session exists at this point, Get-ADTSession is not available within the callback.
	Throwing an exception within the callback aborts the session configuration.
	.PARAMETER Callback
	The command information object representing the function to be invoked.
	.PARAMETER HookPoint
	The configuration hook point at which the callback should be invoked.
	.PARAMETER Prepend
	Add the callback to the top of the list.
	.EXAMPLE
	Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback (Get-Command -Name 'My-SetupCfgModification')

	This example registers the 'My-SetupCfgModification' function, which will be invoked with the -Context parameter after the Setup.cfg files are merged.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.CommandInfo[]]
		$Callback,
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[PSADTNXT.Configuration.ConfigurationHookPoint[]]
		$HookPoint,
		[System.Management.Automation.SwitchParameter]
		$Prepend
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			foreach ($hook in $HookPoint) {
				if ($Prepend) {
					$script:ConfigurationCallbacks[$hook].InsertRange(0, $Callback)
				}
				else {
					$script:ConfigurationCallbacks[$hook].AddRange($Callback)
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
