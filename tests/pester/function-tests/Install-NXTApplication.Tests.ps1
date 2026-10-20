BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Install-NXTApplication' {
	BeforeAll {
		[PSADTNXT.Foundation.NxtDeploymentSession]$adtSession = Get-ADTSession
		[PSADTNXT.Deployment.NxtInstallationInstructions]$installation = $adtSession.NXT.Install
		[PSADTNXT.Application.NxtApplicationCriteria]$criteria = $adtSession.NXT.Detection.Criteria
		[System.String]$applicationKeyPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($criteria.Identifier)"

		function Test-MockApplication {
			[Microsoft.Win32.RegistryKey]$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
			try {
				[Microsoft.Win32.RegistryKey]$applicationKey = $baseKey.OpenSubKey($applicationKeyPath)
				if ($null -eq $applicationKey) { return $false }
				$applicationKey.Dispose()
				return $true
			}
			finally {
				$baseKey.Dispose()
			}
		}

		function Remove-MockApplication {
			[Microsoft.Win32.RegistryKey]$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
			try {
				$baseKey.DeleteSubKeyTree($applicationKeyPath, $false)
			}
			finally {
				$baseKey.Dispose()
			}
		}

		Remove-MockApplication
	}
	AfterEach {
		Remove-MockApplication
	}
	AfterAll {
		Remove-MockApplication
	}

	Context 'When using the ExitCodes parameter set' {
		It 'Should install the reference application' {
			[PSADT.ProcessManagement.ProcessResult]$result = Install-NXTApplication -Target $installation.Target -ArgumentList $installation.Arguments -Method $installation.Method
			$result.ExitCode | Should -Be 0
			Test-MockApplication | Should -BeTrue
		}

		It 'Should register the reference application with the expected data' {
			$null = Install-NXTApplication -Target $installation.Target -ArgumentList $installation.Arguments -Method $installation.Method
			[PSADT.Types.InstalledApplication[]]$applications = @(Get-NXTApplication -Criteria $criteria)
			$applications | Should -HaveCount 1
			$applications[0].DisplayName | Should -Be 'Pester Mock Package'
			$applications[0].DisplayVersion | Should -Be $adtSession.AppVersion
			$applications[0].WindowsInstaller | Should -BeFalse
		}

		It 'Should take the target as positional parameter' {
			[PSADT.ProcessManagement.ProcessResult]$result = Install-NXTApplication $installation.Target -ArgumentList $installation.Arguments
			$result.ExitCode | Should -Be 0
			Test-MockApplication | Should -BeTrue
		}

		It 'Should take the target by alias' {
			[PSADT.ProcessManagement.ProcessResult]$result = Install-NXTApplication -FilePath $installation.Target -ArgumentList $installation.Arguments
			$result.ExitCode | Should -Be 0
			Test-MockApplication | Should -BeTrue
		}

		It 'Should validate the installation when criteria is specified' {
			[PSADT.ProcessManagement.ProcessResult]$result = Install-NXTApplication -Target $installation.Target -ArgumentList $installation.Arguments -Criteria $criteria
			$result.ExitCode | Should -Be 0
			Test-MockApplication | Should -BeTrue
		}

		It 'Should accept criteria as hashtable' {
			[PSADT.ProcessManagement.ProcessResult]$result = Install-NXTApplication -Target $installation.Target -ArgumentList $installation.Arguments -Criteria @{ Store = $criteria.Store; Identifier = $criteria.Identifier }
			$result.ExitCode | Should -Be 0
			Test-MockApplication | Should -BeTrue
		}

		It 'Should accept criteria as string' {
			[PSADT.ProcessManagement.ProcessResult]$result = Install-NXTApplication -Target $installation.Target -ArgumentList $installation.Arguments -Criteria $criteria.Identifier
			$result.ExitCode | Should -Be 0
			Test-MockApplication | Should -BeTrue
		}

		It 'Should accept criteria as scriptblock' {
			[PSADT.ProcessManagement.ProcessResult]$result = Install-NXTApplication -Target $installation.Target -ArgumentList $installation.Arguments -Criteria { $_.DisplayName -eq 'Pester Mock Package' }
			$result.ExitCode | Should -Be 0
			Test-MockApplication | Should -BeTrue
		}

		It 'Should throw when criteria is specified but the application was not installed' {
			{
				Install-NXTApplication -Target $installation.Target -ArgumentList '/c exit 0' -Criteria $criteria -ErrorAction Stop
			} | Should -Throw
		}

		It 'Should treat custom success exit codes as success' {
			[PSADT.ProcessManagement.ProcessResult]$result = Install-NXTApplication -Target $installation.Target -ArgumentList '/c exit 5' -SuccessExitCodes 5 -ErrorAction Stop
			$result.ExitCode | Should -Be 5
		}
	}

	Context 'When using the IgnoreExitCodes parameter set' {
		It 'Should install the reference application' {
			[PSADT.ProcessManagement.ProcessResult]$result = Install-NXTApplication -Target $installation.Target -ArgumentList $installation.Arguments -IgnoreExitCodes
			$result.ExitCode | Should -Be 0
			Test-MockApplication | Should -BeTrue
		}

		It 'Should return a non-success exit code without throwing' {
			[PSADT.ProcessManagement.ProcessResult]$result = Install-NXTApplication -Target $installation.Target -ArgumentList '/c exit 1' -IgnoreExitCodes -ErrorAction Stop
			$result.ExitCode | Should -Be 1
		}

		It 'Should validate the installation when criteria is specified' {
			[PSADT.ProcessManagement.ProcessResult]$result = Install-NXTApplication -Target $installation.Target -ArgumentList $installation.Arguments -Criteria $criteria -IgnoreExitCodes
			$result.ExitCode | Should -Be 0
			Test-MockApplication | Should -BeTrue
		}

		It 'Should throw when combined with -<Name>' -ForEach @(
			@{ Name = 'SuccessExitCodes'; Value = [System.Int32[]]@(0) }
			@{ Name = 'RebootExitCodes'; Value = [System.Int32[]]@(3010) }
			@{ Name = 'ExitOnProcessFailure'; Value = $true }
		) {
			[System.Collections.Hashtable]$exitCodeParams = @{ $Name = $Value }
			{
				Install-NXTApplication -Target $installation.Target -ArgumentList '/c exit 0' -IgnoreExitCodes @exitCodeParams -ErrorAction Stop
			} | Should -Throw
			Test-MockApplication | Should -BeFalse
		}
	}

	Context 'When composing the argument list' {
		It 'Should escape and join an argument list with multiple entries' {
			[PSADT.ProcessManagement.ProcessResult]$result = Install-NXTApplication -Target $installation.Target -ArgumentList '/c', 'exit', '3' -IgnoreExitCodes
			$result.ExitCode | Should -Be 3
		}

		It 'Should append the additional argument list to the argument list' {
			[PSADT.ProcessManagement.ProcessResult]$result = Install-NXTApplication -Target $installation.Target -ArgumentList '/c exit' -AdditionalArgumentList '4' -IgnoreExitCodes
			$result.ExitCode | Should -Be 4
		}

		It 'Should escape and join an additional argument list with multiple entries' {
			[PSADT.ProcessManagement.ProcessResult]$result = Install-NXTApplication -Target $installation.Target -ArgumentList '/c' -AdditionalArgumentList 'exit', '6' -IgnoreExitCodes
			$result.ExitCode | Should -Be 6
		}
	}

	Context 'When passing invalid parameters' {
		It 'Should throw with a <Description> target' -ForEach @(
			@{ Description = 'null'; Value = $null }
			@{ Description = 'empty'; Value = [System.String]::Empty }
		) {
			{
				Install-NXTApplication -Target $Value -ArgumentList '/c exit 0' -ErrorAction Stop
			} | Should -Throw
		}

		It 'Should throw with a null argument list' {
			{
				Install-NXTApplication -Target $installation.Target -ArgumentList $null -ErrorAction Stop
			} | Should -Throw
		}

		It 'Should throw with a null additional argument list' {
			{
				Install-NXTApplication -Target $installation.Target -AdditionalArgumentList $null -ErrorAction Stop
			} | Should -Throw
		}

		It 'Should throw with a log file name without .log extension' {
			{
				Install-NXTApplication -Target $installation.Target -ArgumentList '/c exit 0' -LogFileName 'Install.txt' -ErrorAction Stop
			} | Should -Throw
		}

		It 'Should throw with a relative cache directory' {
			{
				Install-NXTApplication -Target $installation.Target -ArgumentList '/c exit 0' -CacheDirectory 'Cache' -ErrorAction Stop
			} | Should -Throw
		}

		It 'Should throw with null criteria' {
			{
				Install-NXTApplication -Target $installation.Target -ArgumentList '/c exit 0' -Criteria $null -ErrorAction Stop
			} | Should -Throw
		}

		It 'Should throw with criteria of an invalid data type' {
			{
				Install-NXTApplication -Target $installation.Target -ArgumentList '/c exit 0' -Criteria (Get-Date) -ErrorAction Stop
			} | Should -Throw
		}
	}
}
