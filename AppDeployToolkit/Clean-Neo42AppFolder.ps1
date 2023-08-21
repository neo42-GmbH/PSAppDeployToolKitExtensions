<#
.SYNOPSIS
	This script cleans the $app folder of a neo42 package installation
.LINK
	https://neo42.de/psappdeploytoolkit
#>
[CmdletBinding()]
Param (
)
$currentScript = $MyInvocation.MyCommand.Definition
try {
    Start-Sleep -Seconds 10
    ## read neo42PackageConfig.json to determine if user uninstall is enabled
    $packageConfig = Get-Content -Path "$PSScriptRoot\neo42-Install\neo42PackageConfig.json" | Out-String | ConvertFrom-Json
    $folderToRemove = @("$PSScriptRoot\neo42-Install", "$PSScriptRoot\neo42-Source")
    if ($true -eq $packageConfig.UserPartOnUninstallation) {
        ## due to an active user part on UnInstallation, we must keep the userpart folder.
    }
    else {
        ## what is now "User" must be equal to $global:userPartDir in Deploy-Application.ps1
        $folderToRemove += "$PSScriptRoot\User"
    }
    foreach ($folder in $folderToRemove) {
        if (Test-Path -Path $folder) {
            Remove-Item -Path $folder -Recurse -Force
        }
    }
}
finally {
    Remove-Item $currentScript -Force
}