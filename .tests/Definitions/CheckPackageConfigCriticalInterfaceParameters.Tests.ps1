Describe "CheckPackageConfigCriticalInterfaceParameters." {
    Context "With a valid package config file" {
        It "Returns no errors" {
            $valuesToCheck = (
                [PSCustomObject]@{
                    Name = "AppName"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "AppVendor"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "AppVersion"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "DisplayVersion"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "InstallMethod"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "PackageGuid"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "ProductGuid"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "UninstallMethod"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "UserPartOnInstallation"
                    Type = "Bool"
                },
                [PSCustomObject]@{
                    Name = "UserPartOnUninstallation"
                    Type = "Bool"
                },
                [PSCustomObject]@{
                    Name = "ScriptDate"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "InventoryID"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "TestedOn"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "Dependencies"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "RegPackagesKey"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "UninstallOld"
                    Type = "Bool"
                },
                [PSCustomObject]@{
                    Name = "AppArch"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "ScriptDate"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "ScriptAuthor"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "AppRevision"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "Build"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "Description"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "LastChange"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "UserPartRevision"
                    Type = "String"
                },
                [PSCustomObject]@{
                    Name = "UninstallKey"
                    Type = "String"
                }
            )
            $packageConfig = Get-Content "$global:PSADTPath\neo42PackageConfig.json" | Out-String | ConvertFrom-Json
            $valuesToCheck.Name | Should -BeIn $($packageConfig.Psobject.Properties.Name) -Because "The value is expected to be in the package config file"
            $valuesToCheck.Where({$_.Type -eq "String"}).Name | Should -BeIn $($packageConfig.Psobject.Properties.Where({$_.Value -is [string]}).Name) -Because "The value is expected to be a string"
            $valuesToCheck.Where({$_.Type -eq "Bool"}).Name | Should -BeIn $($packageConfig.Psobject.Properties.Where({$_.Value -is [bool]}).Name) -Because "The value is expected to be a bool"
        }
    }
}
