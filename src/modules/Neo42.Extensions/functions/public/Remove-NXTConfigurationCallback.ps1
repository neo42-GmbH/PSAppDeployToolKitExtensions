function Remove-NXTConfigurationCallback {
	<#
	.SYNOPSIS
	Removes a specific configuration callback.
	.DESCRIPTION
	The Remove-NXTConfigurationCallback function removes a callback that was previously added with Add-NXTConfigurationCallback.
	.PARAMETER Callback
	The callback function to remove.
	.PARAMETER HookPoint
	The configuration hook point the callback is attached to.
	.EXAMPLE
	Remove-NXTConfigurationCallback -HookPoint SetupCfg -Callback (Get-Command -Name 'My-SetupCfgModification')

	This example removes the callback function named 'My-SetupCfgModification' from the 'SetupCfg' hook point.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'No state change.')]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.CommandInfo[]]
		$Callback,
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[PSADTNXT.Configuration.ConfigurationHookPoint[]]
		$HookPoint
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			foreach ($hook in $HookPoint) {
				foreach ($call in $Callback) {
					if (-not $script:ConfigurationCallbacks[$hook].Remove($call)) {
						[System.Collections.Hashtable]$errorParams = @{
							Exception    = [System.InvalidOperationException]::new("There is no callback [$($call.Name)] attached to hook point [$hook].")
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
