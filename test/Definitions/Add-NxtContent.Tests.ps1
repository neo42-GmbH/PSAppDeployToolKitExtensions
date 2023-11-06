# Test the Add-NxtContent Function

Describe "Add-NxtContent" {
    Context "When creating a new file" {
        BeforeEach {
            $filePath = "$PSScriptRoot\test.txt"
            $content = "This is a test file."
        }
        AfterEach {
            if ("$PSScriptRoot\test.txt") {
                Remove-Item "$PSScriptRoot\test.txt"
            }
        }

        It "Should create a new file with correct encoding" {
            Add-NxtContent -Path $filePath -Value $content -Encoding "UTF8"

            Get-Content $filePath | Should -Be $content
            Get-NxtFileEncoding -Path $filePath | Should -Be "UTF8withBOM"
        }
    }
    Context "When appending to an existing file" {
        BeforeEach {
            $filePath = "$PSScriptRoot\test.txt"
            Add-NxtContent -Path $filePath -Value "This is a test file." -Encoding "UTF8"
        }
        AfterEach {
            if ("$PSScriptRoot\test.txt") {
                Remove-Item "$PSScriptRoot\test.txt"
            }
        }

        It "Should append to the file" {
            Add-NxtContent -Path $filePath -Value "This is a new line." -Encoding "UTF8"
            Get-Content $filePath -Raw | Should -BeLike "This is a test file.`r`nThis is a new line.`r`n"
        }
    }
    Context "When destination is unavailable" {
        It "Should throw when read-only" -Skip {
            $filePath = "$PSScriptRoot\test.txt"
            New-Item -Path $filePath -ItemType File
            Set-ItemProperty -Path $filePath -Name IsReadOnly -Value $true
            Add-NxtContent -Path $filePath -Value "This is a new line." -Encoding "UTF8" | Should -Throw
            Set-ItemProperty -Path $filePath -Name IsReadOnly -Value $false
            Remove-Item $filePath
        }
        It "Should not create folder structure" {
            try {
                Add-NxtContent -Path $PSScriptRoot\invalid\test.txt -Value "This is a test file."
            }
            catch {}
            Test-Path $PSScriptRoot\invalid\test.txt | Should -Be $false
        }
    }
    Context "When specificing multiple related parameters" {
        AfterEach {
            if ("$PSScriptRoot\test.txt") {
                Remove-Item "$PSScriptRoot\test.txt"
            }
        }

        It "Should use Encoding instead of DefaultEncoding" {
            Add-NxtContent -Path "$PSScriptRoot\test.txt" -Value "This is a test file." -Encoding "UTF8" -DefaultEncoding "UTF7"
            Get-NxtFileEncoding -Path "$PSScriptRoot\test.txt" | Should -Be "UTF8withBOM"
        }
    }
}