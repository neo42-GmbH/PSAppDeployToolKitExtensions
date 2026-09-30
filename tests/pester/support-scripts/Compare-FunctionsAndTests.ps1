param(
	[ValidateScript({ $_.Exists })]
	[System.IO.DirectoryInfo]
	$FunctionsDirectory = "$PSScriptRoot\..\..\..\src\modules\Neo42.Extensions\functions\public",
	[ValidateScript({ $_.Exists })]
	[System.IO.DirectoryInfo]
	$TestsDirectory = "$PSScriptRoot\..\function-tests",
	[System.Management.Automation.SwitchParameter]
	$CreateTests,
	[System.Management.Automation.SwitchParameter]
	$ListEmptyTests
)

# Options
[System.String]$prepScriptPath = '$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1'
[System.String]$defaultTestContent = @'
BeforeDiscovery { . "PREPARATIONSCRIPTPATH" }

Describe 'FUNCTIONNAME' {
	BeforeAll {

	}

	AfterAll {

	}

	Context 'When using ...' {
		It 'Should be ...' {

		}
	}
}
'@.Replace('PREPARATIONSCRIPTPATH', $prepScriptPath)

# Functions
function Convert-TitleString {
	<#
	.SYNOPSIS
    Fill a string with whitespace to create column-like indentation
	#>
    param(
        [System.String]$TitleString
    )
	[System.Int32]$dest = 40
	[System.Int32]$diff = $dest - $TitleString.Length
	if ($diff -gt 0) { return "$($TitleString)$(' '*$diff)" }
	return $TitleString
}

# Preparation
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

try {
	[System.IO.FileInfo[]]$functionFiles = Get-ChildItem -Path $FunctionsDirectory -Recurse -File -Include '*.ps1'
	[System.IO.FileInfo[]]$testFiles = Get-ChildItem -Path $TestsDirectory -Recurse -File -Include '*.Tests.ps1'
	[System.Collections.Generic.List[System.String]]$missingTestFiles = [System.Collections.Generic.List[System.String]]::new()
	foreach ($functionFile in $functionFiles) {
		[System.Boolean]$found = $false
		foreach ($testFile in $testFiles) {
			if ($functionFile.Name.Replace('.ps1', '') -eq $testFile.Name.Replace('.Tests.ps1', '')) {
				$found = $true
                break
			}
		}
		if (-not $found) {
			$missingTestFiles.Add($functionFile.Name.Replace('.ps1', '.Tests.ps1'))
		}
	}
	[System.Collections.Generic.List[System.String]]$missingFunctionFiles = [System.Collections.Generic.List[System.String]]::new()
	foreach ($testFile in $testFiles) {
		[System.Boolean]$found = $false
		foreach ($functionFile in $functionFiles) {
			if ($testFile.Name.Replace('.Tests.ps1', '') -eq $functionFile.Name.Replace('.ps1', '')) {
				$found = $true
                break
			}
		}
		if (-not $found) {
			$missingFunctionFiles.Add($testFile.Name.Replace('.Tests.ps1', '.ps1'))
		}
	}
	Write-Output "Missing test files:$($missingTestFiles | ForEach-Object -Process { "`n    $_" })"
	Write-Output ''
	Write-Output "Missing function files:$($missingFunctionFiles | ForEach-Object -Process { "`n    $_" })"
	if ($CreateTests) {
		Write-Output ''
        Write-Output 'Test file creation:'
		foreach ($file in $missingTestFiles) {
			[System.String]$newTestFilePath = [System.IO.Path]::Combine($TestsDirectory, $file)
			$defaultTestContent.Replace('FUNCTIONNAME', $file.Replace('.Tests.ps1', '')) | Out-File -FilePath $newTestFilePath -Encoding utf8
			Write-Output "$(Convert-TitleString -TitleString $file) : File created."
		}
	}
	if ($ListEmptyTests) {
        $testFiles = Get-ChildItem -Path $TestsDirectory -Recurse -File -Include '*.Tests.ps1'
	    [System.Collections.Generic.List[System.String]]$defaultTestFiles = [System.Collections.Generic.List[System.String]]::new()
		foreach ($file in $testFiles) {
			[System.String]$fileContent = Get-Content -Path $file.FullName -Raw
            [System.String]$defaultContent = $defaultTestContent.Replace('FUNCTIONNAME', $file.Name.Replace('.Tests.ps1', ''))
            if ($fileContent.Trim() -eq $defaultContent.Trim()) {
                $defaultTestFiles.Add("$(Convert-TitleString -TitleString $file.Name) ($($file.Length) bytes)")
            }
		}
		Write-Output ''
        Write-Output "Tests files with default content:$($defaultTestFiles | ForEach-Object -Process { "`n    $_" })"
	}
}
catch {
	Write-Output ($_ | Out-String).Trim()
}
