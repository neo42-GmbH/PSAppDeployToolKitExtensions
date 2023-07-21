<#
.SYNOPSIS
	This script just contains example code.
.DESCRIPTION
	The script is provided to supply examples for usage in script 'Deploy-Application.ps1'.
.NOTES
	Just copy necessary example code into current script.
.LINK
	http://psappdeploytoolkit.com
#>
function CustomBegin {
	[string]$script:installPhase = 'CustomBegin'

	## Always executes at the beginning of the script regardless of the DeploymentType ('Install', 'Uninstall', 'Repair', 'InstallUserPart', 'UninstallUserPart')

    ############################################
	## EXAMPLE 1 ##
	## decision for usage of a custom setup file by pre-defined registry value set by GPO for example

	## please fill in here real used values
	[string]$regKeySetByGPO = "HKLM:\SOFTWARE\Policies\packages\<PackageGUID>"
	[string]$regValueSetByGPO = "CustomSetupFileName"

	[string]$customSetupFileName = Get-RegistryKey -Key "$regKeySetByGPO" -Value "$regValueSetByGPO"
	if (![string]::IsNullOrEmpty($customSetupFileName)) {
		Set-NxtSetupCfg -Path "$PSScriptRoot\$customSetupFileName"
		if ($false -eq (Test-Path -Path "$PSScriptRoot\$customSetupFileName")) {
			## alternatively, if necessary you can stop script execution commonly here: uncomment next line
			#Exit-NxtScriptWithError -ErrorMessage "The installation/uninstallation aborted with an invalid file decision!" -MainExitCode '60001'
		}
	}
	else {
		Write-Log -Message "No or invalid registry key/value for a custom setup file defined." -Severity 3 -Source $deployAppScriptFriendlyName
		## alternatively, if necessary you can stop script execution here: uncomment next line
		#Exit-NxtScriptWithError -ErrorMessage "The installation/uninstallation aborted with an invalid pre-configuration!" -MainExitCode '60001'
	}

	############################################
	## EXAMPLE 2 ##
	## decision for usage of a custom setup file by set an environment variable value for example

	## please fill in here real used values
	[string]$decision = $env:Department

	## please fill in and/or add/remove here real used decisions
	switch ($decision) {
		{"<department_A>","<department_B>" -contains $_} {
			[string]$customSetupFile = "$PSScriptRoot\Setup_AB.cfg"
		}
		## ... just simply for a single value
		"<department_C>" {
			[string]$customSetupFile = "$PSScriptRoot\Setup_C.cfg"
		}
		Default {
			[string]$customSetupFile = $null
			Write-Log -Message "No custom setup file defined for current selection [$decision]." -Severity 3 -Source $deployAppScriptFriendlyName
			## alternatively, if necessary you can stop script execution here: uncomment next line
			#Exit-NxtScriptWithError -ErrorMessage "The installation/uninstallation aborted with an invalid file decision!" -MainExitCode '60001'
		}
	}
	if (![string]::IsNullOrEmpty($customSetupFile)) {
		Set-NxtSetupCfg -Path "$customSetupFile"
		if ($false -eq (Test-Path -Path "$customSetupFile")) {
			## alternatively, if necessary you can stop script execution commonly here: uncomment next line
			#Exit-NxtScriptWithError -ErrorMessage "The installation/uninstallation aborted with an invalid custom setup file selection!" -MainExitCode '60001'
		}
	}

	############################################
	## EXAMPLE 3 ##
	## decision for usage of a custom setup file by set an environment variable value and direct usage of value for file name as fastest solution for example

	## please fill in here real used values
	[string]$decision = $env:Department

	if (![string]::IsNullOrEmpty($decision)) {
		Set-NxtSetupCfg -Path "$PSScriptRoot\$decision.cfg"
		if ($false -eq (Test-Path -Path "$PSScriptRoot\$decision.cfg")) {
			## alternatively, if necessary you can stop script execution commonly here: uncomment next line
			#Exit-NxtScriptWithError -ErrorMessage "The installation/uninstallation aborted with an invalid custom setup file selection!" -MainExitCode '60001'
		}
	}
	else {
		Write-Log -Message "Invalid decision for a custom setup file defined." -Severity 3 -Source $deployAppScriptFriendlyName
		## alternatively, if necessary you can stop script execution here: uncomment next line
		#Exit-NxtScriptWithError -ErrorMessage "The installation/uninstallation aborted with an invalid pre-configuration!" -MainExitCode '60001'
    }
}
Write-Host "Please open this script in an editor and copy necessary code parts into your script."