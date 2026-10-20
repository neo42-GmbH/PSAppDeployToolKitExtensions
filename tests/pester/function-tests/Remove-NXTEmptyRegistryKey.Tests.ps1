BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Remove-NXTEmptyRegistryKey' {
	BeforeAll {
		$rootKeyName = 'SOFTWARE\NxtPesterEmptyRegistryKey'
		$rootKey = "HKLM:\$rootKeyName"
		$wowRootKey = 'HKLM:\SOFTWARE\WOW6432Node\NxtPesterEmptyRegistryKey'
		$userSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
		$userRootKey = "Registry::HKEY_USERS\$userSid\$rootKeyName"

		function Remove-MockKey {
			foreach ($view in @([Microsoft.Win32.RegistryView]::Registry64, [Microsoft.Win32.RegistryView]::Registry32)) {
				$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $view)
				$baseKey.DeleteSubKeyTree($rootKeyName, $false)
				$baseKey.Dispose()
			}
			[Microsoft.Win32.Registry]::Users.DeleteSubKeyTree("$userSid\$rootKeyName", $false)
		}
	}

	BeforeEach {
		Remove-MockKey
		$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
		$baseKey.CreateSubKey("$rootKeyName\Empty").Dispose()
		$baseKey.CreateSubKey("$rootKeyName\WithSubKey\Child").Dispose()
		$valueKey = $baseKey.CreateSubKey("$rootKeyName\WithValue")
		$valueKey.SetValue('Value', 'Data')
		$valueKey.Dispose()
		$baseKey.Dispose()
	}

	AfterAll {
		Remove-MockKey
	}

	Context 'When removing a registry key' {
		It 'Should remove an empty key' {
			Remove-NXTEmptyRegistryKey -Key "$rootKey\Empty"
			Test-Path -LiteralPath "$rootKey\Empty" | Should -BeFalse
		}

		It 'Should not remove a key with values' {
			Remove-NXTEmptyRegistryKey -Key "$rootKey\WithValue"
			Test-Path -LiteralPath "$rootKey\WithValue" | Should -BeTrue
		}

		It 'Should not remove a key with sub keys' {
			Remove-NXTEmptyRegistryKey -Key "$rootKey\WithSubKey"
			Test-Path -LiteralPath "$rootKey\WithSubKey\Child" | Should -BeTrue
		}

		It 'Should not throw an exception with a non-existing key' {
			{ Remove-NXTEmptyRegistryKey -Key "$rootKey\Missing" } | Should -Not -Throw
		}

		It 'Should accept the key as positional parameter' {
			Remove-NXTEmptyRegistryKey "$rootKey\Empty"
			Test-Path -LiteralPath "$rootKey\Empty" | Should -BeFalse
		}

		It 'Should accept a provider qualified key' {
			Remove-NXTEmptyRegistryKey -Key "Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\$rootKeyName\Empty"
			Test-Path -LiteralPath "$rootKey\Empty" | Should -BeFalse
		}
	}

	Context 'When using the pipeline' {
		It 'Should remove empty keys from the pipeline' {
			Get-ChildItem -LiteralPath $rootKey | Remove-NXTEmptyRegistryKey
			Test-Path -LiteralPath "$rootKey\Empty" | Should -BeFalse
			Test-Path -LiteralPath "$rootKey\WithValue" | Should -BeTrue
			Test-Path -LiteralPath "$rootKey\WithSubKey\Child" | Should -BeTrue
		}
	}

	Context 'When using the Wow6432Node' {
		It 'Should remove the empty key from the Wow6432Node' {
			$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry32)
			$baseKey.CreateSubKey("$rootKeyName\Empty").Dispose()
			$baseKey.Dispose()

			Remove-NXTEmptyRegistryKey -Key "$rootKey\Empty" -Wow6432Node
			Test-Path -LiteralPath "$wowRootKey\Empty" | Should -BeFalse
			Test-Path -LiteralPath "$rootKey\Empty" | Should -BeTrue
		}
	}

	Context 'When using a SID' {
		It 'Should remove the empty key of the user' {
			[Microsoft.Win32.Registry]::Users.CreateSubKey("$userSid\$rootKeyName\Empty").Dispose()

			Remove-NXTEmptyRegistryKey -Key "HKCU:\$rootKeyName\Empty" -Sid $userSid
			Test-Path -LiteralPath "$userRootKey\Empty" | Should -BeFalse
		}
	}

	Context 'When validating parameters' {
		It 'Should require the key parameter' {
			(Get-Command -Name 'Remove-NXTEmptyRegistryKey').Parameters['Key'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeTrue
		}

		It 'Should throw an exception with null key' {
			{ Remove-NXTEmptyRegistryKey -Key $null } | Should -Throw
		}

		It 'Should throw an exception with empty key' {
			{ Remove-NXTEmptyRegistryKey -Key '' } | Should -Throw
		}

		It 'Should throw an exception with empty SID' {
			{ Remove-NXTEmptyRegistryKey -Key "$rootKey\Empty" -Sid '' } | Should -Throw
		}
	}
}
