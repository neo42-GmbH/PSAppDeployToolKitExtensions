Describe "Move-NxtItem" {
    Context "When given a valid path" {
        BeforeAll{
            [string]$folder = "$PSScriptRoot\TestFolder"
            [string]$file = "$PSScriptRoot\TestFile"
        }
        BeforeEach {
            New-Item $folder -ItemType Directory -Force | Out-Null
            New-Item $file -ItemType File -Force | Out-Null
        }
        AfterEach{
            if (Test-Path $folder) {
                Remove-Item $folder -Force -Recurse | Out-Null
            }
            if (Test-Path $file) {
                Remove-Item $file -Force | Out-Null
            }
        }
        It "Should move the item to the specified destination" {
            Move-NxtItem -Path $file -Destination "$folder\TestFile"
            Test-Path "$folder\TestFile" | Should -Be $true
        }
        It "Should not add to folder if only folder path is specified" {
            Move-NxtItem -Path $file -Destination $folder
            Test-Path "$folder\TestFile" | Should -Be $true
        }
        It "Should not overwrite the destination if not forced" {
            "Content" | Out-File "$folder\TestFile"
            Move-NxtItem -Path $file -Destination "$folder\TestFile"
            Get-Content "$folder\TestFile" | Should -Be "Content"
        }
        It "Should overwrite the destination if forced" {
            "Content" | Out-File "$folder\TestFile"
            Move-NxtItem -Path $file -Destination "$folder\TestFile" -Force
            Get-Content "$folder\TestFile" | Should -BeNullOrEmpty
        }
        It "Should move folders and keep the content" {
            New-Item "$folder\TestFolder" -ItemType Directory -Force | Out-Null
            New-Item "$folder\TestFolder\TestFile" -ItemType File -Force | Out-Null
            Move-NxtItem -Path "$folder\TestFolder" -Destination "$folder\TestFolder2"
            Test-Path "$folder\TestFolder2\TestFile" | Should -Be $true
        }
        It "Should merge contents of folders" {
            New-Item "$folder\TestFolder" -ItemType Directory -Force | Out-Null
            New-Item "$folder\TestFolder\TestFile" -ItemType File -Force | Out-Null
            New-Item "$folder\TestFolder2" -ItemType Directory -Force | Out-Null
            New-Item "$folder\TestFolder2\TestFile2" -ItemType File -Force | Out-Null
            Move-NxtItem -Path "$folder\TestFolder\*" -Destination "$folder\TestFolder2"
            Test-Path "$folder\TestFolder2\TestFile" | Should -Be $true
            Test-Path "$folder\TestFolder2\TestFile2" | Should -Be $true
        }
    }
}
