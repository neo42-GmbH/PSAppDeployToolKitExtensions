<#
	.SYNOPSIS
		Merges the PSADT with a package and performs migration tasks.
	.PARAMETER PackagePath
		The path to the package that should be merged with a new version of the the PSADT.
	.PARAMETER PSADTPath
		The path to the PSADT that should be merged with the package. 
		By default the value is the parent directory of this script.
	.PARAMETER OutputPath
		The path to the directory where the merged package should be saved. 
		By default a copy will be create next to the source package with the suffix '_Updated'.
	.PARAMETER ConfigVersion
		The version number that should be used to update the package configuration.
	.NOTES
		# LICENSE #
		This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
		You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

		# COPYRIGHT #
		Copyright (c) 2024 neo42 GmbH, Germany.
#>
Param (
	[Parameter(Mandatory = $true)]
	[ValidateScript({ $_.Exists })]
	[System.IO.DirectoryInfo]
	$PackagePath,
	[Parameter(Mandatory = $true)]
	[ValidateScript({ $_.Exists })]
	[System.IO.DirectoryInfo]
	$PSADTPath,
	[Parameter(Mandatory = $false)]
	[string]
	$ConfigVersion = "2023.10.31.1"
)

#region Configuration
## Minimum build version of the PSADT that is compatible with this script
[int]$minimumCompatibleBuild = 53

## Files that should be copied from the PSADT to the packge directory. Migration tasks will be performed on these files afterwards. Order is important if files are supposed to be overwritten.
$copyFromPSADT = @(
	"AppDeployToolkit",
	"COPYING",
	"COPYING.Lesser",
	"README.txt",
	"DeployNxtApplication.exe",
	"neo42PackageConfigValidationRules.json"
)

## Functions that should be migrated to the new PSADT name format
$functionNameMigrations = @{
	"CustomInstallAndReinstallBegin" = "CustomInstallAndReinstallAndSoftMigrationBegin"
}

## Configuration options that should be added to the package configuration if they are missing or replaced if they match a pattern
$addConfigOptionWhenMissing = @(
	@{
		Property = "UninstallKeyContainsExpandVariables"
		Value    = $false
		Before   = "DisplayNamesToExcludeFromAppSearches"
	},
	@{
		Property = "ConfigVersion"
		Value    = $ConfigVersion
		Before   = "ScriptAuthor"
	},
	@{
		Property = "AppRootFolder"
		Value    = "neo42Pkgs"
		Before   = "App"
	},
	@{
		Property = "AcceptedInstallRebootCodes"
		Value    = ""
		Before   = "UninstFile"
	},
	@{
		Property = "AcceptedUninstallRebootCodes"
		Value    = ""
		Before   = "AppKillProcesses"
	}
)
$replaceConfigOptionOnPatternMatch = @(
	@{
		Property = "ConfigVersion"
		Value    = "$ConfigVersion"
		Pattern  = "^((?!$([Regex]::Escape($ConfigVersion))).)*$"
	},
	@{
		Property = "App"
		Value    = '$($global:PackageConfig.AppRootFolder)\$($global:PackageConfig.appVendor)\$($global:PackageConfig.AppName)\$($global:PackageConfig.AppVersion)'
		Pattern  = "^((?!AppRootFolder).)*$"
	},
	@{
		Property = "InstLogFile"
		Value    = '$($global:AppLogFolder)\Install.$global:DeploymentTimestamp.log'
		Pattern  = "^((?!AppLogFolder).)*$"
	},
	@{
		Property = "UninstLogFile"
		Value    = '$($global:AppLogFolder)\Uninstall.$global:DeploymentTimestamp.log'
		Pattern  = "^((?!AppLogFolder).)*$"
	},
	@{
		Property = "AppRootFolder"
		Value    = "neo42Pkgs"
		Pattern  = "^((?!neo42Pkgs).)*$"
	}
	@{
		Property = "Reboot"
		Value    = 0
		Pattern  = "[^01]"
	}
)
$removeConfigOptionWhenFound = @(
	"AcceptedRepairExitCodes"
)

