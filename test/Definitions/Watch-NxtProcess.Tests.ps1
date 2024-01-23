Describe "Watch-NxtProcess" {
    Context "When running the function" {
        BeforeAll {
            [System.Diagnostics.Process]$process = [System.Diagnostics.Process]::GetCurrentProcess()
            function Start-TestProcess {
                return Start-Job -ScriptBlock { Start-Sleep -Seconds 2; $proc = Start-Process -FilePath $args[0] -PassThru; Start-Sleep 2; Stop-Process  $proc } -ArgumentList "$PWD\test\simple.exe"
            }
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
            Start-TestProcess | Out-Null
            $result = Watch-NxtProcess -ProcessName "simple.exe" -Timeout 10
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
