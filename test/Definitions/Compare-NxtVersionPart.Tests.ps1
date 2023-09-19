# Test the Compare-NxtVersionPart function
Describe "Compare-NxtVersionPart" {
    Context "With two equal version numbers 1 vs 1" {
        It "Returns Equal" {
            $detectedVersion = "1"
            $targetVersion = "1"
            [string]$result = Compare-NxtVersionPart -DetectedVersion $detectedVersion -TargetVersion $targetVersion
            $result | Should -Be "Equal"
        }
    }
    Context "With two equal version strings a vs a" {
        It "Returns Equal" {
            $detectedVersion = "a"
            $targetVersion = "a"
            [string]$result = Compare-NxtVersionPart -DetectedVersion $detectedVersion -TargetVersion $targetVersion
            $result | Should -Be "Equal"
        }
    }
    Context "With two equal version HexNumbers in HexMode A vs A" {
        It "Returns Equal" {
            $detectedVersion = "A"
            $targetVersion = "A"
            [string]$result = Compare-NxtVersionPart -DetectedVersion $detectedVersion -TargetVersion $targetVersion
            $result | Should -Be "Equal"
        }
    }
    Context "With two different version numbers 4 vs 1" {
        It "Returns Downgrade" {
            $detectedVersion = "4"
            $targetVersion = "1"
            [string]$result = Compare-NxtVersionPart -DetectedVersion $detectedVersion -TargetVersion $targetVersion
            $result | Should -Be "Downgrade"
        }
    }
    Context "With two different version strings aa vs b" {
        It "Returns Update" {
            $detectedVersion = "aa"
            $targetVersion = "b"
            [string]$result = Compare-NxtVersionPart -DetectedVersion $detectedVersion -TargetVersion $targetVersion
            $result | Should -Be "Update"
        }
    }
    Context "With two different version HexNumbers in HexMode aa vs b" {
        It "Returns Downgrade" {
            $detectedVersion = "aa"
            $targetVersion = "b"
            [string]$result = Compare-NxtVersionPart -DetectedVersion $detectedVersion -TargetVersion $targetVersion -HexMode $true
            $result | Should -Be "Downgrade"
        }
    }
    Context "With two different version HexNumbers in HexMode 1 vs 4" {
        It "Returns Update" {
            $detectedVersion = "1"
            $targetVersion = "4"
            [string]$result = Compare-NxtVersionPart -DetectedVersion $detectedVersion -TargetVersion $targetVersion -HexMode $true
            $result | Should -Be "Update"
        }
    }
    Context "With two different version HexNumbers in HexMode 1 vs 1" {
        It "Returns Equal" {
            $detectedVersion = "1"
            $targetVersion = "1"
            [string]$result = Compare-NxtVersionPart -DetectedVersion $detectedVersion -TargetVersion $targetVersion -HexMode $true
            $result | Should -Be "Equal"
        }
    }
    Context "With two different version Strings with one of both not parsable to hex 1g1 vs f1" {
        It "Returns Update" {
            $detectedVersion = "1g1"
            $targetVersion = "f1"
            [string]$result = Compare-NxtVersionPart -DetectedVersion $detectedVersion -TargetVersion $targetVersion -HexMode $true
            $result | Should -Be "Update"
        }
    }
    Context "With two different version Strings with both parsable to hex 1f1 vs f1" {
        It "Returns Downgrade" {
            $detectedVersion = "1f1"
            $targetVersion = "f1"
            [string]$result = Compare-NxtVersionPart -DetectedVersion $detectedVersion -TargetVersion $targetVersion -HexMode $true
            $result | Should -Be "Downgrade"
        }
    }
    Context "With two different version Strings with both parsable to hex 1f1 vs f2 but without HexMode activated" {
        It "Returns Update" {
            $detectedVersion = "1f1"
            $targetVersion = "f2"
            [string]$result = Compare-NxtVersionPart -DetectedVersion $detectedVersion -TargetVersion $targetVersion
            $result | Should -Be "Update"
        }
    }
}