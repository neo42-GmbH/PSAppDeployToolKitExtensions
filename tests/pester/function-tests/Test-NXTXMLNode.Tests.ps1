BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Test-NXTXMLNode' {
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
		$xml.LoadXml($xmlContent)
		$xml.Save($filePath)
		[System.IO.FileInfo]$file = Get-Item $filePath

		# Valid file 2
		[System.String]$filePath2 = [System.IO.Path]::GetTempFileName()
		[System.String]$xmlContent2 = '<?xml version="1.0" encoding="UTF-8"?>
			<root>
				<parent_single>
					<child property="pvalue">Value</child>
				</parent_single>
			</root>'
		[System.Xml.XmlDocument]$xml2 = [System.Xml.XmlDocument]::new()
		$xml2.LoadXml($xmlContent2)
		$xml2.Save($filePath2)
		[System.IO.FileInfo]$file2 = Get-Item $filePath2

		# Invalid file
		[System.String]$filePathInvalid = [System.IO.Path]::GetTempFileName()
		[System.String]$xmlContentInvalid = '<?xml version="1.0" encoding="UTF-8"?>
			<root>
				<invalidNoClosingTag>
			</root>'
		Set-Content -Path $filePathInvalid -Value $xmlContentInvalid -Encoding UTF8
		[System.IO.FileInfo]$fileInvalid = Get-Item $filePathInvalid

		# Valid file 1 as hidden file
		[System.String]$filePathHidden = ([System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName()))
		[System.IO.FileInfo]$fileHidden = Copy-Item -Path $filePath -Destination $filePathHidden -Force -PassThru
		$fileHidden.Attributes = 'Hidden'

		# Non-existing file
		[System.String]$filePathNotExisting = ([System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName()))

		# XPath
		[System.String]$xpathValid = '/root/parent_multiple/child[@property="pvalue"]'
		[System.String]$xpathValid2 = '/root/parent_single/child[@property="pvalue"]'
		[System.String]$xpathInvalid = '/root/parent_missing/child'
	}

	AfterAll {
		Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue
		Remove-Item -Path $filePath2 -Force -ErrorAction SilentlyContinue
		Remove-Item -Path $filePathHidden -Force -ErrorAction SilentlyContinue
		Remove-Item -Path $filePathInvalid -Force -ErrorAction SilentlyContinue
	}

	Context 'When using an invalid path (one or multiple paths)' {
		It 'Should throw an error with a non-existing path' {
			{ Test-NXTXmlNode -Path $filePathNotExisting, $filePath2 -XPath $xpathValid } | Should -Throw
			{ Test-NXTXmlNode -Path $filePathNotExisting -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with null or empty path' {
			{ Test-NXTXmlNode -Path $null, $filePath2 -XPath $xpathValid } | Should -Throw
			{ Test-NXTXmlNode -Path $null -XPath $xpathValid } | Should -Throw
			{ Test-NXTXmlNode -Path '', $filePath2 -XPath $xpathValid } | Should -Throw
			{ Test-NXTXmlNode -Path '' -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with a wrong data type for path' {
			{ Test-NXTXmlNode -Path 123, $filePath2 -XPath $xpathValid } | Should -Throw
			{ Test-NXTXmlNode -Path 123 -XPath $xpathValid } | Should -Throw
		}
	}

	Context 'When using an invalid encoding' {
		It 'Should throw an error with a non-existing encoding' {
			{ Test-NXTXmlNode -Path $filePath -Encoding 'InvalidEncoding' -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with null or empty encoding' {
			{ Test-NXTXmlNode -Path $filePath -Encoding $null -XPath $xpathValid } | Should -Throw
			{ Test-NXTXmlNode -Path $filePath -Encoding '' -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with a wrong data type for encoding' {
			{ Test-NXTXmlNode -Path $filePath -Encoding 123 -XPath $xpathValid } | Should -Throw
		}
	}

	Context 'When using an invalid input object' {
		It 'Should throw an error with null or empty input object' {
			{ Test-NXTXmlNode -InputObject $null -XPath $xpathValid } | Should -Throw
			{ Test-NXTXmlNode -InputObject '' -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with a wrong data type for input object' {
			{ Test-NXTXmlNode -InputObject 123 -XPath $xpathValid } | Should -Throw
		}
	}

	Context 'When using an invalid xpath' {
		It 'Should be false with a non-existing xpath' {
			$result = Test-NXTXmlNode -Path $filePath -XPath $xpathInvalid
			$result | Should -BeFalse
		}

		It 'Should throw an error with null or empty xpath' {
			{ Test-NXTXmlNode -Path $filePath -XPath $null } | Should -Throw
			{ Test-NXTXmlNode -Path $filePath -XPath '' } | Should -Throw
		}

		It 'Should throw an error with a wrong data type for xpath' {
			{ Test-NXTXmlNode -Path $filePath -XPath 123 } | Should -Throw
		}
	}

	Context 'When using a valid path' {
		It 'Should be true for an existing node' {
			$result = Test-NXTXmlNode -Path $filePath -XPath $xpathValid
			$result | Should -BeTrue
		}

		It 'Should be true for an existing node using alias PSPath' {
			$result = Test-NXTXmlNode -PSPath $filePath -XPath $xpathValid
			$result | Should -BeTrue
		}

		It 'Should be true for an existing node using alias LiteralPath' {
			$result = Test-NXTXmlNode -LiteralPath $filePath -XPath $xpathValid
			$result | Should -BeTrue
		}

		It 'Should be false for a non-existing node' {
			$result = Test-NXTXmlNode -Path $filePath -XPath $xpathInvalid
			$result | Should -BeFalse
		}

		It 'Should be true for an existing node in a hidden file with -Force' {
			$result = Test-NXTXmlNode -Path $filePathHidden -XPath $xpathValid -Force
			$result | Should -BeTrue
		}

		It 'Should throw an error for an existing node in a hidden file without -Force' {
			{ Test-NXTXmlNode -Path $filePathHidden -XPath $xpathValid } | Should -Throw
		}

		It 'Should be true for an existing node using multiple paths' {
			$result = Test-NXTXmlNode -Path $filePath, $filePath2 -XPath $xpathValid2
			$result | Should -BeTrue
		}

		It 'Should be false for a non-existing node using multiple paths' {
			$result = Test-NXTXmlNode -Path $filePath, $filePath2 -XPath $xpathValid
			$result | Should -BeFalse
		}
	}

	Context 'When using an xml node as input object' {
		It 'Should be true for an existing node' {
			$result = Test-NXTXmlNode -InputObject $xml -XPath $xpathValid
			$result | Should -BeTrue
		}
	}

	Context 'When using pipeline input' {
		It 'Should throw an error with a non-existing path' {
			{ $filePathNotExisting | Test-NXTXmlNode -XPath $xpathValid } | Should -Throw
		}

		It 'Should be true for an existing node using an xml node object' {
			$result = $xml | Test-NXTXmlNode -XPath $xpathValid
			$result | Should -BeTrue
		}

		It 'Should be false for an non-existing node using an xml node object' {
			$result = $xml | Test-NXTXmlNode -XPath $xpathInvalid
			$result | Should -BeFalse
		}

		It 'Should be true for an existing node using an xml file object' {
			$result = $file | Test-NXTXmlNode -XPath $xpathValid
			$result | Should -BeTrue
		}

		It 'Should be false for an non-existing node using an xml file object' {
			$result = $file | Test-NXTXmlNode -XPath $xpathInvalid
			$result | Should -BeFalse
		}

		It 'Should throw an error using null or empty input object' {
			{ $null | Test-NXTXmlNode -XPath $xpathValid } | Should -Throw
			{ '' | Test-NXTXmlNode -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error using an invalid input object' {
			{ $123 | Test-NXTXmlNode -XPath $xpathValid } | Should -Throw
		}
	}
}
