BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Remove-NXTEmptyIniFile' {
	BeforeAll {
		# Files
		[System.String]$rootPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName())
		[System.String]$emptyFilePath = [System.IO.Path]::Combine($rootPath, 'empty.ini')
		[System.String]$emptySectionFilePath = [System.IO.Path]::Combine($rootPath, 'emptySection.ini')
		[System.String]$notEmptyFilePath = [System.IO.Path]::Combine($rootPath, 'notEmpty.ini')
		[System.String]$mixedFilePath = [System.IO.Path]::Combine($rootPath, 'mixed.ini')
		[System.String]$folderPath = [System.IO.Path]::Combine($rootPath, 'folder.ini')
		[System.String]$filePathNotExisting = [System.IO.Path]::Combine($rootPath, 'notExisting.ini')
		function New-TestFile {
			Remove-TestFile
			$null = [System.IO.Directory]::CreateDirectory($folderPath)
			[System.IO.File]::WriteAllText($emptyFilePath, '')
			[System.IO.File]::WriteAllText($emptySectionFilePath, "[Section1]`r`n[Section2]`r`n")
			[System.IO.File]::WriteAllText($notEmptyFilePath, "[Section1]`r`nKey=Value`r`n")
			[System.IO.File]::WriteAllText($mixedFilePath, "[Section1]`r`n[Section2]`r`nKey=Value`r`n")
		}
		function Remove-TestFile {
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
			{ Remove-NXTEmptyIniFile -Path $filePathNotExisting } | Should -Throw
			{ Remove-NXTEmptyIniFile -Path $filePathNotExisting, $emptyFilePath } | Should -Throw
		}

		It 'Should throw an error with null or empty path' {
			{ Remove-NXTEmptyIniFile -Path $null } | Should -Throw
			{ Remove-NXTEmptyIniFile -Path '' } | Should -Throw
			{ Remove-NXTEmptyIniFile -Path $null, $emptyFilePath } | Should -Throw
			{ Remove-NXTEmptyIniFile -Path '', $emptyFilePath } | Should -Throw
			[System.IO.File]::Exists($emptyFilePath) | Should -BeTrue
		}

		It 'Should throw an error with a wrong data type for path' {
			{ Remove-NXTEmptyIniFile -Path 123 } | Should -Throw
		}

		It 'Should not remove a folder' {
			Remove-NXTEmptyIniFile -Path $folderPath
			[System.IO.Directory]::Exists($folderPath) | Should -BeTrue
		}
	}

	Context 'When using an invalid literal path' {
		BeforeAll {
			New-TestFile
		}

		It 'Should throw an error with a literal path including wildcards' {
			{ Remove-NXTEmptyIniFile -LiteralPath "$rootPath\empty*" } | Should -Throw
			[System.IO.File]::Exists($emptyFilePath) | Should -BeTrue
		}

		It 'Should throw an error with a non-existing path' {
			{ Remove-NXTEmptyIniFile -LiteralPath $filePathNotExisting } | Should -Throw
		}

		It 'Should throw an error with null or empty path' {
			{ Remove-NXTEmptyIniFile -LiteralPath $null } | Should -Throw
			{ Remove-NXTEmptyIniFile -LiteralPath '' } | Should -Throw
		}
	}

	Context 'When removing ini files' {
		BeforeEach {
			New-TestFile
		}

		It 'Should remove an empty file' {
			Remove-NXTEmptyIniFile -Path $emptyFilePath | Should -BeNullOrEmpty
			[System.IO.File]::Exists($emptyFilePath) | Should -BeFalse
		}

		It 'Should remove a file with empty sections only' {
			Remove-NXTEmptyIniFile -Path $emptySectionFilePath
			[System.IO.File]::Exists($emptySectionFilePath) | Should -BeFalse
		}

		It 'Should not remove a file with keys' {
			Remove-NXTEmptyIniFile -Path $notEmptyFilePath
			[System.IO.File]::Exists($notEmptyFilePath) | Should -BeTrue
		}

		It 'Should not remove a file with empty sections and a key' {
			Remove-NXTEmptyIniFile -Path $mixedFilePath
			[System.IO.File]::Exists($mixedFilePath) | Should -BeTrue
		}

		It 'Should remove multiple files' {
			Remove-NXTEmptyIniFile -Path $emptyFilePath, $emptySectionFilePath, $notEmptyFilePath
			[System.IO.File]::Exists($emptyFilePath) | Should -BeFalse
			[System.IO.File]::Exists($emptySectionFilePath) | Should -BeFalse
			[System.IO.File]::Exists($notEmptyFilePath) | Should -BeTrue
		}

		It 'Should remove files with a path including wildcards' {
			Remove-NXTEmptyIniFile -Path "$rootPath\*.ini"
			[System.IO.File]::Exists($emptyFilePath) | Should -BeFalse
			[System.IO.File]::Exists($emptySectionFilePath) | Should -BeFalse
			[System.IO.File]::Exists($notEmptyFilePath) | Should -BeTrue
			[System.IO.File]::Exists($mixedFilePath) | Should -BeTrue
			[System.IO.Directory]::Exists($folderPath) | Should -BeTrue
		}

		It 'Should remove a file with a literal path' {
			Remove-NXTEmptyIniFile -LiteralPath $emptyFilePath
			[System.IO.File]::Exists($emptyFilePath) | Should -BeFalse
		}

		It 'Should remove files with pipeline input' {
			Get-Item -Path $emptyFilePath, $emptySectionFilePath, $notEmptyFilePath | Remove-NXTEmptyIniFile
			[System.IO.File]::Exists($emptyFilePath) | Should -BeFalse
			[System.IO.File]::Exists($emptySectionFilePath) | Should -BeFalse
			[System.IO.File]::Exists($notEmptyFilePath) | Should -BeTrue
		}
	}

	Context 'When using filter parameters' {
		BeforeEach {
			New-TestFile
		}

		It 'Should use Filter parameter' {
			Remove-NXTEmptyIniFile -Path "$rootPath\*" -Filter 'emptySection*'
			[System.IO.File]::Exists($emptyFilePath) | Should -BeTrue
			[System.IO.File]::Exists($emptySectionFilePath) | Should -BeFalse
		}

		It 'Should use Include parameter' {
			Remove-NXTEmptyIniFile -Path "$rootPath\*" -Include 'empty.ini'
			[System.IO.File]::Exists($emptyFilePath) | Should -BeFalse
			[System.IO.File]::Exists($emptySectionFilePath) | Should -BeTrue
		}

		It 'Should use Exclude parameter' {
			Remove-NXTEmptyIniFile -Path "$rootPath\*" -Exclude 'empty.ini'
			[System.IO.File]::Exists($emptyFilePath) | Should -BeTrue
			[System.IO.File]::Exists($emptySectionFilePath) | Should -BeFalse
		}

		It 'Should not remove anything with an ineffective filter' {
			Remove-NXTEmptyIniFile -Path "$rootPath\*" -Filter 'IneffectiveFilter'
			[System.IO.File]::Exists($emptyFilePath) | Should -BeTrue
			[System.IO.File]::Exists($emptySectionFilePath) | Should -BeTrue
		}

		It 'Should throw an error with null or empty filters' {
			{ Remove-NXTEmptyIniFile -Path "$rootPath\*" -Filter $null } | Should -Throw
			{ Remove-NXTEmptyIniFile -Path "$rootPath\*" -Filter '' } | Should -Throw
			{ Remove-NXTEmptyIniFile -Path "$rootPath\*" -Include $null } | Should -Throw
			{ Remove-NXTEmptyIniFile -Path "$rootPath\*" -Include '' } | Should -Throw
			{ Remove-NXTEmptyIniFile -Path "$rootPath\*" -Exclude $null } | Should -Throw
			{ Remove-NXTEmptyIniFile -Path "$rootPath\*" -Exclude '' } | Should -Throw
			[System.IO.File]::Exists($emptyFilePath) | Should -BeTrue
		}
	}

	Context 'When using WhatIf' {
		BeforeAll {
			New-TestFile
		}

		It 'Should not remove the file' {
			# The global preference variable is used, because the -WhatIf switch fails in PSADT 4.1 for callers outside of the module
			try {
				$global:WhatIfPreference = $true
				Remove-NXTEmptyIniFile -Path $emptyFilePath
			}
			finally {
				$global:WhatIfPreference = $false
			}
			[System.IO.File]::Exists($emptyFilePath) | Should -BeTrue
		}
	}
}
