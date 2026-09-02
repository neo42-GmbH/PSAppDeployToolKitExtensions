BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'ConvertTo-NXTInstallerProductCode' {
	Context 'When converting a valid product GUID to installer product code' {
		It 'Should correctly convert a GUID with reordered character indices' {
			# Test case using a known GUID and expected result
			[System.Guid]$testGuid = '12345678-1234-1234-1234-123456789012'
			$expected = '87654321432143212143214365870921'
			$result = ConvertTo-NXTInstallerProductCode -Guid $testGuid
			$result | Should -Be $expected
		}

		It 'Should accept pipeline input' {
			[System.Guid]$testGuid = '87654321-4321-2143-6543-876521098743'
			$expected = '12345678123434125634785612907834'
			$result = $testGuid | ConvertTo-NXTInstallerProductCode
			$result | Should -Be $expected
		}

		It 'Should accept different GUID formats' {
			# Test with GUID in various formats
			[System.Guid]$bracketFormat = '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}'
			[System.Guid]$plainFormat = 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE'

			$resultBracket = ConvertTo-NXTInstallerProductCode -Guid $bracketFormat
			$resultPlain = ConvertTo-NXTInstallerProductCode -Guid $plainFormat

			$resultBracket | Should -Be $resultPlain
			$resultBracket | Should -Be 'AAAAAAAABBBBCCCCDDDDEEEEEEEEEEEE'
		}
	}

	Context 'When handling edge cases' {
		It 'Should handle zero GUID correctly' {
			[System.Guid]$zeroGuid = '00000000-0000-0000-0000-000000000000'
			$expected = '00000000000000000000000000000000'
			$result = ConvertTo-NXTInstallerProductCode -Guid $zeroGuid
			$result | Should -Be $expected
		}

		It 'Should throw on null input' {
			{ ConvertTo-NXTInstallerProductCode -Guid $null } | Should -Throw
		}
	}

	Context 'When used with related functions' {
		It 'Should handle GUIDs from different property names via pipeline' {
			$mockObject = [PSCustomObject]@{
				ProductCode = [System.Guid]'12345678-1234-1234-1234-123456789012'
			}

			$mockObject | ConvertTo-NXTInstallerProductCode | Should -Be '87654321432143212143214365870921'
			$mockObject.ProductCode | ConvertTo-NXTInstallerProductCode | Should -Be '87654321432143212143214365870921'
		}
	}
}
