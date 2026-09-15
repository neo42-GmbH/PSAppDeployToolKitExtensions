<#
.SYNOPSIS
Updates a package to the latest version of the PSAppDeployToolkit.Neo42.Extenions module.
.PARAMETER Package
The package to upgrade to a newer release.
.PARAMETER Reference
The template data to use as reference for the upgrade.
.PARAMETER Out
The directory where to place the newly build package.
.PARAMETER AnalyzerDirectory
The folder containing the analyzer data required for this migration.
.NOTES
Migrations are not 100% reliable. This script is not a replacement for manual testing.
This only compatible with neo42 template and APD packages.
#>
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleTypes', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'AnalyzerDirectory', Justification = 'Is used.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
[CmdletBinding()]
param (
	[ValidateScript({ @($_.EnumerateFiles('Deploy-Application.ps1', [System.IO.SearchOption]::AllDirectories)).Length -eq 1 })]
	[System.IO.DirectoryInfo]
	$Package,
	[ValidateScript({ $_.Exists -and $_.GetFiles('Deploy-Application.ps1') })]
	[System.IO.DirectoryInfo]
	$Reference,
	[Alias('Out')]
	[System.IO.DirectoryInfo]
	$Output,
	[ValidateScript({ $dirs = $_.EnumerateDirectories('*', [System.IO.SearchOption]::TopDirectoryOnly).Name; $dirs -contains 'migration' -and $dirs -contains 'guidelines' })]
	[System.IO.DirectoryInfo]
	$AnalyzerDirectory = "$PWD\tests\analyzer"
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version '3.0'

#region Settings
[System.String[]]$copyFromPackage = @(
	'Setup.ico',
	'Files',
	'SupportFiles',
	'Assets',
	'Strings'
)

[System.String[]]$copyFromReference = @(
	'PSAppDeployToolkit*',
	'DeployNxtApplication.exe',
	'neo42PackageMetadata.json',
	'PSAppDeployToolkit.Neo42.Extensions\Config'
)

[System.Management.Automation.ScriptBlock[]]$deployApplicationMigrations = @(
	# Architecture specific variables
	{
		param(
			[System.String]
			$Content
		)
		if ($sourceGenerationVersion -ge 4) { return }
		if ($script:packageConfig.Package.Architecture -match '^(x86|ARM)$') {
			return $Content `
				-replace '\$(global:)?ProgramFilesDir\b', '$envProgramFilesW3264' `
				-replace '\$(global:)?ProgramFilesDirx86\b', '$envProgramFilesW3264' `
				-replace '\$(global:)?ProgramW6432\b', '$envProgramFiles' `
				-replace '\$(global:)?CommonFilesDir\b', '$envCommonProgramFilesW3264' `
				-replace '\$(global:)?CommonFilesDirx86\b', '$envCommonProgramFilesW3264' `
				-replace '\$(global:)?CommonProgramW6432\b', '$envCommonProgramFiles' `
				-replace '\$(global:)?RegSoftwarePath\b', '$envRegistrySoftwareW3264' `
				-replace '\$(global:)?RegSoftwarePathx86\b', '$envRegistrySoftwareW3264' `
				-replace '\$(global:)?System', '$envSystemX86'
		}
		else {
			return $Content `
				-replace '\$(global:)?ProgramFilesDir\b', '$envProgramFiles' `
				-replace '\$(global:)?ProgramFilesDirx86\b', '$envProgramFilesW3264' `
				-replace '\$(global:)?ProgramW6432\b', '$envProgramFiles' `
				-replace '\$(global:)?CommonFilesDir\b', '$envCommonProgramFiles' `
				-replace '\$(global:)?CommonFilesDirx86\b', '$envCommonProgramFilesW3264' `
				-replace '\$(global:)?CommonProgramW6432\b', '$envCommonProgramFiles' `
				-replace '\$(global:)?RegSoftwarePath\b', '$envRegistrySoftware' `
				-replace '\$(global:)?RegSoftwarePathx86\b', '$envRegistrySoftwareW3264' `
				-replace '\$(global:)?System', '$envSystemX64'
		}
	}
	# V4 migrations
	{
		param (
			[System.String]
			$Content
		)
		if ($sourceGenerationVersion -ge 4) { return }
		[System.IO.FileInfo]$deployApplicationFile = New-Item -ItemType File -Path "$([System.IO.Path]::GetTempPath())\$([System.IO.Path]::GetRandomFileName()).ps1"
		Set-Content -LiteralPath $deployApplicationFile.FullName -Value $Content
		Invoke-ScriptAnalyzer -Fix -Path $deployApplicationFile.FullName -CustomRulePath "$AnalyzerDirectory\migration\Measure-NXTCompatibility.psm1" -IncludeRule 'Measure-NXTDeprecatedType' | Write-DiagnosticMessage
		Invoke-ScriptAnalyzer -Fix -Path $deployApplicationFile.FullName -CustomRulePath "$AnalyzerDirectory\migration\Measure-NXTCompatibility.psm1" -IncludeRule 'Measure-NXTCustomMigration' | Write-DiagnosticMessage
		Invoke-ScriptAnalyzer -Fix -Path $deployApplicationFile.FullName -CustomRulePath "$AnalyzerDirectory\migration\Measure-NXTCompatibility.psm1" -IncludeRule 'Measure-NXTDeprecatedVariable' | Write-DiagnosticMessage
		Invoke-ScriptAnalyzer -Fix -Path $deployApplicationFile.FullName -CustomRulePath "$AnalyzerDirectory\migration\Measure-NXTCompatibility.psm1" -IncludeRule 'Measure-NXTDeprecatedFunction' | Write-DiagnosticMessage
		$Content = Get-Content -Raw -LiteralPath $deployApplicationFile.FullName
		$deployApplicationFile.Delete()
		return $Content
	},
	# Coding guidelines V4
	{
		param (
			[System.String]
			$Content
		)
		[System.IO.FileInfo]$deployApplicationFile = New-Item -ItemType File -Path "$([System.IO.Path]::GetTempPath())\$([System.IO.Path]::GetRandomFileName()).ps1"
		Set-Content -LiteralPath $deployApplicationFile.FullName -Value $Content
		Invoke-ScriptAnalyzer -Fix -Path $deployApplicationFile.FullName -CustomRulePath "$AnalyzerDirectory\guidelines\neo42PSScriptAnalyzerRules.psm1" -Settings "$AnalyzerDirectory\guidelines\PSScriptAnalyzerSettings.psd1" | Write-DiagnosticMessage
		$Content = Get-Content -Raw -LiteralPath $deployApplicationFile.FullName
		$deployApplicationFile.Delete()
		return $Content
	}
)

[System.Management.Automation.ScriptBlock[]]$setupCfgMigrations = @(
	# V4 migrations
	{
		param(
			[PSADTNXT.Configuration.NxtIniDocument]
			$SetupCfg
		)
		if ($sourceGenerationVersion -ge 4) {
			Write-Output $SetupCfg -NoEnumerate
			return
		}
		if ($SetupCfg.ContainsKey('AskKillProcesses')) {
			[PSADTNXT.Configuration.NxtIniSection]$akp = $SetupCfg['AskKillProcesses']
			$null = $akp.Remove('FORCECONTINUEAFTERDEFERRALS')
			$null = $akp.Remove('APPLYCONTINUETYPEONERROR')
		}
		Write-Output $SetupCfg -NoEnumerate
	}
)
#endregion Settings

#region Helpers
function Write-DiagnosticMessage {
	<#
	.SYNOPSIS
	Returns the color for a given severity.
	#>
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]
		$Record
	)
	process {
		[System.ConsoleColor]$color = switch -Wildcard ($Record.Severity) {
			'Warning' { [System.ConsoleColor]::Yellow }
			'*Error' { [System.ConsoleColor]::Red }
			default { [System.ConsoleColor]::White }
		}
		Write-Host "$($Record.Message) [$($Record.ScriptPath):$($Record.Line)] " -ForegroundColor $color
	}
}

