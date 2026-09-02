BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Get-NXTProcessTree' {
	Context 'When calculating folder sizes' {
		BeforeAll {
			$cmdProc = Start-Process -FilePath 'cmd.exe' -PassThru -WindowStyle Hidden
		}

		AfterAll {
			if (-not $cmdProc.HasExited) { $cmdProc.Kill() }
		}

		It 'Should return the process tree for this process in the correct order' {
			$processTree = Get-NXTProcessTree -ProcessId $PID
			$processTree | Should -Not -BeNullOrEmpty
			$processTree.Length | Should -BeGreaterThan 0
			$processTree.Id | Should -Contain $cmdProc.Id
			$processTree.Id | Should -Contain $PID
		}

		It 'Should throw an error for an invalid process ID' {
			{ Get-NXTParentProcess -Id 999999 } | Should -Throw
		}

		It 'Should be able to ignore child processes' {
			$processTree = Get-NXTProcessTree -ProcessId $PID -NoChildren
			$processTree | Should -Not -BeNullOrEmpty
			$processTree[-1].Id | Should -Be $PID
		}

		It 'Should be able to ignore parent processes' {
			$processTree = Get-NXTProcessTree -ProcessId $cmdProc.Id -NoParents
			$processTree | Should -Not -BeNullOrEmpty
			$processTree.Id | Should -Contain $cmdProc.Id
		}

		It 'Should respect the depth parameter' {
			$processTree = @(Get-NXTProcessTree -ProcessId $PID -Depth 1)
			$processTree | Should -Not -BeNullOrEmpty
			$processTree.Length | Should -Be 1
			$processTree[0].Id | Should -Be $PID
		}
	}
}
