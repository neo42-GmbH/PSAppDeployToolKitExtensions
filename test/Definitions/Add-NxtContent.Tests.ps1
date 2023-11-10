# Test the Add-NxtContent Function

Describe "Add-NxtContent" {
    Context "When creating a new file" {
        BeforeAll {
            [string]$filePath = "$PSScriptRoot\test.txt"
            [string]$content = "This is a test file."
        }
        AfterEach {
            if ("$PSScriptRoot\test.txt") {
                Remove-Item "$PSScriptRoot\test.txt" -Force
            }
        }

        It "Should create a new file with correct encoding" {
            Add-NxtContent -Path $filePath -Value $content -Encoding "UTF8" | Should -Be $null

            Get-Content $filePath | Should -Be $content
            Get-NxtFileEncoding -Path $filePath | Should -Be "UTF8withBOM"
        }
    }
    Context "When appending to an existing file" {
        BeforeEach {
            [string]$filePath = "$PSScriptRoot\test.txt"
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
        BeforeAll {
            [string]$filePath = "$PSScriptRoot\test.txt"
        }
        AfterEach {
            if ("$PSScriptRoot\test.txt") {
                Remove-Item "$PSScriptRoot\test.txt"
            }
        }
        It "Should throw when read-only" -Skip {
            New-Item -Path $filePath -ItemType File
            Set-ItemProperty -Path $filePath -Name IsReadOnly -Value $true
            { Add-NxtContent -Path $filePath -Value "This is a new line." -Encoding "UTF8" } | Should -Throw
            Set-ItemProperty -Path $filePath -Name IsReadOnly -Value $false
        }
        It "Should not create folder structure" -Skip {
            { Add-NxtContent -Path $PSScriptRoot\invalid\test.txt -Value "This is a test file." } | Should -Throw
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
    Context "When entering special inputs" {
        AfterEach {
            if ("$PSScriptRoot\test.txt") {
                Remove-Item "$PSScriptRoot\test.txt"
            }
        }

        It "Should write extended charset characters" {
            Add-NxtContent -Path "$PSScriptRoot\test.txt" -Value "🚀äß$"
            Get-Content "$PSScriptRoot\test.txt" -Raw | Should -Be "🚀äß$`r`n"
        }
    }
}