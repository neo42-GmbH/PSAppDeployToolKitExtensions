Describe "Stop-NxtProcess" {
    Context "When given a running process" {
        BeforeEach {
            $process = Start-Process -FilePath $global:simpleExe -PassThru
        }
        AfterEach {
            if ($process.HasExited -eq $false) {
                $process.Kill()
            }
        }
        It "Should stop the process by name" {
            Stop-NxtProcess -Name $process.Name | Should -BeNullOrEmpty
            $process.HasExited | Should -Be $true
        }
        It "Should stop even if .exe extension is specified" {
            Stop-NxtProcess -Name "$($process.Name).exe" | Should -BeNullOrEmpty
            $process.HasExited | Should -Be $true
        }
        It "Should stop the process by WQL Query" {
            Stop-NxtProcess -Name "Name = '$($process.Name).exe'" -IsWql $true | Should -BeNullOrEmpty
            $process.HasExited | Should -Be $true
        }
        It "Should not stop the Process if the WQL Query does not match" {
            Stop-NxtProcess -Name "Name = 'NonexistantProcess'" -IsWql $true | Should -BeNullOrEmpty
            $process.HasExited | Should -Be $false
        }
        It "Should stop the process by ID" {
            Stop-NxtProcess -Id $process.Id | Should -BeNullOrEmpty
            $process.HasExited | Should -Be $true
        }
    }
    Context "When the process is not running"{
        It "Should fail to kill a nonexistant process" {
            Stop-NxtProcess -Name "NonexistantProcess" | Should -BeNullOrEmpty
        }
    }
}
