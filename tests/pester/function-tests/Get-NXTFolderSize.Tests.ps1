BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Get-NXTFolderSize' {
	Context 'When calculating folder sizes' {
		BeforeAll {
			$testDir = [System.IO.Path]::Combine($env:TEMP, [System.IO.Path]::GetRandomFileName())
			New-Item -Path $testDir -ItemType Directory -Force | Out-Null
			$testFile = [System.IO.Path]::Combine($testDir, 'testfile.txt')
			$bytes = [System.Byte[]]::new(1048576) # 1 MB
			[System.IO.File]::WriteAllBytes($testFile, $bytes)
		}

		AfterAll {
			Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
		}

		It 'Should return the correct size for a folder with a single file' {
			$size = Get-NXTFolderSize -Path $testDir
			$size | Should -Be 1048576 # 1 MB in bytes
		}

		It 'Should convert the units correctly' {
			$size = Get-NXTFolderSize -Path $testDir -Unit 'MB'
			$size | Should -Be 1 # 1 MB
		}

		It 'Should fail throw an error for a non-existent path' {
			{ Get-NXTFolderSize -Path 'C:\NonExistentFolder' } | Should -Throw
		}

		It 'Should handle empty directories' {
			$emptyDir = [System.IO.Path]::Combine($env:TEMP, [System.IO.Path]::GetTempFileName())
			New-Item -Path $emptyDir -ItemType Directory -Force | Out-Null
			$size = Get-NXTFolderSize -Path $emptyDir
			$size | Should -Be 0 # Empty directory should return size 0
			Remove-Item $emptyDir -Recurse -Force -ErrorAction SilentlyContinue
		}
	}
}
