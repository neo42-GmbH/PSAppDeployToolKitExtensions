Describe "Get-NxtComputerModel" {
    Context "When running the function" {
        AfterAll {
            Remove-Item Function:\Get-CimInstance
        }
        It "Should return the correct computer model" {
            function global:Get-CimInstance {
                return [PSCustomObject]@{
                    Model = 'Test'
                }
            }
            $result = Get-NxtComputerModel
            $result | Should -BeOfType 'String'
            $result | Should -Be 'Test'
        }
        It "Should return an empty string if the WMI query fails" {
            function global:Get-CimInstance { return $null }
            $result = Get-NxtComputerModel
            $result | Should -BeOfType 'String'
            $result | Should -Be ''
        }
    }
}
