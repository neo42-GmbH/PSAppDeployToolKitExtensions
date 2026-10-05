#Requires -RunAsAdministrator

param(
	[ValidateScript({ $_.Exists })]
	[System.IO.DirectoryInfo]
	$ModuleDirectory = "$PSScriptRoot\..\..\build"
)

# Preparation
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
Set-StrictMode -Version Latest

# Definitions
[System.IO.DirectoryInfo]$mockFiles = [System.IO.Path]::Combine($PSScriptRoot, 'mock-data')
[System.IO.DirectoryInfo]$psadt = [System.IO.Path]::Combine($ModuleDirectory, 'PSAppDeployToolkit')
[System.IO.DirectoryInfo]$neo42Extensions = [System.IO.Path]::Combine($ModuleDirectory, 'PSAppDeployToolkit.Neo42.Extensions')
[System.String]$modulesToFindPath = "$($ModuleDirectory)\PSAppDeployToolkit*"

# Import modules from local directories if PSADT is not loaded yet
if (-not (Get-Module -Name $psadt.BaseName)) {
	Get-ChildItem -Directory -Path $modulesToFindPath | ForEach-Object -Process { Import-Module -Name $PSItem.FullName -Force -Global }
	if (-not (Get-Module -Name $psadt.BaseName)) {
		throw "PSModule $($psadt.BaseName) not imported and not found in '$($modulesToFindPath)'."
	}
}

# Initialize ADT module
if (-not (Test-ADTModuleInitialized)) {
	Initialize-ADTModule -ScriptDirectory $neo42Extensions.FullName -AdditionalEnvironmentVariables (New-NXTEnvironmentTable)
	(Get-ADTConfig)['Toolkit']['LogWriteToHost'] = $false
}

# Open ADT session
if (-not (Test-ADTSessionActive)) {
	$oasParams = New-NXTSessionParameter -Invocation $MyInvocation -ScriptDirectory $mockFiles.FullName
	$oasParams['DeployMode'] = [PSADT.Module.DeployMode]::Silent
	$oasParams['NoProcessDetection'] = $true
	$oasParams['NoOobeDetection'] = $true
	$oasParams['DisableLogging'] = $true

	Open-ADTSession @oasParams -InformationAction SilentlyContinue
}
