Describe "Remove-NxtEmptyIniFile" {
    Context "When the function is called" {
        BeforeAll{
            [string]$file = "$PSScriptRoot\TestIniFile.ini"
        }
        AfterEach{
            if (Test-Path $file) {
                Remove-Item $file -Force | Out-Null
            }
        }
        It "Should delete an empty ini file" {
            New-Item $file -ItemType File | Out-Null
            Remove-NxtEmptyIniFile -Path $file | Should -BeNullOrEmpty
            Test-Path $file | Should -Be $false
        }
        It "Should delete an ini file with no keys" {
            New-Item $file -ItemType File | Out-Null
            Add-Content $file "[default]" | Out-Null
            Remove-NxtEmptyIniFile -Path $file | Should -BeNullOrEmpty
            Test-Path $file | Should -Be $false
        }
        It "Should not delete an ini file with keys" {
            New-Item $file -ItemType File | Out-Null
            Add-Content $file "[default]`nkey=value" | Out-Null
            Add-Content $file "key=value" | Out-Null
            Remove-NxtEmptyIniFile -Path $file | Should -BeNullOrEmpty
            Test-Path $file | Should -Be $true
        }
        It "Should not delete an ini file with comments" {
            New-Item $file -ItemType File | Out-Null
            Add-Content $file "#comment" | Out-Null
            Add-Content $file "[default]`nkey=value" | Out-Null
            Remove-NxtEmptyIniFile -Path $file | Should -BeNullOrEmpty
            Test-Path $file | Should -Be $true
        }
        It "Should do nothing if the file does not exist" {
            Remove-NxtEmptyIniFile -Path $file | Should -BeNullOrEmpty
            Test-Path $file | Should -Be $false
        }
    }
}