## Regex replacements
$regexReplacements = @(
	@{
		File        = "Deploy-Application.ps1"
		Pattern     = "## executes at after the uninstallation in the reinstall process"
		Replacement = "## executes after the successful uninstallation in the reinstall process"
	},
	@{
		File        = "Deploy-Application.ps1"
		Pattern     = "## executes after the installation in the reinstall process"
		Replacement = "## executes after the successful installation in the reinstall process"
	},
	@{
		File        = "Deploy-Application.ps1"
		Pattern     = "## executes after the installation in the install process\s*"
		Replacement = "## executes after the successful installation in the install process"
	},
	@{
		File        = "Deploy-Application.ps1"
		Pattern     = "## executes after the uninstallation in the uninstall process\s*"
		Replacement = "## executes after the successful uninstallation in the uninstall process"
	},
	@{
		File        = "Deploy-Application.ps1"
		Pattern     = "installPhase = 'CustomPostInstallAndReinstall'"
		Replacement = "installPhase = 'CustomInstallAndReinstallEnd"
	},
	@{
		File        = "Deploy-Application.ps1"
		Pattern     = "(?<=Execute-NxtMSI.*)-IgnoreExitCodes"
		Replacement = "-AcceptedExitCodes"
	},
	@{
		File        = "Deploy-Application.ps1"
		Pattern     = "Close-BlockExecutionWindow(?=\b)"
		Replacement = "Close-NxtBlockExecutionWindow"
	},
	@{
		File        = "Deploy-Application.ps1"
		Pattern     = "(\`$global:|\$)DetectedDisplayVersion(?=\b)(?!.*\=)"
		Replacement = "(Get-NxtCurrentDisplayVersion).DisplayVersion"
	}
	@{
		File        = "Setup.cfg"
		Pattern     = "(<?\b)MINMIZEALLWINDOWS(?=\b)"
		Replacement = "MINIMIZEALLWINDOWS"
	}
	@{
		File        = "neo42PackageConfig.json"
		Pattern     = "\s*`"AcceptedRepairExitCodes`":\s*`"`",`n"
		Replacement = ""
	},
	@{
		File        = "neo42PackageConfig.json"
		Pattern     = "\s*`"AcceptedMSIRepairExitCodes`":\s*`"`",`n"
		Replacement = ""
	}
)

## Error when Regex pattern is found
$regexErrors = @(
	@{
		File        = "Deploy-Application.ps1"
		Pattern     = "(\`$global:|\$)DetectedDisplayVersion(?=\b)"
	}
)

#endregion



#region Functions
function Convert-PSObjectToOrderedDictionary {
	Param (
		[Parameter(Mandatory, ValueFromPipeline)]
		$InputObject
	)
	Process {
		if ($null -eq $InputObject) { return $null }

		if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
			$collection = @(
				foreach ($object in $InputObject) { Convert-PSObjectToOrderedDictionary -InputObject $object }
			)
			Write-Output -NoEnumerate $collection
		}
		elseif ($InputObject -is [psobject]) {
			[System.Collections.Specialized.OrderedDictionary]$dict = @{}
			foreach ($property in $InputObject.PSObject.Properties) {
				$dict.Add($property.Name, (Convert-PSObjectToOrderedDictionary -InputObject $property.Value))
			}
			Write-Output $dict
		}
		else {
			Write-Output $InputObject
		}
	}
}
function Format-Json {
	Param(
		[Parameter(Mandatory, ValueFromPipeline)]
		[String]
		$json
	)
	$indent = 0;
	($json -Split "`n" | ForEach-Object {
		if ($_ -match '[\}\]]\s*,?\s*$') {
			# This line ends with ] or }, decrement the indentation level
			$indent--
		}
		$line = ('	' * $indent) + $($_.TrimStart() -replace '":  (["{[])', '": $1' -replace ':  ', ': ')
		if ($_ -match '[\{\[]\s*$') {
			# This line ends with [ or {, increment the indentation level
			$indent++
		}
		$line
	}) -join "`n" -replace '(?m)\[[\s\n\r]+\]', '[]' -replace '(?m)\{[\s\n\r]+\}', '{}'
}
function Import-NxtIniFileWithComments {
	Param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[String]
		$Path,
		[Parameter(Mandatory = $false)]
		[bool]
		$ContinueOnError = $true
	)
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
}
#endregion

