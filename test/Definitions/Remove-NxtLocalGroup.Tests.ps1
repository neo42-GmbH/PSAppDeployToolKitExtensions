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
        It 'Should remove an existing group with no members' -Skip {
            # Issue #624
            $result = Remove-NxtLocalGroup -GroupName 'TestGroup'
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
            Get-LocalGroup -Name 'TestGroup' | Should -BeNullOrEmpty
        }
        It 'Should remove an existing group with members' -Skip {
            # Issue #624
            Add-LocalGroupMember -Group 'TestGroup' -Member 'Administrator'
            $result = Remove-NxtLocalGroup -GroupName 'TestGroup' | Should -Be $true
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
