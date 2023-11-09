Describe 'Set-NxtXmlNode' {
    Context 'When given valid input' {
        BeforeAll {
            $xml = "$PSScriptRoot\test.xml"
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
        It 'Should update the node' {
            Set-NxtXmlNode -FilePath $xml -NodePath '/catalog' -InnerText 'Test' -Attributes @{'metadata'='test'} | Should -BeNullOrEmpty
            $xmlDoc = [xml](Get-Content -Path $xml -Raw)
            $xmlDoc.catalog.InnerText | Should -Be "test"
            $xmlDoc.catalog.Attributes.GetEnumerator().Name | Should -Contain 'metadata'
            Write-Host $xmlDoc.catalog
            $xmlDoc.catalog.metadata | Should -Be "test"
        }
        It 'Should only update the filtered nodes' {
            Set-NxtXmlNode -FilePath $xml -NodePath '/catalog/product/catalog_item' -InnerText 'Test' -FilterAttributes @{"gender" = "Women's"} | Should -BeNullOrEmpty
            $xmlDoc = [xml](Get-Content -Path $xml -Raw)
            ($xmlDoc.catalog.product.catalog_item | Where-Object { $_.gender -eq "Men's" }).InnerText | Should -Not -Be "Test"
            ($xmlDoc.catalog.product.catalog_item | Where-Object { $_.gender -eq "Women's" }).InnerText | Should -Be "Test"
        }
        It 'Should create the node if node does not exist' -Skip {
            Set-NxtXmlNode -FilePath $xml -NodePath '/new' -InnerText 'Test' | Should -BeNullOrEmpty
            $xmlDoc = [xml](Get-Content -Path $xml -Raw)
            $xmlDoc.GetEnumerator().Name | Should -Contain 'new'
            $xmlDoc.GetEnumerator().Name | Should -Contain 'product'
        }
    }
}
