BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Expand-NXTVariablesInFile' {
	BeforeAll {
		# Setup common test variables
		[System.String]$testFilePath = [System.IO.Path]::GetTempFileName()
		[System.String]$testVariableValue = 'TestValue'
		[System.String]$testEnvironmentVariableValue = 'EnvTestValue'

		# Setup environment variable for testing
		[System.Environment]::SetEnvironmentVariable('PSADT_TEST_VAR', $testEnvironmentVariableValue, [System.EnvironmentVariableTarget]::Process)
	}

	AfterAll {
		# Clean up test files
		Remove-Item -Path $testFilePath -Force -ErrorAction SilentlyContinue

		# Remove test environment variable
		[System.Environment]::SetEnvironmentVariable('PSADT_TEST_VAR', [System.Management.Automation.Language.NullString]$null, [System.EnvironmentVariableTarget]::Process)
	}

	Context 'When expanding environment variables' {
		It 'Should expand Windows-style environment variables' {
			# Arrange
			[System.String]$testContent = 'Test content with %PSADT_TEST_VAR% environment variable.'
			[System.String]$expectedContent = "Test content with $testEnvironmentVariableValue environment variable."
			Set-Content -Path $testFilePath -Value $testContent -NoNewline

			# Act
			Expand-NXTVariablesInFile -Path $testFilePath

			# Assert
			Get-Content -Raw -Path $testFilePath | Should -Be $expectedContent
		}
	}

	Context 'When expanding PowerShell variables' {
		It 'Should expand PowerShell variables' {
			# Arrange
			$TestPSVar = $testVariableValue
			[System.String]$testContent = 'Test content with $TestPSVar PowerShell variable.'
			[System.String]$expectedContent = "Test content with $testVariableValue PowerShell variable."
			Set-Content -Path $testFilePath -Value $testContent -NoNewline

			# Act
			Expand-NXTVariablesInFile -Path $testFilePath

			# Assert
			Get-Content -Raw -Path $testFilePath | Should -Be $expectedContent
		}

		It 'Should expand PowerShell subexpressions' {
			# Arrange
			[System.String]$testContent = 'Test content with $(2 + 2) PowerShell subexpression.'
			[System.String]$expectedContent = 'Test content with 4 PowerShell subexpression.'
			Set-Content -Path $testFilePath -Value $testContent -NoNewline

			# Act
			Expand-NXTVariablesInFile -Path $testFilePath

			# Assert
			Get-Content -Raw -Path $testFilePath | Should -Be $expectedContent
		}

		It 'Should throw on unsafe operations' {
			# Arrange
			[System.String]$testContent = 'Test content with $((Get-Date).Year) PowerShell subexpression.'
			[System.String]$expectedContent = 'Test content with 4 PowerShell subexpression.'
			Set-Content -Path $testFilePath -Value $testContent -NoNewline

			# Act
			{ Expand-NXTVariablesInFile -Path $testFilePath } | Should -Throw
		}
	}

	Context 'When handling errors' {
		It 'Should log an error when variable expansion fails' {
			# Arrange
			[System.String]$testContent = 'Test content with $(ThrowError) invalid expression.'
			Set-Content -Path $testFilePath -Value $testContent -NoNewline

			# Act
			{ Expand-NXTVariablesInFile -Path $testFilePath } | Should -Throw
		}
	}
}
