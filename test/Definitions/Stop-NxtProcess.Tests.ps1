Describe "Stop-NxtProcess" {
    Context "When given a running process" {
        BeforeEach {
            $process = Start-Process -FilePath cmd.exe -PassThru
        }
        AfterEach {
            if (Get-Process -Id $process.Id -ErrorAction SilentlyContinue){
                $process.Kill()
            }
        }
        It "Should stop the process" {
            Stop-NxtProcess -Name $process.Name | Should -BeNullOrEmpty
            $process.HasExited | Should -Be $true
        }
    }
    Context "When the process is not running"{
        It "Should fail to kill a nonexistant process" {
            Stop-NxtProcess -Name "NonexistantProcess" | Should -BeNullOrEmpty
        }
    }
}
