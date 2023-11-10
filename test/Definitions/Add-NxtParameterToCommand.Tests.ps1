Describe "Add-NxtParameterToCommand" {
    Context "When adding a parameter to a command" {
        It "Should add the parameter to the command" {
            $result = Add-NxtParameterToCommand -Command 'text.exe' -Name 'test' -Value 'value'
            $result | Should -BeOfType [System.String]
            $result | Should -Be 'text.exe -test "value"'
        }
        It "Should add a switch to the command" {
            Add-NxtParameterToCommand -Command 'text.exe' -Name 'test' -Switch $true | Should -Be 'text.exe -test'
        }
        It "Should still use switch if value is specified" {
            Add-NxtParameterToCommand -Command 'text.exe' -Name 'test' -Value 'value' -Switch $true | Should -Be 'text.exe -test'
        }
        It "Should not add values if no value or switch is specified" {
            Add-NxtParameterToCommand -Command 'text.exe' -Name 'test' | Should -Be 'text.exe'
        }

    }
}
