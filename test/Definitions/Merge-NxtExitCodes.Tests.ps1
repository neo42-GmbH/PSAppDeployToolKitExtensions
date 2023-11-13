Describe 'Merge-NxtExitCodes' {
    Context 'When merging exit codes' {
        It 'Should combine two valid exit codes' {
            $result = Merge-NxtExitCodes -ExitCodeString1 "1" -ExitCodeString2 "2"
            $result | Should -BeOfType 'System.String'
            $result | Should -be '1,2'
        }
        It 'Should combine lists of exit codes' {
            Merge-NxtExitCodes -ExitCodeString1 "1,2" -ExitCodeString2 "3,4" | Should -Be '1,2,3,4'
            Merge-NxtExitCodes -ExitCodeString1 "1,2" -ExitCodeString2 "3" | Should -Be '1,2,3'
            Merge-NxtExitCodes -ExitCodeString1 "1" -ExitCodeString2 "2,3" | Should -Be '1,2,3'
        }
        It 'Should not remove whitespaces from list' {
            Merge-NxtExitCodes -ExitCodeString1 "1,2" -ExitCodeString2 "3, 4" | Should -Be '1,2,3, 4'
        }
        It 'Should handle empty input' {
            Merge-NxtExitCodes -ExitCodeString1 "" -ExitCodeString2 "" | Should -BeNullOrEmpty
            Merge-NxtExitCodes -ExitCodeString1 "1" -ExitCodeString2 "" | Should -Be '1'
            Merge-NxtExitCodes -ExitCodeString1 "" -ExitCodeString2 "1" | Should -Be '1'
        }
        It 'Should always be * if any element is *' {
            # Issue #631
            Merge-NxtExitCodes -ExitCodeString1 "*" -ExitCodeString2 "1" | Should -Be '*'
            Merge-NxtExitCodes -ExitCodeString1 "1" -ExitCodeString2 "*" | Should -Be '*'
            Merge-NxtExitCodes -ExitCodeString1 "*" -ExitCodeString2 "*" | Should -Be '*'
            Merge-NxtExitCodes -ExitCodeString1 "1,*" -ExitCodeString2 "2" | Should -Be '1,*,2'
        }
    }
}
