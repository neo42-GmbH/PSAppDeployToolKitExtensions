BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Add-NXTPathVariable' {
	BeforeAll {
		[System.String]$pathValue = "C:\$([System.IO.Path]::GetRandomFileName())"
		[System.String]$processBackup = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Process)
		[System.String]$machineBackup = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Machine)
	}
	AfterAll {
		# Restore the original PATH variables after the tests
		[System.Environment]::SetEnvironmentVariable('PATH', $processBackup, [System.EnvironmentVariableTarget]::Process)
		[System.Environment]::SetEnvironmentVariable('PATH', $machineBackup, [System.EnvironmentVariableTarget]::Machine)
	}

	Context 'When adding a path variable' {
		AfterEach {
			[System.Environment]::SetEnvironmentVariable('PATH', $processBackup, [System.EnvironmentVariableTarget]::Process)
			[System.Environment]::SetEnvironmentVariable('PATH', $machineBackup, [System.EnvironmentVariableTarget]::Machine)
		}

		It 'Should add the path with the correct value at the end of the machine PATH variable' {
			Add-NXTPathVariable -Path $pathValue | Should -BeNullOrEmpty
			[System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Machine) | Should -Match "$([System.Text.RegularExpressions.Regex]::Escape($pathValue))$"
		}

		It 'Should add the path with the correct value at the beginning when -Prepend is specified' {
			Add-NXTPathVariable -Path $pathValue -Target 'Process' -Prepend | Should -BeNullOrEmpty
			[System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Process) | Should -Match "^$([System.Text.RegularExpressions.Regex]::Escape($pathValue))"
		}

		It 'Should do nothing if a duplicate is already present' {
			Add-NXTPathVariable -Path $pathValue -Target 'Process' | Should -BeNullOrEmpty
			Add-NXTPathVariable -Path $pathValue -Target 'Process' | Should -BeNullOrEmpty
			[System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Process) | Should -Not -Be "$pathValue;$pathValue"
		}

		It 'Should add to a different target when specified' {
			Add-NXTPathVariable -Path $pathValue -Target 'Process' | Should -BeNullOrEmpty
			[System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Process) | Should -Match "$([System.Text.RegularExpressions.Regex]::Escape($pathValue))$"
			[System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Machine) | Should -Not -Contain $pathValue
		}

		It 'Should take pipeline input' {
			[System.IO.FileInfo]::new($pathValue) | Add-NXTPathVariable -Target 'Process' | Should -BeNullOrEmpty
			[System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Process) | Should -Match "$([System.Text.RegularExpressions.Regex]::Escape($pathValue))$"
		}
	}
}
