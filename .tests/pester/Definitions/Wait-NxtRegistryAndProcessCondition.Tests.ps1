# Test the Wait-NxtRegistryAndProcessCondition Function
Describe "Wait-NxtRegistryAndProcessCondition" {
    Context "Only Registry Key Conditions" {
        It "Returns true if the Registry key does not exist according to the conditions provided" {
            $object = @"
{
    "TotalSecondsToWaitFor": 1,
    "ProcessOperator": "And",
    "ProcessesToWaitFor": [],
    "RegKeyOperator": "And",
    "RegKeysToWaitFor": [
        {
        "KeyPath": "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub1",
        "ValueName": null,
        "ValueData": null,
        "ShouldExist": false
        }
    ]
}
"@|ConvertFrom-Json
            New-Item -Path "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub1" -Force
            [bool]$result = Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor $object.TotalSecondsToWaitFor -ProcessOperator $object.ProcessOperator -ProcessesToWaitFor $object.ProcessesToWaitFor -RegKeyOperator $object.RegKeyOperator -RegKeysToWaitFor $object.RegKeysToWaitFor
            $result | Should -BeFalse
            Remove-Item -Path "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub1" -Force
            [bool]$result = Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor $object.TotalSecondsToWaitFor -ProcessOperator $object.ProcessOperator -ProcessesToWaitFor $object.ProcessesToWaitFor -RegKeyOperator $object.RegKeyOperator -RegKeysToWaitFor $object.RegKeysToWaitFor
            $result | Should -BeTrue
        }
        It "Returns true if the Registry key exists according to the conditions provided" {
            $object = @"
{
    "TotalSecondsToWaitFor": 1,
    "ProcessOperator": "And",
    "ProcessesToWaitFor": [],
    "RegKeyOperator": "And",
    "RegKeysToWaitFor": [
        {
        "KeyPath": "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub2",
        "ValueName": null,
        "ValueData": null,
        "ShouldExist": true
        }
    ]
    }
"@|ConvertFrom-Json
            New-Item -Path "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub2" -Force
            [bool]$result = Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor $object.TotalSecondsToWaitFor -ProcessOperator $object.ProcessOperator -ProcessesToWaitFor $object.ProcessesToWaitFor -RegKeyOperator $object.RegKeyOperator -RegKeysToWaitFor $object.RegKeysToWaitFor
            $result | Should -BeTrue
            Remove-Item -Path "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub2" -Force
            [bool]$result = Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor $object.TotalSecondsToWaitFor -ProcessOperator $object.ProcessOperator -ProcessesToWaitFor $object.ProcessesToWaitFor -RegKeyOperator $object.RegKeyOperator -RegKeysToWaitFor $object.RegKeysToWaitFor
            $result | Should -BeFalse
        }
        It "Returns true if the Registry key exists and the value is correct according to the conditions provided" {
            $object = @"
{
    "TotalSecondsToWaitFor": 1,
    "ProcessOperator": "And",
    "ProcessesToWaitFor": [],
    "RegKeyOperator": "And",
    "RegKeysToWaitFor": [
        {
        "KeyPath": "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub3",
        "ValueName": "ValueName",
        "ValueData": null,
        "ShouldExist": true
        }
    ]
    }
"@|ConvertFrom-Json
            New-Item -Path "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub3" -Force
            New-ItemProperty -Path "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub3" -Name "ValueName" -Value "ValueData" -Force
            [bool]$result = Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor $object.TotalSecondsToWaitFor -ProcessOperator $object.ProcessOperator -ProcessesToWaitFor $object.ProcessesToWaitFor -RegKeyOperator $object.RegKeyOperator -RegKeysToWaitFor $object.RegKeysToWaitFor
            $result | Should -BeTrue
            Set-ItemProperty -Path "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub3" -Name "ValueName" -Value "" -Force
            [bool]$result = Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor $object.TotalSecondsToWaitFor -ProcessOperator $object.ProcessOperator -ProcessesToWaitFor $object.ProcessesToWaitFor -RegKeyOperator $object.RegKeyOperator -RegKeysToWaitFor $object.RegKeysToWaitFor
            $result | Should -BeTrue
            Remove-Item -Path "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub3" -Force
            [bool]$result = Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor $object.TotalSecondsToWaitFor -ProcessOperator $object.ProcessOperator -ProcessesToWaitFor $object.ProcessesToWaitFor -RegKeyOperator $object.RegKeyOperator -RegKeysToWaitFor $object.RegKeysToWaitFor
            $result | Should -BeFalse
        }
        It "Returns true if the Registry key exists and the value is correct according to the conditions provided" {
            $object = @"
{
    "TotalSecondsToWaitFor": 1,
    "ProcessOperator": "And",
    "ProcessesToWaitFor": [],
    "RegKeyOperator": "And",
    "RegKeysToWaitFor": [
        {
        "KeyPath": "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub4",
        "ValueName": "ValueName",
        "ValueData": "ValueData",
        "ShouldExist": true
        }
    ]
}
"@|ConvertFrom-Json
            New-Item -Path "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub4" -Force
            New-ItemProperty -Path "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub4" -Name "ValueName" -Value "ValueData" -Force
            [bool]$result = Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor $object.TotalSecondsToWaitFor -ProcessOperator $object.ProcessOperator -ProcessesToWaitFor $object.ProcessesToWaitFor -RegKeyOperator $object.RegKeyOperator -RegKeysToWaitFor $object.RegKeysToWaitFor
            $result | Should -BeTrue
            Set-ItemProperty -Path "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub4" -Name "ValueName" -Value "" -Force
            [bool]$result = Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor $object.TotalSecondsToWaitFor -ProcessOperator $object.ProcessOperator -ProcessesToWaitFor $object.ProcessesToWaitFor -RegKeyOperator $object.RegKeyOperator -RegKeysToWaitFor $object.RegKeysToWaitFor
            $result | Should -BeFalse
            Remove-Item -Path "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub4" -Force
            [bool]$result = Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor $object.TotalSecondsToWaitFor -ProcessOperator $object.ProcessOperator -ProcessesToWaitFor $object.ProcessesToWaitFor -RegKeyOperator $object.RegKeyOperator -RegKeysToWaitFor $object.RegKeysToWaitFor
            $result | Should -BeFalse
        }
    }
    Context "Only Process Conditions" {
        It "Returns true if the Process does not exist according to the conditions provided" {
            $object = @"
{
    "TotalSecondsToWaitFor": 1,
    "ProcessOperator": "And",
    "ProcessesToWaitFor": [
        {
        "Name": "simple.exe",
        "ShouldExist": false
        }
    ],
    "RegKeyOperator": "And",
    "RegKeysToWaitFor": []
}
"@|ConvertFrom-Json
            [bool]$result = Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor $object.TotalSecondsToWaitFor -ProcessOperator $object.ProcessOperator -ProcessesToWaitFor $object.ProcessesToWaitFor -RegKeyOperator $object.RegKeyOperator -RegKeysToWaitFor $object.RegKeysToWaitFor
            $result | Should -BeTrue
            $process = Start-Process -FilePath ./.tests/pester/simple.exe -PassThru
            [bool]$result = Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor $object.TotalSecondsToWaitFor -ProcessOperator $object.ProcessOperator -ProcessesToWaitFor $object.ProcessesToWaitFor -RegKeyOperator $object.RegKeyOperator -RegKeysToWaitFor $object.RegKeysToWaitFor
            $result | Should -BeFalse
            Stop-Process -Id $process.Id
        }
        It "Returns true if the Process exists according to the conditions provided" {
            $object = @"
{
    "TotalSecondsToWaitFor": 1,
    "ProcessOperator": "And",
    "ProcessesToWaitFor": [
        {
        "Name": "simple.exe",
        "ShouldExist": true
        }
    ],
    "RegKeyOperator": "And",
    "RegKeysToWaitFor": []
    }
"@|ConvertFrom-Json
            [bool]$result = Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor $object.TotalSecondsToWaitFor -ProcessOperator $object.ProcessOperator -ProcessesToWaitFor $object.ProcessesToWaitFor -RegKeyOperator $object.RegKeyOperator -RegKeysToWaitFor $object.RegKeysToWaitFor
            $result | Should -BeFalse
            $process = Start-Process -FilePath ./.tests/pester/simple.exe -PassThru
            [bool]$result = Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor 1 -ProcessOperator $object.ProcessOperator -ProcessesToWaitFor $object.ProcessesToWaitFor -RegKeyOperator $object.RegKeyOperator -RegKeysToWaitFor $object.RegKeysToWaitFor
            $result | Should -BeTrue
            Stop-Process -Id $process.Id
        }
    }
    Context "Registry Key and Process Conditions" {
        It "Returns true if the Registry key does not exist and the Process does not exist according to the conditions provided" {
            $object = @"
{
    "TotalSecondsToWaitFor": 1,
    "ProcessOperator": "And",
    "ProcessesToWaitFor": [
        {
        "Name": "simple.exe",
        "ShouldExist": false
        }
    ],
    "RegKeyOperator": "And",
    "RegKeysToWaitFor": [
        {
        "KeyPath": "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub5",
        "ValueName": null,
        "ValueData": null,
        "ShouldExist": false
        }
    ]
    }
"@|ConvertFrom-Json
            New-Item -Path "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub5" -Force
            [bool]$result = Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor 1 -ProcessOperator $object.ProcessOperator -ProcessesToWaitFor $object.ProcessesToWaitFor -RegKeyOperator $object.RegKeyOperator -RegKeysToWaitFor $object.RegKeysToWaitFor
            $result | Should -BeFalse
            $process = Start-Process -FilePath ./.tests/pester/simple.exe -PassThru
            [bool]$result = Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor 1 -ProcessOperator $object.ProcessOperator -ProcessesToWaitFor $object.ProcessesToWaitFor -RegKeyOperator $object.RegKeyOperator -RegKeysToWaitFor $object.RegKeysToWaitFor
            $result | Should -BeFalse
            Remove-Item -Path "HKLM:\\SOFTWARE\\DeploymentSystem\\Agent\\sub5" -Force
            [bool]$result = Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor 1 -ProcessOperator $object.ProcessOperator -ProcessesToWaitFor $object.ProcessesToWaitFor -RegKeyOperator $object.RegKeyOperator -RegKeysToWaitFor $object.RegKeysToWaitFor
            $result | Should -BeFalse
            Stop-Process -Id $process.Id
            [bool]$result = Wait-NxtRegistryAndProcessCondition -TotalSecondsToWaitFor 1 -ProcessOperator $object.ProcessOperator -ProcessesToWaitFor $object.ProcessesToWaitFor -RegKeyOperator $object.RegKeyOperator -RegKeysToWaitFor $object.RegKeysToWaitFor
            $result | Should -BeTrue
        }
    }
}
