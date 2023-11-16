<#
    .SYNOPSIS
        Start pester with our configuration for Github Actions
    .NOTES
        # LICENSE #
        This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
        You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

        # COPYRIGHT #
        Copyright (c) 2023 neo42 GmbH, Germany.
#>

#requires -module Pester -version 5
##Install-Module pester -SkipPublisherCheck -force
Import-Module Pester
[PesterConfiguration]$config = [PesterConfiguration]::Default
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = "$PSScriptRoot\testresults.xml"
$config.TestResult.OutputFormat = 'NUnitXml'
Import-Module $PSScriptRoot\shared.psm1
Set-Location $PSScriptRoot
Invoke-Pester -Configuration $config
