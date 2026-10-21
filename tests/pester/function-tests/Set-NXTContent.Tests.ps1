BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Set-NXTContent' {
	BeforeAll {
		[System.String]$content = 'This is a test file. 🚀äß$'
		[System.String]$oldContent = 'This is the old content. 🚀äß$'
		[System.String]$newLine = [System.Environment]::NewLine

		# Files
		[System.String]$rootPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName())
		[System.String]$filePath = [System.IO.Path]::Combine($rootPath, 'file.txt')
		[System.String]$filterFilePath1 = [System.IO.Path]::Combine($rootPath, 'filter_a1.txt')
		[System.String]$filterFilePath2 = [System.IO.Path]::Combine($rootPath, 'filter_a2.txt')
		[System.String]$filterFilePath3 = [System.IO.Path]::Combine($rootPath, 'filter_b1.txt')
		[System.String]$folderPath = [System.IO.Path]::Combine($rootPath, 'folder')
		[System.String]$filePathInvalidFolder = [System.IO.Path]::Combine($rootPath, 'invalid', 'file.txt')
		function New-TestFile {
			Remove-TestFile
			$null = [System.IO.Directory]::CreateDirectory($folderPath)
			foreach ($path in @($filterFilePath1, $filterFilePath2, $filterFilePath3)) {
				[System.IO.File]::WriteAllText($path, $oldContent, [System.Text.Encoding]::UTF8)
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

		It 'Should throw an error with null or empty path' {
			{ Set-NXTContent -Path $null -Value $content } | Should -Throw
			{ Set-NXTContent -Path '' -Value $content } | Should -Throw
			{ Set-NXTContent -Path $null, $filePath -Value $content } | Should -Throw
			{ Set-NXTContent -Path '', $filePath -Value $content } | Should -Throw
		}

		It 'Should not create the folder structure' {
			{ Set-NXTContent -Path $filePathInvalidFolder -Value $content } | Should -Throw
			[System.IO.File]::Exists($filePathInvalidFolder) | Should -BeFalse
		}

		It 'Should not write to a folder' {
			Set-NXTContent -Path $folderPath -Value $content
			[System.IO.Directory]::Exists($folderPath) | Should -BeTrue
		}

		It 'Should not create files for a path with unresolved wildcards' {
			Set-NXTContent -Path "$rootPath\notExisting*.txt" -Value $content
			[System.IO.Directory]::GetFiles($rootPath, 'notExisting*').Count | Should -Be 0
		}
	}

	Context 'When using an invalid literal path' {
		BeforeAll {
			New-TestFile
		}

		It 'Should throw an error with null or empty path' {
			{ Set-NXTContent -LiteralPath $null -Value $content } | Should -Throw
			{ Set-NXTContent -LiteralPath '' -Value $content } | Should -Throw
		}

		It 'Should throw an error with a literal path including wildcards' {
			{ Set-NXTContent -LiteralPath "$rootPath\filter_a*" -Value $content } | Should -Throw
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -Be $oldContent
		}
	}

	Context 'When creating a new file' {
		BeforeEach {
			New-TestFile
		}

		It 'Should create a new file with the specified encoding' {
			Set-NXTContent -Path $filePath -Value $content -Encoding BigEndianUnicodeWithBOM -NoNewLine | Should -BeNullOrEmpty
			[System.IO.File]::Exists($filePath) | Should -BeTrue
			[System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::BigEndianUnicode) | Should -Be $content
			Get-NXTFileEncoding -Path $filePath | Should -Be ([System.Text.Encoding]::BigEndianUnicode)
		}

		It 'Should create a new file with the default encoding' {
			Set-NXTContent -Path $filePath -Value $content -NoNewLine
			[System.IO.File]::ReadAllText($filePath, $OutputEncoding) | Should -Be $content
		}

		It 'Should add a new line when -NoNewLine is not specified' {
			Set-NXTContent -Path $filePath -Value $content -Encoding UTF8
			[System.IO.File]::ReadAllText($filePath) | Should -Be "$content$newLine"
		}

		It 'Should join multiple values with new lines' {
			Set-NXTContent -Path $filePath -Value $content, $content -Encoding UTF8 -NoNewLine
			[System.IO.File]::ReadAllText($filePath) | Should -Be "$content$newLine$content"
		}

		It 'Should join multiple values with new lines and add a trailing new line' {
			Set-NXTContent -Path $filePath -Value $content, $content -Encoding UTF8
			[System.IO.File]::ReadAllText($filePath) | Should -Be "$content$newLine$content$newLine"
		}

		It 'Should accept positional parameters' {
			Set-NXTContent $filePath $content -Encoding UTF8 -NoNewLine
			[System.IO.File]::ReadAllText($filePath) | Should -Be $content
		}
	}

	Context 'When overwriting an existing file' {
		BeforeEach {
			New-TestFile
			[System.IO.File]::WriteAllText($filePath, $oldContent, [System.Text.Encoding]::BigEndianUnicode)
		}

		It 'Should replace the content' {
			Set-NXTContent -Path $filePath -Value $content -NoNewLine | Should -BeNullOrEmpty
			[System.IO.File]::ReadAllText($filePath) | Should -Be $content
		}

		It 'Should keep the detected encoding when no encoding is specified' {
			Set-NXTContent -Path $filePath -Value $content -NoNewLine
			Get-NXTFileEncoding -Path $filePath | Should -Be ([System.Text.Encoding]::BigEndianUnicode)
			[System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::BigEndianUnicode) | Should -Be $content
		}

		It 'Should write the content with the specified encoding' {
			Set-NXTContent -Path $filePath -Value $content -Encoding UTF8 -NoNewLine
			[System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8) | Should -Be $content
		}

		It 'Should set an empty string' {
			Set-NXTContent -Path $filePath -Value '' -NoNewLine
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly ''
		}

		It 'Should set an empty string with a new line' {
			Set-NXTContent -Path $filePath -Value ''
			[System.IO.File]::ReadAllText($filePath) | Should -BeExactly $newLine
		}
	}

	Context 'When using valid paths' {
		BeforeEach {
			New-TestFile
		}

		It 'Should set content with a path including wildcards' {
			Set-NXTContent -Path "$rootPath\filter_a*" -Value $content -NoNewLine
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -Be $content
			[System.IO.File]::ReadAllText($filterFilePath2) | Should -Be $content
			[System.IO.File]::ReadAllText($filterFilePath3) | Should -Be $oldContent
		}

		It 'Should set content with multiple paths' {
			Set-NXTContent -Path $filterFilePath1, $filePath -Value $content -NoNewLine
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -Be $content
			[System.IO.File]::ReadAllText($filePath) | Should -Be $content
		}

		It 'Should set content with a literal path' {
			Set-NXTContent -LiteralPath $filePath -Value $content -NoNewLine
			[System.IO.File]::ReadAllText($filePath) | Should -Be $content
		}

		It 'Should set content with pipeline input of files' {
			Get-Item -Path "$rootPath\filter_a*" | Set-NXTContent -Value $content -NoNewLine
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -Be $content
			[System.IO.File]::ReadAllText($filterFilePath2) | Should -Be $content
			[System.IO.File]::ReadAllText($filterFilePath3) | Should -Be $oldContent
		}

		It 'Should set content with pipeline input of values' {
			$content | Set-NXTContent -Path $filePath -NoNewLine
			[System.IO.File]::ReadAllText($filePath) | Should -Be $content
		}

		It 'Should set content with pipeline input of multiple values' {
			@($content, $content) | Set-NXTContent -Path $filePath -NoNewLine
			[System.IO.File]::ReadAllText($filePath) | Should -Be "$content$newLine$content"
		}
	}

	Context 'When using filter parameters' {
		BeforeEach {
			New-TestFile
		}

		It 'Should use Filter parameter' {
			Set-NXTContent -Path "$rootPath\*" -Filter 'filter_a*' -Value $content -NoNewLine
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -Be $content
			[System.IO.File]::ReadAllText($filterFilePath2) | Should -Be $content
			[System.IO.File]::ReadAllText($filterFilePath3) | Should -Be $oldContent
		}

		It 'Should use Include parameter' {
			Set-NXTContent -Path "$rootPath\*" -Include 'filter_a1*', 'filter_b*' -Value $content -NoNewLine
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -Be $content
			[System.IO.File]::ReadAllText($filterFilePath2) | Should -Be $oldContent
			[System.IO.File]::ReadAllText($filterFilePath3) | Should -Be $content
		}

		It 'Should use Exclude parameter' {
			Set-NXTContent -Path "$rootPath\*" -Exclude 'filter_a*' -Value $content -NoNewLine
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -Be $oldContent
			[System.IO.File]::ReadAllText($filterFilePath2) | Should -Be $oldContent
			[System.IO.File]::ReadAllText($filterFilePath3) | Should -Be $content
		}

		It 'Should not change anything with an ineffective filter' {
			Set-NXTContent -Path "$rootPath\*" -Filter 'IneffectiveFilter' -Value $content -NoNewLine
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -Be $oldContent
		}

		It 'Should throw an error with null or empty filters' {
			{ Set-NXTContent -Path "$rootPath\*" -Filter $null -Value $content } | Should -Throw
			{ Set-NXTContent -Path "$rootPath\*" -Filter '' -Value $content } | Should -Throw
			{ Set-NXTContent -Path "$rootPath\*" -Include $null -Value $content } | Should -Throw
			{ Set-NXTContent -Path "$rootPath\*" -Include '' -Value $content } | Should -Throw
			{ Set-NXTContent -Path "$rootPath\*" -Exclude $null -Value $content } | Should -Throw
			{ Set-NXTContent -Path "$rootPath\*" -Exclude '' -Value $content } | Should -Throw
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -Be $oldContent
		}
	}

	Context 'When using invalid values' {
		BeforeAll {
			New-TestFile
		}

		It 'Should throw an error with null' {
			{ Set-NXTContent -Path $filePath -Value $null } | Should -Throw
			[System.IO.File]::Exists($filePath) | Should -BeFalse
		}
	}

	Context 'When using invalid encodings' {
		BeforeAll {
			New-TestFile
		}

		It 'Should throw an error with null or empty encoding' {
			{ Set-NXTContent -Path $filePath -Value $content -Encoding $null } | Should -Throw
			{ Set-NXTContent -Path $filePath -Value $content -Encoding '' } | Should -Throw
		}

		It 'Should throw an error with an invalid encoding' {
			{ Set-NXTContent -Path $filePath -Value $content -Encoding 'InvalidEncoding' } | Should -Throw
			{ Set-NXTContent -Path $filePath -Value $content -Encoding ([System.Object]::new()) } | Should -Throw
			[System.IO.File]::Exists($filePath) | Should -BeFalse
		}
	}

	Context 'When using PassThru' {
		BeforeEach {
			New-TestFile
		}

		It 'Should return the value' {
			Set-NXTContent -Path $filePath -Value $content -NoNewLine -PassThru | Should -Be $content
			[System.IO.File]::ReadAllText($filePath) | Should -Be $content
		}

		It 'Should return multiple values' {
			Set-NXTContent -Path $filePath -Value $content, $content -NoNewLine -PassThru | Should -Be @($content, $content)
		}
	}

	Context 'When the file has special attributes' {
		BeforeEach {
			New-TestFile
			[System.IO.File]::WriteAllText($filePath, $oldContent, [System.Text.Encoding]::UTF8)
		}

		It 'Should throw an error when the file is read-only' {
			[System.IO.File]::SetAttributes($filePath, [System.IO.FileAttributes]::ReadOnly)
			{ Set-NXTContent -Path $filePath -Value $content -NoNewLine } | Should -Throw
			[System.IO.File]::ReadAllText($filePath) | Should -Be $oldContent
		}

		It 'Should overwrite a read-only file with Force and keep the attribute' {
			[System.IO.File]::SetAttributes($filePath, [System.IO.FileAttributes]::ReadOnly)
			Set-NXTContent -Path $filePath -Value $content -NoNewLine -Force
			[System.IO.File]::ReadAllText($filePath) | Should -Be $content
			[System.IO.File]::GetAttributes($filePath).HasFlag([System.IO.FileAttributes]::ReadOnly) | Should -BeTrue
		}

		It 'Should throw an error when the file is hidden' {
			[System.IO.File]::SetAttributes($filePath, [System.IO.FileAttributes]::Hidden)
			{ Set-NXTContent -Path $filePath -Value $content -NoNewLine } | Should -Throw
			[System.IO.File]::ReadAllText($filePath) | Should -Be $oldContent
		}

		It 'Should overwrite a hidden file with Force and keep the attribute' {
			[System.IO.File]::SetAttributes($filePath, [System.IO.FileAttributes]::Hidden)
			Set-NXTContent -Path $filePath -Value $content -NoNewLine -Force
			[System.IO.File]::ReadAllText($filePath) | Should -Be $content
			[System.IO.File]::GetAttributes($filePath).HasFlag([System.IO.FileAttributes]::Hidden) | Should -BeTrue
		}

		It 'Should throw an error when the file is in use' {
			[System.IO.FileStream]$stream = [System.IO.File]::Open($filePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
			try {
				{ Set-NXTContent -Path $filePath -Value $content -NoNewLine } | Should -Throw
			}
			finally {
				$stream.Dispose()
			}
			[System.IO.File]::ReadAllText($filePath) | Should -Be $oldContent
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
				Set-NXTContent -Path $filterFilePath1, $filePath -Value $content -NoNewLine
			}
			finally {
				$global:WhatIfPreference = $false
			}
			[System.IO.File]::ReadAllText($filterFilePath1) | Should -Be $oldContent
			[System.IO.File]::Exists($filePath) | Should -BeFalse
		}
	}
}
