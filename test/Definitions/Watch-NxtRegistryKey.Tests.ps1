Describe "Watch-NxtRegistryKey" {
    Context "When running the function" {
        BeforeAll {
            [string]$key = "HKLM:\SOFTWARE\neo42\PesterTest"
            if (-not (Test-Path "HKLM:\SOFTWARE\neo42")){
                New-Item -Path "HKLM:\SOFTWARE\" -Name "neo42" -Force | Out-Null
            }
            function New-DelayedTestRegistryKey {
                return Start-Job -ScriptBlock { Start-Sleep 2; New-Item -Path "HKLM:\SOFTWARE\neo42" -Name "PesterTest" }
            }
        }
        AfterAll {
            if (Test-Path $key){
                Remove-Item -Path $key -Force -Recurse | Out-Null
            }
        }
        AfterEach {
            if (Test-Path $key){
                Remove-Item -Path $key -Force -Recurse | Out-Null
            }
        }
        It "Should return true if key does exists" {
            New-Item -Path "HKLM:\SOFTWARE\neo42" -Name "PesterTest" -Force | Out-Null
            $result = Watch-NxtRegistryKey -RegistryKey $key -Timeout 1
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
        }
        It "Should return false within timeout when key does not exist" {
            [datetime]$start = Get-Date
            $result = Watch-NxtRegistryKey -RegistryKey $key -Timeout 1
            $result | Should -BeOfType 'bool'
            $result | Should -Be $false
            [Math]::Floor(((Get-Date) - $start).TotalSeconds) | Should -BeLessOrEqual 2
        }
        It "Should return true if the key is created later" {
            [System.Management.Automation.Job]$job = New-DelayedTestRegistryKey
            [datetime]$start = Get-Date
            $result = Watch-NxtRegistryKey -RegistryKey $key -Timeout 10
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
            [Math]::Floor(((Get-Date) - $start).TotalSeconds) | Should -BeLessOrEqual 9
            $job | Remove-Job -Force
        }
    }
}
