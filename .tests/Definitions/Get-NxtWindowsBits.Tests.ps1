Describe "Get-NxtWindowsBits" {
    Context "When running on a 32-bit system" {
        $env:PROCESSOR_ARCHITECTURE="x86"
        It "Should return 32" {
            $result = Get-NxtWindowsBits
            $result | Should -BeOfType 'System.Int32'
            $result | Should -Be 32
        }
    }

    Context "When running on a 64-bit system" {
        BeforeAll {
            $env:PROCESSOR_ARCHITECTURE="AMD64"
        }
        It "Should return 64" {
            Get-NxtWindowsBits | Should -Be 64
        }
    }

    Context "When running on ARM64 system" {
        BeforeAll {
            $env:PROCESSOR_ARCHITECTURE="ARM64"
        }
        It "Should return 64" {
            Get-NxtWindowsBits | Should -Be 64
        }
    }

    Context "When running on ARM32 system" {
        BeforeAll {
            $env:PROCESSOR_ARCHITECTURE="ARM"
        }
        It "Should return 32" {
            Get-NxtWindowsBits | Should -Be 32
        }
    }

    Context "When running the variable is invalid" {
        BeforeAll {
            $env:PROCESSOR_ARCHITECTURE="INVALID"
        }
        It "Should return nothing" {
            { Get-NxtWindowsBits } | Should -Throw
        }
    }

    Context "When architecture variable is not set" {
        BeforeAll {
            Remove-Item Env:\PROCESSOR_ARCHITECTURE
        }
        It "Should return nothing" {
            Get-NxtWindowsBits | Should -Throw
        }
    }
}
