BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Import-NXTIniFile' {
	BeforeAll {
		# Create temporary INI files for testing
		$simpleIniFile = [System.IO.Path]::GetTempFileName()
		$complexIniFile = [System.IO.Path]::GetTempFileName()
		$emptyIniFile = [System.IO.Path]::GetTempFileName()
		$commentedIniFile = [System.IO.Path]::GetTempFileName()
		$nonExistentIniFile = [System.IO.Path]::GetTempFileName()
		Remove-Item -Path $nonExistentIniFile -ErrorAction SilentlyContinue

		# Create INI file content
		$simpleIniContent = @'
[General]
Name=Test Application
Version=1.0
Enabled=true

[Settings]
Path=C:\Program Files\Test
ConnectionString=Server=localhost;Database=TestDB;
'@

		$complexIniContent = @'
[Section1]
Key1=Value1
Key2=Value2

[Section2]
SubKey1=SubValue1
SubKey2=SubValue2

[EmptySection]

[Section3]
Array=Item1,Item2,Item3
'@

		$commentedIniContent = @'
; This is a comment at the top
[General]
; Comment before key
Name=Test Application  ; Comment after value
Version=1.0

; Comment between sections
[Settings]
# Another comment style
Path=C:\Program Files\Test
ConnectionString=Server=localhost;Database=TestDB;
'@

		# Write content to files
		Set-Content -Path $simpleIniFile -Value $simpleIniContent
		Set-Content -Path $complexIniFile -Value $complexIniContent
		Set-Content -Path $emptyIniFile -Value ([System.String]::Empty)
		Set-Content -Path $commentedIniFile -Value $commentedIniContent
	}

	AfterAll {
		# Clean up test files
		Remove-Item -Path $simpleIniFile -ErrorAction SilentlyContinue
		Remove-Item -Path $complexIniFile -ErrorAction SilentlyContinue
		Remove-Item -Path $emptyIniFile -ErrorAction SilentlyContinue
		Remove-Item -Path $commentedIniFile -ErrorAction SilentlyContinue
	}

	Context 'When importing as hashtable' {
		It 'Should import a simple INI file correctly' {
			$result = Import-NXTIniFile -Path $simpleIniFile
			$result | Should -BeOfType [System.Collections.Hashtable]
			$result['General']['Name'] | Should -Be 'Test Application'
			$result['General']['Version'] | Should -Be '1.0'
			$result['General']['Enabled'] | Should -Be 'true'
			$result['Settings']['Path'] | Should -Be 'C:\Program Files\Test'
		}

		It 'Should handle multiple sections' {
			$result = Import-NXTIniFile -Path $complexIniFile
			$result.Count | Should -Be 4
			$result['Section1']['Key1'] | Should -Be 'Value1'
			$result['Section2']['SubKey1'] | Should -Be 'SubValue1'
			$result.ContainsKey('EmptySection') | Should -BeTrue
		}

		It 'Should handle empty INI files' {
			$result = Import-NXTIniFile -Path $emptyIniFile
			$result | Should -BeOfType [System.Collections.Hashtable]
			$result.Count | Should -Be 0
		}

		It 'Should be able to access properties dynamically' {
			$result = Import-NXTIniFile -Path $simpleIniFile
			$result.General.Name | Should -Be 'Test Application'
		}
	}

	Context 'When importing as IniDocument' {
		It 'Should return an IniDocument object when -AsIniDocument is specified' {
			$result = Import-NXTIniFile -Path $simpleIniFile -AsIniDocument
			Should -ActualValue $result -BeOfType [PSADTNXT.Configuration.NxtIniDocument]
			$result['General']['Name'] | Should -Be 'Test Application'
		}

		It 'Should preserve comments in the IniDocument' {
			$result = Import-NXTIniFile -Path $commentedIniFile -AsIniDocument
			Should -ActualValue $result -BeOfType [PSADTNXT.Configuration.NxtIniDocument]

			$result.GetComment('General') | Should -Be ' This is a comment at the top'
			$result['General'].GetComment('Name') | Should -Be ' Comment before key'
		}
	}

	Context 'When using different path parameters' {
		It 'Should accept literal path' {
			$result = Import-NXTIniFile -LiteralPath $simpleIniFile
			$result | Should -BeOfType [System.Collections.Hashtable]
			$result['General']['Name'] | Should -Be 'Test Application'
		}

		It 'Should accept file objects from pipeline' {
			$fileObject = Get-Item -Path $simpleIniFile
			$result = $fileObject | Import-NXTIniFile
			$result | Should -BeOfType [System.Collections.Hashtable]
			$result['General']['Name'] | Should -Be 'Test Application'
		}
	}

	Context 'When handling errors' {
		It 'Should throw when file does not exist' {
			{ Import-NXTIniFile -Path $nonExistentIniFile } | Should -Throw
		}
	}
}
