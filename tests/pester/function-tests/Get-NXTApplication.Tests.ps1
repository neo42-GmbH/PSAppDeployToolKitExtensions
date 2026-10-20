BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Get-NXTApplication' {
	BeforeAll {
		# Create mock ARP entries for each store
		$uninstallKeyPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
		$packageGuid = '{42000000-0000-0000-0000-0000000000A1}'
		$mockApps = @(
			@{ View = [Microsoft.Win32.RegistryView]::Registry64; KeyName = 'NxtPesterApplication64'; Values = @{ DisplayName = 'neo42 Pester Application 64'; DisplayVersion = '1.0.0' } }
			@{ View = [Microsoft.Win32.RegistryView]::Registry32; KeyName = 'NxtPesterApplication32'; Values = @{ DisplayName = 'neo42 Pester Application 32'; DisplayVersion = '2.0.0' } }
			@{ View = [Microsoft.Win32.RegistryView]::Registry64; KeyName = $packageGuid; Values = @{ DisplayName = 'neo42 Pester Package'; DisplayVersion = '3.0.0'; neoRegPackagesKeyRef = "SOFTWARE\NxtPesterApplicationPackages\$packageGuid" } }
		)

		function Remove-MockApplication {
			foreach ($mockApp in $mockApps) {
				$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $mockApp.View)
				$uninstallKey = $baseKey.OpenSubKey($uninstallKeyPath, $true)
				$uninstallKey.DeleteSubKeyTree($mockApp.KeyName, $false)
				$uninstallKey.Dispose()
				$baseKey.Dispose()
			}
		}

		Remove-MockApplication
		foreach ($mockApp in $mockApps) {
			$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $mockApp.View)
			$appKey = $baseKey.CreateSubKey("$uninstallKeyPath\$($mockApp.KeyName)")
			foreach ($value in $mockApp.Values.GetEnumerator()) {
				$appKey.SetValue($value.Key, $value.Value)
			}
			$appKey.Dispose()
			$baseKey.Dispose()
		}
	}

	AfterAll {
		Remove-MockApplication
	}

	Context 'When using an identifier' {
		It 'Should return the application of the ARP64 store' {
			$result = @(Get-NXTApplication -Store ARP64 -Identifier 'NxtPesterApplication64')
			$result | Should -HaveCount 1
			$result[0] | Should -BeOfType ([PSADT.Types.InstalledApplication])
			$result[0].DisplayName | Should -Be 'neo42 Pester Application 64'
			$result[0].DisplayVersion | Should -Be '1.0.0'
		}

		It 'Should return the application of the ARP32 store' {
			$result = @(Get-NXTApplication -Store ARP32 -Identifier 'NxtPesterApplication32')
			$result | Should -HaveCount 1
			$result[0].DisplayName | Should -Be 'neo42 Pester Application 32'
		}

		It 'Should return applications of both views from the ARP store' {
			(Get-NXTApplication -Store ARP -Identifier 'NxtPesterApplication64').DisplayName | Should -Be 'neo42 Pester Application 64'
			(Get-NXTApplication -Store ARP -Identifier 'NxtPesterApplication32').DisplayName | Should -Be 'neo42 Pester Application 32'
		}

		It 'Should use the ARP store by default' {
			(Get-NXTApplication -Identifier 'NxtPesterApplication32').DisplayName | Should -Be 'neo42 Pester Application 32'
		}

		It 'Should not return applications of the other view' {
			Get-NXTApplication -Store ARP64 -Identifier 'NxtPesterApplication32' | Should -BeNullOrEmpty
			Get-NXTApplication -Store ARP32 -Identifier 'NxtPesterApplication64' | Should -BeNullOrEmpty
		}

		It 'Should return nothing for a non-existing identifier' {
			Get-NXTApplication -Identifier 'NxtPesterApplicationMissing' | Should -BeNullOrEmpty
		}
	}

	Context 'When using the package store' {
		It 'Should return the package application' {
			(Get-NXTApplication -Store Package -Identifier $packageGuid).DisplayName | Should -Be 'neo42 Pester Package'
		}

		It 'Should not return package applications from the ARP stores' {
			Get-NXTApplication -Store ARP -Identifier $packageGuid | Should -BeNullOrEmpty
			Get-NXTApplication -Store ARP64 -Identifier $packageGuid | Should -BeNullOrEmpty
		}

		It 'Should not return other applications from the package store' {
			Get-NXTApplication -Store Package -Identifier 'NxtPesterApplication64' | Should -BeNullOrEmpty
		}
	}

	Context 'When using a name' {
		It 'Should return the application with an equal name by default' {
			(Get-NXTApplication -Name 'neo42 Pester Application 64').DisplayName | Should -Be 'neo42 Pester Application 64'
		}

		It 'Should compare the name case-insensitive' {
			(Get-NXTApplication -Name 'NEO42 PESTER APPLICATION 64').DisplayName | Should -Be 'neo42 Pester Application 64'
		}

		It 'Should return the application with name pattern <NamePattern>' -ForEach @(
			@{ NamePattern = 'Contains'; Name = 'Pester Application 6' }
			@{ NamePattern = 'StartsWith'; Name = 'neo42 Pester Application 6' }
			@{ NamePattern = 'EndsWith'; Name = 'Pester Application 64' }
			@{ NamePattern = 'Wildcard'; Name = 'neo42*Application 64' }
			@{ NamePattern = 'Regex'; Name = '^neo42 Pester Application 6\d$' }
		) {
			$result = @(Get-NXTApplication -Name $Name -NamePattern $NamePattern)
			$result | Should -HaveCount 1
			$result[0].DisplayName | Should -Be 'neo42 Pester Application 64'
		}

		It 'Should return nothing for a non-matching name' {
			Get-NXTApplication -Name 'neo42 Pester Application' | Should -BeNullOrEmpty
		}

		It 'Should handle names with quotes' {
			Get-NXTApplication -Name "neo42 Pester's Application" | Should -BeNullOrEmpty
		}
	}

	Context 'When using a filter' {
		It 'Should return all matching applications' {
			$result = @(Get-NXTApplication -Filter { $_.DisplayName -like 'neo42 Pester Application *' } | Sort-Object -Property DisplayName)
			$result | Should -HaveCount 2
			$result.DisplayName | Should -Be @('neo42 Pester Application 32', 'neo42 Pester Application 64')
		}

		It 'Should combine the filter with the name' {
			$result = @(Get-NXTApplication -Name 'neo42 Pester Application' -NamePattern StartsWith -Filter { $_.DisplayVersion -eq '2.0.0' })
			$result | Should -HaveCount 1
			$result[0].DisplayName | Should -Be 'neo42 Pester Application 32'
		}

		It 'Should combine the filter with the identifier' {
			Get-NXTApplication -Identifier 'NxtPesterApplication64' -Filter { $_.DisplayVersion -eq '1.0.0' } | Should -Not -BeNullOrEmpty
			Get-NXTApplication -Identifier 'NxtPesterApplication64' -Filter { $_.DisplayVersion -eq '2.0.0' } | Should -BeNullOrEmpty
		}
	}

	Context 'When using criteria' {
		It 'Should return the application for hashtable criteria' {
			(Get-NXTApplication -Criteria @{ Store = 'ARP64'; Identifier = 'NxtPesterApplication64' }).DisplayName | Should -Be 'neo42 Pester Application 64'
		}

		It 'Should return the application for criteria with identifier and filter' {
			Get-NXTApplication -Criteria @{ Store = 'ARP64'; Identifier = 'NxtPesterApplication64'; Filter = { $_.DisplayVersion -eq '1.0.0' } } | Should -Not -BeNullOrEmpty
			Get-NXTApplication -Criteria @{ Store = 'ARP64'; Identifier = 'NxtPesterApplication64'; Filter = { $_.DisplayVersion -eq '2.0.0' } } | Should -BeNullOrEmpty
		}

		It 'Should return the application for string criteria' {
			(Get-NXTApplication -Criteria 'NxtPesterApplication32').DisplayName | Should -Be 'neo42 Pester Application 32'
		}

		It 'Should return the applications for script block criteria' {
			@(Get-NXTApplication -Criteria { $_.DisplayName -like 'neo42 Pester Application *' }) | Should -HaveCount 2
		}

		It 'Should return the package application for package store criteria' {
			(Get-NXTApplication -Criteria @{ Store = 'Package'; Identifier = $packageGuid }).DisplayName | Should -Be 'neo42 Pester Package'
		}
	}

	Context 'When using a session' {
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
		}

		AfterEach {
			foreach ($property in $originalDetection.Keys) {
				$detection.$property = $originalDetection[$property]
			}
		}

		It 'Should return the application detected by the session' {
			$detection.Enabled = $true
			$detection.Criteria = [PSADTNXT.Application.NxtApplicationCriteria]@{ Store = 'ARP64'; Identifier = 'NxtPesterApplication64' }
			$result = Get-NXTApplication -ADTSession $adtSession
			$result.DisplayName | Should -Be 'neo42 Pester Application 64'
			$detection.Application.DisplayName | Should -Be 'neo42 Pester Application 64'
		}

		It 'Should return nothing if the session detects no application' {
			$detection.Enabled = $true
			$detection.Criteria = [PSADTNXT.Application.NxtApplicationCriteria]@{ Store = 'ARP64'; Identifier = 'NxtPesterApplicationMissing' }
			Get-NXTApplication -ADTSession $adtSession | Should -BeNullOrEmpty
		}
	}

	Context 'When validating parameters' {
		It 'Should throw an exception with null criteria' {
			{ Get-NXTApplication -Criteria $null } | Should -Throw
		}

		It 'Should throw an exception with invalid criteria' {
			{ Get-NXTApplication -Criteria @{ Store = 'ARP' } } | Should -Throw
		}

		It 'Should throw an exception with null session' {
			{ Get-NXTApplication -ADTSession $null } | Should -Throw
		}

		It 'Should throw an exception with an invalid store' {
			{ Get-NXTApplication -Store 'Invalid' } | Should -Throw
		}

		It 'Should throw an exception with an empty identifier' {
			{ Get-NXTApplication -Identifier '' } | Should -Throw
		}

		It 'Should throw an exception with an empty name' {
			{ Get-NXTApplication -Name '' } | Should -Throw
		}

		It 'Should throw an exception with an invalid name pattern' {
			{ Get-NXTApplication -Name 'neo42' -NamePattern 'Invalid' } | Should -Throw
		}

		It 'Should throw an exception with null filter' {
			{ Get-NXTApplication -Filter $null } | Should -Throw
		}
	}
}
