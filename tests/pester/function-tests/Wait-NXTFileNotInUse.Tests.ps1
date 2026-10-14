BeforeDiscovery { . 'C:\Workdir_local\PSAppDeployToolKitExtensions\tests\pester\Initialize-PesterPsadtEnvironment.ps1' }

Describe 'Wait-NXTFileNotInUse' {
	BeforeAll {
		[System.String]$filePathNotExisting = [System.IO.Path]::GetTempFileName()
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
			{ Wait-NXTFileNotInUse -Path $filePath -Timeout '-1' } | Should -Throw
		}

		It 'Should throw an error with null or empty timeout value' {
			{ Wait-NXTFileNotInUse -Path $filePath -Timeout $null } | Should -Throw
			{ Wait-NXTFileNotInUse -Path $filePath -Timeout '' } | Should -Throw
		}

		It 'Should throw an error with an invalid timeout value datatype' {
			{ Wait-NXTFileNotInUse -Path $filePath -Timeout 'abc' } | Should -Throw
		}
	}

	Context 'When using invalid interval' {
		It 'Should throw an error with an invalid interval value' {
			{ Wait-NXTFileNotInUse -Path $filePath -Interval '-1' } | Should -Throw
		}

		It 'Should throw an error with null or empty interval value' {
			{ Wait-NXTFileNotInUse -Path $filePath -Interval $null } | Should -Throw
			{ Wait-NXTFileNotInUse -Path $filePath -Interval '' } | Should -Throw
		}

		It 'Should throw an error with an invalid interval value datatype' {
			{ Wait-NXTFileNotInUse -Path $filePath -Interval 'abc' } | Should -Throw
		}
	}
}
