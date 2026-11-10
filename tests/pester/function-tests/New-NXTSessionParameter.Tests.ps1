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

	Context 'When configuration callbacks are registered' {
		BeforeAll {
			# The package config reads a value from the setup cfg to verify callbacks are applied before it is constructed
			$callbackDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "NxtPester_$([System.Guid]::NewGuid().ToString('N'))")
			$null = New-Item -ItemType Directory -Path $callbackDir
			Copy-Item -LiteralPath "$packageDir\Deploy-Application.ps1" -Destination $callbackDir
			(Get-Content -LiteralPath "$packageDir\neo42PackageConfig.psd1" -Raw).Replace("Author       = 'neo42 Pester'", "Author       = `$SetupCfg['Options']['DESKTOPSHORTCUT']") |
				Set-Content -LiteralPath "$callbackDir\neo42PackageConfig.psd1" -Encoding UTF8

			$captured = @{}
			function Set-PesterDesktopShortcut {
				param ([PSADTNXT.Configuration.NxtConfigurationContext]$Context)
				$captured['Context'] = $Context
				$captured['Order'] += @('Set')
				$Context.SetupCfg['Options']['DESKTOPSHORTCUT'] = '1'
			}
			function Set-PesterInvalidValue {
				param ([PSADTNXT.Configuration.NxtConfigurationContext]$Context)
				$Context.SetupCfg['Options']['DESKTOPSHORTCUT'] = '5'
			}
			function Write-PesterOrder {
				param ([PSADTNXT.Configuration.NxtConfigurationContext]$Context)
				$captured['Order'] += @('Prepended')
			}
			$adtConfig = Get-ADTConfig
			$originalSetupCfgConfig = if ($adtConfig['NXT'].ContainsKey('SetupCfg')) { $adtConfig['NXT']['SetupCfg'] } else { $null }
			# Preserve callbacks registered by other modules on import
			$savedCallbacks = InModuleScope -ModuleName 'PSAppDeployToolkit.Neo42.Extensions' -Scriptblock { , $script:ConfigurationCallbacks[[PSADTNXT.Configuration.ConfigurationHookPoint]::SetupCfg].ToArray() }
		}

		BeforeEach {
			$captured.Clear()
			$captured['Order'] = @()
			Clear-NXTConfigurationCallback -HookPoint SetupCfg
			$callbackInvocation = & "$callbackDir\Deploy-Application.ps1" -DeploymentType 'Repair' -DeploymentSystem 'PesterSystem'
		}

		AfterEach {
			Clear-NXTConfigurationCallback -HookPoint SetupCfg
			if ($null -ne $originalSetupCfgConfig) { $adtConfig['NXT']['SetupCfg'] = $originalSetupCfgConfig }
			elseif ($adtConfig['NXT'].ContainsKey('SetupCfg')) { $adtConfig['NXT'].Remove('SetupCfg') }
		}

		AfterAll {
			Remove-Item -LiteralPath $callbackDir -Recurse -Force -ErrorAction SilentlyContinue
			if ($savedCallbacks) { Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback $savedCallbacks }
		}

		It 'Should use the setup cfg value without callbacks' {
			$result = New-NXTSessionParameter -Invocation $callbackInvocation -ScriptDirectory $callbackDir -SetupCfg @()
			$result['PackageConfig'].Package.Author | Should -Be '0'
		}

		It 'Should apply callback changes before the package config is constructed' {
			Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback (Get-Command -Name 'Set-PesterDesktopShortcut')
			$result = New-NXTSessionParameter -Invocation $callbackInvocation -ScriptDirectory $callbackDir -SetupCfg @()
			$result['SetupCfg']['Options']['DESKTOPSHORTCUT'] | Should -Be '1'
			$result['PackageConfig'].Package.Author | Should -Be '1'
		}

		It 'Should provide the context of the invocation' {
			Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback (Get-Command -Name 'Set-PesterDesktopShortcut')
			$null = New-NXTSessionParameter -Invocation $callbackInvocation -ScriptDirectory $callbackDir -SetupCfg @()
			$captured['Context'] | Should -BeOfType ([PSADTNXT.Configuration.NxtConfigurationContext])
			$captured['Context'].DeploymentType | Should -Be ([PSADTNXT.Deployment.NxtDeploymentType]::Repair)
			$captured['Context'].DeploymentSystem | Should -Be 'PesterSystem'
			$captured['Context'].ScriptDirectory | Should -Be $callbackDir
			$captured['Context'].BoundParameters['DeploymentSystem'] | Should -Be 'PesterSystem'
		}

		It 'Should invoke prepended callbacks first' {
			Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback (Get-Command -Name 'Set-PesterDesktopShortcut')
			Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback (Get-Command -Name 'Write-PesterOrder') -Prepend
			$null = New-NXTSessionParameter -Invocation $callbackInvocation -ScriptDirectory $callbackDir -SetupCfg @()
			$captured['Order'] | Should -Be @('Prepended', 'Set')
		}

		It 'Should apply toolkit overrides after the callbacks' {
			$adtConfig['NXT']['SetupCfg'] = @{ Overrides = @{ Pester = 'Options;DESKTOPSHORTCUT;0' } }
			Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback (Get-Command -Name 'Set-PesterDesktopShortcut')
			$result = New-NXTSessionParameter -Invocation $callbackInvocation -ScriptDirectory $callbackDir -SetupCfg @()
			$result['SetupCfg']['Options']['DESKTOPSHORTCUT'] | Should -Be '0'
			$result['PackageConfig'].Package.Author | Should -Be '0'
		}

		It 'Should validate the setup cfg after the callbacks' {
			Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback (Get-Command -Name 'Set-PesterInvalidValue')
			{ New-NXTSessionParameter -Invocation $callbackInvocation -ScriptDirectory $callbackDir -SetupCfg @() } | Should -Throw -ExceptionType ([PSADTNXT.Configuration.NxtIniValidationException])
		}
	}
}
