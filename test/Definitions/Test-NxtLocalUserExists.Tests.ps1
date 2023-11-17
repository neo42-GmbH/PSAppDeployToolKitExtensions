Describe "Test-NxtLocalUserExists" {
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
            $result = Test-NxtLocalUserExists -UserName 'TestUser'
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
        }
        It "Should return false if group does not exist" {
            $result = Test-NxtLocalUserExists -UserName 'InvalidUser'
            $result | Should -BeOfType 'bool'
            $result | Should -Be $false
        }
        It "Should return false if group is a user" {
            $result = Test-NxtLocalUserExists -UserName 'TestGroup'
            $result | Should -BeOfType 'bool'
            $result | Should -Be $false
        }
    }
}
