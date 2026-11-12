function Import-NXTEmpirumVariable {
	<#
	.SYNOPSIS
	Imports the Empirum computer variables into the Setup.cfg.
	.DESCRIPTION
	Configuration callback for the [SetupCfg] hook point. Only processed if the deployment system is Empirum.
	All Setup.cfg settings with the metadata CompVar=1 and a VarTmpl of the form 'Section.Setting' are set to the value of the matching entry in the computer specific Empirum ini file.
	The Setup.cfg is validated by the caller after all callbacks are processed.
	.PARAMETER Context
	The configuration context provided by the configuration callback invocation.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[ValidateNotNull()]
		[PSADTNXT.Configuration.NxtConfigurationContext]
		$Context
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if ($Context.DeploymentSystem -ne 'Empirum') { return }

			Initialize-NXTEmpirum

			# Import variables set in Empirum to the SetupConfig
			if (-not $script:EMP.ComputerValues.Exists) {
				Write-ADTLogEntry -Severity Warning -Message 'Cannot import Empirum variables, because the computer specific ini file does not exist.'
				return
			}

			Write-ADTLogEntry -Message "Importing Empirum variables from the computer specific ini file [$($script:EMP.ComputerValues.FullName)]."
			[PSADTNXT.Configuration.NxtIniDocument]$computerDocument = Import-NXTIniFile -Path $script:EMP.ComputerValues.FullName -AsIniDocument

			foreach ($setupSection in $Context.SetupCfg.GetEnumerator()) {
				foreach ($settingName in $setupSection.Value.Keys) {
					if (([System.Collections.Generic.Dictionary[System.String, System.String]]$metadata = $setupSection.Value.GetMetadata($settingName)) -and
						$metadata['CompVar'] -eq '1' -and
						-not [System.String]::IsNullOrWhiteSpace($metadata['VarTmpl'])
					) {
						if ($metadata['VarTmpl'] -notmatch '^[^\.]+\.[^\.]+$') {
							Write-ADTLogEntry -Severity Warning -Message "The variable [$settingName] in section [$($setupSection.Key)] does not have a valid VarTmpl value [$($metadata['VarTmpl'])] and will not be set."
							continue
						}
						[System.String]$compSectionName, [System.String]$compSettingName = $metadata['VarTmpl'].Split('.', 2)
						$compSectionName = [System.Environment]::ExpandEnvironmentVariables($compSectionName)
						$compSettingName = [System.Environment]::ExpandEnvironmentVariables($compSettingName)
						if (([PSADTNXT.Configuration.NxtIniSection]$compSection = $computerDocument[$compSectionName]) -and
							$compSection.ContainsKey($compSettingName)
						) {
							Write-ADTLogEntry -Message "Setting the variable [$compSettingName] in section [$($compSectionName)] to value [$($compSection[$compSettingName])]."
							$setupSection.Value[$settingName] = $compSection[$compSettingName]
						}
						else {
							Write-ADTLogEntry -Severity Warning -Message "The computer specific ini file does not contain a section [$compSectionName] or setting [$compSettingName]." -DebugMessage
						}
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
