Describe "Remove-NxtEmptyFolder" {
    Context "When the function is called" {
        BeforeAll{
            [string]$folder = "$PSScriptRoot\TestFolder"
        }
        BeforeEach {
            New-Item $folder -ItemType Directory -Force | Out-Null
        }
        AfterEach{
            if (Test-Path $folder) {
                Remove-Item $folder -Force -Recurse | Out-Null
            }
        }
        It "Should delete an empty folder" {
            Remove-NxtEmptyFolder -Path $folder | Should -BeNullOrEmpty
            Test-Path $folder | Should -Be $false
        }
        It "Should not delete a folder if it has content" {
            New-Item "$folder\test.txt" -ItemType File -Force | Out-Null
            Remove-NxtEmptyFolder -Path $folder | Should -BeNullOrEmpty
            Test-Path $folder | Should -Be $true
        }
        It "Should do nothing if folder does not exist" {
            Remove-NxtEmptyFolder -Path "$folder\test" | Should -BeNullOrEmpty
            Test-Path "$folder\test" | Should -Be $false
        }
        It "Should not delete a folder if it is read-only" {
            $folder = Get-Item -Path $folder
            $folder.Attributes += [System.IO.FileAttributes]::ReadOnly
            Remove-NxtEmptyFolder -Path "$folder" | Should -BeNullOrEmpty
            $folder.Attributes -band -bnot [System.IO.FileAttributes]::ReadOnly
            Test-Path "$folder" | Should -Be $false
        }
        It "Should delete a folder if the folder recurse to folder exists" {
            New-Item "$folder\1" -ItemType Directory -Force | Out-Null
            New-Item "$folder\1\2" -ItemType Directory -Force | Out-Null
            New-Item "$folder\1\2\3" -ItemType Directory -Force | Out-Null
            Remove-NxtEmptyFolder -Path "$folder\1\2\3" -RootPathToRecurseUpTo "$folder" | Should -BeNullOrEmpty
            Test-Path "$folder\1\2\3" | Should -Be $false
        }
        It "Should not delete a folder in recurse if one has content" {
            New-Item "$folder\1" -ItemType Directory -Force | Out-Null
            New-Item "$folder\1\2" -ItemType Directory -Force | Out-Null
            New-Item "$folder\1\test.txt" -ItemType File -Force | Out-Null
            New-Item "$folder\1\2\3" -ItemType Directory -Force | Out-Null
            Remove-NxtEmptyFolder -Path "$folder\1\2\3" -RootPathToRecurseUpTo "$folder" | Should -BeNullOrEmpty
            Test-Path "$folder\1\2" | Should -Be $false
            Test-Path "$folder\1" | Should -Be $true
        }
    }
}
