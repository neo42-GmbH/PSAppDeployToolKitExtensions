BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Update-NXTDetectionStatus' {
	BeforeAll {
		$adtSession = Get-ADTSession
		$detection = $adtSession.NXT.Detection
		$originalDetection = [ordered]@{
			Enabled       = $detection.Enabled
			Criteria      = $detection.Criteria
			TargetVersion = $detection.TargetVersion
			IsInstalled   = $detection.IsInstalled
			VersionStatus = $detection.VersionStatus
			Application   = $detection.Application
		}

		function Reset-Detection {
			foreach ($property in $originalDetection.Keys) {
				$detection.$property = $originalDetection[$property]
			}
		}

		# Create mock ARP entries, the 64-bit view is used to match the ARP64 store regardless of the process bitness
		$uninstallKeyPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
		$mockApps = @(
			@{ KeyName = 'NxtPesterDetectionApp1'; DisplayName = 'neo42 Pester Detection App 1'; DisplayVersion = '1.0.0' }
			@{ KeyName = 'NxtPesterDetectionApp2'; DisplayName = 'neo42 Pester Detection App 2'; DisplayVersion = '2.0.0' }
		)

		function Remove-MockApps {
			$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
			$uninstallKey = $baseKey.OpenSubKey($uninstallKeyPath, $true)
			foreach ($mockApp in $mockApps) {
				$uninstallKey.DeleteSubKeyTree($mockApp.KeyName, $false)
			}
			$uninstallKey.Dispose()
			$baseKey.Dispose()
		}

		Remove-MockApps
		$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
		$uninstallKey = $baseKey.OpenSubKey($uninstallKeyPath, $true)
		foreach ($mockApp in $mockApps) {
			$appKey = $uninstallKey.CreateSubKey($mockApp.KeyName)
			$appKey.SetValue('DisplayName', $mockApp.DisplayName)
			$appKey.SetValue('DisplayVersion', $mockApp.DisplayVersion)
			$appKey.Dispose()
		}
		$uninstallKey.Dispose()
		$baseKey.Dispose()

		$singleCriteria = [PSADTNXT.Application.NxtApplicationCriteria]@{ Store = 'ARP64'; Identifier = 'NxtPesterDetectionApp1' }
		$multipleCriteria = [PSADTNXT.Application.NxtApplicationCriteria]@{ Store = 'ARP64'; Filter = { $_.DisplayName -like 'neo42 Pester Detection App *' } }
		$noMatchCriteria = [PSADTNXT.Application.NxtApplicationCriteria]@{ Store = 'ARP64'; Identifier = 'NxtPesterDetectionAppMissing' }
	}

	AfterEach {
		Reset-Detection
	}

	AfterAll {
		Remove-MockApps
		Reset-Detection
	}

	Context 'When detection is disabled' {
		It 'Should not change the detection status' {
			$detection.Enabled = $false
			$detection.Criteria = $singleCriteria
			$detection.IsInstalled = $false
			Update-NXTDetectionStatus
			$detection.IsInstalled | Should -BeFalse
			$detection.Application | Should -BeNullOrEmpty
		}
	}

	Context 'When detection is enabled without criteria' {
		It 'Should keep the existing custom detection status' {
			$detection.Enabled = $true
			$detection.Criteria = $null
			$detection.IsInstalled = $true
			$detection.VersionStatus = [PSADTNXT.Application.VersionCompareResult]::Update
			Update-NXTDetectionStatus
			$detection.IsInstalled | Should -BeTrue
			$detection.VersionStatus | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Update)
		}
	}

	Context 'When detection criteria match a single application' {
		BeforeEach {
			$detection.Enabled = $true
			$detection.Criteria = $singleCriteria
		}

		It 'Should mark the application as installed' {
			Update-NXTDetectionStatus
			$detection.IsInstalled | Should -BeTrue
			$detection.Application | Should -BeOfType ([PSADT.Types.InstalledApplication])
			$detection.Application.DisplayName | Should -Be 'neo42 Pester Detection App 1'
			$detection.Application.DisplayVersion | Should -Be '1.0.0'
		}

		It 'Should report an equal version status without target version' {
			$detection.TargetVersion = $null
			$detection.VersionStatus = [PSADTNXT.Application.VersionCompareResult]::Update
			Update-NXTDetectionStatus
			$detection.VersionStatus | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Equal)
		}

		It 'Should report version status <Expected> for target version <Target>' -ForEach @(
			@{ Target = '2.0'; Expected = [PSADTNXT.Application.VersionCompareResult]::Update }
			@{ Target = '1.0.0'; Expected = [PSADTNXT.Application.VersionCompareResult]::Equal }
			@{ Target = '0.9'; Expected = [PSADTNXT.Application.VersionCompareResult]::Downgrade }
		) {
			$detection.TargetVersion = [PSADTNXT.Application.NxtVersion]::new($Target)
			Update-NXTDetectionStatus
			$detection.VersionStatus | Should -Be $Expected
		}
	}

	Context 'When detection criteria match no application' {
		It 'Should reset a previously detected application' {
			$detection.Enabled = $true
			$detection.Criteria = $singleCriteria
			$detection.TargetVersion = [PSADTNXT.Application.NxtVersion]::new('2.0')
			Update-NXTDetectionStatus
			$detection.IsInstalled | Should -BeTrue
			$detection.VersionStatus | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Update)

			$detection.Criteria = $noMatchCriteria
			Update-NXTDetectionStatus
			$detection.IsInstalled | Should -BeFalse
			$detection.Application | Should -BeNullOrEmpty
			$detection.VersionStatus | Should -Be ([PSADTNXT.Application.VersionCompareResult]::Equal)
		}
	}

	Context 'When detection criteria match multiple applications' {
		BeforeEach {
			$detection.Enabled = $true
			$detection.Criteria = $multipleCriteria
		}

		It 'Should throw an exception' {
			{ Update-NXTDetectionStatus } | Should -Throw -ErrorId 'MultipleApplicationsFound,Update-NXTDetectionStatus' -ExceptionType ([System.ApplicationException])
		}

		It 'Should not change the detection status' {
			$detection.IsInstalled = $false
			{ Update-NXTDetectionStatus } | Should -Throw
			$detection.IsInstalled | Should -BeFalse
			$detection.Application | Should -BeNullOrEmpty
		}
	}

	Context 'When validating parameters' {
		BeforeEach {
			$detection.Enabled = $true
			$detection.Criteria = $singleCriteria
		}

		It 'Should update an explicitly provided session' {
			Update-NXTDetectionStatus -ADTSession $adtSession
			$detection.IsInstalled | Should -BeTrue
		}

		It 'Should accept the session as positional parameter' {
			Update-NXTDetectionStatus $adtSession
			$detection.IsInstalled | Should -BeTrue
		}

		It 'Should throw an exception with null session' {
			{ Update-NXTDetectionStatus -ADTSession $null } | Should -Throw
		}

		It 'Should throw an exception with invalid session type' {
			{ Update-NXTDetectionStatus -ADTSession 'Session' } | Should -Throw
		}
	}
}
