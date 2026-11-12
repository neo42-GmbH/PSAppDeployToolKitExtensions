BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Add-NXTConfigurationCallback' {
	BeforeAll {
		function Invoke-PesterFirstCallback { param ([PSADTNXT.Configuration.NxtConfigurationContext]$Context) }
		function Invoke-PesterSecondCallback { param ([PSADTNXT.Configuration.NxtConfigurationContext]$Context) }
		$first = Get-Command -Name 'Invoke-PesterFirstCallback'
		$second = Get-Command -Name 'Invoke-PesterSecondCallback'
		$getRegistered = {
			InModuleScope -ModuleName 'PSAppDeployToolkit.Neo42.Extensions' -Scriptblock { , $script:ConfigurationCallbacks[[PSADTNXT.Configuration.ConfigurationHookPoint]::SetupCfg].ToArray() }
		}
		# Preserve callbacks registered by other modules on import
		$savedCallbacks = & $getRegistered
	}

	BeforeEach {
		Clear-NXTConfigurationCallback -HookPoint SetupCfg
	}

	AfterAll {
		Clear-NXTConfigurationCallback -HookPoint SetupCfg
		if ($savedCallbacks) { Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback $savedCallbacks }
	}

	Context 'When adding callbacks' {
		It 'Should append callbacks in order' {
			Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback $first
			Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback $second
			$registered = & $getRegistered
			$registered.Count | Should -Be 2
			$registered[0].Name | Should -Be $first.Name
			$registered[1].Name | Should -Be $second.Name
		}

		It 'Should prepend callbacks' {
			Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback $first
			Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback $second -Prepend
			$registered = & $getRegistered
			$registered[0].Name | Should -Be $second.Name
			$registered[1].Name | Should -Be $first.Name
		}

		It 'Should accept multiple callbacks at once' {
			Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback $first, $second
			(& $getRegistered).Count | Should -Be 2
		}
	}

	Context 'When providing invalid input' {
		It 'Should throw on an unknown hook point' {
			{ Add-NXTConfigurationCallback -HookPoint 'NotAHookPoint' -Callback $first } | Should -Throw
		}

		It 'Should throw on a null callback' {
			{ Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback $null } | Should -Throw
		}
	}
}
