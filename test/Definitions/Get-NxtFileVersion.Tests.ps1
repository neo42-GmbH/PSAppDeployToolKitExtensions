Describe "Get-NxtFileVersion" {
    Context "With a file saved with a version of 1" {
        It "Returns 1" {
            $returnCode = 0
            $filePath = "$PSScriptRoot\$returnCode.exe"
            $fileVersion = "1.9.3.4"
            $sourceFilePath = "$PSScriptRoot\source.cs"
            $sourceCode = @"
            using System;
            using System.Reflection;
            [assembly: AssemblyVersion("$fileVersion")]
            [assembly: AssemblyFileVersion("$fileVersion")]
            class Program
            {
                static void Main(string[] args)
                {
                    Environment.ExitCode = $returnCode;
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