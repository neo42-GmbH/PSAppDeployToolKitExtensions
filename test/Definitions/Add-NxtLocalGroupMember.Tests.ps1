# Test the Add-NxtLocalGroupMember Function
Describe 'Add-NxtLocalGroupMember' {
    Context 'When adding an entity to a group' {
        BeforeAll {
            New-LocalGroup -Name "TestGroup"
            New-LocalGroup -Name "TestGroupAdd"
            New-LocalUser -Name "TestUser" -Password (ConvertTo-SecureString -String "2uqWjQ/OvM,wh£9[47o" -AsPlainText -Force)
        }
        AfterAll {
            Remove-LocalGroup -Name "TestGroup"
            Remove-LocalGroup -Name "TestGroupAdd"
            Remove-LocalUser -Name "TestUser"
        }
        AfterEach {
            Get-LocalGroupMember -Name "TestGroup" | ForEach-Object { $_ | Remove-LocalGroupMember -Confirm:$false }
        }
        It 'Should add a user to the group' -Skip {
            Add-NxtLocalGroupMember -GroupName "TestGroup" -MemberName "TestUser" -MemberType "User" | Should -Be $true
            (Get-LocalGroup -Name "TestGroup").Members | Should -Contain "TestUser"
        }
        It 'Should add a group to a group' -Skip {
            #Add-NxtLocalGroupMember fails to add nested groups #621
            Add-NxtLocalGroupMember -GroupName "TestGroup" -MemberName "TestGroupAdd" -MemberType "Group" | Should -Be $true
            (Get-LocalGroup -Name "TestGroup").Members | Should -Contain "TestGroupAdd"
        }
        It 'Should fail when the target group does not exist' {
            Add-NxtLocalGroupMember -GroupName "TestGroupDoesNotExist" -MemberName "TestUser" -MemberType "User" | Should -Be $false
        }
        It 'Should fail if user to be added does not exist' {
            Add-NxtLocalGroupMember -GroupName "TestGroup" -MemberName "TestUserDoesNotExist" -MemberType "User" | Should -Be $false
        }
        It 'Should fail if the group to added does not exist' {
            Add-NxtLocalGroupMember -GroupName "TestGroup" -MemberName "TestGroupDoesNotExist" -MemberType "Group" | Should -Be $false
        }
        It 'Should fail if the wrong MemberType has been selected' -Skip {
            Add-NxtLocalGroupMember -GroupName "TestGroup" -MemberName "TestUser" -MemberType "Group" | Should -Be $false
            Add-NxtLocalGroupMember -GroupName "TestGroup" -MemberName "TestGroupAdd" -MemberType "User"  | Should -Be $false
        }
        It 'Should do nothing if the user is already a member' -Skip {
            Add-NxtLocalGroupMember -GroupName "TestGroup" -MemberName "TestUser" -MemberType "User"
            Add-NxtLocalGroupMember -GroupName "TestGroup" -MemberName "TestUser" -MemberType "User" | Should -Be $false
        }
        It 'Should fail on self reference' -Skip {
            Add-NxtLocalGroupMember -GroupName "TestGroup" -MemberName "TestGroup" -MemberType "Group" | Should -Throw
        }
    }
}
