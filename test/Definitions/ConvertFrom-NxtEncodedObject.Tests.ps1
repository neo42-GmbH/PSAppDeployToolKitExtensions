Describe "ConvertFrom-NxtEncodedObject" {
    Context "When given an input" {
        BeforeAll {
            [string]$encoded = 'H4sIAAAAAAAEAKtWKkktLlGyglC1AEohkvMPAAAA'
        }
        It "Should return expected output" {
            $output = ConvertFrom-NxtEncodedObject -EncodedObject $encoded
            $output | Should -BeOfType PSCustomObject
            $output.test | Should -Be 'test'

        }
        It "Should fail when given an invalid input" {
            { ConvertFrom-NxtEncodedObject -EncodedObject 'invalid' } | Should -Throw
        }
    }
}
