BeforeDiscovery { . 'C:\Workdir_local\PSAppDeployToolKitExtensions\tests\pester\Initialize-PesterPsadtEnvironment.ps1' }

Describe 'Wait-NXTRegistryKey' {
	BeforeAll {
		[System.String]$regPathNotExisting = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\PesterTestNonExistingKey'
		[System.String]$regPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\PesterTestExistingKey'
		[System.String]$regName = 'Test'
		[System.String]$regVal = '1234'
		[Microsoft.Win32.RegistryKey]$regKey = New-Item -Path $regPath -ErrorAction Ignore
		[PSCustomObject]$regProp = New-ItemProperty -Path $regPath -Name $regName -Value $regVal -ErrorAction Ignore
	}

	AfterAll {
		Remove-Item -Path $regPath -Force -ErrorAction SilentlyContinue
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

	Context 'When using a valid input' -Skip {
		It 'Should be $true when the file exists' {
			Wait-NXTRegistryKey -Path $filePath | Should -BeTrue
		}

		It 'Should be $false after 3 seconds waiting for the file to exist' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTRegistryKey -Path $filePathNotExisting -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeFalse
			$duration.TotalSeconds | Should -BeGreaterOrEqual 3
			$duration.TotalSeconds | Should -BeLessThan 4
		}

		It 'Should be $false after 3 seconds waiting for the file to not exist anymore' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTRegistryKey -Path $filePath -Timeout '00:00:03' -Interval '00:00:02' -IsRemoved
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeFalse
			$duration.TotalSeconds | Should -BeGreaterOrEqual 4
			$duration.TotalSeconds | Should -BeLessThan 5
		}

		It 'Should be $true instantly waiting for the file to exist' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTRegistryKey -Path $filePath -Timeout '00:00:03' -Interval '00:00:00.500'
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeTrue
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be [System.IO.FileSystemInfo] instantly waiting for the file to exist' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTRegistryKey -Path $filePath -Timeout '00:00:03' -Interval '00:00:00.500' -PassThru
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeOfType [System.IO.FileSystemInfo]
			$duration.TotalSeconds | Should -BeLessThan 1
		}

		It 'Should be $null instantly waiting for the file to be in use' {
			$start = [System.DateTime]::Now
			$result = Wait-NXTRegistryKey -Path $filePathNotExisting -Timeout '00:00:03' -Interval '00:00:00.500' -IsRemoved -PassThru
			$duration = [System.DateTime]::Now - $start
			$result | Should -BeNullOrEmpty
			$duration.TotalSeconds | Should -BeLessThan 1
		}
	}
}
