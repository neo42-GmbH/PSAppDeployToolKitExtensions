BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Get-NXTStrictMode' {
	Context 'When checking strict mode' {
		AfterAll {
			Set-StrictMode -Off
		}

		It 'Should return 1.0 version' {
			Set-StrictMode -Version 3.0
			Get-NXTStrictMode | Should -Be '3.0'
		}

		It 'Should return 2.0 version' {
			Set-StrictMode -Version 2.0
			Get-NXTStrictMode | Should -Be '2.0'
		}

		It 'Should return 3.0 version' {
			Set-StrictMode -Version 3.0
			Get-NXTStrictMode | Should -Be '3.0'
		}

		It 'Should return empty when strict mode is off' {
			Set-StrictMode -Off
			Get-NXTStrictMode | Should -BeNullOrEmpty
		}
	}
}
