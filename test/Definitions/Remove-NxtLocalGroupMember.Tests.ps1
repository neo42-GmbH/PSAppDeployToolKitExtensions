Describe 'Remove-NxtLocalGroupMember' {
    Context 'When a group with member is supplied' {
        BeforeAll {
            New-LocalUser 'TestUser1' -NoPassword
            New-LocalUser 'TestUser2' -NoPassword
        }
        BeforeEach {
            New-LocalGroup -Name 'TestGroup'
            Add-LocalGroupMember -Group 'TestGroup' -Member 'TestUser1'
            Add-LocalGroupMember -Group 'TestGroup' -Member 'TestUser2'
        }
        AfterEach {
            Remove-LocalGroup -Name 'TestGroup'
        }
        AfterAll {
            Remove-LocalUser -Name 'TestUser1'
            Remove-LocalUser -Name 'TestUser2'
        }
        It 'Should remove the specified member from the group' {

            $result = Remove-NxtLocalGroupMember -GroupName 'TestGroup' -MemberName 'TestUser1'
            $result | Should -BeOfType 'System.Int32'
            $result | Should -Be 1
            (Get-LocalGroupMember -Group 'TestGroup').Name | Should -Not -Contain "$env:ComputerName\TestUser1"
            (Get-LocalGroupMember -Group 'TestGroup').Name | Should -Contain "$env:ComputerName\TestUser2"
        }
        It 'Should remove all members of the group when -AllMember is specified' {
            $result = Remove-NxtLocalGroupMember -GroupName 'TestGroup' -AllMember
            $result | Should -BeOfType 'System.Int32'
            $result | Should -Be 2
            (Get-LocalGroupMember -Group 'TestGroup').Name | Should -BeNullOrEmpty
        }
        It 'Should return nothing if the member was not found' {
            Remove-NxtLocalGroupMember -GroupName 'TestGroup' -MemberName 'TestUser3' | Should -BeNullOrEmpty
        }
        It 'Should do nothing if group was not found' {
            Remove-NxtLocalGroupMember -GroupName 'TestGroup2' -MemberName 'TestUser1' | Should -BeNullOrEmpty
        }
    }
}
