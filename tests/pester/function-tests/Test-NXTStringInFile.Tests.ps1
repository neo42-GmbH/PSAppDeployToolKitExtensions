BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Test-NXTStringInFile' {
	BeforeAll {
		# Create test files
		$testFile = [System.IO.Path]::GetTempFileName()
		$emptyFile = [System.IO.Path]::GetTempFileName()
		$specialCharsFile = [System.IO.Path]::GetTempFileName()
		$multilineFile = [System.IO.Path]::GetTempFileName()
		$hiddenFile = [System.IO.Path]::GetTempFileName()

		# Create file content
		$testContent = "This is a test file with some content. Line 1.`r`nHello World on Line 2.`r`nFinal line of the file."
		$specialContent = "Special characters: @#$%^&*()_+`r`nUnicode chars: äöü 你好 こんにちは"
		$multilineContent = "Line 1`r`nLine 2`r`nLine 3`r`nLine 4`r`nLine 5"

		# Write content to files
		Set-Content -Path $testFile -Value $testContent -Encoding UTF8 -NoNewline
		New-Item -Path $emptyFile -ItemType File -Force
		Set-Content -Path $specialCharsFile -Value $specialContent -Encoding UTF8 -NoNewline
		Set-Content -Path $multilineFile -Value $multilineContent -Encoding UTF8 -NoNewline
		Set-Content -Path $hiddenFile -Value 'This is hidden content' -Encoding UTF8 -NoNewline

		# Set hidden attribute
		Set-ItemProperty -Path $hiddenFile -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)
	}

	AfterAll {
		# Clean up test files
		Remove-Item -Path $testFile -ErrorAction SilentlyContinue
		Remove-Item -Path $emptyFile -ErrorAction SilentlyContinue
		Remove-Item -Path $specialCharsFile -ErrorAction SilentlyContinue
		Remove-Item -Path $multilineFile -ErrorAction SilentlyContinue

		# Need to use -Force for hidden files
		Remove-Item -Path $hiddenFile -Force -ErrorAction SilentlyContinue
	}

	Context 'When searching for exact strings' {
		It 'Should find exact match' {
			Test-NXTStringInFile -Path $testFile -Query 'Hello World on Line 2.' -PatternType Contains | Should -BeTrue
		}

		It 'Should not find string with different case when case sensitive' {
			Test-NXTStringInFile -Path $testFile -Query 'HELLO WORLD' -PatternType Contains -CaseSensitive | Should -BeFalse
		}

		It 'Should find string with different case when not case sensitive' {
			Test-NXTStringInFile -Path $testFile -Query 'hello world' -PatternType Contains | Should -BeTrue
		}

		It 'Should return false for non-existent string' {
			Test-NXTStringInFile -Path $testFile -Query 'This string does not exist' -PatternType Contains | Should -BeFalse
		}
	}

	Context 'When using wildcard patterns' {
		It 'Should match wildcard pattern' {
			Test-NXTStringInFile -Path $testFile -Query '*Hello World*' -PatternType Wildcard | Should -BeTrue
		}

		It 'Should match beginning of string with wildcard' {
			Test-NXTStringInFile -Path $testFile -Query 'This is*' -PatternType Wildcard | Should -BeTrue
		}

		It 'Should match end of string with wildcard' {
			Test-NXTStringInFile -Path $testFile -Query '*Final line of the file.' -PatternType Wildcard | Should -BeTrue
		}

		It 'Should not match invalid wildcard pattern' {
			Test-NXTStringInFile -Path $testFile -Query '*nonexistent*pattern*' -PatternType Wildcard | Should -BeFalse
		}
	}

	Context 'When using regex patterns' {
		It 'Should match regex pattern' {
			Test-NXTStringInFile -Path $testFile -Query 'Hello\s+World' -PatternType Regex | Should -BeTrue
		}

		It 'Should match multiline regex' {
			Test-NXTStringInFile -Path $testFile -Query 'Line 1\.\r\nHello' -PatternType Regex | Should -BeTrue
		}

		It 'Should match regex with quantifiers' {
			Test-NXTStringInFile -Path $multilineFile -Query 'Line \d{1,5}' -PatternType Regex | Should -BeTrue
		}
	}

	Context 'When handling special cases' {
		It 'Should find string with special characters' {
			Test-NXTStringInFile -Path $specialCharsFile -Query '*@#$%^&*()_+*' -PatternType Wildcard | Should -BeTrue
		}

		It 'Should find string with Unicode characters' {
			Test-NXTStringInFile -Path $specialCharsFile -Query '*äöü 你好*' -PatternType Wildcard | Should -BeTrue
		}

		It 'Should return false for empty files' {
			Test-NXTStringInFile -Path $emptyFile -Query 'any content' -PatternType Contains | Should -BeFalse
		}

		It 'Should find content in hidden files when Force is used' {
			Test-NXTStringInFile -Path $hiddenFile -Query 'hidden content' -PatternType Contains -Force | Should -BeTrue
		}
	}

	Context 'When using different path parameters' {
		It 'Should accept literal path' {
			Test-NXTStringInFile -LiteralPath $testFile -Query 'Hello World' -PatternType Contains | Should -BeTrue
		}

		It 'Should accept file objects from pipeline' {
			$fileObject = Get-Item -Path $testFile
			$fileObject | Test-NXTStringInFile -Query 'Hello World' -PatternType Contains | Should -BeTrue
		}
	}
}
