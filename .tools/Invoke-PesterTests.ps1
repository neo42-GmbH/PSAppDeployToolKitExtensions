#Requires -Modules @{ ModuleName='Pester'; MaximumVersion='6.1.0' }

<#
    .SYNOPSIS
    Invoke the test suite for this repo.

    .PARAMETER ModuleDirectory
    The directory to load the PSADT modules from.

    .PARAMETER PesterTestDirectory
    The directory that is scanned for ps1 files to test.

    .PARAMETER CompatibilityTestDirectory
    The directory that is scanned for ps1 files to test compatibility factors.

    .PARAMETER ExcludeTestFilesLike
    A set of strings with test file names to exclude from the test run. Wildcards allowed.

    .PARAMETER IncludeTestFilesLike
    A set of strings with test file names to include to the test run ignoring other test files. Wildcards allowed.

    .PARAMETER Verbosity
    A string value of a selection list to define the pester verbosity level.

    .PARAMETER StackTraceVerbosity
    A string value of a selection list to define the pester stack trace verbosity level.

    .PARAMETER ResultXmlOutput
    Full file path for pester result xml with a detailed result overview (like .\pester_result.xml).

    .PARAMETER PassThru
    If enabled, the pester result object will be returned. Otherwise, the script will return nothing.

    .PARAMETER Exit
    If enabled, the pester test will exit with non-zero exit code and no result object when the test run fails.

    .PARAMETER SkipRun
    If enabled, the pester test will be skipped. Useful for test scenarios.

    .PARAMETER WriteDebugMessages
    If enabled, debug messages will be written to the console.

    .PARAMETER ShowNavigationMarkers
    If enabled, navigation markers will be written to the console (Write paths after every block and test, for easy navigation in VSCode).

    .PARAMETER ShowStartMarkers
    If enabled, navigation markers will be written to the console (Write an indication when each test starts).

    .INPUTS
    None. You cannot pipe objects to this script.

    .OUTPUTS
    None
	PassThru: [Pester.Run] result object
#>

[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSNxtAvoidTypeAccelerator', '', Justification = '[PesterConfiguration] is the FullName and no Accelerator')]
param(
	[ValidateScript({ $_.Exists })]
	[System.IO.DirectoryInfo]
	$ModuleDirectory = "$($PWD.Path)\build",
	[ValidateScript({ $_.Exists })]
	[System.IO.DirectoryInfo]
	$PesterTestDirectory = "$($PWD.Path)\tests\pester",
	[ValidateScript({ $_.Exists })]
	[System.IO.DirectoryInfo]
	$CompatibilityTestDirectory = "$($PWD.Path)\src\modules",
	[System.String[]]
	$ExcludeTestFilesLike,
	[System.String[]]
	$IncludeTestFilesLike,
	[ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
	[System.String]
	$Verbosity = 'Normal',
	[ValidateSet('None', 'FirstLine', 'Filtered ', 'Full')]
	[System.String]
	$StackTraceVerbosity = 'FirstLine',
	[System.String]
	$ResultXmlOutput,
	[System.Management.Automation.SwitchParameter]
	$PassThru,
	[System.Management.Automation.SwitchParameter]
	$Exit,
	[System.Management.Automation.SwitchParameter]
	$SkipRun,
	[System.Management.Automation.SwitchParameter]
	$WriteDebugMessages,
	[System.Management.Automation.SwitchParameter]
	$ShowNavigationMarkers,
	[System.Management.Automation.SwitchParameter]
	$ShowStartMarkers
)

# Definitions
[System.IO.DirectoryInfo]$fcnDir = "$($PesterTestDirectory.FullName)\function-tests"
[System.IO.FileInfo]$compScript = "$($PesterTestDirectory.FullName)\Compatibility.Tests.ps1"
[System.IO.FileInfo]$initEnvScript = "$($PesterTestDirectory.FullName)\Initialize-PesterPsadtEnvironment.ps1"

# Preparation
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Add-Type -AssemblyName 'PresentationFramework'  # to remove false positives in UI scripts

# Check files
@($fcnDir, $compScript, $initEnvScript) | ForEach-Object -Process {
	if (-not (Test-Path -Path $_)) { throw "Missing file: '$_'!" }
}

# Initialize pester psadt environment
. $initEnvScript.FullName -ModuleDirectory $ModuleDirectory

# Create the test container
[System.Collections.Generic.List[Pester.ContainerInfo]]$containers = [System.Collections.Generic.List[Pester.ContainerInfo]]::new()

# Build test container for testing compatibility factors of existing script files, such as function files
[System.IO.FileInfo[]]$sourceFiles = Get-ChildItem -Recurse -File -Path $CompatibilityTestDirectory.FullName | Where-Object -FilterScript { $_.Extension -eq '.ps1' }
[Pester.ContainerInfo]$pContainer = [Pester.ContainerInfo](New-PesterContainer -Path $compScript -Data @{ FilePath = $sourceFiles })
$containers.Add($pContainer)

# Build test container for testing functions via defined test files
[Pester.ContainerInfo[]]$pContainers = [Pester.ContainerInfo[]]@(New-PesterContainer -Path $fcnDir)
$containers.AddRange($pContainers)

# Exclude and include files
[System.Collections.Generic.List[Pester.ContainerInfo]]$containersFiltered = [System.Collections.Generic.List[Pester.ContainerInfo]]::new()
if ($containers.Count -ge 0) {
	if (-not [System.String]::IsNullOrWhiteSpace($IncludeTestFilesLike)) {
		foreach ($container in $containers) {
			[System.Boolean]$found = $false
			foreach ($filename in $IncludeTestFilesLike) {
				if ($container.Item.Name -like $filename) {
					$found = $true
				}
			}
			if ($found) { $containersFiltered.Add($container) }
		}
	}
	else {
		$containersFiltered.AddRange($containers)
	}
	if (-not [System.String]::IsNullOrWhiteSpace($ExcludeTestFilesLike)) {
		foreach ($container in $containers) {
			foreach ($filename in $ExcludeTestFilesLike) {
				if ($container.Item.Name -like $filename) {
					$containersFiltered.Remove($container)
				}
			}
		}
	}
}

# Start test process
[PesterConfiguration]$pConf = New-PesterConfiguration -Hashtable @{
	Run          = @{
		Container = $containersFiltered
		PassThru  = $PassThru.ToBool()
		SkipRun   = $SkipRun.ToBool()
		Exit      = $Exit.ToBool()
	}
	TestResult   = @{
		Enabled    = -not [System.String]::IsNullOrWhiteSpace($ResultXmlOutput)
		OutputPath = $ResultXmlOutput
	}
	Debug        = @{
		WriteDebugMessages    = $WriteDebugMessages.ToBool()
		ShowNavigationMarkers = $ShowNavigationMarkers.ToBool()
		ShowStartMarkers      = $ShowStartMarkers.ToBool()
	}
	Output       = @{
		StackTraceVerbosity = $StackTraceVerbosity
		Verbosity           = $Verbosity
	}
	TestDrive    = @{
		Enabled = $false
	}
	TestRegistry = @{
		Enabled = $false
	}
}
$result = Invoke-Pester -Configuration $pConf

# Return script result
if ($PassThru) {
	return $result
}
