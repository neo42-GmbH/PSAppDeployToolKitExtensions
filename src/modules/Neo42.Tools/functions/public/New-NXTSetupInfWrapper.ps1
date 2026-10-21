function New-NXTSetupInfWrapper {
	<#
	.SYNOPSIS
	This function applies the Setup.inf wrapper to a given (or current) directory.
	A Setup.inf file is generated and the folder structure is adjusted so that the package is prepared for import into Empirum.
	.PARAMETER LocalWrapperPath
	Provide a local path to a custom wrapper file.
	If this parameter is not provided, the script will download the latest wrapper from neo42.
	.PARAMETER Move
	Instead of creating a copy of the package, move it instead.
	This will remove the old package format.
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
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Not implemented')]
	[CmdletBinding()]
	param (
		[System.IO.DirectoryInfo]
		$Package = $PWD.Path,
		[ValidateScript({ $_.Exists })]
		[System.IO.DirectoryInfo]
		$LocalWrapperPath,
		[System.Management.Automation.SwitchParameter]
		$Move,
		[System.IO.DirectoryInfo]
		$Output = "$($Package.Parent.FullName)\$($Package.BaseName)_SetupInf",
		[System.Version]
		$FrameworkVersion = '4.0'
	)

	Set-StrictMode -Version 3.0
	$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
	$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue

	## Define basic variables
	[System.String]$adtSubFolder = "$($Output.FullName)\PSADT"
	[System.Uri]$wrapperUrl = 'https://portal.neo42.de/api/v2/app/SetupInfWrapper/Latest'
	[System.String]$wrapperPath = "$($Output.FullName)\SetupInfWrapper.zip"
	[System.String]$jsonPath = "$adtSubFolder\neo42PackageConfig.json"
	[System.String]$infPath = "$($Output.FullName)\neoInstall\Setup.inf"
	[System.String]$expandDirectory = [System.IO.Path]::Combine($Output.FullName, 'tmp')
	[System.String]$versionDirectory = [System.IO.Path]::Combine($expandDirectory, $FrameworkVersion.ToString())

	## Test for some basic requirements
	'Deploy-Application.ps1', 'neo42PackageConfig.json', 'Setup.ico' | ForEach-Object {
		if (-not (Test-Path (Join-Path $($Package.FullName) $_))) {
			Write-Error "[$_] does not exist. This script is designed to work with proper neo42 APD packages. Abort!"
		}
	}

	## Create the PSADT folder
	$null = New-Item -ItemType Directory -Path $adtSubFolder -Force

	## Iterate through each item (file or folder) in the current directory and move it to the PSADT folder
	Write-Host "Moving all package files to [$adtSubFolder]"
	Get-ChildItem -LiteralPath $($Package.FullName) -Exclude $adtSubFolder | ForEach-Object {
		if ($Move) {
			Move-Item -Path $_.FullName -Destination $adtSubFolder -Force
		}
		else {
			Copy-Item -Path $_.FullName -Destination $adtSubFolder -Force -Recurse
		}
	}

	if (-not $PSBoundParameters.ContainsKey('LocalWrapperPath')) {
		Write-Host 'No local wrapper path provided. Downloading the latest wrapper from neo42.'
		## Download the latest wrapper from neo42
		Write-Host "Download latest wrapper from [$wrapperUrl]"
		[System.Management.Automation.PSObject]$latestWrapper = Invoke-RestMethod -Uri $wrapperUrl -Method Get

		## Write wrapper to disk as zip file
		Write-Host "Write wrapper to disk as zip file '$wrapperPath'"
		[System.IO.File]::WriteAllBytes($wrapperPath, [System.Convert]::FromBase64String($latestWrapper.Wrapper))

		## Validate the computed hash against the WrapperHash
		Write-Host 'Validate wrapper SHA512 hash'
		if ((Get-FileHash -LiteralPath $wrapperPath -Algorithm SHA512).Hash -ne $latestWrapper.WrapperHash) {
			throw 'Wrapper hash validation failed. Download was not successful. Abort!'
		}
	}
	else {
		Write-Host "Using local wrapper from [$LocalWrapperPath]"
		Copy-Item -Path $LocalWrapperPath.FullName -Destination $Output.FullName
		$wrapperPath = [System.IO.Path]::Combine($Output.FullName, $LocalWrapperPath.BaseName)
	}

	## Extract the archive to the working directory
	Write-Host 'Extract the wrapper to the working directory'
	Expand-Archive -Path $wrapperPath -DestinationPath $expandDirectory -Force
	Move-Item -Path $versionDirectory -Destination $Output.FullName
	Remove-Item -Path $wrapperPath, $expandDirectory -Recurse

	## Parse the json content
	Write-Host "Load the input data from [$jsonPath]"
	[System.Management.Automation.PSObject]$jsonContent = ConvertFrom-Json -InputObject (Get-Content -LiteralPath $jsonPath -Raw)

	## Load the inf content and replace placeholders with values from the json
	Write-Host "Apply the input data to [$infPath]"
	[System.String]$textContent = Get-Content -Path $infPath -Raw
	foreach ($property in $jsonContent.PSObject.Properties) {
		[System.String]$placeholderPattern = [System.Text.RegularExpressions.Regex]::Escape("!$($property.Name)!")
		[System.String]$value = if ($property.TypeNameOfValue -eq 'System.Boolean') { $property.Value.ToInt32($null).ToString() } else { $property.Value.ToString() }
		if ($property.Name -ieq 'AppArch' -and $value -ine 'x64') { $value = '*' }
		$textContent = $textContent -replace $placeholderPattern, $value
	}

	## Validate that all placeholders have been replaced
	Write-Host 'Test if all placeholders have been replaced'
	if ($textContent -match '![\w]+!') {
		throw "Not all placeholders have been replaced. Remaining placeholders are: $Matches"
	}

	# Write the new inf content to disk
	Write-Host 'Write the new inf content to disk'
	Set-Content -Path $infPath -Value $textContent -Encoding UTF8

	## Copy ico File to neoInstall Folder
	Write-Host 'Copy ico file to neoInstall folder'
	Copy-Item -Path "$adtSubFolder\Setup.ico" -Destination "$($Output.FullName)\neoInstall\Setup.ico" -Force

	## Self destruct the current script
	Write-Host 'Wrapper successfully created!'
}
