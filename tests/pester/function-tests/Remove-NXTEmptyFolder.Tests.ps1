BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Remove-NXTEmptyFolder' {
	BeforeAll {
		# Folders
		[System.String]$rootPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName())
		[System.String]$emptyFolderPath = [System.IO.Path]::Combine($rootPath, 'empty')
		[System.String]$emptyFolderPath2 = [System.IO.Path]::Combine($rootPath, 'empty2')
		[System.String]$notEmptyFolderPath = [System.IO.Path]::Combine($rootPath, 'notEmpty')
		[System.String]$hiddenFolderPath = [System.IO.Path]::Combine($rootPath, 'hidden')
		[System.String]$nestedRootPath = [System.IO.Path]::Combine($rootPath, 'nested')
		[System.String]$nestedPath1 = [System.IO.Path]::Combine($nestedRootPath, 'level1')
		[System.String]$nestedPath2 = [System.IO.Path]::Combine($nestedPath1, 'level2')
		[System.String]$nestedPath3 = [System.IO.Path]::Combine($nestedPath2, 'level3')
		[System.String]$filePath = [System.IO.Path]::Combine($rootPath, 'file.txt')
		[System.String]$folderPathNotExisting = [System.IO.Path]::Combine($rootPath, 'notExisting')
		function New-TestFolder {
			Remove-TestFolder
			$null = [System.IO.Directory]::CreateDirectory($emptyFolderPath)
			$null = [System.IO.Directory]::CreateDirectory($emptyFolderPath2)
			$null = [System.IO.Directory]::CreateDirectory($notEmptyFolderPath)
			[System.IO.File]::WriteAllText([System.IO.Path]::Combine($notEmptyFolderPath, 'file.txt'), 'content')
			[System.IO.DirectoryInfo]$hiddenFolder = [System.IO.Directory]::CreateDirectory($hiddenFolderPath)
			$hiddenFolder.Attributes = $hiddenFolder.Attributes -bor [System.IO.FileAttributes]::Hidden
			$null = [System.IO.Directory]::CreateDirectory($nestedPath3)
			[System.IO.File]::WriteAllText($filePath, 'content')
		}
		function Remove-TestFolder {
			Remove-Item -LiteralPath $rootPath -Recurse -Force -ErrorAction SilentlyContinue
		}
	}

	AfterAll {
		Remove-TestFolder
	}

	Context 'When using an invalid path' {
		BeforeAll {
			New-TestFolder
		}

		It 'Should throw an error with null or empty path' {
			{ Remove-NXTEmptyFolder -Path $null } | Should -Throw
			{ Remove-NXTEmptyFolder -Path '' } | Should -Throw
			{ Remove-NXTEmptyFolder -Path $null, $emptyFolderPath } | Should -Throw
			{ Remove-NXTEmptyFolder -Path '', $emptyFolderPath } | Should -Throw
			[System.IO.Directory]::Exists($emptyFolderPath) | Should -BeTrue
		}

		It 'Should not throw an error with a non-existing path' {
			{ Remove-NXTEmptyFolder -Path $folderPathNotExisting } | Should -Not -Throw
		}

		It 'Should not remove a file' {
			Remove-NXTEmptyFolder -Path $filePath
			[System.IO.File]::Exists($filePath) | Should -BeTrue
		}
	}

	Context 'When using an invalid literal path' {
		BeforeAll {
			New-TestFolder
		}

		It 'Should throw an error with null or empty path' {
			{ Remove-NXTEmptyFolder -LiteralPath $null } | Should -Throw
			{ Remove-NXTEmptyFolder -LiteralPath '' } | Should -Throw
		}

		It 'Should not resolve wildcards' {
			Remove-NXTEmptyFolder -LiteralPath "$rootPath\empty*"
			[System.IO.Directory]::Exists($emptyFolderPath) | Should -BeTrue
			[System.IO.Directory]::Exists($emptyFolderPath2) | Should -BeTrue
		}
	}

	Context 'When removing folders' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should remove an empty folder' {
			Remove-NXTEmptyFolder -Path $emptyFolderPath | Should -BeNullOrEmpty
			[System.IO.Directory]::Exists($emptyFolderPath) | Should -BeFalse
		}

		It 'Should not remove a folder which is not empty' {
			{ Remove-NXTEmptyFolder -Path $notEmptyFolderPath } | Should -Not -Throw
			[System.IO.Directory]::Exists($notEmptyFolderPath) | Should -BeTrue
		}

		It 'Should not remove a folder which only contains an empty folder' {
			Remove-NXTEmptyFolder -Path $nestedPath2
			[System.IO.Directory]::Exists($nestedPath2) | Should -BeTrue
			[System.IO.Directory]::Exists($nestedPath3) | Should -BeTrue
		}

		It 'Should remove multiple folders' {
			Remove-NXTEmptyFolder -Path $emptyFolderPath, $emptyFolderPath2, $notEmptyFolderPath
			[System.IO.Directory]::Exists($emptyFolderPath) | Should -BeFalse
			[System.IO.Directory]::Exists($emptyFolderPath2) | Should -BeFalse
			[System.IO.Directory]::Exists($notEmptyFolderPath) | Should -BeTrue
		}

		It 'Should remove folders with a path including wildcards' {
			Remove-NXTEmptyFolder -Path "$rootPath\empty*"
			[System.IO.Directory]::Exists($emptyFolderPath) | Should -BeFalse
			[System.IO.Directory]::Exists($emptyFolderPath2) | Should -BeFalse
			[System.IO.Directory]::Exists($notEmptyFolderPath) | Should -BeTrue
		}

		It 'Should remove a folder with a literal path' {
			Remove-NXTEmptyFolder -LiteralPath $emptyFolderPath
			[System.IO.Directory]::Exists($emptyFolderPath) | Should -BeFalse
		}

		It 'Should remove folders with pipeline input' {
			Get-Item -Path $emptyFolderPath, $emptyFolderPath2, $notEmptyFolderPath | Remove-NXTEmptyFolder
			[System.IO.Directory]::Exists($emptyFolderPath) | Should -BeFalse
			[System.IO.Directory]::Exists($emptyFolderPath2) | Should -BeFalse
			[System.IO.Directory]::Exists($notEmptyFolderPath) | Should -BeTrue
		}

		It 'Should not remove the parent folder by default' {
			Remove-NXTEmptyFolder -Path $nestedPath3
			[System.IO.Directory]::Exists($nestedPath3) | Should -BeFalse
			[System.IO.Directory]::Exists($nestedPath2) | Should -BeTrue
		}
	}

	Context 'When using filter parameters' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should use Filter parameter' {
			Remove-NXTEmptyFolder -Path "$rootPath\*" -Filter 'empty*'
			[System.IO.Directory]::Exists($emptyFolderPath) | Should -BeFalse
			[System.IO.Directory]::Exists($emptyFolderPath2) | Should -BeFalse
			[System.IO.Directory]::Exists($nestedRootPath) | Should -BeTrue
		}

		It 'Should use Include parameter' {
			Remove-NXTEmptyFolder -Path "$rootPath\*" -Include 'empty2'
			[System.IO.Directory]::Exists($emptyFolderPath) | Should -BeTrue
			[System.IO.Directory]::Exists($emptyFolderPath2) | Should -BeFalse
		}

		It 'Should use Exclude parameter' {
			Remove-NXTEmptyFolder -Path "$rootPath\*" -Exclude 'empty2'
			[System.IO.Directory]::Exists($emptyFolderPath) | Should -BeFalse
			[System.IO.Directory]::Exists($emptyFolderPath2) | Should -BeTrue
			[System.IO.Directory]::Exists($notEmptyFolderPath) | Should -BeTrue
		}

		It 'Should not remove anything with an ineffective filter' {
			Remove-NXTEmptyFolder -Path "$rootPath\*" -Filter 'IneffectiveFilter'
			[System.IO.Directory]::Exists($emptyFolderPath) | Should -BeTrue
			[System.IO.Directory]::Exists($emptyFolderPath2) | Should -BeTrue
		}

		It 'Should throw an error with null or empty filters' {
			{ Remove-NXTEmptyFolder -Path "$rootPath\*" -Filter $null } | Should -Throw
			{ Remove-NXTEmptyFolder -Path "$rootPath\*" -Filter '' } | Should -Throw
			{ Remove-NXTEmptyFolder -Path "$rootPath\*" -Include $null } | Should -Throw
			{ Remove-NXTEmptyFolder -Path "$rootPath\*" -Include '' } | Should -Throw
			{ Remove-NXTEmptyFolder -Path "$rootPath\*" -Exclude $null } | Should -Throw
			{ Remove-NXTEmptyFolder -Path "$rootPath\*" -Exclude '' } | Should -Throw
			[System.IO.Directory]::Exists($emptyFolderPath) | Should -BeTrue
		}
	}

	Context 'When using hidden folders' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should not resolve hidden folders by wildcard without Force' {
			Remove-NXTEmptyFolder -Path "$rootPath\hid*"
			[System.IO.Directory]::Exists($hiddenFolderPath) | Should -BeTrue
		}

		It 'Should resolve hidden folders by wildcard with Force' {
			Remove-NXTEmptyFolder -Path "$rootPath\hid*" -Force
			[System.IO.Directory]::Exists($hiddenFolderPath) | Should -BeFalse
		}
	}

	Context 'When using a root path' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should remove all empty folders up to the root path' {
			Remove-NXTEmptyFolder -Path $nestedPath3 -RootPath $nestedRootPath
			[System.IO.Directory]::Exists($nestedPath1) | Should -BeFalse
			[System.IO.Directory]::Exists($nestedRootPath) | Should -BeTrue
		}

		It 'Should stop at the first folder which is not empty' {
			[System.IO.File]::WriteAllText([System.IO.Path]::Combine($nestedPath1, 'file.txt'), 'content')
			Remove-NXTEmptyFolder -Path $nestedPath3 -RootPath $nestedRootPath
			[System.IO.Directory]::Exists($nestedPath2) | Should -BeFalse
			[System.IO.Directory]::Exists($nestedPath1) | Should -BeTrue
		}

		It 'Should remove nothing when the folder is the root path' {
			Remove-NXTEmptyFolder -Path $nestedPath3 -RootPath $nestedPath3
			[System.IO.Directory]::Exists($nestedPath3) | Should -BeTrue
		}

		It 'Should accept a root path with a trailing separator' {
			Remove-NXTEmptyFolder -Path $nestedPath3 -RootPath "$nestedRootPath\"
			[System.IO.Directory]::Exists($nestedPath1) | Should -BeFalse
			[System.IO.Directory]::Exists($nestedRootPath) | Should -BeTrue
		}

		It 'Should accept the parameter alias' {
			Remove-NXTEmptyFolder -Path $nestedPath3 -RootPathToRecurseUpTo $nestedRootPath
			[System.IO.Directory]::Exists($nestedPath1) | Should -BeFalse
		}

		It 'Should remove the existing empty parents of a non-existing folder' {
			Remove-NXTEmptyFolder -Path ([System.IO.Path]::Combine($nestedPath3, 'notExisting')) -RootPath $nestedRootPath
			[System.IO.Directory]::Exists($nestedPath1) | Should -BeFalse
			[System.IO.Directory]::Exists($nestedRootPath) | Should -BeTrue
		}

		It 'Should throw an error when the folder is not a sub-folder of the root path' {
			{ Remove-NXTEmptyFolder -Path $nestedPath3 -RootPath $emptyFolderPath } | Should -Throw
			{ Remove-NXTEmptyFolder -Path $nestedRootPath -RootPath $nestedPath3 } | Should -Throw
			[System.IO.Directory]::Exists($nestedPath3) | Should -BeTrue
		}

		It 'Should throw an error with an invalid root path' {
			{ Remove-NXTEmptyFolder -Path $nestedPath3 -RootPath 'relative\path' } | Should -Throw
			{ Remove-NXTEmptyFolder -Path $nestedPath3 -RootPath '' } | Should -Throw
			{ Remove-NXTEmptyFolder -Path $nestedPath3 -RootPath $null } | Should -Throw
			[System.IO.Directory]::Exists($nestedPath3) | Should -BeTrue
		}
	}

	Context 'When using WhatIf' {
		BeforeAll {
			New-TestFolder
		}

		It 'Should not remove the folder' {
			# The global preference variable is used, because the -WhatIf switch fails in PSADT 4.1 for callers outside of the module
			try {
				$global:WhatIfPreference = $true
				Remove-NXTEmptyFolder -Path $nestedPath3 -RootPath $nestedRootPath
			}
			finally {
				$global:WhatIfPreference = $false
			}
			[System.IO.Directory]::Exists($nestedPath3) | Should -BeTrue
		}
	}
}
