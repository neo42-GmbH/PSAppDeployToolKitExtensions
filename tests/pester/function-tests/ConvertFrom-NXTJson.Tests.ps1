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

		It 'Should convert a JSON array to an array of hashtables' {
			$json = '[{"id": 1}, {"id": 2}]'
			$result = ConvertFrom-NXTJson -InputObject $json -AsHashTable
			$result.Count | Should -Be 2
			$result | Should -BeOfType [Hashtable]
			$result[1]['id'] | Should -Be 2
		}

		It 'Should convert a single element JSON array to a hashtable' {
			$json = '[{"id": 1}]'
			$result = ConvertFrom-NXTJson -InputObject $json -AsHashTable
			$result | Should -BeOfType [Hashtable]
			$result['id'] | Should -Be 1
		}

		It 'Should convert nested arrays and keep their values' {
			$json = '{"list": [1, "two", null, [3], {"four": 4}], "empty": []}'
			$result = ConvertFrom-NXTJson -InputObject $json -AsHashTable
			Should -ActualValue $result['list'] -BeOfType [System.Object[]]
			$result['list'].Count | Should -Be 5
			$result['list'][0] | Should -Be 1
			$result['list'][1] | Should -Be 'two'
			$result['list'][2] | Should -BeNullOrEmpty
			Should -ActualValue $result['list'][3] -BeOfType [System.Object[]]
			$result['list'][3].Count | Should -Be 1
			$result['list'][3][0] | Should -Be 3
			$result['list'][4] | Should -BeOfType [Hashtable]
			$result['list'][4]['four'] | Should -Be 4
			Should -ActualValue $result['empty'] -BeOfType [System.Object[]]
			$result['empty'].Count | Should -Be 0
		}

		It 'Should keep keys that only differ in casing' {
			$json = '{"key": "lower", "Key": "upper", "nested": {"a": 1, "A": [{"x": true, "X": false}]}}'
			$result = ConvertFrom-NXTJson -InputObject $json -AsHashTable
			$result.Count | Should -Be 3
			$result['key'] | Should -BeExactly 'lower'
			$result['Key'] | Should -BeExactly 'upper'
			$result['nested']['a'] | Should -Be 1
			$result['nested']['A'][0]['x'] | Should -BeTrue
			$result['nested']['A'][0]['X'] | Should -BeFalse
		}

		It 'Should return case-sensitive hashtables' {
			$result = ConvertFrom-NXTJson -InputObject '{"key": "value", "nested": {"key": "value"}}' -AsHashTable
			$result.ContainsKey('KEY') | Should -BeFalse
			$result['nested'].ContainsKey('KEY') | Should -BeFalse
		}

		It 'Should handle empty keys' {
			$result = ConvertFrom-NXTJson -InputObject '{"": "value"}' -AsHashTable
			$result[''] | Should -Be 'value'
		}

		It 'Should handle JSON with comments' {
			$jsonWithComments = @'
{
	"key": "value // no comment" /* comment */,
	"Key": 42 // comment
}
'@
			$result = ConvertFrom-NXTJson -InputObject $jsonWithComments -AsHashTable
			$result['key'] | Should -Be 'value // no comment'
			$result['Key'] | Should -Be 42
		}

		It 'Should keep the value types of ConvertFrom-Json' {
			$json = '{"int": 1, "long": 3000000000, "decimal": 1.5, "double": 1e3, "bool": true, "null": null}'
			$result = ConvertFrom-NXTJson -InputObject $json -AsHashTable
			$expected = ConvertFrom-NXTJson -InputObject $json
			foreach ($key in 'int', 'long', 'decimal', 'double', 'bool') {
				$result[$key] | Should -BeOfType $expected.$key.GetType()
				$result[$key] | Should -Be $expected.$key
			}
			$result.ContainsKey('null') | Should -BeTrue
			$result['null'] | Should -BeNullOrEmpty
		}

		It 'Should return empty when no data is provided' {
			ConvertFrom-NXTJson -InputObject '' -AsHashTable | Should -BeNullOrEmpty
			ConvertFrom-NXTJson -InputObject '[]' -AsHashTable | Should -BeNullOrEmpty
		}

		It 'Should throw on invalid JSON' {
			{ ConvertFrom-NXTJson -InputObject '{invalid json}' -AsHashTable } | Should -Throw
		}
	}

	Context 'When converting JSON with keys that only differ in casing' {
		It 'Should throw without AsHashTable parameter' {
			{ ConvertFrom-NXTJson -InputObject '{"key": "lower", "Key": "upper"}' } | Should -Throw
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

		It 'Should return empty when no data is provided' {
			ConvertFrom-NXTJson -InputObject $null | Should -BeNullOrEmpty
			ConvertFrom-NXTJson -InputObject '' | Should -BeNullOrEmpty
		}
	}

	Context 'When using through pipeline' {
		It 'Should accept JSON string from pipeline' {
			$result = '{"test": "value"}' | ConvertFrom-NXTJson
			$result.test | Should -Be 'value'
		}
	}
}
