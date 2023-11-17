Describe 'Get-NxtNameBySid' {
    Context 'when given an SID' {
        BeforeAll {
            [System.Security.Principal.WindowsIdentity]$currentID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        }
        It 'Should return the correct name'{
            $result = Get-NxtNameBySid -Sid $currentID.User.Value
            $result | Should -BeOfType 'System.String'
            $result | Should -Be $currentID.Name
        }
        It 'Should return the correct name for a well-known SID' {
            [string]$name = (New-Object System.Security.Principal.SecurityIdentifier('S-1-5-18')).Translate([System.Security.Principal.NTAccount]).Value
            Get-NxtNameBySid -Sid 'S-1-5-18' | Should -Be $name
        }
        It 'Should fail on an invalid SID' {
            Get-NxtNameBySid -Sid 'S-1-5-18-19' | Should -BeNullOrEmpty
        }
        It 'Should fail in invalid SID format' {
            Get-NxtNameBySid -Sid 'invalid' | Should -BeNullOrEmpty
        }
    }
}
