Describe "Update-NxtProcessPathVariable" {
    BeforeAll {
        [string]$pathBackup = $env:PATH
    }
    AfterEach {
        $env:PATH = $pathBackup
    }
    Context "When the function is called with the -AddPath parameter" {
        It "Adds the path to the environment variable" {
            Update-NxtProcessPathVariable -AddPath "C:\test"
            $env:PATH.Split(';') | Should -Contain "C:\test"
        }
        It "Adds the path to the environment variable at the correct position" {
            Update-NxtProcessPathVariable -AddPath "C:\test" -Position "Start"
            $env:PATH.Split(";")[0] | Should -Be "C:\test"
        }
        It "Adds the path twice if the -Force parameter is used" {
            Update-NxtProcessPathVariable -AddPath "C:\test" -Position "Start" -Force
            Update-NxtProcessPathVariable -AddPath "C:\test" -Position "Start" -Force
            $env:PATH.Split(";")[0] | Should -Be "C:\test"
            $env:PATH.Split(";")[1] | Should -Be "C:\test"
        }
    }
    Context "When the function is called with the -RemovePath parameter" {
        BeforeAll {
            [string]$pathBackup = $env:PATH
        }
        BeforeEach {
            $env:PATH = "C:\test;" + $pathBackup + ";C:\test"
        }
        AfterEach {
            $env:PATH = $pathBackup
        }
        It "Removes all occurences from the path environment variable" {
            Update-NxtProcessPathVariable -RemovePath "C:\test"
            $env:PATH.Split(';') | Should -Not -Contain "C:\test"
        }
        It "Removes the first occurence from the path environment variable" {
            Update-NxtProcessPathVariable -RemovePath "C:\test" -RemoveOccurences "First"
            Write-Host $env:PATH
            $env:PATH.Split(';')[0] | Should -Not -Be 'C:\test'
            $env:PATH.Split(';')[-1] | Should -Be 'C:\test'
        }
        It "Removes the last occurence from the path environment variable" {
            Update-NxtProcessPathVariable -RemovePath "C:\test" -RemoveOccurences "Last"
            $env:PATH.Split(';')[0] | Should -Be 'C:\test'
            $env:PATH.Split(';')[-1] | Should -Not -Be 'C:\test'
        }
    }
}