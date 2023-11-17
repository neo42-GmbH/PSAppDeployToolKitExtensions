# Test the Add-NxtLocalGroup Function
Describe 'Add-NxtLocalGroup' {
    Context 'When adding a new local group' {
        AfterEach{
            Remove-LocalGroup -Name 'TestGroup'
        }

        It 'Should create a new local group' {
            Add-NxtLocalGroup -GroupName 'TestGroup' | Should -Be $true
            Get-LocalGroup -Name 'TestGroup' | Should -Not -BeNullOrEmpty
        }

        It 'Should alter the description if group already exists' {
            Add-NxtLocalGroup -GroupName 'TestGroup'
            Add-NxtLocalGroup -GroupName 'TestGroup' -Description 'Test Description🚀äß' | Should -Be $true
            (Get-LocalGroup -Name 'TestGroup').Description | Should -Be 'Test Description🚀äß'
        }
    }
}
