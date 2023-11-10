Describe "Remove-NxtProcessEnvironmentVariable" {
    Context "When removing a process environment variable" {
        It "Should remove the specified environment variable" {
            $env:TestVariable = "TestValue"
            Remove-NxtProcessEnvironmentVariable -Key "TestVariable" | Should -BeNullOrEmpty
            $env:TestVariable | Should -BeNullOrEmpty
        }
        It "Should do nothing if the environment variable does not exist" {
            Remove-NxtProcessEnvironmentVariable -Key "TestVariable2" | Should -BeNullOrEmpty
        }
    }
}
