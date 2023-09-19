<#
    .SYNOPSIS
        This script applies the Setup.inf wrapper to the current directory.
    .LINK
        https://neo42.de/psappdeploytoolkit
#>
[CmdletBinding()]
Param (
)

[string]$workingDir = $PSScriptRoot
if([string]::IsNullOrEmpty($workingDir) -or $true -ne [System.IO.Directory]::Exists($workingDir)) {
    Write-Warning "Failed to detect working directory. Abort!"
    Exit
}

## Define basic variables
[string]$scriptName = "ApplySetupInfWrapper.ps1"
[string]$adtSubFolder = "$workingDir\PSADT"
[string]$wrapperUrl = "https://adtdev.neo42.de/api/app/SetupInfWrapper/Latest"
[string]$wrapperPath = "$workingDir\SetupInfWrapper_{VERSION}.zip"
[string]$jsonPath = "$adtSubFolder\neo42PackageConfig.json"
[string]$infPath = "$workingDir\neoInstall\Setup.inf"

## Create some help output
Write-Output "neo42 GmbH - Apply Setup.inf Wrapper to APD package"
Write-Output ""
Write-Output "This script applies the Setup.inf wrapper to the current directory."
Write-Output "The current directory is expected to be an APD based package."
Write-Output "The script will download the latest wrapper from neo42 and apply it to the current directory."
Write-Output "The script will self destruct after execution - so make sure you are using a copy of this script."
Write-Output ""
Write-Output "Press any key to continue or CTRL+C to abort."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Output ""

## Test for some basic requirements
[array]$files = @("Deploy-Application.ps1", "neo42PackageConfig.json", "neo42PackageConfigValidationRules.json", "AppDeployToolkit\AppDeployToolkitExtensions.ps1", "AppDeployToolkit\AppDeployToolkitMain.ps1")
$files | ForEach-Object {
    if ($false -eq (Test-Path (Join-Path $workingDir $_))) {
        Write-Warning "$_ does not exist. This script is designed to work with proper neo42 APD packages. Abort!"
        Start-Sleep -Seconds 5
        Exit
    }
}

## Create the PSADT folder if it doesn't exist
if (-not (Test-Path $adtSubFolder)) {
    New-Item -ItemType Directory -Path $adtSubFolder | Out-Null
}

## Iterate through each item (file or folder) in the current directory and move it to the PSADT folder
Write-Output "Moving all package files to '$adtSubFolder'"
Get-ChildItem -Path $workingDir | ForEach-Object {
    if ($_.Name -ne $scriptName -and $_.Name -ne $adtSubFolder) {
        Move-Item -Path $_.FullName -Destination $adtSubFolder -ErrorAction SilentlyContinue
    }
}

## Download the latest wrapper from neo42
Write-Output "Download latest wrapper from '$wrapperUrl'"
[PsObject]$latestWrapper = Invoke-RestMethod -Uri $wrapperUrl -Method Get
$wrapperPath = $wrapperPath -Replace "{VERSION}", $latestWrapper.Version

## Write wrapper to disk as zip file
Write-Output "Write wrapper to disk as zip file '$wrapperPath'"
[byte[]]$decodedBytes = [System.Convert]::FromBase64String($latestWrapper.Wrapper)
[System.IO.File]::WriteAllBytes($wrapperPath, $decodedBytes)

## Compute the SHA512 hash of the file
Write-Output "Validate wrapper SHA512 hash"
[byte[]]$fileBytes = [System.IO.File]::ReadAllBytes($wrapperPath)
[PsObject]$sha512 = [System.Security.Cryptography.SHA512]::Create()
[byte[]]$hashBytes = $sha512.ComputeHash($fileBytes)

## Convert the hash bytes to a hexadecimal string
[string]$computedHash = [BitConverter]::ToString($hashBytes) -replace '-'

## Validate the computed hash against the WrapperHash
if ($computedHash -ne $latestWrapper.WrapperHash) {
    Write-Warning "Wrapper hash validation failed. Download was not successful. Abort!"
    Start-Sleep -Seconds 5
    Exit
}

## Extract the archive to the working directory
Write-Output "Extract the wrapper to the working directory"
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($wrapperPath, $workingDir)

## Remove the archive
Write-Output "Remove the wrapper archive"
Remove-Item -Path $wrapperPath

## Parse the json content
Write-Output "Load the input data from '$jsonPath'"
[PsObject]$jsonContent = Get-Content -Path $jsonPath | ConvertFrom-Json

## Load the inf content and replace placeholders with values from the json
Write-Output "Apply the input data to '$infPath'"
[string]$textContent = Get-Content -Path $infPath -Raw
foreach ($property in $jsonContent.PSObject.Properties) {
    $placeholder = "!" + $property.Name + "!"
    $value = [string]$property.Value
    $pattern = [regex]::Escape($placeholder)
    $textContent = [regex]::Replace($textContent, $pattern, $value, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

## Validate that all placeholders have been replaced
Write-Output "Test if all placeholders have been replaced"
[System.Text.RegularExpressions.MatchCollection]$unmatchedPlaceholders = [regex]::Matches($textContent, "![\w]+!")
if ($unmatchedPlaceholders.Count -gt 0) {
    Write-Warning "Not all placeholders have been replaced. Remaining placeholders are:"
    $unmatchedPlaceholders | ForEach-Object { Write-Warning $_.Value }
    Start-Sleep -Seconds 5
    Exit
}

# Write the new inf content to disk
Write-Output "Write the new inf content to disk"
Set-Content -Path $infPath -Value $textContent -Encoding UTF8

## Self destruct the current script
Write-Output ""
Write-Output "Wrapper successfully created! Removing the current script in 5 seconds....."
Start-Sleep -Seconds 5
Remove-Item $MyInvocation.MyCommand.Definition -Force