function Get-FolderLocation {
	<#
	.SYNOPSIS
	Open a dialog to select a package directory.
	#>
	param(
		[Parameter(Mandatory)]
		[System.String]
		$Message
	)
	Add-Type -AssemblyName 'System.Windows.Forms'
	[System.Windows.Forms.FolderBrowserDialog]$packageSelector = [System.Windows.Forms.FolderBrowserDialog]::new()
	$packageSelector.Description = $Message
	$packageSelector.ShowNewFolderButton = $false
	[System.Windows.Forms.DialogResult]$result = $packageSelector.ShowDialog()
	if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
		return [System.IO.DirectoryInfo]::new($packageSelector.SelectedPath)
	}
	else {
		throw 'No update package selected.'
	}
}
#endregion Helpers

#region Initialize
# Show a dialog to select the package if not provided
if (-not $Package) {
	Write-Host 'No package directory provided, opening selection dialog...'
	$Package = Get-FolderLocation -Message '(Package) Select the package that you want to update:'
}
if (-not $Reference) {
	Write-Host 'No reference package directory provided, opening selection dialog...'
	$Reference = Get-FolderLocation -Message '(Reference) Select the reference package directory:'
}
if (-not $Output) {
	Write-Host 'No output directory provided, opening selection dialog...'
	$Output = Get-FolderLocation -Message '(Out) Select the output directory for the updated package:'
}

