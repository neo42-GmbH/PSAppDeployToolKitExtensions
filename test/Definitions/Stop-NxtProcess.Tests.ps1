Describe "Stop-NxtProcess" {
    Context "When given a running process" {
        BeforeEach {
            $process = Start-Process -FilePath simple.exe -PassThru
        }
        AfterEach {
            if (Get-Process -Id $process.Id -ErrorAction SilentlyContinue){
                $process.Kill()
            }
        }
        It "Should stop the process by name" {
            Stop-NxtProcess -Name $process.Name | Should -BeNullOrEmpty
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
    }
    Context "When the process is not running"{
        It "Should fail to kill a nonexistant process" {
            Stop-NxtProcess -Name "NonexistantProcess" | Should -BeNullOrEmpty
        }
    }
}
