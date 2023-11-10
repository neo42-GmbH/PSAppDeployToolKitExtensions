Describe "Watch-NxtProcess" {
    Context "When running the function" {
        BeforeAll {
            [System.Diagnostics.Process]$process = [System.Diagnostics.Process]::GetCurrentProcess()
        }
        It "Should return true if process exists" {
            $result = Watch-NxtProcess -ProcessName "$($process.MainModule.ModuleName)" -Timeout 1
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
        }
        It "Should return false within timeout when process is not running" {
            [datetime]$start = Get-Date
            $result = Watch-NxtProcess -ProcessName "NonExistentProcess" -Timeout 1
            $result | Should -BeOfType 'bool'
            $result | Should -Be $false
            [Math]::Floor(((Get-Date) - $start).TotalSeconds) | Should -BeLessOrEqual 2
        }
        It "Should return true if process is started later" {
            [datetime]$start = Get-Date
            [System.Management.Automation.Job]$job = Start-Job -ScriptBlock { Start-Sleep -Seconds 2; $proc = Start-Process -FilePath "cmd" -PassThru; Start-Sleep 2; Stop-Process  $proc } | Out-Null
            $result = Watch-NxtProcess -ProcessName "cmd.exe" -Timeout 10
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
            [Math]::Floor(((Get-Date) - $start).TotalSeconds) | Should -BeLessOrEqual 9
        }
        It "Should return true if WQL is used" {
            $result = Watch-NxtProcess -ProcessName "Name LIKE '$($process.MainModule.ModuleName)'" -Timeout 1 -IsWql
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
        }
        It "Should throw when WQL is invalid" {
            { Watch-NxtProcess -ProcessName "INVALID" -Timeout 1 -IsWql } | Should -Throw
        }
    }
}