Write-Host 'Initializing script...'

# Find the root of the package and update paths.
[System.IO.FileInfo]$deployApplicationFile = Get-ChildItem -Path $Package.FullName -Filter 'Deploy-Application.ps1' -File -Recurse
[System.String]$subDirectory = $deployApplicationFile.Directory.FullName.Substring($Package.Parent.FullName.Length + 1)
$Output = [System.IO.DirectoryInfo]::new([System.IO.Path]::Combine($Output.FullName, $subDirectory))
$Package = $deployApplicationFile.Directory

# Import and initialize PSADTNXT.Nxt) module for validation, types and environment
[System.Int32]$sourceGenerationVersion = if ([System.IO.Directory]::Exists("$($Package.FullName)\AppDeployToolkit")) { 3 } else { 4 }
[System.String[]]$moduleDirs = (Get-Item -Path "$Reference\PSAppDeployToolkit", "$Reference\PSAppDeployToolkit.Neo42.Extensions").FullName
Get-ChildItem -LiteralPath $moduleDirs -Recurse -File | Unblock-File
Import-Module -Name $moduleDirs -Force
Initialize-ADTModule -ScriptDirectory $moduleDirs -AdditionalEnvironmentVariables (New-NXTEnvironmentTable)
#endregion Initialize

#region Copy files
# Create output directory with trap for cleanup
Write-Host 'Creating output directory and copy static files...'
$Output.Create()
foreach ($item in $copyFromPackage) {
	$copyFromPackagePath = [System.IO.Path]::Combine($Package.FullName, $item)
	if (Test-Path -LiteralPath $copyFromPackagePath) {
		Copy-Item -Path $copyFromPackagePath -Destination $Output.FullName -Force -Recurse
	}
	else {
		Write-Host -ForegroundColor Yellow "The [$item] directory does not exists in the source package."
	}
}
foreach ($item in $copyFromReference) {
	$copyFromReferencePath = [System.IO.Path]::Combine($Reference.FullName, $item)
	Copy-Item -Path $copyFromReferencePath -Destination $Output.FullName -Force -Recurse
}
#endregion Copy files

#region SetupCfg migration
Write-Host 'Merging new reference settings and metadata to Setup.cfg...'
[PSADTNXT.Configuration.NxtIniDocument]$packageCfg = [PSADTNXT.Configuration.NxtIniDocument]::CreateFrom("$Package\Setup.cfg")
[PSADTNXT.Configuration.NxtIniDocument]$setupCfg = [PSADTNXT.Configuration.NxtIniDocument]::CreateFrom("$Reference\Setup.cfg")

# Merge new reference settings and update comments
[System.Int32]$sectionIdx = 0
foreach ($packageCfgSection in $packageCfg.GetEnumerator()) {
	if (-not $setupCfg.ContainsKey($packageCfgSection.Key)) {
		$setupCfg.Insert($sectionIdx, $packageCfgSection.Key, $packageCfgSection.Value, $packageCfg.GetComment($packageCfgSection.Key))
	}
	else {
		[System.Int32]$settingIdx = 0
		foreach ($packageCfgSetting in $packageCfgSection.Value.GetEnumerator()) {
			if (-not $setupCfg[$packageCfgSection.Key].ContainsKey($packageCfgSetting.Key)) {
				$setupCfg[$packageCfgSection.Key].Insert($settingIdx, $packageCfgSetting.Key, $packageCfgSetting.Value, $packageCfgSection.Value.GetComment($packageCfgSetting.Key))
			}
			$settingIdx++
		}
	}
	$sectionIdx++
}

