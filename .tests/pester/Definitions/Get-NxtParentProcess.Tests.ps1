Describe 'Get-NxtParentProcess' {
    Context 'when given a process ID' {
        BeforeAll {
            [string]$selfPID = ([System.Diagnostics.Process]::GetCurrentProcess()).Id
            [System.Diagnostics.Process]$childProcess = Start-Process -FilePath ./test/simple.exe -PassThru
            [ciminstance]$service = Get-CimInstance -Class Win32_Service -Filter "State = 'Running'" | Select-Object -First 1
            [System.Diagnostics.Process]$serviceProcess = Get-Process -Id $service.ProcessId
        }
        AfterAll{
            $childProcess.Kill()
        }
        It 'Should return the parent process ID' {
            $process = Get-NxtParentProcess -Id $childProcess.Id
            $process | Should -BeOfType 'ciminstance'
            $process.ProcessId | Should -Be $selfPID
        }
        It 'Should return multiple parent process IDs' {
            $processes = Get-NxtParentProcess -Id $childProcess.Id -Recurse
            $processes.GetType().BaseType.Name | Should -Be 'Array'
            $processes.Length | Should -BeGreaterThan 1
            $processes.ProcessId | Should -Contain $selfPID
        }
        It 'Should fail if process not found' {
            [Array]@((Get-NxtParentProcess -Id 9999999)).count | Should -Be 0
            [Array]@((Get-NxtParentProcess -Id 9999999 -Recurse)).count | Should -Be 0
        }
        It 'Should not loop on idle or service process' {
            [Array]@((Get-NxtParentProcess -Id 0)).count | Should -Be 0
            [Array]@((Get-NxtParentProcess -Id $serviceProcess.id)).count | Should -BeLessThan 25
        }
    }
}
