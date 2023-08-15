# Test the Compare-NxtVersion function
Describe "Compare-NxtVersion" {
    Context "With two equal version numbers" {
        It "Returns 1" {
            # Arrange
            $detectedVersion = "01.0.0"
            $targetVersion = "1.0.0.0"

            # Act
            $result = Compare-NxtVersion -DetectedVersion $detectedVersion -TargetVersion $targetVersion

            # Assert
            $result | Should -Be 1
        }
    }

    Context "With a higher version number for TargetVersion" {
        It "Returns 2" {
            # Arrange
            $detectedVersion = "1.0.0"
            $targetVersion = "2.0.0"

            # Act
            $result = Compare-NxtVersion -DetectedVersion $detectedVersion -TargetVersion $targetVersion

            # Assert
            $result | Should -Be 2
        }
    }

    Context "With a lower version number for TargetVersion" {
        It "Returns 3" {
            # Arrange
            $detectedVersion = "2.0.0"
            $targetVersion = "1.0.0"

            # Act
            $result = Compare-NxtVersion -DetectedVersion $detectedVersion -TargetVersion $targetVersion

            # Assert
            $result | Should -Be 3
        }
    }
}