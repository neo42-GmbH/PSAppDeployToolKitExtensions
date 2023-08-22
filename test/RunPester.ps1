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
