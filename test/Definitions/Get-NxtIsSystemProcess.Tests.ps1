Describe "Get-NxtIsSystemProcess" {
    Context "When given a process name" {
        BeforeAll {
            [int]$systemProcessId = 4
            [int]$lsassProcessId = (Get-Process -Name 'lsass' | Select-Object -First 1).Id

            [securestring]$securePassword = ConvertTo-SecureString -String "sdouighASDG42!" -AsPlainText -Force
            [pscredential]$credential = New-Object System.Management.Automation.PSCredential ('TestUser', $securePassword)
            New-LocalUser -Name 'TestUser' -Password $securePassword

            [System.Diagnostics.Process]$userProcess = Start-Process -FilePath "timeout" -ArgumentList ("/t 300") -Credential $credential -PassThru -WorkingDirectory "$env:windir"
        }
        AfterAll {
            if (Get-LocalUser -Name 'TestUser' -ErrorAction SilentlyContinue) {
                Remove-LocalUser -Name 'TestUser'
            }
            $userProcess.Kill()
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
