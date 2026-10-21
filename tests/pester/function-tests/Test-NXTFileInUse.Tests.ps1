BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Test-NXTFileInUse' {
	BeforeAll {
		# Files
		[System.String]$rootPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName())
		[System.String]$filePath = [System.IO.Path]::Combine($rootPath, 'file.txt')
		[System.String]$hiddenFilePath = [System.IO.Path]::Combine($rootPath, 'hidden.txt')
		[System.String]$folderPath = [System.IO.Path]::Combine($rootPath, 'folder')
		[System.String]$filePathNotExisting = [System.IO.Path]::Combine($rootPath, 'notExisting.txt')
		function New-TestFile {
			Remove-TestFile
			$null = [System.IO.Directory]::CreateDirectory($folderPath)
			[System.IO.File]::WriteAllText($filePath, 'content')
			[System.IO.File]::WriteAllText($hiddenFilePath, 'content')
			[System.IO.File]::SetAttributes($hiddenFilePath, [System.IO.FileAttributes]::Hidden)
		}
		function Remove-TestFile {
			Remove-Item -LiteralPath $rootPath -Recurse -Force -ErrorAction SilentlyContinue
		}

		New-TestFile
	}

	AfterAll {
		Remove-TestFile
	}

	Context 'When using an invalid path' {
		It 'Should throw an error with a non-existing path' {
			{ Test-NXTFileInUse -Path $filePathNotExisting } | Should -Throw
		}

		It 'Should throw an error with null or empty path' {
			{ Test-NXTFileInUse -Path $null } | Should -Throw
			{ Test-NXTFileInUse -Path '' } | Should -Throw
		}

		It 'Should throw an error with a wrong data type for path' {
			{ Test-NXTFileInUse -Path 123 } | Should -Throw
			{ Test-NXTFileInUse -Path $filePath, $filePath } | Should -Throw
		}

		It 'Should throw an error with a path including wildcards' {
			{ Test-NXTFileInUse -Path "$rootPath\file*" } | Should -Throw
		}

		It 'Should be false for a folder' {
			Test-NXTFileInUse -Path $folderPath | Should -BeFalse
		}
	}

	Context 'When testing a file which is not in use' {
		It 'Should be false' {
			Test-NXTFileInUse -Path $filePath | Should -BeFalse
		}

		It 'Should return a boolean' {
			Test-NXTFileInUse -Path $filePath | Should -BeOfType [System.Boolean]
		}

		It 'Should accept the parameter aliases' {
			Test-NXTFileInUse -LiteralPath $filePath | Should -BeFalse
			Test-NXTFileInUse -PSPath $filePath | Should -BeFalse
		}

		It 'Should accept pipeline input' {
			Get-Item -LiteralPath $filePath | Test-NXTFileInUse | Should -BeFalse
		}

		It 'Should be false after the file was released' {
			[System.IO.FileStream]$stream = [System.IO.File]::Open($filePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
			$stream.Dispose()
			Test-NXTFileInUse -Path $filePath | Should -BeFalse
		}
	}

	Context 'When testing a file which is in use' {
		It 'Should be true when the file is locked exclusively' {
			[System.IO.FileStream]$stream = [System.IO.File]::Open($filePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
			try {
				Test-NXTFileInUse -Path $filePath | Should -BeTrue
			}
			finally {
				$stream.Dispose()
			}
		}

		It 'Should be true when the file is opened for writing' {
			[System.IO.FileStream]$stream = [System.IO.File]::Open($filePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
			try {
				Test-NXTFileInUse -Path $filePath | Should -BeTrue
			}
			finally {
				$stream.Dispose()
			}
		}

		It 'Should be true with pipeline input' {
			[System.IO.FileStream]$stream = [System.IO.File]::Open($filePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
			try {
				Get-Item -LiteralPath $filePath | Test-NXTFileInUse | Should -BeTrue
			}
			finally {
				$stream.Dispose()
			}
		}

		It 'Should return a result for each pipeline input' {
			[System.IO.FileStream]$stream = [System.IO.File]::Open($filePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
			try {
				Get-Item -LiteralPath $filePath, $hiddenFilePath -Force | Test-NXTFileInUse -Force | Should -Be @($true, $false)
			}
			finally {
				$stream.Dispose()
			}
		}
	}

	Context 'When testing hidden files' {
		It 'Should throw an error without Force' {
			{ Test-NXTFileInUse -Path $hiddenFilePath } | Should -Throw
		}

		It 'Should be false with Force' {
			Test-NXTFileInUse -Path $hiddenFilePath -Force | Should -BeFalse
		}

		It 'Should be true with Force when the file is in use' {
			[System.IO.FileStream]$stream = [System.IO.File]::Open($hiddenFilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
			try {
				Test-NXTFileInUse -Path $hiddenFilePath -Force | Should -BeTrue
			}
			finally {
				$stream.Dispose()
			}
		}
	}
}