# Apply migrations
[System.UInt16]$migrationCounter = 0
foreach ($migration in $setupCfgMigrations) {
	$migrationCounter++
	Write-Host "Running [Setup.cfg] migration [$migrationCounter]."
	$setupCfg = & $migration $setupCfg
}

# Validate with newest schema
Write-Host 'Validating Setup.cfg...'
[System.String[]]$setupCfgErrors = $null
if (-not $setupCfg.Validate([ref]$setupCfgErrors)) {
	Write-Host -ForegroundColor Red "Setup.cfg validation failed:`n$([System.String]::Join('`n', $setupCfgErrors))"
}

Set-Content -Encoding UTF8 -Path "$($Output.FullName)\Setup.cfg" -Value ($setupCfg.Export())
#endregion SetupCfg migration

#region PackageConfig migration
Write-Host 'Running PackageConfig migration...'
try {
	if ([System.IO.File]::Exists("$Package\neo42PackageConfig.json")) {
		Copy-Item -Path "$Package\neo42PackageConfig.json" -Destination "$($Output.FullName)\neo42PackageConfig.json" -Force
		Copy-Item -Path "$Package\neo42PackageConfig.psd1" -Destination "$($Output.FullName)\neo42PackageConfig.psd1" -Force -ErrorAction SilentlyContinue # Only copy if exists

		[PSADTNXT.Deployment.Configuration.Legacy.NxtLegacyPackageConfigurationModel]$legacyConfig = [PSADTNXT.Deployment.Configuration.NxtPackageConfigurationFactory]::CreateLegacyFrom(
			"$Package\neo42PackageConfig.json",
			(Get-ADTEnvironmentTable),
			([System.Management.Automation.Runspaces.SessionStateVariableEntry]::new('SetupCfg', $setupCfg, ''))
		)

		if (-not $legacyConfig.AppendInstParaToDefaultParameters -and [System.String]::IsNullOrWhiteSpace($legacyConfig.InstPara)) {
			Write-Host -ForegroundColor Yellow '[AppendInstParaToDefaultParameters] is false and no install parameters are specified. Appending default parameters anyway was removed. Set [AppendInstParaToDefaultParameters] to true to retain the old behavior.'
		}
		if (-not $legacyConfig.AppendUninstParaToDefaultParameters -and [System.String]::IsNullOrWhiteSpace($legacyConfig.UninstPara)) {
			Write-Host -ForegroundColor Yellow '[AppendUninstParaToDefaultParameters] is false and no uninstall parameters are specified. Appending default parameters anyway was removed. Set [AppendUninstParaToDefaultParameters] to true to retain the old behavior.'
		}

		[PSADTNXT.Deployment.Configuration.NxtPackageConfigurationModel]$script:packageConfig = [PSADTNXT.Deployment.Configuration.NxtPackageConfigurationFactory]::Translate($legacyConfig)
	}
	else {
		Copy-Item -Path "$Package\neo42PackageConfig.psd1" -Destination "$($Output.FullName)\neo42PackageConfig.psd1" -Force
		[PSADTNXT.Deployment.Configuration.NxtPackageConfigurationModel]$script:packageConfig = [PSADTNXT.Deployment.Configuration.NxtPackageConfigurationFactory]::CreateFrom(
			"$Package\neo42PackageConfig.psd1",
			(Get-ADTEnvironmentTable),
			([System.Management.Automation.Runspaces.SessionStateVariableEntry]::new('SetupCfg', $setupCfg, ''))
		)
	}
}
catch {
	Write-Host -ForegroundColor Red "Package configuration validation failed:`n$($_.Exception | Out-String)"
}
#endregion PackageConfig migration

#region Deploy-Application migration
Write-Host 'Migrating Deploy-Application custom functions...'
[System.Management.Automation.Language.ParseError[]]$parserErrors = $null

# Parse both files to retrieve custom function names and content markers
[System.Management.Automation.Language.Token[]]$referenceTokens = $null
[System.Management.Automation.Language.ScriptBlockAst]$referenceAst = [System.Management.Automation.Language.Parser]::ParseFile("$Reference\Deploy-Application.ps1", [ref]$referenceTokens, [ref]$parserErrors)
if ($parserErrors) { throw "Parser errors in [$Reference\Deploy-Application.ps1]:`n$([System.String]::Join('`n', $parserErrors.Message))" }
[System.Management.Automation.Language.FunctionDefinitionAst[]]$referenceCustomFunctions = $referenceAst.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -like 'Custom*' }, $false)
[System.Array]::Reverse($referenceCustomFunctions) # Reverse functions order to go from buttoms up to prevent insertion issues

