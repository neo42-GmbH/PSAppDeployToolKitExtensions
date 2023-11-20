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
            [string]$pathToRemove = "C:\TestPath"
        }
        BeforeEach {
            Set-SystemPath -Path ("$pathToRemove;" + $pathBackup + "$pathToRemove;" + "C:\KeepMe;")
        }
        AfterEach {
            Set-SystemPath -Path $pathBackup
        }
        It "Removes all occurences from the path environment variable" {
            Remove-NxtSystemPathVariable -Path $pathToRemove
            (Get-SystemPath).Split(';') | Should -Not -Contain $pathToRemove
        }
        It "Should not remove other entries" {
            Remove-NxtSystemPathVariable -Path $pathToRemove
            (Get-SystemPath).Split(';') | Should -Contain "C:\KeepMe"
        }
    }
}
