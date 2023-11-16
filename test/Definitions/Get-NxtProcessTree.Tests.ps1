Describe "Get-NxtProcessTree" {
    Context "When given a valid process ID" {
        BeforeAll {
            [System.Diagnostics.Process]$process = [System.Diagnostics.Process]::GetCurrentProcess()
            [System.Diagnostics.Process]$childProcess = Start-Process -FilePath simple.exe -PassThru
        }
        AfterAll {
            $childProcess.Kill()
        }
        It "Should return a correct list of processes" {
            $processes = Get-NxtProcessTree -ProcessId $childProcess.Id
            $processes.GetType().BaseType.Name | Should -Be 'Array'
            $processes | ForEach-Object { $_ | Should -BeOfType 'System.Management.ManagementObject' }
            $processes.Length | Should -BeGreaterThan 1
            $processes.ProcessId | Should -Contain $childProcess.Id
            $processes.ProcessId | Should -Contain $process.Id
        }
        It "Should not contain childs when specified" {
            [System.Array]$processes = Get-NxtProcessTree -ProcessId $process.Id -IncludeChildProcesses $false
            $processes.ProcessId | Should -Not -Contain $childProcess.Id
        }
        It "Should not contain parents when specified" {
            [System.Array]$processes = Get-NxtProcessTree -ProcessId $childProcess.Id -IncludeParentProcesses $false
            $processes.ProcessId | Should -Not -Contain $process.Id
        }
        It "Should output nothing if PID does not exist" {
            Get-NxtProcessTree -ProcessId 9999999 | Should -BeNullOrEmpty
        }
        It 'Should not loop on idle process' {
            (Get-NxtProcessTree -Id 0).length | Should -Be 1
        }
    }
}
