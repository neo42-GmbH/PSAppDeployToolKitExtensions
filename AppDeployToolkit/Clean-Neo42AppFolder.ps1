<#
    .SYNOPSIS
        This script cleans the $app folder of a neo42 package installation
    .NOTES
        # LICENSE #
        This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
        You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

        # COPYRIGHT #
        Copyright (c) 2023 neo42 GmbH, Germany.
    .LINK
        https://neo42.de/psappdeploytoolkit
#>
[CmdletBinding()]
Param (
)
$currentScript = $MyInvocation.MyCommand.Definition
try {
    Start-Sleep -Seconds 10
    $packageConfig = Get-Content -Path "$PSScriptRoot\neo42-Install\neo42PackageConfig.json" | Out-String | ConvertFrom-Json
    $folderToRemove = @("$PSScriptRoot\neo42-Install", "$PSScriptRoot\neo42-Source")
    if ($true -eq $packageConfig.UserPartOnUninstallation) {
        ## due to an active UserPart on UnInstallation, we must keep userPartDir.
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