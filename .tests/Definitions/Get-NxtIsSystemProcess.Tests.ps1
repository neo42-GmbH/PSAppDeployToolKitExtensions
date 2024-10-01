Describe "Get-NxtIsSystemProcess" {
    Context "When given a process name" {
        BeforeAll {
            [int]$lsassProcessId = (Get-Process -Name 'lsass' | Select-Object -First 1).Id
            [int]$userProcessId = (Get-WmiObject -Class Win32_Process -Filter "Name = 'explorer.exe'" | Where-Object { $_.GetOwner().User -notmatch '^(System|)$' }).ProcessId
        }
        It "Should return true for lsass (System) process" {
            $result = Get-NxtIsSystemProcess -ProcessId $lsassProcessId
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
        }
        It "Should be true for system process" {
            Get-NxtIsSystemProcess -ProcessId 4 | Should -Be $true
        }
        It "Should return true for user process" -Skip {
            if ($userProcessId) {
                $result = Get-NxtIsSystemProcess -ProcessId $userProcessId
                $result | Should -BeOfType 'bool'
                $result | Should -Be $false
            }
            else {
                Set-ItResult -Inconclusive -Message "No user process found"
            }
        }
    }
}
