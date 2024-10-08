Describe 'Get-NxtProcessEnvironmentVariable' {
    Context 'When asking for an evironment variable' {
        BeforeAll {
            $env:testVar = 'test'
        }
        It 'Should return the value of an existing environment variable' {
            $result = Get-NxtProcessEnvironmentVariable -Key 'testVar'
            $result | Should -BeOfType 'System.String'
            $result | Should -Be 'test'
        }
        It 'Should fail when the variable does not exist'{
            Get-NxtProcessEnvironmentVariable -Key 'invalid' | Should -BeNullOrEmpty
        }
    }

}
