Describe "Watch-NxtFileIsRemoved" {
    Context "When given valid parameters" {
        BeforeAll {
            [string]$file = "$PSScriptRoot\TestFile"
        }
        AfterEach {
            if (Test-Path $file) {
                Remove-Item $file -Force
            }
        }
        It "Should return true if file does not exist" {
            $result = Watch-NxtFileIsRemoved -FileName $file
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
        }
        It "Should timeout and return false within specified time" {
            New-Item -Path $file -ItemType File | Out-Null
            [datetime]$start = Get-Date
            $result = Watch-NxtFileIsRemoved -FileName $file -Timeout 1 | Should -Be $false
            [Math]::Floor(((Get-Date) - $start).TotalSeconds) | Should -BeLessOrEqual 2
        }
        It "Should return true if file is removed later" {
            New-Item -Path $file -ItemType File | Out-Null
            [datetime]$start = Get-Date
            Start-Job -ScriptBlock { Start-Sleep -Seconds 2; Remove-Item -Path "$using:PSScriptRoot\TestFile" -Force } | Out-Null
            Watch-NxtFileIsRemoved -FileName $file -Timeout 4 | Should -Be $true
            [Math]::Floor(((Get-Date) - $start).TotalSeconds) | Should -BeLessOrEqual 3
        }
        It "Should return true if folder path does not exist" {
            Watch-NxtFileIsRemoved -FileName "$PSScriptRoot\NonExistentFolder\TestFile" -Timeout 1 | Should -Be $true
        }
    }
}
