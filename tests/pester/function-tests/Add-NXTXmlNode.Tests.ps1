BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Add-NXTXmlNode' {
	BeforeAll {
		# Create a temporary XML file for testing
		[System.String]$xmlFilePath = [System.IO.Path]::GetTempFileName()
		[System.String]$simpleXml = @'
<?xml version="1.0" encoding="UTF-8"?>
<root>
	<parent>
		<child attr="value">Text</child>
	</parent>
	<parent2>
		<child/>
		<child/>
	</parent2>
</root>
'@
		Set-Content -Path $xmlFilePath -Value $simpleXml -Encoding UTF8
	}

	AfterAll {
		# Clean up test files
		Remove-Item -LiteralPath $xmlFilePath -ErrorAction SilentlyContinue
	}

	Context 'When adding nodes to an XML file' {
		AfterEach {
			# Reset the test file after each test
			Set-Content -Path $xmlFilePath -Value $simpleXml -Encoding UTF8
		}

		It 'Should add a simple node to the specified XPath location' {
			Add-NXTXmlNode -Path $xmlFilePath -XPath '/root/parent' -Name 'newchild' | Should -BeNullOrEmpty
			$xml = [System.Xml.XmlDocument](Get-Content -Path $xmlFilePath)
			$xml.root.parent.newchild | Should -Not -Be $null
			$xml.root.parent.ChildNodes.Count | Should -Be 2
		}

		It 'Should add a node with attributes correctly' {
			$attributes = @{
				'attr1' = 'value1'
				'attr2' = 'value2'
			}
			Add-NXTXmlNode -Path $xmlFilePath -XPath '/root/parent' -Name 'attrchild' -Attributes $attributes | Should -BeNullOrEmpty
			$xml = [System.Xml.XmlDocument](Get-Content -Path $xmlFilePath)
			$node = $xml.SelectSingleNode('/root/parent/attrchild')
			$node | Should -Not -Be $null
			$node.GetAttribute('attr1') | Should -Be 'value1'
			$node.GetAttribute('attr2') | Should -Be 'value2'
		}

		It 'Should add a node with inner text correctly' {
			Add-NXTXmlNode -Path $xmlFilePath -XPath '/root/parent' -Name 'textchild' -InnerText 'Inner Text Value' | Should -BeNullOrEmpty
			$xml = [System.Xml.XmlDocument](Get-Content -Path $xmlFilePath)
			$xml.SelectSingleNode('/root/parent/textchild').InnerText | Should -Be 'Inner Text Value'
		}

		It 'Should add a node to every node matching the XPath' {
			Add-NXTXmlNode -Path $xmlFilePath -XPath '/root/parent2/child' -Name 'subchild' | Should -BeNullOrEmpty
			$xml = [System.Xml.XmlDocument](Get-Content -Path $xmlFilePath)
			$xml.SelectNodes('/root/parent2/child/subchild').Count | Should -Be 2
		}

		It 'Should add the child to the start of a list' {
			Add-NXTXmlNode -Path $xmlFilePath -XPath '/root/parent' -Name 'child' -Attributes @{ First = 'true' } -Prepend | Should -BeNullOrEmpty
			$xml = [System.Xml.XmlDocument](Get-Content -Path $xmlFilePath)
			$nodes = $xml.SelectNodes('/root/parent/child')
			$nodes.Count | Should -Be 2
			$nodes[0].Attributes['First'] | Should -Not -BeNullOrEmpty
		}
	}

	Context 'When working with XML objects directly' {
		It 'Should add nodes to an XML object when using InputObject' {
			$xmlDoc = [System.Xml.XmlDocument]$simpleXml
			Add-NXTXmlNode -InputObject $xmlDoc -XPath '/root/parent' -Name 'objectchild' -PassThru | Should -BeOfType [System.Xml.XmlDocument]
			$xmlDoc.SelectSingleNode('/root/parent/objectchild') | Should -Not -BeNullOrEmpty
		}

		It 'Should add nodes to a specific XML node when using InputObject' {
			$xmlDoc = [System.Xml.XmlDocument]$simpleXml
			$parentNode = $xmlDoc.SelectSingleNode('/root/parent')
			Add-NXTXmlNode -InputObject $parentNode -XPath '.' -Name 'childnode' -PassThru | Should -BeOfType [System.Xml.XmlNode]
			$xmlDoc.SelectSingleNode('/root/parent/childnode') | Should -Not -Be $null
		}
	}

	Context 'When handling errors' {
		It 'Should not throw when XPath does not exist' {
			{ Add-NXTXmlNode -Path $xmlFilePath -XPath '/root/nonexistent' -Name 'errorchild' } | Should -Not -Throw
		}

		It 'Should throw when -Single is specified but multiple nodes are found' {
			{ Add-NXTXmlNode -Path $xmlFilePath -XPath '/root/parent2' -Name 'errorchild' -Single } | Should -Not -Throw
		}

		It 'Should throw when file is read-only' {
			Set-ItemProperty -Path $xmlFilePath -Name IsReadOnly -Value $true
			{ Add-NXTXmlNode -Path $xmlFilePath -XPath '/root/parent' -Name 'readonlychild' } | Should -Throw
			Set-ItemProperty -Path $xmlFilePath -Name IsReadOnly -Value $false
		}

		It 'Should override read-only when -Force is used' {
			Set-ItemProperty -Path $xmlFilePath -Name IsReadOnly -Value $true
			Add-NXTXmlNode -Path $xmlFilePath -XPath '/root/parent' -Name 'forcechild' -Force | Should -BeNullOrEmpty
			$xml = [System.Xml.XmlDocument](Get-Content -Path $xmlFilePath)
			$xml.SelectSingleNode('/root/parent/forcechild') | Should -Not -BeNullOrEmpty
			Set-ItemProperty -Path $xmlFilePath -Name IsReadOnly -Value $false
		}
	}
}
