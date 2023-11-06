## comment main in Deploy-Application.ps1 and run this script to get a list of functions without a test
# .\Tools\Get-NxtFunctionsWithoutATest.ps1
function Get-NxtFunctionTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TestDefinitionFolder = ".\test\Definitions",
        [Parameter(Mandatory = $false)]
        [string]$TestFileNameExtension = ".Tests.ps1",
        [Parameter(Mandatory = $false)]
        [ValidateSet("ShowAll", "ShowOnlyMissing", "ShowOnlyExisting")]
        [string]$Mode = "ShowAll",
        [Parameter(Mandatory = $false)]
        [switch]$BaseFunctionsOnly
    )
    [psobject]$nxtFunctions = Get-Command -Name "*-Nxt*"
    [psobject]$tests = Get-ChildItem -Path $TestDefinitionFolder -Filter "*$TestFileNameExtension" | Select-Object -ExpandProperty Name | ForEach-Object {
        $_ -replace $TestFileNameExtension, ""
    }
    $(foreach ($nxtFunction in $nxtFunctions) {
        [PSCustomObject]$obj = [PSCustomObject]@{
            Name = $nxtFunction.Name
            Test = $false
            BaseFunction = $false
        }
        if ($tests -contains $nxtFunction.Name) {
            $obj.Test = $true
        }
        $pattern = '=\s*\$global:PackageConfig'
        $patternExists = ($nxtFunction.ScriptBlock.ToString()) -match $pattern
        $obj.BaseFunction = -not $patternExists
        $obj
    }) | Where-Object {
        if ($BaseFunctionsOnly) {
            $_.BaseFunction
        } else {
            $true
        }
    } | Where-Object {
        if ($Mode -eq "ShowOnlyMissing") {
            -not $_.Test
        } elseif ($Mode -eq "ShowOnlyExisting") {
            $_.Test
        } else {
            $true
        }
    }
}
Get-NxtFunctionTests -Mode ShowOnlyMissing -BaseFunctionsOnly