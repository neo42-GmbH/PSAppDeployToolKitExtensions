<#
	.SYNOPSIS
		This script just contains example code.
	.DESCRIPTION
		The script is provided to supply examples for usage in script 'Deploy-Application.ps1'.
    .NOTES
		Just copy necessary example code into current script.

        # LICENSE #
        This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
        You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

        # COPYRIGHT #
        Copyright (c) 2024 neo42 GmbH, Germany.
	.LINK
		http://psappdeploytoolkit.com
#>
function CustomBegin {
	[string]$script:installPhase = 'CustomBegin'

	## Always executes at the beginning of the script regardless of the DeploymentType ('Install', 'Uninstall', 'Repair', 'InstallUserPart', 'UninstallUserPart')

    ############################################
	## EXAMPLE 1 ##
	## decision for usage of an alternative setup file by pre-defined registry value set by GPO for example

	## please fill in here real used values
	[string]$regKeySetByGPO = "HKLM:\SOFTWARE\Policies\packages\<PackageGUID>"
	[string]$regValueSetByGPO = "SetupFileNameToUse"

	[string]$alternativeSetupCfg = Get-RegistryKey -Key "$regKeySetByGPO" -Value "$regValueSetByGPO"
	if (![string]::IsNullOrEmpty($alternativeSetupCfg)) {
		Set-NxtSetupCfg -Path "$PSScriptRoot\$alternativeSetupCfg"
		if ($false -eq (Test-Path -Path "$PSScriptRoot\$alternativeSetupCfg")) {
			## alternatively, if necessary you can stop script execution commonly here: uncomment next line
			#Exit-NxtScriptWithError -ErrorMessage "The installation/uninstallation aborted with an invalid file decision!" -MainExitCode '69001'
		}
	}
	else {
		Write-Log -Message "No or invalid registry key/value for an alternative setup file defined." -Severity 3 -Source $deployAppScriptFriendlyName
		## alternatively, if necessary you can stop script execution here: uncomment next line
		#Exit-NxtScriptWithError -ErrorMessage "The installation/uninstallation aborted with an invalid pre-configuration!" -MainExitCode '69001'
	}

	############################################
	## EXAMPLE 2 ##
	## decision for usage of an alternative setup file by set an environment variable value for example

	## please fill in here real used values
	[string]$decision = $env:Department

	## please fill in and/or add/remove here real used decisions
	switch ($decision) {
		{"<department_A>","<department_B>" -contains $_} {
			[string]$alternativeSetupCfg = "$PSScriptRoot\Setup_AB.cfg"
		}
		## ... just simply for a single value
		"<department_C>" {
			[string]$alternativeSetupCfg = "$PSScriptRoot\Setup_C.cfg"
		}
		Default {
			[string]$alternativeSetupCfg = $null
			Write-Log -Message "No alternative setup file defined for current selection [$decision]." -Severity 3 -Source $deployAppScriptFriendlyName
			## alternatively, if necessary you can stop script execution here: uncomment next line
			#Exit-NxtScriptWithError -ErrorMessage "The installation/uninstallation aborted with an invalid file decision!" -MainExitCode '69001'
		}
	}
	if (![string]::IsNullOrEmpty($alternativeSetupCfg)) {
		Set-NxtSetupCfg -Path "$alternativeSetupCfg"
		if ($false -eq (Test-Path -Path "$alternativeSetupCfg")) {
			## alternatively, if necessary you can stop script execution commonly here: uncomment next line
			#Exit-NxtScriptWithError -ErrorMessage "The installation/uninstallation aborted with an invalid alternative setup file selection!" -MainExitCode '69001'
		}
	}

	############################################
	## EXAMPLE 3 ##
	## decision for usage of an alternative setup file by set an environment variable value and direct usage of value for file name as fastest solution for example

	## please fill in here real used values
	[string]$decision = $env:Department

	if (![string]::IsNullOrEmpty($decision)) {
		Set-NxtSetupCfg -Path "$PSScriptRoot\$decision.cfg"
		if ($false -eq (Test-Path -Path "$PSScriptRoot\$decision.cfg")) {
			## alternatively, if necessary you can stop script execution commonly here: uncomment next line
			#Exit-NxtScriptWithError -ErrorMessage "The installation/uninstallation aborted with an invalid alternative setup file selection!" -MainExitCode '69001'
		}
	}
	else {
		Write-Log -Message "Invalid decision for an alternative setup file defined." -Severity 3 -Source $deployAppScriptFriendlyName
		## alternatively, if necessary you can stop script execution here: uncomment next line
		#Exit-NxtScriptWithError -ErrorMessage "The installation/uninstallation aborted with an invalid pre-configuration!" -MainExitCode '69001'
    }
}
Write-Host "Please open this script in an editor and copy necessary code parts into your script."