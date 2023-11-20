Describe "Update-NxtProcessPathVariable" {
    BeforeAll {
        [string]$pathBackup = $env:PATH
        [string]$pathToAdd = "C:\TestPath"
    }
    AfterEach {
        $env:PATH = $pathBackup
    }
    Context "When the function is called with the -AddPath parameter" {
        It "Adds the path to the environment variable" {
            Update-NxtProcessPathVariable -AddPath $pathToAdd
            $env:PATH.Split(';') | Should -Contain $pathToAdd
        }
        It "Adds the path to the environment variable at the correct position" {
            Update-NxtProcessPathVariable -AddPath $pathToAdd -Position "Start"
            $env:PATH.Split(";")[0] | Should -Be $pathToAdd
        }
        It "Adds the path twice if the -Force parameter is used" {
            Update-NxtProcessPathVariable -AddPath $pathToAdd -Position "Start" -Force
            Update-NxtProcessPathVariable -AddPath $pathToAdd -Position "Start" -Force
            $env:PATH.Split(";")[0] | Should -Be $pathToAdd
            $env:PATH.Split(";")[1] | Should -Be $pathToAdd
        }
    }
    Context "When the function is called with the -RemovePath parameter" {
        BeforeAll {
            [string]$pathBackup = $env:PATH
            [string]$pathToRemove = "C:\TestPath"
        }
        BeforeEach {
            $env:PATH = "$pathToRemove;" + $pathBackup + ";$pathToRemove"
        }
        AfterEach {
            $env:PATH = $pathBackup
        }
        It "Removes all occurences from the path environment variable" {
            Update-NxtProcessPathVariable -RemovePath $pathToRemove
            $env:PATH.Split(';') | Should -Not -Contain $pathToRemove
        }
        It "Removes the first occurence from the path environment variable" {
            Update-NxtProcessPathVariable -RemovePath $pathToRemove -RemoveOccurences "First"
            Write-Host $env:PATH
            $env:PATH.Split(';')[0] | Should -Not -Be $pathToRemove
            $env:PATH.Split(';')[-1] | Should -Be $pathToRemove
        }
        It "Removes the last occurence from the path environment variable" {
            Update-NxtProcessPathVariable -RemovePath $pathToRemove -RemoveOccurences "Last"
            $env:PATH.Split(';')[0] | Should -Be $pathToRemove
            $env:PATH.Split(';')[-1] | Should -Not -Be $pathToRemove
        }
    }
}