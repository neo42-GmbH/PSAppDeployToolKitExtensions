Describe "Get-NxtFileEncoding" {
    Context "With a file saved in UTF8 with BOM" {
        It "Returns UTF8withBOM" {
            $fileContent = "This is a test file saved in UTF8 with BOM"
            $filePath = "$PSScriptRoot\example1.txt"
            Set-Content -Value $fileContent -Path $FilePath -Encoding UTF8
            $result = Get-NxtFileEncoding -Path $FilePath
            $result | Should -Be "UTF8withBOM"
            Remove-Item $filePath
        }
    }
    Context "With a file saved in UTF8" {
        It "Returns Empty String" {
            $fileContent = "This is a test file saved in UTF8 without BOM"
            $filePath = "$PSScriptRoot\example2.txt"
            $Encoding = New-Object System.Text.UTF8Encoding $False
            [System.IO.File]::WriteAllLines($filePath, $fileContent, $Encoding)
            $result = Get-NxtFileEncoding -Path $FilePath
            $result | Should -Be ""
            Remove-Item $filePath
        }
    }
    Context "With a file saved in Unicode (UTF16-LE))" {
        It "Returns Unicode" {
            $fileContent = "This is a test file saved in UTF16 with BOM"
            $filePath = "$PSScriptRoot\example3.txt"
            Set-Content -Value $fileContent -Path $FilePath -Encoding Unicode
            $result = Get-NxtFileEncoding -Path $FilePath
            $result | Should -Be "Unicode"
            Remove-Item $filePath
        }
    }
    Context "With a file saved in UTF32-LE" {
        It "Returns UTF32" {
            $fileContent = "This is a test file saved in UTF32 with BOM"
            $filePath = "$PSScriptRoot\example4.txt"
            Set-Content -Value $fileContent -Path $FilePath -Encoding UTF32
            $result = Get-NxtFileEncoding -Path $FilePath
            $result | Should -Be "UTF32"
            Remove-Item $filePath
        }
    }
    Context "With a file saved in ASCII" {
        It "Returns ASCII" {
            $fileContent = "This is a test file saved in ASCII"
            $filePath = "$PSScriptRoot\example5.txt"
            Set-Content -Value $fileContent -Path $FilePath -Encoding ASCII
            $result = Get-NxtFileEncoding -Path $FilePath
            $result | Should -Be ""
            Remove-Item $filePath
        }
    }
}