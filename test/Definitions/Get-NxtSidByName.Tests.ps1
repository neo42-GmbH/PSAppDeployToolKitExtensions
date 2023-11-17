Describe 'Get-NxtSidByName' {
    Context 'when given an SID' {
        BeforeAll {
            [Microsoft.PowerShell.Commands.LocalUser]$localUser = New-LocalUser -Name 'TestUser' -NoPassword
        }
        AfterAll {
            if (Get-LocalUser -Name 'TestUser' -ErrorAction SilentlyContinue) {
                Remove-LocalUser -Name 'TestUser'
            }
        }
        It 'Should return the correct name'{
            $result = Get-NxtSidByName -UserName $localUser.Name
            $result | Should -BeOfType 'System.String'
            $result | Should -Be $localUser.SID
        }
        It 'Should fail on an invalid SID' {
            Get-NxtSidByName -UserName 'INVALID' | Should -BeNullOrEmpty
        }
    }
}
