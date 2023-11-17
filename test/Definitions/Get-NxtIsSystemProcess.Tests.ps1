Describe "Get-NxtIsSystemProcess" {
    Context "When given a process name" {
        BeforeAll {
            [int]$systemProcessId = 4
            [int]$lsassProcessId = (Get-Process -Name 'lsass' | Select-Object -First 1).Id
        }
        It "Should return true for lsass (System) process" {
            $result = Get-NxtIsSystemProcess -ProcessId $lsassProcessId
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
        }
        It "Should throw on access denied" -Skip {
            # Issue #628
            Get-NxtIsSystemProcess -ProcessId $systemProcessId | Should -Be $true
        }
        It "Should return true for user prorcess" -Skip {
            "@
                It is currently hard to reliably create a user process for this test.
                On self-hosted runners this process runs as System. System cannot impersonate a user.
                This test will be skipped until a reliable way to create a user process is found.
            @"
        }
    }
}
