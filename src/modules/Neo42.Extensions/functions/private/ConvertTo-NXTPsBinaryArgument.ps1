function ConvertTo-NXTPsBinaryArgument {
	<#
	.SYNOPSIS
	Translates given data into a PowerShell binary compatible command line argument string.
	#>
	[OutputType([System.String])]
	[CmdletBinding(DefaultParameterSetName = 'Command')]
	param (
		[Parameter(ParameterSetName = 'File', Mandatory)]
		[System.String]
		$File,
		[Parameter(ParameterSetName = 'Command', Mandatory)]
		[System.String]
		$Command,

		[System.Collections.Hashtable]
		$Arguments,
		[System.Management.Automation.SwitchParameter]
		$UseEnumValue,
		[AllowNull()]
		[Microsoft.PowerShell.ExecutionPolicy]
		$ExecutionPolicy = (Get-ExecutionPolicy -Scope Process),
		[System.Management.Automation.SwitchParameter]
		$Interactive,
		[System.Management.Automation.SwitchParameter]
		$LoadProfile,
		[System.Management.Automation.SwitchParameter]
		$ShowLogo,
		[System.Diagnostics.ProcessWindowStyle]
		$WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden,
		[System.Management.Automation.SwitchParameter]
		$UseLastExitCode,
		[System.Management.Automation.SwitchParameter]
		$Encode
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			# Construct base parameters of the powershell binary
			[System.Text.StringBuilder]$psArguments = [System.Text.StringBuilder]::new()
			if (-not $Interactive) { $null = $psArguments.Append('-NonI ') }
			if (-not $LoadProfile) { $null = $psArguments.Append('-NoP ') }
			if (-not $ShowLogo) { $null = $psArguments.Append('-NoL ') }
			if ($ExecutionPolicy) { $null = $psArguments.Append("-Ex $ExecutionPolicy ") }
			$null = $psArguments.Append("-W $($WindowStyle.ToString().Substring(0, 2)) ")
			$null = $psArguments.Append($(if ($Encode) { '-En "' } else { '-C "' }))

			# Construct the command string separately to be able to encode it if needed
			[System.Text.StringBuilder]$commandString = [System.Text.StringBuilder]::new('&{')
			$null = $commandString.Append($(if ($PSCmdlet.ParameterSetName -eq 'File') { "&'$File'" } else { ".{$Command}" }))

			if ($Arguments) {
				$null = $commandString.Append(' ')
				$null = $commandString.Append((ConvertTo-NXTPsArgumentString -InputObject $Arguments -StringDelimiter '''' -UseEnumValue:$UseEnumValue))
			}

			if ($UseLastExitCode) {
				$null = $commandString.Append(';exit(@(!$?;gv LASTEXITCODE -va -ea 0)[-1])')
			}

			$null = $commandString.Append('}')

			# Append the command string to the base parameters, encoded if needed
			$null = $psArguments.Append($(if ($Encode) { (Out-ADTPowerShellEncodedCommand -Command $commandString.ToString()) } else { $commandString.ToString() }))

			$null = $psArguments.Append('"')
			return $psArguments.ToString()
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
