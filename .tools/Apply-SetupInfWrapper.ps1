<#
.SYNOPSIS
This script applies the Setup.inf wrapper to the current directory.
Place this script at the root of a created package and run it via PowerShell.
A Setup.inf file is generated and the folder structure is adjusted so that the package is prepared for import into Empirum.
The script will remove itself once completed.
.PARAMETER LocalWrapperPath
Provide a local path to a custom wrapper file.
If this parameter is not provided, the script will download the latest wrapper from neo42.
.NOTES
# LICENSE #
This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

# COPYRIGHT #
Copyright (c) 2026 neo42 GmbH, Germany.
.LINK
https://neo42.de/psappdeploytoolkit
#>
[CmdletBinding()]
param (
	[ValidateScript({ $_.Exists })]
	[System.IO.DirectoryInfo]
	$LocalWrapperPath
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue

## Define basic variables
[System.String]$adtSubFolder = "$PSScriptRoot\PSADT"
[System.Uri]$wrapperUrl = 'https://portal.neo42.de/api/app/SetupInfWrapper/Latest'
[System.String]$wrapperPath = "$PSScriptRoot\SetupInfWrapper_{VERSION}.zip"
[System.String]$jsonPath = "$adtSubFolder\neo42PackageConfig.json"
[System.String]$infPath = "$PSScriptRoot\neoInstall\Setup.inf"

## Create some help output
Write-Output @'
neo42 GmbH - Apply Setup.inf Wrapper to APD package

This script applies the Setup.inf wrapper to the current directory.
The current directory is expected to be an APD based package.
It will download the latest wrapper from neo42, or use the provided wrapper, and apply it to the current directory.
The script will self destruct after execution - so make sure you are using a copy of this script.

Press any key to continue or CTRL+C to abort.
'@
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

## Test for some basic requirements
'Deploy-Application.ps1', 'neo42PackageConfig.json', 'Setup.ico' | ForEach-Object {
	if (-not (Test-Path (Join-Path $PSScriptRoot $_))) {
		Write-Error "[$_] does not exist. This script is designed to work with proper neo42 APD packages. Abort!"
	}
}

## Create the PSADT folder
$null = New-Item -ItemType Directory -Path $adtSubFolder -Force

## Iterate through each item (file or folder) in the current directory and move it to the PSADT folder
Write-Output "Moving all package files to [$adtSubFolder]"
Get-ChildItem -LiteralPath $PSScriptRoot -Exclude $PSCommandPath, $adtSubFolder | ForEach-Object {
	Move-Item -Path $_.FullName -Destination $adtSubFolder -Force
}

if (-not $PSBoundParameters.Contains('Wrapper')) {
	Write-Output 'No local wrapper path provided. Downloading the latest wrapper from neo42.'
	## Download the latest wrapper from neo42
	Write-Output "Download latest wrapper from [$wrapperUrl]"
	[System.Management.Automation.PSObject]$latestWrapper = Invoke-RestMethod -Uri $wrapperUrl -Method Get

	$wrapperPath = $wrapperPath -replace '{VERSION}', $latestWrapper.Version
	## Write wrapper to disk as zip file
	Write-Output "Write wrapper to disk as zip file '$wrapperPath'"
	[System.IO.File]::WriteAllBytes($wrapperPath, [System.Convert]::FromBase64String($latestWrapper.Wrapper))

	## Validate the computed hash against the WrapperHash
	Write-Output 'Validate wrapper SHA512 hash'
	if ((Get-FileHash -LiteralPath $wrapperPath -Algorithm SHA512).Hash -ne $latestWrapper.WrapperHash) {
		Write-Error 'Wrapper hash validation failed. Download was not successful. Abort!'
	}
}
else {
	Write-Output "Using local wrapper from [$LocalWrapperPath]"
	Copy-Item -Path $LocalWrapperPath.FullName -Destination $PSScriptRoot
	$wrapperPath = [System.IO.Path]::Combine($PSScriptRoot, $LocalWrapperPath.BaseName)
}

## Extract the archive to the working directory
Write-Output 'Extract the wrapper to the working directory'
Expand-Archive -Path $wrapperPath -DestinationPath $PSScriptRoot -Force

## Remove the archive
Write-Output 'Remove the wrapper archive'
Remove-Item -Path $wrapperPath

## Parse the json content
Write-Output "Load the input data from '$jsonPath'"
[System.Management.Automation.PSObject]$jsonContent = ConvertFrom-Json -InputObject (Get-Content -Path $jsonPath -Raw)

## Load the inf content and replace placeholders with values from the json
Write-Output "Apply the input data to '$infPath'"
[System.String]$textContent = Get-Content -Path $infPath -Raw
foreach ($property in $jsonContent.PSObject.Properties) {
	[System.String]$placeholderPattern = [System.Text.RegularExpressions.Regex]::Escape("!$($property.Name)!")
	[System.String]$value = if ($property.TypeNameOfValue -eq 'System.Boolean') { $property.Value.ToInt32($null).ToString() } else { $property.Value.ToString() }
	if ($property.Name -ieq 'AppArch' -and $value -ine 'x64') { $value = '*' }
	$textContent = $textContent -replace $placeholderPattern, $value
}

## Validate that all placeholders have been replaced
Write-Output 'Test if all placeholders have been replaced'
if ($textContent -match '![\w]+!') {
	Write-Error "Not all placeholders have been replaced. Remaining placeholders are: $Matches"
}

# Write the new inf content to disk
Write-Output 'Write the new inf content to disk'
Set-Content -Path $infPath -Value $textContent -Encoding UTF8

## Copy ico File to neoInstall Folder
Write-Output 'Copy ico file to neoInstall folder'
Copy-Item -Path "$adtSubFolder\Setup.ico" -Destination "$workingDir\neoInstall\Setup.ico" -Force

## Self destruct the current script
Write-Output 'Wrapper successfully created! Removing the current script in 5 seconds.....'
Start-Sleep -Seconds 5
Remove-Item $PSCommandPath -Force
