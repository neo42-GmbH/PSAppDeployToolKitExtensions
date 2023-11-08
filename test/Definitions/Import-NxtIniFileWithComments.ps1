Describe 'Import-NxtIniFileWithComments' {
    Context 'When given a simple INI file' {
        BeforeAll {
            @"
; last modified 1 April 2001 by John Doe
[owner]
name = John Doe
organization = Acme Widgets Inc.
            
[database]
; use IP address in case network name resolution is not working
server = 192.0.2.62     
port = 143
"@ | Out-File -FilePath $PSScriptRoot\test.ini -Encoding utf8
        }
        AfterAll {
            if (Test-Path -Path $PSScriptRoot\test.ini)
            {
                Remove-Item -Path $PSScriptRoot\test.ini -Force
            }
        }

        It 'Should return a hashtable of the INI file contents' {
            $result = Import-NxtIniFileWithComments -Path $PSScriptRoot\test.ini

            # Return value is a hashtable
            $result.GetEnumerator().Name | Should -Contain 'database'
            $result.database | Should -BeOfType 'System.Collections.Hashtable'

            # Variables are assigned correctly 
            $result.owner.GetEnumerator().Name | Should -Contain 'name'
            $result.owner.name | Should -BeOfType 'System.Collections.Hashtable'
            $result.owner.name.Value | Should -BeOfType 'System.String'
            $result.owner.name.Value | Should -Be 'John Doe'

            # Numbers should be returned as strings
            $result.database.port.Value | Should -BeOfType 'System.String'
            $result.database.port.Value | Should -Be '143'
        }
    }
    Context 'When given a complex INI file' {
        BeforeAll {
            @"
; last modified 1 April 2001 by John Doe
[owner]
name : John Doe
organization=Acme Widgets Inc.
hobby = surf\'n
            
[owner.database]
; use IP address
server = 192.0.2.62     
port = 143

[.metadata]
#This is a comment
file = "payroll.dat"
            
"@ | Out-File -FilePath $PSScriptRoot\test.ini -Encoding utf8
}
        AfterAll {
            if (Test-Path -Path $PSScriptRoot\test.ini)
            {
                Remove-Item -Path $PSScriptRoot\test.ini -Force
            }
        }

        It "Should return a hashtable of the INI file contents" {
            $result = Import-NxtIniFileWithComments -Path $PSScriptRoot\test.ini

            # Test delimiter
            $result.owner.GetEnumerator().Name | Should -Not -Contain 'name'

            # Test escaping
            $result.owner.hobby.Value | Should -Be "surf\'n"

            # Test quotation
            $result['.metadata'].file.Value | Should -BeOfType 'System.String'
            $result['.metadata'].file.Value | Should -Be '"payroll.dat"'

            # Test subsections
            $result.GetEnumerator().Name | Should -Contain 'owner.database'
            $result.GetEnumerator().Name | Should -Contain '.metadata'

            # Comment above section should not be carried to first value
            $result.owner.name.Comments | Should -BeNullOrEmpty

            # Valid comments
            $result['owner.database'].server.Comments | Should -Be 'use IP address'
            $result['.metadata'].file.Comments | Should -Be 'This is a comment'
        }
    }
}
