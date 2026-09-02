BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'ConvertTo-NXTEncodedObject' {
	It 'Should convert a array to a base64 encoded string' {
		ConvertTo-NXTEncodedObject -InputObject @('a', 'b') | Should -Be 'i1ZKVNJRSlKKBQA='
	}

	It 'Should convert a hashtable to a base64 encoded string' {
		ConvertTo-NXTEncodedObject -InputObject @{ 'a' = 'b' } | Should -Be 'q1ZKVLJSSlKqBQA='
	}

	It 'Shoud convert value types to base64 encoded strings' {
		ConvertTo-NXTEncodedObject -InputObject 'test' | Should -Be 'UypJLS5RAgA='
		ConvertTo-NXTEncodedObject -InputObject 2 | Should -Be 'MwIA'
		ConvertTo-NXTEncodedObject -InputObject $true | Should -Be 'KykqTQUA'
	}

	It 'Should handle pipeline input' {
		@{ 'a' = 'b' } | ConvertTo-NXTEncodedObject | Should -Be 'q1ZKVLJSSlKqBQA='
	}
}
