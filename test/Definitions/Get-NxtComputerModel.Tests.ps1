Describe "Get-NxtComputerModel" {
    Context "When running the function with working WMI" {
        BeforeAll{
            Mock Get-WmiObject { return [PSCustomObject]@{ Model = 'Test' } }
        }
        It "Should return the correct computer model" {
            $result = Get-NxtComputerModel
            $result | Should -BeOfType 'String'
            $result | Should -Be 'Test'
        }
    }
    Context "When running the function with broken WMI" {
        BeforeAll{
            Mock Get-WmiObject { return $null }
        }
        It "Should return the correct computer model" {
            $result = Get-NxtComputerModel
            $result | Should -BeOfType 'String'
            $result | Should -Be ''
        }
    }
}
