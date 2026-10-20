BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'New-NXTEnvironmentTable' {
	BeforeAll {
		$environmentTable = New-NXTEnvironmentTable
	}

	Context 'When creating the environment table' {
		It 'Should return a read-only dictionary' {
			$environmentTable.GetType() | Should -Be ([System.Collections.ObjectModel.ReadOnlyDictionary[System.String, System.Object]])
		}

		It 'Should contain environment variables' {
			$environmentTable.Count | Should -BeGreaterThan 0
		}

		It 'Should reflect the current system' {
			$environmentTable['envWindowsBits'] | Should -Be $(if ([System.Environment]::Is64BitOperatingSystem) { 64 } else { 32 })
			$environmentTable['envComputerThreadCount'] | Should -BeGreaterThan 0
		}
	}
}
