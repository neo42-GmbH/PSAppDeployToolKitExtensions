function Import-NXTSetupCfg {
	<#
	.SYNOPSIS
	Imports the setup configuration.
	#>
	[OutputType([PSADTNXT.Configuration.NxtIniDocument])]
	[CmdletBinding()]
	param (
		[AllowEmptyCollection()]
		[System.IO.FileInfo[]]
		$Path
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Collections.Hashtable]$adtConfig = Get-ADTConfig
	}
	process {
		try {
			[PSADTNXT.Configuration.NxtIniDocument]$setupCfgObj = Import-NXTIniFile -LiteralPath ([System.IO.Path]::Combine($MyInvocation.MyCommand.Module.ModuleBase, 'Setup.cfg')) -AsIniDocument
			if ($Path) {
				$Path | & { process { $setupCfgObj.Merge((Import-NXTIniFile -LiteralPath $_.FullName -AsIniDocument), $true) } }
			}

			# Check if overrides exists for setup cfg overrides (GPO or other)
			if ($adtConfig['NXT'].ContainsKey('SetupCfg') -and $adtConfig['NXT']['SetupCfg'].ContainsKey('Overrides')) {
				foreach ($override in $adtConfig['NXT']['SetupCfg']['Overrides'].Values) {
					[System.String]$section, [System.String]$setting, [System.String]$value = $override.Split(';', 3).Trim()
					if ($setupCfgObj.ContainsKey($section) -and $setupCfgObj[$section].ContainsKey($setting)) {
						$setupCfgObj[$section][$setting] = $value
					}
				}
			}

			# Validate the final setup cfg with the metadata it contains
			[System.String[]]$errors = @()
			if (-not $setupCfgObj.Validate([ref]$errors)) {
				[System.Collections.Hashtable]$errorParams = @{
					Exception    = [System.Exception]::new("The provided setup configuration is invalid. Errors:`n- $($errors -join "`n- ")")
					Category     = [System.Management.Automation.ErrorCategory]::InvalidData
					ErrorId      = 'SetupConfigInvalid'
					TargetObject = $setupCfgObj
				}
				throw (New-ADTErrorRecord @errorParams)
			}

			$PSCmdlet.WriteObject($setupCfgObj, $false)
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
