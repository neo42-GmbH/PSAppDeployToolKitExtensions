BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Set-NXTFolderPermission' {
	BeforeAll {
		# Identities
		[System.String]$sidEveryone = 'S-1-1-0'
		[System.String]$sidUsers = 'S-1-5-32-545'
		[System.String]$sidAuthenticatedUsers = 'S-1-5-11'
		[System.String]$sidAdministrators = 'S-1-5-32-544'
		[System.String]$sidCurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value

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

		# Returns the unique identities of all access rules
		function Get-RuleIdentity {
			param (
				[System.String]$Path,
				[System.Boolean]$IncludeInherited = $true
			)
			return (Get-Acl -LiteralPath $Path).GetAccessRules($true, $IncludeInherited, [System.Security.Principal.SecurityIdentifier]) | ForEach-Object -Process { $_.IdentityReference.Value } | Sort-Object -Unique
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
			{ Set-NXTFolderPermission -Path $folderPathNotExisting -FullControl $sidCurrentUser } | Should -Throw
			{ Set-NXTFolderPermission -Path $folderPathNotExisting, $folderPath -FullControl $sidCurrentUser } | Should -Throw
		}

		It 'Should throw an error with null or empty path' {
			{ Set-NXTFolderPermission -Path $null -FullControl $sidCurrentUser } | Should -Throw
			{ Set-NXTFolderPermission -Path '' -FullControl $sidCurrentUser } | Should -Throw
			{ Set-NXTFolderPermission -Path $null, $folderPath -FullControl $sidCurrentUser } | Should -Throw
			{ Set-NXTFolderPermission -Path '', $folderPath -FullControl $sidCurrentUser } | Should -Throw
		}

		It 'Should throw an error with a wrong data type for path' {
			{ Set-NXTFolderPermission -Path 123 -FullControl $sidCurrentUser } | Should -Throw
		}

		It 'Should not change anything when the path is a file' {
			[System.String]$sddlBefore = (Get-Acl -LiteralPath $filePath).Sddl
			{ Set-NXTFolderPermission -Path $filePath -FullControl $sidCurrentUser } | Should -Not -Throw
			(Get-Acl -LiteralPath $filePath).Sddl | Should -Be $sddlBefore
		}
	}

	Context 'When using an invalid literal path' {
		BeforeAll {
			New-TestFolder
		}

		It 'Should throw an error with a literal path including wildcards' {
			{ Set-NXTFolderPermission -LiteralPath "$folderPath*" -FullControl $sidCurrentUser } | Should -Throw
		}

		It 'Should throw an error with a non-existing path' {
			{ Set-NXTFolderPermission -LiteralPath $folderPathNotExisting -FullControl $sidCurrentUser } | Should -Throw
		}

		It 'Should throw an error with null or empty path' {
			{ Set-NXTFolderPermission -LiteralPath $null -FullControl $sidCurrentUser } | Should -Throw
			{ Set-NXTFolderPermission -LiteralPath '' -FullControl $sidCurrentUser } | Should -Throw
		}
	}

	Context 'When using valid paths' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should set permissions with a path' {
			Set-NXTFolderPermission -Path $folderPath -FullControl $sidCurrentUser | Should -BeNullOrEmpty
			Test-ExplicitRight -Path $folderPath -Sid $sidCurrentUser -Rights FullControl | Should -BeTrue
		}

		It 'Should set permissions with a path including wildcards' {
			Set-NXTFolderPermission -Path "$rootPath\filter_a*" -FullControl $sidCurrentUser, $sidEveryone
			Test-ExplicitRight -Path "$rootPath\filter_a1" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Test-ExplicitRight -Path "$rootPath\filter_a2" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Get-ExplicitRight -Path "$rootPath\filter_b1" -Sid $sidEveryone | Should -Be 0
		}

		It 'Should set permissions with multiple paths' {
			Set-NXTFolderPermission -Path "$rootPath\filter_a1", "$rootPath\filter_b1" -FullControl $sidCurrentUser, $sidEveryone
			Test-ExplicitRight -Path "$rootPath\filter_a1" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Test-ExplicitRight -Path "$rootPath\filter_b1" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
		}

		It 'Should set permissions with a literal path' {
			Set-NXTFolderPermission -LiteralPath $folderPath -FullControl $sidCurrentUser | Should -BeNullOrEmpty
			Test-ExplicitRight -Path $folderPath -Sid $sidCurrentUser -Rights FullControl | Should -BeTrue
		}

		It 'Should set permissions with pipeline input' {
			Get-Item -LiteralPath $folderPath | Set-NXTFolderPermission -FullControl $sidCurrentUser | Should -BeNullOrEmpty
			Test-ExplicitRight -Path $folderPath -Sid $sidCurrentUser -Rights FullControl | Should -BeTrue
		}

		It 'Should set permissions with multiple pipeline inputs' {
			Get-Item -Path "$rootPath\filter_a*" | Set-NXTFolderPermission -FullControl $sidCurrentUser, $sidEveryone
			Test-ExplicitRight -Path "$rootPath\filter_a1" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Test-ExplicitRight -Path "$rootPath\filter_a2" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
		}

		It 'Should set permissions using the alias' {
			Set-NXTFolderPermissions -Path $folderPath -FullControl $sidCurrentUser
			Test-ExplicitRight -Path $folderPath -Sid $sidCurrentUser -Rights FullControl | Should -BeTrue
		}
	}

	Context 'When using filter parameters' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should use Filter parameter' {
			Set-NXTFolderPermission -Path "$rootPath\*" -Filter 'filter_a*' -FullControl $sidCurrentUser, $sidEveryone
			Test-ExplicitRight -Path "$rootPath\filter_a1" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Test-ExplicitRight -Path "$rootPath\filter_a2" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Get-ExplicitRight -Path "$rootPath\filter_b1" -Sid $sidEveryone | Should -Be 0
		}

		It 'Should use Include parameter' {
			Set-NXTFolderPermission -Path "$rootPath\*" -Include 'filter_a1', 'filter_b*' -FullControl $sidCurrentUser, $sidEveryone
			Test-ExplicitRight -Path "$rootPath\filter_a1" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Get-ExplicitRight -Path "$rootPath\filter_a2" -Sid $sidEveryone | Should -Be 0
			Test-ExplicitRight -Path "$rootPath\filter_b1" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
		}

		It 'Should use Exclude parameter' {
			Set-NXTFolderPermission -Path "$rootPath\*" -Exclude 'filter_a*', 'folder' -FullControl $sidCurrentUser, $sidEveryone
			Get-ExplicitRight -Path "$rootPath\filter_a1" -Sid $sidEveryone | Should -Be 0
			Get-ExplicitRight -Path "$rootPath\filter_a2" -Sid $sidEveryone | Should -Be 0
			Get-ExplicitRight -Path $folderPath -Sid $sidEveryone | Should -Be 0
			Test-ExplicitRight -Path "$rootPath\filter_b1" -Sid $sidEveryone -Rights FullControl | Should -BeTrue
		}

		It 'Should not change anything with an ineffective filter' {
			[System.String]$sddlBefore = (Get-Acl -LiteralPath "$rootPath\filter_a1").Sddl
			{ Set-NXTFolderPermission -Path "$rootPath\*" -Filter 'IneffectiveFilter' -FullControl $sidCurrentUser } | Should -Not -Throw
			(Get-Acl -LiteralPath "$rootPath\filter_a1").Sddl | Should -Be $sddlBefore
		}

		It 'Should throw an error with null or empty filters' {
			{ Set-NXTFolderPermission -Path "$rootPath\*" -Filter $null -FullControl $sidCurrentUser } | Should -Throw
			{ Set-NXTFolderPermission -Path "$rootPath\*" -Filter '' -FullControl $sidCurrentUser } | Should -Throw
			{ Set-NXTFolderPermission -Path "$rootPath\*" -Include $null -FullControl $sidCurrentUser } | Should -Throw
			{ Set-NXTFolderPermission -Path "$rootPath\*" -Include '' -FullControl $sidCurrentUser } | Should -Throw
			{ Set-NXTFolderPermission -Path "$rootPath\*" -Exclude $null -FullControl $sidCurrentUser } | Should -Throw
			{ Set-NXTFolderPermission -Path "$rootPath\*" -Exclude '' -FullControl $sidCurrentUser } | Should -Throw
		}
	}

	Context 'When setting permission levels' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should set full control permissions' {
			Set-NXTFolderPermission -Path $folderPath -FullControl $sidCurrentUser
			Test-ExplicitRight -Path $folderPath -Sid $sidCurrentUser -Rights FullControl | Should -BeTrue
		}

		It 'Should set modify permissions' {
			Set-NXTFolderPermission -Path $folderPath -FullControl $sidCurrentUser -Modify $sidEveryone
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Modify | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights FullControl | Should -BeFalse
		}

		It 'Should set write permissions' {
			Set-NXTFolderPermission -Path $folderPath -FullControl $sidCurrentUser -Write $sidEveryone
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Write | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Modify | Should -BeFalse
		}

		It 'Should set read and execute permissions' {
			Set-NXTFolderPermission -Path $folderPath -FullControl $sidCurrentUser -ReadAndExecute $sidEveryone
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights ReadAndExecute | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Write | Should -BeFalse
		}

		It 'Should set permissions for multiple identities' {
			Set-NXTFolderPermission -Path $folderPath -FullControl $sidCurrentUser, $sidEveryone
			Test-ExplicitRight -Path $folderPath -Sid $sidCurrentUser -Rights FullControl | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights FullControl | Should -BeTrue
		}

		It 'Should replace existing permissions' {
			Set-NXTFolderPermission -Path $folderPath -FullControl $sidCurrentUser -Modify $sidUsers
			Set-NXTFolderPermission -Path $folderPath -FullControl $sidCurrentUser -ReadAndExecute $sidEveryone
			Get-ExplicitRight -Path $folderPath -Sid $sidUsers | Should -Be 0
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights ReadAndExecute | Should -BeTrue
		}

		It 'Should only contain the defined permissions' {
			Set-NXTFolderPermission -Path $folderPath -FullControl $sidCurrentUser -Modify $sidUsers
			Get-RuleIdentity -Path $folderPath | Should -Be (@($sidCurrentUser, $sidUsers) | Sort-Object)
		}

		It 'Should remove all permissions without permission parameters' {
			Set-NXTFolderPermission -Path $folderPath
			Get-RuleIdentity -Path $folderPath | Should -BeNullOrEmpty
		}

		It 'Should accept identities in different formats' {
			Set-NXTFolderPermission -Path $folderPath `
				-FullControl ([System.Security.Principal.WellKnownSidType]::WorldSid) `
				-Modify 'BuiltinUsersSid' `
				-ReadAndExecute ([System.Security.Principal.SecurityIdentifier]::new($sidAuthenticatedUsers))
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidUsers -Rights Modify | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidAuthenticatedUsers -Rights ReadAndExecute | Should -BeTrue
		}

		It 'Should accept the parameter aliases' {
			Set-NXTFolderPermission -Path $folderPath -FullControlPermissions $sidCurrentUser -ModifyPermissions $sidUsers -WritePermissions $sidEveryone -ReadAndExecutePermissions $sidAuthenticatedUsers
			Test-ExplicitRight -Path $folderPath -Sid $sidCurrentUser -Rights FullControl | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidUsers -Rights Modify | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Write | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidAuthenticatedUsers -Rights ReadAndExecute | Should -BeTrue
		}
	}

	Context 'When using invalid identities' {
		BeforeAll {
			New-TestFolder
		}

		It 'Should throw an error with null identities' -ForEach @(
			@{ level = 'FullControl' }, @{ level = 'Modify' }, @{ level = 'Write' }, @{ level = 'ReadAndExecute' }, @{ level = 'Owner' }
		) {
			{ [System.Collections.Hashtable]$splat = @{ $level = $null }; Set-NXTFolderPermission -Path $folderPath @splat } | Should -Throw
			{ [System.Collections.Hashtable]$splat = @{ $level = '' }; Set-NXTFolderPermission -Path $folderPath @splat } | Should -Throw
		}

		It 'Should throw an error with null in a collection of identities' -ForEach @(
			@{ level = 'FullControl' }, @{ level = 'Modify' }, @{ level = 'Write' }, @{ level = 'ReadAndExecute' }
		) {
			{ [System.Collections.Hashtable]$splat = @{ $level = @($sidCurrentUser, $null) }; Set-NXTFolderPermission -Path $folderPath @splat } | Should -Throw
		}

		It 'Should throw an error with a wrong data type for identities' -ForEach @(
			@{ level = 'FullControl' }, @{ level = 'Modify' }, @{ level = 'Write' }, @{ level = 'ReadAndExecute' }, @{ level = 'Owner' }
		) {
			{ [System.Collections.Hashtable]$splat = @{ $level = 123 }; Set-NXTFolderPermission -Path $folderPath @splat } | Should -Throw
			{ [System.Collections.Hashtable]$splat = @{ $level = [System.Object]::new() }; Set-NXTFolderPermission -Path $folderPath @splat } | Should -Throw
		}

		It 'Should throw an error with multiple owners' {
			{ Set-NXTFolderPermission -Path $folderPath -Owner $sidCurrentUser, $sidAdministrators } | Should -Throw
		}
	}

	Context 'When setting the owner' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should set the owner as security identifier' {
			Set-NXTFolderPermission -Path $folderPath -FullControl $sidCurrentUser -Owner $sidAdministrators
			(Get-Acl -LiteralPath $folderPath).GetOwner([System.Security.Principal.SecurityIdentifier]).Value | Should -Be $sidAdministrators
		}

		It 'Should set the owner as windows identity' {
			Set-NXTFolderPermission -Path $folderPath -FullControl $sidCurrentUser -Owner ([System.Security.Principal.WindowsIdentity]::GetCurrent())
			(Get-Acl -LiteralPath $folderPath).GetOwner([System.Security.Principal.SecurityIdentifier]).Value | Should -Be $sidCurrentUser
		}

		It 'Should keep the owner when not specified' {
			[System.String]$ownerBefore = (Get-Acl -LiteralPath $folderPath).GetOwner([System.Security.Principal.SecurityIdentifier]).Value
			Set-NXTFolderPermission -Path $folderPath -FullControl $sidCurrentUser
			(Get-Acl -LiteralPath $folderPath).GetOwner([System.Security.Principal.SecurityIdentifier]).Value | Should -Be $ownerBefore
		}
	}

	Context 'When using inheritance' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should protect the permissions by default' {
			Set-NXTFolderPermission -Path $folderPath -FullControl $sidCurrentUser
			[System.Security.AccessControl.DirectorySecurity]$acl = Get-Acl -LiteralPath $folderPath
			$acl.AreAccessRulesProtected | Should -BeTrue
			$acl.GetAccessRules($false, $true, [System.Security.Principal.SecurityIdentifier]).Count | Should -Be 0
		}

		It 'Should inherit the permissions with Inherit' {
			Set-NXTFolderPermission -Path $folderPath -FullControl $sidEveryone -Inherit
			[System.Security.AccessControl.DirectorySecurity]$acl = Get-Acl -LiteralPath $folderPath
			$acl.AreAccessRulesProtected | Should -BeFalse
			$acl.GetAccessRules($false, $true, [System.Security.Principal.SecurityIdentifier]).Count | Should -BeGreaterThan 0
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights FullControl | Should -BeTrue
		}

		It 'Should apply permissions inheritable to sub-folders and files' {
			Set-NXTFolderPermission -Path $folderPath -FullControl $sidCurrentUser -Modify $sidEveryone
			[System.Security.AccessControl.FileSystemAccessRule]$rule = (Get-Acl -LiteralPath $folderPath).GetAccessRules($true, $false, [System.Security.Principal.SecurityIdentifier]) |
				Where-Object -FilterScript { $_.IdentityReference.Value -eq $sidEveryone }
			$rule.InheritanceFlags | Should -Be ([System.Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit')
			Get-RuleIdentity -Path $subFolderPath | Should -Be (@($sidCurrentUser, $sidEveryone) | Sort-Object)
		}
	}

	Context 'When using a custom directory security' {
		BeforeEach {
			New-TestFolder
			[System.Security.AccessControl.DirectorySecurity]$customSecurity = [System.Security.AccessControl.DirectorySecurity]::new()
			$customSecurity.AddAccessRule(
				[System.Security.AccessControl.FileSystemAccessRule]::new(
					[System.Security.Principal.SecurityIdentifier]::new($sidUsers),
					[System.Security.AccessControl.FileSystemRights]::Read,
					[System.Security.AccessControl.AccessControlType]::Allow
				)
			)
		}

		It 'Should use the custom directory security as base' {
			Set-NXTFolderPermission -Path $folderPath -FullControl $sidCurrentUser -CustomDirectorySecurity $customSecurity
			Test-ExplicitRight -Path $folderPath -Sid $sidUsers -Rights Read | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidCurrentUser -Rights FullControl | Should -BeTrue
		}

		It 'Should throw an error with null' {
			{ Set-NXTFolderPermission -Path $folderPath -CustomDirectorySecurity $null } | Should -Throw
		}

		It 'Should throw an error with a wrong data type' {
			{ Set-NXTFolderPermission -Path $folderPath -CustomDirectorySecurity 'Invalid' } | Should -Throw
			{ Set-NXTFolderPermission -Path $folderPath -CustomDirectorySecurity ([System.Security.AccessControl.FileSecurity]::new()) } | Should -Throw
		}
	}

	Context 'When using the recurse parameter' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should only set explicit permissions on the folder without recurse' {
			Set-NXTFolderPermission -Path $folderPath -FullControl $sidCurrentUser -Modify $sidEveryone
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Modify | Should -BeTrue
			Get-ExplicitRight -Path $subFolderPath -Sid $sidEveryone | Should -Be 0
			(Get-Acl -LiteralPath $subFolderPath).AreAccessRulesProtected | Should -BeFalse
		}

		It 'Should set explicit permissions on all sub-folders with recurse' {
			Set-NXTFolderPermission -Path $folderPath -FullControl $sidCurrentUser -Modify $sidEveryone -Recurse
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Modify | Should -BeTrue
			Test-ExplicitRight -Path $subFolderPath -Sid $sidEveryone -Rights Modify | Should -BeTrue
			(Get-Acl -LiteralPath $subFolderPath).AreAccessRulesProtected | Should -BeTrue
		}
	}

	Context 'When using WhatIf' {
		BeforeAll {
			New-TestFolder
		}

		It 'Should not change the permissions' {
			[System.String]$sddlBefore = (Get-Acl -LiteralPath $folderPath).Sddl
			# The global preference variable is used, because the -WhatIf switch fails in PSADT 4.1 for callers outside of the module
			try {
				$global:WhatIfPreference = $true
				Set-NXTFolderPermission -Path $folderPath -FullControl $sidCurrentUser
			}
			finally {
				$global:WhatIfPreference = $false
			}
			(Get-Acl -LiteralPath $folderPath).Sddl | Should -Be $sddlBefore
		}
	}
}
