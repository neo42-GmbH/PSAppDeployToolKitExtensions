BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Update-NXTDeploymentStatus' {
	BeforeAll {
		$adtSession = Get-ADTSession
		$originalExitCode = $adtSession.GetExitCode()
		$fastRetryExitCode = (Get-ADTConfig)['UI']['DefaultExitCode']
	}

	BeforeEach {
		$adtSession.SetExitCode(0)
	}

	AfterAll {
		$adtSession.SetExitCode($originalExitCode)
	}

	Context 'When resolving a success exit code' {
		It 'Should set the status to complete for exit code 0 without success codes' {
			Update-NXTDeploymentStatus -ExitCode 0
			$adtSession.GetExitCode() | Should -Be 0
			$adtSession.GetDeploymentStatus() | Should -Be ([PSADT.Module.DeploymentStatus]::Complete)
		}

		It 'Should set the status to complete for a provided success code' {
			Update-NXTDeploymentStatus -ExitCode 0 -SuccessExitCodes 0, 5
			$adtSession.GetExitCode() | Should -Be 0
			$adtSession.GetDeploymentStatus() | Should -Be ([PSADT.Module.DeploymentStatus]::Complete)
		}

		It 'Should translate a success code which is not a session success code to 0' {
			Update-NXTDeploymentStatus -ExitCode 5 -SuccessExitCodes 0, 5
			$adtSession.GetExitCode() | Should -Be 0
			$adtSession.GetDeploymentStatus() | Should -Be ([PSADT.Module.DeploymentStatus]::Complete)
		}
	}

	Context 'When resolving a reboot exit code' {
		It 'Should set the status to restart required for a session reboot code' {
			Update-NXTDeploymentStatus -ExitCode 3010 -RebootExitCodes 3010
			$adtSession.GetExitCode() | Should -Be 3010
			$adtSession.GetDeploymentStatus() | Should -Be ([PSADT.Module.DeploymentStatus]::RestartRequired)
		}

		It 'Should translate a reboot code which is not a session reboot code to 3010' {
			Update-NXTDeploymentStatus -ExitCode 1641 -RebootExitCodes 1641
			$adtSession.GetExitCode() | Should -Be 3010
			$adtSession.GetDeploymentStatus() | Should -Be ([PSADT.Module.DeploymentStatus]::RestartRequired)
		}

		It 'Should prefer reboot codes over success codes' {
			Update-NXTDeploymentStatus -ExitCode 3010 -SuccessExitCodes 3010 -RebootExitCodes 3010
			$adtSession.GetExitCode() | Should -Be 3010
			$adtSession.GetDeploymentStatus() | Should -Be ([PSADT.Module.DeploymentStatus]::RestartRequired)
		}

		It 'Should not treat a session reboot code as reboot without reboot codes' {
			Update-NXTDeploymentStatus -ExitCode 3010
			$adtSession.GetExitCode() | Should -Be 1
			$adtSession.GetDeploymentStatus() | Should -Be ([PSADT.Module.DeploymentStatus]::Error)
		}
	}

	Context 'When resolving a fast retry exit code' {
		It 'Should set the status to fast retry for the configured default exit code' {
			Update-NXTDeploymentStatus -ExitCode $fastRetryExitCode
			$adtSession.GetExitCode() | Should -Be $fastRetryExitCode
			$adtSession.GetDeploymentStatus() | Should -Be ([PSADT.Module.DeploymentStatus]::FastRetry)
		}
	}

	Context 'When resolving an error exit code' {
		It 'Should set the status to error for a non-zero code without success codes' {
			Update-NXTDeploymentStatus -ExitCode 5
			$adtSession.GetExitCode() | Should -Be 5
			$adtSession.GetDeploymentStatus() | Should -Be ([PSADT.Module.DeploymentStatus]::Error)
		}

		It 'Should set the status to error for a code missing in the success codes' {
			Update-NXTDeploymentStatus -ExitCode 6 -SuccessExitCodes 5
			$adtSession.GetExitCode() | Should -Be 6
			$adtSession.GetDeploymentStatus() | Should -Be ([PSADT.Module.DeploymentStatus]::Error)
		}

		It 'Should translate an error code which is a session success code to 1' {
			Update-NXTDeploymentStatus -ExitCode 0 -SuccessExitCodes 5
			$adtSession.GetExitCode() | Should -Be 1
			$adtSession.GetDeploymentStatus() | Should -Be ([PSADT.Module.DeploymentStatus]::Error)
		}
	}

	Context 'When the session already has a deployment status' {
		It 'Should not upgrade an error status to complete' {
			$adtSession.SetExitCode(5)
			Update-NXTDeploymentStatus -ExitCode 0
			$adtSession.GetExitCode() | Should -Be 5
			$adtSession.GetDeploymentStatus() | Should -Be ([PSADT.Module.DeploymentStatus]::Error)
		}

		It 'Should not upgrade an error status to fast retry' {
			$adtSession.SetExitCode(5)
			Update-NXTDeploymentStatus -ExitCode $fastRetryExitCode
			$adtSession.GetExitCode() | Should -Be 5
			$adtSession.GetDeploymentStatus() | Should -Be ([PSADT.Module.DeploymentStatus]::Error)
		}

		It 'Should not upgrade a restart required status to complete' {
			$adtSession.SetExitCode(3010)
			Update-NXTDeploymentStatus -ExitCode 0
			$adtSession.GetExitCode() | Should -Be 3010
			$adtSession.GetDeploymentStatus() | Should -Be ([PSADT.Module.DeploymentStatus]::RestartRequired)
		}

		It 'Should degrade a complete status to restart required' {
			Update-NXTDeploymentStatus -ExitCode 3010 -RebootExitCodes 3010
			$adtSession.GetExitCode() | Should -Be 3010
			$adtSession.GetDeploymentStatus() | Should -Be ([PSADT.Module.DeploymentStatus]::RestartRequired)
		}

		It 'Should degrade a restart required status to error' {
			$adtSession.SetExitCode(3010)
			Update-NXTDeploymentStatus -ExitCode 5
			$adtSession.GetExitCode() | Should -Be 5
			$adtSession.GetDeploymentStatus() | Should -Be ([PSADT.Module.DeploymentStatus]::Error)
		}

		It 'Should overwrite the exit code if the status stays equal' {
			$adtSession.SetExitCode(5)
			Update-NXTDeploymentStatus -ExitCode 6
			$adtSession.GetExitCode() | Should -Be 6
			$adtSession.GetDeploymentStatus() | Should -Be ([PSADT.Module.DeploymentStatus]::Error)
		}
	}

	Context 'When using PassThru' {
		It 'Should return the resolved deployment status' {
			$result = Update-NXTDeploymentStatus -ExitCode 3010 -RebootExitCodes 3010 -PassThru
			$result | Should -BeOfType ([PSADT.Module.DeploymentStatus])
			$result | Should -Be ([PSADT.Module.DeploymentStatus]::RestartRequired)
		}

		It 'Should return the resolved deployment status even if it was not applied' {
			$adtSession.SetExitCode(5)
			Update-NXTDeploymentStatus -ExitCode 0 -PassThru | Should -Be ([PSADT.Module.DeploymentStatus]::Complete)
			$adtSession.GetExitCode() | Should -Be 5
		}

		It 'Should return nothing without PassThru' {
			Update-NXTDeploymentStatus -ExitCode 0 | Should -BeNullOrEmpty
		}
	}

	Context 'When validating parameters' {
		It 'Should require the exit code parameter' {
			(Get-Command -Name 'Update-NXTDeploymentStatus').Parameters['ExitCode'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeTrue
		}

		It 'Should accept the exit code as positional parameter' {
			Update-NXTDeploymentStatus 5
			$adtSession.GetExitCode() | Should -Be 5
		}

		It 'Should update an explicitly provided session' {
			Update-NXTDeploymentStatus -ADTSession $adtSession -ExitCode 5
			$adtSession.GetExitCode() | Should -Be 5
		}

		It 'Should throw an exception with null session' {
			{ Update-NXTDeploymentStatus -ADTSession $null -ExitCode 0 } | Should -Throw
		}

		It 'Should throw an exception with invalid session type' {
			{ Update-NXTDeploymentStatus -ADTSession 'Session' -ExitCode 0 } | Should -Throw
		}

		It 'Should throw an exception with invalid exit code type' {
			{ Update-NXTDeploymentStatus -ExitCode 'Invalid' } | Should -Throw
		}

		It 'Should treat null success and reboot codes as not provided' {
			Update-NXTDeploymentStatus -ExitCode 0 -SuccessExitCodes $null -RebootExitCodes $null
			$adtSession.GetExitCode() | Should -Be 0
			$adtSession.GetDeploymentStatus() | Should -Be ([PSADT.Module.DeploymentStatus]::Complete)
		}
	}
}
