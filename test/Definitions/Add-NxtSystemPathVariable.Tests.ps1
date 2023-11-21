Describe "Remove-NxtSystemPathVariable" {
    Context "When the function is called" {
        BeforeAll {
            function Get-SystemPath {
                return [System.Environment]::GetEnvironmentVariable('PATH',[System.EnvironmentVariableTarget]::Machine)
            }
            function Set-SystemPath {
                param(
                    [string]$path
                )
                [System.Environment]::SetEnvironmentVariable('PATH',$path,[System.EnvironmentVariableTarget]::Machine)
            }
            [string]$pathBackup = Get-SystemPath
            [string]$pathToAdd = "C:\TestPath"
        }
        AfterEach {
            Set-SystemPath -Path $pathBackup
        }
        It "Adds the path to the environment variable" {
            Add-NxtSystemPathVariable -Path $pathToAdd | Should -BeNullOrEmpty
            (Get-SystemPath).Split(';') | Should -Contain $pathToAdd
        }
        It "Adds the path to the environment variable at the correct position" {
            Add-NxtSystemPathVariable -Path $pathToAdd -AddToBeginning $true | Should -BeNullOrEmpty
            (Get-SystemPath).Split(';')[0] | Should -Be $pathToAdd
        }
        It "Does not remove other entires" {
            Set-SystemPath -path ("C:\keepme;" + $pathBackup + ";C:\keepme;")
            Add-NxtSystemPathVariable -Path $pathToAdd -AddToBeginning $true | Should -BeNullOrEmpty
            (Get-SystemPath).Split(";")[0] | Should -Be $pathToAdd
            (Get-SystemPath).Split(";")[1] | Should -Be "C:\keepme"
            (Get-SystemPath).Split(";")[-2] | Should -Be "C:\keepme"
        }
        It "Should throw when invalid path is specified" {
            { Add-NxtSystemPathVariable -Path "?" } | Should -Throw
        }
    }
}
