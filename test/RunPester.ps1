Import-Module Pester
[PesterConfiguration]$config = [PesterConfiguration]::Default
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = "$PSScriptRoot\testresults.xml"
$config.TestResult.OutputFormat = 'NUnitXml'
Import-Module $PSScriptRoot\shared.psm1
cd $PSScriptRoot
Invoke-Pester -Configuration $config
