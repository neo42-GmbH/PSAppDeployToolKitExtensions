Describe "Watch-NxtFile" {
    Context "When given valid parameters" {
        BeforeAll {
            [string]$file = "$PSScriptRoot\TestFile"
        }
        AfterEach {
            if (Test-Path $file) {
                Remove-Item $file -Force
            }
        }
        It "Should return true if file already exists" {
            New-Item -Path $file -ItemType File | Out-Null
            $result = Watch-NxtFile -FileName $file
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
        }
        It "Should timeout and return false within specified time" {
            [datetime]$start = Get-Date
            $result = Watch-NxtFile -FileName $file -Timeout 1 | Should -Be $false
            [Math]::Floor(((Get-Date) - $start).TotalSeconds) | Should -BeLessOrEqual 2
        }
        It "Should return true if file is created later" {
            [datetime]$start = Get-Date
            Start-Job -ScriptBlock { Start-Sleep -Seconds 2; New-Item -Path $args[0] -ItemType File -Force } -ArgumentList @($file) | Out-Null
            Watch-NxtFile -FileName $file -Timeout 5 | Should -Be $true
            [Math]::Floor(((Get-Date) - $start).TotalSeconds) | Should -BeLessOrEqual 4
        }
        It "Should return false if folder path does not exist" {
            Watch-NxtFile -FileName "$PSScriptRoot\NonExistentFolder\TestFile" -Timeout 1 | Should -Be $false
        }
    }
}
