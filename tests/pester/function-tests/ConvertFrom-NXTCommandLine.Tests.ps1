BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'ConvertFrom-NXTCommandLine' {
	Context 'When converting command lines with spaces and quotes' {
		It 'Should properly parse quoted strings' {
			$result = ConvertFrom-NXTCommandLine -InputObject '"C:\Program Files\App\app.exe" -arg1 "value 1"'
			$result.Count | Should -Be 3
			$result[0] | Should -Be 'C:\Program Files\App\app.exe'
			$result[1] | Should -Be '-arg1'
			$result[2] | Should -Be 'value 1'
		}

		It 'Should handle empty quotes correctly' {
			$result = ConvertFrom-NXTCommandLine -InputObject '"" -arg1 ""'
			$result.Count | Should -Be 3
			$result[0] | Should -BeNullOrEmpty
			$result[1] | Should -Be '-arg1'
			$result[2] | Should -BeNullOrEmpty
		}

		It 'Should handle nested escaped quotes' {
			$result = ConvertFrom-NXTCommandLine -InputObject '"C:\Path\To\Program.exe" -arg1 "outer \"inner\" outer"'
			$result.Count | Should -Be 3
			$result[0] | Should -Be 'C:\Path\To\Program.exe'
			$result[1] | Should -Be '-arg1'
			$result[2] | Should -Be 'outer "inner" outer'
		}

		It 'Should parse command lines with multiple arguments' {
			$result = ConvertFrom-NXTCommandLine -InputObject '"app.exe" -arg1 "val1" -arg2 "val2" -flag -arg3="val3"'
			$result.Count | Should -Be 7
			$result[0] | Should -Be 'app.exe'
			$result[3] | Should -Be '-arg2'
			$result[5] | Should -Be '-flag'
			$result[6] | Should -Be '-arg3="val3"'
		}
	}

	Context 'When handling edge cases' {
		It 'Should return empty on empty input' {
			ConvertFrom-NXTCommandLine -InputObject '' | Should -BeNullOrEmpty
			ConvertFrom-NXTCommandLine -InputObject $null | Should -BeNullOrEmpty
			ConvertFrom-NXTCommandLine -InputObject '   ' | Should -BeNullOrEmpty
		}

		It 'Should accept pipeline input' {
			$result = '"app.exe" -arg "value"' | ConvertFrom-NXTCommandLine
			$result.Count | Should -Be 3
			$result[0] | Should -Be 'app.exe'
			$result[1] | Should -Be '-arg'
			$result[2] | Should -Be 'value'
		}
	}
}
