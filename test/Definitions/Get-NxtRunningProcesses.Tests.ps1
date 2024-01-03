Describe "Get-NxtRunningProcesses" {
    Context "When running processes are present" {
        BeforeAll {
            [System.Diagnostics.Process]$childProcess = Start-Process -FilePath ./test/simple.exe -PassThru
        }
        AfterAll {
            $childProcess.Kill()
        }
        It "Returns the list of found processes" {
            [array]$processes = @(
                @{
                    ProcessName = $childProcess.Name
                }
            )
            $result = Get-NxtRunningProcesses -ProcessObjects $processes
            $result.GetType().BaseType.Name | Should -Be 'Array'
            $result.ProcessName | Should -Contain $childProcess.Name
            $result.Count | Should -Be 1
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
            $result.GetType().BaseType.Name | Should -Be 'Array'
            $result.ProcessName | Should -Contain $childProcess.Name
            $result.Count | Should -Be 1
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
