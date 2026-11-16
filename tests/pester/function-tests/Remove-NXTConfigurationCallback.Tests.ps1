BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Remove-NXTConfigurationCallback' {
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
		Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback $first, $second
	}

	AfterAll {
		Clear-NXTConfigurationCallback -HookPoint SetupCfg
		if ($savedCallbacks) { Add-NXTConfigurationCallback -HookPoint SetupCfg -Callback $savedCallbacks }
	}

	Context 'When removing a registered callback' {
		It 'Should only remove the given callback' {
			Remove-NXTConfigurationCallback -HookPoint SetupCfg -Callback $first
			$registered = & $getRegistered
			$registered.Count | Should -Be 1
			$registered[0].Name | Should -Be $second.Name
		}

		It 'Should remove multiple callbacks at once' {
			Remove-NXTConfigurationCallback -HookPoint SetupCfg -Callback $first, $second
			(& $getRegistered).Count | Should -Be 0
		}
	}

	Context 'When removing a callback that is not registered' {
		It 'Should throw' {
			Remove-NXTConfigurationCallback -HookPoint SetupCfg -Callback $first
			{ Remove-NXTConfigurationCallback -HookPoint SetupCfg -Callback $first } | Should -Throw -ExpectedMessage '*no callback*'
		}
	}
}
