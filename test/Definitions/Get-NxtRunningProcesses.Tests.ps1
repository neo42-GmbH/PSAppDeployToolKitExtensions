Describe "Get-NxtRunningProcesses" {
    Context "When running processes are present" {
        BeforeAll {
            [System.Diagnostics.Process]$selfProcess = [System.Diagnostics.Process]::GetCurrentProcess()
            [System.Diagnostics.Process]$lsassProcess = (Get-Process | Where-Object { $_.ProcessName -eq "lsass" })[0]
        }
        It "Returns the list of found processes" {
            $processes = [array]@(
                @{
                    ProcessName = $selfProcess.Name
                },
                @{
                    ProcessName = $lsassProcess.Name
                }
            )
            $result = Get-NxtRunningProcesses -ProcessObjects $processes
            $result.GetType().BaseType.Name | Should -Be 'Array'
            $result.ProcessName | Should -Contain $selfProcess.Name
            $result.ProcessName | Should -Contain $lsassProcess.Name
        }
        It "Should return only the running processes" -Skip {
            $processes = [array]@(
                @{
                    ProcessName = $lsassProcess.Name
                },
                @{
                    ProcessName = "invalid"
                }
            )
            $result = Get-NxtRunningProcesses -ProcessObjects $processes
            $result.GetType().BaseType.Name | Should -Be 'Array'
            $result.ProcessName | Should -NotContain $selfProcess.Name
            $result.ProcessName | Should -Contain $lsassProcess.Name
        }
        It "Should return empty array if no running processes are found" {
            $processes = [array]@(
                @{
                    ProcessName = "invalid"
                }
            )
            $result = Get-NxtRunningProcesses -ProcessObjects $processes
            $result | Should -BeNullOrEmpty
        }
    }
}
