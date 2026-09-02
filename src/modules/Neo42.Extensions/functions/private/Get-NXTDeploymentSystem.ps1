function Get-NXTDeploymentSystem {
	<#
	.SYNOPSIS
	Will return the current deployment system name.
	.DESCRIPTION
	Tries to determine the current deployment system name based on the environment.
	Returns 'Unknown' if no deployment system could be determined.
	#>
	[OutputType([System.String])]
	[CmdletBinding()]
	param ()
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			# TODO: Add more deployment systems as needed

			# Process based detection
			[System.Diagnostics.Process[]]$parents = Get-NXTParentProcess -Id $PID -Recurse
			if ($parents) {
				if ($parents.ProcessName -contains 'Microsoft.Management.Services.IntuneWindowsAgent') { return 'Intune' }
				if ($parents.ProcessName -contains 'Matrix42.Platform.Service.Host') { return 'Empirum' }
			}

			# Return unknown if no deployment system could be determined
			return 'Unknown'
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
