Describe "Set-NxtProcessEnvironmentVariable" {
    Context "When setting a new environment variable" {
        AfterEach{
            Remove-Item env:\TestVariable -ErrorAction SilentlyContinue
        }
        It "Should add the variable to the process environment" {
            Set-NxtProcessEnvironmentVariable -Key "TestVariable" -Value "Test" | Should -BeNullOrEmpty
            $env:TestVariable | Should -Be "Test"
        }
        It "Should alter existing variables" {
            $env:TestVairable = "Test"
            Set-NxtProcessEnvironmentVariable -Key "TestVariable" -Value "Test2" | Should -BeNullOrEmpty
            $env:TestVariable | Should -Be "Test2"
        }
        It "Should not alter system environment variables" {
            Set-NxtProcessEnvironmentVariable -Key "TestVariable" -Value "Test" | Should -BeNullOrEmpty
            [System.Environment]::GetEnvironmentVariable("TestVariable",'Machine') | Should -BeNullOrEmpty
        }
    }
}
