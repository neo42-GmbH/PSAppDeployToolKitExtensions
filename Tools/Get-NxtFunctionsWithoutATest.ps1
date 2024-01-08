<#
    .SYNOPSIS
        This script returns a list of functions without a unit test.
    .NOTES
        # LICENSE #
        This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
        You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

        # COPYRIGHT #
        Copyright (c) 2024 neo42 GmbH, Germany.
    .EXAMPLE
        .\Tools\Get-NxtFunctionsWithoutATest.ps1
#>
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