Describe 'Get-NxtParentProcess' {
    Context 'when given a process ID' {
        BeforeAll {
            [string]$selfPID = ([System.Diagnostics.Process]::GetCurrentProcess()).Id
            [System.Diagnostics.Process]$childProcess = Start-Process -FilePath simple.exe -PassThru
        }
        AfterAll{
            $childProcess.Kill()
        }
        It 'Should return the parent process ID' {
            $process = Get-NxtParentProcess -Id $childProcess.Id
            $process | Should -BeOfType 'System.Management.ManagementBaseObject'
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
        It 'Should not loop on idle process' {
            [Array]@((Get-NxtParentProcess -Id 0)).count | Should -Be 1
        }
    }
}
