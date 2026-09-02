BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'ConvertTo-NXTPsArgumentString' {
	Context 'When converting simple key-value pairs' {
		It 'Should convert a hashtable with string values to a valid argument string' {
			# Arrange
			[System.Collections.Hashtable]$inputHashtable = @{
				'Key1' = 'Value1'
				'Key2' = 'Value2'
			}

			# Act
			[System.String]$result = ConvertTo-NXTPsArgumentString -InputObject $inputHashtable

			# Assert - The order of keys is not guaranteed in hashtables
			$result | Should -Match '-Key1'
			$result | Should -Match 'Value1'
			$result | Should -Match '-Key2'
			$result | Should -Match 'Value2'
		}

		It 'Should handle numeric values correctly' {
			# Arrange
			[System.Collections.Hashtable]$inputHashtable = @{
				'IntValue'    = 42
				'DoubleValue' = 3.14
			}

			# Act
			[System.String]$result = ConvertTo-NXTPsArgumentString -InputObject $inputHashtable

			# Assert
			$result | Should -Match '-IntValue:42'
			$result | Should -Match '-DoubleValue:3.14'
		}

		It 'Should handle boolean and switch values correctly' {
			# Arrange
			[System.Collections.Hashtable]$inputHashtable = @{
				'TrueFlag'   = $true
				'FalseFlag'  = $false
				'SwitchFlag' = [System.Management.Automation.SwitchParameter]$true
			}

			# Act
			[System.String]$result = ConvertTo-NXTPsArgumentString -InputObject $inputHashtable

			# Assert
			$result | Should -Match '-TrueFlag:\$true'
			$result | Should -Match '-FalseFlag:\$false'
			$result | Should -Match '-SwitchFlag:\$true'
		}

		It 'Should handle null values correctly' {
			# Arrange
			[System.Collections.Hashtable]$inputHashtable = @{
				'NullValue' = $null
			}

			# Act
			[System.String]$result = ConvertTo-NXTPsArgumentString -InputObject $inputHashtable

			# Assert
			$result | Should -Be '-NullValue:$null'
		}
	}

	Context 'When converting complex data types' {
		It 'Should handle DateTime values correctly' {
			# Arrange
			[System.DateTime]$testDate = [System.DateTime]::Parse('2025-06-03T12:00:00Z')
			[System.Collections.Hashtable]$inputHashtable = @{
				'Date' = $testDate
			}

			# Act
			[System.String]$result = ConvertTo-NXTPsArgumentString -InputObject $inputHashtable

			# Assert - Using the UniversalSortableDateTimePattern format
			$result | Should -Match '-Date:"[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}Z"'
		}

		It 'Should handle Enum values based on UseEnumValue parameter' {
			# Arrange
			[System.Collections.Hashtable]$inputHashtable = @{
				'DayOfWeek' = [System.DayOfWeek]::Monday
			}

			# Act - Default behavior (enum name)
			[System.String]$resultName = ConvertTo-NXTPsArgumentString -InputObject $inputHashtable
			# Act - Using enum value
			[System.String]$resultValue = ConvertTo-NXTPsArgumentString -InputObject $inputHashtable -UseEnumValue

			# Assert
			$resultName | Should -Be '-DayOfWeek:"Monday"'
			$resultValue | Should -Be '-DayOfWeek:1'
		}

		It 'Should handle nested dictionaries correctly' {
			# Arrange
			[System.Collections.Hashtable]$inputHashtable = @{
				'NestedDict' = @{
					'SubKey1' = 'SubValue1'
					'SubKey2' = 'SubValue2'
				}
			}

			# Act
			[System.String]$result = ConvertTo-NXTPsArgumentString -InputObject $inputHashtable

			# Assert - The order of nested keys is not guaranteed
			$result | Should -Match '-NestedDict:@{'
			$result | Should -Match 'SubKey1'
			$result | Should -Match 'SubKey2'
			$result | Should -Match '="SubValue1"'
			$result | Should -Match '="SubValue2"'
		}

		It 'Should handle arrays correctly' {
			# Arrange
			[System.Collections.Hashtable]$inputHashtable = @{
				'ArrayValue' = @('Item1', 'Item2', 'Item3')
			}

			# Act
			[System.String]$result = ConvertTo-NXTPsArgumentString -InputObject $inputHashtable

			# Assert
			$result | Should -Match '-ArrayValue:@\("Item1","Item2","Item3"\)'
		}
	}

	Context 'When handling string escaping' {
		It 'Should properly escape strings with delimiters' {
			# Arrange
			[System.Collections.Hashtable]$inputHashtable = @{
				'EscapedString' = 'Value with "escape quotes" inside'
			}

			# Act
			[System.String]$result = ConvertTo-NXTPsArgumentString -InputObject $inputHashtable

			# Assert - Default behavior with backtick escaping
			$result | Should -Be '-EscapedString:"Value with `"escape quotes`" inside"'
		}

		It 'Should use custom string delimiter and replacement when specified' {
			# Arrange
			[System.Collections.Hashtable]$inputHashtable = @{
				'CustomEscaped' = "Value with 'apostrophes' inside"
			}

			# Act
			[System.String]$result = ConvertTo-NXTPsArgumentString -InputObject $inputHashtable -StringDelimiter "'" -StringDelimiterReplacement '"'

			# Assert
			$result | Should -Match '-CustomEscaped:''Value with "apostrophes" inside'''
		}
	}

	Context 'When using with pipeline input' {
		It 'Should accept dictionary objects from pipeline' {
			# Arrange
			[System.Collections.Hashtable]$inputHashtable = @{
				'PipelineKey' = 'PipelineValue'
			}

			# Act
			[System.String]$result = $inputHashtable | ConvertTo-NXTPsArgumentString

			# Assert
			$result | Should -Be '-PipelineKey:"PipelineValue"'
		}

		It 'Should handle PSBoundParameters via pipeline' {
			# Arrange & Act
			function Test-PipelineArguments {
				param (
					[System.String]$Param1,
					[System.Int32]$Param2
				)

				$PSBoundParameters | ConvertTo-NXTPsArgumentString
			}

			[System.String]$result = Test-PipelineArguments -Param1 'Test' -Param2 42

			# Assert
			$result | Should -Match '-Param1:"Test"'
			$result | Should -Match '-Param2:42'
		}
	}
}
