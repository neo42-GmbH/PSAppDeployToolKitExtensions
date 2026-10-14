BeforeDiscovery { . 'C:\Workdir_local\PSAppDeployToolKitExtensions\tests\pester\Initialize-PesterPsadtEnvironment.ps1' }

Describe 'Wait-NXTFileNotInUse' {
	BeforeAll {
		[System.String]$filePathNotExisting = [System.IO.Path]::GetTempFileName()
		[System.String]$filePath = [System.IO.Path]::GetTempFileName()
		[System.IO.File]::WriteAllText($filePath, 'Pester test file')
		function Invoke-FileLock {
			param(
				[System.Management.Automation.SwitchParameter]$Unlock
			)
			if ($Unlock) {
				if (Get-Variable -Name 'fileStream' -Scope 'Script' -ErrorAction Ignore) {
					$script:fileStream.Close()
					return
				}
			}
			[System.IO.FileStream]$script:fileStream = [System.IO.File]::Open(
				$filePath,
				[System.IO.FileMode]::Open,
				[System.IO.FileAccess]::ReadWrite,
				[System.IO.FileShare]::None
			)
		}
	}

	AfterAll {

	}

	Context 'When using invalid path' {
		It 'Should throw an error with a non-existing path' {
			{ Wait-NXTFileNotInUse -Path 'C:\Temp\file.txt' } | Should -Throw
		}
	}
}
