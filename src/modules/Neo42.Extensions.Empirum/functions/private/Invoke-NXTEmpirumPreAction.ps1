function Invoke-NXTEmpirumPreAction {
	<#
	.SYNOPSIS
	Invokes Empirum specific post session tasks.
	#>
	[CmdletBinding()]
	param ()
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[PSADTNXT.Foundation.NxtDeploymentSession]$adtSession = Get-ADTSession
			if ($adtSession.NXT.DeploymentSystem -ne 'Empirum') { return }

			# Import variables set in Empirum to the SetupConfig
			if ($script:EMP.ComputerValues.Exists) {
				Write-ADTLogEntry -Message "Importing Empirum variables from the computer specific ini file [$($script:EMP.ComputerValues.FullName)]."
				[PSADTNXT.Configuration.NxtIniDocument]$computerDocument = Import-NXTIniFile -Path $script:EMP.ComputerValues.FullName -AsIniDocument

				foreach ($setupSection in $adtSession.NXT.SetupCfg.GetEnumerator()) {
					foreach ($settingName in $setupSection.Value.Keys) {
						if (([System.Collections.Generic.Dictionary[System.String, System.String]]$metadata = $setupSection.Value.GetMetadata($settingName)) -and
							$metadata['CompVar'] -eq '1' -and
							-not [System.String]::IsNullOrWhiteSpace($metadata['VarTmpl'])
						) {
							if ($metadata['VarTmpl'] -notmatch '^\w+\.\w+$') {
								Write-ADTLogEntry -Severity Warning -Message "The variable [$settingName] in section [$($setupSection.Key)] does not have a valid VarTmpl value [$($metadata['VarTmpl'])] and will not be set."
								continue
							}
							[System.String]$compSectionName, [System.String]$compSettingName = $metadata['VarTmpl'].Split('.', 2)
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
			else {
				Write-ADTLogEntry -Severity Warning -Message 'Cannot import Empirum variables, because the computer specific ini file does not exist.'
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
