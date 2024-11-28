Describe "Expand-NxtVariablesInFile" {
    Context "With a file containing an environment variable in PowerShell notation" {
        It "Returns the file with the variable expanded" {
            $fileContent = "This is a test file with a variable `$(`$env:APPDATA)"
            $expectedResult = "This is a test file with a variable $($env:APPDATA)"
            $FilePath = "$PSScriptRoot\example1.txt"
            Set-Content -Value $fileContent -Path $FilePath
            Expand-NxtVariablesInFile -Path $FilePath
            Get-Content -Path $FilePath | Should -Be $expectedResult
            Remove-Item $FilePath
        }
    }
    Context "With a file containing an environment variable in CMD notation "{
        It "Returns the file with the variable expanded" {
            $fileContent = "This is a test file with a variable %APPDATA%"
            $expectedResult = "This is a test file with a variable $($env:APPDATA)"
            $FilePath = "$PSScriptRoot\example2.txt"
            Set-Content -Value $fileContent -Path $FilePath
            Expand-NxtVariablesInFile -Path $FilePath
            Get-Content -Path $FilePath | Should -Be $expectedResult
            Remove-Item $FilePath
        }
    }
    Context "With a file containing an environment variable in CMD notation "{
        It "Returns the file with the variable expanded" {
            $env:TestVar3 = "TestValue3"
            $fileContent = "This is a test file with a variable %TestVar3%"
            $expectedResult = "This is a test file with a variable TestValue3"
            $FilePath = "$PSScriptRoot\example3.txt"
            Set-Content -Value $fileContent -Path $FilePath
            Expand-NxtVariablesInFile -Path $FilePath
            Get-Content -Path $FilePath | Should -Be $expectedResult
            Remove-Item $FilePath
            [System.Environment]::SetEnvironmentVariable("TestVar3", $null, [System.EnvironmentVariableTarget]::Process)
        }
    }
    Context "With a file containing a variable in PowerShell notation "{
        It "Returns the file with the variable expanded" {
            Set-Variable TestVar4 -Value "TestValue4" -Scope global
            $fileContent = "This is a test file with a variable `$TestVar4"
            $expectedResult = "This is a test file with a variable $TestVar4"
            $FilePath = "$PSScriptRoot\example4.txt"
            Set-Content -Value $fileContent -Path $FilePath
            Expand-NxtVariablesInFile -Path $FilePath
            Get-Content -Path $FilePath | Should -Be $expectedResult
            Remove-Item $FilePath
            Remove-Variable TestVar4 -Scope global
        }
    }
    Context "With a file containing a variable in PowerShell notation enclosed by brackets"{
        It "Returns the file with the variable expanded" {
            Set-Variable TestVar5 -Value "TestValue5" -Scope global
            $fileContent = "This is a test file with a variable `$(`$TestVar5)"
            $expectedResult = "This is a test file with a variable $($TestVar5)"
            $FilePath = "$PSScriptRoot\example5.txt"
            Set-Content -Value $fileContent -Path $FilePath
            Expand-NxtVariablesInFile -Path $FilePath
            Get-Content -Path $FilePath | Should -Be $expectedResult
            Remove-Item $FilePath
            Remove-Variable TestVar5 -Scope global
        }
    }
    Context "With a file containing a global variable in PowerShell notation" {
        It "Returns the file with the variable expanded" {
            Set-Variable TestVar6 -Value "TestValue6" -Scope Global
            $fileContent = "This is a test file with a variable `$global:TestVar6"
            $expectedResult = "This is a test file with a variable $($global:TestVar6)"
            $FilePath = "$PSScriptRoot\example6.txt"
            Set-Content -Value $fileContent -Path $FilePath
            Expand-NxtVariablesInFile -Path $FilePath
            Get-Content -Path $FilePath | Should -Be $expectedResult
            Remove-Item $FilePath
            Remove-Variable TestVar6 -Scope Global
        }
    }
    Context "With a file containing a global variable in PowerShell notation enclosed by brackets" {
        It "Returns the file with the variable expanded" {
            Set-Variable TestVar7 -Value "TestValue7" -Scope Global
            $fileContent = "This is a test file with a variable `$(`$global:TestVar7)"
            $expectedResult = "This is a test file with a variable $($global:TestVar7)"
            $FilePath = "$PSScriptRoot\example7.txt"
            Set-Content -Value $fileContent -Path $FilePath
            Expand-NxtVariablesInFile -Path $FilePath
            Get-Content -Path $FilePath | Should -Be $expectedResult
            Remove-Item $FilePath
            Remove-Variable TestVar7 -Scope Global
        }
    }
}