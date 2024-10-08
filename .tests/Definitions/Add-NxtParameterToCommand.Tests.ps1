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
        It "Should not allow a switch and a value to be specified" {
            { Add-NxtParameterToCommand -Command 'text.exe' -Name 'test' -Value 'value' -Switch $true } | Should -Throw
        }
        It "Should not allow not specifiying what to add" {
            { Add-NxtParameterToCommand -Command 'text.exe' -Name 'test' } | Should -Throw
        }

    }
}
