Describe 'Update-NxtTextInFile' {
    Context 'When updating text in a file' {
        BeforeAll {
            [string]$file = "$PSScriptRoot\TestFile"
            [string]$content = @"
%REPLACE%
%REPLACE%DONTREPLACE
DONTREPLACE%REPLACE%DONTREPLACE
%DONTREPLACE%
"@
        }
        BeforeEach {
            $content | Out-File -FilePath $file -Encoding UTF8 -NoNewline
        }
        AfterAll {
            Remove-Item -Path $file -Force
        }
        It 'Should only replace the old text with the new text' {
            Update-NxtTextInFile -Path $file -SearchString "%REPLACE%" -ReplaceString "REPLACED" | Should -BeNullOrEmpty
            $fileContent = Get-Content -Path $file
            $fileContent[0] | Should -Be "REPLACED"
            $fileContent[1] | Should -Be "REPLACEDDONTREPLACE"
            $fileContent[2] | Should -Be "DONTREPLACEREPLACEDDONTREPLACE"
            $fileContent[3] | Should -Be "%DONTREPLACE%"
        }
        It 'Should only replace specific amount of occurences' {
            Update-NxtTextInFile -Path $file -SearchString "%REPLACE%" -ReplaceString "REPLACED" -Count 2 | Should -BeNullOrEmpty
            $fileContent = Get-Content -Path $file
            $fileContent[0] | Should -Be "REPLACED"
            $fileContent[1] | Should -Be "REPLACEDDONTREPLACE"
            $fileContent[2] | Should -Be "DONTREPLACE%REPLACE%DONTREPLACE"
            $fileContent[3] | Should -Be "%DONTREPLACE%"
        }
        It 'Should do nothing if file does not exist' {
            Update-NxtTextInFile -Path "C:\DoesNotExist" -SearchString "%REPLACE%" -ReplaceString "REPLACED" | Should -BeNullOrEmpty
        }
        It 'Should replace nothing if it does not find anything' {
            Update-NxtTextInFile -Path $file -SearchString "NOTHING" -ReplaceString "REPLACED" | Should -BeNullOrEmpty
            Get-Content -Path $file -Raw | Should -Be $content
        }
    }
}
