Describe "Watch-NxtProcessIsStopped" {
    Context "When running the function" {
        BeforeAll {
            [System.Diagnostics.Process]$process = [System.Diagnostics.Process]::GetCurrentProcess()
            function New-TestProcess {
                return Start-Job -ScriptBlock { $proc = Start-Process -FilePath $args[0] -PassThru; Start-Sleep 2; Stop-Process  $proc } -ArgumentList "$global:simpleExe"
            }
        }
        It "Should return true if process does not exists" {
            $result = Watch-NxtProcessIsStopped -ProcessName "NonExistantProcess" -Timeout 1
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
        }
        It "Should return false within timeout when process is running" {
            [datetime]$start = Get-Date
            $result = Watch-NxtProcessIsStopped -ProcessName "$($process.MainModule.ModuleName)" -Timeout 1
            $result | Should -BeOfType 'bool'
            $result | Should -Be $false
            [Math]::Floor(((Get-Date) - $start).TotalSeconds) | Should -BeLessOrEqual 2
        }
        It "Should return true if process is started later" {
            [System.Management.Automation.Job]$job = New-TestProcess
            $start = Get-Date
            $result = Watch-NxtProcessIsStopped -ProcessName "simple.exe" -Timeout 10
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
            [Math]::Floor(((Get-Date) - $start).TotalSeconds) | Should -BeLessOrEqual 9
            $job | Wait-Job
        }
        It "Should return true if WQL is used" {
            [System.Management.Automation.Job]$job = New-TestProcess
            $result = Watch-NxtProcessIsStopped -ProcessName "Name LIKE 'simple.exe'" -Timeout 1 -IsWql
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
            $job | Wait-Job
        }
        It "Should throw when WQL is invalid" {
            { Watch-NxtProcessIsStopped -ProcessName "INVALID" -Timeout 1 -IsWql } | Should -Throw
        }
    }
}
