Describe "Get-NxtDriveFreeSpace" {
    Context "When running the function" {
        BeforeAll {
            [System.Management.Automation.PSDriveInfo]$drive = (Get-PSDrive -PSProvider FileSystem)[0]
            [string]$driveLetter = $drive.Root.TrimEnd('\')
        }
        It "Should return the free space of a drive" {
            $result = Get-NxtDriveFreeSpace -DriveName $driveLetter
            $result | Should -BeOfType 'System.Int64'
            $result | Should -Be $drive.Free
        }
        It "Should convert values between unit sizes" {
            [System.Int64]$inByte = Get-NxtDriveFreeSpace -DriveName $driveLetter -Unit B
            [System.Int64]$inKByte = [math]::floor($($inByte / 1024))
            Get-NxtDriveFreeSpace -DriveName $driveLetter -Unit KB | Should -Be $inKByte
        }
        It "Should fail for invalid drives" {
            Get-NxtDriveFreeSpace -DriveName B: -Unit KB | Should -Be 0
        }
    }
}
