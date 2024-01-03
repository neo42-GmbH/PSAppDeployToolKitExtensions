<#
    .SYNOPSIS
        Starts pester with our configuration
    .NOTES
        # LICENSE #
        This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
        You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

        # COPYRIGHT #
        Copyright (c) 2023 neo42 GmbH, Germany.
#>

#requires -module Pester -version 5
Import-Module Pester

# Pester config
[PesterConfiguration]$config = [PesterConfiguration]::Default
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = "$PSScriptRoot\testresults.xml"
$config.TestResult.OutputFormat = 'NUnitXml'
$config.Should.ErrorAction = 'Continue'

# Create process test binary
$compilerPath = [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory() + "csc.exe"
$compilerArgs = "/target:winexe /out:$testWorkFolder\simple.exe $PSScriptRoot\simple.cs"
Start-Process -FilePath $compilerPath -ArgumentList $compilerArgs -Wait

# Import PSADT
[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
. $moduleAppDeployToolkitMain -DisableLogging

# Run Pester
Invoke-Pester -Configuration $config
