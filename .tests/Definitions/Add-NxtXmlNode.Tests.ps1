# Test the Add-NxtXmlNode Function

Describe "Add-NxtXmlNode" {
    Context "Add the node" {
        It "Adds the node to Root" {
            $xml = @"
<Root>
</Root>
"@
            $filePath = "$PSScriptRoot\example1.xml"
            $nodePath = "/Root/Child"
            $Attributes = @{ "id" = "123" }
            Set-Content -Path $filePath -Value $xml
            [bool]$result = Test-NxtXmlNodeExists -FilePath $filePath -NodePath $nodePath -FilterAttributes $Attributes
            $result | Should -BeFalse
            Add-NxtXmlNode -FilePath $filePath -NodePath $nodePath -Attributes $Attributes
            [bool]$result = Test-NxtXmlNodeExists -FilePath $filePath -NodePath $nodePath -FilterAttributes $Attributes
            $result | Should -BeTrue
            Remove-Item $filePath
        }
    }
    Context "Add the node with text" {
        It "Adds the node to Level1" {
            $xml = @"
<Root>
    <Level1/>
</Root>
"@
            $filePath = "$PSScriptRoot\example2.xml"
            $nodePath = "/Root/Level1/Child"
            $Attributes = @{ "id" = "123" }
            $text = "Some text"
            Set-Content -Path $filePath -Value $xml
            [bool]$result = Test-NxtXmlNodeExists -FilePath $filePath -NodePath $nodePath -FilterAttributes $Attributes
            $result | Should -BeFalse
            Add-NxtXmlNode -FilePath $filePath -NodePath $nodePath -Attributes $Attributes -InnerText $text
            [string]$result = ([xml](Get-Content -Path $filePath)).selectNodes($nodePath).innertext
            $result | Should -Be $text
            Remove-Item $filePath
        }
    }
    Context "Add the node with text and attributes" {
        It "Adds another node Level2 to Level1" {
            $xml = @"
<Root123>
    <Level1>
        <Level2/>
    </Level1>
</Root123>
"@

            $filePath = "$PSScriptRoot\example3.xml"
            $nodePath = "/Root123/Level1/Level2"
            $Attributes = @{ "attribute1" = "22213" }
            $text = "Some text2"
            Set-Content -Path $filePath -Value $xml
            [bool]$result = Test-NxtXmlNodeExists -FilePath $filePath -NodePath $nodePath -FilterAttributes $Attributes
            $result | Should -BeFalse
            Add-NxtXmlNode -FilePath $filePath -NodePath $nodePath -Attributes $Attributes -InnerText $text
            [string]$result = ([xml](Get-Content -Path $filePath)).selectNodes("$nodePath[@attribute1=22213]").InnerText
            $result | Should -Be $text
            [string]$result = ([xml](Get-Content -Path $filePath)).selectNodes($nodePath).count
            $result | Should -Be 2
            Remove-Item $filePath
        }
    }
}
