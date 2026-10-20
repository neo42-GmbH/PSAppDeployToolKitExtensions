BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Remove-NXTService' {
	BeforeAll {
		$serviceKeyPath = 'HKLM:\SYSTEM\CurrentControlSet\Services'
		$createdServices = [System.Collections.Generic.List[System.String]]::new()

		# The function only removes the service key, the service control manager keeps the service until it is deleted or the system restarts.
		# Therefore each test creates services with unique names, which are deleted from the service control manager afterwards.
		function New-MockService {
			param (
				[System.String]
				$DependsOn
			)
			$serviceName = "NxtPester_$([System.Guid]::NewGuid().ToString('N').Substring(0, 8))"
			$scArgs = @('create', $serviceName, 'binPath=', 'C:\Windows\System32\svchost.exe -k NxtPester', 'start=', 'demand')
			if ($DependsOn) {
				$scArgs += @('depend=', $DependsOn)
			}
			$null = & sc.exe @scArgs
			$LASTEXITCODE | Should -Be 0
			$createdServices.Add($serviceName)
			return $serviceName
		}
	}

	AfterAll {
		foreach ($serviceName in $createdServices) {
			$null = & sc.exe delete $serviceName
		}
	}

	Context 'When removing a stopped service' {
		It 'Should remove the service' {
			$serviceName = New-MockService
			Remove-NXTService -Name $serviceName
			Test-Path -LiteralPath "$serviceKeyPath\$serviceName" | Should -BeFalse
		}

		It 'Should remove multiple services' {
			$serviceNames = @((New-MockService), (New-MockService))
			Remove-NXTService -Name $serviceNames
			foreach ($serviceName in $serviceNames) {
				Test-Path -LiteralPath "$serviceKeyPath\$serviceName" | Should -BeFalse
			}
		}

		It 'Should not throw an exception with a non-existing service' {
			{ Remove-NXTService -Name 'NxtPester_Missing' } | Should -Not -Throw
		}
	}

	Context 'When the service has dependent services' {
		It 'Should throw an exception' {
			$serviceName = New-MockService
			$null = New-MockService -DependsOn $serviceName
			{ Remove-NXTService -Name $serviceName } | Should -Throw -ErrorId 'ServiceHasDependencies,Remove-NXTService'
			Test-Path -LiteralPath "$serviceKeyPath\$serviceName" | Should -BeTrue
		}

		It 'Should remove the service with Force' {
			$serviceName = New-MockService
			$null = New-MockService -DependsOn $serviceName
			Remove-NXTService -Name $serviceName -Force
			Test-Path -LiteralPath "$serviceKeyPath\$serviceName" | Should -BeFalse
		}
	}

	Context 'When the service is marked for deletion' {
		BeforeEach {
			$serviceName = New-MockService
			Set-ItemProperty -LiteralPath "$serviceKeyPath\$serviceName" -Name 'DeleteFlag' -Value 1 -Type DWord
		}

		It 'Should skip the removal' {
			Remove-NXTService -Name $serviceName
			Test-Path -LiteralPath "$serviceKeyPath\$serviceName" | Should -BeTrue
		}

		It 'Should remove the service with Force' {
			Remove-NXTService -Name $serviceName -Force
			Test-Path -LiteralPath "$serviceKeyPath\$serviceName" | Should -BeFalse
		}
	}

	Context 'When validating parameters' {
		It 'Should require the name parameter' {
			(Get-Command -Name 'Remove-NXTService').Parameters['Name'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeTrue
		}

		It 'Should throw an exception with null name' {
			{ Remove-NXTService -Name $null } | Should -Throw
		}

		It 'Should throw an exception with empty name' {
			{ Remove-NXTService -Name '' } | Should -Throw
		}

		It 'Should accept the timeout as <Description>' -ForEach @(
			@{ Description = 'time span string'; Timeout = '00:00:05' }
			@{ Description = 'seconds'; Timeout = '5' }
			@{ Description = 'time span'; Timeout = [System.TimeSpan]::FromSeconds(5) }
		) {
			$serviceName = New-MockService
			Remove-NXTService -Name $serviceName -Timeout $Timeout
			Test-Path -LiteralPath "$serviceKeyPath\$serviceName" | Should -BeFalse
		}

		It 'Should throw an exception with an invalid timeout' {
			{ Remove-NXTService -Name 'NxtPester_Missing' -Timeout 'Invalid' } | Should -Throw
		}
	}
}
