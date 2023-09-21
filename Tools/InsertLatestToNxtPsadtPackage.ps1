param(
        [Parameter(Mandatory=$true)]
        [string]$PackagesToUpdatePath,
        [Parameter(Mandatory=$true)]
        [string]$LatestVersionPath
    )
function Get-NxtContentBetweenTags {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,
        [Parameter(Mandatory=$true)]
        [string]$StartTag,
        [Parameter(Mandatory=$true)]
        [string]$EndTag
    )
    $StartIndex = $Content.IndexOf($StartTag)+$StartTag.Length
    $EndIndex = $Content.IndexOf($EndTag)
    $ContentBetweenTags = $Content.Substring($StartIndex, $EndIndex - $StartIndex)
    return $ContentBetweenTags
}
function Set-NxtContentBetweenTags {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,
        [Parameter(Mandatory=$true)]
        [string]$StartTag,
        [Parameter(Mandatory=$true)]
        [string]$EndTag,
        [Parameter(Mandatory=$true)]
        [string]$ContentBetweenTags
    )
    $StartIndex = $Content.IndexOf($StartTag)+$StartTag.Length
    $EndIndex = $Content.IndexOf($EndTag)
    $Content = $Content.Remove($StartIndex, $EndIndex - $StartIndex)
    $Content = $Content.Insert($StartIndex, $ContentBetweenTags)
    return $Content
}
function Add-ContentBeforeTag {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,
        [Parameter(Mandatory=$true)]
        [string]$StartTag,
        [Parameter(Mandatory=$true)]
        [string]$ContentToInsert
    )
    $StartIndex = $Content.IndexOf($StartTag)
    if ($StartIndex -eq -1) {
        throw "StartIndex not found"
    }
    $content = $content.Insert($StartIndex, $ContentToInsert)
    return $content
}
function Update-NxtPSAdtPackage {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PackageToUpdatePath,
        [Parameter(Mandatory=$true)]
        [string]$LatestVersionPath,
        [Parameter(Mandatory=$false)]
        [string]$LogFileName
    )
    try {
    # test if both paths exist
    if (-not (Test-Path -Path $PackageToUpdatePath)) {
        throw "PackageToUpdatePath does not exist"
    }
    if (-not (Test-Path -Path $LatestVersionPath)) {
        throw "LatestVersionPath does not exist"
    }
    [string]$newVersionContent = Get-Content -raw -Path "$LatestVersionPath\Deploy-Application.ps1"
    [string]$existingContent = Get-Content -Raw -Path "$PackageToUpdatePath\Deploy-Application.ps1"
    #check for Version -ge 2023.06.12.01-53
    if ($existingContent -match "ConfigVersion:") {
        [string]$version = Get-NxtContentBetweenTags -Content $existingContent -StartTag "Version: " -EndTag "	ConfigVersion:"
    }else{
        [string]$version = Get-NxtContentBetweenTags -Content $existingContent -StartTag "	Version: " -EndTag "	Toolkit Exit Code Ranges:"
    }
    if ([int]($version.TrimEnd("`n") -split "-")[1] -lt 53) {
        throw "Version of $PackageToUpdatePath is lower than 2023.06.12.01-53 and must be updated manually"
    }
    [string]$newVersion = Get-NxtContentBetweenTags -Content $newVersionContent -StartTag "	Version: " -EndTag "	ConfigVersion:"
    if ($version.TrimEnd("`n") -eq $newVersion.TrimEnd("`n")) {
        $versionInfo = " ... but seems already up-to-date (same version tag!)"
    }
    else {
        $versionInfo = [string]::Empty
    }
    [string[]]$customFunctionNames = foreach ($line in ($existingContent -split "`n")){
        if ($line -match "function Custom") {
            $line -split " " | Select-Object -Index 1
        }
    }
    [string]$resultContent = $newVersionContent
    if ($null -eq $customFunctionNames){
        throw "No custom functions found in $PackageToUpdatePath"
    }
    #add new custom sections
    [array]$newCustomFunctions = "CustomReinstallPostUninstallOnError","CustomReinstallPostInstallOnError","CustomInstallEndOnError","CustomUninstallEndOnError"
    foreach ($newcustomFunctionName in $newCustomFunctions) {
        if (-not ($customFunctionNames.contains($newcustomFunctionName))) {
            [string]$content = $existingContent
            $resultContent = $null
            switch ($newcustomFunctionName) {
                "CustomReinstallPostUninstallOnError" {
                    $resultContent = Add-ContentBeforeTag -Content $existingContent -StartTag "function CustomReinstallPostUninstall {" -ContentToInsert "function CustomReinstallPostUninstallOnError {
    param (
        [Parameter(Mandatory = `$true)]
        [PSADTNXT.NxtApplicationResult]
        `$ResultToCheck
    )
    [string]`$script:installPhase = 'CustomReinstallPostUninstallOnError'

    ## executes right after the uninstallation in the reinstall process (just add possible cleanup steps here, because scripts exits right after this function!)
    #region CustomReinstallPostUninstallOnError content

    #endregion CustomReinstallPostUninstallOnError content
}

"
                }
                "CustomReinstallPostInstallOnError" {
                    $resultContent = Add-ContentBeforeTag -Content $existingContent -StartTag "function CustomReinstallPostInstall {" -ContentToInsert "function CustomReinstallPostInstallOnError {
    param (
        [Parameter(Mandatory = `$true)]
        [PSADTNXT.NxtApplicationResult]
        `$ResultToCheck
    )
    [string]`$script:installPhase = 'CustomReinstallPostInstallOnError'

    ## executes right after the installation in the reinstall process (just add possible cleanup steps here, because scripts exits right after this function!)
    #region CustomReinstallPostInstallOnError content

    #endregion CustomReinstallPostInstallOnError content
}

"
                }
                "CustomInstallEndOnError" {
                    $resultContent = Add-ContentBeforeTag -Content $existingContent -StartTag "function CustomInstallEnd {" -ContentToInsert "function CustomInstallEndOnError {
    param (
        [Parameter(Mandatory = `$true)]
        [PSADTNXT.NxtApplicationResult]
        `$ResultToCheck
    )
    [string]`$script:installPhase = 'CustomInstallEndOnError'

    ## executes right after the installation in the install process (just add possible cleanup steps here, because scripts exits right after this function!)
    #region CustomInstallEndOnError content

    #endregion CustomInstallEndOnError content
}

"
                }
                "CustomUninstallEndOnError" {
                    $resultContent = Add-ContentBeforeTag -Content $existingContent -StartTag "function CustomUninstallEnd {" -ContentToInsert "function CustomUninstallEndOnError {
    param (
        [Parameter(Mandatory = `$true)]
        [PSADTNXT.NxtApplicationResult]
        `$ResultToCheck
    )
    [string]`$script:installPhase = 'CustomUninstallEndOnError'

    ## executes right after the uninstallation in the uninstall process (just add possible cleanup steps here, because scripts exits right after this function!)
    #region CustomUninstallEndOnError content

    #endregion CustomUninstallEndOnError content
}

"
                }
            }
            if (-not [string]::IsNullOrEmpty($resultContent)) {
                Write-Output "... adding custom function: $newcustomFunctionName"
                Set-Content -Path "$PackageToUpdatePath\Deploy-Application.ps1" -Value $resultContent -NoNewline
                #re-read content
                [string]$existingContent = Get-Content -Raw -Path "$PackageToUpdatePath\Deploy-Application.ps1"
            }
        }
    }
    #also change comments of some custom sections
    [string]$existingContent = $existingContent.Replace("## executes at after the uninstallation in the reinstall process","## executes after the successful uninstallation in the reinstall process")
    [string]$existingContent = $existingContent.Replace("## executes after the installation in the reinstall process","## executes after the successful installation in the reinstall process")
    [string]$existingContent = $existingContent.Replace("## executes after the installation in the install process","## executes after the successful installation in the install process")
    [string]$existingContent = $existingContent.Replace("## executes after the uninstallation in the uninstall process","## executes after the successful uninstallation in the uninstall process")

    #also change wrong installphase names of some custom sections
    [string]$existingContent = $existingContent.Replace("installPhase = 'CustomPostInstallAndReinstall'","installPhase = 'CustomInstallAndReinstallEnd'")

    foreach ($customFunctionName in $customFunctionNames) {
        [string]$startTag = "#region $customFunctionName content"
        [string]$endTag = "#endregion $customFunctionName content"
        [string]$contentBetweenTags = Get-NxtContentBetweenTags -Content $existingContent -StartTag $startTag -EndTag $endTag
        $resultContent = Set-NxtContentBetweenTags -Content $resultContent -StartTag $startTag -EndTag $endTag -ContentBetweenTags $contentBetweenTags
    }
    Write-Output "Updating $PackageToUpdatePath$versionInfo"
    Set-Content -Path "$PackageToUpdatePath\Deploy-Application.ps1" -Value $resultContent -NoNewline -Encoding 'UTF8'
    Add-Content -Path "$PSscriptRoot\$LogFileName" -Value "Updated $PackageToUpdatePath from $LatestVersionPath$versionInfo"
    ## insert an updated framework folder to destination
    Remove-Item -Path "$PackageToUpdatePath\AppDeployToolkit" -Recurse -Force
    Copy-Item -Path "$LatestVersionPath\AppDeployToolkit" -Destination $PackageToUpdatePath -Recurse -Force
    ## insert an updated validation file to destination
    Copy-Item -Path "$LatestVersionPath\neo42PackageConfigValidationRules.json" -Destination "$PackageToUpdatePath\neo42PackageConfigValidationRules.json" -Force

            ## also update neo42PackageConfig.json so it contains all default values
            Add-Content -Path "$PSscriptRoot\$LogFileName" -Value "   -> list if additional update tasks had to be done in 'neo42PackageConfig.json':"
            ## remove entries: "AcceptedRepairExitCodes" and "AcceptedMSIRepairExitCodes" (just to be sure!)
            [string]$content = Get-Content -Raw -Path $PackageToUpdatePath\neo42PackageConfig.json
            [PSCustomObject]$jsonContent = $content | ConvertFrom-Json
            if (($null -ne $jsonContent.AcceptedRepairExitCodes) -or ($null -ne $jsonContent.AcceptedMSIRepairExitCodes)) {
                $content = $content.Replace(('  "AcceptedRepairExitCodes":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "AcceptedRepairExitCodes":' -EndTag '  "UninstFile":')),'')
                $content = $content.Replace(('  "AcceptedMSIRepairExitCodes":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "AcceptedMSIRepairExitCodes":' -EndTag '  "UninstFile":')),'')
                Set-Content -Path "$PackageToUpdatePath\neo42PackageConfig.json" -Value $content -NoNewline
                Add-Content -Path "$PSscriptRoot\$LogFileName" -Value '      * removed "Accepted*RepairExitCodes"'
            }
            ## new entry: UninstallKeyContainsExpandVariables
            [string]$content = Get-Content -Raw -Path $PackageToUpdatePath\neo42PackageConfig.json
            [PSCustomObject]$jsonContent = $content | ConvertFrom-Json
            if ($null -eq $jsonContent.UninstallKeyContainsExpandVariables){
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayNamesToExcludeFromAppSearches"' -ContentToInsert '  "UninstallKeyContainsExpandVariables": false,
'
                Set-Content -Path "$PackageToUpdatePath\neo42PackageConfig.json" -Value $content -NoNewline
                Add-Content -Path "$PSscriptRoot\$LogFileName" -Value '      * removed "UninstallKeyContainsExpandVariables"'
            }
            ## new entry: "ConfigVersion"
            [string]$content = Get-Content -Raw -Path $PackageToUpdatePath\neo42PackageConfig.json
            [PSCustomObject]$jsonContent = $content | ConvertFrom-Json
            if ($null -eq $jsonContent.ConfigVersion){
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "ScriptAuthor"' -ContentToInsert '  "ConfigVersion": "2023.09.18.1",
'
                Set-Content -Path "$PackageToUpdatePath\neo42PackageConfig.json" -Value $content -NoNewline
                Add-Content -Path "$PSscriptRoot\$LogFileName" -Value '      * added "ConfigVersion"'
            }
            ## new entry: "AcceptedInstallRebootCodes"
            [string]$content = Get-Content -Raw -Path $PackageToUpdatePath\neo42PackageConfig.json
            [PSCustomObject]$jsonContent = $content | ConvertFrom-Json
            if ($null -eq $jsonContent.AcceptedInstallRebootCodes){
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "UninstFile"' -ContentToInsert '  "AcceptedInstallRebootCodes": "",
'
                Set-Content -Path "$PackageToUpdatePath\neo42PackageConfig.json" -Value $content -NoNewline
                Add-Content -Path "$PSscriptRoot\$LogFileName" -Value '      * added "AcceptedInstallRebootCodes"'
            }
            ## new entry: "AcceptedUninstallRebootCodes"
            [string]$content = Get-Content -Raw -Path $PackageToUpdatePath\neo42PackageConfig.json
            [PSCustomObject]$jsonContent = $content | ConvertFrom-Json
            if ($null -eq $jsonContent.AcceptedUninstallRebootCodes){
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "AppKillProcesses"' -ContentToInsert '  "AcceptedUninstallRebootCodes": "",
'
                Set-Content -Path "$PackageToUpdatePath\neo42PackageConfig.json" -Value $content -NoNewline
                Add-Content -Path "$PSscriptRoot\$LogFileName" -Value '      * added "AcceptedUninstallRebootCodes"'
            }
            ## re-sort entries by topic
            [string]$content = Get-Content -Raw -Path $PackageToUpdatePath\neo42PackageConfig.json
            ## check, if already sorted -> then "LastChange" is placed after "ScriptDate"!
            if ($(Get-NxtContentBetweenTags -Content $content -StartTag '  "ScriptDate":' -EndTag '  "InventoryID":') -notmatch '"LastChange":') {
                [string]$blockInventoryID = '  "InventoryID":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "InventoryID":' -EndTag '  "Description":')
                [string]$blockDescription = '  "Description":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "Description":' -EndTag '  "InstallMethod":')
                [string]$blockInstallMethod = '  "InstallMethod":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "InstallMethod":' -EndTag '  "UninstallMethod":')
                [string]$blockUninstallMethod = '  "UninstallMethod":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "UninstallMethod":' -EndTag '  "ReinstallMode":')
                [string]$blockReinstallMode = '  "ReinstallMode":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "ReinstallMode":' -EndTag '  "MSIInplaceUpgradeable":')
                [string]$blockMSIInplaceUpgradeable = '  "MSIInplaceUpgradeable":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "MSIInplaceUpgradeable":' -EndTag '  "MSIDowngradeable":')
                [string]$blockMSIDowngradeable = '  "MSIDowngradeable":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "MSIDowngradeable":' -EndTag '  "SoftMigration":')
                [string]$blockSoftMigration = '  "SoftMigration":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "SoftMigration":' -EndTag '  "TestedOn":')
                [string]$blockTestedOn = '  "TestedOn":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "TestedOn":' -EndTag '  "Dependencies":')
                [string]$blockDependencies = '  "Dependencies":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "Dependencies":' -EndTag '  "LastChange":')
                [string]$blockLastChange = '  "LastChange":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "LastChange":' -EndTag '  "Build":')
                [string]$blockBuild = '  "Build":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "Build":' -EndTag '  "AppArch":')
                [string]$blockAppArch = '  "AppArch":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "AppArch":' -EndTag '  "AppVendor":')
                [string]$blockAppVendor = '  "AppVendor":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "AppVendor":' -EndTag '  "AppName":')
                [string]$blockAppName = '  "AppName":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "AppName":' -EndTag '  "AppVersion":')
                [string]$blockAppVersion = '  "AppVersion":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "AppVersion":' -EndTag '  "AppRevision":')
                [string]$blockAppRevision = '  "AppRevision":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "AppRevision":' -EndTag '  "AppLang":')
                [string]$blockAppLang = '  "AppLang":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "AppLang":' -EndTag '  "ProductGUID":')
                [string]$blockProductGUID = '  "ProductGUID":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "ProductGUID":' -EndTag '  "RemovePackagesWithSameProductGUID":')
                [string]$blockRemovePackagesWithSameProductGUID = '  "RemovePackagesWithSameProductGUID":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "RemovePackagesWithSameProductGUID":' -EndTag '  "PackageGUID":')
                [string]$blockPackageGUID = '  "PackageGUID":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "PackageGUID":' -EndTag '  "DependentPackages":')
                [string]$blockDependentPackages = '  "DependentPackages":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "DependentPackages":' -EndTag '  "RegPackagesKey":')
                [string]$blockRegPackagesKey = '  "RegPackagesKey":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "RegPackagesKey":' -EndTag '  "UninstallDisplayName":')
                [string]$blockUninstallDisplayName = '  "UninstallDisplayName":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "UninstallDisplayName":' -EndTag '  "App":')
                [string]$blockApp = '  "App":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "App":' -EndTag '  "UninstallOld":')
                [string]$blockUninstallOld = '  "UninstallOld":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "UninstallOld":' -EndTag '  "Reboot":')
                [string]$blockReboot = '  "Reboot":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "Reboot":' -EndTag '  "UserPartOnInstallation":')
                [string]$blockUserPartOnInstallation = '  "UserPartOnInstallation":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "UserPartOnInstallation":' -EndTag '  "UserPartOnUninstallation":')
                [string]$blockUserPartOnUninstallation = '  "UserPartOnUninstallation":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "UserPartOnUninstallation":' -EndTag '  "UserPartRevision":')
                [string]$blockUserPartRevision = '  "UserPartRevision":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "UserPartRevision":' -EndTag '  "HidePackageUninstallButton":')
                [string]$blockHidePackageUninstallButton = '  "HidePackageUninstallButton":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "HidePackageUninstallButton":' -EndTag '  "HidePackageUninstallEntry":')
                [string]$blockHidePackageUninstallEntry = '  "HidePackageUninstallEntry":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "HidePackageUninstallEntry":' -EndTag '  "DisplayVersion":') 
                ## remove complete old block between ScriptDate and DisplayVersion
                $content = $content.Replace(('  "InventoryID":' + $(Get-NxtContentBetweenTags -Content $content -StartTag '  "InventoryID":' -EndTag '  "DisplayVersion":')),'')
                ## lines re-sorted above DisplayVersion
				$content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockLastChange
				$content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockBuild
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockInventoryID
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockDescription
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockDependencies
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockTestedOn
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockAppArch
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockAppVendor
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockAppName
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockAppVersion
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockAppRevision
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockAppLang
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockProductGUID
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockRemovePackagesWithSameProductGUID
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockPackageGUID
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockDependentPackages
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockApp
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockRegPackagesKey
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockUninstallDisplayName
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockHidePackageUninstallButton
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockHidePackageUninstallEntry
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockReboot
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockUninstallOld
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockSoftMigration
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockInstallMethod
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockUninstallMethod
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockReinstallMode
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockMSIInplaceUpgradeable
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockMSIDowngradeable
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockUserPartOnInstallation
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockUserPartOnUninstallation
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayVersion":' -ContentToInsert $blockUserPartRevision
                Set-Content -Path "$PackageToUpdatePath\neo42PackageConfig.json" -Value $content -NoNewline
                Add-Content -Path "$PSscriptRoot\$LogFileName" -Value "      * re-sorted parameters by topic"
            }
        }
        catch {
            Write-Error "$PackageToUpdatePath could not be updated from $LatestVersionPath - $_"
            Add-Content -Path "$PSscriptRoot\$LogFileName" -Value "Failed to update $PackageToUpdatePath"
        }
    }
[string]$logFileName = (Get-Date -format "yyyy-MM-dd_HH-mm-ss") + "_UpdateNxtPSAdtPackage." + "log"
Get-ChildItem -Recurse -Path $PackagesToUpdatePath -Filter "Deploy-Application.ps1" | ForEach-Object {
   Update-NxtPSAdtPackage -PackageToUpdatePath $_.Directory.FullName -LatestVersionPath $LatestVersionPath -LogFileName $logFileName
} 
Read-Host -Prompt "Press Enter to exit"
