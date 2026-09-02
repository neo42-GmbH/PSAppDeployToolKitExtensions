BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'ConvertFrom-NXTEncodedObject' {
	It 'Should decode objects' {
		$result = ConvertFrom-NXTEncodedObject -InputObject 'q1YqSS0uUbKCULUA' # @{ test = 'test' }
		$result | Should -BeOfType 'System.Management.Automation.PSCustomObject'
		$result.test | Should -Be 'test'
	}

	It 'Should handle arrays' {
		$result = ConvertFrom-NXTEncodedObject -InputObject 'i1YqSS0uUdIBU0ZKsQA=' # @('test', 'test2')
		$result.GetType().BaseType.FullName | Should -Be 'System.Array'
		$result[0] | Should -BeOfType 'System.String'
		$result[0] | Should -Be 'test'
		$result[1] | Should -Be 'test2'
	}

	It 'Should handle value types' {
		$result = ConvertFrom-NXTEncodedObject -InputObject 'UypJLS5RAgA=' # 'test'
		$result | Should -BeOfType 'System.String'
		$result | Should -Be 'test'

		$result = ConvertFrom-NXTEncodedObject -InputObject 'MwIA' # 2
		$result.GetType().FullName | Should -BeIn @('System.Int32', 'System.Int64')
		$result | Should -Be 2

		$result = ConvertFrom-NXTEncodedObject -InputObject 'KykqTQUA' # $true
		$result | Should -BeOfType 'System.Boolean'
		$result | Should -Be $true
	}

	It 'Should throw an error for invalid input' {
		{ ConvertFrom-NXTEncodedObject -InputObject 'invalidBase64' } | Should -Throw
	}

	It 'Should handle pipeline input' {
		'UypJLS5RAgA=' | ConvertFrom-NXTEncodedObject | Should -Be 'test'
	}
}
