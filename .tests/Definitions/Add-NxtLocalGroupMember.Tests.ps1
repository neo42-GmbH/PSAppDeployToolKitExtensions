# Test the Add-NxtLocalGroupMember Function
Describe 'Add-NxtLocalGroupMember' {
    Context 'When adding an entity to a group' {
        BeforeAll {
            New-LocalGroup -Name "TestGroup"
            New-LocalUser -Name "TestUser" -NoPassword
        }
        AfterAll {
            Remove-LocalGroup -Name "TestGroup"
            Remove-LocalUser -Name "TestUser"
        }
        AfterEach {
            Get-LocalGroupMember -Group "TestGroup" | ForEach-Object { Remove-LocalGroupMember -Group "TestGroup" -Member $_.Name }
        }
        It 'Should add a user to the group' {
            Add-NxtLocalGroupMember -GroupName "TestGroup" -MemberName "TestUser" | Should -Be $true
            (Get-LocalGroupMember -Group "TestGroup").Name | Should -Contain "$env:COMPUTERNAME\TestUser"
        }
        It 'Should fail when the target group does not exist' {
            Add-NxtLocalGroupMember -GroupName "TestGroupDoesNotExist" -MemberName "TestUser" | Should -Be $false
        }
        It 'Should fail if user to be added does not exist' {
            Add-NxtLocalGroupMember -GroupName "TestGroup" -MemberName "TestUserDoesNotExist" | Should -Be $false
        }
        It 'Should fail if the group to added does not exist' {
            Add-NxtLocalGroupMember -GroupName "TestGroup" -MemberName "TestGroupDoesNotExist" | Should -Be $false
        }
        It 'Should do nothing if the user is already a member' {
            Add-NxtLocalGroupMember -GroupName "TestGroup" -MemberName "TestUser"
            Add-NxtLocalGroupMember -GroupName "TestGroup" -MemberName "TestUser" | Should -Be $false
        }
    }
}
