Describe "Get-NxtComputerManufacturer" {
    Context "When running the function with working WMI" {
        It "Should return the correct computer manufacturer" {
            [string]$manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
            $result = Get-NxtComputerManufacturer
            $result | Should -BeOfType 'String'
            $result | Should -Be $manufacturer
        }
        It "Should return an empty string if the WMI query fails" -Skip{
            # Mocking and replacing function does not work because of scope issues #626
            Mock Get-WmiObject { return $null }
            $result = Get-NxtComputerManufacturer
            $result | Should -BeOfType 'String'
            $result | Should -Be ''
        }
    }
}
