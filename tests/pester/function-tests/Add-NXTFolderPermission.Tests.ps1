BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Add-NXTFolderPermission' {
	BeforeAll {
		# Identities
		[System.String]$sidEveryone = 'S-1-1-0'
		[System.String]$sidUsers = 'S-1-5-32-545'
		[System.String]$sidAuthenticatedUsers = 'S-1-5-11'

		# Folders
		[System.String]$rootPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName())
		[System.String]$folderPath = [System.IO.Path]::Combine($rootPath, 'folder')
		[System.String]$subFolderPath = [System.IO.Path]::Combine($folderPath, 'sub')
		[System.String]$filePath = [System.IO.Path]::Combine($rootPath, 'file.txt')
		[System.String]$folderPathNotExisting = [System.IO.Path]::Combine($rootPath, 'notExisting')
		function New-TestFolder {
			Remove-TestFolder
			$null = [System.IO.Directory]::CreateDirectory($subFolderPath)
			$null = [System.IO.Directory]::CreateDirectory([System.IO.Path]::Combine($rootPath, 'filter_a1'))
			$null = [System.IO.Directory]::CreateDirectory([System.IO.Path]::Combine($rootPath, 'filter_a2'))
			$null = [System.IO.Directory]::CreateDirectory([System.IO.Path]::Combine($rootPath, 'filter_b1'))
			[System.IO.File]::WriteAllText($filePath, 'content')
		}
		function Remove-TestFolder {
			if ([System.IO.Directory]::Exists($rootPath)) {
				$null = & icacls.exe $rootPath /reset /T /C /Q 2>&1
				Remove-Item -LiteralPath $rootPath -Recurse -Force -ErrorAction SilentlyContinue
			}
		}

		# Returns the combined explicit (not inherited) allow rights of an identity
		function Get-ExplicitRight {
			param (
				[System.String]$Path,
				[System.String]$Sid
			)
			[System.Security.AccessControl.FileSystemRights]$rights = 0
			foreach ($rule in (Get-Acl -LiteralPath $Path).GetAccessRules($true, $false, [System.Security.Principal.SecurityIdentifier])) {
				if ($rule.IdentityReference.Value -eq $Sid -and $rule.AccessControlType -eq [System.Security.AccessControl.AccessControlType]::Allow) {
					$rights = $rights -bor $rule.FileSystemRights
				}
			}
			return $rights
		}
		function Test-ExplicitRight {
			param (
				[System.String]$Path,
				[System.String]$Sid,
				[System.Security.AccessControl.FileSystemRights]$Rights
			)
			return ((Get-ExplicitRight -Path $Path -Sid $Sid) -band $Rights) -eq $Rights
		}
	}

	AfterAll {
		Remove-TestFolder
	}

	Context 'When using an invalid path' {
		BeforeAll {
			New-TestFolder
		}

		It 'Should throw an error with a non-existing path' {
			{ Add-NXTFolderPermission -Path $folderPathNotExisting -FullControl $sidEveryone } | Should -Throw
			{ Add-NXTFolderPermission -Path $folderPathNotExisting, $folderPath -FullControl $sidEveryone } | Should -Throw
		}

		It 'Should throw an error with null or empty path' {
			{ Add-NXTFolderPermission -Path $null -FullControl $sidEveryone } | Should -Throw
			{ Add-NXTFolderPermission -Path '' -FullControl $sidEveryone } | Should -Throw
			{ Add-NXTFolderPermission -Path $null, $folderPath -FullControl $sidEveryone } | Should -Throw
			{ Add-NXTFolderPermission -Path '', $folderPath -FullControl $sidEveryone } | Should -Throw
		}

		It 'Should throw an error with a wrong data type for path' {
			{ Add-NXTFolderPermission -Path 123 -FullControl $sidEveryone } | Should -Throw
		}

		It 'Should not change anything when the path is a file' {
			{ Add-NXTFolderPermission -Path $filePath -FullControl $sidEveryone } | Should -Not -Throw
			Get-ExplicitRight -Path $filePath -Sid $sidEveryone | Should -Be 0
		}
	}

	Context 'When using an invalid literal path' {
		BeforeAll {
			New-TestFolder
		}

		It 'Should throw an error with a literal path including wildcards' {
			{ Add-NXTFolderPermission -LiteralPath "$folderPath*" -FullControl $sidEveryone } | Should -Throw
		}

		It 'Should throw an error with a non-existing path' {
			{ Add-NXTFolderPermission -LiteralPath $folderPathNotExisting -FullControl $sidEveryone } | Should -Throw
		}

		It 'Should throw an error with null or empty path' {
			{ Add-NXTFolderPermission -LiteralPath $null -FullControl $sidEveryone } | Should -Throw
			{ Add-NXTFolderPermission -LiteralPath '' -FullControl $sidEveryone } | Should -Throw
		}
	}

	Context 'When using valid paths' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should add permissions with a path' {
			Add-NXTFolderPermission -Path $folderPath -FullControl $sidEveryone | Should -BeNullOrEmpty
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights FullControl | Should -BeTrue
		}

		It 'Should add permissions with a path including wildcards' {
			Add-NXTFolderPermission -Path "$rootPath\filter_a*" -FullControl $sidEveryone
			Test-ExplicitRight -Path "$rootPath\filter_a1" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Test-ExplicitRight -Path "$rootPath\filter_a2" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Get-ExplicitRight -Path "$rootPath\filter_b1" -Sid $sidEveryone | Should -Be 0
		}

		It 'Should add permissions with multiple paths' {
			Add-NXTFolderPermission -Path "$rootPath\filter_a1", "$rootPath\filter_b1" -FullControl $sidEveryone
			Test-ExplicitRight -Path "$rootPath\filter_a1" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Test-ExplicitRight -Path "$rootPath\filter_b1" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
		}

		It 'Should add permissions with a literal path' {
			Add-NXTFolderPermission -LiteralPath $folderPath -FullControl $sidEveryone | Should -BeNullOrEmpty
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights FullControl | Should -BeTrue
		}

		It 'Should add permissions with pipeline input' {
			Get-Item -LiteralPath $folderPath | Add-NXTFolderPermission -FullControl $sidEveryone | Should -BeNullOrEmpty
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights FullControl | Should -BeTrue
		}

		It 'Should add permissions with multiple pipeline inputs' {
			Get-Item -Path "$rootPath\filter_a*" | Add-NXTFolderPermission -FullControl $sidEveryone
			Test-ExplicitRight -Path "$rootPath\filter_a1" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Test-ExplicitRight -Path "$rootPath\filter_a2" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
		}
	}

	Context 'When using filter parameters' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should use Filter parameter' {
			Add-NXTFolderPermission -Path "$rootPath\*" -Filter 'filter_a*' -FullControl $sidEveryone
			Test-ExplicitRight -Path "$rootPath\filter_a1" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Test-ExplicitRight -Path "$rootPath\filter_a2" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Get-ExplicitRight -Path "$rootPath\filter_b1" -Sid $sidEveryone | Should -Be 0
		}

		It 'Should use Include parameter' {
			Add-NXTFolderPermission -Path "$rootPath\*" -Include 'filter_a1', 'filter_b*' -FullControl $sidEveryone
			Test-ExplicitRight -Path "$rootPath\filter_a1" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Get-ExplicitRight -Path "$rootPath\filter_a2" -Sid $sidEveryone | Should -Be 0
			Test-ExplicitRight -Path "$rootPath\filter_b1" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
		}

		It 'Should use Exclude parameter' {
			Add-NXTFolderPermission -Path "$rootPath\*" -Exclude 'filter_a*' -FullControl $sidEveryone
			Get-ExplicitRight -Path "$rootPath\filter_a1" -Sid $sidEveryone | Should -Be 0
			Get-ExplicitRight -Path "$rootPath\filter_a2" -Sid $sidEveryone | Should -Be 0
			Test-ExplicitRight -Path "$rootPath\filter_b1" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
		}

		It 'Should not change anything with an ineffective filter' {
			{ Add-NXTFolderPermission -Path "$rootPath\*" -Filter 'IneffectiveFilter' -FullControl $sidEveryone } | Should -Not -Throw
			Get-ExplicitRight -Path "$rootPath\filter_a1" -Sid $sidEveryone | Should -Be 0
		}

		It 'Should throw an error with null or empty filters' {
			{ Add-NXTFolderPermission -Path "$rootPath\*" -Filter $null -FullControl $sidEveryone } | Should -Throw
			{ Add-NXTFolderPermission -Path "$rootPath\*" -Filter '' -FullControl $sidEveryone } | Should -Throw
			{ Add-NXTFolderPermission -Path "$rootPath\*" -Include $null -FullControl $sidEveryone } | Should -Throw
			{ Add-NXTFolderPermission -Path "$rootPath\*" -Include '' -FullControl $sidEveryone } | Should -Throw
			{ Add-NXTFolderPermission -Path "$rootPath\*" -Exclude $null -FullControl $sidEveryone } | Should -Throw
			{ Add-NXTFolderPermission -Path "$rootPath\*" -Exclude '' -FullControl $sidEveryone } | Should -Throw
		}
	}

	Context 'When adding permission levels' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should add full control permissions' {
			Add-NXTFolderPermission -Path $folderPath -FullControl $sidEveryone
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights FullControl | Should -BeTrue
		}

		It 'Should add modify permissions' {
			Add-NXTFolderPermission -Path $folderPath -Modify $sidEveryone
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Modify | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights FullControl | Should -BeFalse
		}

		It 'Should add write permissions' {
			Add-NXTFolderPermission -Path $folderPath -Write $sidEveryone
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Write | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Modify | Should -BeFalse
		}

		It 'Should add read and execute permissions' {
			Add-NXTFolderPermission -Path $folderPath -ReadAndExecute $sidEveryone
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights ReadAndExecute | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Write | Should -BeFalse
		}

		It 'Should add multiple permission levels at once' {
			Add-NXTFolderPermission -Path $folderPath -FullControl $sidEveryone -Modify $sidUsers -ReadAndExecute $sidAuthenticatedUsers
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidUsers -Rights Modify | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidAuthenticatedUsers -Rights ReadAndExecute | Should -BeTrue
		}

		It 'Should add permissions for multiple identities' {
			Add-NXTFolderPermission -Path $folderPath -Modify $sidEveryone, $sidUsers
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Modify | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidUsers -Rights Modify | Should -BeTrue
		}

		It 'Should keep existing permissions' {
			Add-NXTFolderPermission -Path $folderPath -Modify $sidEveryone
			Add-NXTFolderPermission -Path $folderPath -ReadAndExecute $sidUsers
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Modify | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidUsers -Rights ReadAndExecute | Should -BeTrue
		}

		It 'Should apply permissions inheritable to sub-folders and files' {
			Add-NXTFolderPermission -Path $folderPath -Modify $sidEveryone
			[System.Security.AccessControl.FileSystemAccessRule]$rule = (Get-Acl -LiteralPath $folderPath).GetAccessRules($true, $false, [System.Security.Principal.SecurityIdentifier]) |
				Where-Object -FilterScript { $_.IdentityReference.Value -eq $sidEveryone }
			$rule.InheritanceFlags | Should -Be ([System.Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit')
			$rule.PropagationFlags | Should -Be ([System.Security.AccessControl.PropagationFlags]::None)
		}

		It 'Should accept identities in different formats' {
			Add-NXTFolderPermission -Path $folderPath `
				-FullControl ([System.Security.Principal.WellKnownSidType]::WorldSid) `
				-Modify 'BuiltinUsersSid' `
				-ReadAndExecute ([System.Security.Principal.SecurityIdentifier]::new($sidAuthenticatedUsers))
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidUsers -Rights Modify | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidAuthenticatedUsers -Rights ReadAndExecute | Should -BeTrue
		}

		It 'Should accept the parameter aliases' {
			Add-NXTFolderPermission -Path $folderPath -FullControlPermissions $sidEveryone -ModifyPermissions $sidUsers
			Add-NXTFolderPermission -Path $subFolderPath -WritePermissions $sidEveryone -ReadAndExecutePermissions $sidUsers
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidUsers -Rights Modify | Should -BeTrue
			Test-ExplicitRight -Path $subFolderPath -Sid $sidEveryone -Rights Write | Should -BeTrue
			Test-ExplicitRight -Path $subFolderPath -Sid $sidUsers -Rights ReadAndExecute | Should -BeTrue
		}

		It 'Should not change anything without permission parameters' {
			[System.String]$sddlBefore = (Get-Acl -LiteralPath $folderPath).Sddl
			Add-NXTFolderPermission -Path $folderPath | Should -BeNullOrEmpty
			(Get-Acl -LiteralPath $folderPath).Sddl | Should -Be $sddlBefore
		}
	}

	Context 'When using invalid identities' {
		BeforeAll {
			New-TestFolder
		}

		It 'Should throw an error with null or empty identities' -ForEach @(
			@{ level = 'FullControl' }, @{ level = 'Modify' }, @{ level = 'Write' }, @{ level = 'ReadAndExecute' }
		) {
			{ [System.Collections.Hashtable]$splat = @{ $level = $null }; Add-NXTFolderPermission -Path $folderPath @splat } | Should -Throw
			{ [System.Collections.Hashtable]$splat = @{ $level = '' }; Add-NXTFolderPermission -Path $folderPath @splat } | Should -Throw
			{ [System.Collections.Hashtable]$splat = @{ $level = @() }; Add-NXTFolderPermission -Path $folderPath @splat } | Should -Throw
			{ [System.Collections.Hashtable]$splat = @{ $level = @($sidEveryone, $null) }; Add-NXTFolderPermission -Path $folderPath @splat } | Should -Throw
		}

		It 'Should throw an error with a wrong data type for identities' -ForEach @(
			@{ level = 'FullControl' }, @{ level = 'Modify' }, @{ level = 'Write' }, @{ level = 'ReadAndExecute' }
		) {
			{ [System.Collections.Hashtable]$splat = @{ $level = 123 }; Add-NXTFolderPermission -Path $folderPath @splat } | Should -Throw
			{ [System.Collections.Hashtable]$splat = @{ $level = [System.Object]::new() }; Add-NXTFolderPermission -Path $folderPath @splat } | Should -Throw
		}
	}

	Context 'When using the recurse parameter' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should only add explicit permissions to the folder without recurse' {
			Add-NXTFolderPermission -Path $folderPath -Modify $sidEveryone
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Modify | Should -BeTrue
			Get-ExplicitRight -Path $subFolderPath -Sid $sidEveryone | Should -Be 0
		}

		It 'Should add explicit permissions to all sub-folders with recurse' {
			Add-NXTFolderPermission -Path $folderPath -Modify $sidEveryone -Recurse
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Modify | Should -BeTrue
			Test-ExplicitRight -Path $subFolderPath -Sid $sidEveryone -Rights Modify | Should -BeTrue
		}
	}

	Context 'When using WhatIf' {
		BeforeAll {
			New-TestFolder
		}

		It 'Should not change the permissions' {
			# The global preference variable is used, because the -WhatIf switch fails in PSADT 4.1 for callers outside of the module
			try {
				$global:WhatIfPreference = $true
				Add-NXTFolderPermission -Path $folderPath -FullControl $sidEveryone
			}
			finally {
				$global:WhatIfPreference = $false
			}
			Get-ExplicitRight -Path $folderPath -Sid $sidEveryone | Should -Be 0
		}
	}
}
