Describe "Remove-NxtEmptyRegistryKey" {
    Context "When the function is called" {
        BeforeAll{
            [string]$baseKey = "HKLM:\SOFTWARE\neo42\PesterTests"
        }
        BeforeEach {
            New-Item $baseKey -Force | Out-Null
        }
        AfterEach{
            if (Test-Path $baseKey) {
                Remove-Item $baseKey -Force -Recurse | Out-Null
            }
        }
        It "Should delete an empty registry key" {
            Remove-NxtEmptyRegistryKey -Path $baseKey | Should -BeNullOrEmpty
            Test-Path $baseKey | Should -Be $false
        }
        It "Should not delete a key if it has subkeys" {
            New-Item "$baseKey\test" -Force | Out-Null
            Remove-NxtEmptyFolder -Path $baseKey | Should -BeNullOrEmpty
            Test-Path $baseKey | Should -Be $true
        }
        It "Should not delete if key has properties" {
            New-ItemProperty -Path $baseKey -Name "Test" -Value "Test" | Out-Null
            Remove-NxtEmptyRegistryKey -Path "$baseKey" | Should -BeNullOrEmpty
            Test-Path $baseKey | Should -Be $true
        }
        It "Should do nothing if path does not exist" {
            Remove-NxtEmptyRegistryKey -Path "INVALID" | Should -BeNullOrEmpty
        }
        It "Should replace the hive names with their respecitive address" {
            Remove-NxtEmptyRegistryKey -Path ($baseKey -replace "HKLM:", "HKEY_LOCAL_MACHINE") | Should -BeNullOrEmpty
            Test-Path $baseKey | Should -Be $false
        }
        It "Should mount hives that are not by default" {
            Remove-NxtEmptyRegistryKey -Path "HKEY_CLASSES_ROOT\*" | Should -BeNullOrEmpty
        }
    }
}
