<#
.SYNOPSIS
	This script is a minimalistic version of Deploy-Application.ps1. It is used to test our AppDeployToolkit Extensions.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.NOTES
	# LICENSE #
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

	# ORIGINAL COPYRIGHT #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.

	# MODIFICATION COPYRIGHT #
	Copyright (c) 2024 neo42 GmbH, Germany.

	Version: ##REPLACEVERSION##
.LINK
	http://psappdeploytoolkit.com
#>
## set the script execution policy for this process
Try { Set-ExecutionPolicy -ExecutionPolicy 'Bypass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
## Variables: Exit Code
[int32]$mainExitCode = 0
## Variables: Script
[string]$deployAppScriptFriendlyName = 'Deploy Application'
[string]$deployAppScriptVersion = [string]'##REPLACEVERSION##'
[string]$deployAppScriptDate = '02/05/2023'
[hashtable]$deployAppScriptParameters = $psBoundParameters
## Variables: Environment
If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
[string]$global:AppLogFolder = $scriptDirectory
[int]$env:nxtScriptDepth += 1
## dot source the required AppDeploy Toolkit functions
Try {
	[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
	Write-Output $moduleAppDeployToolkitMain
	Test-Path $moduleAppDeployToolkitMain
	If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { 
		Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]."
	}
	If ($DisableLogging) {
		. $moduleAppDeployToolkitMain -DisableLogging
	} 
	Else {
		. $moduleAppDeployToolkitMain
	}
}
Catch {
	If ($mainExitCode -eq 0) { [int32]$mainExitCode = 60008 }
	Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
	## exit the script, returning the exit code
	Write-Output "Testing path $moduleAppDeployToolkitMain"
	Test-Path $moduleAppDeployToolkitMain
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
}
Write-Log "Current running script depth: $($global:NxtScriptDepth)" -Source $deployAppScriptFriendlyName