#Requires -Modules Pester
param(
	[System.IO.DirectoryInfo]
	$ModuleDirectory = "$($PWD.Path)\build"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework # Import to remove false positives in UI scripts

[System.IO.FileInfo[]]$sourceFiles = Get-ChildItem -Recurse -File -Path "$PSScriptRoot\src\modules\" | Where-Object { $_.Extension -eq '.ps1' }
[System.Collections.Generic.List[Pester.ContainerInfo]]$containers = [System.Collections.Generic.List[Pester.ContainerInfo]]::new()
$containers.Add((New-PesterContainer -Path "$PSScriptRoot\tests\pester\Compatibility.Tests.ps1" -Data @{ FilePath = $sourceFiles }))
$containers.AddRange([Pester.ContainerInfo[]]@(New-PesterContainer -Path "$PSScriptRoot\tests\pester\function-tests"))

[System.IO.DirectoryInfo]$mockData = "$PSScriptRoot\tests\pester\mock-data"
[System.IO.DirectoryInfo]$psadt = "$($ModuleDirectory.FullName)\PSAppDeployToolkit"
[System.IO.DirectoryInfo]$neo42Extensions = "$($ModuleDirectory.FullName)\PSAppDeployToolkit.Neo42.Extensions"

if (-not (Get-Module -Name $psadt.BaseName)) {
	Get-ChildItem -Directory -LiteralPath $ModuleDirectory.FullName -Filter 'PSAppDeployToolkit*' | ForEach-Object {
		Import-Module -Name $PSItem.FullName -Force -ErrorAction Stop -Global
	}
}

if (-not (Test-ADTModuleInitialized)) {
	Initialize-ADTModule -ScriptDirectory $neo42Extensions.FullName -AdditionalEnvironmentVariables (New-NXTEnvironmentTable) -ErrorAction Stop
	(Get-ADTConfig)['Toolkit']['LogWriteToHost'] = $false
}

if (-not (Test-ADTSessionActive)) {
	$oasParams = New-NXTSessionParameter -Invocation $MyInvocation -ScriptDirectory $mockData.FullName -ErrorAction Stop
	$oasParams['DeployMode'] = 'Silent'
	$oasParams['NoProcessDetection'] = $true
	$oasParams['NoOobeDetection'] = $true
	$oasParams['DisableLogging'] = $true

	Open-ADTSession @oasParams -ErrorAction Stop -InformationAction SilentlyContinue
}

Invoke-Pester -Configuration @{
	Output = @{
		StackTraceVerbosity = 'None'
	}
	Run    = @{
		Exit      = $true
		Container = $containers
	}
}
