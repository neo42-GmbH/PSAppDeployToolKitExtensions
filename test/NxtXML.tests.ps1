# Test the Set-NxtXmlNode Function

# Test 1: Set the value of an existing node
Describe "Test-NxtXmlNodeExists" {
    Context "When the node exists" {
        It "Returns true" {
            $xml = @"
<Root>
    <Child id="123">Some text</Child>
</Root>
"@
            $filePath = "$PSScriptRoot\example1.xml"
            $nodePath = "/Root/Child"
            $filterAttributes = @{ "id" = "123" }
            Set-Content -Path $filePath -Value $xml
            [bool]$result = Test-NxtXmlNodeExists -FilePath $filePath -NodePath $nodePath -FilterAttributes $filterAttributes
            $result | Should -BeTrue
        }
    }
    Context "When the node does not exist" {
        It "Returns false" {
            $xml = @"
<Root>
    <Child id="456">Some text</Child>
</Root>
"@
            $filePath = "$PSScriptRoot\example2.xml"
            $nodePath = "/Root/Child"
            $filterAttributes = @{ "id" = "123" }
            Set-Content -Path $filePath -Value $xml
            [bool]$result = Test-NxtXmlNodeExists -FilePath $filePath -NodePath $nodePath -FilterAttributes $filterAttributes
            $result| Should -BeFalse
        }
    }
    Context "When the node does not exist with multiple attributes" {
        It "Returns false" {
            $xml = @"
<Root>
    <Child id="456" name="test">Some text</Child>
</Root>
"@
            $filePath = "$PSScriptRoot\example3.xml"
            $nodePath = "/Root/Child"
            $filterAttributes = @{ "id" = "123"; "name" = "test" }
            Set-Content -Path $filePath -Value $xml
            [bool]$result = Test-NxtXmlNodeExists -FilePath $filePath -NodePath $nodePath -FilterAttributes $filterAttributes
            $result| Should -BeFalse
        }
    }
    Context "When the node does exist with multiple attributes" {
        It "Returns true" {
            $xml =@"
<Root>
    <Child id="324" name="test">Some text</Child>
</Root>
"@
            $filePath = "$PSScriptRoot\example4.xml"
            $nodePath = "/Root/Child"
            $filterAttributes = @{ "id" = "324"; "name" = "test" }
            Set-Content -Path $filePath -Value $xml
            [bool]$result = Test-NxtXmlNodeExists -FilePath $filePath -NodePath $nodePath -FilterAttributes $filterAttributes
            $result| Should -BeTrue
        }
    }
    Context "When the node does exist with multiple attributes and the filter is not complete" {
        It "Returns true" {
            $xml =@"
<Root>
    <Child id="324" name="test">Some text</Child>
</Root>
"@
            $filePath = "$PSScriptRoot\example5.xml"
            $nodePath = "/Root/Child"
            $filterAttributes = @{ "id" = "324" }
            Set-Content -Path $filePath -Value $xml
            [bool]$result = Test-NxtXmlNodeExists -FilePath $filePath -NodePath $nodePath -FilterAttributes $filterAttributes
            $result| Should -BeTrue
        }
    }
}