BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'New-NXTSessionParameter' {
	BeforeAll {
		# TestDrive is disabled, so a unique temporary directory is used as package directory
		$packageDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "NxtPester_$([System.Guid]::NewGuid().ToString('N'))")
		$null = New-Item -ItemType Directory -Path $packageDir, "$packageDir\Files", "$packageDir\SupportFiles"

		# The deploy script returns its own invocation, mirroring the parameters of the template deploy script
		Set-Content -LiteralPath "$packageDir\Deploy-Application.ps1" -Encoding UTF8 -Value @'
param (
	[System.String]
	$DeploymentType = 'Install',
	[System.String]
	$DeployMode = 'Auto',
	[System.Management.Automation.SwitchParameter]
	$SuppressRebootPassThru,
	[System.Management.Automation.SwitchParameter]
	$TerminalServerMode,
	[System.Management.Automation.SwitchParameter]
	$DisableLogging,
	[System.String]
	$DeploymentSystem
)
return $MyInvocation
'@
		Set-Content -LiteralPath "$packageDir\neo42PackageConfig.psd1" -Encoding UTF8 -Value @'
@{
	ConfigVersion  = '2025.12.01.0'
	Package        = @{
		GUID         = '{42000000-0000-0000-0000-000000000001}'
		Vendor       = 'neo42'
		Name         = 'Pester Package'
		Version      = '2.1'
		Architecture = 'x64'
		Language     = 'DEU'
		Author       = 'neo42 Pester'
		CreationDate = '2026-01-31'
		Revision     = 3
	}
	CloseProcesses = @(
		@{
			Name        = 'notepad'
			Description = 'Editor'
		}
	)
}
'@
		Set-Content -LiteralPath "$packageDir\Pester.cfg" -Encoding UTF8 -Value @(
			'[Options]'
			'DESKTOPSHORTCUT=1'
		)

		$invocation = & "$packageDir\Deploy-Application.ps1" -DeploymentType 'Uninstall' -DeployMode 'Silent' -SuppressRebootPassThru -TerminalServerMode -DisableLogging -DeploymentSystem 'Pester'
		$params = New-NXTSessionParameter -Invocation $invocation -ScriptDirectory $packageDir -SetupCfg "$packageDir\Pester.cfg"
	}

	AfterAll {
		Remove-Item -LiteralPath $packageDir -Recurse -Force -ErrorAction SilentlyContinue
	}

	Context 'When providing all inputs' {
		It 'Should reflect the package config' {
			$params['AppVendor'] | Should -Be 'neo42'
			$params['AppName'] | Should -Be 'Pester Package'
			$params['AppVersion'] | Should -Be '2.1'
			$params['AppArch'] | Should -Be 'x64'
			$params['AppLang'] | Should -Be 'DEU'
			$params['AppRevision'] | Should -Be 3
			$params['AppScriptAuthor'] | Should -Be 'neo42 Pester'
			$params['AppScriptDate'] | Should -Be ([System.DateTime]::new(2026, 1, 31))
			$params['AppProcessesToClose'][0].Name | Should -Be 'notepad'
			$params['AppProcessesToClose'][0].Description | Should -Be 'Editor'
			$params['PackageConfig'].Package.Name | Should -Be 'Pester Package'
		}

		It 'Should reflect the script directory' {
			$params['DirFiles'] | Should -Be "$packageDir\Files"
			$params['DirSupportFiles'] | Should -Be "$packageDir\SupportFiles"
		}

		It 'Should reflect the setup cfg' {
			$params['SetupCfg']['Options']['DESKTOPSHORTCUT'] | Should -Be '1'
		}

		It 'Should reflect the invocation' {
			$params['DeployAppScriptPath'] | Should -Be "$packageDir\Deploy-Application.ps1"
			$params['DeployAppScriptParameters'] | Should -Be $invocation.BoundParameters
		}

		It 'Should reflect the invocation parameters' {
			$params['DeploymentType'] | Should -Be ([PSADT.Module.DeploymentType]::Uninstall)
			$params['NxtDeploymentType'] | Should -Be ([PSADTNXT.Deployment.NxtDeploymentType]::Uninstall)
			$params['DeployMode'] | Should -Be ([PSADT.Module.DeployMode]::Silent)
			$params['SuppressRebootPassThru'] | Should -BeTrue
			$params['TerminalServerMode'] | Should -BeTrue
			$params['DisableLogging'] | Should -BeTrue
			$params['DeploymentSystem'] | Should -Be 'Pester'
		}
	}
}
