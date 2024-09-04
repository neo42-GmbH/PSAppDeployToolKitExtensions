Describe "ConvertTo-NxtEncodedObject" {
    Context "When given an input" {
        BeforeAll {
            # Depth 2
            [string]$encoded = 'H4sIAAAAAAAEAKtWKkktLlGyglA6SjmJlalFhkpW1RCWEYhVlphTmqpkZVSrA2Ma1tYCAN+Gkf05AAAA'
            [PSCustomObject]$decoded = @{
                test = 'test'
                layer1 = @{
                    value = 1
                    layer2= @{
                        value = 2
                    }
                }
            }
        }
        It "Should return expected output" {
            $result = Convertto-NxtEncodedObject -Object $decoded -Depth 2
            $result | Should -BeOfType 'String'
            $result | Should -Be $encoded
        }
        It "Should fail when given an invalid input" {
            { ConvertFrom-NxtEncodedObject -EncodedObject 'invalid' } | Should -Throw
        }
    }
}
