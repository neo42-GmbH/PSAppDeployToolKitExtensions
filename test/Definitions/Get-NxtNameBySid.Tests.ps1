Describe 'Get-NxtNameBySid' {
    Context 'when given an SID' {
        BeforeAll {
            [System.Security.Principal.WindowsIdentity]$currentID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        }
        It 'Should return the correct name'{
            $result = Get-NxtNameBySid -Sid $currentID.User
            $result | Should -BeOfType 'System.String'
            $result | Should -Be $currentID.Name
        }
        It 'Should return the correct name for a well-known SID' {
            Get-NxtNameBySid -Sid 'S-1-5-18' | Should -Be 'NT AUTHORITY\SYSTEM'
        }
        It 'Should fail on an invalid SID' {
            Get-NxtNameBySid -Sid 'S-1-5-18-19' | Should -BeNullOrEmpty
        }
    }
}
