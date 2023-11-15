Describe "Remove-NxtLocalUser" {
    Context "When calling the function" {
        BeforeEach {
            New-LocalUser -Name "TestUser" -NoPassword
        }
        AfterEach { 
            if (Get-LocalUser -Name "TestUser" -ErrorAction SilentlyContinue) {
                Remove-LocalUser -Name "TestUser"
            }
        }
        It "Should remove the user from the local machine" {
            $result = Remove-NxtLocalUser -UserName "TestUser"
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
        }
        It "Should fail if the user does not exist" {
            $result = Remove-NxtLocalUser -UserName "TestUser2"
            $result | Should -BeOfType 'bool'
            $result | Should -Be $false
        }
    }
}
