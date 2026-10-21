BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'New-NXTTemporaryFolder' {
	BeforeAll {
		# Identities
		[System.String]$sidUsers = 'S-1-5-32-545'
		[System.String]$sidSystem = 'S-1-5-18'
		[System.String]$sidCurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value

		# Base path of the temporary folders and the state before the tests
		[System.String]$basePath = [System.IO.Path]::Combine((Get-ADTEnvironmentTable).envTemp, 'n42Tmp')
		[System.String[]]$preExistingItems = @(if ([System.IO.Directory]::Exists($basePath)) { [System.IO.Directory]::GetFileSystemEntries($basePath) })

		# Removes all folders created by the tests
		function Remove-TestFolder {
			if (-not [System.IO.Directory]::Exists($basePath)) { return }
			if ($preExistingItems.Count -eq 0) {
				Remove-Item -LiteralPath $basePath -Recurse -Force -ErrorAction SilentlyContinue
				return
			}
			foreach ($item in [System.IO.Directory]::GetFileSystemEntries($basePath)) {
				if ($item -notin $preExistingItems) { Remove-Item -LiteralPath $item -Recurse -Force -ErrorAction SilentlyContinue }
			}
		}

		# Returns the highest numeric folder name in the base path
		function Get-HighestFolderNumber {
			[System.UInt32]$max = 0
			[System.UInt32]$number = 0
			foreach ($directory in [System.IO.Directory]::GetDirectories($basePath)) {
				if ([System.UInt32]::TryParse([System.IO.Path]::GetFileName($directory), [ref]$number) -and $number -gt $max) { $max = $number }
			}
			return $max
		}
	}

	AfterAll {
		Remove-TestFolder
	}

	Context 'When creating a temporary folder' {
		AfterEach {
			Remove-TestFolder
		}

		It 'Should return the created folder' {
			$result = New-NXTTemporaryFolder
			$result | Should -BeOfType [System.IO.DirectoryInfo]
			@($result).Count | Should -Be 1
			[System.IO.Directory]::Exists($result.FullName) | Should -BeTrue
		}

		It 'Should create the folder in the base path' {
			[System.IO.DirectoryInfo]$result = New-NXTTemporaryFolder
			$result.Parent.FullName | Should -Be ([System.IO.DirectoryInfo]::new($basePath).FullName)
		}

		It 'Should create the base path if missing' {
			if ($preExistingItems.Count -gt 0) {
				Set-ItResult -Skipped -Because "the base path [$basePath] contains items which were not created by the tests"
				return
			}
			Remove-TestFolder
			[System.IO.Directory]::Exists($basePath) | Should -BeFalse
			[System.IO.DirectoryInfo]$result = New-NXTTemporaryFolder
			[System.IO.Directory]::Exists($basePath) | Should -BeTrue
			$result.Name | Should -Be '1'
		}

		It 'Should name the folders with increasing numbers' {
			[System.IO.DirectoryInfo]$result1 = New-NXTTemporaryFolder
			[System.IO.DirectoryInfo]$result2 = New-NXTTemporaryFolder
			[System.UInt32]$number1 = $result1.Name
			[System.UInt32]$number2 = $result2.Name
			$number2 | Should -Be ($number1 + 1)
		}

		It 'Should use the next number after the highest existing number' {
			$null = New-NXTTemporaryFolder
			[System.UInt32]$nextNumber = (Get-HighestFolderNumber) + 10
			$null = [System.IO.Directory]::CreateDirectory([System.IO.Path]::Combine($basePath, $nextNumber))
			(New-NXTTemporaryFolder).Name | Should -Be ($nextNumber + 1)
		}

		It 'Should ignore non-numeric folder names' {
			$null = New-NXTTemporaryFolder
			[System.UInt32]$nextNumber = (Get-HighestFolderNumber) + 1
			$null = [System.IO.Directory]::CreateDirectory([System.IO.Path]::Combine($basePath, 'abc'))
			$null = [System.IO.Directory]::CreateDirectory([System.IO.Path]::Combine($basePath, "$($nextNumber + 10)abc"))
			(New-NXTTemporaryFolder).Name | Should -Be $nextNumber
		}
	}

	Context 'When checking the permissions of the temporary folder' {
		BeforeAll {
			[System.IO.DirectoryInfo]$folder = New-NXTTemporaryFolder
		}

		AfterAll {
			Remove-TestFolder
		}

		It 'Should set the current user as owner' {
			(Get-Acl -LiteralPath $folder.FullName).GetOwner([System.Security.Principal.SecurityIdentifier]).Value | Should -Be $sidCurrentUser
		}

		It 'Should set the predefined permissions' {
			Test-NXTFolderPermission -Path $folder.FullName -FullControl $sidCurrentUser, $sidSystem -ReadAndExecute $sidUsers | Should -BeTrue
		}

		It 'Should not grant more than read and execute permissions to users' {
			Test-NXTFolderPermission -Path $folder.FullName -Write $sidUsers | Should -BeFalse
		}

		It 'Should protect the permissions' {
			[System.Security.AccessControl.DirectorySecurity]$acl = Get-Acl -LiteralPath $folder.FullName
			$acl.AreAccessRulesProtected | Should -BeTrue
			$acl.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier]).IdentityReference.Value | Sort-Object -Unique | Should -Be (@($sidCurrentUser, $sidSystem, $sidUsers) | Sort-Object -Unique)
		}
	}

	Context 'When using invalid input' {
		It 'Should throw an error with any argument' {
			{ New-NXTTemporaryFolder -Path $basePath } | Should -Throw
			{ New-NXTTemporaryFolder $basePath } | Should -Throw
		}
	}

	Context 'When using WhatIf' {
		AfterAll {
			Remove-TestFolder
		}

		It 'Should not create a folder' {
			$null = New-NXTTemporaryFolder
			[System.Int32]$countBefore = [System.IO.Directory]::GetDirectories($basePath).Count
			# The global preference variable is used, because the -WhatIf switch fails in PSADT 4.1 for callers outside of the module
			try {
				$global:WhatIfPreference = $true
				New-NXTTemporaryFolder | Should -BeNullOrEmpty
			}
			finally {
				$global:WhatIfPreference = $false
			}
			[System.IO.Directory]::GetDirectories($basePath).Count | Should -Be $countBefore
		}
	}
}
