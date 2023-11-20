Describe "Add-NxtProcessPathVariable" {
    Context "When the function is called" {
        BeforeAll {
            [string]$pathBackup = $env:PATH
            [string]$pathToAdd = "C:\TestPath"
        }
        AfterEach {
            $env:PATH = $pathBackup
        }
        It "Adds the path to the environment variable" {
            Add-NxtProcessPathVariable -Path $pathToAdd
            $env:PATH.Split(';') | Should -Contain $pathToAdd
        }
        It "Adds the path to the environment variable at the correct position" {
            Add-NxtProcessPathVariable -Path $pathToAdd -AddToBeginning $true
            $env:PATH.Split(";")[0] | Should -Be $pathToAdd
        }
        It "Should throw when invalid path is specified" {
            { Add-NxtProcessPathVariable -Path "?" } | Should -Throw
        }
    }
}