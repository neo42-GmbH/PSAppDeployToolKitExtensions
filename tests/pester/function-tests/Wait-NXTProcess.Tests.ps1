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
		It 'Should throw an error with null or empty value' {
			{ Wait-NXTProcess -Name $null } | Should -Throw
			{ Wait-NXTProcess -Name '' } | Should -Throw
		}
	}

	Context 'When using invalid id' {
		It 'Should throw an error with invalid value' {
			{ Wait-NXTProcess -Id 'abc' } | Should -Throw
		}

		It 'Should throw an error with null or empty value' {
			{ Wait-NXTProcess -Id $null } | Should -Throw
			{ Wait-NXTProcess -Id '' } | Should -Throw
		}

		It 'Should throw an error with invalid value datatype' {
			{ Wait-NXTProcess -Id ([System.Guid]::NewGuid()) } | Should -Throw
		}
	}

	Context 'When using invalid ProcessDefinition' {
		It 'Should throw exception with null or empty value' {
			{ Wait-NXTProcess -ProcessDefinition $null } | Should -Throw
			{ Wait-NXTProcess -ProcessDefinition '' } | Should -Throw
		}

		It 'Should throw an error with invalid value datatype' {
			{ Test-NXTProcess -ProcessDefinition ([System.Guid]::NewGuid()) } | Should -Throw
		}
	}

	Context 'When using invalid timeout' {
		It 'Should throw an error with an invalid value' {
			{ Wait-NXTProcess -Path $filePath -Timeout 'abc' } | Should -Throw
		}

		It 'Should throw an error with null or empty value' {
			{ Wait-NXTProcess -Path $filePath -Timeout $null } | Should -Throw
			{ Wait-NXTProcess -Path $filePath -Timeout '' } | Should -Throw
		}

		It 'Should throw an error with an invalid value datatype' {
			{ Wait-NXTProcess -Path $filePath -Timeout ([System.Guid]::NewGuid()) } | Should -Throw
		}
	}

	Context 'When using invalid interval' {
		It 'Should throw an error with an invalid value' {
			{ Wait-NXTProcess -Path $filePath -Interval 'abc' } | Should -Throw
		}

		It 'Should throw an error with null or empty value' {
			{ Wait-NXTProcess -Path $filePath -Interval $null } | Should -Throw
			{ Wait-NXTProcess -Path $filePath -Interval '' } | Should -Throw
		}

		It 'Should throw an error with an invalid value datatype' {
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

	Context 'When using a valid input' {
		It 'Should be $true instantly waiting for the process to exist using Name parameter' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTProcess -Name $cmdProc.Name -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeTrue
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be $true instantly waiting for the process to exist using Id parameter' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTProcess -Id $cmdProc.Id -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeTrue
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be $true instantly waiting for the process to exist using ProcessDefinition parameter' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTProcess -ProcessDefinition $cmdProcDef -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeTrue
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be $true instantly waiting for the process to exist using [System.String] pipeline input' {
			$start = [System.DateTime]::Now
			$result = $cmdProc.Name | Wait-NXTProcess -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeTrue
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be $true instantly waiting for the process to exist using [System.Int32] pipeline input' {
			$start = [System.DateTime]::Now
			$result = $cmdProc.Id | Wait-NXTProcess -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeTrue
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be $true instantly waiting for the process to exist using [System.Diagnostics.Process] pipeline input' {
			$start = [System.DateTime]::Now
			$result = $cmdProc | Wait-NXTProcess -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeTrue
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be $true instantly waiting for the process to exist using [Microsoft.Management.Infrastructure.CimInstance] pipeline input' {
			$cmdProcCim = Get-CmdProcCim
			$start = [System.DateTime]::Now
			$result = $cmdProcCim | Wait-NXTProcess -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeTrue
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be $true instantly waiting for the process to exist using [PSADT.ProcessManagement.ProcessDefinition] pipeline input' {
			$start = [System.DateTime]::Now
			$result = $cmdProcDef | Wait-NXTProcess -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeTrue
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be $true instantly waiting for the process to exist using [PSADTNXT.ProcessManagement.NxtCloseProcess] pipeline input' {
			$start = [System.DateTime]::Now
			$result = $cmdProcClose | Wait-NXTProcess -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeTrue
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be $false after 3 seconds waiting for the process to exist' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTProcess -Name $dummyProcName -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeFalse
			$duration.TotalSeconds | Should -BeGreaterOrEqual 3
			$duration.TotalSeconds | Should -BeLessThan 4
		}

		It 'Should be $false after 3 seconds waiting for the process to not exist anymore' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTProcess -Name $cmdProc.Name -Timeout '00:00:03' -Interval '00:00:02' -IsStopped
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeFalse
			$duration.TotalSeconds | Should -BeGreaterOrEqual 4
			$duration.TotalSeconds | Should -BeLessThan 5
		}

		It 'Should be $true instantly waiting for the process to exist' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTProcess -Name $cmdProc.Name -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeTrue
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be [System.Diagnostics.Process] instantly waiting for the process to exist' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTProcess -Name $cmdProc.Name -Timeout '00:00:03' -Interval '00:00:00.500' -PassThru
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeOfType [System.Diagnostics.Process]
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be $null instantly waiting for the process to be stopped' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTProcess -Id $dummyProcId -Timeout '00:00:03' -Interval '00:00:00.500' -IsStopped -PassThru
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeNullOrEmpty
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be $true instantly waiting for a non-existing process to be stopped using pipeline input as [PSADTNXT.ProcessManagement.NxtCloseProcess]' {
			$start = [System.DateTime]::Now
			$result = $dummyProcClose | Wait-NXTProcess -Timeout '00:00:03' -Interval '00:00:00.500' -IsStopped
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeTrue
			$duration.TotalSeconds | Should -BeLessThan 1
		}
	}
}
