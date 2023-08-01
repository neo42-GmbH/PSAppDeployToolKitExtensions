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
    ## what is now "User" must be equal to $global:userPartDir in Deploy-Application.ps1
    $folderToRemove = @("$PSScriptRoot\neo42-Install","$PSScriptRoot\neo42-Source","$PSScriptRoot\User" )

    foreach ($folder in $folderToRemove) {
        if (Test-Path -Path $folder) {
            Remove-Item -Path $folder -Recurse -Force
        }
    }
}
finally {
    Remove-Item $currentScript -Force
}