#region Definitions
## Create a template object from the PSADT source files
[PSCustomObject]$template = @{
	Files = @{
		DeployApplication	= $PSADTPath.GetFiles("Deploy-Application.ps1")
		PackageConfig		= $PSADTPath.GetFiles("neo42PackageConfig.json")
	}
	Ast   = @{
		Script = [System.Management.Automation.Language.Parser]::ParseFile($PSADTPath.GetFiles("Deploy-Application.ps1").FullName, [ref]$null, [ref]$null)
	}
}
$template.Ast.CustomFunctions = $template.Ast.Script.FindAll({
		$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
		$args[0].Name -match "^Custom[A-Z]"
	}, $false)
$template.Version = $template.Ast.Script.GetHelpContent().Notes | Select-String -Pattern '\s*Version:\s*(?<Version>.*)' | Select-Object -First 1 -ExpandProperty Matches | Select-Object -ExpandProperty Groups | Where-Object { $_.Name -eq "Version" } | Select-Object -ExpandProperty Value

## Import the package information
[PSCustomObject]$package = @{
	Files = @{
		DeployApplication	= $PackagePath.GetFiles("Deploy-Application.ps1")
		PackageConfig		= $PackagePath.GetFiles("neo42PackageConfig.json")
	}
	Ast   = @{
		Script = [System.Management.Automation.Language.Parser]::ParseFile($PackagePath.GetFiles("Deploy-Application.ps1").FullName, [ref]$null, [ref]$null)
	}
}
$package.Ast.CustomFunctions = $package.Ast.Script.FindAll({
		$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
		$args[0].Name -match "^Custom[A-Z]"
	}, $false)
$package.Version = $template.Ast.Script.GetHelpContent().Notes | Select-String -Pattern '\s*Version:\s*(?<Version>.*)' | Select-Object -First 1 -ExpandProperty Matches | Select-Object -ExpandProperty Groups | Where-Object { $_.Name -eq "Version" } | Select-Object -ExpandProperty Value
#endregion

#region Version checks
Write-Host @"

###################
## Version check ##
###################
"@
[string]$versionRegex = '^(?<year>\d{4})\.(?<month>\d{1,2})\.(?<day>\d{1,2})\.(?<revision>\d+)\-(?<build>\d+)$'
if ($template.Version -notmatch $versionRegex) {
	Write-Host -ForegroundColor Yellow "The version number '$($template.Version)' in the new PSADT does not match the expected pattern. Press Enter to continue anyway. Press Ctrl+C to cancel."
	Read-Host
}
elseif ($package.Version -notmatch $versionRegex) {
	Write-Host -ForegroundColor Yellow "The version number '$($package.Version)' in the source package does not match the expected pattern. Do you want to continue anyway?"
	Read-Host
}
else {
	[int]$packageBuild = $package.Version | Select-String -Pattern $versionRegex | Select-Object -First 1 -ExpandProperty Matches | Select-Object -ExpandProperty Groups | Where-Object { $_.Name -eq "build" } | Select-Object -ExpandProperty Value
	if ($packageBuild -lt $minimumCompatibleBuild) {
		throw "The source package build number ($packageBuild) is lower than the minimum compatible build number ($minimumCompatibleBuild). Please update the source package manually."
	}
	else {
		Write-Host "The source package build number ($packageBuild) is compatible with the minimum build number ($minimumCompatibleBuild)."
	}
}
Write-Host -ForegroundColor Green "Finished version check."
#endregion

