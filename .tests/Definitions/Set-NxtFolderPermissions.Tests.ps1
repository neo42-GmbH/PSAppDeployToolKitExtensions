Describe "Set-NxtFolderPermissions" {
    Context "When the function is called" {
        BeforeAll {
            [string]$folder = "$PSScriptRoot\TestFolder"
            function Get-NameOfSid{
                param(
                    [Parameter(Mandatory=$true)]
                    [System.Security.Principal.WellKnownSidType]$SidName
                )
                [System.Security.Principal.SecurityIdentifier]$Sid = (New-Object System.Security.Principal.SecurityIdentifier -ArgumentList ($SidName, $null))
                return (New-Object System.Security.Principal.SecurityIdentifier($sid.value)).Translate([System.Security.Principal.NTAccount]).Value
            }
        }
        BeforeEach {
            New-Item -Path $folder -ItemType Directory | Out-Null
        }
        AfterEach {
            Remove-Item -Path $folder -Force -Recurse | Out-Null
        }
        It "Should set the folder permissions for a single Sid correctly" {
            Set-NxtFolderPermissions -Path $folder -Owner 'WorldSid' -FullControlPermissions 'WorldSid' -BreakInheritance $true | Should -BeNullOrEmpty
            [System.Security.AccessControl.DirectorySecurity]$acl = Get-Acl -Path $folder
            $acl.Access[0].IdentityReference.Value | Should -Be (Get-NameOfSid -SidName 'WorldSid')
            $acl.Access[0].FileSystemRights | Should -Be 'FullControl'
            $acl.Access.Count | Should -Be 1
            $acl.Owner | Should -Be (Get-NameOfSid -SidName 'WorldSid')
            $acl.AreAccessRulesProtected | Should -Be $true
        }
        It "Should set the folder permissions for a group of Sids correctly" {
            Set-NxtFolderPermissions -Path $folder -Owner 'WorldSid' -FullControlPermissions 'WorldSid','BuiltinGuestsSid' | Should -BeNullOrEmpty
            [System.Security.AccessControl.DirectorySecurity]$acl = Get-Acl -Path $folder
            $acl.Access.IdentityReference.Value | Should -Contain (Get-NameOfSid -SidName 'WorldSid')
            $acl.Access.IdentityReference.Value | Should -Contain (Get-NameOfSid -SidName 'BuiltinGuestsSid')
            $acl.Access.Count | Should -Be 2
            $acl.Owner | Should -Be (Get-NameOfSid -SidName 'WorldSid')
        }
        It "Should apply custom access rules" {
            [System.Security.AccessControl.DirectorySecurity]$access = New-Object System.Security.AccessControl.DirectorySecurity
            [System.Security.Principal.SecurityIdentifier]$everyone = New-Object System.Security.Principal.SecurityIdentifier -ArgumentList ([System.Security.Principal.WellKnownSidType]'WorldSid', $null)
            $access.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
				$everyone,
				"FullControl",
				"ContainerInherit,ObjectInherit",
				"None",
				"Allow"
			)))
            $access.SetOwner($everyone)
            Set-NxtFolderPermissions -Path $folder -CustomDirectorySecurity $access | Should -BeNullOrEmpty
            [System.Security.AccessControl.DirectorySecurity]$acl = Get-Acl -Path $folder
            $acl.Access[0].IdentityReference.Value | Should -Be (Get-NameOfSid -SidName 'WorldSid')
            $acl.Owner | Should -Be (Get-NameOfSid -SidName 'WorldSid')
        }
        It "Should fail if any of the Sid's are invalid" {
            { Set-NxtFolderPermissions -Path $folder -Owner 'WorldSid' -FullControlPermissions 'WorldSid' -WritePermissions 'InvalidSid' } | Should -Throw
        }
        It "Should fail if the path does not exist" {
            { Set-NxtFolderPermissions -Path 'InvalidPath' -Owner 'WorldSid' -FullControlPermissions 'WorldSid' } | Should -Throw
        }
    }
}
