BeforeDiscovery { . 'C:\Workdir_local\PSAppDeployToolKitExtensions\tests\pester\Initialize-PesterPsadtEnvironment.ps1' }

Describe 'Wait-NXTProcess' {
	BeforeAll {
		Stop-Process -Name 'cmd' -Force -ErrorAction SilentlyContinue
		$cmdProc = Start-Process -FilePath 'cmd.exe' -PassThru -WindowStyle Hidden
		Start-Sleep -Milliseconds 500

		$cmdProcDef = [PSADT.ProcessManagement.ProcessDefinition]::new('cmd')
		$cmdProcClose = [PSADTNXT.ProcessManagement.NxtCloseProcess]::new('cmd')
		$dummyProcDef = [PSADT.ProcessManagement.ProcessDefinition]::new('dummy')
		$dummyProcClose = [PSADTNXT.ProcessManagement.NxtCloseProcess]::new('dummy')
		$dummyProcName = 'dummy'
		$dummyProcId = 123456789

		function Get-CmdProcCim {
			return [Microsoft.Management.Infrastructure.CimInstance](Get-CimInstance -ClassName Win32_Process -Filter "ProcessId like $($cmdProc.Id)" | Select-Object -Last 1)
		}
	}

	AfterAll {
		if (-not $cmdProc.HasExited) { $cmdProc.Kill() }
	}

	Context 'When using invalid name' {
		It 'Should throw an error with null or empty name' {
			{ Wait-NXTProcess -Name $null } | Should -Throw
			{ Wait-NXTProcess -Name '' } | Should -Throw
		}
	}

	Context 'When using invalid id' {
		It 'Should throw an error with invalid id' {
			{ Wait-NXTProcess -Id 'abc' } | Should -Throw
		}

		It 'Should throw an error with null or empty id value' {
			{ Wait-NXTProcess -Id $null } | Should -Throw
			{ Wait-NXTProcess -Id '' } | Should -Throw
		}

		It 'Should throw an error with invalid id datatype' {
			{ Wait-NXTProcess -Id ([System.Guid]::NewGuid()) } | Should -Throw
		}
	}

	Context 'When using invalid ProcessDefinition' {
		It 'Should throw exception with null value' {
			{ Wait-NXTProcess -ProcessDefinition $null } | Should -Throw
			{ Wait-NXTProcess -ProcessDefinition '' } | Should -Throw
		}

		It 'Should throw an error with invalid id datatype' {
			{ Test-NXTProcess -ProcessDefinition ([System.Guid]::NewGuid()) } | Should -Throw
		}
	}

	Context 'When using invalid timeout' {
		It 'Should throw an error with an invalid timeout value' {
			{ Wait-NXTProcess -Path $filePath -Timeout 'abc' } | Should -Throw
		}

		It 'Should throw an error with null or empty timeout value' {
			{ Wait-NXTProcess -Path $filePath -Timeout $null } | Should -Throw
			{ Wait-NXTProcess -Path $filePath -Timeout '' } | Should -Throw
		}

		It 'Should throw an error with an invalid timeout value datatype' {
			{ Wait-NXTProcess -Path $filePath -Timeout ([System.Guid]::NewGuid()) } | Should -Throw
		}
	}

	Context 'When using invalid interval' {
		It 'Should throw an error with an invalid interval value' {
			{ Wait-NXTProcess -Path $filePath -Interval 'abc' } | Should -Throw
		}

		It 'Should throw an error with null or empty interval value' {
			{ Wait-NXTProcess -Path $filePath -Interval $null } | Should -Throw
			{ Wait-NXTProcess -Path $filePath -Interval '' } | Should -Throw
		}

		It 'Should throw an error with an invalid interval value datatype' {
			{ Wait-NXTProcess -Path $filePath -Interval ([System.Guid]::NewGuid()) } | Should -Throw
		}
	}

	Context 'When using a invalid pipeline input' {
		It 'Should throw an error with null or empty value' {
			{ $null | Wait-NXTProcess } | Should -Throw
			{ '' | Wait-NXTProcess } | Should -Throw
		}

		It 'Should throw an error with an invalid value datatype' {
			{ [System.Guid]::NewGuid() | Wait-NXTProcess } | Should -Throw
		}
	}

	Context 'When using a valid input' -Skip {
		It 'Should be true with existing process' {
			Test-NXTProcess -ProcessDefinition $cmdProcDef | Should -BeTrue
		}

		It 'Should be false with non-existing process' {
			Test-NXTProcess -ProcessDefinition $dummyProcDef | Should -BeFalse
		}

		It 'Should be $true when the file exists' {
			Wait-NXTProcess -Path $filePath | Should -BeTrue
		}

		It 'Should be $false after 3 seconds waiting for the file to exist' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTProcess -Path $filePathNotExisting -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeFalse
			$duration.TotalSeconds | Should -BeGreaterOrEqual 3
			$duration.TotalSeconds | Should -BeLessThan 4
		}

		It 'Should be $false after 3 seconds waiting for the file to not exist anymore' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTProcess -Path $filePath -Timeout '00:00:03' -Interval '00:00:02' -IsRemoved
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeFalse
			$duration.TotalSeconds | Should -BeGreaterOrEqual 4
			$duration.TotalSeconds | Should -BeLessThan 5
		}

		It 'Should be $true instantly waiting for the file to exist' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTProcess -Path $filePath -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeTrue
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be [System.IO.FileSystemInfo] instantly waiting for the file to exist' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTProcess -Path $filePath -Timeout '00:00:03' -Interval '00:00:00.500' -PassThru
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeOfType [System.IO.FileSystemInfo]
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be $null instantly waiting for the file to be in use' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTProcess -Path $filePathNotExisting -Timeout '00:00:03' -Interval '00:00:00.500' -IsRemoved -PassThru
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeNullOrEmpty
			$duration.TotalSeconds | Should -BeLessThan 1
		}
	}
}
