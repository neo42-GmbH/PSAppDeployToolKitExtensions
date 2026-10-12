BeforeDiscovery { . "$PSScriptRoot\..\Initialize-PesterPsadtEnvironment.ps1" }

Describe 'Remove-NXTXmlNode' {
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
			{ Remove-NXTXmlNode -Path $filePathNotExisting, $filePath2 -XPath $xpathValid } | Should -Throw
			{ Remove-NXTXmlNode -Path $filePathNotExisting -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with null or empty path' {
			New-FileValid2
			{ Remove-NXTXmlNode -Path $null, $filePath2 -XPath $xpathValid } | Should -Throw
			{ Remove-NXTXmlNode -Path $null -XPath $xpathValid } | Should -Throw
			New-FileValid2
			{ Remove-NXTXmlNode -Path '', $filePath2 -XPath $xpathValid } | Should -Throw
			{ Remove-NXTXmlNode -Path '' -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with a wrong data type for path' {
			New-FileValid2
			{ Remove-NXTXmlNode -Path 123, $filePath2 -XPath $xpathValid } | Should -Throw
			{ Remove-NXTXmlNode -Path 123 -XPath $xpathValid } | Should -Throw
		}
	}

	Context 'When using an invalid literal path (one or multiple paths)' {
		It 'Should throw an error with a literal path including wildcards' {
			New-FileValid
			New-FileValid2
			{ Remove-NXTXmlNode LiteralPath "$filePath*", $filePath2 -XPath $xpathValid } | Should -Throw
			New-FileValid
			New-FileValid2
			{ Remove-NXTXmlNode LiteralPath "$filePath*" -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with a non-existing path' {
			New-FileValid2
			{ Remove-NXTXmlNode LiteralPath $filePathNotExisting, $filePath2 -XPath $xpathValid } | Should -Throw
			{ Remove-NXTXmlNode LiteralPath $filePathNotExisting -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with null or empty path' {
			New-FileValid2
			{ Remove-NXTXmlNode LiteralPath $null, $filePath2 -XPath $xpathValid } | Should -Throw
			{ Remove-NXTXmlNode LiteralPath $null -XPath $xpathValid } | Should -Throw
			New-FileValid2
			{ Remove-NXTXmlNode LiteralPath '', $filePath2 -XPath $xpathValid } | Should -Throw
			{ Remove-NXTXmlNode LiteralPath '' -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with a wrong data type for path' {
			New-FileValid2
			{ Remove-NXTXmlNode LiteralPath 123, $filePath2 -XPath $xpathValid } | Should -Throw
			{ Remove-NXTXmlNode LiteralPath 123 -XPath $xpathValid } | Should -Throw
		}
	}

	Context 'When using filter' {
		It 'Should be $null with an ineffective filter' {
			New-FileValid
			New-FileValid2
			Remove-NXTXmlNode -Path $filePath, $filePath2 -Filter 'IneffectiveFilter' -XPath $xpathValid -PassThru | Should -BeNullOrEmpty
			New-FileValid
			Remove-NXTXmlNode -Path $filePath -Filter 'IneffectiveFilter' -XPath $xpathValid -PassThru | Should -BeNullOrEmpty
		}

		It 'Should be [System.Xml.XmlNode[]] with multiple paths and with null or empty filter' {
			New-FileValid
			New-FileValid2
			Remove-NXTXmlNode -Path $filePath, $filePath2 -Filter $null -XPath $xpathValid -PassThru | Should -BeOfType '[System.Xml.XmlNode[]]'
			New-FileValid
			New-FileValid2
			Remove-NXTXmlNode -Path $filePath, $filePath2 -Filter '' -XPath $xpathValid -PassThru | Should -BeOfType '[System.Xml.XmlNode[]]'
		}

		It 'Should be [System.Xml.XmlNode] with multiple paths and with null or empty filter' {
			New-FileValid
			Remove-NXTXmlNode -Path $filePath -Filter $null -XPath $xpathValid -PassThru | Should -BeOfType '[System.Xml.XmlNode]'
			New-FileValid
			Remove-NXTXmlNode -Path $filePath -Filter '' -XPath $xpathValid -PassThru | Should -BeOfType '[System.Xml.XmlNode]'
		}
	}

	Context 'When using exclude (one or multiple definitions)' {
		It 'Should be [System.Xml.XmlNode[]] with multiple paths and with an ineffective exclude value' {
			New-FileValid
			New-FileValid2
			Remove-NXTXmlNode -Path $filePath, $filePath2 -Exclude 'IneffectiveExclude' -XPath $xpathValid -PassThru | Should -BeOfType '[System.Xml.XmlNode[]]'
		}

		It 'Should be [System.Xml.XmlNode] with one path and with an ineffective exclude value' {
			New-FileValid
			Remove-NXTXmlNode -Path $filePath -Exclude 'IneffectiveExclude' -XPath $xpathValid -PassThru | Should -BeOfType '[System.Xml.XmlNode]'
		}

		It 'Should be [System.Xml.XmlNode[]] with multiple paths with null or empty exclude value' {
			New-FileValid
			New-FileValid2
			Remove-NXTXmlNode -Path $filePath, $filePath2 -Exclude $null -XPath $xpathValid -PassThru | Should -BeOfType '[System.Xml.XmlNode[]]'
			New-FileValid
			New-FileValid2
			Remove-NXTXmlNode -Path $filePath, $filePath2 -Exclude '' -XPath $xpathValid -PassThru | Should -BeOfType '[System.Xml.XmlNode[]]'
		}

		It 'Should be [System.Xml.XmlNode] with one path and with null or empty exclude value' {
			New-FileValid
			Remove-NXTXmlNode -Path $filePath -Exclude $null -XPath $xpathValid -PassThru | Should -BeOfType '[System.Xml.XmlNode]'
			New-FileValid
			Remove-NXTXmlNode -Path $filePath -Exclude '' -XPath $xpathValid -PassThru | Should -BeOfType '[System.Xml.XmlNode]'
		}
	}

	Context 'When using include (one or multiple definitions)' {
		It 'Should be null with an ineffective include value' {
			New-FileValid
			New-FileValid2
			Remove-NXTXmlNode -Path $filePath, $filePath2 -Include 'IneffectiveInclude' -XPath $xpathValid -PassThru | Should -BeNullOrEmpty
			New-FileValid
			Remove-NXTXmlNode -Path $filePath -Include 'IneffectiveInclude' -XPath $xpathValid -PassThru | Should -BeNullOrEmpty
		}

		It 'Should be [System.Xml.XmlNode[]] with multiple paths and with null or empty include value' {
			New-FileValid
			New-FileValid2
			Remove-NXTXmlNode -Path $filePath, $filePath2 -Include $null -XPath $xpathValid -PassThru | Should -BeOfType '[System.Xml.XmlNode[]]'
			New-FileValid
			New-FileValid2
			Remove-NXTXmlNode -Path $filePath, $filePath2 -Include '' -XPath $xpathValid -PassThru | Should -BeOfType '[System.Xml.XmlNode[]]'
		}

		It 'Should be [System.Xml.XmlNode] with one path and with null or empty include value' {
			New-FileValid
			Remove-NXTXmlNode -Path $filePath -Include $null -XPath $xpathValid -PassThru | Should -Not -BeOfType '[System.Xml.XmlNode]'
			New-FileValid
			Remove-NXTXmlNode -Path $filePath -Include '' -XPath $xpathValid -PassThru | Should -Not -BeOfType '[System.Xml.XmlNode]'
		}
	}

	Context 'When using an invalid encoding' {
		It 'Should throw an error with a non-existing encoding' {
			New-FileValid
			New-FileValid2
			{ Remove-NXTXmlNode -Path $filePath, $filePath2 -Encoding 'InvalidEncoding' -XPath $xpathValid } | Should -Throw
			New-FileValid
			{ Remove-NXTXmlNode -Path $filePath -Encoding 'InvalidEncoding' -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with null or empty encoding' {
			New-FileValid
			New-FileValid2
			{ Remove-NXTXmlNode -Path $filePath, $filePath2 -Encoding $null -XPath $xpathValid } | Should -Throw
			New-FileValid
			{ Remove-NXTXmlNode -Path $filePath -Encoding $null -XPath $xpathValid } | Should -Throw
			New-FileValid
			New-FileValid2
			{ Remove-NXTXmlNode -Path $filePath, $filePath2 -Encoding '' -XPath $xpathValid } | Should -Throw
			New-FileValid
			{ Remove-NXTXmlNode -Path $filePath -Encoding '' -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with a wrong data type for encoding' {
			New-FileValid
			New-FileValid2
			{ Remove-NXTXmlNode -Path $filePath, $filePath2 -Encoding 123 -XPath $xpathValid } | Should -Throw
			New-FileValid
			{ Remove-NXTXmlNode -Path $filePath -Encoding 123 -XPath $xpathValid } | Should -Throw
		}
	}

	Context 'When using an input object' {
		It 'Should throw an error with null or empty path' {
			{ Remove-NXTXmlNode InputObject $null -XPath $xpathValid } | Should -Throw
			{ Remove-NXTXmlNode InputObject '' -XPath $xpathValid } | Should -Throw
		}

		It 'Should throw an error with a wrong data type for path' {
			{ Remove-NXTXmlNode InputObject 123 -XPath $xpathValid } | Should -Throw
		}
	}

	Context 'When using pipeline input' {
		It 'Should be ...' {

		}
	}
}
