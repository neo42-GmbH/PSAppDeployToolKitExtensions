<#
    .SYNOPSIS
        Starts pester with our configuration
    .NOTES
        # LICENSE #
        This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
        You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

        # COPYRIGHT #
        Copyright (c) 2024 neo42 GmbH, Germany.
#>

#requires -module Pester -version 5
Import-Module Pester

# Pester config
[PesterConfiguration]$config = [PesterConfiguration]::Default
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = "$PSScriptRoot\testresults.xml"
$config.TestResult.OutputFormat = 'NUnitXml'
$config.Should.ErrorAction = 'Continue'
$config.Output.Verbosity = 'Detailed'

# Set location
[FileInfo]$toolkitMain = Get-ChildItem -Path .. -Recurse -Filter "AppDeployToolkitMain.ps1" | Select-Object -First 1
Set-Location $toolkitMain.Directory.Parent.FullName

# Create process test binary
$compilerPath = [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory() + "csc.exe"
$compilerArgs = "/target:winexe /out:$PSScriptRoot\simple.exe $PSScriptRoot\simple.cs"
Start-Process -FilePath $compilerPath -ArgumentList $compilerArgs -Wait

# Mute Toolkit logging
(Get-Content "$($toolkitMain.Directory.FullName)\AppDeployToolkitConfig.xml" -Raw).Replace('<Toolkit_LogWriteToHost>True</Toolkit_LogWriteToHost>', '<Toolkit_LogWriteToHost>False</Toolkit_LogWriteToHost>') | 
    Out-File "$($toolkitMain.Directory.FullName)\AppDeployToolkitConfig.xml"

# Import PSADT
. $toolkitMain.FullName -DisableLogging

# Run Pester
Invoke-Pester -Configuration $config
