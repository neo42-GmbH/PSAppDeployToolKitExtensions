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
                    Type = "GUID"
                },
                [PSCustomObject]@{
                    Name = "ProductGuid"
                    Type = "GUID"
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
                }
            )
            $packageConfig = Get-Content .\neo42PackageConfig.json | Out-String | ConvertFrom-Json
            $valuesToCheck.Name | Should -BeIn $($packageConfig.Psobject.Properties.Name) -Because "The value is expected to be in the package config file"
            $valuesToCheck.Where({$_.Type -eq "String"}).Name | Should -BeIn $($packageConfig.Psobject.Properties.Where({$_.Value -is [string]}).Name) -Because "The value is expected to be a string"
            $valuesToCheck.Where({$_.Type -eq "Bool"}).Name | Should -BeIn $($packageConfig.Psobject.Properties.Where({$_.Value -is [bool]}).Name) -Because "The value is expected to be a bool"
            $guidParameterNames = $valuesToCheck.Where({$_.Type -eq "GUID"}).Name
            $guidParameters = $packageConfig.Psobject.Properties.Where({$_.Name -in $GuidParameterNames})
            $guidOutput = [guid]::NewGuid()
            $guidParameters.Name | Should -BeIn $($guidParameters.Where({[guid]::TryParse($_.Value, [ref]$guidOutput)}).Name) -Because "The value is expected to be a GUID"
        }
    }
}