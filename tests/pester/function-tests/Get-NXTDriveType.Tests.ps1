BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Get-NXTDriveType' {
	BeforeAll {
		[Microsoft.Management.Infrastructure.CimInstance]$drive = Get-Volume | Where-Object { $_.DriveLetter } | Select-Object -First 1
	}

	Context 'When checking an existing drive' {
		It 'Should identify the drive correctly' {
			Get-NXTDriveType -Name $drive.DriveLetter | Should -Be $drive.DriveType
		}
	}

	Context 'When using different input formats' {
		It 'Should accept drive letter with colon' {
			Get-NXTDriveType -Name $drive.DriveLetter | Should -Be $drive.DriveType
		}

		It 'Should accept drive letter without colon' {
			Get-NXTDriveType -Name "$($drive.DriveLetter):" | Should -Be $drive.DriveType
		}

		It 'Should accept drive letter with trailing backslash' {
			Get-NXTDriveType -Name "$($drive.DriveLetter):\" | Should -Be $drive.DriveType
		}

		It 'Should accept drive path' {
			Get-NXTDriveType -Name "$($drive.DriveLetter):\Windows" | Should -Be $drive.DriveType
		}
	}

	Context 'When using pipeline input' {
		It 'Should accept PSDrive from pipeline' {
			Get-PSDrive -Name $drive.DriveLetter | Get-NXTDriveType | Should -Be $drive.DriveType
		}

		It 'Should accept a CimInstance from pipeline' {
			$drive | Get-NXTDriveType | Should -Be $drive.DriveType
		}
	}

	Context 'When checking special drives' {
		BeforeAll {
			# Create temporary network drive for testing
			[System.Management.Automation.PSDriveInfo]$networkDrive = New-PSDrive -Name 'N' -PSProvider FileSystem -Root "\\localhost\$($drive.DriveLetter)$" -Scope Global -Persist
		}

		AfterAll {
			# Remove the temporary network drive
			$networkDrive | Remove-PSDrive -Force
		}

		It 'Should identify a network drive' {
			Get-NXTDriveType -Name $networkDrive.Name | Should -Be ([System.IO.DriveType]::Network)
		}
	}

	Context 'When checking invalid or non-existent drives' {
		It 'Should throw for completely invalid drive names' {
			{ Get-NXTDriveType -Name 'InvalidDrive' } | Should -Throw
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
				{ Get-NXTDriveType -Name $nonExistentDriveLetter } | Should -Throw
			}
		}
	}
}
