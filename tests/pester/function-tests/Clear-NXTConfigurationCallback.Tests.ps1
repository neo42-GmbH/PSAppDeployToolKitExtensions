BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Clear-NXTConfigurationCallback' {
	BeforeAll {
		function Invoke-PesterFirstCallback { param ([PSADTNXT.Configuration.NxtConfigurationContext]$Context) }
		$first = Get-Command -Name 'Invoke-PesterFirstCallback'
		$getRegistered = {
			InModuleScope -ModuleName 'PSAppDeployToolkit.Neo42.Extensions' -Scriptblock { , $script:ConfigurationCallbacks[[PSADTNXT.Configuration.ConfigurationHookPoint]::SetupCfg].ToArray() }
		}
		# Preserve callbacks registered by other modules on import
		$savedCallbacks = & $getRegistered
	}

	AfterAll {
		Clear-NXTConfigurationCallback -HookPoint SetupCfg
		if ($savedCallbacks) { Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback $savedCallbacks }
	}

	Context 'When callbacks are registered' {
		It 'Should remove all callbacks of the hook point' {
			Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback $first, $first
			Clear-NXTConfigurationCallback -HookPoint SetupCfg
			(& $getRegistered).Count | Should -Be 0
		}
	}

	Context 'When no callbacks are registered' {
		It 'Should not throw' {
			Clear-NXTConfigurationCallback -HookPoint SetupCfg
			{ Clear-NXTConfigurationCallback -HookPoint SetupCfg } | Should -Not -Throw
		}
	}
}
