Describe "Read-NxtSingleXmlNode" {
    Context "When running the function" {
        BeforeAll {
            $xml = "$PSScriptRoot\test.xml"
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

        AfterAll {
            if (Test-Path -Path $xml) {
                Remove-Item -Path $xml -Force
            }
        }

        It "Should return the value of the specified node" {
            $result = Read-NxtSingleXmlNode -XmlFilePath $xml -SingleNodeName '/catalog/product[@description="Cardigan Sweater"]/catalog_item[@gender="Men''s"]/item_number'
            $result | Should -BeOfType 'System.String'
            $result | Should -Be "QWZ5671"
        }
        It "Should return the attributes of a specified node" {
            $result = Read-NxtSingleXmlNode -XmlFilePath $xml -SingleNodeName '/catalog/product[1]' -AttributeName 'product_image'
            $result | Should -BeOfType 'System.String'
            $result | Should -Be "cardigan.jpg"
        }
        It "Should error when specifing node with multiple entries but return concated string" {
            Read-NxtSingleXmlNode -XmlFilePath $xml -SingleNodeName '//catalog_item' | Should -Be 'QWZ567139.95BurgundyRedBurgundy'
        }
        It "Should return empty if node or attribute does not exist" {
            Read-NxtSingleXmlNode -XmlFilePath $xml -SingleNodeName '//invalid' | Should -BeNullOrEmpty
            Read-NxtSingleXmlNode -XmlFilePath $xml -SingleNodeName '/catalog/product[1]' -AttributeName 'invalid' | Should -BeNullOrEmpty
        }
        It "Should return empty if file does not exist" {
            Read-NxtSingleXmlNode -XmlFilePath 'C:\doesnotexist.xml' -SingleNodeName '/catalog/product' | Should -BeNullOrEmpty
        }
    }
}
