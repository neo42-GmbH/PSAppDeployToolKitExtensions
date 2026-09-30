BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Test-NXTProcess' {
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
	}

	AfterAll {
		if (-not $cmdProc.HasExited) { $cmdProc.Kill() }
	}

	Context 'When using process name' {
		It 'Should be true with existing process' {
			Test-NXTProcess -Name $cmdProc.Name | Should -BeTrue
		}

		It 'Should be false with non-existing process' {
			Test-NXTProcess -Name $dummyProcName | Should -BeFalse
		}

		It 'Should throw exception with zero-length string' {
			{
				Test-NXTProcess -Name ''
			} | Should -Throw
		}

		It 'Should throw exception with null value' {
			{
				Test-NXTProcess -Name $null
			} | Should -Throw
		}
	}

	Context 'When using process id' {
		It 'Should be true with existing process' {
			Test-NXTProcess -Id $cmdProc.Id | Should -BeTrue
		}

		It 'Should be false with non-existing process' {
			Test-NXTProcess -Id $dummyProcId | Should -BeFalse
		}

		It 'Should throw exception with invalid value' {
			{
				Test-NXTProcess -Id (-2)
			} | Should -Throw
		}

		It 'Should throw exception with null value' {
			{
				Test-NXTProcess -Id $null
			} | Should -Throw
		}
	}

	Context 'When using ProcessDefinition' {
		It 'Should be true with existing process' {
			Test-NXTProcess -ProcessDefinition $cmdProcDef | Should -BeTrue
		}

		It 'Should be false with non-existing process' {
			Test-NXTProcess -ProcessDefinition $dummyProcDef | Should -BeFalse
		}

		# Origin for false value instead of exception in PSADT core function
		It 'Should be false with invalid value' -Skip {
			{
				Test-NXTProcess -ProcessDefinition (-2)
			} | Should -Throw
		}

		It 'Should throw exception with null value' {
			{
				Test-NXTProcess -ProcessDefinition $null
			} | Should -Throw
		}
	}

	Context 'When using pipeline input' {
		It 'Should be true if data type is String with existing process' {
			$cmdProc.Name | Test-NXTProcess | Should -BeTrue
		}

		It 'Should be false if data type is String with non-existing process' {
			$dummyProcName | Test-NXTProcess | Should -BeFalse
		}

		It 'Should be true if data type is UInt32 with existing process' {
			$cmdProc.Id | Test-NXTProcess | Should -BeTrue
		}

		It 'Should be false if data type is UInt32 with non-existing process' {
			$dummyProcId | Test-NXTProcess | Should -BeFalse
		}

		It 'Should be true if data type is System.Diagnostics.Process with existing process' {
			[PSADT.ProcessManagement.RunningProcess]$cmdProcRun = Get-ADTRunningProcesses -ProcessObjects ([PSADT.ProcessManagement.ProcessDefinition]::new('cmd'))
			$cmdProc | Test-NXTProcess | Should -BeTrue
		}

		It 'Should be true if data type is Microsoft.Management.Infrastructure.CimInstance with existing process' {
			[Microsoft.Management.Infrastructure.CimInstance]$cmdProcCim = (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId like $($cmdProc.Id)" | Select-Object -Last 1)
			$cmdProcCim | Test-NXTProcess | Should -BeTrue
		}

		It 'Should be true if data type is PSADT.ProcessManagement.ProcessDefinition with existing process' {
			$cmdProcDef | Test-NXTProcess | Should -BeTrue
		}

		It 'Should be true if data type is PSADTNXT.ProcessManagement.NxtCloseProcess with existing process' {
			$cmdProcClose | Test-NXTProcess | Should -BeTrue
		}

		It 'Should throw exception if data type is invalid' {
			{
				(Get-Date) | Test-NXTProcess
			} | Should -Throw
		}

		It 'Should throw exception if input is null' {
			{
				$null | Test-NXTProcess
			} | Should -Throw
		}
	}
}
