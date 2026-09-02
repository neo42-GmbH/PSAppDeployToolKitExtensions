BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Compare-NXTVersion' {
	Context 'When comparing standard version formats' {
		It 'Should return Update when Version is lower than Target' {
			Compare-NXTVersion -Version '1.2.3.4' -Target '4.3.2.1' | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Update)
		}

		It 'Should return Current when Version equals Target' {
			Compare-NXTVersion -Version '1.2.3.4' -Target '1.2.3.4' | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Equal)
		}

		It 'Should return Downgrade when Version is higher than Target' {
			Compare-NXTVersion -Version '4.3.2.1' -Target '1.2.3.4' | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Downgrade)
		}
	}

	Context 'When comparing partial versions' {
		It 'Should treat missing version parts as zeros' {
			Compare-NXTVersion -Version '1.2' -Target '1.2.0.0' | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Equal)
			Compare-NXTVersion -Version '1.2.3' -Target '1.2.3.0' | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Equal)
			Compare-NXTVersion -Version '1.2' -Target '1.2.1.0' | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Update)
		}

		It 'Should correctly compare versions with different numbers of parts' {
			Compare-NXTVersion -Version '2.0' -Target '1.9.9.9' | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Downgrade)
			Compare-NXTVersion -Version '1.9.9' -Target '2.0' | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Update)
		}
	}

	Context 'When comparing complex versions' {
		It 'it should handle all versions correctly' {
			Compare-NXTVersion -Version '1.2.3.A' -Target '1.2.3.A' | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Equal)
			Compare-NXTVersion -Version 'v1' -Target 'v1' | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Equal)
			Compare-NXTVersion -Version '1.2-pre+build' -Target '1.2-pre+build' | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Equal)
			Compare-NXTVersion -Version 'beta64' -Target 'beta64' | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Equal)
		}
	}

	Context 'When handling edge cases' {
		It 'Should handle if the version parameter is empty' {
			Compare-NXTVersion -Version '' -Target '1.0' | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Update)
			Compare-NXTVersion -Version '1.0' -Target '' | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Downgrade)
		}
	}

	Context 'When using pipeline input' {
		It 'Should accept version from pipeline' {
			'1.2.3.4' | Compare-NXTVersion -Target '4.3.2.1' | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Update)
		}

		It 'Should work with aliased parameter names' {
			$versionObject = [PSCustomObject]@{
				DetectedVersion = '1.2.3.4'
			}
			$versionObject | Compare-NXTVersion -Target '4.3.2.1' | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Update)
		}
	}
}
