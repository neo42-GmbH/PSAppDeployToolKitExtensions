Describe "Get-NxtProcessName" {
    Context "When given a process ID" {
        BeforeAll {
            [System.Diagnostics.Process]$process = [System.Diagnostics.Process]::GetCurrentProcess()
        }
        It "Should return the correct process name for a valid id" {
            $result = Get-NxtProcessName -ProcessId $process.Id
            $result | Should -BeOfType 'System.String'
            $result | Should -Be $process.ProcessName
        }
        It "Should return an empty string if process not found" {
            $result = Get-NxtProcessName -ProcessId 999999
            $result | Should -BeOfType 'System.String'
            $result | Should -Be ''
        }
    }
}
