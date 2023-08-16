# Test the Compare-NxtVersion function
Describe "Compare-NxtVersion" {
    Context "With two equal version numbers 01.0.0 vs 1.0.0" {
        It "Returns Equal" {
            $detectedVersion = "01.0.0"
            $targetVersion = "1.0.0.0"
            $result = Compare-NxtVersion -DetectedVersion $detectedVersion -TargetVersion $targetVersion
            $result | Should -Be "Equal"
        }
    }
    Context "With a higher version number for TargetVersion 1.0.0 vs 2.0.0" {
        It "Returns Update" {
            $detectedVersion = "1.0.0"
            $targetVersion = "2.0.0"
            $result = Compare-NxtVersion -DetectedVersion $detectedVersion -TargetVersion $targetVersion
            $result | Should -Be "Update"
        }
    }
    Context "With a lower version number for TargetVersion 2.0.0 vs 1.0.0" {
        It "Returns Downgrade" {
            $detectedVersion = "2.0.0"
            $targetVersion = "1.0.0"
            $result = Compare-NxtVersion -DetectedVersion $detectedVersion -TargetVersion $targetVersion
            $result | Should -Be "Downgrade"
        }
    }
    Context "With a lower version number for TargetVersion b vs a " {
        It "Returns Downgrade" {
            $detectedVersion = "b"
            $targetVersion = "a"
            $result = Compare-NxtVersion -DetectedVersion $detectedVersion -TargetVersion $targetVersion
            $result | Should -Be "Downgrade"
        }
    }
    Context "With a lower version number for TargetVersion 1a vs 1.a" {
        It "Returns Downgrade" {
            $detectedVersion = "1a"
            $targetVersion = "1.a"
            $result = Compare-NxtVersion -DetectedVersion $detectedVersion -TargetVersion $targetVersion
            $result | Should -Be "Downgrade"
        }
    }
    Context "With AB vs AA in HexMode" {
        It "Returns Downgrade" {
            $detectedVersion = "AB"
            $targetVersion = "AA"
            $result = Compare-NxtVersion -DetectedVersion $detectedVersion -TargetVersion $targetVersion -HexMode $true
            $result | Should -Be "Downgrade"
        }
    }
}