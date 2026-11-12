function Import-NXTSetupCfg {
	<#
	.SYNOPSIS
	Imports the setup configuration.
	.DESCRIPTION
	Loads the module default Setup.cfg and merges the provided files on top of it.
	Afterwards the [SetupCfg] configuration callbacks are invoked, the toolkit overrides are applied and the result is validated.
	#>
	[OutputType([PSADTNXT.Configuration.NxtIniDocument])]
	[CmdletBinding()]
	param (
		[AllowEmptyCollection()]
		[System.IO.FileInfo[]]
		$Path,
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$ScriptDirectory,
		[Parameter(Mandatory)]
		[ValidateNotNull()]
		[PSADTNXT.Deployment.NxtDeploymentType]
		$DeploymentType,
		[AllowEmptyString()]
		[System.String]
		$DeploymentSystem
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

			# Allow extensions to alter the setup cfg before the toolkit overrides are applied and the package config is constructed
			[PSADTNXT.Configuration.NxtConfigurationContext]$context = [PSADTNXT.Configuration.NxtConfigurationContext]::new($setupCfgObj, $ScriptDirectory, $DeploymentType, $DeploymentSystem)
			foreach ($callback in $script:ConfigurationCallbacks[[PSADTNXT.Configuration.ConfigurationHookPoint]::SetupCfg]) {
				$null = & $callback -Context $context
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
			$setupCfgObj.ThrowIfInvalid()

			$PSCmdlet.WriteObject($setupCfgObj, $false)
		}
		catch [PSADTNXT.Configuration.NxtIniValidationException] {
			[System.Collections.Hashtable]$errorParams = @{
				Exception    = $_.Exception
				Category     = [System.Management.Automation.ErrorCategory]::InvalidData
				ErrorId      = 'SetupConfigInvalid'
				TargetObject = $setupCfgObj
			}
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord (New-ADTErrorRecord @errorParams)
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
