Describe 'ConvertFrom-NxtEscapedString' {
	Context 'When given an escaped string' {
		BeforeAll {
			[string]$escapedString = 'C:\my\ program.exe -Argument1 "Value 1" -Argument2 ''Value 2'' -Argument3 Value\ 3'
		}
		It 'Should return expected output' {
			$output = ConvertFrom-NxtEscapedString -InputString $escapedString
			$output | Should -BeOfType 'String'
			$output[0] | Should -Be 'C:\my program.exe'
			$output[1] | Should -Be '-Argument1'
			$output[2] | Should -Be 'Value 1'
			$output[4] | Should -Be 'Value 2'
			$output[6] | Should -Be 'Value 3'
		}
	}
}
