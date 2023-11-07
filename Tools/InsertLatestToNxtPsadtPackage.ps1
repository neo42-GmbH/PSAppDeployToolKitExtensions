param(
        [Parameter(Mandatory=$true)]
        [string]$PackagesToUpdatePath,
        [Parameter(Mandatory=$true)]
        [string]$LatestVersionPath,
        [Parameter(Mandatory=$false)]
        [string]$CompatibleVersion = "##REPLACEVERSION##"
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
#region Function Import-NxtIniFileWithComments
function Import-NxtIniFileWithComments {
    <#
	.SYNOPSIS
		Imports an INI file into Powershell Object.
	.DESCRIPTION
		Imports an INI file into Powershell Object.
	.PARAMETER Path
		The path to the INI file.
	.PARAMETER ContinueOnError
		Continue on error.
	.EXAMPLE
		Import-NxtIniFileWithComments -Path C:\path\to\ini\file.ini
	.NOTES
		AppDeployToolkit is required in order to run this function.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Path,
        [Parameter(Mandatory = $false)]
        [bool]
        $ContinueOnError = $true
    )
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		try {
			[hashtable]$ini = @{}
			[string]$section = 'default'
			[array]$commentBuffer = @()
			[Array]$content = Get-Content -Path $Path
			foreach ($line in $content) {
				if ($line -match '^\[(.+)\]$') {
					[string]$section = $matches[1]
					if (!$ini.ContainsKey($section)) {
						[hashtable]$ini[$section] = @{}
					}
				}
				elseif ($line -match '^(;|#)\s*(.*)') {
					[array]$commentBuffer += $matches[2].trim("; ")
				}
				elseif ($line -match '^(.+?)\s*=\s*(.*)$') {
					[string]$variableName = $matches[1]
					[string]$value = $matches[2].Trim()
					[hashtable]$ini[$section][$variableName] = @{
						Value    = $value.trim()
						Comments = $commentBuffer -join "`r`n"
					}
					[array]$commentBuffer = @()
				}
			}
			Write-Output $ini
		}
		catch {
			if (-not $ContinueOnError) {
				throw "Failed to read ini file [$path]: $($_.Exception.Message)"
			}
		}
	}
    End {}
}
#endregion
function Update-NxtPSAdtPackage {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PackageToUpdatePath,
        [Parameter(Mandatory=$true)]
        [string]$LatestVersionPath,
        [Parameter(Mandatory=$false)]
        [string]$LogFileName,
        [Parameter(Mandatory=$true)]
        [string]$CompatibleVersion,
        [Parameter(Mandatory=$true)]
        [string]$ConfigVersion
    )
    try {
    # test if both paths exist
    if (-not (Test-Path -Path $PackageToUpdatePath)) {
        throw "PackageToUpdatePath does not exist"
    }
    if (-not (Test-Path -Path $LatestVersionPath)) {
        throw "LatestVersionPath does not exist"
    }
    [string]$newVersionContent = Get-Content -Raw -Path "$LatestVersionPath\Deploy-Application.ps1"
    [string]$newVersion = (Get-NxtContentBetweenTags -Content $newVersionContent -StartTag "	Version: " -EndTag "	ConfigVersion:").TrimEnd("`n")
    if ($CompatibleVersion -eq "`#`#`R`E`P`L`A`C`E`V`E`R`S`I`O`N`#`#") {
        Write-Warning "CompatibleVersion is $CompatibleVersion, you are probably using a development version, skipping UpdateToolVersionCompatibilityCheck!"
        Write-Warning "Using $CompatibleVersion as CompatibleVersion might render the resulting package unfunctional, please use a properly built version instead!"
        Read-Host -Prompt "Press Enter to continue or CTRL+C to exit"
    }
    elseif ($newVersion -ne $CompatibleVersion) {
        throw "LatestVersion $newVersion is not compatible with $CompatibleVersion"
    }
    [string]$existingContent = Get-Content -Raw -Path "$PackageToUpdatePath\Deploy-Application.ps1"
    #check for Version -ge 2023.06.12.01-53
    if ($existingContent -match "ConfigVersion:") {
        [string]$version =(Get-NxtContentBetweenTags -Content $existingContent -StartTag "	Version: " -EndTag "	ConfigVersion:").TrimEnd("`n")
    } else {
        [string]$version = (Get-NxtContentBetweenTags -Content $existingContent -StartTag "	Version: " -EndTag "	Toolkit Exit Code Ranges:").TrimEnd("`n")
    }
    if ([int]($version -split "-")[1] -lt 53) {
        throw "Version of $PackageToUpdatePath is lower than 2023.06.12.01-53 and must be updated manually"
    }
    if ($version -eq $newVersion) {
        $versionInfo = " ... but seems already up-to-date (same version tag!)"
    } else {
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
            [string]$addContent = $null
            switch ($newcustomFunctionName) {
                "CustomReinstallPostUninstallOnError" {
                    $addContent = Add-ContentBeforeTag -Content $existingContent -StartTag "function CustomReinstallPostUninstall {" -ContentToInsert "function CustomReinstallPostUninstallOnError {
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
                    $addContent = Add-ContentBeforeTag -Content $existingContent -StartTag "function CustomReinstallPostInstall {" -ContentToInsert "function CustomReinstallPostInstallOnError {
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
                    $addContent = Add-ContentBeforeTag -Content $existingContent -StartTag "function CustomInstallEnd {" -ContentToInsert "function CustomInstallEndOnError {
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
                    $addContent = Add-ContentBeforeTag -Content $existingContent -StartTag "function CustomUninstallEnd {" -ContentToInsert "function CustomUninstallEndOnError {
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
            if (-not [string]::IsNullOrEmpty($addContent)) {
                Write-Output "... adding custom function: $newcustomFunctionName"
                Set-Content -Path "$PackageToUpdatePath\Deploy-Application.ps1" -Value $addContent -NoNewline
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

    ## re-read custom function names
    [string[]]$customFunctionNames = foreach ($line in ($existingContent -split "`n")){
        if ($line -match "function Custom") {
            $line -split " " | Select-Object -Index 1
        }
    }

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
    Copy-Item -Path "$LatestVersionPath\DeployNxtApplication.exe" -Destination "$PackageToUpdatePath\DeployNxtApplication.exe" -Force

            #also update packageconfig.json so it contains all default values
            ## remove entries: "AcceptedRepairExitCodes" and "AcceptedMSIRepairExitCodes" (just to be sure!)
            [string]$content = Get-Content -Raw -Path $PackageToUpdatePath\neo42PackageConfig.json
            $content = $content -Replace ('  "AcceptedRepairExitCodes": "",'+"`n"),''
            $content = $content -Replace ('  "AcceptedMSIRepairExitCodes": "",'+"`n"),''
            Set-Content -Path "$PackageToUpdatePath\neo42PackageConfig.json" -Value $content -NoNewline
            ## new entry: UninstallKeyContainsExpandVariables
            [string]$content = Get-Content -Raw -Path $PackageToUpdatePath\neo42PackageConfig.json
            [PSCustomObject]$jsonContent = $content | ConvertFrom-Json
            if ($null -eq $jsonContent.UninstallKeyContainsExpandVariables){
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "DisplayNamesToExcludeFromAppSearches"' -ContentToInsert '  "UninstallKeyContainsExpandVariables": false,
'
                Set-Content -Path "$PackageToUpdatePath\neo42PackageConfig.json" -Value $content -NoNewline
            }
            ## new entry: "ConfigVersion"
            [string]$content = Get-Content -Raw -Path $PackageToUpdatePath\neo42PackageConfig.json
            [PSCustomObject]$jsonContent = $content | ConvertFrom-Json
            if ($null -eq $jsonContent.ConfigVersion){
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "ScriptAuthor"' -ContentToInsert '  "ConfigVersion": "2023.10.31.1",
'
                Set-Content -Path "$PackageToUpdatePath\neo42PackageConfig.json" -Value $content -NoNewline
            }
            ## update entry: "ConfigVersion"
            [string]$PackageToUpdateContent = Get-Content -Raw -Path $PackageToUpdatePath\neo42PackageConfig.json
            [PSCustomObject]$PackageToUpdateJsonContent = $content | ConvertFrom-Json
            if ($PackageToUpdateJsonContent.ConfigVersion -ne $ConfigVersion){
                $PackageToUpdateContent = $PackageToUpdateContent -Replace ('  "ConfigVersion": "'+$PackageToUpdateJsonContent.ConfigVersion+'",'),('  "ConfigVersion": "'+$ConfigVersion+'",')
                Set-Content -Path "$PackageToUpdatePath\neo42PackageConfig.json" -Value $PackageToUpdateContent -NoNewline
            }
            ## Update App variable
            [string]$content = Get-Content -Raw -Path $PackageToUpdatePath\neo42PackageConfig.json
            [PSCustomObject]$jsonContent = $content | ConvertFrom-Json
            if ($jsonContent.App -notlike '*AppRootFolder*'){
                $content = Set-NxtContentBetweenTags -Content $content -StartTag '  "App": "' -EndTag ("`n" + '  "UninstallOld"') -ContentBetweenTags '$($global:PackageConfig.AppRootFolder)\\$($global:PackageConfig.appVendor)\\$($global:PackageConfig.AppName)\\$($global:PackageConfig.AppVersion)",'
                Set-Content -Path "$PackageToUpdatePath\neo42PackageConfig.json" -Value $content -NoNewline
            }
            ## Update InstLogFile variable
            [string]$content = Get-Content -Raw -Path $PackageToUpdatePath\neo42PackageConfig.json
            [PSCustomObject]$jsonContent = $content | ConvertFrom-Json
            if ($jsonContent.InstLogFile -notlike '*AppRootFolder*'){
                $content = Set-NxtContentBetweenTags -Content $content -StartTag '  "InstLogFile": "' -EndTag ("`n" + '  "UninstLogFile"') -ContentBetweenTags '$($global:PackageConfig.AppRootFolder)Logs\\$($global:PackageConfig.AppVendor)\\$($global:PackageConfig.AppName)\\$($global:PackageConfig.AppVersion)\\Install.$global:DeploymentTimestamp.log",'
                Set-Content -Path "$PackageToUpdatePath\neo42PackageConfig.json" -Value $content -NoNewline
            }
            ## Update UninstLogFile variable
            [string]$content = Get-Content -Raw -Path $PackageToUpdatePath\neo42PackageConfig.json
            [PSCustomObject]$jsonContent = $content | ConvertFrom-Json
            if ($jsonContent.UninstLogFile -notlike '*AppRootFolder*'){
                $content = Set-NxtContentBetweenTags -Content $content -StartTag '  "UninstLogFile": "' -EndTag ("`n" + '  "InstFile"') -ContentBetweenTags '$($global:PackageConfig.AppRootFolder)Logs\\$($global:PackageConfig.AppVendor)\\$($global:PackageConfig.AppName)\\$($global:PackageConfig.AppVersion)\\Uninstall.$global:DeploymentTimestamp.log",'
                Set-Content -Path "$PackageToUpdatePath\neo42PackageConfig.json" -Value $content -NoNewline
            }
            ## Add AppRootFolder variable
            [string]$content = Get-Content -Raw -Path $PackageToUpdatePath\neo42PackageConfig.json
            [PSCustomObject]$jsonContent = $content | ConvertFrom-Json
            if ($null -eq $jsonContent.AppRootFolder){
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "App"' -ContentToInsert '  "AppRootFolder" : "$($env:ProgramData)\\neo42Pkgs",
'
                Set-Content -Path "$PackageToUpdatePath\neo42PackageConfig.json" -Value $content -NoNewline
            }
            ## new entry: "AcceptedInstallRebootCodes"
            [string]$content = Get-Content -Raw -Path $PackageToUpdatePath\neo42PackageConfig.json
            [PSCustomObject]$jsonContent = $content | ConvertFrom-Json
            if ($null -eq $jsonContent.AcceptedInstallRebootCodes){
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "UninstFile"' -ContentToInsert '  "AcceptedInstallRebootCodes": "",
'
                Set-Content -Path "$PackageToUpdatePath\neo42PackageConfig.json" -Value $content -NoNewline
            }
            ## new entry: "AcceptedUninstallRebootCodes"
            [string]$content = Get-Content -Raw -Path $PackageToUpdatePath\neo42PackageConfig.json
            [PSCustomObject]$jsonContent = $content | ConvertFrom-Json
            if ($null -eq $jsonContent.AcceptedUninstallRebootCodes){
                $content = Add-ContentBeforeTag -Content $content -StartTag '  "AppKillProcesses"' -ContentToInsert '  "AcceptedUninstallRebootCodes": "",
'
                Set-Content -Path "$PackageToUpdatePath\neo42PackageConfig.json" -Value $content -NoNewline
            }
            ## rename : "-Ignore-ExitCodes to -AcceptedExitCodes in case it is in the same line as Execute-NxtMSI"
            [string]$content = Get-Content -Raw -Path "$PackageToUpdatePath\Deploy-Application.ps1"
            foreach ($line in ($content -split "`n")){
                if ($line -match "Execute-NxtMSI" -and $line -match "-IgnoreExitCodes") {
                    [bool]$contentChanged = $true
                    $content = $content.Replace($line, $line.Replace("-IgnoreExitCodes","-AcceptedExitCodes"))
                    Write-Warning "Replaced -IgnoreExitCodes with -AcceptedExitCodes in $PackageToUpdatePath in line: $line"
                }
            }
            if ($true -eq $contentChanged) {
                Set-Content -Path "$PackageToUpdatePath\Deploy-Application.ps1" -Value $content -NoNewline
                [bool]$contentChanged = $false
            }
            ## check for MINMIZEALLWINDOWS in setup.cfg
            [string]$content = Get-Content -Raw -Path "$PackageToUpdatePath\setup.cfg"
            if ($content -like "*MINMIZEALLWINDOWS*") {
                $content = $content -replace "MINMIZEALLWINDOWS","MINIMIZEALLWINDOWS"
                Set-Content -Path "$PackageToUpdatePath\setup.cfg" -Value $content -NoNewline
            }
            ## check setup.cfg default parameters
            [bool]$missingIniValues = $true
            while ($true -eq $missingIniValues) {
                [psobject]$iniToUpdate=Import-NxtIniFileWithComments -Path "$PackageToUpdatePath\setup.cfg"
                [psobject]$iniLatest=Import-NxtIniFileWithComments -Path "$LatestVersionPath\setup.cfg"
                [bool]$missingIniValues = $false
                foreach ($section in $iniLatest.Keys) {
                    foreach ($key in ($iniLatest.$section.Keys|Where-Object {$_ -ne "DesktopShortcut"})) {
                        if ($null -eq $iniToUpdate.$section.$key) {
                            Write-Warning "Missing key $key in section $section in $PackageToUpdatePath\setup.cfg, Please Add:"
                            foreach ($comment in $iniLatest.$section.$key.Comments) {
                                Write-Output ";$comment"
                            }
                            Write-Output "$key=$($iniLatest.$section.$key.Value)"
                            [bool]$missingIniValues = $true
                        }
                    }
                }
                if ($true -eq $missingIniValues) {
                    Write-Warning "Please add the missing values to $PackageToUpdatePath\setup.cfg"
                    Write-Output "Press Enter to open $PackageToUpdatePath\setup.cfg in notepad or CTRL+C to exit"
                    Read-Host
                    notepad.exe "$PackageToUpdatePath\setup.cfg"
                    Read-Host "Press to check again or CTRL+C to exit"
                }
            }
        }
        catch {
            Write-Error "$PackageToUpdatePath could not be updated from $LatestVersionPath - $_"
            Add-Content -Path "$PSscriptRoot\$LogFileName" -Value "Failed to update $PackageToUpdatePath"
        }
    }
[string]$logFileName = (Get-Date -format "yyyy-MM-dd_HH-mm-ss") + "_UpdateNxtPSAdtPackage." + "log"
$PackagesToUpdatePath = $PackagesToUpdatePath.Trim("`"`'")
$LatestVersionPath = $LatestVersionPath.Trim("`"`'")
$ConfigVersion = "2023.10.31.1"
Get-ChildItem -Recurse -Path $PackagesToUpdatePath -Filter "Deploy-Application.ps1" | ForEach-Object {
   Update-NxtPSAdtPackage -PackageToUpdatePath $_.Directory.FullName -LatestVersionPath $LatestVersionPath -LogFileName $logFileName -CompatibleVersion $CompatibleVersion -ConfigVersion $ConfigVersion
} 
Read-Host -Prompt "Press Enter to exit"