#region Copy jobs
Write-Host @"

###############
## Copy jobs ##
###############
"@
$copyFromPSADT | ForEach-Object {
	Write-Host "Copying '$($_)' from the PSADT"
	Copy-Item -Path (Join-Path $PSADTPath.FullName $_) -Destination (Join-Path $PackagePath.FullName $_) -Recurse -Force
}
Write-Host -ForegroundColor Green "Finished copying files."
#endregion

#region Function migration
Write-Host @"

########################
## Function migration ##
########################
"@
[string]$deployApplicationContent = Get-Content -Raw -Path $template.Ast.Script.Extent.Text
[string[]]$migratableFunctionNames = $template.Ast.CustomFunctions.Name + $functionNameMigrations.Keys

## Check if all functions are present in the PSADT template or the configuration
[string[]]$functionNamesNotInPSADTOrConfig = $package.Ast.CustomFunctions.Name | Where-Object { $_ -notin $migratableFunctionNames }
if ($functionNamesNotInPSADTOrConfig.Count -gt 0) {
	Write-Host -ForegroundColor Red "The following functions are not present in the PSADT template or the configuration: $($functionNamesNotInPSADTOrConfig -join ", "). Please add them manually to the output copy."
}

## Migrate the functions to the new PSADT name format
foreach ($functionName in $template.Ast.CustomFunctions.Name) {
	[System.Management.Automation.Language.FunctionDefinitionAst]$functionSource = $null
	if ($package.Ast.CustomFunctions.Name -contains $functionName) {
		Write-Host "Migrating '$functionName'"
		$functionSource = $package.Ast.CustomFunctions | Where-Object { $_.Name -eq $functionName }
	}
	elseif (
		$functionNameMigrations.Values -contains $functionName -and 
		$package.Ast.CustomFunctions.Name -contains ($functionNameMigrations.Keys | Where-Object { $functionNameMigrations[$_] -eq $functionName })
	) {
		[string]$oldCustomFunctionName = $functionNameMigrations.Keys | Where-Object { $functionNameMigrations[$_] -eq $functionName } | Select-Object -First 1
		Write-Host -ForegroundColor Yellow "Migrating '$oldCustomFunctionName' to the new PSADT name format. The function name will be changed to '$functionName'."
		$functionSource = $package.Ast.CustomFunctions | Where-Object { $_.Name -eq $oldCustomFunctionName }
	}
	else {
		Write-Host -ForegroundColor Yellow "The function '$functionName' is not present in the source package. Adding template function to the output copy."
		$functionSource = $template.Ast.CustomFunctions | Where-Object { $_.Name -eq $functionName }
	}

	## Copy the function to the working copy
	[System.Management.Automation.Language.Ast]$outputDeployApplicationAst = [System.Management.Automation.Language.Parser]::ParseInput($deployApplicationContent, [ref]$null, [ref]$null)
	[System.Management.Automation.Language.FunctionDefinitionAst]$outputDeployApplicationTargetFunctionAst = $outputDeployApplicationAst.Find({
			$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and 
			$args[0].Name -eq $functionName
		}, $false)
	if ($null -eq ($functionSource.Body.Extent.Text | Select-String -Pattern '\[string\]\$script\:installPhase')) {
		Write-Host -ForegroundColor Red "Function $($functionSource.Name) does not contain the variable `$script:installPhase. Please add it manually to the output copy if needed."
	}

	$deployApplicationContent = $deployApplicationContent.Remove($outputDeployApplicationTargetFunctionAst.Extent.StartOffset, $outputDeployApplicationTargetFunctionAst.Extent.EndOffset - $outputDeployApplicationTargetFunctionAst.Extent.StartOffset)
	$deployApplicationContent = $deployApplicationContent.Insert($outputDeployApplicationTargetFunctionAst.Extent.StartOffset, $functionSource.Extent.Text)
}
Set-Content -Path (Join-Path $PackagePath.FullName "Deploy-Application.ps1") -Value $deployApplicationContent -Encoding UTF8 -Force
Write-Host -ForegroundColor Green "Finished migrating functions."
#endregion

