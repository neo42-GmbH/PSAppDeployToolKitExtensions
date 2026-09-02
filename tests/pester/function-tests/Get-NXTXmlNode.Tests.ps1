BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Get-NXTXmlNode' {
	Context 'When accessing a xml document' {
		BeforeAll {
			$xml = [System.Xml.XmlDocument]'<root>
						<single>
							<child property="pvalue">Value</child>
						</single>
						<multiple>
							<child>AnotherValue</child>
							<child>YetAnotherValue</child>
						</multiple>
					</root>'


			$file = [System.IO.Path]::GetTempFileName()
			$xml.Save($file)
		}

		AfterAll {
			Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
		}

		It 'Should return the correct node from xml node' {
			$node = Get-NXTXmlNode -InputObject $xml -XPath '/root/single/child'
			$node | Should -BeOfType [System.Xml.XmlNode]
			$node | Should -Not -BeNullOrEmpty
			$node.InnerText | Should -Be 'Value'
		}

		It 'Should return the correct node from xml file' {
			$node = Get-NXTXmlNode -Path $file -XPath '/root/single/child'
			$node | Should -BeOfType [System.Xml.XmlNode]
			$node | Should -Not -BeNullOrEmpty
			$node.InnerText | Should -Be 'Value'
		}

		It 'Should return the desired attribute' {
			$attribute = Get-NXTXmlNode -InputObject $xml -XPath '/root/single/child' -Attribute 'property'
			$attribute | Should -BeOfType [System.String]
			$attribute | Should -Be 'pvalue'
		}

		It 'Should return innertext as attribute value' {
			$attribute = Get-NXTXmlNode -InputObject $xml -XPath '/root/single/child' -Attribute 'InnerText'
			$attribute | Should -BeOfType [System.String]
			$attribute | Should -Be 'Value'
		}

		It 'Should return multiple nodes from xml file' {
			$nodes = Get-NXTXmlNode -Path $file -XPath '/root/multiple/child'
			$nodes | Should -BeOfType [System.Xml.XmlNode]
			$nodes | Should -Not -BeNullOrEmpty
			$nodes.Count | Should -Be 2
			$nodes[0].InnerText | Should -Be 'AnotherValue'
			$nodes[1].InnerText | Should -Be 'YetAnotherValue'
		}

		It 'Should return a single node when Single switch is used' {
			$node = Get-NXTXmlNode -Path $file -XPath '/root/multiple/child' -Single
			$node | Should -BeOfType [System.Xml.XmlNode]
			$node | Should -Not -BeNullOrEmpty
			$node.InnerText | Should -Be 'AnotherValue'
		}

		It 'Should throw if XPath is not found' {
			{ Get-NXTXmlNode -Path $file -XPath '/root/single/child/notfound' } | Should -Throw
		}

		It 'Should throw if file does not exist' {
			{ Get-NXTXmlNode -Path 'C:\NonExistentFile.xml' -XPath '/root/single/child' } | Should -Throw
		}
	}
}
