Describe "Get-NxtFileVersion" {
    Context "With a file saved with a version of 1" {
        It "Returns 1" {
            $filePath = "$PSScriptRoot\example1.exe"
            $fileVersion = "1.9.3.4"
            $sourceFilePath = "$PSScriptRoot\source.cs"
            $sourceCode = @"
            using System;
            using System.Reflection;
            [assembly: AssemblyVersion("$fileVersion")]
            [assembly: AssemblyFileVersion("$fileVersion")]
            namespace MyApp {
                class Program {
                    static void Main(string[] args) {
                        Console.WriteLine("Hello World!");
                    }
                }
            }
"@
            $sourceCode | Out-File -FilePath $sourceFilePath -Force
            $compilerPath = [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory() + "csc.exe"
            $compilerArgs = "/out:$filePath $sourceFilePath"
            Start-Process -FilePath $compilerPath -ArgumentList $compilerArgs -Wait
            $result = Get-NxtFileVersion -FilePath $filePath
            $result | Should -Be $fileVersion
        }
    }
}