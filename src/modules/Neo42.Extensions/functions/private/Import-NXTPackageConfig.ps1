function Import-NXTPackageConfig {
	<#
	.SYNOPSIS
	Imports the package config.
	#>
	[OutputType([PSADTNXT.Deployment.Configuration.NxtPackageConfigurationModel])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$ScriptDirectory,
		[Parameter(Mandatory)]
		[ValidateNotNull()]
		[PSADTNXT.Configuration.NxtIniDocument]
		$SetupCfg
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Collections.Hashtable]$adtConfig = Get-ADTConfig
		[System.Collections.Generic.IReadOnlyDictionary[System.String, System.Object]]$adtEnvironment = Get-ADTEnvironmentTable
	}
	process {
		try {
			[System.Management.Automation.Runspaces.SessionStateVariableEntry]$setupCfgVariable = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new('SetupCfg', $SetupCfg.AsReadOnly(), [System.String]::Empty)

			[PSADTNXT.Deployment.Configuration.NxtPackageConfigurationModel]$packageConfig = $null
			if ($adtConfig['NXT']['Toolkit']['SupportLegacyConfig'] -and
				([System.IO.FileInfo]$packageConfigJson = Get-Item -LiteralPath ([System.IO.Path]::Combine($ScriptDirectory, 'neo42PackageConfig.json')) -ErrorAction Ignore)
			) {
				[PSADTNXT.Deployment.Configuration.Legacy.NxtLegacyPackageConfigurationModel]$legacyPackageConfig = [PSADTNXT.Deployment.Configuration.NxtPackageConfigurationFactory]::CreateLegacyFrom(
					$packageConfigJson.FullName,
					$adtEnvironment,
					@($setupCfgVariable)
				)
				# The legacy config has to be valid before it can be translated to the current model
				$legacyPackageConfig.ThrowIfInvalid()
				$packageConfig = [PSADTNXT.Deployment.Configuration.NxtPackageConfigurationFactory]::Translate($legacyPackageConfig)
			}
			elseif (([System.IO.FileInfo]$packageConfigPsd1 = Get-Item -LiteralPath ([System.IO.Path]::Combine($ScriptDirectory, 'neo42PackageConfig.psd1')) -ErrorAction Ignore)) {
				$packageConfig = [PSADTNXT.Deployment.Configuration.NxtPackageConfigurationFactory]::CreateFrom(
					$packageConfigPsd1.FullName,
					$adtEnvironment,
					@($setupCfgVariable)
				)
			}
			else {
				[System.Collections.Hashtable]$errorParams = @{
					Exception    = [System.Exception]::new("No valid package configuration file found. Please ensure that either 'neo42PackageConfig.json' (legacy) or 'neo42PackageConfig.psd1' (recommended) exists in the script directory.")
					Category     = [System.Management.Automation.ErrorCategory]::InvalidData
					ErrorId      = 'PackageConfigNotFound'
					TargetObject = $ScriptDirectory
				}
				throw (New-ADTErrorRecord @errorParams)
			}

			$packageConfig.ThrowIfInvalid()
			return $packageConfig
		}
		catch [PSADTNXT.Deployment.Configuration.NxtPackageConfigurationValidationException] {
			[System.Collections.Hashtable]$errorParams = @{
				Exception = $_.Exception
				Category  = [System.Management.Automation.ErrorCategory]::InvalidData
				ErrorId   = 'PackageConfigInvalid'
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
