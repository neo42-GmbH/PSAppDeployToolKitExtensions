BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Add-NxtContent' {
	BeforeAll {
		[System.String]$filePath = [System.IO.Path]::GetTempFileName()
		[System.String]$content = 'This is a test file. 🚀äß$'
	}

	AfterAll {
		Remove-Item -LiteralPath $filePath -ErrorAction SilentlyContinue
	}

	Context 'When creating a new file' {
		AfterEach {
			Remove-Item -LiteralPath $filePath -ErrorAction SilentlyContinue
		}

		It 'Should create a new file with correct encoding' {
			Add-NXTContent -Path $filePath -Value $content -Encoding BigEndianUnicode -NoNewLine | Should -BeNullOrEmpty
			Test-Path -Path $filePath | Should -Be $true
			[System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::BigEndianUnicode) | Should -Be $content
		}

		It 'Should add new line when parameter when -NoNewLine is not specified' {
			Add-NXTContent -Path $filePath -Value $content -Encoding BigEndianUnicode | Should -BeNullOrEmpty
			[System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::BigEndianUnicode) | Should -Be "$content$([System.Environment]::NewLine)"
		}

		It 'Should pass thru the value when -PassThru is specified' {
			Add-NXTContent -Path $filePath -Value $content -Encoding BigEndianUnicode -NoNewLine -PassThru | Should -Be $content
			[System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::BigEndianUnicode) | Should -Be $content
		}

		It 'Should take pipeline input' {
			@($content, $content) | Add-NXTContent -Path $filePath -Encoding BigEndianUnicode -NoNewLine | Should -BeNullOrEmpty
			[System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::BigEndianUnicode) | Should -Be "$content$content"
		}
	}

	Context 'When appending to an existing file' {
		BeforeEach {
			[System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::BigEndianUnicode)
		}

		AfterEach {
			Remove-Item $filePath -ErrorAction SilentlyContinue
		}

		It 'Should append to the file' {
			Add-NxtContent -Path $filePath -Value $content -Encoding BigEndianUnicode -NoNewLine | Should -BeNullOrEmpty
			[System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::BigEndianUnicode) | Should -Be "$content$content"
		}

		It 'Should not alter the encoding' {
			Add-NXTContent -Path $filePath -Value $content -Encoding UTF8 -NoNewLine | Should -BeNullOrEmpty
			Get-NXTFileEncoding -Path $filePath | Should -Be ([System.Text.Encoding]::BigEndianUnicode)
		}
	}

	Context 'When destination is unavailable' {
		AfterEach {
			Remove-Item $filePath -ErrorAction SilentlyContinue
		}
		It 'Should throw when read-only' {
			New-Item -Path $filePath -ItemType File
			Set-ItemProperty -Path $filePath -Name IsReadOnly -Value $true
			{ Add-NXTContent -Path $filePath -Value $content } | Should -Throw
			Set-ItemProperty -Path $filePath -Name IsReadOnly -Value $false
		}
		It 'Should overwrite read-only when forced' {
			New-Item -Path $filePath -ItemType File
			Set-ItemProperty -Path $filePath -Name IsReadOnly -Value $true
			Add-NXTContent -Path $filePath -Value $content -Force -Encoding BigEndianUnicodeWithBOM -NoNewLine | Should -BeNullOrEmpty
			[System.IO.File]::ReadAllText($filePath) | Should -Be $content
			Set-ItemProperty -Path $filePath -Name IsReadOnly -Value $false
		}
		It 'Should not create folder structure' {
			{ Add-NxtContent -Path $PSScriptRoot\invalid\test.txt -Value $content } | Should -Throw
		}
	}
}