#region Configuration adjustments
Write-Host @"

########################
## Config adjustments ##
########################
"@
## Import the configuration files
[System.Collections.Specialized.OrderedDictionary]$packageConfig = Get-Content -Raw -Path $package.Files.PackageConfig.FullName | Select-Object -First 1 | ConvertFrom-Json | Convert-PSObjectToOrderedDictionary

## Add missing configuration options in order
foreach ($configOption in $addConfigOptionWhenMissing) {
	if ($false -eq $packageConfig.Contains($configOption.Property)) {
		if ($packageConfig.Contains($configOption.Before)) {
			[int]$index = [Array]::IndexOf($packageConfig.Keys, $configOption.Before)
			Write-Host -ForegroundColor Yellow "Adding new value '$($configOption.Property)' before '$($configOption.Before)' at index $index."
			$packageConfig.Insert($index, $configOption.Property, $configOption.Value) | Out-Null
		}
		else {
			Write-Host -ForegroundColor Red "The configuration option '$($configOption.Before)' does not exist. Cannot add '$($configOption.Property)' to configuration. Please check the configuration options and add the missing configuration option manually."
		}
	}
}

## Replace configuration options on pattern match
foreach ($configOption in $replaceConfigOptionOnPatternMatch) {
	if ($true -eq $packageConfig.Contains($configOption.Property)) {
		[string]$value = (Invoke-Expression "`$packageConfig.$($configOption.Property)").ToString()
		[Microsoft.PowerShell.Commands.MatchInfo]$matchInfo = $value | Select-String -Pattern $configOption.Pattern
		if ( $null -ne $matchInfo -and $matchInfo.Matches.Count -gt 0) {
			Write-Host -ForegroundColor Yellow "Replacing configuration option '$($configOption.Property)' with value '$($configOption.Value)' because the current value '$($packageConfig[$configOption.Property])' does not match the pattern '$($configOption.Pattern)'."
			$packageConfig[$configOption.Property] = $configOption.Value
		}
	}
	else {
		Write-Host -ForegroundColor Red "The configuration option '$($configOption.Property)' does not exist. Please check the configuration options and add the missing configuration option manually."
	}
}

## Remove configuration options when found
foreach ($configOption in $removeConfigOptionWhenFound) {
	if ($true -eq $packageConfig.Contains($configOption)) {
		Write-Host -ForegroundColor Yellow "Removing configuration option '$($configOption)' from the configuration."
		$packageConfig.Remove($configOption)
	}
}

## Output ordered dictionary to JSON
$packageConfig | ConvertTo-Json -Depth 10 | Format-Json | Set-Content -Path (Join-Path $PackagePath.FullName "neo42PackageConfig.json") -Encoding UTF8 -Force
Write-Host -ForegroundColor Green "Finished configuration adjustments."
#endregion

#region Regex replacements
Write-Host @"

###################
## Regex replace ##
###################
"@
foreach ($regexRule in $regexReplacements) {
	[System.IO.FileInfo]$file = $PackagePath.GetFiles($regexRule.File) | Select-Object -First 1
	if ($false -eq $file.Exists) {
		Write-Host -ForegroundColor Red "File '$($file.Name)' does not exist. Skipping regex replacements."
		continue
	}
	
	[string[]]$content = Get-Content -Path $file.FullName
	foreach ($line in $content) {
		[Microsoft.PowerShell.Commands.MatchInfo]$matchInfo = $line | Select-String -Pattern $regexRule.Pattern
		if ($matchInfo.Matches.Count -gt 0) {
			Write-Host -ForegroundColor Yellow "The following regex replace was applied:`n	- Found: '$($matchInfo.Matches[0].Value)'`n	- Pattern: '$($regexRule.Pattern)'`n	- File: '$($file.Name)'`n	- Replacement: '$($regexRule.Replacement)'."
			$content[$content.IndexOf($line)] = $line -replace $regexRule.Pattern, $regexRule.Replacement
		}
	}
	Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -Force
}
Write-Host -ForegroundColor Green "Finished regex replacements."
#endregion

