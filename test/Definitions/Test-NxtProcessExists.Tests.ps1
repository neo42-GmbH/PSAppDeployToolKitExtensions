Describe "Test-NxtProcessExists" {
    Context "When given a process name" {
        BeforeAll {
            [string]$processName = [System.Diagnostics.Process]::GetCurrentProcess().ProcessName + '.exe'
        }
        It "Should return true if the process exists" {
            $result = Test-NxtProcessExists -ProcessName $processName
            $result | Should -BeOfType "Boolean"
            $result | Should -Be $true
        }
        It "Should return false if the process is not running" {
            Test-NxtProcessExists -ProcessName 'invalidProcess' | Should -Be $false
        }
        It "Should work with wildcard character *" {
            Test-NxtProcessExists -ProcessName "$($processName.Substring(0, 5))*" | Should -Be $true
        }
    }
    Context "When given wql" {
        BeforeAll {
            [string]$processName = [System.Diagnostics.Process]::GetCurrentProcess().ProcessName + '.exe'
        }
        It "Should return true if the process exists" {
            $result = Test-NxtProcessExists -ProcessName "Name LIKE `"$processName`"" -IsWql
            $result | Should -BeOfType "Boolean"
            $result | Should -Be $true
        }
        It "Should return false if the process is not running" {
            Test-NxtProcessExists -ProcessName 'Name LIKE "invalidProcess"' -IsWql | Should -Be $false
        }
        It "Should throw an error if the wql is invalid" -Skip {
            # Issue #625
            { Test-NxtProcessExists -ProcessName 'invalidWql' -IsWql } | Should -Throw
        }
    }
}
