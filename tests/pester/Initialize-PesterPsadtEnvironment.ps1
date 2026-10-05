#Requires -RunAsAdministrator

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
[System.IO.DirectoryInfo]$workspace = "$PSScriptRoot\..\.."
[System.IO.DirectoryInfo]$mockFiles = [System.IO.Path]::Combine($PSScriptRoot, 'mock-data')
[System.IO.DirectoryInfo]$psadt = [System.IO.Path]::Combine($workspace.FullName, 'build', 'PSAppDeployToolkit')
[System.IO.DirectoryInfo]$neo42Extensions = [System.IO.Path]::Combine($workspace.FullName, 'build', 'PSAppDeployToolkit.Neo42.Extensions')

if (-not (Get-Module -Name $psadt.BaseName)) {
	Get-ChildItem -Directory -LiteralPath $workspace.FullName -Filter 'PSAppDeployToolkit*' | ForEach-Object {
		Import-Module -Name $PSItem.FullName -Force -Global
	}
}

if (-not (Test-ADTModuleInitialized)) {
	Initialize-ADTModule -ScriptDirectory $neo42Extensions.FullName -AdditionalEnvironmentVariables (New-NXTEnvironmentTable)
	(Get-ADTConfig)['Toolkit']['LogWriteToHost'] = $false
}

if (-not (Test-ADTSessionActive)) {
	$oasParams = New-NXTSessionParameter -Invocation $MyInvocation -ScriptDirectory $mockFiles.FullName
	$oasParams['DeployMode'] = [PSADT.Module.DeployMode]::Silent
	$oasParams['NoProcessDetection'] = $true
	$oasParams['NoOobeDetection'] = $true
	$oasParams['DisableLogging'] = $true

	Open-ADTSession @oasParams -InformationAction SilentlyContinue
}
