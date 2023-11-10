Describe 'Remove-NxtSystemEnvironmentVariable' {
    Context 'When removing a system environment variable' {
        BeforeEach {
            [System.Environment]::SetEnvironmentVariable('TestVariable','TestValue','Machine')
            $env:TestVariable = "TestValue"
        }
        It 'Removes the variable successfully' {
            Remove-NxtSystemEnvironmentVariable -Key "TestVariable" | Should -BeNullOrEmpty
            [System.Environment]::GetEnvironmentVariable('TestVariable', 'Machine') | Should -BeNullOrEmpty
        }
        It 'Should not affect the process environment variables' {
            Remove-NxtSystemEnvironmentVariable -Key "TestVariable" | Should -BeNullOrEmpty
            $env:TestVariable | Should -Be "TestValue"
        }
        It 'Should do nothing if the environment variable does not exist' {
            Remove-NxtSystemEnvironmentVariable -Key "TestVariable2" | Should -BeNullOrEmpty
        }
    }
}
