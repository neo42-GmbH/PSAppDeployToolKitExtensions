Describe "Get-NxtUILanguage" {
    Context "When running the function" {
        It "Should return a valid LCID" {
            $result = Get-NxtUILanguage
            $result | Should -BeOfType 'System.Int32'
            $result | Should -BeGreaterOrEqual 1000
            $result | Should -BeLessOrEqual 59000
        }
    }
}
