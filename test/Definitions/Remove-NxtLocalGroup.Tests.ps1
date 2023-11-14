Describe 'Remove-NxtLocalGroup' {
    Context 'When the group exists' {
        BeforeEach {
            New-LocalGroup -Name 'TestGroup'
        }
        AfterEach {
            if (Get-LocalGroup -Name 'TestGroup' -ErrorAction SilentlyContinue) {
                Remove-LocalGroup -Name 'TestGroup' -Force
            }
        }
        It 'Should remove an existing group with no members' {
            # Issue #624
            $result = Remove-NxtLocalGroup -GroupName 'TestGroup'
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
            Get-LocalGroup -Name 'TestGroup' | Should -BeNullOrEmpty
        }
        It 'Should remove an existing group with members' {
            # Issue #624
            Add-LocalGroupMember -Group 'TestGroup' -Member 'Administrator'
            Remove-NxtLocalGroup -GroupName 'TestGroup' | Should -Be $true
            Get-LocalGroup -Name 'TestGroup' | Should -BeNullOrEmpty
        }
    }
    Context 'When group does not exist' {
        It 'Should return false' {
            $result = Remove-NxtLocalGroup -GroupName 'TestGroup'
            $result | Should -BeOfType 'bool'
            $result | Should -Be $false
        }
    }
}