#region Regex errors
Write-Host @"

##################
## Regex errors ##
##################
"@
foreach ($regexRule in $regexErrors) {
	[System.IO.FileInfo]$file = $PackagePath.GetFiles($regexRule.File) | Select-Object -First 1
	if ($false -eq $file.Exists) {
		Write-Host -ForegroundColor Red "File '$($file.Name)' does not exist. Skipping regex error check."
		continue
	}
	
	[string[]]$content = Get-Content -Path $file.FullName
	foreach ($line in $content) {
		[Microsoft.PowerShell.Commands.MatchInfo]$matchInfo = $line | Select-String -Pattern $regexRule.Pattern
		if ($matchInfo.Matches.Count -gt 0) {
			Write-Host -ForegroundColor Red "The regex error pattern '$($regexRule.Pattern)' was found in file '$($file.Name)'. Please check the output copy for the mentioned issues and correct them manually."
		}
	}
}
Write-Host -ForegroundColor Green "Finished regex replacements."
#endregion

#region Custom tasks
Write-Host @"

###################
## Custom tasks ##
###################
"@
[PSCustomObject]$iniContent = Import-NxtIniFileWithComments -Path (Join-Path $PackagePath.FullName "Setup.cfg" | Select-Object -First 1)
foreach ($section in $iniContent.Keys) {
	foreach ($key in ($iniContent.$section.Keys | Where-Object {$_ -ne "DesktopShortcut"})) {
		if ($true -eq [string]::IsNullOrEmpty($iniContent.$section.$key.Value)) {
			Write-Host -ForegroundColor Red "Missing key $key in section $section in 'Setup.cfg', Please add the missing property."
		}
	}
}
if ($iniContent.AskKillProcesses.TOPMOSTWINDOW.Comments -notlike "*Values    = 0,1*"){
	Write-Host -ForegroundColor Red "Please correct the comments in 'Setup.cfg' TOPMOSTWINDOW to 'Values    = 0,1'"
}
if ($iniContent.AskKillProcesses.MINIMIZEALLWINDOWS.Comments -notlike "*Values    = 0,1*"){
	Write-Host -ForegroundColor Red "Please correct the comments in 'Setup.cfg' MINIMIZEALLWINDOWS to 'Values    = 0,1'"
}
if ($iniContent.AskKillProcesses.APPLYCONTINUETYPEONERROR.Comments -notlike "*Values    = 0,1*"){
	Write-Host -ForegroundColor Red "Please correct the comments in 'Setup.cfg' APPLYCONTINUETYPEONERROR to 'Values    = 0,1'"
}
Write-Host -ForegroundColor Green "Finished custom tasks."

## Convert files to CRLF with UTF8 encoding
Get-ChildItem -Path $PackagePath.FullName -Recurse -File -Include @(
	"Deploy-Application.ps1",
	"neo42PackageConfig.json",
	"Setup.cfg"
) | ForEach-Object {
	$filePath = $_.FullName
	$contents = Get-Content -Path $filePath -Raw
	$contents = $contents -replace "`r`n", "`n" -replace "`n", "`r`n"
	Set-Content -Path $filePath -Value $contents -Encoding UTF8
}
#endregion

#region End
Write-Host @"
###################
Finished merging the PSADT with the package. The updated package is located at '$($PackagePath.FullName)'.
If any red messages were displayed, please check the output copy for the mentioned issues and correct them manually.
You can run the script again to perform the migrations and checks again.

"@
# Prevent accidental closing
while($true) {
	Read-Host "Press Ctrl+C to exit."
}
#endregion
