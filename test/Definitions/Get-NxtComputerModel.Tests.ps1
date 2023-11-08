Describe "Get-NxtComputerModel" {
    Context "When running the function" {
        It "Should return the correct computer model" {
            [string]$model = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
            $result = Get-NxtComputerModel
            $result | Should -BeOfType 'String'
            $result | Should -Be $model
        }
        It "Should return an empty string if the WMI query fails" -Skip {
            # Mocking and replacing function does not work because of scope issues #626
            Mock Get-WmiObject { return $null }
            $result = Get-NxtComputerModel
            $result | Should -BeOfType 'String'
            $result | Should -Be ''
        }
    }
}
