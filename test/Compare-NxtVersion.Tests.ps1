# Test the Compare-NxtVersion function
Describe "Compare-NxtVersion" {
    Context "With two equal version numbers" {
        It "Returns 1" {
            $detectedVersion = "01.0.0"
            $targetVersion = "1.0.0.0"
            $result = Compare-NxtVersion -DetectedVersion $detectedVersion -TargetVersion $targetVersion
            $result | Should -Be 1
        }
    }
    Context "With a higher version number for TargetVersion" {
        It "Returns 2" {
            $detectedVersion = "1.0.0"
            $targetVersion = "2.0.0"
            $result = Compare-NxtVersion -DetectedVersion $detectedVersion -TargetVersion $targetVersion
            $result | Should -Be 2
        }
    }
    Context "With a lower version number for TargetVersion" {
        It "Returns 3" {
            $detectedVersion = "2.0.0"
            $targetVersion = "1.0.0"
            $result = Compare-NxtVersion -DetectedVersion $detectedVersion -TargetVersion $targetVersion
            $result | Should -Be 3
        }
    }
    Context "With a lower version number for TargetVersion" {
        It "Returns 3" {
            $detectedVersion = "b"
            $targetVersion = "a"
            $result = Compare-NxtVersion -DetectedVersion $detectedVersion -TargetVersion $targetVersion
            $result | Should -Be 3
        }
    }
}