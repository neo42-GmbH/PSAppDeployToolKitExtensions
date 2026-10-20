BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'ConvertFrom-NXTProductCode' {
	Context 'When converting a valid installer product code to product GUID' {
		It 'Should correctly convert a product code with reordered character indices' {
			# Test case using a known product code and expected result
			$testProductCode = '87654321432143212143214365870921'
			[System.Guid]$expected = '12345678-1234-1234-1234-123456789012'
			$result = ConvertFrom-NXTProductCode -ProductCode $testProductCode
			$result | Should -Be $expected
		}

		It 'Should return a System.Guid' {
			$result = ConvertFrom-NXTProductCode -ProductCode '87654321432143212143214365870921'
			$result | Should -BeOfType [System.Guid]
		}

		It 'Should accept pipeline input' {
			$testProductCode = '12345678123434125634785612907834'
			[System.Guid]$expected = '87654321-4321-2143-6543-876521098743'
			$result = $testProductCode | ConvertFrom-NXTProductCode
			$result | Should -Be $expected
		}

		It 'Should accept positional input' {
			[System.Guid]$expected = '12345678-1234-1234-1234-123456789012'
			$result = ConvertFrom-NXTProductCode '87654321432143212143214365870921'
			$result | Should -Be $expected
		}

		It 'Should convert the product code from the help example' {
			[System.Guid]$expected = '{34E04A47-52EA-33A2-ADC9-8256E6F1E401}'
			$result = '74A40E43AE252A33DA9C28656E1F4E10' | ConvertFrom-NXTProductCode
			$result | Should -Be $expected
		}

		It 'Should treat upper and lower case product codes equally' {
			$resultUpper = ConvertFrom-NXTProductCode -ProductCode 'ABCDEF01ABCDEF01ABCDEF01ABCDEF01'
			$resultLower = ConvertFrom-NXTProductCode -ProductCode 'abcdef01abcdef01abcdef01abcdef01'

			$resultUpper | Should -Be $resultLower
			$resultUpper | Should -Be ([System.Guid]'10FEDCBA-DCBA-10FE-BADC-FE10BADCFE10')
		}
	}

	Context 'When handling edge cases' {
		It 'Should handle zero product code correctly' {
			$zeroProductCode = '00000000000000000000000000000000'
			$result = ConvertFrom-NXTProductCode -ProductCode $zeroProductCode
			$result | Should -Be ([System.Guid]::Empty)
		}

		It 'Should throw on null input' {
			{ ConvertFrom-NXTProductCode -ProductCode $null } | Should -Throw
		}

		It 'Should throw on empty input' {
			{ ConvertFrom-NXTProductCode -ProductCode '' } | Should -Throw
		}

		It 'Should throw on a product code that is too short' {
			{ ConvertFrom-NXTProductCode -ProductCode '1234567890ABCDEF' } | Should -Throw
		}

		It 'Should throw on a product code that is too long' {
			{ ConvertFrom-NXTProductCode -ProductCode '87654321432143212143214365870921FF' } | Should -Throw
		}

		It 'Should throw on a product code in GUID format' {
			{ ConvertFrom-NXTProductCode -ProductCode '{12345678-1234-1234-1234-123456789012}' } | Should -Throw
		}

		It 'Should throw on a product code containing non-hexadecimal characters' {
			{ ConvertFrom-NXTProductCode -ProductCode 'GHIJKLMNOPQRSTUVWXYZGHIJKLMNOPQR' } | Should -Throw
		}
	}

	Context 'When used with related functions' {
		It 'Should round-trip with ConvertTo-NXTProductCode' {
			[System.Guid]$testGuid = '{AB12CD34-EF56-7890-1A2B-3C4D5E6F7A8B}'
			$testGuid | ConvertTo-NXTProductCode | ConvertFrom-NXTProductCode | Should -Be $testGuid
		}

		It 'Should round-trip a product code with ConvertTo-NXTProductCode' {
			$testProductCode = '74A40E43AE252A33DA9C28656E1F4E10'
			$testProductCode | ConvertFrom-NXTProductCode | ConvertTo-NXTProductCode | Should -Be $testProductCode
		}
	}
}
