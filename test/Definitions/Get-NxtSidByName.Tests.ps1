Describe 'Get-NxtSidByName' {
    Context 'when given an SID' {
        BeforeAll {
            [System.Security.Principal.WindowsIdentity]$currentID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        }
        It 'Should return the correct name'{
            $result = Get-NxtSidByName -UserName $currentID.Name
            $result | Should -BeOfType 'System.String'
            $result | Should -Be $currentID.User.Value
        }
        It 'Should fail on an invalid SID' {
            Get-NxtSidByName -UserName 'INVALID' | Should -BeNullOrEmpty
        }
    }
}
