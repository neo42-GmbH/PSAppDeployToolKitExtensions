Describe "Get-NxtIsSystemProcess" {
    Context "When given a system process name" {
        BeforeAll {
            [int]$systemProcessId = 4
            [int]$lsassProcessId = (Get-Process -Name 'lsass' | Select-Object -First 1).Id

            [securestring]$securePassword = ConvertTo-SecureString -String "sdouighASDG42!" -AsPlainText -Force
            New-LocalUser -Name 'TestUser' -Password $securePassword
            [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)
            [System.Diagnostics.Process]$userProcess = Start-Process -FilePath "simple.exe" -Credential $credObject
        }
        AfterAll {
            if (Get-LocalUser -Name 'TestUser' -ErrorAction SilentlyContinue) {
                Remove-LocalUser -Name 'TestUser'
            }
            if (Get-Process $process.Id -ErrorAction SilentlyContinue){
                $userProcess.Kill()
            }
        }
        It "Should return true for lsass process" {
            $result = Get-NxtIsSystemProcess -ProcessId $lsassProcessId
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
        }
        It "Should return false on self" {
            Get-NxtIsSystemProcess -ProcessId $userProcess.Id | Should -Be $false
        }
        It "Should throw on access denied" -Skip {
            # Issue #628
            Get-NxtIsSystemProcess -ProcessId $systemProcessId | Should -Be $true
        }
    }
}
