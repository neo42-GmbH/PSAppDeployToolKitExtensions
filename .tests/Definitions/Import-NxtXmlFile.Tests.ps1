Describe 'Import-NxtXmlFile' {
	Context 'When given a simple XML file' {
		BeforeAll {
			@'
<Root123>
	<Level1>
		<Level2>Some Text</Level2>
	</Level1>
</Root123>
'@ | Out-File -FilePath $PSScriptRoot\test.xml -Encoding utf8
		}
		AfterAll {
			if (Test-Path -Path $PSScriptRoot\test.xml) {
				Remove-Item -Path $PSScriptRoot\test.xml -Force
			}
		}

		It 'Should return the XML file contents as xml objects' {
			$result = Import-NxtXmlFile -Path $PSScriptRoot\test.xml
			# Return value is a hashtable
			$result.GetEnumerator().Name | Should -Contain 'Root123'
			$result.Root123 | Should -BeOfType 'System.Xml.XmlLinkedNode'

			# Variables are assigned correctly
			$result.Root123.Level1 | Should -BeOfType 'System.Xml.XmlLinkedNode'
			$result.Root123.Level1.Level2 | Should -BeOfType 'System.String'
			$result.Root123.Level1.Level2 | Should -Be 'Some Text'
		}
	}
	Context 'When given a XML File with utf8 encoding' {
		BeforeAll {
			@'
<Root123>
	<Level1>
		<Level2>Some Text</Level2>
	</Level1>
</Root123>
'@ | Out-File -FilePath $PSScriptRoot\test.xml -Encoding utf8
		}
		AfterAll {
			if (Test-Path -Path $PSScriptRoot\test.xml) {
				Remove-Item -Path $PSScriptRoot\test.xml -Force
			}
		}
		It 'Should return the XML file contents as xml objects' {
			$result = Import-NxtXmlFile -Path $PSScriptRoot\test.xml
			# Return value is a hashtable
			$result.GetEnumerator().Name | Should -Contain 'Root123'
			$result.Root123 | Should -BeOfType 'System.Xml.XmlLinkedNode'

			# Variables are assigned correctly
			$result.Root123.Level1 | Should -BeOfType 'System.Xml.XmlLinkedNode'
			$result.Root123.Level1.Level2 | Should -BeOfType 'System.String'
			$result.Root123.Level1.Level2 | Should -Be 'Some Text'
		}
	}
	Context 'When given a XML File with utf32 encoding' {
		BeforeAll {
			@'
<Root123>
	<Level1>
		<Level2>Some Text</Level2>
	</Level1>
</Root123>
'@ | Out-File -FilePath $PSScriptRoot\test.xml -Encoding utf32
		}
		AfterAll {
			if (Test-Path -Path $PSScriptRoot\test.xml) {
				Remove-Item -Path $PSScriptRoot\test.xml -Force
			}
		}
		It 'Should return the XML file contents as xml objects' {
			$result = Import-NxtXmlFile -Path $PSScriptRoot\test.xml
			# Return value is a hashtable
			$result.GetEnumerator().Name | Should -Contain 'Root123'
			$result.Root123 | Should -BeOfType 'System.Xml.XmlLinkedNode'

			# Variables are assigned correctly
			$result.Root123.Level1 | Should -BeOfType 'System.Xml.XmlLinkedNode'
			$result.Root123.Level1.Level2 | Should -BeOfType 'System.String'
			$result.Root123.Level1.Level2 | Should -Be 'Some Text'
		}
	}
	Context 'When given a XML File with unicode encoding' {
		BeforeAll {
			@'
<Root123>
	<Level1>
		<Level2>Some Text</Level2>
	</Level1>
</Root123>
'@ | Out-File -FilePath $PSScriptRoot\test.xml -Encoding unicode
		}
		AfterAll {
			if (Test-Path -Path $PSScriptRoot\test.xml) {
				Remove-Item -Path $PSScriptRoot\test.xml -Force
			}
		}
		It 'Should return the XML file contents as xml objects' {
			$result = Import-NxtXmlFile -Path $PSScriptRoot\test.xml
			# Return value is a hashtable
			$result.GetEnumerator().Name | Should -Contain 'Root123'
			$result.Root123 | Should -BeOfType 'System.Xml.XmlLinkedNode'

			# Variables are assigned correctly
			$result.Root123.Level1 | Should -BeOfType 'System.Xml.XmlLinkedNode'
			$result.Root123.Level1.Level2 | Should -BeOfType 'System.String'
			$result.Root123.Level1.Level2 | Should -Be 'Some Text'
		}
	}
	Context 'When given a XML File with Default encoding' {
		BeforeAll {
			@'
<Root123>
	<Level1>
		<Level2>Some Text</Level2>
	</Level1>
</Root123>
'@ | Out-File -FilePath $PSScriptRoot\test.xml -Encoding Default
		}
		AfterAll {
			if (Test-Path -Path $PSScriptRoot\test.xml) {
				Remove-Item -Path $PSScriptRoot\test.xml -Force
			}
		}
		It 'Should return the XML file contents as xml objects' {
			$result = Import-NxtXmlFile -Path $PSScriptRoot\test.xml
			# Return value is a hashtable
			$result.GetEnumerator().Name | Should -Contain 'Root123'
			$result.Root123 | Should -BeOfType 'System.Xml.XmlLinkedNode'

			# Variables are assigned correctly
			$result.Root123.Level1 | Should -BeOfType 'System.Xml.XmlLinkedNode'
			$result.Root123.Level1.Level2 | Should -BeOfType 'System.String'
			$result.Root123.Level1.Level2 | Should -Be 'Some Text'
		}
	}
	Context 'When given a XML File with ASCII encoding' {
		BeforeAll {
			@'
<Root123>
	<Level1>
		<Level2>Some Text</Level2>
	</Level1>
</Root123>
'@ | Out-File -FilePath $PSScriptRoot\test.xml -Encoding ASCII
		}
		AfterAll {
			if (Test-Path -Path $PSScriptRoot\test.xml) {
				Remove-Item -Path $PSScriptRoot\test.xml -Force
			}
		}
		It 'Should return the XML file contents as xml objects' {
			$result = Import-NxtXmlFile -Path $PSScriptRoot\test.xml
			# Return value is a hashtable
			$result.GetEnumerator().Name | Should -Contain 'Root123'
			$result.Root123 | Should -BeOfType 'System.Xml.XmlLinkedNode'

			# Variables are assigned correctly
			$result.Root123.Level1 | Should -BeOfType 'System.Xml.XmlLinkedNode'
			$result.Root123.Level1.Level2 | Should -BeOfType 'System.String'
			$result.Root123.Level1.Level2 | Should -Be 'Some Text'
		}
	}
	Context 'When given a XML File with BigEndianUnicode encoding' {
		BeforeAll {
			@'
<Root123>
	<Level1>
		<Level2>Some Text</Level2>
	</Level1>
</Root123>
'@ | Out-File -FilePath $PSScriptRoot\test.xml -Encoding BigEndianUnicode
		}
		AfterAll {
			if (Test-Path -Path $PSScriptRoot\test.xml) {
				Remove-Item -Path $PSScriptRoot\test.xml -Force
			}
		}
		It 'Should return the XML file contents as xml objects' {
			$result = Import-NxtXmlFile -Path $PSScriptRoot\test.xml
			# Return value is a hashtable
			$result.GetEnumerator().Name | Should -Contain 'Root123'
			$result.Root123 | Should -BeOfType 'System.Xml.XmlLinkedNode'

			# Variables are assigned correctly
			$result.Root123.Level1 | Should -BeOfType 'System.Xml.XmlLinkedNode'
			$result.Root123.Level1.Level2 | Should -BeOfType 'System.String'
			$result.Root123.Level1.Level2 | Should -Be 'Some Text'
		}
	}
}
