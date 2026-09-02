BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Get-NXTFileEncoding' {
	BeforeAll {
		# Create test files with different encodings
		$utf8File = [System.IO.Path]::GetTempFileName()
		$utf8BomFile = [System.IO.Path]::GetTempFileName()
		$utf16LeFile = [System.IO.Path]::GetTempFileName()
		$utf16BeFile = [System.IO.Path]::GetTempFileName()
		$asciiFile = [System.IO.Path]::GetTempFileName()
		$nonExistentFile = [System.IO.Path]::GetTempFileName()
		Remove-Item -Path $nonExistentFile -ErrorAction SilentlyContinue

		$sampleContent = 'This is a test file with some content. Special characters: äöü 你好 こんにちは'

		# Create the files with various encodings
		[System.IO.File]::WriteAllText($utf8File, $sampleContent, [System.Text.UTF8Encoding]::new($false))
		[System.IO.File]::WriteAllText($utf8BomFile, $sampleContent, [System.Text.Encoding]::UTF8)
		[System.IO.File]::WriteAllText($utf16LeFile, $sampleContent, [System.Text.Encoding]::Unicode)
		[System.IO.File]::WriteAllText($utf16BeFile, $sampleContent, [System.Text.Encoding]::BigEndianUnicode)
		[System.IO.File]::WriteAllText($asciiFile, 'ASCII text only', [System.Text.Encoding]::ASCII)
	}

	AfterAll {
		# Clean up test files
		Remove-Item -Path $utf8File -ErrorAction SilentlyContinue
		Remove-Item -Path $utf8BomFile -ErrorAction SilentlyContinue
		Remove-Item -Path $utf16LeFile -ErrorAction SilentlyContinue
		Remove-Item -Path $utf16BeFile -ErrorAction SilentlyContinue
		Remove-Item -Path $asciiFile -ErrorAction SilentlyContinue
	}

	Context 'When detecting encodings from existing files' {
		It 'Should not be able to detect UTF-8 without BOM when default encoding is specified' {
			$encoding = Get-NXTFileEncoding -Path $utf8File -DefaultEncoding ([System.Text.UTF8Encoding]::new($false))
			$encoding.GetType().Name | Should -Be 'UTF8Encoding'
			$encoding.GetPreamble().Length | Should -Be 0 # No BOM
		}

		It 'Should not be able to detect UTF-8 without BOM when the default is not UTF-8' {
			$encoding = Get-NXTFileEncoding -Path $utf8File -DefaultEncoding ([System.Text.Encoding]::ASCII)
			$encoding.GetType().Name | Should -BeIn @('ASCIIEncoding', 'ASCIIEncodingSealed')
			$encoding.GetPreamble().Length | Should -Be 0 # No BOM
		}

		It 'Should detect UTF-8 with BOM' {
			$encoding = Get-NXTFileEncoding -Path $utf8BomFile
			$encoding.GetType().Name | Should -BeIn @('UTF8Encoding', 'UTF8EncodingSealed')
			$encoding.GetPreamble().Length | Should -BeGreaterThan 0 # Has BOM
		}

		It 'Should detect UTF-16 Little Endian' {
			$encoding = Get-NXTFileEncoding -Path $utf16LeFile
			$encoding.GetType().Name | Should -Be 'UnicodeEncoding'
			$encoding.GetPreamble()[0] | Should -Be 255 # FF FE is UTF-16 LE BOM
			$encoding.GetPreamble()[1] | Should -Be 254
		}

		It 'Should detect UTF-16 Big Endian' {
			$encoding = Get-NXTFileEncoding -Path $utf16BeFile
			$encoding.GetType().Name | Should -Be 'UnicodeEncoding'
			$encoding.GetPreamble()[0] | Should -Be 254 # FE FF is UTF-16 BE BOM
			$encoding.GetPreamble()[1] | Should -Be 255
		}

		It 'Should detect ASCII encoding or default to system encoding for ASCII files' {
			$encoding = Get-NXTFileEncoding -Path $asciiFile
			# ASCII might be detected as the system default encoding, typically UTF-8
			$encoding.GetType().Name | Should -BeIn @('ASCIIEncoding', 'UTF8Encoding', 'ASCIIEncodingSealed', 'UTF8EncodingSealed')
		}
	}

	Context 'When handling non-existent files or paths' {
		It 'Should return default encoding for non-existent file' {
			$defaultEncoding = [System.Text.Encoding]::ASCII
			$encoding = Get-NXTFileEncoding -Path $nonExistentFile -DefaultEncoding $defaultEncoding
			$encoding | Should -Be $defaultEncoding
		}
	}

	Context 'When using different path parameters' {
		It 'Should accept literal path' {
			$encoding = Get-NXTFileEncoding -LiteralPath $utf16LeFile
			$encoding.GetType().Name | Should -Be 'UnicodeEncoding'
		}

		It 'Should accept file objects from pipeline' {
			$fileObject = Get-Item -Path $utf16BeFile
			$encoding = $fileObject | Get-NXTFileEncoding
			$encoding.GetType().Name | Should -Be 'UnicodeEncoding'
			$encoding.GetPreamble()[0] | Should -Be 254 # FE FF is UTF-16 BE BOM
		}
	}

	Context 'When using custom default encoding' {
		It 'Should use provided default encoding' {
			$defaultEncoding = [System.Text.Encoding]::GetEncoding('iso-8859-1')
			$encoding = Get-NXTFileEncoding -Path $nonExistentFile -DefaultEncoding $defaultEncoding
			$encoding | Should -Be $defaultEncoding
		}
	}
}
