BeforeDiscovery { . 'C:\Workdir_local\PSAppDeployToolKitExtensions\tests\pester\Initialize-PesterPsadtEnvironment.ps1' }

Describe 'Wait-NXTFileNotInUse' {
	BeforeAll {
		[System.String]$filePathNotExisting = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
		[System.String]$filePath = [System.IO.Path]::GetTempFileName()
		[System.IO.File]::WriteAllText($filePath, 'Pester test file')
		function Invoke-FileLock {
			param(
				[System.Management.Automation.SwitchParameter]$Unlock
			)
			if ($Unlock) {
				if (Get-Variable -Name 'fileStream' -Scope 'Script' -ErrorAction Ignore) {
					$script:fileStream.Close()
					return
				}
			}
			[System.IO.FileStream]$script:fileStream = [System.IO.File]::Open(
				$filePath,
				[System.IO.FileMode]::Open,
				[System.IO.FileAccess]::ReadWrite,
				[System.IO.FileShare]::None
			)
		}
	}

	AfterAll {
		Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue
	}

	Context 'When using invalid path' {
		It 'Should throw an error with a non-existing path' {
			{ Wait-NXTFileNotInUse -Path $filePathNotExisting } | Should -Throw
		}

		It 'Should throw an error with null or empty path' {
			{ Wait-NXTFileNotInUse -Path $null } | Should -Throw
			{ Wait-NXTFileNotInUse -Path '' } | Should -Throw
		}
	}

	Context 'When using invalid timeout' {
		It 'Should throw an error with an invalid timeout value' {
			{ Wait-NXTFileNotInUse -Path $filePath -Timeout 'abc' } | Should -Throw
		}

		It 'Should throw an error with null or empty timeout value' {
			{ Wait-NXTFileNotInUse -Path $filePath -Timeout $null } | Should -Throw
			{ Wait-NXTFileNotInUse -Path $filePath -Timeout '' } | Should -Throw
		}

		It 'Should throw an error with an invalid timeout value datatype' {
			{ Wait-NXTFileNotInUse -Path $filePath -Timeout ([System.Guid]::NewGuid()) } | Should -Throw
		}
	}

	Context 'When using invalid interval' {
		It 'Should throw an error with an invalid interval value' {
			{ Wait-NXTFileNotInUse -Path $filePath -Interval 'abc' } | Should -Throw
		}

		It 'Should throw an error with null or empty interval value' {
			{ Wait-NXTFileNotInUse -Path $filePath -Interval $null } | Should -Throw
			{ Wait-NXTFileNotInUse -Path $filePath -Interval '' } | Should -Throw
		}

		It 'Should throw an error with an invalid interval value datatype' {
			{ Wait-NXTFileNotInUse -Path $filePath -Interval ([System.Guid]::NewGuid()) } | Should -Throw
		}
	}

	Context 'When using a valid path' {
		It 'Should be $true when the file is not in use' {
			Wait-NXTFileNotInUse -Path $filePath | Should -BeTrue
		}

		It 'Should be $false after 3 seconds waiting for the file to be not in use' {
			Invoke-FileLock
			$start = [System.DateTime]::Now
			$result = Wait-NXTFileNotInUse -Path $filePath -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			Invoke-FileLock -Unlock
			$result | Should -BeFalse
			$duration.TotalSeconds | Should -BeGreaterOrEqual 3
			$duration.TotalSeconds | Should -BeLessThan 4
		}

		It 'Should be $false after 3 seconds waiting for the file to be in use' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTFileNotInUse -Path $filePath -Timeout '00:00:03' -Interval '00:00:02' -IsInUse
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeFalse
			$duration.TotalSeconds | Should -BeGreaterOrEqual 4
			$duration.TotalSeconds | Should -BeLessThan 5
		}

		It 'Should be $true instantly waiting for the file to be not in use' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTFileNotInUse -Path $filePath -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeTrue
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be [System.IO.FileSystemInfo] instantly waiting for the file to be not in use' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTFileNotInUse -Path $filePath -Timeout '00:00:03' -Interval '00:00:00.500' -PassThru
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeOfType [System.IO.FileSystemInfo]
			$duration.TotalSeconds | Should -BeLessThan 1
		}
	}
}
