Describe 'Import-NxtIniFile' {
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
            $result = Import-NxtIniFile -Path $PSScriptRoot\test.ini

            # Return value is a hashtable
            $result.GetEnumerator().Name | Should -Contain 'database'
            $result.database | Should -BeOfType 'System.Collections.Hashtable'

            # Variables are assigned correctly 
            $result.owner.GetEnumerator().Name | Should -Contain 'name'
            $result.owner.name | Should -BeOfType 'System.String'
            $result.owner.name | Should -Be 'John Doe'

            # Numbers should be returned as strings
            $result.database.port | Should -BeOfType 'System.String'
            $result.database.port | Should -Be '143'
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
; use IP address in case network name resolution is not working
server = 192.0.2.62     
port = 143

[.metadata]
# This is a comment
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
            $result = Import-NxtIniFile -Path $PSScriptRoot\test.ini -ContinueOnError $true

            # Test delimiter
            $result.owner.GetEnumerator().Name | Should -Not -Contain 'name'

            # Test escaping
            $result.owner.hobby | Should -Be "surf\'n"

            # Test quotation
            $result['.metadata'].file | Should -BeOfType 'System.String'
            $result['.metadata'].file | Should -Be '"payroll.dat"'

            # Test subsections
            $result.GetEnumerator().Name | Should -Contain 'owner.database'
            $result.GetEnumerator().Name | Should -Contain '.metadata'
        }
    }
}
