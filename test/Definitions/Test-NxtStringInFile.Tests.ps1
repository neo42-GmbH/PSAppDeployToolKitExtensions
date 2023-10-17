Describe "Test-NxtStringInFile" {
    Context "When searching for text in a file" {
        It "Returns true if the text is found (case-insensitive)" {
            $tempFile = New-TemporaryFile
            $content = "This is a test file. It contains some text that we will search for."
            Set-Content -Path $tempFile.FullName -Value $content
            $result = Test-NxtStringInFile -Path $tempFile.FullName -SearchString "contains Some text" -IgnoreCase $true
            $result | Should -BeTrue
            Remove-Item -Path $tempFile.FullName
        }
        It "Returns true if the text is found (case-sensitive)" {
            $tempFile = New-TemporaryFile
            $content = "This is a test file. It contains some text that we will search for."
            Set-Content -Path $tempFile.FullName -Value $content
            $result = Test-NxtStringInFile -Path $tempFile.FullName -SearchString "contains some text" -IgnoreCase $false
            $result | Should -BeTrue
            Remove-Item -Path $tempFile.FullName
        }
        It "Returns false if the text is not found (case-insensitive)" {
            $tempFile = New-TemporaryFile
            $content = "This is a test file. It contains some text that we will search for."
            Set-Content -Path $tempFile.FullName -Value $content
            $result = Test-NxtStringInFile -Path $tempFile.FullName -SearchString "DOES NOT EXIST" -IgnoreCase $true
            $result | Should -BeFalse
            Remove-Item -Path $tempFile.FullName
        }
        It "Returns false if the text is not found (case-sensitive)" {
            $tempFile = New-TemporaryFile
            $content = "This is a test file. It contains some text that we will search for."
            Set-Content -Path $tempFile.FullName -Value $content
            $result = Test-NxtStringInFile -Path $tempFile.FullName -SearchString "text that we Will search" -IgnoreCase $false
            $result | Should -BeFalse
            Remove-Item -Path $tempFile.FullName
        }
        It "Throws if the file does not exist" {
            { Test-NxtStringInFile -Path "C:\DOES_NOT_EXIST" -SearchString "text that we Will search" } | Should -Throw "File C:\DOES_NOT_EXIST does not exist"
        }
    }
}