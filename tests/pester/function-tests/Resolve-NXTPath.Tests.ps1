BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Resolve-NXTPath' {
	BeforeAll {
		# TestDrive is disabled, so a unique temporary directory is used
		$testDir = (New-Item -ItemType Directory -Path ([System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "NxtPester_$([System.Guid]::NewGuid().ToString('N'))"))).FullName
		$null = New-Item -ItemType Directory -Path "$testDir\Sub"
		$null = New-Item -ItemType File -Path "$testDir\File1.txt", "$testDir\File2.log", "$testDir\Sub\Nested.txt"
		$null = New-Item -ItemType File -Path "$testDir\Hidden.txt"
		(Get-Item -LiteralPath "$testDir\Hidden.txt").Attributes = [System.IO.FileAttributes]::Hidden
		$null = New-Item -ItemType File -Path "$testDir\[Bracket].txt"

		$fileSystemPrefix = 'Microsoft.PowerShell.Core\FileSystem::'
	}

	AfterAll {
		Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
	}

	Context 'When resolving a path' {
		It 'Should return the qualified path' {
			Resolve-NXTPath -Path "$testDir\File1.txt" | Should -Be "$fileSystemPrefix$testDir\File1.txt"
		}

		It 'Should return the provider path' {
			Resolve-NXTPath -Path "$testDir\File1.txt" -AsProviderPath | Should -Be "$testDir\File1.txt"
		}

		It 'Should resolve a relative path' {
			Push-Location -LiteralPath $testDir
			try {
				Resolve-NXTPath -Path '.\File1.txt' -AsProviderPath | Should -Be "$testDir\File1.txt"
			}
			finally {
				Pop-Location
			}
		}

		It 'Should resolve multiple paths' {
			Resolve-NXTPath -Path "$testDir\File1.txt", "$testDir\File2.log" -AsProviderPath | Should -Be @("$testDir\File1.txt", "$testDir\File2.log")
		}

		It 'Should accept the path as positional parameter' {
			Resolve-NXTPath "$testDir\File1.txt" -AsProviderPath | Should -Be "$testDir\File1.txt"
		}
	}

	Context 'When using wildcards' {
		It 'Should resolve all matching items' {
			Resolve-NXTPath -Path "$testDir\*" -AsProviderPath | Sort-Object | Should -Be @("$testDir\[Bracket].txt", "$testDir\File1.txt", "$testDir\File2.log", "$testDir\Sub")
		}

		It 'Should include hidden items with Force' {
			Resolve-NXTPath -Path "$testDir\*" -AsProviderPath -Force | Should -Contain "$testDir\Hidden.txt"
		}

		It 'Should return nothing if no item matches' {
			Resolve-NXTPath -Path "$testDir\*.missing" | Should -BeNullOrEmpty
		}

		It 'Should treat brackets as wildcard characters' {
			Resolve-NXTPath -Path "$testDir\[Bracket].txt" | Should -BeNullOrEmpty
		}

		It 'Should not treat brackets as wildcard characters in a literal path' {
			Resolve-NXTPath -LiteralPath "$testDir\[Bracket].txt" -AsProviderPath | Should -Be "$testDir\[Bracket].txt"
		}
	}

	Context 'When the path does not exist' {
		It 'Should throw an exception' {
			{ Resolve-NXTPath -Path "$testDir\Missing.txt" } | Should -Throw -ErrorId 'ItemNotFound,Resolve-NXTPath'
		}

		It 'Should throw an exception for a literal path' {
			{ Resolve-NXTPath -LiteralPath "$testDir\Missing.txt" } | Should -Throw -ErrorId 'ItemNotFound,Resolve-NXTPath'
		}

		It 'Should return the path with IncludeNonExistent' {
			Resolve-NXTPath -Path "$testDir\Missing.txt" -IncludeNonExistent | Should -Be "$fileSystemPrefix$testDir\Missing.txt"
			Resolve-NXTPath -Path "$testDir\Missing.txt" -IncludeNonExistent -AsProviderPath | Should -Be "$testDir\Missing.txt"
		}

		It 'Should not return a wildcard path with IncludeNonExistent' {
			Resolve-NXTPath -Path "$testDir\*.missing" -IncludeNonExistent | Should -BeNullOrEmpty
		}
	}

	Context 'When filtering the items' {
		It 'Should apply the filter' {
			Resolve-NXTPath -Path "$testDir\*" -Filter '*.txt' -AsProviderPath | Sort-Object | Should -Be @("$testDir\[Bracket].txt", "$testDir\File1.txt")
		}

		It 'Should apply the include patterns' {
			Resolve-NXTPath -Path "$testDir\*" -Include 'File*' -AsProviderPath | Sort-Object | Should -Be @("$testDir\File1.txt", "$testDir\File2.log")
		}

		It 'Should apply the exclude patterns' {
			Resolve-NXTPath -Path "$testDir\*" -Exclude '*.log', 'Sub' -AsProviderPath | Sort-Object | Should -Be @("$testDir\[Bracket].txt", "$testDir\File1.txt")
		}

		It 'Should return only leafs' {
			Resolve-NXTPath -Path "$testDir\*" -PathType Leaf -AsProviderPath | Should -Not -Contain "$testDir\Sub"
		}

		It 'Should return only containers' {
			Resolve-NXTPath -Path "$testDir\*" -PathType Container -AsProviderPath | Should -Be "$testDir\Sub"
		}
	}

	Context 'When using a provider' {
		It 'Should resolve a registry drive path' {
			Resolve-NXTPath -Path 'HKLM:\SOFTWARE' | Should -Be 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE'
			Resolve-NXTPath -Path 'HKLM:\SOFTWARE' -AsProviderPath | Should -Be 'HKEY_LOCAL_MACHINE\SOFTWARE'
		}

		It 'Should resolve a native path of the specified provider' {
			Resolve-NXTPath -Path 'HKEY_LOCAL_MACHINE\SOFTWARE' -ProviderName 'Registry' | Should -Be 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE'
		}

		It 'Should throw an exception if the path does not match the specified provider' {
			{ Resolve-NXTPath -Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE' -ProviderName 'FileSystem' } | Should -Throw -ErrorId 'InvalidProviderPath,Resolve-NXTPath'
		}
	}

	Context 'When using the pipeline' {
		It 'Should resolve an item from the pipeline' {
			Get-Item -LiteralPath "$testDir\File1.txt" | Resolve-NXTPath -AsProviderPath | Should -Be "$testDir\File1.txt"
		}

		It 'Should resolve a literal item path from the pipeline' {
			Get-Item -LiteralPath "$testDir\[Bracket].txt" | Resolve-NXTPath -AsProviderPath | Should -Be "$testDir\[Bracket].txt"
		}

		It 'Should resolve a registry item from the pipeline' {
			Get-Item -LiteralPath 'HKLM:\SOFTWARE' | Resolve-NXTPath -AsProviderPath | Should -Be 'HKEY_LOCAL_MACHINE\SOFTWARE'
		}
	}

	Context 'When passing unbound arguments' {
		It 'Should ignore parameters which are not path parameters' {
			Resolve-NXTPath -Path "$testDir\File1.txt" -AsProviderPath -Recurse -Value 'Ignored' | Should -Be "$testDir\File1.txt"
		}
	}

	Context 'When validating parameters' {
		It 'Should throw an exception with null path' {
			{ Resolve-NXTPath -Path $null } | Should -Throw
		}

		It 'Should throw an exception with empty path' {
			{ Resolve-NXTPath -Path '' } | Should -Throw
		}

		It 'Should throw an exception with an invalid path type' {
			{ Resolve-NXTPath -Path $testDir -PathType 'Invalid' } | Should -Throw
		}

		It 'Should throw an exception with an unknown provider' {
			{ Resolve-NXTPath -Path $testDir -ProviderName 'Missing' } | Should -Throw
		}
	}
}
