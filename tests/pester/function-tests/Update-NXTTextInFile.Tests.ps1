BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Update-NXTTextInFile' {
	BeforeAll {
		[System.String]$content = "Hello World. hello world. HELLO WORLD.`r`nSpecial: (a+b)*[c] costs `$5. 🚀äß"

		# Files
		[System.String]$rootPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName())
		[System.String]$filePath = [System.IO.Path]::Combine($rootPath, 'file.txt')
		[System.String]$filterFilePath1 = [System.IO.Path]::Combine($rootPath, 'filter_a1.txt')
		[System.String]$filterFilePath2 = [System.IO.Path]::Combine($rootPath, 'filter_a2.txt')
		[System.String]$filterFilePath3 = [System.IO.Path]::Combine($rootPath, 'filter_b1.txt')
		[System.String]$folderPath = [System.IO.Path]::Combine($rootPath, 'folder')
		[System.String]$filePathNotExisting = [System.IO.Path]::Combine($rootPath, 'notExisting.txt')
		function New-TestFile {
			param (
				[System.Text.Encoding]$Encoding = [System.Text.Encoding]::UTF8
			)
			Remove-TestFile
			$null = [System.IO.Directory]::CreateDirectory($folderPath)
			foreach ($path in @($filePath, $filterFilePath1, $filterFilePath2, $filterFilePath3)) {
				[System.IO.File]::WriteAllText($path, $content, $Encoding)
			}
		}
		function Remove-TestFile {
			if ([System.IO.Directory]::Exists($rootPath)) {
				foreach ($file in [System.IO.Directory]::GetFiles($rootPath)) { [System.IO.File]::SetAttributes($file, [System.IO.FileAttributes]::Normal) }
			}
			Remove-Item -LiteralPath $rootPath -Recurse -Force -ErrorAction SilentlyContinue
		}
	}

	AfterAll {
		Remove-TestFile
	}

	Context 'When using an invalid path' {
		BeforeAll {
			New-TestFile
		}

		It 'Should throw an error with a non-existing path' {
			{ Update-NXTTextInFile -Path $filePathNotExisting -Query 'Hello' -Value 'Hi' } | Should -Throw
			{ Update-NXTTextInFile -Path $filePathNotExisting, $filePath -Query 'Hello' -Value 'Hi' } | Should -Throw
			[System.IO.File]::Exists($filePathNotExisting) | Should -BeFalse
		}

		It 'Should throw an error with null or empty path' {
			{ Update-NXTTextInFile -Path $null -Query 'Hello' -Value 'Hi' } | Should -Throw
			{ Update-NXTTextInFile -Path '' -Query 'Hello' -Value 'Hi' } | Should -Throw
			{ Update-NXTTextInFile -Path $null, $filePath -Query 'Hello' -Value 'Hi' } | Should -Throw
			{ Update-NXTTextInFile -Path '', $filePath -Query 'Hello' -Value 'Hi' } | Should -Throw
			[System.IO.File]::ReadAllText($filePath) | Should -Be $content
		}

		It 'Should throw an error with a wrong data type for path' {
			{ Update-NXTTextInFile -Path 123 -Query 'Hello' -Value 'Hi' } | Should -Throw
		}

		It 'Should not change a folder' {
			{ Update-NXTTextInFile -Path $folderPath -Query 'Hello' -Value 'Hi' } | Should -Not -Throw
			[System.IO.Directory]::Exists($folderPath) | Should -BeTrue
		}
	}

	Context 'When using an invalid literal path' {
		BeforeAll {
			New-TestFile
		}

		It 'Should throw an error with a literal path including wildcards' {
			{ Update-NXTTextInFile -LiteralPath "$rootPath\filter_a*" -Query 'Hello' -Value 'Hi' } | Should -Throw
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -Be $content
		}

		It 'Should throw an error with a non-existing path' {
			{ Update-NXTTextInFile -LiteralPath $filePathNotExisting -Query 'Hello' -Value 'Hi' } | Should -Throw
		}

		It 'Should throw an error with null or empty path' {
			{ Update-NXTTextInFile -LiteralPath $null -Query 'Hello' -Value 'Hi' } | Should -Throw
			{ Update-NXTTextInFile -LiteralPath '' -Query 'Hello' -Value 'Hi' } | Should -Throw
		}
	}

	Context 'When replacing text' {
		BeforeEach {
			New-TestFile
		}

		It 'Should replace all occurrences case-insensitive by default' {
			Update-NXTTextInFile -Path $filePath -Query 'hello' -Value 'Hi' | Should -BeNullOrEmpty
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content.Replace('Hello', 'Hi').Replace('hello', 'Hi').Replace('HELLO', 'Hi')
		}

		It 'Should only replace matching case with CaseSensitive' {
			Update-NXTTextInFile -Path $filePath -Query 'hello' -Value 'Hi' -CaseSensitive
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content.Replace('hello', 'Hi')
		}

		It 'Should not change the file when the query is not found' {
			Update-NXTTextInFile -Path $filePath -Query 'NotExistingText' -Value 'Hi'
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content
		}

		It 'Should not add a new line' {
			Update-NXTTextInFile -Path $filePath -Query 'NotExistingText' -Value 'Hi'
			[System.IO.File]::ReadAllText($filePath).EndsWith([System.Environment]::NewLine) | Should -BeFalse
		}

		It 'Should replace text across lines' {
			Update-NXTTextInFile -Path $filePath -Query "WORLD.`r`nSpecial" -Value 'X'
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content.Replace("WORLD.`r`nSpecial", 'X')
		}

		It 'Should remove text with an empty value' {
			Update-NXTTextInFile -Path $filePath -Query 'Hello World. ' -Value '' -CaseSensitive
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content.Replace('Hello World. ', '')
		}

		It 'Should treat special characters in query and value literally' {
			Update-NXTTextInFile -Path $filePath -Query '(a+b)*[c] costs $5.' -Value '$1 $$ $0 \n'
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content.Replace('(a+b)*[c] costs $5.', '$1 $$ $0 \n')
		}

		It 'Should replace unicode characters' {
			Update-NXTTextInFile -Path $filePath -Query '🚀äß' -Value 'ÖÜ🎉'
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content.Replace('🚀äß', 'ÖÜ🎉')
		}

		It 'Should accept positional parameters' {
			Update-NXTTextInFile $filePath 'Hello' 'Hi' -CaseSensitive
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content.Replace('Hello', 'Hi')
		}

		It 'Should accept the parameter aliases' {
			Update-NXTTextInFile -Path $filePath -SearchString 'Hello' -ReplaceString 'Hi' -CaseSensitive
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content.Replace('Hello', 'Hi')
		}

		It 'Should accept the value as pipeline input' {
			'Hi' | Update-NXTTextInFile -Path $filePath -Query 'Hello' -CaseSensitive
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content.Replace('Hello', 'Hi')
		}
	}

	Context 'When using regular expressions' {
		BeforeEach {
			New-TestFile
		}

		It 'Should replace a regex pattern' {
			Update-NXTTextInFile -Path $filePath -Query 'h\w+o' -Value 'Hi' -Regex
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content.Replace('Hello', 'Hi').Replace('hello', 'Hi').Replace('HELLO', 'Hi')
		}

		It 'Should replace a regex pattern case-sensitive' {
			Update-NXTTextInFile -Path $filePath -Query 'h\w+o' -Value 'Hi' -Regex -CaseSensitive
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content.Replace('hello', 'Hi')
		}

		It 'Should support substitutions in the value' {
			Update-NXTTextInFile -Path $filePath -Query '(Hello) (World)' -Value '$2 $1' -Regex -CaseSensitive
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content.Replace('Hello World', 'World Hello')
		}

		It 'Should throw an error with an invalid regex pattern' {
			{ Update-NXTTextInFile -Path $filePath -Query '(Hello' -Value 'Hi' -Regex } | Should -Throw
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content
		}
	}

	Context 'When using count' {
		BeforeEach {
			New-TestFile
		}

		It 'Should replace only the first occurrence' {
			Update-NXTTextInFile -Path $filePath -Query 'world' -Value 'Earth' -Count 1
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly "Hello Earth. hello world. HELLO WORLD.`r`nSpecial: (a+b)*[c] costs `$5. 🚀äß"
		}

		It 'Should replace only the given number of occurrences' {
			Update-NXTTextInFile -Path $filePath -Query 'world' -Value 'Earth' -Count 2
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly "Hello Earth. hello Earth. HELLO WORLD.`r`nSpecial: (a+b)*[c] costs `$5. 🚀äß"
		}

		It 'Should replace all occurrences when the count exceeds the occurrences' {
			Update-NXTTextInFile -Path $filePath -Query 'world' -Value 'Earth' -Count 100
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content.Replace('World', 'Earth').Replace('world', 'Earth').Replace('WORLD', 'Earth')
		}

		It 'Should not replace anything with count 0' {
			Update-NXTTextInFile -Path $filePath -Query 'world' -Value 'Earth' -Count 0
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content
		}

		It 'Should throw an error with an invalid count' {
			{ Update-NXTTextInFile -Path $filePath -Query 'world' -Value 'Earth' -Count -1 } | Should -Throw
			{ Update-NXTTextInFile -Path $filePath -Query 'world' -Value 'Earth' -Count 'Invalid' } | Should -Throw
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content
		}
	}

	Context 'When using valid paths' {
		BeforeEach {
			New-TestFile
		}

		It 'Should update files with a path including wildcards' {
			Update-NXTTextInFile -Path "$rootPath\filter_a*" -Query 'Hello' -Value 'Hi' -CaseSensitive
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -BeExactly $content.Replace('Hello', 'Hi')
			[System.IO.File]::ReadAllText($filterFilePath2) | Should -BeExactly $content.Replace('Hello', 'Hi')
			[System.IO.File]::ReadAllText($filterFilePath3) | Should -BeExactly $content
		}

		It 'Should update multiple files' {
			Update-NXTTextInFile -Path $filterFilePath1, $filterFilePath3 -Query 'Hello' -Value 'Hi' -CaseSensitive
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -BeExactly $content.Replace('Hello', 'Hi')
			[System.IO.File]::ReadAllText($filterFilePath2) | Should -BeExactly $content
			[System.IO.File]::ReadAllText($filterFilePath3) | Should -BeExactly $content.Replace('Hello', 'Hi')
		}

		It 'Should update a file with a literal path' {
			Update-NXTTextInFile -LiteralPath $filePath -Query 'Hello' -Value 'Hi' -CaseSensitive
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content.Replace('Hello', 'Hi')
		}

		It 'Should update files with pipeline input' {
			Get-Item -Path "$rootPath\filter_a*" | Update-NXTTextInFile -Query 'Hello' -Value 'Hi' -CaseSensitive
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -BeExactly $content.Replace('Hello', 'Hi')
			[System.IO.File]::ReadAllText($filterFilePath2) | Should -BeExactly $content.Replace('Hello', 'Hi')
			[System.IO.File]::ReadAllText($filterFilePath3) | Should -BeExactly $content
		}
	}

	Context 'When using filter parameters' {
		BeforeEach {
			New-TestFile
		}

		It 'Should use Filter parameter' {
			Update-NXTTextInFile -Path "$rootPath\*" -Filter 'filter_a*' -Query 'Hello' -Value 'Hi' -CaseSensitive
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -BeExactly $content.Replace('Hello', 'Hi')
			[System.IO.File]::ReadAllText($filterFilePath2) | Should -BeExactly $content.Replace('Hello', 'Hi')
			[System.IO.File]::ReadAllText($filterFilePath3) | Should -BeExactly $content
		}

		It 'Should use Include parameter' {
			Update-NXTTextInFile -Path "$rootPath\*" -Include 'filter_a1*', 'filter_b*' -Query 'Hello' -Value 'Hi' -CaseSensitive
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -BeExactly $content.Replace('Hello', 'Hi')
			[System.IO.File]::ReadAllText($filterFilePath2) | Should -BeExactly $content
			[System.IO.File]::ReadAllText($filterFilePath3) | Should -BeExactly $content.Replace('Hello', 'Hi')
		}

		It 'Should use Exclude parameter' {
			Update-NXTTextInFile -Path "$rootPath\*" -Exclude 'filter_a*', 'file.txt' -Query 'Hello' -Value 'Hi' -CaseSensitive
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -BeExactly $content
			[System.IO.File]::ReadAllText($filterFilePath2) | Should -BeExactly $content
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content
			[System.IO.File]::ReadAllText($filterFilePath3) | Should -BeExactly $content.Replace('Hello', 'Hi')
		}

		It 'Should not change anything with an ineffective filter' {
			Update-NXTTextInFile -Path "$rootPath\*" -Filter 'IneffectiveFilter' -Query 'Hello' -Value 'Hi'
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -BeExactly $content
		}

		It 'Should throw an error with null or empty filters' {
			{ Update-NXTTextInFile -Path "$rootPath\*" -Filter $null -Query 'Hello' -Value 'Hi' } | Should -Throw
			{ Update-NXTTextInFile -Path "$rootPath\*" -Filter '' -Query 'Hello' -Value 'Hi' } | Should -Throw
			{ Update-NXTTextInFile -Path "$rootPath\*" -Include $null -Query 'Hello' -Value 'Hi' } | Should -Throw
			{ Update-NXTTextInFile -Path "$rootPath\*" -Include '' -Query 'Hello' -Value 'Hi' } | Should -Throw
			{ Update-NXTTextInFile -Path "$rootPath\*" -Exclude $null -Query 'Hello' -Value 'Hi' } | Should -Throw
			{ Update-NXTTextInFile -Path "$rootPath\*" -Exclude '' -Query 'Hello' -Value 'Hi' } | Should -Throw
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -BeExactly $content
		}
	}

	Context 'When using invalid query or value' {
		BeforeEach {
			New-TestFile
		}

		It 'Should throw an error with null or empty query' {
			{ Update-NXTTextInFile -Path $filePath -Query $null -Value 'Hi' } | Should -Throw
			{ Update-NXTTextInFile -Path $filePath -Query '' -Value 'Hi' } | Should -Throw
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content
		}

		It 'Should treat a null value as empty string' {
			Update-NXTTextInFile -Path $filePath -Query 'Hello ' -Value $null -CaseSensitive
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content.Replace('Hello ', '')
		}
	}

	Context 'When using encodings' {
		It 'Should keep the detected encoding' {
			New-TestFile -Encoding ([System.Text.Encoding]::BigEndianUnicode)
			Update-NXTTextInFile -Path $filePath -Query 'Hello' -Value 'Hi' -CaseSensitive
			Get-NXTFileEncoding -Path $filePath | Should -Be ([System.Text.Encoding]::BigEndianUnicode)
			[System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::BigEndianUnicode) | Should -BeExactly $content.Replace('Hello', 'Hi')
		}

		It 'Should use the specified encoding' {
			New-TestFile -Encoding ([System.Text.Encoding]::Unicode)
			Update-NXTTextInFile -Path $filePath -Query 'Hello' -Value 'Hi' -CaseSensitive -Encoding Unicode
			[System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::Unicode) | Should -BeExactly $content.Replace('Hello', 'Hi')
		}

		It 'Should throw an error with an invalid encoding' {
			New-TestFile
			{ Update-NXTTextInFile -Path $filePath -Query 'Hello' -Value 'Hi' -Encoding 'InvalidEncoding' } | Should -Throw
			{ Update-NXTTextInFile -Path $filePath -Query 'Hello' -Value 'Hi' -Encoding $null } | Should -Throw
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content
		}
	}

	Context 'When the file has special attributes' {
		BeforeEach {
			New-TestFile
		}

		It 'Should throw an error when the file is read-only' {
			[System.IO.File]::SetAttributes($filePath, [System.IO.FileAttributes]::ReadOnly)
			{ Update-NXTTextInFile -Path $filePath -Query 'Hello' -Value 'Hi' } | Should -Throw
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content
		}

		It 'Should update a read-only file with Force and keep the attribute' {
			[System.IO.File]::SetAttributes($filePath, [System.IO.FileAttributes]::ReadOnly)
			Update-NXTTextInFile -Path $filePath -Query 'Hello' -Value 'Hi' -CaseSensitive -Force
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content.Replace('Hello', 'Hi')
			[System.IO.File]::GetAttributes($filePath).HasFlag([System.IO.FileAttributes]::ReadOnly) | Should -BeTrue
		}

		It 'Should throw an error when the file is hidden' {
			[System.IO.File]::SetAttributes($filePath, [System.IO.FileAttributes]::Hidden)
			{ Update-NXTTextInFile -Path $filePath -Query 'Hello' -Value 'Hi' } | Should -Throw
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content
		}

		It 'Should update a hidden file with Force and keep the attribute' {
			[System.IO.File]::SetAttributes($filePath, [System.IO.FileAttributes]::Hidden)
			Update-NXTTextInFile -Path $filePath -Query 'Hello' -Value 'Hi' -CaseSensitive -Force
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content.Replace('Hello', 'Hi')
			[System.IO.File]::GetAttributes($filePath).HasFlag([System.IO.FileAttributes]::Hidden) | Should -BeTrue
		}
	}

	Context 'When using WhatIf' {
		BeforeAll {
			New-TestFile
		}

		It 'Should not change the file' {
			# The global preference variable is used, because the -WhatIf switch fails in PSADT 4.1 for callers outside of the module
			try {
				$global:WhatIfPreference = $true
				Update-NXTTextInFile -Path $filePath -Query 'Hello' -Value 'Hi'
			}
			finally {
				$global:WhatIfPreference = $false
			}
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $content
		}
	}
}
