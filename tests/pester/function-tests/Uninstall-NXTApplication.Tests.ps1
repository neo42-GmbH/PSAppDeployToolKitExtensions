BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Uninstall-NXTApplication' {
	BeforeAll {
		[PSADTNXT.Foundation.NxtDeploymentSession]$adtSession = Get-ADTSession
		[PSADTNXT.Deployment.NxtInstallationInstructions]$installation = $adtSession.NXT.Install
		[PSADTNXT.Deployment.NxtUninstallationInstructions]$uninstallation = $adtSession.NXT.Uninstall
		[PSADTNXT.Application.NxtApplicationCriteria]$criteria = $adtSession.NXT.Detection.Criteria
		[System.String]$uninstallKeyPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
		[System.String]$applicationKeyPath = "$uninstallKeyPath\$($criteria.Identifier)"
		[System.String]$packageEntryKeyPath = "$uninstallKeyPath\$($adtSession.NXT.Package.GUID)"
		[System.String]$packageKeyPath = $adtSession.NXT.Package.RegistryKey

		function Test-MockRegistryKey {
			param (
				[System.String]
				$Path
			)
			[Microsoft.Win32.RegistryKey]$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
			try {
				[Microsoft.Win32.RegistryKey]$key = $baseKey.OpenSubKey($Path)
				if ($null -eq $key) { return $false }
				$key.Dispose()
				return $true
			}
			finally {
				$baseKey.Dispose()
			}
		}

		function Install-MockApplication {
			# Install the reference application without relying on Install-NXTApplication
			[System.Diagnostics.Process]$process = Start-Process -FilePath $installation.Target -ArgumentList $installation.Arguments -WindowStyle Hidden -Wait -PassThru
			if ($process.ExitCode -ne 0 -or -not (Test-MockRegistryKey -Path $applicationKeyPath)) {
				throw "Installation of the reference application failed with exit code [$($process.ExitCode)]."
			}
		}

		function Register-MockPackage {
			# The package uninstaller removes the reference application and its own uninstall entry, like a real package uninstallation would
			[System.String]$uninstallString = "`"$([System.Environment]::SystemDirectory)\cmd.exe`" /c reg delete `"HKLM\$applicationKeyPath`" /f /reg:64 & reg delete `"HKLM\$packageEntryKeyPath`" /f /reg:64"
			[Microsoft.Win32.RegistryKey]$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
			try {
				[Microsoft.Win32.RegistryKey]$packageKey = $baseKey.CreateSubKey($packageKeyPath)
				$packageKey.SetValue('ProductName', $adtSession.NXT.Package.DisplayName)
				$packageKey.SetValue('UninstallString', $uninstallString)
				$packageKey.Dispose()

				[Microsoft.Win32.RegistryKey]$packageEntryKey = $baseKey.CreateSubKey($packageEntryKeyPath)
				$packageEntryKey.SetValue('DisplayName', $adtSession.NXT.Package.DisplayName)
				$packageEntryKey.SetValue('UninstallString', $uninstallString)
				$packageEntryKey.SetValue('neoRegPackagesKeyRef', $packageKeyPath)
				$packageEntryKey.Dispose()
			}
			finally {
				$baseKey.Dispose()
			}
		}

		function Remove-MockData {
			[Microsoft.Win32.RegistryKey]$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
			try {
				$baseKey.DeleteSubKeyTree($applicationKeyPath, $false)
				$baseKey.DeleteSubKeyTree($packageEntryKeyPath, $false)
				$baseKey.DeleteSubKeyTree($packageKeyPath, $false)
			}
			finally {
				$baseKey.Dispose()
			}
		}

		Remove-MockData
	}
	AfterEach {
		Remove-MockData
	}
	AfterAll {
		Remove-MockData
	}

	Context 'When using the ManualExitCodes parameter set' {
		BeforeEach {
			Install-MockApplication
		}

		It 'Should uninstall the reference application' {
			[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication -Target $uninstallation.Target -ArgumentList $uninstallation.Arguments -Method $uninstallation.Method
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeFalse
		}

		It 'Should take the target as positional parameter' {
			[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication $uninstallation.Target -ArgumentList $uninstallation.Arguments
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeFalse
		}

		It 'Should validate the uninstallation when criteria is specified' {
			[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication -Target $uninstallation.Target -ArgumentList $uninstallation.Arguments -Criteria $criteria
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeFalse
		}

		It 'Should resolve the uninstall string of the application when only criteria is specified' {
			[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication -Criteria $criteria
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeFalse
		}

		It 'Should accept criteria as hashtable' {
			[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication -Criteria @{ Store = $criteria.Store; Identifier = $criteria.Identifier }
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeFalse
		}

		It 'Should accept criteria as string' {
			[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication -Criteria $criteria.Identifier
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeFalse
		}

		It 'Should accept criteria as scriptblock' {
			[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication -Criteria { $_.DisplayName -eq 'Pester Mock Package' }
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeFalse
		}

		It 'Should throw when criteria is specified but the application was not removed' {
			{
				Uninstall-NXTApplication -Target $uninstallation.Target -ArgumentList '/c exit 0' -Criteria $criteria -ErrorAction Stop
			} | Should -Throw
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeTrue
		}

		It 'Should treat custom success exit codes as success' {
			[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication -Target $uninstallation.Target -ArgumentList '/c exit 5' -SuccessExitCodes 5 -ErrorAction Stop
			$result.ExitCode | Should -Be 5
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeTrue
		}
	}

	Context 'When using the ManualExitCodes parameter set without an installed application' {
		It 'Should succeed when criteria is specified but the application is not installed' {
			[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication -Criteria $criteria -ErrorAction Stop
			$result.ExitCode | Should -Be 0
		}

		It 'Should throw when neither target nor criteria is specified' {
			{
				Uninstall-NXTApplication -ErrorAction Stop
			} | Should -Throw
		}
	}

	Context 'When using the ManualIgnoreExitCodes parameter set' {
		BeforeEach {
			Install-MockApplication
		}

		It 'Should uninstall the reference application' {
			[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication -Target $uninstallation.Target -ArgumentList $uninstallation.Arguments -IgnoreExitCodes
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeFalse
		}

		It 'Should resolve the uninstall string of the application when only criteria is specified' {
			[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication -Criteria $criteria -IgnoreExitCodes
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeFalse
		}

		It 'Should return a non-success exit code without throwing' {
			[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication -Target $uninstallation.Target -ArgumentList '/c exit 1' -IgnoreExitCodes -ErrorAction Stop
			$result.ExitCode | Should -Be 1
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeTrue
		}

		It 'Should throw when combined with -<Name>' -ForEach @(
			@{ Name = 'SuccessExitCodes'; Value = [System.Int32[]]@(0) }
			@{ Name = 'RebootExitCodes'; Value = [System.Int32[]]@(3010) }
			@{ Name = 'ExitOnProcessFailure'; Value = $true }
		) {
			[System.Collections.Hashtable]$exitCodeParams = @{ $Name = $Value }
			{
				Uninstall-NXTApplication -Target $uninstallation.Target -ArgumentList $uninstallation.Arguments -IgnoreExitCodes @exitCodeParams -ErrorAction Stop
			} | Should -Throw
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeTrue
		}
	}

	Context 'When using the ApplicationExitCodes parameter set' {
		BeforeEach {
			Install-MockApplication
			[PSADT.Types.InstalledApplication]$application = Get-NXTApplication -Criteria $criteria
		}

		It 'Should uninstall the reference application' {
			[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication -Application $application
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeFalse
		}

		It 'Should take the application as positional parameter' {
			[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication $application
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeFalse
		}

		It 'Should take the application from the pipeline' {
			[PSADT.ProcessManagement.ProcessResult]$result = $application | Uninstall-NXTApplication
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeFalse
		}

		It 'Should replace the arguments of the uninstall string with the argument list' {
			# reg.exe /? exits with 0 without removing anything, so the application must still be found afterwards
			{
				Uninstall-NXTApplication -Application $application -ArgumentList '/?' -ErrorAction Stop
			} | Should -Throw
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeTrue
		}

		It 'Should throw when combined with -<Name>' -ForEach @(
			@{ Name = 'Target'; Value = 'cmd.exe' }
			@{ Name = 'Criteria'; Value = 'Identifier' }
		) {
			[System.Collections.Hashtable]$manualParams = @{ $Name = $Value }
			{
				Uninstall-NXTApplication -Application $application @manualParams -ErrorAction Stop
			} | Should -Throw
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeTrue
		}
	}

	Context 'When using the ApplicationIgnoreExitCodes parameter set' {
		BeforeEach {
			Install-MockApplication
			[PSADT.Types.InstalledApplication]$application = Get-NXTApplication -Criteria $criteria
		}

		It 'Should uninstall the reference application' {
			[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication -Application $application -IgnoreExitCodes
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeFalse
		}

		It 'Should take the application from the pipeline' {
			[PSADT.ProcessManagement.ProcessResult]$result = $application | Uninstall-NXTApplication -IgnoreExitCodes
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeFalse
		}
	}

	Context 'When using the PackageExitCodes parameter set' {
		BeforeEach {
			Install-MockApplication
			Register-MockPackage
			[PSADTNXT.Package.NxtRegisteredPackage]$package = Get-NXTRegisteredPackage -PackageId $adtSession.NXT.Package.GUID
		}

		It 'Should uninstall the package and the reference application' {
			[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication -Package $package
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $packageEntryKeyPath | Should -BeFalse
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeFalse
		}

		It 'Should take the package as positional parameter' {
			[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication $package
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $packageEntryKeyPath | Should -BeFalse
		}

		It 'Should take the package from the pipeline' {
			[PSADT.ProcessManagement.ProcessResult]$result = $package | Uninstall-NXTApplication
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $packageEntryKeyPath | Should -BeFalse
		}

		It 'Should throw when combined with -<Name>' -ForEach @(
			@{ Name = 'Target'; Value = 'cmd.exe' }
			@{ Name = 'Criteria'; Value = 'Identifier' }
			@{ Name = 'Method'; Value = 'Setup' }
			@{ Name = 'ArgumentList'; Value = [System.String[]]@('/c exit 0') }
			@{ Name = 'AdditionalArgumentList'; Value = [System.String[]]@('/c exit 0') }
			@{ Name = 'CacheDirectory'; Value = 'C:\Cache' }
		) {
			[System.Collections.Hashtable]$invalidParams = @{ $Name = $Value }
			{
				Uninstall-NXTApplication -Package $package @invalidParams -ErrorAction Stop
			} | Should -Throw
			Test-MockRegistryKey -Path $packageEntryKeyPath | Should -BeTrue
		}
	}

	Context 'When using the PackageIgnoreExitCodes parameter set' {
		BeforeEach {
			Install-MockApplication
			Register-MockPackage
			[PSADTNXT.Package.NxtRegisteredPackage]$package = Get-NXTRegisteredPackage -PackageId $adtSession.NXT.Package.GUID
		}

		It 'Should uninstall the package and the reference application' {
			[PSADT.ProcessManagement.ProcessResult]$result = Uninstall-NXTApplication -Package $package -IgnoreExitCodes
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $packageEntryKeyPath | Should -BeFalse
			Test-MockRegistryKey -Path $applicationKeyPath | Should -BeFalse
		}

		It 'Should take the package from the pipeline' {
			[PSADT.ProcessManagement.ProcessResult]$result = $package | Uninstall-NXTApplication -IgnoreExitCodes
			$result.ExitCode | Should -Be 0
			Test-MockRegistryKey -Path $packageEntryKeyPath | Should -BeFalse
		}
	}

	Context 'When passing invalid parameters' {
		It 'Should throw with a <Description> target' -ForEach @(
			@{ Description = 'null'; Value = $null }
			@{ Description = 'empty'; Value = [System.String]::Empty }
		) {
			{
				Uninstall-NXTApplication -Target $Value -ArgumentList '/c exit 0' -ErrorAction Stop
			} | Should -Throw
		}

		It 'Should throw with a null application' {
			{
				Uninstall-NXTApplication -Application $null -ErrorAction Stop
			} | Should -Throw
		}

		It 'Should throw with a null package' {
			{
				Uninstall-NXTApplication -Package $null -ErrorAction Stop
			} | Should -Throw
		}

		It 'Should throw with null pipeline input' {
			{
				$null | Uninstall-NXTApplication -ErrorAction Stop
			} | Should -Throw
		}

		It 'Should throw with pipeline input of an invalid data type' {
			{
				Get-Date | Uninstall-NXTApplication -ErrorAction Stop
			} | Should -Throw
		}

		It 'Should throw with a log file name without .log extension' {
			{
				Uninstall-NXTApplication -Target $uninstallation.Target -ArgumentList '/c exit 0' -LogFileName 'Uninstall.txt' -ErrorAction Stop
			} | Should -Throw
		}

		It 'Should throw with a relative cache directory' {
			{
				Uninstall-NXTApplication -Target $uninstallation.Target -ArgumentList '/c exit 0' -CacheDirectory 'Cache' -ErrorAction Stop
			} | Should -Throw
		}

		It 'Should throw with null criteria' {
			{
				Uninstall-NXTApplication -Criteria $null -ErrorAction Stop
			} | Should -Throw
		}
	}
}
