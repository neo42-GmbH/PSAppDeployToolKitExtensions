# Assuming the function New-NxtTemporaryFolder is loaded in the current session or sourced from another file.

Describe "New-NxtTemporaryFolder" {
    Context "Default TempRootPath" {
        It "Uses default TempRootPath when none is provided" {
            $tempFolder = New-NxtTemporaryFolder
            $tempFolder | Should -BeLike "$env:SystemDrive\`n42tmp*"
        }
    }

    Context "Folder Creation" {
        It "Creates a folder in the specified TempRootPath" {
            $tempPath = "C:\CustomTempPath"
            $tempFolder = New-NxtTemporaryFolder -TempRootPath $tempPath
            $tempFolder | Should -BeLike "$tempPath*"
            Remove-Item -Path $tempPath -Recurse -Force
        }
    }
    Context "Random Folder Name Generation" {
        It "Generates a unique folder name" {
            Mock Test-Path { return $true } -ParameterFilter { $Path -like "*ABC*" } # Assuming ABC is the random name generated
            Mock Test-Path { return $false } -ParameterFilter { $Path -notlike "*ABC*" }

            $tempFolder = New-NxtTemporaryFolder
            $tempFolder | Should -Not -BeLike "*ABC*"
        }
    }
}

