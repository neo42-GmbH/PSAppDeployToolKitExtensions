BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Wait-NXTFileSystem' {
	BeforeAll {
		[System.String]$filePathNotExisting = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
		[System.String]$filePath = [System.IO.Path]::GetTempFileName()
		[System.IO.File]::WriteAllText($filePath, 'Pester test file')
		[System.String]$fileDir = Split-Path -Path $filePath -Parent
	}

	AfterAll {
		Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue
	}

	Context 'When using invalid path' {
		It 'Should throw an error with null or empty value' {
			{ Wait-NXTFileSystem -Path $null } | Should -Throw
			{ Wait-NXTFileSystem -Path '' } | Should -Throw
		}
	}

	Context 'When using invalid pathtype' {
		It 'Should throw an error with invalid value' {
			{ Wait-NXTFileSystem -Path $filePath -PathType '123' } | Should -Throw
		}

		It 'Should throw an error with null or empty value' {
			{ Wait-NXTFileSystem -Path $filePath -PathType $null } | Should -Throw
			{ Wait-NXTFileSystem -Path $filePath -PathType '' } | Should -Throw
		}

		It 'Should throw an error with invalid value datatype' {
			{ Wait-NXTFileSystem -Path $filePath -PathType ([System.Guid]::NewGuid()) } | Should -Throw
		}
	}

	Context 'When using invalid timeout' {
		It 'Should throw an error with an invalid value' {
			{ Wait-NXTFileSystem -Path $filePath -Timeout 'abc' } | Should -Throw
		}

		It 'Should throw an error with null or empty value' {
			{ Wait-NXTFileSystem -Path $filePath -Timeout $null } | Should -Throw
			{ Wait-NXTFileSystem -Path $filePath -Timeout '' } | Should -Throw
		}

		It 'Should throw an error with an invalid value datatype' {
			{ Wait-NXTFileSystem -Path $filePath -Timeout ([System.Guid]::NewGuid()) } | Should -Throw
		}
	}

	Context 'When using invalid interval' {
		It 'Should throw an error with an invalid value' {
			{ Wait-NXTFileSystem -Path $filePath -Interval 'abc' } | Should -Throw
		}

		It 'Should throw an error with null or empty value' {
			{ Wait-NXTFileSystem -Path $filePath -Interval $null } | Should -Throw
			{ Wait-NXTFileSystem -Path $filePath -Interval '' } | Should -Throw
		}

		It 'Should throw an error with an invalid value datatype' {
			{ Wait-NXTFileSystem -Path $filePath -Interval ([System.Guid]::NewGuid()) } | Should -Throw
		}
	}

	Context 'When using a invalid pipeline input' {
		It 'Should throw an error with null or empty value' {
			{ $null | Wait-NXTFileSystem } | Should -Throw
			{ '' | Wait-NXTFileSystem } | Should -Throw
		}

		It 'Should throw an error with an invalid value datatype' {
			{ [System.Guid]::NewGuid() | Wait-NXTFileSystem } | Should -Throw
		}
	}

	Context 'When using a valid input' {
		It 'Should be $true when the file exists' {
			Wait-NXTFileSystem -Path $filePath | Should -BeTrue
		}

		It 'Should be $false after 3 seconds waiting for the file to exist' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTFileSystem -Path $filePathNotExisting -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeFalse
			$duration.TotalSeconds | Should -BeGreaterOrEqual 3
			$duration.TotalSeconds | Should -BeLessThan 4
		}

		It 'Should be $false after 3 seconds waiting for the file to not exist anymore' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTFileSystem -Path $filePath -Timeout '00:00:03' -Interval '00:00:02' -IsRemoved
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeFalse
			$duration.TotalSeconds | Should -BeGreaterOrEqual 4
			$duration.TotalSeconds | Should -BeLessThan 5
		}

		It 'Should be $true instantly waiting for the file to exist' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTFileSystem -Path $filePath -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeTrue
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be [System.IO.FileSystemInfo] instantly waiting for the file to exist' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTFileSystem -Path $filePath -Timeout '00:00:03' -Interval '00:00:00.500' -PassThru
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeOfType [System.IO.FileSystemInfo]
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be $null instantly waiting for the file to be removed' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTFileSystem -Path $filePathNotExisting -Timeout '00:00:03' -Interval '00:00:00.500' -IsRemoved -PassThru
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeNullOrEmpty
			$duration.TotalSeconds | Should -BeLessThan 1
		}
	}
}
