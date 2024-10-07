Describe "Get-NxtServiceState" {
    Context "When running against a single service" {
        BeforeAll {
            [System.ServiceProcess.ServiceController]$runningProcess = (Get-Service | Where-Object {$_.Status -eq 'Running'})[0]
            [System.ServiceProcess.ServiceController]$stoppedProcess = (Get-Service | Where-Object {$_.Status -eq 'Stopped'})[0]
        }
        It "Should return the correct service state for a running service" {
            $result = Get-NxtServiceState -ServiceName $runningProcess.Name
            $result | Should -BeOfType 'System.String'
            $result | Should -Be 'Running'
        }
        It "Should return the correct service state for a stopped service" {
            Get-NxtServiceState -ServiceName $stoppedProcess.Name | Should -Be 'Stopped'
        }
        It "Should be empty for non-existent service" {
            Get-NxtServiceState -ServiceName "invalid" | Should -BeNullOrEmpty
        }
    }
}
