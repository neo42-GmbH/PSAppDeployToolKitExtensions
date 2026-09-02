BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Get-NXTParentProcess' {
	Context 'When calculating folder sizes' {
		BeforeAll {
			$cmdProc = Start-Process -FilePath 'cmd.exe' -PassThru -WindowStyle Hidden
		}

		AfterAll {
			if (-not $cmdProc.HasExited) { $cmdProc.Kill() }
		}

		It 'Should return the parent process of a child process' {
			$parentProcess = Get-NXTParentProcess -ProcessId $cmdProc.Id
			$parentProcess | Should -Not -BeNullOrEmpty
			$parentProcess.Id | Should -Be $PID
		}

		It 'Should return the list of processes in the parent hierarchy' {
			$parentProcesses = Get-NXTParentProcess -ProcessId $cmdProc.Id -Recurse
			$parentProcesses | Should -Not -BeNullOrEmpty
			$parentProcesses.Length | Should -BeGreaterThan 0
			$parentProcesses[-1].Id | Should -Be $PID
		}

		It 'Should throw an error for an invalid process ID' {
			{ Get-NXTParentProcess -Id 999999 } | Should -Throw
		}

		It 'Should recurse the parent process chain' {
			$parentProcesses = Get-NXTParentProcess -ProcessId $cmdProc.Id -Recurse
			$parentProcesses | Should -Not -BeNullOrEmpty
			$parentProcesses.Length | Should -BeGreaterThan 1
			$parentProcesses[-1].Id | Should -Be $PID
		}

		It 'Should respect the depth parameter' {
			$parentProcesses = @(Get-NXTParentProcess -ProcessId $cmdProc.Id -Recurse -Depth 1)
			$parentProcesses | Should -Not -BeNullOrEmpty
			$parentProcesses.Length | Should -Be 1
			$parentProcesses[0].Id | Should -Be $PID
		}
	}
}
