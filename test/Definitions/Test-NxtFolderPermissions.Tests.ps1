Describe "Test-NxtFolderPermissions" {
    Context "When running against a valid folder" {
        BeforeAll {
            [string]$folder = "$PSScriptRoot\TestFolder"
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
            Set-NxtFolderPermissions -Path $folder -FullControlPermissions 'WorldSid' -Owner 'WorldSid' -BreakInheritance $true
        }
        AfterAll {
            Remove-Item -Path $folder -Force -Recurse | Out-Null
        }
        It "Should return success on matching conditions" {
            Test-NxtFolderPermissions -Path $folder -FullControlPermissions 'WorldSid' -Owner 'WorldSid' | Should -Be $true
        }
        It "Should return false if one permission missmatches" {
            Test-NxtFolderPermissions -Path $folder -FullControlPermissions 'WorldSid' -ModifyPermissions 'BuiltinGuestsSid' -Owner 'WorldSid' | Should -Be $false
        }
        It "Should fail if owner is not correct" {
            Test-NxtFolderPermissions -Path $folder -FullControlPermissions 'WorldSid' -Owner 'BuiltinGuestsSid' | Should -Be $false
        }
        It "Should fail if inheritance is not correct" {
            Test-NxtFolderPermissions -Path $folder -FullControlPermissions 'WorldSid' -CheckIsInherited $true -IsInherited $true | Should -Be $false
        }
    }

    Context "When running against an invalid folder" {
        BeforeAll {
            $file = "$PSScriptRoot\TestFile.txt"
        }
        AfterEach {
            if (Test-Path $file) {
                Remove-Item -Path $file  -Force | Out-Null
            }
        }
        It "Should return failure when folder does not exist" {
            { Test-NxtFolderPermissions -Path 'C:\InvalidFolder' -FullControlPermissions 'WorldSid' -Owner 'WorldSid' } | Should -Throw
        }
        It "Should return failure when run against a file" {
            New-Item -Path $file -ItemType File -Force | Out-Null
            { Test-NxtFolderPermissions -Path $file -FullControlPermissions 'WorldSid' -Owner 'WorldSid' } | Should -Throw
        }
    }
}
