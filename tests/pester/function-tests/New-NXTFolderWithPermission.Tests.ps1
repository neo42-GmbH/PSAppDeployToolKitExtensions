BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'New-NXTFolderWithPermission' {
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
		[System.String]$folderPath2 = [System.IO.Path]::Combine($rootPath, 'folder2')
		[System.String]$nestedFolderPath = [System.IO.Path]::Combine($rootPath, 'parent', 'child')
		function New-TestFolder {
			Remove-TestFolder
			$null = [System.IO.Directory]::CreateDirectory($rootPath)
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

		It 'Should throw an error with null or empty path' {
			{ New-NXTFolderWithPermission -Path $null -FullControl $sidEveryone } | Should -Throw
			{ New-NXTFolderWithPermission -Path '' -FullControl $sidEveryone } | Should -Throw
			{ New-NXTFolderWithPermission -Path $null, $folderPath -FullControl $sidEveryone } | Should -Throw
			{ New-NXTFolderWithPermission -Path '', $folderPath -FullControl $sidEveryone } | Should -Throw
		}

		It 'Should throw an error with invalid characters in path' {
			{ New-NXTFolderWithPermission -Path "$rootPath\inva|id" -FullControl $sidEveryone } | Should -Throw
		}

		It 'Should not change anything when the path is an existing file' {
			[System.String]$filePath = [System.IO.Path]::Combine($rootPath, 'file.txt')
			[System.IO.File]::WriteAllText($filePath, 'content')
			New-NXTFolderWithPermission -Path $filePath -FullControl $sidEveryone -Force -PassThru | Should -BeNullOrEmpty
			[System.IO.File]::Exists($filePath) | Should -BeTrue
			Get-ExplicitRight -Path $filePath -Sid $sidEveryone | Should -Be 0
		}
	}

	Context 'When creating folders' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should create a folder' {
			New-NXTFolderWithPermission -Path $folderPath -FullControl $sidCurrentUser | Should -BeNullOrEmpty
			[System.IO.Directory]::Exists($folderPath) | Should -BeTrue
		}

		It 'Should create multiple folders' {
			New-NXTFolderWithPermission -Path $folderPath, $folderPath2 -FullControl $sidCurrentUser
			[System.IO.Directory]::Exists($folderPath) | Should -BeTrue
			[System.IO.Directory]::Exists($folderPath2) | Should -BeTrue
		}

		It 'Should create a nested folder structure' {
			New-NXTFolderWithPermission -Path $nestedFolderPath -FullControl $sidCurrentUser
			[System.IO.Directory]::Exists($nestedFolderPath) | Should -BeTrue
			Test-ExplicitRight -Path $nestedFolderPath -Sid $sidCurrentUser -Rights FullControl | Should -BeTrue
		}

		It 'Should create a folder using the alias' {
			New-NxtFolderWithPermissions -Path $folderPath -FullControl $sidCurrentUser
			[System.IO.Directory]::Exists($folderPath) | Should -BeTrue
		}

		It 'Should create a folder without permission parameters' {
			New-NXTFolderWithPermission -Path $folderPath
			[System.IO.Directory]::Exists($folderPath) | Should -BeTrue
		}

		It 'Should return the created folder with PassThru' {
			$result = New-NXTFolderWithPermission -Path $folderPath -FullControl $sidCurrentUser -PassThru
			$result | Should -BeOfType [System.IO.DirectoryInfo]
			$result.FullName | Should -Be $folderPath
		}

		It 'Should return all created folders with PassThru' {
			$result = New-NXTFolderWithPermission -Path $folderPath, $folderPath2 -FullControl $sidCurrentUser -PassThru
			$result.Count | Should -Be 2
			$result.FullName | Should -Be @($folderPath, $folderPath2)
		}
	}

	Context 'When the folder already exists' {
		BeforeEach {
			New-TestFolder
			$null = [System.IO.Directory]::CreateDirectory($folderPath)
			[System.IO.File]::WriteAllText([System.IO.Path]::Combine($folderPath, 'file.txt'), 'content')
		}

		It 'Should throw an error without Force' {
			{ New-NXTFolderWithPermission -Path $folderPath -FullControl $sidEveryone } | Should -Throw
			Get-ExplicitRight -Path $folderPath -Sid $sidEveryone | Should -Be 0
		}

		It 'Should apply the permissions with Force' {
			{ New-NXTFolderWithPermission -Path $folderPath -FullControl $sidEveryone -Force } | Should -Not -Throw
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights FullControl | Should -BeTrue
		}
	}

	Context 'When setting permission levels' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should set full control permissions' {
			New-NXTFolderWithPermission -Path $folderPath -FullControl $sidEveryone
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights FullControl | Should -BeTrue
		}

		It 'Should set modify permissions' {
			New-NXTFolderWithPermission -Path $folderPath -FullControl $sidCurrentUser -Modify $sidEveryone
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Modify | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights FullControl | Should -BeFalse
		}

		It 'Should set write permissions' {
			New-NXTFolderWithPermission -Path $folderPath -FullControl $sidCurrentUser -Write $sidEveryone
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Write | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Modify | Should -BeFalse
		}

		It 'Should set read and execute permissions' {
			New-NXTFolderWithPermission -Path $folderPath -FullControl $sidCurrentUser -ReadAndExecute $sidEveryone
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights ReadAndExecute | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights Write | Should -BeFalse
		}

		It 'Should set permissions for multiple identities' {
			New-NXTFolderWithPermission -Path $folderPath -FullControl $sidCurrentUser, $sidEveryone
			Test-ExplicitRight -Path $folderPath -Sid $sidCurrentUser -Rights FullControl | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights FullControl | Should -BeTrue
		}

		It 'Should only contain the defined permissions' {
			New-NXTFolderWithPermission -Path $folderPath -FullControl $sidCurrentUser -Modify $sidUsers
			[System.Security.AccessControl.AuthorizationRuleCollection]$rules = (Get-Acl -LiteralPath $folderPath).GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier])
			$rules.IdentityReference.Value | Sort-Object -Unique | Should -Be (@($sidCurrentUser, $sidUsers) | Sort-Object)
		}

		It 'Should accept identities in different formats' {
			New-NXTFolderWithPermission -Path $folderPath `
				-FullControl ([System.Security.Principal.WellKnownSidType]::WorldSid) `
				-Modify 'BuiltinUsersSid' `
				-ReadAndExecute ([System.Security.Principal.SecurityIdentifier]::new($sidAuthenticatedUsers))
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights FullControl | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidUsers -Rights Modify | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidAuthenticatedUsers -Rights ReadAndExecute | Should -BeTrue
		}

		It 'Should accept the parameter aliases' {
			New-NXTFolderWithPermission -Path $folderPath -FullControlPermissions $sidCurrentUser -ModifyPermissions $sidUsers -WritePermissions $sidEveryone -ReadAndExecutePermissions $sidAuthenticatedUsers
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

		It 'Should throw an error with null or empty identities' -ForEach @(
			@{ level = 'FullControl' }, @{ level = 'Modify' }, @{ level = 'Write' }, @{ level = 'ReadAndExecute' }, @{ level = 'Owner' }
		) {
			{ [System.Collections.Hashtable]$splat = @{ $level = $null }; New-NXTFolderWithPermission -Path $folderPath @splat } | Should -Throw
			{ [System.Collections.Hashtable]$splat = @{ $level = '' }; New-NXTFolderWithPermission -Path $folderPath @splat } | Should -Throw
			[System.IO.Directory]::Exists($folderPath) | Should -BeFalse
		}

		It 'Should throw an error with an empty collection of identities' -ForEach @(
			@{ level = 'FullControl' }, @{ level = 'Modify' }, @{ level = 'Write' }, @{ level = 'ReadAndExecute' }
		) {
			{ [System.Collections.Hashtable]$splat = @{ $level = @() }; New-NXTFolderWithPermission -Path $folderPath @splat } | Should -Throw
			{ [System.Collections.Hashtable]$splat = @{ $level = @($sidEveryone, $null) }; New-NXTFolderWithPermission -Path $folderPath @splat } | Should -Throw
			[System.IO.Directory]::Exists($folderPath) | Should -BeFalse
		}

		It 'Should throw an error with a wrong data type for identities' -ForEach @(
			@{ level = 'FullControl' }, @{ level = 'Modify' }, @{ level = 'Write' }, @{ level = 'ReadAndExecute' }, @{ level = 'Owner' }
		) {
			{ [System.Collections.Hashtable]$splat = @{ $level = 123 }; New-NXTFolderWithPermission -Path $folderPath @splat } | Should -Throw
			{ [System.Collections.Hashtable]$splat = @{ $level = [System.Object]::new() }; New-NXTFolderWithPermission -Path $folderPath @splat } | Should -Throw
			[System.IO.Directory]::Exists($folderPath) | Should -BeFalse
		}

		It 'Should throw an error with multiple owners' {
			{ New-NXTFolderWithPermission -Path $folderPath -Owner $sidCurrentUser, $sidAdministrators } | Should -Throw
		}
	}

	Context 'When setting the owner' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should set the owner as security identifier' {
			New-NXTFolderWithPermission -Path $folderPath -FullControl $sidCurrentUser -Owner $sidAdministrators
			(Get-Acl -LiteralPath $folderPath).GetOwner([System.Security.Principal.SecurityIdentifier]).Value | Should -Be $sidAdministrators
		}

		It 'Should set the owner as well known sid type' {
			New-NXTFolderWithPermission -Path $folderPath -FullControl $sidCurrentUser -Owner ([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid)
			(Get-Acl -LiteralPath $folderPath).GetOwner([System.Security.Principal.SecurityIdentifier]).Value | Should -Be $sidAdministrators
		}

		It 'Should set the owner as windows identity' {
			New-NXTFolderWithPermission -Path $folderPath -FullControl $sidCurrentUser -Owner ([System.Security.Principal.WindowsIdentity]::GetCurrent())
			(Get-Acl -LiteralPath $folderPath).GetOwner([System.Security.Principal.SecurityIdentifier]).Value | Should -Be $sidCurrentUser
		}
	}

	Context 'When using inheritance' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should protect the permissions by default' {
			New-NXTFolderWithPermission -Path $folderPath -FullControl $sidCurrentUser
			[System.Security.AccessControl.DirectorySecurity]$acl = Get-Acl -LiteralPath $folderPath
			$acl.AreAccessRulesProtected | Should -BeTrue
			$acl.GetAccessRules($false, $true, [System.Security.Principal.SecurityIdentifier]).Count | Should -Be 0
		}

		It 'Should inherit the permissions with Inherit' {
			New-NXTFolderWithPermission -Path $folderPath -FullControl $sidEveryone -Inherit
			[System.Security.AccessControl.DirectorySecurity]$acl = Get-Acl -LiteralPath $folderPath
			$acl.AreAccessRulesProtected | Should -BeFalse
			$acl.GetAccessRules($false, $true, [System.Security.Principal.SecurityIdentifier]).Count | Should -BeGreaterThan 0
			Test-ExplicitRight -Path $folderPath -Sid $sidEveryone -Rights FullControl | Should -BeTrue
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
			New-NXTFolderWithPermission -Path $folderPath -FullControl $sidCurrentUser -CustomDirectorySecurity $customSecurity
			Test-ExplicitRight -Path $folderPath -Sid $sidUsers -Rights Read | Should -BeTrue
			Test-ExplicitRight -Path $folderPath -Sid $sidCurrentUser -Rights FullControl | Should -BeTrue
		}

		It 'Should throw an error with null' {
			{ New-NXTFolderWithPermission -Path $folderPath -CustomDirectorySecurity $null } | Should -Throw
		}

		It 'Should throw an error with a wrong data type' {
			{ New-NXTFolderWithPermission -Path $folderPath -CustomDirectorySecurity 'Invalid' } | Should -Throw
			{ New-NXTFolderWithPermission -Path $folderPath -CustomDirectorySecurity ([System.Security.AccessControl.FileSecurity]::new()) } | Should -Throw
		}
	}

	Context 'When using Hide' {
		BeforeEach {
			New-TestFolder
		}

		It 'Should create a hidden folder' {
			New-NXTFolderWithPermission -Path $folderPath -FullControl $sidCurrentUser -Hide
			[System.IO.DirectoryInfo]::new($folderPath).Attributes.HasFlag([System.IO.FileAttributes]::Hidden) | Should -BeTrue
		}

		It 'Should create a visible folder without Hide' {
			New-NXTFolderWithPermission -Path $folderPath -FullControl $sidCurrentUser
			[System.IO.DirectoryInfo]::new($folderPath).Attributes.HasFlag([System.IO.FileAttributes]::Hidden) | Should -BeFalse
		}
	}

	Context 'When using WhatIf' {
		BeforeAll {
			New-TestFolder
		}

		It 'Should not create the folder' {
			# The global preference variable is used, because the -WhatIf switch fails in PSADT 4.1 for callers outside of the module
			try {
				$global:WhatIfPreference = $true
				New-NXTFolderWithPermission -Path $folderPath -FullControl $sidCurrentUser -PassThru | Should -BeNullOrEmpty
			}
			finally {
				$global:WhatIfPreference = $false
			}
			[System.IO.Directory]::Exists($folderPath) | Should -BeFalse
		}
	}
}
