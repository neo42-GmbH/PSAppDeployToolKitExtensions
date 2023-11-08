Describe 'Add-NxtLocalUser' {
    Context 'When adding a new local user' {
        BeforeAll {
            Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        }
        AfterEach {
            if (Get-LocalUser -Name 'TestUser' -ErrorAction SilentlyContinue) {
                Remove-LocalUser -Name 'TestUser'
            }
        }
        It 'Should create a new user account' -Skip {
            # Issue #624
            Add-NxtLocalUser -Username 'TestUser' -Password 'JX{C@Wb<PHV=H}Gx' | Should -Be $true
            Get-LocalUser -Name 'TestUser' | Should -Not -Be $null
        }
        It 'Should have the correct password' {
            Add-NxtLocalUser -Username 'TestUser' -Password 'JX{C@Wb<PHV=H}Gx'
            [System.DirectoryServices.AccountManagement.PrincipalContext]$accounts = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('machine', $env:COMPUTERNAME)
            $accounts.ValidateCredentials('TestUser', 'JX{C@Wb<PHV=H}Gx') | Should -Be $true
        }
        It 'User should have defined attributes' {
            Add-NxtLocalUser -Username 'TestUser' -Password 'JX{C@Wb<PHV=H}Gx' -Description 'Test Description' -SetPwdNeverExpires -FullName 'Test User'
            [Microsoft.PowerShell.Commands.LocalUser]$user = Get-LocalUser -Name 'TestUser'
            $user.FullName | Should -Be 'Test User'
            $user.Description | Should -Be 'Test Description'
            $user.PasswordExpires | Should -Be $null
        }
        It 'Should update parameters when user exists' -Skip {
            # Issue #624
            Add-NxtLocalUser -Username 'TestUser' -Password 'JX{C@Wb<PHV=H}Gx' -Description 'Test Description' -SetPwdNeverExpires -FullName 'Test User'
            Add-NxtLocalUser -UserName 'TestUser' -Password 'JX{C@Wb<PHV=H}Gx2' -Description 'Test Description2' -SetPwdExpired -FullName 'Test User2' | Should -Be $true
            [Microsoft.PowerShell.Commands.LocalUser]$user = Get-LocalUser -Name 'TestUser'
            $user.FullName | Should -Be 'Test User2'
            $user.Description | Should -Be 'Test Description2'
            $user.PasswordExpires | Should -Be $null
            $user.PasswordChangeableDate | Should -BeLessOrEqual (Get-Date)

            [System.DirectoryServices.AccountManagement.PrincipalContext]$accounts = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('machine', $env:COMPUTERNAME)
            $accounts.ValidateCredentials('TestUser', 'JX{C@Wb<PHV=H}Gx2') | Should -Be $true
        }
    }
}
