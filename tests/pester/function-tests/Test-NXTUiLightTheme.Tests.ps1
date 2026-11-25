BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Test-NXTUiLightTheme' {
	BeforeAll {
		$script:identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
	}

	Context 'When using an invalid value as identity' {
		It 'Should throw an exception with $null or zero string' {
			{ Test-NXTUiLightTheme -Identity $null } | Should -Throw
			{ Test-NXTUiLightTheme -Identity '' } | Should -Throw
		}

		It 'Should throw an exception with an invalid value datatype' {
			{ Test-NXTUiLightTheme -Identity ([System.GUID]::NewGuid()) } | Should -Throw
		}
	}

	Context 'When using a non-existing SID as identity' {
		It 'Should throw exception with invalid characters at the begin of the sid' {
			{ Test-NXTUiLightTheme -Identity "abc$($script:identity)" } | Should -Throw `
				-Because 'Non existing SIDs (invalid sid format with invalid start character)'
		}

		It 'Should be true with invalid characters at the end of the sid' {
			Test-NXTUiLightTheme -Identity "$($script:identity)123456789" | Should -BeTrue `
				-Because 'Non existing SIDs (valid sid format with additional characters at end) will return true'
		}
	}

	# Current user could have an already personalized dark mode enabled so the test would fail in this case
	Context 'When using current user identity (default value)' -Skip {
		It 'Should be true using no parameter' {
			Test-NXTUiLightTheme | Should -BeTrue
		}

		It 'Should be true using parameter Identity' {
			Test-NXTUiLightTheme -Identity $script:identity | Should -BeTrue
		}
	}

	Context 'When using another existing identity' {
		BeforeAll {
			$script:sid = (. "$PSScriptRoot\..\support-scripts\New-LocalTestUser.ps1" -Name 'TestUser_Pester')
		}

		It 'Should be true' {
			Test-NXTUiLightTheme -Identity $script:sid | Should -BeTrue
		}

		It 'Should be true using alias parameter SID' {
			Test-NXTUiLightTheme -SID $script:sid | Should -BeTrue
		}
	}
}
