BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Get-NXTDriveFreeSpace' {
	BeforeAll {
		[Microsoft.Management.Infrastructure.CimInstance]$drive = Get-Volume | Where-Object { $_.DriveLetter } | Select-Object -First 1
	}

	Context 'When checking free space of an existing drive' {
		It 'Should return free space in bytes by default' {
			[System.UInt64]$expectedFreeSpace = [System.Math]::Floor($drive.SizeRemaining)
			[System.UInt64]$actualFreeSpace = Get-NXTDriveFreeSpace -Name $drive.DriveLetter
			$actualFreeSpace | Should -BeGreaterOrEqual ($expectedFreeSpace * 0.9) -Because 'Free space can change during test execution'
			$actualFreeSpace | Should -BeLessOrEqual ($expectedFreeSpace * 1.1) -Because 'Free space can change during test execution'
		}

		It 'Should return free space in KB' {
			[System.UInt64]$expectedFreeSpaceKB = [System.Math]::Floor($drive.SizeRemaining / 1KB)
			[System.UInt64]$actualFreeSpaceKB = Get-NXTDriveFreeSpace -Name $drive.DriveLetter -Unit KB
			$actualFreeSpaceKB | Should -BeGreaterOrEqual ($expectedFreeSpaceKB * 0.9) -Because 'Free space can change during test execution'
			$actualFreeSpaceKB | Should -BeLessOrEqual ($expectedFreeSpaceKB * 1.1) -Because 'Free space can change during test execution'
		}

		It 'Should return free space in MB' {
			[System.UInt64]$expectedFreeSpaceMB = [System.Math]::Floor($drive.SizeRemaining / 1MB)
			[System.UInt64]$actualFreeSpaceMB = Get-NXTDriveFreeSpace -Name $drive.DriveLetter -Unit MB
			$actualFreeSpaceMB | Should -BeGreaterOrEqual ($expectedFreeSpaceMB * 0.9) -Because 'Free space can change during test execution'
			$actualFreeSpaceMB | Should -BeLessOrEqual ($expectedFreeSpaceMB * 1.1) -Because 'Free space can change during test execution'
		}

		It 'Should return free space in GB' {
			[System.UInt64]$expectedFreeSpaceGB = [System.Math]::Floor($drive.SizeRemaining / 1GB)
			[System.UInt64]$actualFreeSpaceGB = Get-NXTDriveFreeSpace -Name $drive.DriveLetter -Unit GB
			$actualFreeSpaceGB | Should -BeGreaterOrEqual ($expectedFreeSpaceGB * 0.9) -Because 'Free space can change during test execution'
			$actualFreeSpaceGB | Should -BeLessOrEqual ($expectedFreeSpaceGB * 1.1) -Because 'Free space can change during test execution'
		}

		It 'Should return free space in TB' {
			[System.UInt64]$expectedFreeSpaceTB = [System.Math]::Floor($drive.SizeRemaining / 1TB)
			[System.UInt64]$actualFreeSpaceTB = Get-NXTDriveFreeSpace -Name $drive.DriveLetter -Unit TB
			$actualFreeSpaceTB | Should -BeGreaterOrEqual ($expectedFreeSpaceTB * 0.9) -Because 'Free space can change during test execution'
			$actualFreeSpaceTB | Should -BeLessOrEqual ($expectedFreeSpaceTB * 1.1) -Because 'Free space can change during test execution'
		}
	}

	Context 'When using different input formats' {
		It 'Should accept drive letter with colon' {
			Get-NXTDriveFreeSpace -Name "$($drive.DriveLetter):" | Should -BeOfType [System.UInt64]
		}

		It 'Should accept drive letter without colon' {
			Get-NXTDriveFreeSpace -Name $drive.DriveLetter | Should -BeOfType [System.UInt64]
		}

		It 'Should accept drive letter with trailing backslash' {
			Get-NXTDriveFreeSpace -Name "$($drive.DriveLetter):\" | Should -BeOfType [System.UInt64]
		}

		It 'Should accept a path with drive letter' {
			Get-NXTDriveFreeSpace -Name "$($drive.DriveLetter):\Temp" | Should -BeOfType [System.UInt64]
		}
	}

	Context 'When using pipeline input' {
		It 'Should accept PSDrive from pipeline' {
			Get-PSDrive -Name $drive.DriveLetter | Get-NXTDriveFreeSpace | Should -BeOfType [System.UInt64]
		}

		It 'Should accept a CimInstance from pipeline' {
			$drive | Get-NXTDriveFreeSpace | Should -BeOfType [System.UInt64]
		}
	}

	Context 'When checking invalid or non-existent drives' {
		It 'Should throw for completely invalid drive names' {
			{ Get-NXTDriveFreeSpace -Name 'InvalidDrive' } | Should -Throw
		}

		It 'Should throw for drive letters that do not exist' {
			# Find a drive letter that doesn't exist
			$nonExistentDriveLetter = $null
			foreach ($letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.ToCharArray()) {
				if (-not (Test-Path -Path "$letter`:" -ErrorAction SilentlyContinue)) {
					$nonExistentDriveLetter = "$letter`:"
					break
				}
			}

			if ($nonExistentDriveLetter) {
				{ Get-NXTDriveFreeSpace -Name $nonExistentDriveLetter } | Should -Throw
			}
		}
	}
}
