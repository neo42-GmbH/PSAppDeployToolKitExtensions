Describe "Get-NxtIsSystemProcess" {
    Context "When given a system process name" {
        BeforeAll {
            [int]$systemProcess = 4
            [int]$userProcess = (Get-Process -Name 'explorer' | Select-Object -First 1).Id
            [int]$lsassProcess = (Get-Process -Name 'lsass' | Select-Object -First 1).Id
        }
        It "Should return true for lsass process" {
            $result = Get-NxtIsSystemProcess -ProcessId $lsassProcess
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
        }
        It "Should return false on self" {
            Get-NxtIsSystemProcess -ProcessId $selfProcess | Should -Be $false
        }
        It "Should throw on access denied" -Skip {
            # Issue #628
            Get-NxtIsSystemProcess -ProcessId $systemProcess | Should -Be $true
        }
    }
}
