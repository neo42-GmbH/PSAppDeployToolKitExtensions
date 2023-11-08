Describe "Get-NxtProcessorArchiteW6432" {
    Context "When running on a 64-bit OS" {
        It "Should returns value if PROCESSOR_ARCHITEW6432 is set" {
            $env:PROCESSOR_ARCHITEW6432 = 'AMD64'
            $result = Get-NxtProcessorArchiteW6432
            $result | Should -BeOfType 'System.String'
            $result | Should -Be 'AMD64'
        }
        It "Should return AMD64 when overwrite is set to 'AMD64'" {
            Remove-Item env:\PROCESSOR_ARCHITEW6432 -ErrorAction SilentlyContinue
            $result = Get-NxtProcessorArchiteW6432 -PROCESSOR_ARCHITEW6432 'AMD64'
            $result | Should -Be 'AMD64'
        }
        It "Should return empty if PROCESSOR_ARCHITEW6432 is not set" {
            Remove-Item env:\PROCESSOR_ARCHITEW6432 -ErrorAction SilentlyContinue
            $result = Get-NxtProcessorArchiteW6432
            $result | Should -BeNullOrEmpty
        }
    }
}
