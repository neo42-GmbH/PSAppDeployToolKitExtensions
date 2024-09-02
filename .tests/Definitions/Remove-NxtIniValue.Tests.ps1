Describe 'Remove-NxtIniValue' {
    Context 'When the function is called' {
        BeforeAll{
            [string]$ini = "$PSScriptRoot\test.ini"
        }
        BeforeEach {
            @"
; last modified 1 April 2001 by John Doe
[owner]
name : John Doe
organization=Acme Widgets Inc.
hobby = surf\'n
            
[owner.database]
; use IP address in case network name resolution is not working
server = 192.0.2.62     
port = 143

[.metadata]
# This is a comment
file = "payroll.dat"
            
"@ | Out-File -FilePath $ini -Encoding utf8
        }
        AfterEach {
            if (Test-Path -Path $ini)
            {
                Remove-Item -Path $ini -Force
            }
        }
        It 'Should remove the value from the INI file' {
            Remove-NxtIniValue -FilePath $ini -Section 'owner' -Key 'organization' | Should -BeNullOrEmpty
            (Import-NxtIniFileWithComments -Path $ini).owner.GetEnumerator().Name | Should -Not -Contain 'organization'
        }
        It 'Should not remove other values from the INI file' {
            Remove-NxtIniValue -FilePath $ini -Section 'owner' -Key 'organization' | Should -BeNullOrEmpty
            (Import-NxtIniFileWithComments -Path $ini).owner.GetEnumerator().Name | Should -Contain 'hobby'
        }
        It 'Should work with vaguely defined specs' {
            Remove-NxtIniValue -FilePath $ini -Section 'owner.database' -Key 'server' | Should -BeNullOrEmpty
            Remove-NxtIniValue -FilePath $ini -Section '.metadata' -Key 'file' | Should -BeNullOrEmpty
            $iniContent = Import-NxtIniFileWithComments -Path $ini
            $iniContent['owner.database'].GetEnumerator().Name | Should -Not -Contain 'server'
            $iniContent['.metadata'].GetEnumerator().Name | Should -Not -Contain 'file'
        }
        It 'Should delete nothing if section does not exist' {
            Remove-NxtIniValue -FilePath $ini -Section 'doesnotexist' -Key 'server' | Should -BeNullOrEmpty
            (Import-NxtIniFileWithComments -Path $ini)['owner.database'].GetEnumerator().Name | Should -Contain 'server'
        }
        It ' Should delete noting if key does not exist' {
            Remove-NxtIniValue -FilePath $ini -Section 'owner.database' -Key 'doesnotexist' | Should -BeNullOrEmpty
            (Import-NxtIniFileWithComments -Path $ini).GetEnumerator().Name | Should -Contain 'owner.database'
        }
        It 'Should do nothing if the file does not exist' {
            Remove-NxtIniValue -FilePath 'C:\doesnotexist.ini' -Section 'owner' -Key 'organization' | Should -BeNullOrEmpty
        }
    }
}