[System.Management.Automation.Language.Token[]]$packageTokens = $null
[System.Management.Automation.Language.ScriptBlockAst]$packageAst = [System.Management.Automation.Language.Parser]::ParseFile("$Package\Deploy-Application.ps1", [ref]$packageTokens, [ref]$parserErrors)
if ($parserErrors) { throw "Parser errors in [$Package\Deploy-Application.ps1]:`n$([System.String]::Join('`n', $parserErrors.Message))" }
[System.Management.Automation.Language.FunctionDefinitionAst[]]$packageCustomFunctions = $packageAst.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -like 'Custom*' }, $false)

# If there are custom functions that have been removed, we need to migrate them manually
if ([System.String[]]$missingFunctions = $packageCustomFunctions.Name | Where-Object { $referenceCustomFunctions.Name -notcontains $_ }) {
	Write-Host -ForegroundColor Red "Custom functions have been removed. Manual migration is required for:`n$([System.String]::Join('`n', $missingFunctions))"
}

# Migrate custom functions
[System.Text.StringBuilder]$deployApplicationSb = [System.Text.StringBuilder]::new($referenceAst.Extent.Text)
foreach ($referenceCustomFunction in $referenceCustomFunctions) {
	if ($packageCustomFunctions.Name -notcontains $referenceCustomFunction.Name) { continue }
	# Retrieve content markers
	[System.Management.Automation.Language.Token]$referenceStartToken = $referenceTokens | Where-Object {
		$_.Kind -eq [System.Management.Automation.Language.TokenKind]::Comment -and
		$_.Text -eq "#region $($referenceCustomFunction.Name) content"
	}
	if (-not $referenceStartToken) { throw "No start token found for [$($referenceCustomFunction.Name)] in [$Reference\Deploy-Application.ps1]" }

	[System.Management.Automation.Language.Token]$packageStartToken = $packageTokens | Where-Object {
		$_.Kind -eq [System.Management.Automation.Language.TokenKind]::Comment -and
		$_.Text -eq "#region $($referenceCustomFunction.Name) content"
	}
	if (-not $packageStartToken) { throw "No start token found for [$($referenceCustomFunction.Name)] in [$Package\Deploy-Application.ps1]" }

	[System.Management.Automation.Language.Token]$packageEndToken = $packageTokens | Where-Object {
		$_.Kind -eq [System.Management.Automation.Language.TokenKind]::Comment -and
		$_.Text -eq "#endregion $($referenceCustomFunction.Name) content"
	}
	if (-not $packageEndToken) { throw "No end token found for [$($referenceCustomFunction.Name)] in [$Package\Deploy-Application.ps1]" }

	# Insert at the defined position
	[System.String]$originalFunctionContent = $packageAst.Extent.Text.Substring($packageStartToken.Extent.EndOffset, $packageEndToken.Extent.StartOffset - $packageStartToken.Extent.EndOffset).TrimEnd() + [System.Environment]::NewLine
	if (-not [System.String]::IsNullOrWhiteSpace($originalFunctionContent)) {
		$null = $deployApplicationSb.Insert($referenceStartToken.Extent.EndOffset, $originalFunctionContent)
	}
}

# Apply migrations
[System.UInt16]$migrationCounter = 0
[System.String]$deployApplicationContent = $deployApplicationSb.ToString() -replace '\r\n', "`n" -replace '\r', "`n" -replace '\n', "`r`n" # Fix line endings pre migration
foreach ($migration in $deployApplicationMigrations) {
	$migrationCounter++
	Write-Host "Running [Deploy-Application] migration [$migrationCounter]."
	$deployApplicationContent = & $migration $deployApplicationContent
}

Set-Content -LiteralPath "$($Output.FullName)\Deploy-Application.ps1" -Value $deployApplicationContent
#endregion Deploy-Application migration

Write-Host -ForegroundColor Green 'Migration completed. Please review the logs, output files and test the package.'
Write-Host -ForegroundColor Green "Output files are located in [$($Output.FullName)]."

if (-not [System.Environment]::GetCommandLineArgs().Contains('-NonInteractive')) {
	Remove-Module -Name 'PSAppDeployToolkit*' -Force # Release file locks
	Read-Host -Prompt 'Press ENTER to exit'
}

