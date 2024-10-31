Describe 'Save-NxtXmlFile' {
	Context 'When given a xml object' {
		BeforeAll {
			@"
<Root123>
	<Level1>
		<Level2>Some Text</Level2>
	</Level1>
</Root123>
"@ | Out-File -FilePath $PSScriptRoot\test.xml -Encoding utf8
		}
		AfterAll {
			if (Test-Path -Path $PSScriptRoot\test.xml) {
				Remove-Item -Path $PSScriptRoot\test.xml -Force
				Remove-Item -Path $PSScriptRoot\test2.xml -Force
			}
		}

		It 'Should save the xml object to a file with utf8 encoding and BOM' {
			$xml = Import-NxtXmlFile -Path $PSScriptRoot\test.xml
			Save-NxtXmlFile -Path $PSScriptRoot\test2.xml -Xml $xml
			$imported = Import-NxtXmlFile -Path $PSScriptRoot\test2.xml
			$imported.Root123.OuterXml | Should -Be $xml.Root123.OuterXml
			Get-NxtFileEncoding -Path $PSScriptRoot\test2.xml | Should -Be 'UTF8withBOM'
		}
		It 'Should save the xml object to a file with unicode encoding' {
			$xml = Import-NxtXmlFile -Path $PSScriptRoot\test.xml
			Save-NxtXmlFile -Path $PSScriptRoot\test2.xml -Xml $xml -Encoding Unicode
			$imported = Import-NxtXmlFile -Path $PSScriptRoot\test2.xml
			$imported.Root123.OuterXml | Should -Be $xml.Root123.OuterXml
			Get-NxtFileEncoding -Path $PSScriptRoot\test2.xml | Should -Be 'Unicode'
		}
		It 'Should save the xml object to a file with utf8 encoding without BOM' {
			$xml = Import-NxtXmlFile -Path $PSScriptRoot\test.xml
			Save-NxtXmlFile -Path $PSScriptRoot\test2.xml -Xml $xml -Encoding UTF8
			$imported = Import-NxtXmlFile -Path $PSScriptRoot\test2.xml
			$imported.Root123.OuterXml | Should -Be $xml.Root123.OuterXml
			Get-NxtFileEncoding -Path $PSScriptRoot\test2.xml -DefaultEncoding UTF8 | Should -Be 'UTF8'
		}
		It 'Should save the xml object to a file with Default encoding' {
			$xml = Import-NxtXmlFile -Path $PSScriptRoot\test.xml
			Save-NxtXmlFile -Path $PSScriptRoot\test2.xml -Xml $xml -Encoding Default
			$imported = Import-NxtXmlFile -Path $PSScriptRoot\test2.xml
			$imported.Root123.OuterXml | Should -Be $xml.Root123.OuterXml
			Get-NxtFileEncoding -Path $PSScriptRoot\test2.xml -DefaultEncoding Default | Should -Be 'Default'
		}
		It 'Should save the xml object to a file with ASCII encoding' {
			$xml = Import-NxtXmlFile -Path $PSScriptRoot\test.xml
			Save-NxtXmlFile -Path $PSScriptRoot\test2.xml -Xml $xml -Encoding ASCII
			$imported = Import-NxtXmlFile -Path $PSScriptRoot\test2.xml
			$imported.Root123.OuterXml | Should -Be $xml.Root123.OuterXml
			Get-NxtFileEncoding -Path $PSScriptRoot\test2.xml -DefaultEncoding ASCII | Should -Be 'ASCII'
		}
	}
}
