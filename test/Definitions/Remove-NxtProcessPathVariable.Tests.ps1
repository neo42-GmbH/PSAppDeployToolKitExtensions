Describe "Remove-NxtProcessPathVariable" {
    Context "When the function is called" {
        BeforeAll {
            [string]$pathBackup = $env:PATH
            [string]$pathToRemove = "C:\TestPath"
        }
        BeforeEach {
            $env:PATH = "$pathToRemove;" + $pathBackup + "$pathToRemove;" + "C:\KeepMe;"
        }
        AfterEach {
            $env:PATH = $pathBackup
        }
        It "Removes all occurences from the path environment variable" {
            Remove-NxtProcessPathVariable -Path $pathToRemove
            $env:PATH.Split(';') | Should -Not -Contain $pathToRemove
        }
        It "Should not remove other entries" {
            Remove-NxtProcessPathVariable -Path $pathToRemove
            $env:PATH.Split(';') | Should -Contain "C:\KeepMe"
        }
    }
}
