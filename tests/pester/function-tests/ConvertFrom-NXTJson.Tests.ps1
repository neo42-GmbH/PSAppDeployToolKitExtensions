BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'ConvertFrom-NXTJson' {
	Context 'When converting simple JSON strings' {
		It 'Should convert a simple JSON object to a PSObject' {
			$json = '{"name": "TestName", "value": 42, "enabled": true}'
			$result = ConvertFrom-NXTJson -InputObject $json
			$result | Should -BeOfType [PSCustomObject]
			$result.name | Should -Be 'TestName'
			$result.value | Should -Be 42
			$result.enabled | Should -BeTrue
		}

		It 'Should convert a JSON array to an array of objects' {
			$json = '[{"id": 1, "name": "Item1"}, {"id": 2, "name": "Item2"}]'
			$result = ConvertFrom-NXTJson -InputObject $json
			$result.GetType().BaseType.Name | Should -Be 'Array'
			$result.Count | Should -Be 2
			$result[0].id | Should -Be 1
			$result[1].name | Should -Be 'Item2'
		}

		It 'Should handle nested JSON objects correctly' {
			$json = '{"person": {"name": "John", "age": 30, "address": {"city": "New York", "zip": "10001"}}}'
			$result = ConvertFrom-NXTJson -InputObject $json
			$result.person.name | Should -Be 'John'
			$result.person.address.city | Should -Be 'New York'
		}
	}

	Context 'When using AsHashTable parameter' {
		It 'Should return a hashtable instead of PSObject' {
			$json = '{"key1": "value1", "key2": "value2"}'
			$result = ConvertFrom-NXTJson -InputObject $json -AsHashTable
			$result | Should -BeOfType [Hashtable]
			$result['key1'] | Should -Be 'value1'
			$result['key2'] | Should -Be 'value2'
		}

		It 'Should convert nested objects to hashtables' {
			$json = '{"main": {"sub": {"value": "nestedValue"}}}'
			$result = ConvertFrom-NXTJson -InputObject $json -AsHashTable
			$result['main'] | Should -BeOfType [Hashtable]
			$result['main']['sub'] | Should -BeOfType [Hashtable]
			$result['main']['sub']['value'] | Should -Be 'nestedValue'
		}
	}

	Context 'When handling special JSON formats' {
		It 'Should handle JSON with comments' {
			$jsonWithComments = @'
{
	// This is a comment
	"key": "value", /* Another comment */
	"key2": 42
}
'@
			$result = ConvertFrom-NXTJson -InputObject $jsonWithComments
			$result.key | Should -Be 'value'
			$result.key2 | Should -Be 42
		}

		It 'Should handle empty JSON objects' {
			$json = '{}'
			$result = ConvertFrom-NXTJson -InputObject $json
			$result | Should -Not -Be $null
			$result.PSObject.Properties | Should -BeNullOrEmpty
		}

		It 'Should not handle empty JSON arrays' {
			$json = '[]'
			ConvertFrom-NXTJson -InputObject $json | Should -BeNullOrEmpty
		}
	}

	Context 'When handling invalid input' {
		It 'Should throw on invalid JSON' {
			{ ConvertFrom-NXTJson -InputObject '{invalid json}' } | Should -Throw
		}

		It 'Should throw on empty or null input' {
			{ ConvertFrom-NXTJson -InputObject $null } | Should -Throw
			{ ConvertFrom-NXTJson -InputObject '' } | Should -Throw
		}
	}

	Context 'When using through pipeline' {
		It 'Should accept JSON string from pipeline' {
			$result = '{"test": "value"}' | ConvertFrom-NXTJson
			$result.test | Should -Be 'value'
		}
	}
}
