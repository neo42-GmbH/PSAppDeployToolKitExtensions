function Import-NXTPackageConfig {
	<#
	.SYNOPSIS
	Imports the package config.
	#>
	[OutputType([PSADTNXT.Deployment.Configuration.NxtPackageConfigurationModel])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[ValidateNotNull()]
		[System.IO.DirectoryInfo]
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
			[System.IO.FileInfo]$packageConfigJson = [System.IO.Path]::Combine($ScriptDirectory.FullName, 'neo42PackageConfig.json')
			[System.IO.FileInfo]$packageConfigPsd1 = [System.IO.Path]::Combine($ScriptDirectory.FullName, 'neo42PackageConfig.psd1')
			[System.Management.Automation.Runspaces.SessionStateVariableEntry]$setupCfgVariable = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new('SetupCfg', $SetupCfg.AsReadOnly(), [System.String]::Empty)

			if ($adtConfig['NXT']['Toolkit']['SupportLegacyConfig'] -and $packageConfigJson.Exists) {
				return [PSADTNXT.Deployment.Configuration.NxtPackageConfigurationFactory]::Translate(
					[PSADTNXT.Deployment.Configuration.NxtPackageConfigurationFactory]::CreateLegacyFrom(
						$packageConfigJson.FullName,
						$adtEnvironment,
						@($setupCfgVariable)
					)
				)
			}
			elseif ($packageConfigPsd1.Exists) {
				return [PSADTNXT.Deployment.Configuration.NxtPackageConfigurationFactory]::CreateFrom(
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
					TargetObject = $ScriptDirectory.FullName
				}
				throw (New-ADTErrorRecord @errorParams)
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
