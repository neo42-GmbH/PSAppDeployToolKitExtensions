Describe "Test-NxtProcessExists" {
    Context "When function is called" {
        BeforeAll {
            [System.Diagnostics.Process]$process = Start-Process "cmd.exe" -PassThru
        }
        AfterAll {
            if (-not $process.HasExited) {
                $process.Kill()
            }
        }
        It "Should return true if process exists" {
            $result = Test-NxtProcessExists -ProcessName $process.MainModule.ModuleName
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
        }
        It "Should return true when using WQL on existing process" {
            $result = Test-NxtProcessExists -ProcessName "Name LIKE '$($process.MainModule.ModuleName)'" -IsWql
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
        }
        It "Should fail when WQL is invalid" -Skip {
            $result = Test-NxtProcessExists -ProcessName "invalid" -IsWql
            $result | Should -BeOfType 'bool'
            $result | Should -Be $false
        }
        It "Should return false when process does not exsit" {
            $result = Test-NxtProcessExists -ProcessName "invalid"
            $result | Should -BeOfType 'bool'
            $result | Should -Be $false
        }
    }
}
