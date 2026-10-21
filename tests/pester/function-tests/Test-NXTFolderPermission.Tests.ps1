BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Test-NXTFolderPermission' {
	BeforeAll {
		# Identities
		[System.String]$sidEveryone = 'S-1-1-0'
		[System.String]$sidUsers = 'S-1-5-32-545'
		[System.String]$sidAdministrators = 'S-1-5-32-544'
		[System.String]$sidLocalService = 'S-1-5-19'
		[System.Security.Principal.SecurityIdentifier]$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
		[System.String]$sidCurrentUser = $currentUser.Value
		[System.String]$accountCurrentUser = $currentUser.Translate([System.Security.Principal.NTAccount]).Value

		# Folders
		[System.String]$rootPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName())
		[System.String]$folderPath = [System.IO.Path]::Combine($rootPath, 'folder')
		[System.String]$subFolderPath = [System.IO.Path]::Combine($folderPath, 'sub')
		[System.String]$folderPathNotExisting = [System.IO.Path]::Combine($rootPath, 'notExisting')

		# Creates a folder with protected permissions (independent of the tested function):
		# - Owner: current user
		# - Allow: FullControl for current user and administrators, Modify and ChangePermissions for users, ReadAndExecute for everyone
		# - Deny: ChangePermissions for users
		# The sub-folder only contains the inherited permissions.
		function New-TestFolder {
			Remove-TestFolder
			$null = [System.IO.Directory]::CreateDirectory($subFolderPath)
			[System.Security.AccessControl.DirectorySecurity]$security = [System.Security.AccessControl.DirectorySecurity]::new()
			$security.SetOwner($currentUser)
			$security.SetAccessRuleProtection($true, $false)
			foreach ($rule in @(
					@($sidCurrentUser, 'FullControl', 'Allow'),
					@($sidAdministrators, 'FullControl', 'Allow'),
					@($sidUsers, 'Modify', 'Allow'),
					@($sidUsers, 'ChangePermissions', 'Allow'),
					@($sidEveryone, 'ReadAndExecute', 'Allow'),
					@($sidUsers, 'ChangePermissions', 'Deny')
				)) {
				$security.AddAccessRule(
					[System.Security.AccessControl.FileSystemAccessRule]::new(
						[System.Security.Principal.SecurityIdentifier]::new($rule[0]),
						[System.Security.AccessControl.FileSystemRights]$rule[1],
						[System.Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit',
						[System.Security.AccessControl.PropagationFlags]::None,
						[System.Security.AccessControl.AccessControlType]$rule[2]
					)
				)
			}
			Set-Acl -LiteralPath $folderPath -AclObject $security
		}
		function Remove-TestFolder {
			if ([System.IO.Directory]::Exists($rootPath)) {
				$null = & icacls.exe $rootPath /reset /T /C /Q 2>&1
				Remove-Item -LiteralPath $rootPath -Recurse -Force -ErrorAction SilentlyContinue
			}
		}

		# Creates a custom directory security with a single rule
		function New-CustomDirectorySecurity {
			param (
				[System.String]$Sid,
				[System.Security.AccessControl.FileSystemRights]$Rights,
				[System.Security.AccessControl.AccessControlType]$Type
			)
			[System.Security.AccessControl.DirectorySecurity]$security = [System.Security.AccessControl.DirectorySecurity]::new()
			$security.AddAccessRule(
				[System.Security.AccessControl.FileSystemAccessRule]::new(
					[System.Security.Principal.SecurityIdentifier]::new($Sid),
					$Rights,
					[System.Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit',
					[System.Security.AccessControl.PropagationFlags]::None,
					$Type
				)
			)
			return $security
		}

		New-TestFolder
	}

	AfterAll {
		Remove-TestFolder
	}

	Context 'When using an invalid path' {
		It 'Should throw an error with a non-existing path' {
			{ Test-NXTFolderPermission -Path $folderPathNotExisting -FullControl $sidAdministrators } | Should -Throw
		}

		It 'Should throw an error with null or empty path' {
			{ Test-NXTFolderPermission -Path $null -FullControl $sidAdministrators } | Should -Throw
			{ Test-NXTFolderPermission -Path '' -FullControl $sidAdministrators } | Should -Throw
		}

		It 'Should throw an error with a wrong data type for path' {
			{ Test-NXTFolderPermission -Path 123 -FullControl $sidAdministrators } | Should -Throw
			{ Test-NXTFolderPermission -Path $folderPath, $subFolderPath -FullControl $sidAdministrators } | Should -Throw
		}
	}

	Context 'When using valid paths' {
		It 'Should accept a positional path' {
			Test-NXTFolderPermission $folderPath -FullControl $sidAdministrators | Should -BeTrue
		}

		It 'Should accept the FullName alias' {
			Test-NXTFolderPermission -FullName $folderPath -FullControl $sidAdministrators | Should -BeTrue
		}

		It 'Should accept pipeline input' {
			Get-Item -LiteralPath $folderPath | Test-NXTFolderPermission -FullControl $sidAdministrators | Should -BeTrue
		}

		It 'Should return a result for each pipeline input' {
			[System.Boolean[]]$result = Get-Item -LiteralPath $folderPath, $rootPath | Test-NXTFolderPermission -Modify $sidUsers
			$result | Should -Be @($true, $false)
		}

		It 'Should accept the command alias' {
			Test-NXTFolderPermissions -Path $folderPath -FullControl $sidAdministrators | Should -BeTrue
		}

		It 'Should return a boolean' {
			Test-NXTFolderPermission -Path $folderPath -FullControl $sidAdministrators | Should -BeOfType [System.Boolean]
			Test-NXTFolderPermission -Path $folderPath -FullControl $sidLocalService | Should -BeOfType [System.Boolean]
		}

		It 'Should be true without any expectation' {
			Test-NXTFolderPermission -Path $folderPath | Should -BeTrue
		}
	}

	Context 'When testing permission levels' {
		It 'Should be true with matching full control permissions' {
			Test-NXTFolderPermission -Path $folderPath -FullControl $sidAdministrators | Should -BeTrue
		}

		It 'Should be true with matching modify permissions' {
			Test-NXTFolderPermission -Path $folderPath -Modify $sidUsers | Should -BeTrue
		}

		It 'Should be true with matching write permissions' {
			Test-NXTFolderPermission -Path $folderPath -Write $sidUsers | Should -BeTrue
		}

		It 'Should be true with matching read and execute permissions' {
			Test-NXTFolderPermission -Path $folderPath -ReadAndExecute $sidEveryone | Should -BeTrue
		}

		It 'Should be true with matching permissions for all levels' {
			Test-NXTFolderPermission -Path $folderPath -FullControl $sidAdministrators, $sidCurrentUser -Modify $sidUsers -Write $sidUsers -ReadAndExecute $sidEveryone, $sidUsers | Should -BeTrue
		}

		It 'Should be true when the actual permissions exceed the expected ones' {
			Test-NXTFolderPermission -Path $folderPath -Modify $sidAdministrators -ReadAndExecute $sidUsers | Should -BeTrue
		}

		It 'Should be false when the actual permissions are lower than the expected ones' {
			Test-NXTFolderPermission -Path $folderPath -FullControl $sidUsers | Should -BeFalse
			Test-NXTFolderPermission -Path $folderPath -Modify $sidEveryone | Should -BeFalse
			Test-NXTFolderPermission -Path $folderPath -Write $sidEveryone | Should -BeFalse
		}

		It 'Should be false when an identity has no permissions' {
			Test-NXTFolderPermission -Path $folderPath -ReadAndExecute $sidLocalService | Should -BeFalse
		}

		It 'Should be false when only one of multiple identities is missing permissions' {
			Test-NXTFolderPermission -Path $folderPath -FullControl $sidAdministrators, $sidUsers | Should -BeFalse
			Test-NXTFolderPermission -Path $folderPath -FullControl $sidAdministrators -ReadAndExecute $sidLocalService | Should -BeFalse
		}

		It 'Should accept identities in different formats' {
			Test-NXTFolderPermission -Path $folderPath `
				-FullControl ([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid), $accountCurrentUser `
				-Modify 'BuiltinUsersSid' `
				-ReadAndExecute ([System.Security.Principal.SecurityIdentifier]::new($sidEveryone)) | Should -BeTrue
		}

		It 'Should accept the parameter aliases' {
			Test-NXTFolderPermission -Path $folderPath -FullControlPermissions $sidAdministrators -ModifyPermissions $sidUsers -WritePermissions $sidUsers -ReadAndExecutePermissions $sidEveryone | Should -BeTrue
		}

		It 'Should throw an error with an unresolvable identity' {
			{ Test-NXTFolderPermission -Path $folderPath -FullControl ([System.Security.Principal.NTAccount]::new('NotExistingDomain', 'NotExistingUser')) } | Should -Throw
		}
	}

	Context 'When testing denied permissions' {
		It 'Should be false when allowed rights are denied by a deny rule' {
			[System.Security.AccessControl.DirectorySecurity]$security = New-CustomDirectorySecurity -Sid $sidUsers -Rights ChangePermissions -Type Allow
			Test-NXTFolderPermission -Path $folderPath -CustomDirectorySecurity $security | Should -BeFalse
		}

		It 'Should be false when allowed rights are partially denied by a deny rule' {
			Test-NXTFolderPermission -Path $folderPath -FullControl $sidUsers | Should -BeFalse
		}

		It 'Should be true when the allowed rights are not affected by a deny rule' {
			Test-NXTFolderPermission -Path $folderPath -Modify $sidUsers | Should -BeTrue
		}

		It 'Should be true when an expected deny rule exists' {
			[System.Security.AccessControl.DirectorySecurity]$security = New-CustomDirectorySecurity -Sid $sidUsers -Rights ChangePermissions -Type Deny
			Test-NXTFolderPermission -Path $folderPath -CustomDirectorySecurity $security | Should -BeTrue
		}

		It 'Should be false when an expected deny rule does not exist' {
			[System.Security.AccessControl.DirectorySecurity]$security = New-CustomDirectorySecurity -Sid $sidEveryone -Rights ChangePermissions -Type Deny
			Test-NXTFolderPermission -Path $folderPath -CustomDirectorySecurity $security | Should -BeFalse
		}

		It 'Should combine the custom directory security with the permission parameters' {
			[System.Security.AccessControl.DirectorySecurity]$security = New-CustomDirectorySecurity -Sid $sidUsers -Rights ChangePermissions -Type Deny
			Test-NXTFolderPermission -Path $folderPath -CustomDirectorySecurity $security -FullControl $sidAdministrators | Should -BeTrue
			$security = New-CustomDirectorySecurity -Sid $sidUsers -Rights ChangePermissions -Type Deny
			Test-NXTFolderPermission -Path $folderPath -CustomDirectorySecurity $security -FullControl $sidLocalService | Should -BeFalse
		}

		It 'Should throw an error with an invalid custom directory security' {
			{ Test-NXTFolderPermission -Path $folderPath -CustomDirectorySecurity $null } | Should -Throw
			{ Test-NXTFolderPermission -Path $folderPath -CustomDirectorySecurity 'Invalid' } | Should -Throw
		}
	}

	Context 'When testing the owner' {
		It 'Should be true with the matching owner as security identifier' {
			Test-NXTFolderPermission -Path $folderPath -Owner $sidCurrentUser | Should -BeTrue
		}

		It 'Should be true with the matching owner as account name' {
			Test-NXTFolderPermission -Path $folderPath -Owner $accountCurrentUser | Should -BeTrue
		}

		It 'Should be true with the matching owner as windows identity' {
			Test-NXTFolderPermission -Path $folderPath -Owner ([System.Security.Principal.WindowsIdentity]::GetCurrent()) | Should -BeTrue
		}

		It 'Should be false with a different owner' {
			Test-NXTFolderPermission -Path $folderPath -Owner $sidLocalService | Should -BeFalse
		}

		It 'Should be false with an unresolvable owner' {
			Test-NXTFolderPermission -Path $folderPath -Owner ([System.Security.Principal.NTAccount]::new('NotExistingDomain', 'NotExistingUser')) | Should -BeFalse
		}

		It 'Should be false with a different owner although the permissions match' {
			Test-NXTFolderPermission -Path $folderPath -Owner $sidLocalService -FullControl $sidAdministrators | Should -BeFalse
		}

		It 'Should throw an error with an invalid owner' {
			{ Test-NXTFolderPermission -Path $folderPath -Owner $null } | Should -Throw
			{ Test-NXTFolderPermission -Path $folderPath -Owner '' } | Should -Throw
			{ Test-NXTFolderPermission -Path $folderPath -Owner 123 } | Should -Throw
			{ Test-NXTFolderPermission -Path $folderPath -Owner $sidCurrentUser, $sidAdministrators } | Should -Throw
		}
	}

	Context 'When testing the inheritance' {
		It 'Should be true for explicit permissions when not inherited is expected' {
			Test-NXTFolderPermission -Path $folderPath -FullControl $sidAdministrators -IsInherited $false | Should -BeTrue
		}

		It 'Should be false for explicit permissions when inherited is expected' {
			Test-NXTFolderPermission -Path $folderPath -FullControl $sidAdministrators -IsInherited $true | Should -BeFalse
		}

		It 'Should be true for inherited permissions when inherited is expected' {
			Test-NXTFolderPermission -Path $subFolderPath -FullControl $sidAdministrators -IsInherited $true | Should -BeTrue
		}

		It 'Should be false for inherited permissions when not inherited is expected' {
			Test-NXTFolderPermission -Path $subFolderPath -FullControl $sidAdministrators -IsInherited $false | Should -BeFalse
		}

		It 'Should ignore the inheritance when not specified' {
			Test-NXTFolderPermission -Path $folderPath -FullControl $sidAdministrators | Should -BeTrue
			Test-NXTFolderPermission -Path $subFolderPath -FullControl $sidAdministrators | Should -BeTrue
		}

		It 'Should throw an error with an invalid inheritance value' {
			{ Test-NXTFolderPermission -Path $folderPath -IsInherited 'Invalid' } | Should -Throw
			{ Test-NXTFolderPermission -Path $folderPath -IsInherited $null } | Should -Throw
		}
	}

	Context 'When using invalid identities' {
		It 'Should throw an error with null identities' -ForEach @(
			@{ level = 'FullControl' }, @{ level = 'Modify' }, @{ level = 'Write' }, @{ level = 'ReadAndExecute' }
		) {
			{ [System.Collections.Hashtable]$splat = @{ $level = $null }; Test-NXTFolderPermission -Path $folderPath @splat } | Should -Throw
			{ [System.Collections.Hashtable]$splat = @{ $level = @($sidEveryone, $null) }; Test-NXTFolderPermission -Path $folderPath @splat } | Should -Throw
		}

		It 'Should throw an error with a wrong data type for identities' -ForEach @(
			@{ level = 'FullControl' }, @{ level = 'Modify' }, @{ level = 'Write' }, @{ level = 'ReadAndExecute' }
		) {
			{ [System.Collections.Hashtable]$splat = @{ $level = 123 }; Test-NXTFolderPermission -Path $folderPath @splat } | Should -Throw
			{ [System.Collections.Hashtable]$splat = @{ $level = [System.Object]::new() }; Test-NXTFolderPermission -Path $folderPath @splat } | Should -Throw
		}
	}
}
