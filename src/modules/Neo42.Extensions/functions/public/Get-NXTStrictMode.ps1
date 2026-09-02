function Get-NXTStrictMode {
	<#
	.SYNOPSIS
	Returns the currently applied strict mode version.
	.DESCRIPTION
	Returns the currently applied strict mode version.
	.OUTPUTS
	[System.Version] or $null
	.EXAMPLE
	Get-NXTStrictMode

	Returns the currently applied strict mode version as a System.Version object.
	.NOTES
	This function tries to determine the currently applied strict mode version by causing an error in each version.
	Currently the maximum supported version is 3. If a higher version is released, this function will need to be updated.
	#>
	[CmdletBinding()]
	[OutputType([System.Version])]
	param ()
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			# Run this test in the caller's session state to get their strict mode version
			return $ExecutionContext.InvokeCommand.InvokeScript(
				$PSCmdlet.SessionState,
				{
					# Array out of bounds in v3
					try { $null = @('OutOfBounds')[1] }
					catch { return [System.Version]::new('3.0') }
					# Accessing undefined properties in v2
					try { $null = @{}.undefined }
					catch { return [System.Version]::new('2.0') }
					# Accessing undefined variables in v1
					try { $null = ($undefined -gt 1) }
					catch { return [System.Version]::new('1.0') }
				}.Ast.GetScriptBlock()
			)
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
