Describe "Get-NxtSystemEnvironmentVariable" {
    Context "When querying for a system environment variable" {
        It "Should return the value of an existing environment variable" {
            $result = Get-NxtSystemEnvironmentVariable -Key "Path"
            $result | Should -BeOfType 'System.String'
            $result | Should -Not -BeNullOrEmpty
        }
        It "Should ignore changes to the process environment" {
            $env:Path = $env:Path + ";C:\Test"
            Get-NxtSystemEnvironmentVariable -Key "Path" | Should -Not -Contain "C:\Test"
        }
        It "Should return null for a non-existing environment variable" {
            Get-NxtSystemEnvironmentVariable -Key "NonExisting" | Should -BeNullOrEmpty
        }
    }
}
