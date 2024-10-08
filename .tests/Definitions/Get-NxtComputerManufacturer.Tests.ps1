Describe "Get-NxtComputerManufacturer" {
    Context "When running the function with working WMI" {
        AfterAll {
            Remove-Item Function:\Get-WmiObject
        }
        It "Should return the correct computer manufacturer" {
            function global:Get-WmiObject {
                return [PSCustomObject]@{
                    Manufacturer = 'Test'
                }
            }
            $result = Get-NxtComputerManufacturer
            $result | Should -BeOfType 'String'
            $result | Should -Be 'Test'
        }
        It "Should return an empty string if the WMI query fails"{
            function global:Get-WmiObject {
                return $null
            }
            $result = Get-NxtComputerManufacturer
            $result | Should -BeOfType 'String'
            $result | Should -Be ''
        }
    }
}
