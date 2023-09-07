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
    [string]$version = Get-NxtContentBetweenTags -Content $existingContent -StartTag "	Version: " -EndTag "	Toolkit Exit Code Ranges:"
    if ([int]($version.TrimEnd("`n") -split "-")[1] -lt 53) {
        throw "Version of $PackageToUpdatePath is lower than 2023.06.12.01-53 and must be updated manually"
    }
    [string]$newVersion = Get-NxtContentBetweenTags -Content $newVersionContent -StartTag "	Version: " -EndTag "	Toolkit Exit Code Ranges:"
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
    [string]$existingContent = $existingContent.Replace("## executes at after the uninstallation in the reinstall process","## executes after the succesful uninstallation in the reinstall process")
    [string]$existingContent = $existingContent.Replace("## executes after the installation in the reinstall process","## executes after the succesful installation in the reinstall process")
    [string]$existingContent = $existingContent.Replace("## executes after the installation in the install process","## executes after the succesful installation in the install process")
    [string]$existingContent = $existingContent.Replace("## executes after the uninstallation in the uninstall process","## executes after the succesful uninstallation in the uninstall process")

    #also change wrong installphase nams of some custom sections
    [string]$existingContent = $existingContent.Replace("installPhase = 'CustomPostInstallAndReinstall'","installPhase = 'CustomInstallAndReinstallEnd'")

    foreach ($customFunctionName in $customFunctionNames) {
        [string]$startTag = "#region $customFunctionName content"
        [string]$endTag = "#endregion $customFunctionName content"
        [string]$contentBetweenTags = Get-NxtContentBetweenTags -Content $existingContent -StartTag $startTag -EndTag $endTag
        $resultContent = Set-NxtContentBetweenTags -Content $resultContent -StartTag $startTag -EndTag $endTag -ContentBetweenTags $contentBetweenTags
    }
    Write-Output "Updating $PackageToUpdatePath$versionInfo"
    Set-Content -Path "$PackageToUpdatePath\Deploy-Application.ps1" -Value $resultContent -NoNewline
    Add-Content -Path "$PSscriptRoot\$LogFileName" -Value "Updated $PackageToUpdatePath from $LatestVersionPath$versionInfo"
    Remove-Item -Path "$PackageToUpdatePath\AppDeployToolkit" -Recurse -Force
    Copy-Item -Path "$LatestVersionPath\AppDeployToolkit" -Destination $PackageToUpdatePath -Recurse -Force

            #also update packagecofig.json so it contains all default values
            [string]$content = Get-Content -Raw -Path $PackageToUpdatePath\neo42PackageConfig.json
            [PSCustomObject]$jsonContent = $content | ConvertFrom-Json
            if ($null -eq $jsonContent.UninstallKeyContainsExpandVariables){
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayNamesToExcludeFromAppSearches"' -ContentToInsert '  "UninstallKeyContainsExpandVariables": false,
'
                Set-Content -Path "$PackageToUpdatePath\neo42PackageConfig.json" -Value $content -NoNewline
            }
            ## rename AcceptedRepairExitCodes to AcceptedMSIRepairExitCodes
            [string]$content = Get-Content -Raw -Path $PackageToUpdatePath\neo42PackageConfig.json
            [PSCustomObject]$jsonContent = $content | ConvertFrom-Json
            if ($null -ne $jsonContent.AcceptedRepairExitCodes){
                $content = $content.Replace("AcceptedRepairExitCodes","AcceptedMSIRepairExitCodes")
                Set-Content -Path "$PackageToUpdatePath\neo42PackageConfig.json" -Value $content -NoNewline
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
