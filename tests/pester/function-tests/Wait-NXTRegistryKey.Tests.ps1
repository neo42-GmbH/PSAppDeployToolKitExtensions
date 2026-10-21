BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Wait-NXTRegistryKey' {
	BeforeAll {
		[System.String]$regPathNotExisting = 'HKEY_LOCAL_MACHINE\SOFTWARE\PesterTestNonExistingKey'
		[System.String]$regName = 'Test'
		[System.String]$regVal = '1234'

		[System.String]$regPath = 'HKEY_LOCAL_MACHINE\SOFTWARE\PesterTestExistingKey'
		[Microsoft.Win32.RegistryKey]$regKey = New-Item -Path "Registry::$regPath" -ErrorAction Ignore
		[PSCustomObject]$regProp = New-ItemProperty -Path "Registry::$regPath" -Name $regName -Value $regVal -ErrorAction Ignore

		[System.String]$regPathx86 = 'HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\PesterTestExistingKey'
		[Microsoft.Win32.RegistryKey]$regKeyx86 = New-Item -Path "Registry::$regPathx86" -ErrorAction Ignore
		[PSCustomObject]$regPropx86 = New-ItemProperty -Path "Registry::$regPathx86" -Name $regName -Value $regVal -ErrorAction Ignore
	}

	AfterAll {
		Remove-Item -Path "Registry::$regPath" -Force -ErrorAction SilentlyContinue
		Remove-Item -Path "Registry::$regPathx86" -Force -ErrorAction SilentlyContinue
	}

	Context 'When using invalid key' {
		It 'Should throw an error with null or empty value' {
			{ Wait-NXTRegistryKey -Key $null } | Should -Throw
			{ Wait-NXTRegistryKey -Key '' } | Should -Throw
		}
	}

	Context 'When using invalid keyname' {
		It 'Should throw an error with null or empty value' {
			{ Wait-NXTRegistryKey -Key $regPath -KeyName $null } | Should -Throw
			{ Wait-NXTRegistryKey -Key $regPath -KeyName '' } | Should -Throw
		}
	}

	Context 'When using invalid keyvalue' {
		It 'Should throw an error with null or empty value' {
			{ Wait-NXTRegistryKey -Key $regPath -KeyName $regName -KeyValue $null } | Should -Throw
			{ Wait-NXTRegistryKey -Key $regPath -KeyName $regName -KeyValue '' } | Should -Throw
		}
	}

	Context 'When using invalid timeout' {
		It 'Should throw an error with an invalid timeout value' {
			{ Wait-NXTRegistryKey -Path $filePath -Timeout 'abc' } | Should -Throw
		}

		It 'Should throw an error with null or empty timeout value' {
			{ Wait-NXTRegistryKey -Path $filePath -Timeout $null } | Should -Throw
			{ Wait-NXTRegistryKey -Path $filePath -Timeout '' } | Should -Throw
		}

		It 'Should throw an error with an invalid timeout value datatype' {
			{ Wait-NXTRegistryKey -Path $filePath -Timeout ([System.Guid]::NewGuid()) } | Should -Throw
		}
	}

	Context 'When using invalid interval' {
		It 'Should throw an error with an invalid interval value' {
			{ Wait-NXTRegistryKey -Path $filePath -Interval 'abc' } | Should -Throw
		}

		It 'Should throw an error with null or empty interval value' {
			{ Wait-NXTRegistryKey -Path $filePath -Interval $null } | Should -Throw
			{ Wait-NXTRegistryKey -Path $filePath -Interval '' } | Should -Throw
		}

		It 'Should throw an error with an invalid interval value datatype' {
			{ Wait-NXTRegistryKey -Path $filePath -Interval ([System.Guid]::NewGuid()) } | Should -Throw
		}
	}

	Context 'When using a invalid pipeline input' {
		It 'Should throw an error with null or empty value' {
			{ $null | Wait-NXTRegistryKey } | Should -Throw
			{ '' | Wait-NXTRegistryKey } | Should -Throw
		}

		It 'Should throw an error with an invalid value datatype' {
			{ [System.Guid]::NewGuid() | Wait-NXTRegistryKey } | Should -Throw
		}
	}

	Context 'When using a valid input' {
		It 'Should be $true instantly waiting for the registry key to exist' {
			Wait-NXTRegistryKey -Key $regPath -Timeout '00:00:03' -Interval '00:00:00.500' | Should -BeTrue
		}

		It 'Should be $true instantly waiting for the registry key and name to exist' {
			Wait-NXTRegistryKey -Key $regPath -KeyName $regName -Timeout '00:00:03' -Interval '00:00:00.500' | Should -BeTrue
		}

		It 'Should be $true instantly waiting for the registry key and name and value to exist' {
			Wait-NXTRegistryKey -Key $regPath -KeyName $regName -KeyValue $regVal -Timeout '00:00:03' -Interval '00:00:00.500' | Should -BeTrue
		}

		It 'Should be $true instantly waiting for the registry key and name and value to exist for x86' {
			Wait-NXTRegistryKey -Key $regPath -KeyName $regName -KeyValue $regVal -Timeout '00:00:03' -Interval '00:00:00.500' -Wow6432Node | Should -BeTrue
		}

		It 'Should be $true instantly waiting for the registry key to exist using pipeline input' {
			$regKey | Wait-NXTRegistryKey -Timeout '00:00:03' -Interval '00:00:00.500' | Should -BeTrue
		}

		It 'Should be [PSCustomObject] instantly waiting for the registry key to exist using pipeline input for x86' {
			$start = [System.DateTime]::Now
			$result = $regKeyx86 | Wait-NXTRegistryKey -Timeout '00:00:03' -Interval '00:00:00.500' -PassThru
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeOfType [PSCustomObject]
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be $false after 3 seconds waiting for the registry key to exist' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTRegistryKey -Key $regPathNotExisting -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeFalse
			$duration.TotalSeconds | Should -BeGreaterOrEqual 3
			$duration.TotalSeconds | Should -BeLessThan 4
		}

		It 'Should be $false after 3 seconds waiting for the registry key to not exist anymore' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTRegistryKey -Key $regPath -Timeout '00:00:03' -Interval '00:00:02' -IsRemoved
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeFalse
			$duration.TotalSeconds | Should -BeGreaterOrEqual 4
			$duration.TotalSeconds | Should -BeLessThan 5
		}

		It 'Should be $true instantly waiting for the registry key to exist' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTRegistryKey -Key $regPath -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeTrue
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be [PSCustomObject] instantly waiting for the registry key to exist' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTRegistryKey -Key $regPath -Timeout '00:00:03' -Interval '00:00:00.500' -PassThru
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeOfType [PSCustomObject]
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be $null instantly waiting for the registry key to be removed' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTRegistryKey -Key $regPathNotExisting -Timeout '00:00:03' -Interval '00:00:00.500' -IsRemoved -PassThru
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeNullOrEmpty
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be $true after 3 seconds waiting for the registry key for x86 to exist' {
			Remove-Item -Path "Registry::$regPathx86" -Force -ErrorAction SilentlyContinue
			$start = [System.DateTime]::Now
			$result = Wait-NXTRegistryKey -Key $regPath -Timeout '00:00:03' -Interval '00:00:01' -Wow6432Node
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeFalse
			$duration.TotalSeconds | Should -BeGreaterOrEqual 3
			$duration.TotalSeconds | Should -BeLessThan 4
		}
	}
}
