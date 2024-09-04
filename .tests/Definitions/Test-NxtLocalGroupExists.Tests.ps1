Describe "Test-NxtLocalGroupExists" {
    Context "When testing the function" {
        BeforeAll {
            New-LocalGroup -Name 'TestGroup' | Out-Null
            New-LocalUser -Name 'TestUser' -NoPassword | Out-Null
        }
        AfterAll {
            Remove-LocalGroup -Name 'TestGroup' | Out-Null
            Remove-LocalUser -Name 'TestUser' | Out-Null
        }
        It "Should return true if group exists" {
            $result = Test-NxtLocalGroupExists -GroupName 'TestGroup'
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
        }
        It "Should return false if group does not exist" {
            $result = Test-NxtLocalGroupExists -GroupName 'InvalidGroup'
            $result | Should -BeOfType 'bool'
            $result | Should -Be $false
        }
        It "Should return false if group is a user" {
            $result = Test-NxtLocalGroupExists -GroupName 'TestUser'
            $result | Should -BeOfType 'bool'
            $result | Should -Be $false
        }
    }
}
