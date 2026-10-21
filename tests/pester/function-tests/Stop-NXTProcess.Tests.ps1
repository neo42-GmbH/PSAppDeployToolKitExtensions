BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Stop-NXTProcess' {
	BeforeAll {
		$procStartWait = 100

		Stop-Process -Name 'cmd' -Force -ErrorAction SilentlyContinue
		$cmdProc = Start-Process -FilePath 'cmd.exe' -PassThru -WindowStyle Hidden
		Start-Sleep -Milliseconds $procStartWait

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
		AfterEach {
			Stop-Process -Name 'cmd' -Force -ErrorAction SilentlyContinue
			$cmdProc = Start-Process -FilePath 'cmd.exe' -PassThru -WindowStyle Hidden
			Start-Sleep -Milliseconds $procStartWait
		}

		It 'Should be false with existing process' {
			Stop-NXTProcess -Name $cmdProc.Name
			Test-NXTProcess -Name $cmdProc.Name | Should -BeFalse
		}

		It 'Should not throw an exception with non-existing process' {
			Stop-NXTProcess -Name $dummyProcName | Should -BeNullOrEmpty
		}

		It 'Should throw an exception with zero-length string' {
			{
				Stop-NXTProcess -Name ''
			} | Should -Throw
		}

		It 'Should throw exception with null value' {
			{
				Stop-NXTProcess -Name $null
			} | Should -Throw
		}
	}

	Context 'When using process id' {
		AfterEach {
			Stop-Process -Name 'cmd' -Force -ErrorAction SilentlyContinue
			$cmdProc = Start-Process -FilePath 'cmd.exe' -PassThru -WindowStyle Hidden
			Start-Sleep -Milliseconds $procStartWait
		}

		It 'Should be false with existing process' {
			Stop-NXTProcess -Id $cmdProc.Id
			Test-NXTProcess -Id $cmdProc.Id | Should -BeFalse
		}

		It 'Should not throw an exception with non-existing process' {
			Stop-NXTProcess -Id $dummyProcId | Should -BeNullOrEmpty
		}

		It 'Should throw an exception with invalid value' {
			{
				Stop-NXTProcess -Id (-2)
			} | Should -Throw
		}

		It 'Should throw exception with null value' {
			{
				Stop-NXTProcess -Id $null
			} | Should -Throw
		}
	}

	Context 'When using process object' {
		AfterEach {
			Stop-Process -Name 'cmd' -Force -ErrorAction SilentlyContinue
			$cmdProc = Start-Process -FilePath 'cmd.exe' -PassThru -WindowStyle Hidden
			Start-Sleep -Milliseconds $procStartWait
		}

		It 'Should be false with existing process' {
			Stop-NXTProcess -Process $cmdProc
			Test-NXTProcess -Id $cmdProc.Id | Should -BeFalse
		}

		It 'Should throw an exception with invalid value' {
			{
				Stop-NXTProcess -Process (-2)
			} | Should -Throw
		}

		It 'Should throw exception with null value' {
			{
				Stop-NXTProcess -Process $null
			} | Should -Throw
		}
	}

	Context 'When using ProcessDefinition' {
		AfterEach {
			Stop-Process -Name 'cmd' -Force -ErrorAction SilentlyContinue
			$cmdProc = Start-Process -FilePath 'cmd.exe' -PassThru -WindowStyle Hidden
			Start-Sleep -Milliseconds $procStartWait
		}

		It 'Should be true with existing process' {
			Stop-NXTProcess -ProcessDefinition $cmdProcDef
			Test-NXTProcess -ProcessDefinition $cmdProcDef | Should -BeFalse
		}

		It 'Should not throw an exception with non-existing process' {
			Stop-NXTProcess -ProcessDefinition $dummyProcDef | Should -BeNullOrEmpty
		}

		# Origin for false value instead of exception in PSADT core function
		It 'Should be false with invalid value' -Skip {
			{
				Stop-NXTProcess -ProcessDefinition (-2)
			} | Should -Throw
		}

		It 'Should throw exception with null value' {
			{
				Stop-NXTProcess -ProcessDefinition $null
			} | Should -Throw
		}
	}

	Context 'When using pipeline input' {
		AfterEach {
			Stop-Process -Name 'cmd' -Force -ErrorAction SilentlyContinue
			$cmdProc = Start-Process -FilePath 'cmd.exe' -PassThru -WindowStyle Hidden
			Start-Sleep -Milliseconds $procStartWait
		}

		It 'Should be false if data type is String with existing process' {
			$cmdProc.Name | Stop-NXTProcess
			Test-NXTProcess -Name $cmdProc.Name | Should -BeFalse
		}

		It 'Should not throw an exception if data type is String with non-existing process' {
			$dummyProcName | Stop-NXTProcess | Should -BeNullOrEmpty
		}

		It 'Should be false if data type is UInt32 with existing process' {
			$cmdProc.Id | Stop-NXTProcess
			Test-NXTProcess -Id $cmdProc.Id | Should -BeFalse
		}

		It 'Should not throw an exception if data type is UInt32 with non-existing process' {
			$dummyProcId | Stop-NXTProcess | Should -BeFalse
		}

		It 'Should be false if data type is System.Diagnostics.Process with existing process' {
			$cmdProc | Stop-NXTProcess
			Test-NXTProcess -Id $cmdProc.Id | Should -BeFalse
		}

		It 'Should be false if data type is Microsoft.Management.Infrastructure.CimInstance with existing process' {
			[Microsoft.Management.Infrastructure.CimInstance]$cmdProcCim = (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId like $($cmdProc.Id)" | Select-Object -Last 1)
			$cmdProcCim | Stop-NXTProcess
			Test-NXTProcess -Id $cmdProc.Id | Should -BeFalse
		}

		It 'Should be false if data type is PSADT.ProcessManagement.ProcessDefinition with existing process' {
			$cmdProcDef | Stop-NXTProcess
			Test-NXTProcess -Id $cmdProc.Id | Should -BeFalse
		}

		It 'Should be false if data type is PSADT.ProcessManagement.RunningProcess with existing process' {
			[PSADT.ProcessManagement.RunningProcess]$cmdProcRun = Get-ADTRunningProcesses -ProcessObjects ([PSADT.ProcessManagement.ProcessDefinition]::new('cmd'))
			$cmdProcRun | Stop-NXTProcess
			Test-NXTProcess -Id $cmdProc.Id | Should -BeFalse
		}

		It 'Should be false if data type is PSADTNXT.ProcessManagement.NxtCloseProcess with existing process' {
			$cmdProcClose | Stop-NXTProcess
			Test-NXTProcess -Id $cmdProc.Id | Should -BeFalse
		}

		It 'Should throw exception if data type is invalid' {
			{
				(Get-Date) | Stop-NXTProcess
			} | Should -Throw
		}

		It 'Should throw exception if input is null' {
			{
				$null | Stop-NXTProcess
			} | Should -Throw
		}
	}

	Context 'When using with KillProcessTree' {
		It 'Should be false with existing process' {
			# The child process must run directly below cmd.exe and with the same privileges as the test, so it can be stopped:
			# ping.exe is available on every system, does not elevate (unlike regedit.exe) and is no packaged app (unlike notepad.exe on current systems).
			$cmdWithChildProc = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c ping.exe -n 60 127.0.0.1 >nul' -PassThru -WindowStyle Hidden
			[System.UInt32[]]$childProcIds = @()
			for ($i = 0; $i -lt 50 -and $childProcIds.Count -eq 0; $i++) {
				Start-Sleep -Milliseconds $procStartWait
				$childProcIds = @(Get-CimInstance -ClassName Win32_Process -Filter "ParentProcessId = $($cmdWithChildProc.Id) AND Name = 'PING.EXE'" | ForEach-Object -Process { $_.ProcessId })
			}
			$childProcIds | Should -Not -BeNullOrEmpty -Because 'the child process must be running before the process tree is stopped'
			Stop-NXTProcess -Id $cmdWithChildProc.Id -KillProcessTree
			Test-NXTProcess -Id $cmdWithChildProc.Id | Should -BeFalse
			foreach ($childProcId in $childProcIds) {
				Test-NXTProcess -Id $childProcId | Should -BeFalse
			}
		}
	}
}
