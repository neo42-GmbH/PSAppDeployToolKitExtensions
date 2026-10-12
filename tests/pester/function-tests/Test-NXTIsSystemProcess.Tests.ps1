BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Test-NXTIsSystemProcess' {
	BeforeAll {
		Stop-Process -Name 'cmd' -Force -ErrorAction SilentlyContinue
		$cmdProc = Start-Process -FilePath 'cmd.exe' -PassThru -WindowStyle Hidden
		Start-Sleep -Milliseconds 500

		$sysProc = Get-Process | Where-Object -FilterScript { $_.SI -eq 0 } | Select-Object -First 1
		$dummyProcId = 123456789
	}

	AfterAll {
		if (-not $cmdProc.HasExited) { $cmdProc.Kill() }
	}

	Context 'When using process id' {
		It 'Should be true with system process' {
			Test-NXTIsSystemProcess -Id $sysProc.Id | Should -BeTrue
		}

		It 'Should be false with non-system process' {
			Test-NXTIsSystemProcess -Id $cmdProc.Id | Should -BeFalse
		}

		It 'Should be false with non-existing process' {
			Test-NXTProcess -Id $dummyProcId | Should -BeFalse
		}

		It 'Should throw exception with invalid value' {
			{
				Test-NXTIsSystemProcess -Id (-2)
			} | Should -Throw
		}

		It 'Should throw exception with null value' {
			{
				Test-NXTIsSystemProcess -Id $null
			} | Should -Throw
		}
	}

	Context 'When using pipeline input' {
		It 'Should be true if data type is UInt32 with system process' {
			$sysProc.Id | Test-NXTIsSystemProcess | Should -BeTrue
		}

		It 'Should be false if data type is UInt32 with non-system process' {
			$cmdProc.Id | Test-NXTIsSystemProcess | Should -BeFalse
		}

		It 'Should be false if data type is UInt32 with non-existing process' {
			$dummyProcId | Test-NXTIsSystemProcess | Should -BeFalse
		}

		It 'Should be true if data type is System.Diagnostics.Process with system process' {
			Test-NXTIsSystemProcess -Id $sysProc.Id | Should -BeTrue
		}

		It 'Should be false if data type is System.Diagnostics.Process with non-system process' {
			Test-NXTIsSystemProcess -Id $cmdProc.Id | Should -BeFalse
		}

		It 'Should be true if data type is Microsoft.Management.Infrastructure.CimInstance with system process' {
			[Microsoft.Management.Infrastructure.CimInstance]$sysProcCim = (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId like $($sysProc.Id)" | Select-Object -Last 1)
			$sysProcCim | Test-NXTIsSystemProcess | Should -BeTrue
		}

		It 'Should be false if data type is Microsoft.Management.Infrastructure.CimInstance with non-system process' {
			[Microsoft.Management.Infrastructure.CimInstance]$cmdProcCim = (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId like $($cmdProc.Id)" | Select-Object -Last 1)
			$cmdProcCim | Test-NXTIsSystemProcess | Should -BeFalse
		}

		It 'Should throw exception if data type is invalid' {
			{
				(Get-Date) | Test-NXTIsSystemProcess
			} | Should -Throw
		}

		It 'Should throw exception if input is null' {
			{
				$null | Test-NXTIsSystemProcess
			} | Should -Throw
		}
	}
}
