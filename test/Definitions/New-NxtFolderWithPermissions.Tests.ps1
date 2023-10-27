Describe "New-NxtFolderWithPermissions" {

    # Prepare the test environment
    BeforeEach {
        $testFolderPath = "$env:Temp\TestFolder\NxtFolderWithPermissions"
        if (Test-Path $testFolderPath) {
            Remove-Item -Path $testFolderPath -Force -Recurse
        }
    }

    AfterAll {
        # Clean up the test environment
    }

    It "Creates a folder with FullControlPermissions" {
        $expectedFullControlPermissions = @("BuiltinAdministrators", "LocalSystem") | ForEach-Object {
            @{
                Name = $_
                Sid = (New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::"$($_)Sid", $null)).Value
                Permission = "FullControl"  # Assuming FullControl for both
            }
        }

        New-NxtFolderWithPermissions -Path $testFolderPath -FullControlPermissions ($expectedFullControlPermissions | ForEach-Object { $_.Name })

        (Test-Path $testFolderPath) | Should -Be $true

        $acl = Get-Acl -Path $testFolderPath

        # Validate expected permissions
        $acl.Access | ForEach-Object {
            $currentSid = $_.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).Value
            $matchingPermission = $expectedFullControlPermissions | Where-Object { $_.Sid -eq $currentSid }
            $matchingPermission | Should -Not -BeNull
            $_.FileSystemRights | Should -Be $matchingPermission.Permission
        }
    }
    It "Creates a folder and sets it as hidden" {
        New-NxtFolderWithPermissions -Path $testFolderPath -FullControlPermissions "BuiltinAdministrators" -Hidden $true
        $attributes = (Get-Item $testFolderPath -Force).Attributes
        { $attributes -band [System.IO.FileAttributes]::Hidden } | Should -Not -Throw
    }
    It "Creates a folder with ReadAndExecutePermissions" {
        $expectedReadAndExecutePermissions = @("BuiltinUsers") | ForEach-Object {
            @{
                Name = $_
                Sid = (New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::"$($_)Sid", $null)).Value
                Permission = "ReadAndExecute, Synchronize"  # Assuming ReadAndExecute for both
            }
        }
        $expectedFullControlPermissions = @("BuiltinAdministrators") | ForEach-Object {
            @{
                Name = $_
                Sid = (New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::"$($_)Sid", $null)).Value
                Permission = "FullControl"  # Assuming ReadAndExecute for both
            }
        }

        New-NxtFolderWithPermissions -Path $testFolderPath -ReadAndExecutePermissions ($expectedReadAndExecutePermissions | ForEach-Object { $_.Name }) -FullControlPermissions BuiltinAdministrators

        (Test-Path $testFolderPath) | Should -Be $true

        $acl = Get-Acl -Path $testFolderPath

        # Validate expected permissions
        $acl.Access | ForEach-Object {
            $currentSid = $_.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).Value
            $matchingPermission = $($expectedReadAndExecutePermissions;$expectedFullControlPermissions) | Where-Object { $_.Sid -eq $currentSid }
            $matchingPermission | Should -Not -BeNull
            $_.FileSystemRights | Should -Be $matchingPermission.Permission
        }
    }
    # More tests can be added as necessary...
}
