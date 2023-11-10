Describe 'Set-NxtSystemEnvironmentVariable' {
    Context 'When setting a new environment variable' {
        AfterEach {
            [System.Environment]::SetEnvironmentVariable('TestVariable', $null, 'Machine')
        }
        It 'Should create the variable with the correct value' {
            Set-NxtSystemEnvironmentVariable -Key 'TestVariable' -Value 'Test' | Should -BeNullOrEmpty
            [System.Environment]::GetEnvironmentVariable('TestVariable','Machine') | Should -Be 'Test'
        }
        It 'Should update an existing variable value' {
            [System.Environment]::SetEnvironmentVariable('TestVariable', 'Test', 'Machine')
            Set-NxtSystemEnvironmentVariable -Key 'TestVariable' -Value 'Test2' | Should -BeNullOrEmpty
            [System.Environment]::GetEnvironmentVariable('TestVariable','Machine') | Should -Be 'Test2'
        }
        It 'Should not update process variables' {
            Set-NxtSystemEnvironmentVariable -Key 'TestVariable' -Value 'Test' | Should -BeNullOrEmpty
            $env:TestVariable | Should -BeNullOrEmpty
        }
    }
}
