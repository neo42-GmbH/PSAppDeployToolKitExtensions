Describe "Watch-NxtRegistryKeyIsRemoved" {
    Context "When running the function" {
        BeforeAll {
            [string]$key = "HKLM:\SOFTWARE\neo42\PesterTest"
            if (-not (Test-Path "HKLM:\SOFTWARE\neo42")){
                New-Item -Path "HKLM:\SOFTWARE\" -Name "neo42" -Force | Out-Null
            }
            function New-DelayedTestRegistryKeyRemoval {
                return Start-Job -ScriptBlock { Start-Sleep 2; Remove-Item -Path "HKLM:\SOFTWARE\neo42\PesterTest" -Force -Recurse}
            }
        }
        AfterEach {
            if (Test-Path $key){
                Remove-Item -Path $key -Force -Recurse | Out-Null
            }
        }
        It "Should return false if key does not exists" {
            $result = Watch-NxtRegistryKeyIsRemoved -RegistryKey $key -Timeout 1
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
        }
        It "Should return false within timeout when key does exist" {
            New-Item -Path "HKLM:\SOFTWARE\neo42" -Name "PesterTest" -Force | Out-Null
            [datetime]$start = Get-Date
            $result = Watch-NxtRegistryKeyIsRemoved -RegistryKey $key -Timeout 1
            $result | Should -BeOfType 'bool'
            $result | Should -Be $false
            [Math]::Floor(((Get-Date) - $start).TotalSeconds) | Should -BeLessOrEqual 2
        }
        It "Should return true if the key is created later" {
            New-Item -Path "HKLM:\SOFTWARE\neo42" -Name "PesterTest" -Force | Out-Null
            [System.Management.Automation.Job]$job = New-DelayedTestRegistryKeyRemoval
            [datetime]$start = Get-Date
            $result = Watch-NxtRegistryKeyIsRemoved -RegistryKey $key -Timeout 4
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
            [Math]::Floor(((Get-Date) - $start).TotalSeconds) | Should -BeLessOrEqual 3
            $job | Remove-Job
        }
    }
}
