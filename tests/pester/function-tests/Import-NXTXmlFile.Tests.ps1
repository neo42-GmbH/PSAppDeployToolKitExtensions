BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Import-NXTXmlFile' {
	BeforeAll {
		$file = [System.IO.Path]::GetTempFileName()
	}

	AfterAll {
		Remove-Item -Path $file -ErrorAction SilentlyContinue
	}

	Context 'When importing a legitimate XML file' {
		BeforeAll {
			Set-Content -Path $file -Value '<root/>'
		}

		It 'Should import a simple XML file' {
			$xml = Import-NXTXmlFile -Path $file
			$xml | Should -Not -BeNullOrEmpty
			$xml | Should -BeOfType [System.Xml.XmlDocument]
			$xml.DocumentElement.Name | Should -Be 'root'
		}
	}

	Context 'When importing an invalid XML file' {
		BeforeAll {
			Set-Content -Path $file -Value '<root><invalid></root>'
		}

		It 'Should throw an error for invalid XML' {
			{ Import-NXTXmlFile -Path $file } | Should -Throw
		}

		It 'Should throw an error when the file does not exist' {
			{ Import-NXTXmlFile -Path 'C:\NonExistentFile.xml' } | Should -Throw
		}
	}
}
