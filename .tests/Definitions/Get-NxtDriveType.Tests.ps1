Describe "Get-NxtDriveType" {
    Context "When given a valid drive letter" {
        BeforeAll {
            [ciminstance]$localDrive = (Get-Volume | Where-Object { $_.DriveLetter -ne $null -and $_.DriveType -eq 'Fixed' })[0]
        }
        It "Returns the correct drive type" {
            $result = Get-NxtDriveType -DriveName "$($localDrive.DriveLetter):"
            $result | Should -BeOfType 'PSADTNXT.DriveType'
            $result | Should -Be 3
        }
        It "Returns error if drive is not found" {
            Get-NxtDriveType -DriveName "B:" | Should -Be 0
        }
    }
}
