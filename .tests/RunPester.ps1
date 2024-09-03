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

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
Param (
	[System.IO.FileInfo]
	$ToolkitMain = (Get-ChildItem -Recurse -Filter 'AppDeployToolkitMain.ps1' | Select-Object -First 1)
)

Import-Module Pester

# Pester config
[PesterConfiguration]$config = [PesterConfiguration]::Default
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = "$PSScriptRoot\testresults.xml"
$config.TestResult.OutputFormat = 'NUnitXml'
$config.Run.Path = "$PSScriptRoot\Definitions"
$config.Should.ErrorAction = 'Continue'
$config.Output.StackTraceVerbosity = 'None'
$config.Output.Verbosity = 'Detailed'

# Create process test binary
[string]$global:simpleExe = "$PSScriptRoot\simple.exe"
$compilerPath = [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory() + "csc.exe"
$compilerArgs = "/target:winexe /out:$global:simpleExe $PSScriptRoot\simple.cs"
Start-Process -FilePath $compilerPath -ArgumentList $compilerArgs -Wait -NoNewWindow

# Mute Toolkit logging
(Get-Content "$($ToolkitMain.Directory.FullName)\AppDeployToolkitConfig.xml" -Raw).Replace('<Toolkit_LogWriteToHost>true</Toolkit_LogWriteToHost>', '<Toolkit_LogWriteToHost>false</Toolkit_LogWriteToHost>') |
	Out-File "$($ToolkitMain.Directory.FullName)\AppDeployToolkitConfig.xml"

# Import PSADT
[string]$global:PSADTPath = $ToolkitMain.Directory.Parent.FullName
Write-Host "Importing AppDeployToolkitMain.ps1 from [$($ToolkitMain.FullName)]"
. $ToolkitMain.FullName -DisableLogging

# Run Pester
Invoke-Pester -Configuration $config
