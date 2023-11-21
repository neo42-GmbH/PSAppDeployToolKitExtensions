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
            Add-NxtProcessPathVariable -Path $pathToAdd | Should -BeNullOrEmpty
            $env:PATH.Split(';') | Should -Contain $pathToAdd
        }
        It "Adds the path to the environment variable at the correct position" {
            Add-NxtProcessPathVariable -Path $pathToAdd -AddToBeginning $true | Should -BeNullOrEmpty
            $env:PATH.Split(";")[0] | Should -Be $pathToAdd
        }
        It "Does not remove other entires" {
            $env:PATH = "C:\keepme;" + $pathBackup + ";C:\keepme;"
            Add-NxtProcessPathVariable -Path $pathToAdd -AddToBeginning $true | Should -BeNullOrEmpty
            $env:PATH.Split(";")[0] | Should -Be $pathToAdd
            $env:PATH.Split(";")[1] | Should -Be "C:\keepme"
            $env:PATH.Split(";")[-2] | Should -Be "C:\keepme"
        }
        It "Should throw when invalid path is specified" {
            { Add-NxtProcessPathVariable -Path "?" } | Should -Throw
        }
    }
}