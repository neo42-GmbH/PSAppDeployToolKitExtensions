Describe "Get-NxtRunningProcesses" {
    Context "When running processes are present" {
        BeforeAll {
            [System.Diagnostics.Process]$childProcess = Start-Process -FilePath ./test/simple.exe -PassThru
            [System.Diagnostics.Process]$lsassProcess = Get-Process -Name lsass
        }
        AfterAll {
            $childProcess.Kill()
        }
        It "Returns the list of found processes" {
            [array]$processes = @(
                @{
                    ProcessName = $childProcess.Name
                }
                @{
                    ProcessName = $lsassProcess.Name
                }
            )
            $result = Get-NxtRunningProcesses -ProcessObjects $processes
            $result.GetType().BaseType.Name | Should -Be 'Array'
            $result.ProcessName | Should -Contain $childProcess.Name
            $result.ProcessName | Should -Contain $lsassProcess.Name
            $result.Count | Should -Be 2
        }
        It "Should return only the running processes" {
            [array]$processes = @(
                @{
                    ProcessName = $childProcess.Name
                },
                @{
                    ProcessName = "invalid"
                }
            )
            $result = Get-NxtRunningProcesses -ProcessObjects $processes
            $result.GetType().Name | Should -Be 'Process'
            $result.ProcessName | Should -Be $childProcess.Name
        }
        It "Should return empty array if no running processes are found" {
            [array]$processes = @(
                @{
                    ProcessName = "invalid"
                }
            )
            $result = Get-NxtRunningProcesses -ProcessObjects $processes
            $result | Should -BeNullOrEmpty
        }
    }
}
