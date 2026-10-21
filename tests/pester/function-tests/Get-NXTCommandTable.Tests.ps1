BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Get-NXTCommandTable' {
	BeforeAll {
		$module = Get-Module -Name 'PSAppDeployToolkit.Neo42.Extensions'
		$moduleCommandTable = & $module { $script:CommandTable }
		$exportedFunctionNames = [System.String[]]$module.ExportedFunctions.Keys
		$privateCommandNames = [System.String[]]@($moduleCommandTable.Keys | Where-Object { $_ -like '*-NXT*' -and $_ -notin $exportedFunctionNames })
		$commandTable = Get-NXTCommandTable
	}

	Context 'When retrieving the command table' {
		It 'Should return a read-only dictionary' {
			$commandTable.GetType() | Should -Be ([System.Collections.ObjectModel.ReadOnlyDictionary[System.String, System.Management.Automation.CommandInfo]])
		}

		It 'Should not allow modifications' {
			{ ([System.Collections.Generic.IDictionary[System.String, System.Management.Automation.CommandInfo]]$commandTable).Add('Test-NXTDummy', $null) } | Should -Throw
		}

		It 'Should return a new instance on each call' {
			[System.Object]::ReferenceEquals($commandTable, (Get-NXTCommandTable)) | Should -BeFalse
		}

		It 'Should contain every exported module function' {
			foreach ($functionName in $exportedFunctionNames) {
				$commandTable.ContainsKey($functionName) | Should -BeTrue -Because "[$functionName] is exported by the module"
			}
		}

		It 'Should contain the PSADT commands' {
			$commandTable.ContainsKey('Open-ADTSession') | Should -BeTrue
			$commandTable.ContainsKey('Write-ADTLogEntry') | Should -BeTrue
		}

		It 'Should contain the core commands' {
			$commandTable.ContainsKey('Get-Item') | Should -BeTrue
			$commandTable.ContainsKey('Import-Module') | Should -BeTrue
		}

		It 'Should contain the additional Appx module commands' {
			$commandTable.ContainsKey('Get-AppxPackage') | Should -BeTrue
		}

		It 'Should not contain private module commands' {
			$privateCommandNames | Should -Not -BeNullOrEmpty
			$privateCommandNames | Should -Contain 'Import-NXTPackageConfig'
			foreach ($commandName in $privateCommandNames) {
				$commandTable.ContainsKey($commandName) | Should -BeFalse -Because "[$commandName] is not exported by the module"
			}
		}

		It 'Should contain exactly the module command table without private commands' {
			$expectedNames = [System.String[]]@($moduleCommandTable.Keys | Where-Object { $_ -notin $privateCommandNames } | Sort-Object)
			[System.String[]]@($commandTable.Keys | Sort-Object) | Should -Be $expectedNames
		}

		It 'Should return the same command info objects as the module command table' {
			foreach ($commandName in $commandTable.Keys) {
				[System.Object]::ReferenceEquals($commandTable[$commandName], $moduleCommandTable[$commandName]) | Should -BeTrue -Because "[$commandName] should reference the module command"
			}
		}
	}
}
