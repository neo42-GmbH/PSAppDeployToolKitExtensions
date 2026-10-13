BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Set-NXTXmlNode' {
	BeforeAll {
		# Valid file 1
		[System.String]$filePath = [System.IO.Path]::GetTempFileName()
		[System.String]$xmlContent = '<?xml version="1.0" encoding="UTF-8"?>
			<root>
				<parent_single>
					<child property="pvalue">Value</child>
				</parent_single>
				<parent_multiple>
					<child property="pvalue">AnotherValue</child>
					<child>YetAnotherValue</child>
				</parent_multiple>
			</root>'
		[System.Xml.XmlDocument]$xml = [System.Xml.XmlDocument]::new()
		function New-FileValid {
			$xml.LoadXml($xmlContent)
			$xml.Save($filePath)
			[System.IO.FileInfo]$script:file = Get-Item $filePath
		}

		# Valid file 2
		[System.String]$filePath2 = [System.IO.Path]::GetTempFileName()
		[System.String]$xmlContent2 = '<?xml version="1.0" encoding="UTF-8"?>
			<root>
				<parent_single>
					<child property="pvalue">Value</child>
				</parent_single>
			</root>'
		[System.Xml.XmlDocument]$xml2 = [System.Xml.XmlDocument]::new()
		function New-FileValid2 {
			$xml2.LoadXml($xmlContent2)
			$xml2.Save($filePath2)
			[System.IO.FileInfo]$script:file2 = Get-Item $filePath2
		}

		# Invalid file
		[System.String]$filePathInvalid = [System.IO.Path]::GetTempFileName()
		[System.String]$xmlContentInvalid = '<?xml version="1.0" encoding="UTF-8"?>
			<root>
				<invalidNoClosingTag>
			</root>'
		function New-FileInvalid {
			Set-Content -Path $filePathInvalid -Value $xmlContentInvalid -Encoding UTF8
			[System.IO.FileInfo]$script:fileInvalid = Get-Item $filePathInvalid
		}

		# Valid file 1 as hidden file
		[System.String]$filePathHidden = ([System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName()))
		function New-FileHidden {
			New-FileValid
			[System.IO.FileInfo]$script:fileHidden = Copy-Item -Path $filePath -Destination $filePathHidden -Force -PassThru
			$script:fileHidden.Attributes = 'Hidden'
		}

		# Non-existing file
		[System.String]$filePathNotExisting = ([System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName()))

		# XPath
		[System.String]$xpathValid = '/root/parent_multiple/child[@property="pvalue"]'
		[System.String]$xpathValid2 = '/root/parent_single/child[@property="pvalue"]'
		[System.String]$xpathInvalid = '/root/parent_missing/child'
		[System.String]$nodeXpathValid = './child'

		# Nodes
		function Init-Nodes {
			New-FileValid
			[System.Xml.XmlNode[]]$script:nodes = $xml.SelectNodes("/root/*[contains(local-name(), 'parent')]")
			[System.Xml.XmlNode]$script:node = $xml.SelectSingleNode('/root/parent_single')
		}
	}

	AfterAll {
		Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue
		Remove-Item -Path $filePath2 -Force -ErrorAction SilentlyContinue
		Remove-Item -Path $filePathHidden -Force -ErrorAction SilentlyContinue
		Remove-Item -Path $filePathInvalid -Force -ErrorAction SilentlyContinue
	}

	Context 'When using an invalid path (one or multiple paths)' {
		It 'Should throw an error with a non-existing path' {
			New-FileValid2
			{ Set-NXTXmlNode -Path $filePathNotExisting, $filePath2 -XPath $xpathValid } | Should -Throw
			{ Set-NXTXmlNode -Path $filePathNotExisting -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with null or empty path' {
			New-FileValid2
			{ Set-NXTXmlNode -Path $null, $filePath2 -XPath $xpathValid } | Should -Throw
			{ Set-NXTXmlNode -Path $null -XPath $xpathValid } | Should -Throw
			New-FileValid2
			{ Set-NXTXmlNode -Path '', $filePath2 -XPath $xpathValid } | Should -Throw
			{ Set-NXTXmlNode -Path '' -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with a wrong data type for path' {
			New-FileValid2
			{ Set-NXTXmlNode -Path 123, $filePath2 -XPath $xpathValid } | Should -Throw
			{ Set-NXTXmlNode -Path 123 -XPath $xpathValid } | Should -Throw
		}
	}

	Context 'When using an invalid literal path (one or multiple paths)' {
		It 'Should throw an error with a literal path including wildcards' {
			New-FileValid
			New-FileValid2
			{ Set-NXTXmlNode LiteralPath "$filePath*", $filePath2 -XPath $xpathValid } | Should -Throw
			New-FileValid
			{ Set-NXTXmlNode LiteralPath "$filePath*" -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with a non-existing path' {
			New-FileValid2
			{ Set-NXTXmlNode LiteralPath $filePathNotExisting, $filePath2 -XPath $xpathValid } | Should -Throw
			{ Set-NXTXmlNode LiteralPath $filePathNotExisting -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with null or empty path' {
			New-FileValid2
			{ Set-NXTXmlNode LiteralPath $null, $filePath2 -XPath $xpathValid } | Should -Throw
			{ Set-NXTXmlNode LiteralPath $null -XPath $xpathValid } | Should -Throw
			New-FileValid2
			{ Set-NXTXmlNode LiteralPath '', $filePath2 -XPath $xpathValid } | Should -Throw
			{ Set-NXTXmlNode LiteralPath '' -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with a wrong data type for path' {
			New-FileValid2
			{ Set-NXTXmlNode LiteralPath 123, $filePath2 -XPath $xpathValid } | Should -Throw
			{ Set-NXTXmlNode LiteralPath 123 -XPath $xpathValid } | Should -Throw
		}
	}

	Context 'When using filter' {
		It 'Should be $null with an ineffective filter' {
			New-FileValid
			New-FileValid2
			$result = Set-NXTXmlNode -Path $filePath, $filePath2 -Filter 'IneffectiveFilter' -XPath $xpathValid -PassThru
			$result | Should -BeNullOrEmpty
			New-FileValid
			$result = Set-NXTXmlNode -Path $filePath -Filter 'IneffectiveFilter' -XPath $xpathValid -PassThru
			$result | Should -BeNullOrEmpty
		}

		It 'Should be [System.Xml.XmlDocument] with multiple paths and with null or empty filter' {
			New-FileValid
			New-FileValid2
			$result = Set-NXTXmlNode -Path $filePath, $filePath2 -Filter $null -XPath $xpathValid -PassThru
			$result | Should -BeOfType '[System.Xml.XmlDocument]'
			New-FileValid
			New-FileValid2
			$result = Set-NXTXmlNode -Path $filePath, $filePath2 -Filter '' -XPath $xpathValid -PassThru
			$result | Should -BeOfType '[System.Xml.XmlDocument]'
		}

		It 'Should be [System.Xml.XmlNode] with multiple paths and with null or empty filter' {
			New-FileValid
			$result = Set-NXTXmlNode -Path $filePath -Filter $null -XPath $xpathValid -PassThru
			$result | Should -BeOfType '[System.Xml.XmlNode]'
			New-FileValid
			$result = Set-NXTXmlNode -Path $filePath -Filter '' -XPath $xpathValid -PassThru
			$result | Should -BeOfType '[System.Xml.XmlNode]'
		}
	}

	Context 'When using exclude (one or multiple definitions)' {
		It 'Should be [System.Xml.XmlDocument] with multiple paths and with an ineffective exclude value' {
			New-FileValid
			New-FileValid2
			$result = Set-NXTXmlNode -Path $filePath, $filePath2 -Exclude 'IneffectiveExclude' -XPath $xpathValid -PassThru
			$result | Should -BeOfType '[System.Xml.XmlDocument]'
		}

		It 'Should be [System.Xml.XmlNode] with one path and with an ineffective exclude value' {
			New-FileValid
			$result = Set-NXTXmlNode -Path $filePath -Exclude 'IneffectiveExclude' -XPath $xpathValid -PassThru
			$result | Should -BeOfType '[System.Xml.XmlNode]'
		}

		It 'Should be [System.Xml.XmlDocument] with multiple paths with null or empty exclude value' {
			New-FileValid
			New-FileValid2
			$result = Set-NXTXmlNode -Path $filePath, $filePath2 -Exclude $null -XPath $xpathValid -PassThru
			$result | Should -BeOfType '[System.Xml.XmlDocument]'
			New-FileValid
			New-FileValid2
			$result = Set-NXTXmlNode -Path $filePath, $filePath2 -Exclude '' -XPath $xpathValid -PassThru
			$result | Should -BeOfType '[System.Xml.XmlDocument]'
		}

		It 'Should be [System.Xml.XmlNode] with one path and with null or empty exclude value' {
			New-FileValid
			$result = Set-NXTXmlNode -Path $filePath -Exclude $null -XPath $xpathValid -PassThru
			$result | Should -BeOfType '[System.Xml.XmlNode]'
			New-FileValid
			$result = Set-NXTXmlNode -Path $filePath -Exclude '' -XPath $xpathValid -PassThru
			$result | Should -BeOfType '[System.Xml.XmlNode]'
		}
	}

	Context 'When using include (one or multiple definitions)' {
		It 'Should be null with an ineffective include value' {
			New-FileValid
			New-FileValid2
			$result = Set-NXTXmlNode -Path $filePath, $filePath2 -Include 'IneffectiveInclude' -XPath $xpathValid -PassThru
			$result | Should -BeNullOrEmpty
			New-FileValid
			$result = Set-NXTXmlNode -Path $filePath -Include 'IneffectiveInclude' -XPath $xpathValid -PassThru
			$result | Should -BeNullOrEmpty
		}

		It 'Should be [System.Xml.XmlDocument] with multiple paths and with null or empty include value' {
			New-FileValid
			New-FileValid2
			$result = Set-NXTXmlNode -Path $filePath, $filePath2 -Include $null -XPath $xpathValid -PassThru
			$result | Should -BeOfType '[System.Xml.XmlDocument]'
			New-FileValid
			New-FileValid2
			$result = Set-NXTXmlNode -Path $filePath, $filePath2 -Include '' -XPath $xpathValid -PassThru
			$result | Should -BeOfType '[System.Xml.XmlDocument]'
		}

		It 'Should be [System.Xml.XmlNode] with one path and with null or empty include value' {
			New-FileValid
			$result = Set-NXTXmlNode -Path $filePath -Include $null -XPath $xpathValid -PassThru
			$result | Should -BeOfType '[System.Xml.XmlNode]'
			New-FileValid
			$result = Set-NXTXmlNode -Path $filePath -Include '' -XPath $xpathValid -PassThru
			$result | Should -BeOfType '[System.Xml.XmlNode]'
		}
	}

	Context 'When using an invalid encoding' {
		It 'Should throw an exception with a non-existing encoding' {
			New-FileValid
			New-FileValid2
			{ Set-NXTXmlNode -Path $filePath, $filePath2 -Encoding 'InvalidEncoding' -XPath $xpathValid } | Should -Throw
			New-FileValid
			{ Set-NXTXmlNode -Path $filePath -Encoding 'InvalidEncoding' -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an exception with null or empty encoding' {
			New-FileValid
			New-FileValid2
			{ Set-NXTXmlNode -Path $filePath, $filePath2 -Encoding $null -XPath $xpathValid } | Should -Throw
			New-FileValid
			{ Set-NXTXmlNode -Path $filePath -Encoding $null -XPath $xpathValid } | Should -Throw
			New-FileValid
			New-FileValid2
			{ Set-NXTXmlNode -Path $filePath, $filePath2 -Encoding '' -XPath $xpathValid } | Should -Throw
			New-FileValid
			{ Set-NXTXmlNode -Path $filePath -Encoding '' -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an exception with a wrong data type for encoding' {
			New-FileValid
			New-FileValid2
			{ Set-NXTXmlNode -Path $filePath, $filePath2 -Encoding 123 -XPath $xpathValid } | Should -Throw
			New-FileValid
			{ Set-NXTXmlNode -Path $filePath -Encoding 123 -XPath $xpathValid } | Should -Throw
		}
	}

	Context 'When using an invalid xpath' {
		It 'Should throw an exception with a non-existing xpath' {
			New-FileValid
			New-FileValid2
			$result = Set-NXTXmlNode -Path $filePath, $filePath2 -XPath $xpathInvalid -PassThru
			$result | Should -BeNullOrEmpty
			New-FileValid
			$result = Set-NXTXmlNode -Path $filePath -XPath $xpathInvalid -PassThru
			$result | Should -BeNullOrEmpty
		}

		It 'Should throw an exception with multiple paths and with null or empty xpath' {
			New-FileValid
			New-FileValid2
			{ Set-NXTXmlNode -Path $filePath, $filePath2 -XPath $null } | Should -Throw
			New-FileValid
			New-FileValid2
			{ Set-NXTXmlNode -Path $filePath, $filePath2 -XPath '' } | Should -Throw
		}

		It 'Should throw an exception with one path and with null or empty xpath' {
			New-FileValid
			{ Set-NXTXmlNode -Path $filePath -XPath $null } | Should -Throw
			New-FileValid
			{ Set-NXTXmlNode -Path $filePath -XPath '' } | Should -Throw
		}
	}

	Context 'When using an input object' {
		It 'Should throw an exception with null or empty path' {
			{ Set-NXTXmlNode InputObject $null -XPath $xpathValid } | Should -Throw
			{ Set-NXTXmlNode InputObject '' -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with a wrong data type for path' {
			{ Set-NXTXmlNode InputObject 123 -XPath $xpathValid } | Should -Throw
		}
	}

	Context 'When using invalid pipeline input' {
		It 'Should throw an exception with null or empty pipeline input' {
			{ $null | Set-NXTXmlNode -XPath $xpathValid } | Should -Throw
			{ '' | Set-NXTXmlNode -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an exception with wrong data type for pipeline input' {
			{ 123 | Set-NXTXmlNode -XPath $xpathValid } | Should -Throw
		}
	}

	Context 'When using valid input' {
		It 'Should be [System.Xml.XmlDocument] with multiple paths' {
			New-FileValid
			New-FileValid2
			$result = Set-NXTXmlNode -Path $filePath, $filePath2 -XPath $xpathValid -InnerText 'Test Value' -PassThru
			$result | Should -BeOfType '[System.Xml.XmlDocument]'
			$result.SelectSingleNode('.//parent_multiple/child').InnerText | Should -Be 'Test Value'
		}

		It 'Should be [System.Xml.XmlNode] with multiple paths and -Single switch' {
			New-FileValid
			New-FileValid2
			$result = Set-NXTXmlNode -LiteralPath $filePath, $filePath2 -XPath $xpathValid -Single -Attributes @{'property' = 'testvalue' } -Passthru
			$result | Should -BeOfType '[System.Xml.XmlNode]'
			$result.SelectSingleNode('.//parent_multiple/child[@property="testvalue"]') | Should -Not -BeNullOrEmpty
		}

		It 'Should be [System.Xml.XmlNode] with one path to a hidden file and -Force switch' {
			New-FileHidden
			$result = Set-NXTXmlNode -LiteralPath $filePathHidden -XPath $xpathValid -InnerText 'Test Value' -Force -Passthru
			$result | Should -BeOfType '[System.Xml.XmlNode]'
			$result.SelectSingleNode('.//parent_multiple/child[@property="pvalue"]').InnerText | Should -Be 'Test Value'
		}

		It 'Should throw an exception with one path to a hidden file without -Force switch' {
			New-FileHidden
			{ Set-NXTXmlNode -LiteralPath $filePathHidden -XPath $xpathValid -Passthru } | Should -Throw
		}

		It 'Should be [System.Xml.XmlNode] with input objects as [System.Xml.XmlNode]' {
			Init-Nodes
			$result = Set-NXTXmlNode -InputObject $node -XPath $nodeXpathValid -InnerText 'Test Value' -Passthru
			$result | Should -BeOfType '[System.Xml.XmlNode]'
			$result.SelectSingleNode('.//child[@property="pvalue"]').InnerText | Should -Be 'Test Value'
		}

		It 'Should be [System.Object[]] with input objects as [System.Xml.XmlNode[]]' {
			Init-Nodes
			$result = Set-NXTXmlNode -InputObject $nodes -XPath $nodeXpathValid -InnerText 'Test Value' -Attributes @{'property' = 'testvalue' } -PassThru
			Should -BeOfType '[System.Object[]]' -ActualValue $result
			Should -HaveCount 2 -ActualValue $result
			$result | ForEach-Object { $_ | Should -BeOfType '[System.Xml.XmlNode]' }
			$result | ForEach-Object { $_.SelectSingleNode('.//child[@property="testvalue"][text() = "Test Value"]') | Should -Not -BeNullOrEmpty }
		}
	}
}
