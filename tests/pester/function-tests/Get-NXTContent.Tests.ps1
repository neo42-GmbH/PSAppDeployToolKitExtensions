BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Get-NXTContent' {
	BeforeAll {
		[System.String]$filePath = [System.IO.Path]::GetTempFileName()
		[System.String]$content = 'This is a test file. 🚀äß$'
	}

	AfterAll {
		Remove-Item -LiteralPath $filePath -ErrorAction SilentlyContinue
	}

	Context 'When reading a file with specific encoding' {
		BeforeEach {
			[System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::BigEndianUnicode)
		}

		AfterEach {
			Remove-Item -LiteralPath $filePath -ErrorAction SilentlyContinue
		}

		It 'Should read content with specified encoding' {
			Get-NXTContent -Path $filePath -Encoding BigEndianUnicode | Should -Be $content
		}

		It 'Should detect encoding automatically' {
			Get-NXTContent -Path $filePath | Should -Be $content
		}
	}

	Context 'When reading a file with different encodings' {
		AfterEach {
			Remove-Item -LiteralPath $filePath -ErrorAction SilentlyContinue
		}

		It 'Should read UTF-8 encoded content' {
			[System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)
			Get-NXTContent -Path $filePath | Should -Be $content
		}

		It 'Should read UTF-16LE encoded content' {
			[System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::Unicode)
			Get-NXTContent -Path $filePath | Should -Be $content
		}

		It 'Should read ASCII encoded content' {
			[System.String]$asciiContent = 'This is an ASCII test file.'
			[System.IO.File]::WriteAllText($filePath, $asciiContent, [System.Text.Encoding]::ASCII)
			Get-NXTContent -Path $filePath | Should -Be $asciiContent
		}
	}

	Context 'When using LiteralPath parameter' {
		BeforeEach {
			[System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)
		}

		AfterEach {
			Remove-Item -LiteralPath $filePath -ErrorAction SilentlyContinue
		}

		It 'Should read content with LiteralPath parameter' {
			Get-NXTContent -LiteralPath $filePath | Should -Be $content
		}
	}

	Context 'When file is unavailable or has special properties' {
		AfterEach {
			Remove-Item -Path $filePath -ErrorAction SilentlyContinue
			Set-ItemProperty -Path $filePath -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
		}

		It 'Should throw when file does not exist' {
			{ Get-NXTContent -Path "$PSScriptRoot\nonexistent.txt" } | Should -Throw
		}

		It 'Should throw when path is invalid' {
			{ Get-NXTContent -Path "$PSScriptRoot\invalid\folder\file.txt" } | Should -Throw
		}

		It 'Should read hidden files when Force is specified' {
			[System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)
			Set-ItemProperty -Path $filePath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)
			Get-NXTContent -Path $filePath -Force | Should -Be $content
			Set-ItemProperty -Path $filePath -Name Attributes -Value ([System.IO.FileAttributes]::Normal)
		}

		It 'Should read read-only files' {
			[System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)
			Set-ItemProperty -Path $filePath -Name IsReadOnly -Value $true
			Get-NXTContent -Path $filePath | Should -Be $content
			Set-ItemProperty -Path $filePath -Name IsReadOnly -Value $false
		}
	}

	Context 'When using filter parameters' {
		BeforeAll {
			[System.String]$tempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString())
			New-Item -Path $tempDir -ItemType Directory | Out-Null
			[System.String]$file1 = Join-Path -Path $tempDir -ChildPath 'test1.txt'
			[System.String]$file2 = Join-Path -Path $tempDir -ChildPath 'test2.txt'
			[System.String]$file3 = Join-Path -Path $tempDir -ChildPath 'other.txt'

			[System.IO.File]::WriteAllText($file1, 'test1', [System.Text.Encoding]::UTF8)
			[System.IO.File]::WriteAllText($file2, 'test2', [System.Text.Encoding]::UTF8)
			[System.IO.File]::WriteAllText($file3, 'other', [System.Text.Encoding]::UTF8)
		}

		AfterAll {
			Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
		}

		It 'Should use Include filter' {
			$result = Get-NXTContent -Path "$tempDir\*" -Include 'test*.txt'
			$result -join '' | Should -BeExactly 'test1test2'
		}

		It 'Should use Exclude filter' {
			$result = Get-NXTContent -Path "$tempDir\*" -Exclude 'other.txt'
			$result -join '' | Should -BeExactly 'test1test2'
		}

		It 'Should use Filter parameter' {
			$result = Get-NXTContent -Path "$tempDir\*" -Filter 'test*.txt'
			$result -join '' | Should -BeExactly 'test1test2'
		}
	}
}
