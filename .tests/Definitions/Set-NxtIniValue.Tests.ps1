Describe 'Set-NxtIniValue' {
    Context 'When the ini file exists' {
        BeforeAll {
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
            if (Test-Path -Path $ini) {
                Remove-Item -Path $ini -Force
            }
        }
        It 'Should add the value in the INI file' {
            Set-NxtIniValue -FilePath $ini -Section 'owner' -Key 'name' -Value 'Jane Doe' | Should -BeNullOrEmpty
            [hashtable]$content = Import-NxtIniFileWithComments -Path $ini
            $content.owner.name.Value | Should -Be 'Jane Doe'
        }
        It 'Should update the value of an existing entry' {
            Set-NxtIniValue -FilePath $ini -Section 'owner.database' -Key 'port' -Value '144' | Should -BeNullOrEmpty
            [hashtable]$content = Import-NxtIniFileWithComments -Path $ini
            $content['owner.database'].port.Value | Should -Be '144'
        }
    }
    Context 'When the ini file does not exist' {
        BeforeAll {
            [string]$ini = "$PSScriptRoot\test.ini"
        }
        AfterEach {
            if (Test-Path -Path $ini) {
                Remove-Item -Path $ini -Force
            }
        }
        It 'Should create the file' {
            Set-NxtIniValue -FilePath $ini -Section 'owner' -Key 'name' -Value 'Jane Doe' | Should -BeNullOrEmpty
            [hashtable]$content = Import-NxtIniFileWithComments -Path $ini
            $content.owner.name.Value | Should -Be 'Jane Doe'
        }
    }
}