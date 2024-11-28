Describe 'Write-NxtXmlNode' {
    Context 'When the function is called' {
        BeforeAll {
            $xml = "$PSScriptRoot\test.xml"
            [PSADTNXT.XmlNodeModel]$newNode = New-Object PSADTNXT.XmlNodeModel
            $newNode.name = 'product'
            $newNode.AddAttribute('description', 'NewNode[from Test]')
            $newNode.Child = New-Object PSADTNXT.XmlNodeModel
            $newNode.Child.name = 'prop'
            $newNode.Child.AddAttribute('oor:name', 'ooSetupFactoryDefaultFilter')
            $newNode.Child.AddAttribute('oor:op', 'fuse')
            $newNode.Child.Child = New-Object PSADTNXT.XmlNodeModel
            $newNode.Child.Child.name = 'value'
            $newNode.Child.Child.value = 'Impress MS PowerPoint 2007 XML'
        }
        BeforeEach {
            @"
<?xml version="1.0"?>
<catalog>
    <product description="Cardigan Sweater" product_image="cardigan.jpg">
        <catalog_item gender="Men's">
            <item_number>QWZ5671</item_number>
            <price>39.95</price>
            <size description="Medium">
                <color_swatch image="burgundy_cardigan.jpg">Burgundy</color_swatch>
            </size>
            <size description="Large">
                <color_swatch image="red_cardigan.jpg">Red</color_swatch>
                <color_swatch image="burgundy_cardigan.jpg">Burgundy</color_swatch>
            </size>
        </catalog_item>
        <catalog_item gender="Women's">
            <item_number>RRX9856</item_number>
            <price>42.50</price>
            <size description="Small">
                <color_swatch image="navy_cardigan.jpg">Navy</color_swatch>
                <color_swatch image="burgundy_cardigan.jpg">Burgundy</color_swatch>
            </size>
            <size description="Medium">
                <color_swatch image="navy_cardigan.jpg">Navy</color_swatch>
                <color_swatch image="burgundy_cardigan.jpg">Burgundy</color_swatch>
                <color_swatch image="black_cardigan.jpg">Black</color_swatch>
            </size>
        </catalog_item>
    </product>
</catalog>
"@ | Out-File -FilePath $xml -Encoding UTF8
        }
        AfterEach {
            if (Test-Path -Path $xml) {
                Remove-Item -Path $xml -Force
            }
        }
        It 'Should add the new node to the xml' {
            Write-NxtXmlNode -XmlFilePath $xml -Model $newNode | Should -BeNullOrEmpty
            [xml]$xmlContent = Get-Content -Path $xml -Raw
            $xmlContent.catalog.product.description | Should -Contain 'NewNode[from Test]'
        }
        It 'Should not overwrite other content in list' {
            Write-NxtXmlNode -XmlFilePath $xml -Model $newNode | Should -BeNullOrEmpty
            [xml]$xmlContent = Get-Content -Path $xml -Raw

            $xmlContent.catalog.product.description.GetType().BaseType.Name | Should -Be 'Array'
            $xmlContent.catalog.product.description.Length | Should -Be 2

            $oldNode = $xmlContent.catalog.product | Where-Object { $_.description -eq 'Cardigan Sweater' } | Select-Object -First 1
            $newNode = $xmlContent.catalog.product | Where-Object { $_.description -eq 'NewNode[from Test]' } | Select-Object -First 1
            $newNode.prop | Should -Not -BeNullOrEmpty
            $oldNode.prop | Should -BeNullOrEmpty
            $oldNode.catalog_item | Should -Not -BeNullOrEmpty
        }
        It 'Should fail when file does not exist' {
            Write-NxtXmlNode -XmlFilePath "$PSScriptRoot\invalid.xml" -Model $newNode | Should -BeNullOrEmpty
            Test-Path "$PSScriptRoot\invalid.xml" | Should -Be $false
        }
        It 'Should fail when model is of wrong type' {
            { Write-NxtXmlNode -XmlFilePath $xml -Model [PSCustomObject]@{Name = 'product'} } | Should -Throw
        }
    }
}
