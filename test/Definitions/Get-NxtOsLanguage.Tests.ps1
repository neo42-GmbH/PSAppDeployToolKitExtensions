Describe "Get-NxtOsLanguage" {
    Context "When running the function" {
        BeforeALl {
            [int]$LCID = (Get-WinSystemLocale).LCID
        }
        It "Should return the expected output" {
            $result = Get-NxtOsLanguage
            $result | Should -BeOfType 'System.Int32'
            $result | Should -Be $LCID
        }
    }
}
