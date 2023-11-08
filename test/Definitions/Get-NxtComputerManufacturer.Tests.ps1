Describe "Get-NxtComputerManufacturer" {
    Context "When running the function with working WMI" {
        BeforeAll{
            function Get-WmiObject { return [PSCustomObject]@{ Manufacturer = 'Test' } }
        }
        It "Should return the correct computer manufacturer" {
            $result = Get-NxtComputerManufacturer
            $result | Should -BeOfType 'String'
            $result | Should -Be 'Test'
        }
    }
    Context "When running the function with broken WMI" {
        BeforeAll{
            function Get-WmiObject { return $null }
        }
        It "Should return the correct computer manufacturer" {
            $result = Get-NxtComputerManufacturer
            $result | Should -BeOfType 'String'
            $result | Should -Be ''
        }
    }
}
