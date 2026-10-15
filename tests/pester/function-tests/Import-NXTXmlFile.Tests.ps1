BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Import-NXTXmlFile' {
	BeforeAll {
		[System.String]$file = [System.IO.Path]::GetTempFileName()
		[System.Xml.XmlDocument]$xml = '<?xml version="1.0" encoding="UTF-8"?>
			<root>
				<parent_single>
					<child property="pvalue">Value</child>
				</parent_single>
				<parent_multiple>
					<child>AnotherValue</child>
					<child>YetAnotherValue</child>
				</parent_multiple>
			</root>'
		$xml.Save($file)
		[System.IO.FileInfo]$fileObj = Get-Item $file

		[System.String]$fileHidden = ([System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName()))
		[System.IO.FileInfo]$fileHiddenObj = Copy-Item -Path $file -Destination $fileHidden -Force -PassThru
		$fileHiddenObj.Attributes = 'Hidden'

		[System.String]$fileInvalid = [System.IO.Path]::GetTempFileName()
		[System.String]$xmlInvalid = '<?xml version="1.0" encoding="UTF-8"?>
			<root>
				<invalidNoClosingTag>
			</root>'
		Set-Content -Path $fileInvalid -Value $xmlInvalid -Encoding UTF8
		[System.IO.FileInfo]$fileInvalidObj = Get-Item $fileInvalid

		[System.String]$fileNotExisting = ([System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName()))
	}

	AfterAll {
		Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
		Remove-Item -Path $fileHidden -Force -ErrorAction SilentlyContinue
		Remove-Item -Path $fileInvalid -Force -ErrorAction SilentlyContinue
	}

	Context 'When importing a valid XML file' {
		It 'Should import a simple XML file' {
			$xml = Import-NXTXmlFile -Path $file
			$xml | Should -Not -BeNullOrEmpty
			$xml | Should -BeOfType [System.Xml.XmlDocument]
			$xml.DocumentElement.Name | Should -Be 'root'
		}

		It 'Should import a hidden XML file when using the -Force parameter' {
			$xml = Import-NXTXmlFile -Path $fileHidden -Force
			$xml | Should -Not -BeNullOrEmpty
			$xml | Should -BeOfType [System.Xml.XmlDocument]
			$xml.DocumentElement.Name | Should -Be 'root'
		}

		It 'Should throw an exception importing a hidden XML file when not using the -Force parameter' {
			{ Import-NXTXmlFile -Path $fileHidden } | Should -Throw
		}
	}

	Context 'When importing an invalid XML file' {
		It 'Should throw an error for invalid XML' {
			{ Import-NXTXmlFile -Path $fileInvalid } | Should -Throw
		}

		It 'Should throw an error when the file does not exist' {
			{ Import-NXTXmlFile -Path $fileNotExisting } | Should -Throw
		}
	}
}
