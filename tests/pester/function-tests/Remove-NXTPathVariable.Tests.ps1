BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Remove-NXTPathVariable' {
	BeforeAll {
		[System.String]$pathValue = "C:\$([System.Guid]::NewGuid().ToString('N'))"
		[System.String]$processBackup = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Process)
		[System.String]$userBackup = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::User)
	}

	AfterAll {
		# Restore original PATH variables
		[System.Environment]::SetEnvironmentVariable('PATH', $processBackup, [System.EnvironmentVariableTarget]::Process)
		[System.Environment]::SetEnvironmentVariable('PATH', $userBackup, [System.EnvironmentVariableTarget]::User)
	}

	Context 'When removing from process PATH variable' {
		BeforeEach {
			# Add the test path to the PATH variable
			$currentPath = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Process)
			[System.Environment]::SetEnvironmentVariable('PATH', "$currentPath;$pathValue", [System.EnvironmentVariableTarget]::Process)
		}

		AfterEach {
			# Restore original PATH
			[System.Environment]::SetEnvironmentVariable('PATH', $processBackup, [System.EnvironmentVariableTarget]::Process)
		}

		It 'Should remove the path from the process PATH variable' {
			Remove-NXTPathVariable -Path $pathValue -Target 'Process' | Should -BeNullOrEmpty
			[System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Process) | Should -Not -Match ([System.Text.RegularExpressions.Regex]::Escape($pathValue))
		}

		It 'Should remove path with trailing slash correctly' {
			# Remove path with slash
			Remove-NXTPathVariable -Path "$pathValue\" -Target 'Process' | Should -BeNullOrEmpty
			[System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Process) | Should -Not -Match ([System.Text.RegularExpressions.Regex]::Escape("$pathValue"))
		}
	}

	Context 'When removing from user PATH variable' {
		BeforeEach {
			# Add the test path to the user PATH variable
			$currentUserPath = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::User)
			[System.Environment]::SetEnvironmentVariable('PATH', "$currentUserPath;$pathValue", [System.EnvironmentVariableTarget]::User)
		}

		AfterEach {
			# Restore original user PATH
			[System.Environment]::SetEnvironmentVariable('PATH', $userBackup, [System.EnvironmentVariableTarget]::User)
		}

		It 'Should remove the path from the user PATH variable' {
			Remove-NXTPathVariable -Path $pathValue -Target 'User' | Should -BeNullOrEmpty
			[System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::User) | Should -Not -Match ([System.Text.RegularExpressions.Regex]::Escape($pathValue))
		}
	}
}
