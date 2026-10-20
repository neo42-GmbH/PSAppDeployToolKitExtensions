BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Get-NXTRegisteredPackage' {
	BeforeAll {
		# Create mock packages in a dedicated packages key, only the installed package has an uninstall key referencing it
		$registryKeyName = 'NxtPesterPackages'
		$legacyRegistryKeyName = 'NxtPesterLegacyPackages'
		$uninstallKeyPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
		$installedGuid = '{42000000-0000-0000-0000-0000000000B1}'
		$registeredGuid = '{42000000-0000-0000-0000-0000000000B2}'
		$legacyGuid = '{42000000-0000-0000-0000-0000000000B3}'
		$danglingGuid = '{42000000-0000-0000-0000-0000000000B4}'
		$appKeyName = 'NxtPesterRegisteredPackageApp'

		function Remove-MockPackage {
			$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
			$baseKey.DeleteSubKeyTree("SOFTWARE\$registryKeyName", $false)
			$baseKey.DeleteSubKeyTree("SOFTWARE\$legacyRegistryKeyName", $false)
			foreach ($keyName in @($installedGuid, $legacyGuid, $danglingGuid, $appKeyName)) {
				$baseKey.DeleteSubKeyTree("$uninstallKeyPath\$keyName", $false)
			}
			$baseKey.Dispose()
		}

		Remove-MockPackage
		$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
		$mockKeys = @{
			"SOFTWARE\$registryKeyName\$installedGuid"    = @{
				ProductName          = 'Pester Installed Package'
				DeveloperName        = 'neo42'
				Version              = '1.2.3'
				Revision             = '4'
				AppPath              = 'C:\ProgramData\neo42Pkgs\neo42\Pester\1.2.3'
				Date                 = '2026-01-31 12:00:00'
				SoftMigrationOccured = '1'
				UninstallString      = '"C:\ProgramData\neo42Pkgs\neo42\Pester\1.2.3\Uninstall.exe" /quiet /log'
			}
			"SOFTWARE\$registryKeyName\$registeredGuid"   = @{
				ProductName   = 'Pester Registered Package'
				DeveloperName = 'neo42'
				Version       = '2.0'
			}
			"SOFTWARE\$legacyRegistryKeyName\$legacyGuid" = @{
				ProductName   = 'Pester Legacy Package'
				DeveloperName = 'neo42'
				Version       = '3.0'
			}
			"$uninstallKeyPath\$installedGuid"            = @{
				DisplayName          = 'neo42 Pester Installed Package'
				neoRegPackagesKeyRef = "SOFTWARE\$registryKeyName\$installedGuid"
			}
			# Older package iterations wrote the back reference without the leading SOFTWARE node
			"$uninstallKeyPath\$legacyGuid"               = @{
				DisplayName          = 'neo42 Pester Legacy Package'
				neoRegPackagesKeyRef = "$legacyRegistryKeyName\$legacyGuid"
			}
			# The back reference points to a package key which does not exist
			"$uninstallKeyPath\$danglingGuid"             = @{
				DisplayName          = 'neo42 Pester Dangling Package'
				neoRegPackagesKeyRef = "SOFTWARE\$registryKeyName\$danglingGuid"
			}
			"$uninstallKeyPath\$appKeyName"               = @{
				DisplayName = 'neo42 Pester Application'
			}
		}
		foreach ($mockKey in $mockKeys.GetEnumerator()) {
			$key = $baseKey.CreateSubKey($mockKey.Key)
			foreach ($value in $mockKey.Value.GetEnumerator()) {
				$key.SetValue($value.Key, $value.Value)
			}
			$key.Dispose()
		}
		$baseKey.Dispose()
	}

	AfterAll {
		Remove-MockPackage
	}

	Context 'When filtering by registry key name' {
		It 'Should return the installed packages of the registry key' {
			$result = @(Get-NXTRegisteredPackage -RegistryKeyName $registryKeyName)
			$result | Should -HaveCount 1
			$result[0] | Should -BeOfType ([PSADTNXT.Package.NxtRegisteredPackage])
			$result[0].GUID | Should -Be $installedGuid
		}

		It 'Should return nothing for a non-existing registry key' {
			Get-NXTRegisteredPackage -RegistryKeyName 'NxtPesterPackagesMissing' | Should -BeNullOrEmpty
		}
	}

	Context 'When filtering by package id' {
		It 'Should return the installed package' {
			$result = @(Get-NXTRegisteredPackage -PackageId $installedGuid)
			$result | Should -HaveCount 1
			$result[0].GUID | Should -Be $installedGuid
		}

		It 'Should accept the package GUID alias' {
			(Get-NXTRegisteredPackage -PackageGUID $installedGuid).GUID | Should -Be $installedGuid
		}

		It 'Should not return a package without uninstall reference' {
			Get-NXTRegisteredPackage -PackageId $registeredGuid | Should -BeNullOrEmpty
		}

		It 'Should return a package without uninstall reference by its registry key name' {
			$result = @(Get-NXTRegisteredPackage -PackageId $registeredGuid -RegistryKeyName $registryKeyName)
			$result | Should -HaveCount 1
			$result[0].GUID | Should -Be $registeredGuid
			$result[0].IsInstalled | Should -BeFalse
			$result[0].Application | Should -BeNullOrEmpty
		}

		It 'Should return nothing for a non-existing package' {
			Get-NXTRegisteredPackage -PackageId '{42000000-0000-0000-0000-0000000000BF}' -RegistryKeyName $registryKeyName | Should -BeNullOrEmpty
		}
	}

	Context 'When resolving the package back reference' {
		It 'Should resolve a back reference including the SOFTWARE node' {
			$result = @(Get-NXTRegisteredPackage -PackageId $installedGuid)
			$result | Should -HaveCount 1
			$result[0].RegistryName | Should -Be $registryKeyName
		}

		It 'Should resolve a legacy back reference without the SOFTWARE node' {
			$result = @(Get-NXTRegisteredPackage -PackageId $legacyGuid)
			$result | Should -HaveCount 1
			$result[0].RegistryName | Should -Be $legacyRegistryKeyName
			$result[0].Name | Should -Be 'Pester Legacy Package'
			$result[0].IsInstalled | Should -BeTrue
		}

		It 'Should resolve a legacy back reference of an application' {
			(Get-NXTApplication -Store Package -Identifier $legacyGuid | Get-NXTRegisteredPackage).GUID | Should -Be $legacyGuid
		}

		It 'Should not return a package for a dangling back reference' {
			Get-NXTRegisteredPackage -PackageId $danglingGuid | Should -BeNullOrEmpty
		}

		It 'Should not return a package for an application with a dangling back reference' {
			$application = Get-NXTApplication -Store Package -Identifier $danglingGuid
			$application | Should -Not -BeNullOrEmpty
			Get-NXTRegisteredPackage -Application $application | Should -BeNullOrEmpty
		}
	}

	Context 'When filtering by installation state' {
		It 'Should return installed packages' {
			(Get-NXTRegisteredPackage -RegistryKeyName $registryKeyName -Installed $true).GUID | Should -Be $installedGuid
		}

		It 'Should return a package which is not installed' {
			(Get-NXTRegisteredPackage -PackageId $registeredGuid -RegistryKeyName $registryKeyName -Installed $false).GUID | Should -Be $registeredGuid
		}

		It 'Should not return packages with a different installation state' {
			Get-NXTRegisteredPackage -RegistryKeyName $registryKeyName -Installed $false | Should -BeNullOrEmpty
			Get-NXTRegisteredPackage -PackageId $registeredGuid -RegistryKeyName $registryKeyName -Installed $true | Should -BeNullOrEmpty
		}
	}

	Context 'When excluding packages' {
		It 'Should not return excluded packages' {
			Get-NXTRegisteredPackage -RegistryKeyName $registryKeyName -Exclude $installedGuid | Should -BeNullOrEmpty
		}

		It 'Should return packages which are not excluded' {
			(Get-NXTRegisteredPackage -RegistryKeyName $registryKeyName -Exclude $registeredGuid).GUID | Should -Be $installedGuid
		}
	}

	Context 'When reading the package properties' {
		BeforeAll {
			$package = Get-NXTRegisteredPackage -PackageId $installedGuid -RegistryKeyName $registryKeyName
		}

		It 'Should provide the registry information' {
			$package.RegistryName | Should -Be $registryKeyName
			$package.GUID | Should -Be $installedGuid
			$package.PSChildName | Should -Be $installedGuid
		}

		It 'Should provide the registered values' {
			$package.Name | Should -Be 'Pester Installed Package'
			$package.Developer | Should -Be 'neo42'
			$package.Version | Should -Be ([System.Version]'1.2.3')
			$package.Revision | Should -Be 4
			$package.PackageDirectory.FullName | Should -Be 'C:\ProgramData\neo42Pkgs\neo42\Pester\1.2.3'
			$package.RegistrationDate | Should -Be ([System.DateTime]::new(2026, 1, 31, 12, 0, 0))
			$package.SoftMigrated | Should -BeTrue
		}

		It 'Should split the uninstall string' {
			$package.UninstallString | Should -Be '"C:\ProgramData\neo42Pkgs\neo42\Pester\1.2.3\Uninstall.exe" /quiet /log'
			$package.UninstallStringFilePath | Should -Be 'C:\ProgramData\neo42Pkgs\neo42\Pester\1.2.3\Uninstall.exe'
			$package.UninstallStringArgumentList | Should -Be @('/quiet', '/log')
		}

		It 'Should provide the installed application' {
			$package.IsInstalled | Should -BeTrue
			$package.Application | Should -BeOfType ([PSADT.Types.InstalledApplication])
			$package.Application.DisplayName | Should -Be 'neo42 Pester Installed Package'
		}
	}

	Context 'When using an application' {
		It 'Should return the package of the application' {
			$application = Get-NXTApplication -Store Package -Identifier $installedGuid
			(Get-NXTRegisteredPackage -Application $application).GUID | Should -Be $installedGuid
		}

		It 'Should accept the application from the pipeline' {
			(Get-NXTApplication -Store Package -Identifier $installedGuid | Get-NXTRegisteredPackage).GUID | Should -Be $installedGuid
		}

		It 'Should return nothing for an application without package reference' {
			$application = Get-NXTApplication -Store ARP64 -Identifier $appKeyName
			$application | Should -Not -BeNullOrEmpty
			Get-NXTRegisteredPackage -Application $application | Should -BeNullOrEmpty
		}
	}

	Context 'When using a session' {
		BeforeAll {
			$adtSession = Get-ADTSession
			$sessionPackageKeyPath = $adtSession.NXT.Package.RegistryKey
		}

		It 'Should return nothing if the session package is not registered' {
			Test-Path -LiteralPath "HKLM:\$sessionPackageKeyPath" | Should -BeFalse -Because 'the mock session package must not be registered on the test machine'
			Get-NXTRegisteredPackage -ADTSession $adtSession | Should -BeNullOrEmpty
		}

		It 'Should return the registered session package' {
			$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
			$keyCreated = $null -eq ($existingKey = $baseKey.OpenSubKey($sessionPackageKeyPath))
			if ($keyCreated) {
				$baseKey.CreateSubKey($sessionPackageKeyPath).Dispose()
			}
			else {
				$existingKey.Dispose()
			}
			try {
				$result = Get-NXTRegisteredPackage -ADTSession $adtSession
				$result | Should -BeOfType ([PSADTNXT.Package.NxtRegisteredPackage])
				$result.GUID | Should -Be $adtSession.NXT.Package.GUID
			}
			finally {
				if ($keyCreated) {
					$baseKey.DeleteSubKeyTree($sessionPackageKeyPath, $false)
				}
				$baseKey.Dispose()
			}
		}
	}

	Context 'When validating parameters' {
		It 'Should throw an exception with an invalid package id' {
			{ Get-NXTRegisteredPackage -PackageId 'Invalid' } | Should -Throw
		}

		It 'Should throw an exception with an empty registry key name' {
			{ Get-NXTRegisteredPackage -RegistryKeyName '' } | Should -Throw
		}

		It 'Should throw an exception with null exclusions' {
			{ Get-NXTRegisteredPackage -Exclude $null } | Should -Throw
		}

		It 'Should throw an exception with null application' {
			{ Get-NXTRegisteredPackage -Application $null } | Should -Throw
		}

		It 'Should throw an exception with null session' {
			{ Get-NXTRegisteredPackage -ADTSession $null } | Should -Throw
		}
	}
}
