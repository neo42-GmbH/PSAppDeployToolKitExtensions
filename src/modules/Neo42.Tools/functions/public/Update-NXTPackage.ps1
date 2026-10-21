function Update-NXTPackage {
	<#
	.SYNOPSIS
	Updates a package to match the latest version of the PSAppDeployToolkit.Neo42.Extenions module.
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
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Migration scriptblocks might not need the parameters')]
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline)]
		[ValidateScript({ @($_.EnumerateFiles('Deploy-Application.ps1', [System.IO.SearchOption]::AllDirectories)).Length -eq 1 })]
		[System.IO.DirectoryInfo]
		$Package,
		[ValidateScript({ $_.Exists -and $_.GetFiles('Deploy-Application.ps1') })]
		[System.IO.DirectoryInfo]
		$Reference,
		[Alias('Out')]
		[System.IO.DirectoryInfo]
		$Output
	)
	begin {
		[System.Version]$supportedMinimumFramework = '3.0'
		[System.Version]$supportedMaximumFramework = '4.0'
		[System.String]$moduleBase = $ExecutionContext.SessionState.Module.ModuleBase
		[System.String[]]$copyFromPackage = @('Setup.ico', 'Files', 'SupportFiles', 'neo42PackageConfig.json', 'neo42PackageConfig.psd1')
		[System.String[]]$copyFromReference = @('PSAppDeployToolkit*', 'DeployNxtApplication.exe', 'PSAppDeployToolkit.Neo42.Extensions\Config', 'neo42PackageMetadata.json')

		[System.Management.Automation.ScriptBlock[]]$migrations = @(
			{ # v4.0 Deploy-Application
				param(
					[System.IO.DirectoryInfo]
					$Package,
					[System.Version]
					$PackageFramework
				)
				if ($PackageFramework -ge '4.0') { return }

				[System.String]$arch = Get-NXTPackageArchitecture -Package $Package
				[System.String]$deployApplication = [System.IO.Path]::Combine($Package.FullName, 'Deploy-Application.ps1')
				Set-Content -Encoding UTF8 -LiteralPath $deployApplication -NoNewline -Value $(
					if ($arch -match '^(x86|ARM)$') {
						(Get-Content -Raw -LiteralPath $deployApplication) `
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
						(Get-Content -Raw -LiteralPath $deployApplication) `
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
				)

				[System.String]$compatRules = [System.IO.Path]::Combine($moduleBase, 'CompatibilityRules.psm1')
				'Measure-NXTDeprecatedType', 'Measure-NXTCustomMigration', 'Measure-NXTDeprecatedVariable', 'Measure-NXTDeprecatedFunction' | ForEach-Object {
					Invoke-ScriptAnalyzer -Path $deployApplication -CustomRulePath $compatRules -Fix -IncludeRule $_ | Write-NXTDiagnosticMessage
				}
			}
			{ # v4.0 Setup.cfg
				param(
					[System.IO.DirectoryInfo]
					$Package,
					[System.Version]
					$PackageFramework
				)
				if ($PackageFramework -ge '4.0') { return }

				[System.String]$setupCfg = [System.IO.Path]::Combine($Package.FullName, 'Setup.cfg')
				[PSADTNXT.Configuration.NxtIniDocument]$doc = [PSADTNXT.Configuration.NxtIniDocument]::CreateFrom($setupCfg)
				if ($doc.ContainsKey('AskKillProcesses')) {
					[PSADTNXT.Configuration.NxtIniSection]$akp = $doc['AskKillProcesses']
					$null = $akp.Remove('FORCECONTINUEAFTERDEFERRALS')
					$null = $akp.Remove('APPLYCONTINUETYPEONERROR')
				}
				Set-Content -Encoding UTF8 -LiteralPath $setupCfg -Value ($doc.Export($setupCfg))
			}
			{ # v4.0 PackageConfig warnings
				param(
					[System.IO.DirectoryInfo]
					$Package,
					[System.Version]
					$PackageFramework
				)
				if ($PackageFramework -ge '4.0') { return }

				[PSCustomObject]$legacyConfig = ConvertFrom-Json -InputObject (Get-Content -Raw -LiteralPath "$($Package.FullName)\neo42PackageConfig.json")

				if (-not $legacyConfig.AppendInstParaToDefaultParameters -and [System.String]::IsNullOrWhiteSpace($legacyConfig.InstPara)) {
					Write-Host -ForegroundColor Yellow '[AppendInstParaToDefaultParameters] is false and no [InstPara] are specified. Appending default parameters anyway was removed. Set [AppendInstParaToDefaultParameters] to true to retain the old behavior.'
				}
				if (-not $legacyConfig.AppendUninstParaToDefaultParameters -and [System.String]::IsNullOrWhiteSpace($legacyConfig.UninstPara)) {
					Write-Host -ForegroundColor Yellow '[AppendUninstParaToDefaultParameters] is false and no [UninstPara] are specified. Appending default parameters anyway was removed. Set [AppendUninstParaToDefaultParameters] to true to retain the old behavior.'
				}
				foreach ($akp in $legacyConfig.AppKillProcesses) {
					if ($akp.IsWQL) {
						Write-Host -ForegroundColor Red "[IsWQL] is set to true on [$($akp.Name)]. Switch to false in Order for migration to proceed. Please update afterwards!"
					}
				}
			}
		)
	}
	process {
		#region Initialize
		if (-not $Package) {
			Write-Host -NoNewline 'No package directory provided, opening selection dialog...'
			$Package = Get-NXTFolderWindow -Message '(Package) Select the package that you want to update:'
			Write-Host -ForegroundColor Green 'OK.'
		}
		if (-not $Reference) {
			Write-Host -NoNewline 'No reference package directory provided, opening selection dialog...'
			$Reference = Get-NXTFolderWindow -Message '(Reference) Select the reference package directory:'
			Write-Host -ForegroundColor Green 'OK.'
		}
		if (-not $Output) {
			Write-Host -NoNewline 'No output directory provided, opening selection dialog...'
			$Output = Get-NXTFolderWindow -Message '(Output) Select the output directory for the updated package:'
			Write-Host -ForegroundColor Green 'OK.'
		}

		Write-Host 'Initializing script...'

		# Update the path parameters to find nested Packages
		[System.IO.FileInfo]$deployApplicationFile = Get-ChildItem -Path $Package.FullName -Filter 'Deploy-Application.ps1' -File -Recurse
		[System.String]$subDirectory = $deployApplicationFile.Directory.FullName.Substring($Package.Parent.FullName.Length + 1)
		$Output = [System.IO.DirectoryInfo]::new([System.IO.Path]::Combine($Output.FullName, $subDirectory))
		$Package = $deployApplicationFile.Directory

		# Get the framework version. Assume 3.0 if file is missing.
		[System.Version]$packageFrameworkVersion = if (Test-Path -LiteralPath "$($Package.FullName)\neo42PackageMetadata.json" -PathType Leaf) {
			(ConvertFrom-Json -InputObject (Get-Content -Raw -Path "$($Package.FullName)\neo42PackageMetadata.json")).PackageFramework
		}
		elseif (Test-Path -LiteralPath "$($Package.FullName)\AppDeployToolkit" -PathType Container) {
			'3.0'
		}
		else {
			'0.0'
		}

		if ($packageFrameworkVersion -lt $supportedMinimumFramework -or $packageFrameworkVersion -gt $supportedMaximumFramework) {
			throw "The given framework [$packageFrameworkVersion] is not within supported range of [$($supportedMinimumFramework)-$($supportedMaximumFramework)]."
		}
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
		}
		foreach ($item in $copyFromReference) {
			$copyFromReferencePath = [System.IO.Path]::Combine($Reference.FullName, $item)
			Copy-Item -Path $copyFromReferencePath -Destination $Output.FullName -Force -Recurse
		}
		#endregion Copy files

		#region SetupCfg
		Write-Host 'Merging new reference settings and metadata to Setup.cfg...'
		[PSADTNXT.Configuration.NxtIniDocument]$packageCfg = [PSADTNXT.Configuration.NxtIniDocument]::CreateFrom("$($Package.FullName)\Setup.cfg")
		[PSADTNXT.Configuration.NxtIniDocument]$setupCfg = [PSADTNXT.Configuration.NxtIniDocument]::CreateFrom("$($Reference.FullName)\Setup.cfg")

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

		Set-Content -Encoding UTF8 -LiteralPath "$($Output.FullName)\Setup.cfg" -Value ($setupCfg.Export())
		#endregion SetupCfg

		#region Deploy-Application migration
		Write-Host 'Migrating Deploy-Application custom functions...'
		[System.Management.Automation.Language.ParseError[]]$parserErrors = $null

		# Parse both files to retrieve custom function names and content markers
		[System.Management.Automation.Language.Token[]]$referenceTokens = $null
		[System.Management.Automation.Language.ScriptBlockAst]$referenceAst = [System.Management.Automation.Language.Parser]::ParseFile("$($Reference.FullName)\Deploy-Application.ps1", [ref]$referenceTokens, [ref]$parserErrors)
		if ($parserErrors) { throw "Parser errors in [$($Reference.FullName)\Deploy-Application.ps1]:`n$([System.String]::Join('`n', $parserErrors.Message))" }
		[System.Management.Automation.Language.FunctionDefinitionAst[]]$referenceCustomFunctions = $referenceAst.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -like 'Custom*' }, $false)
		[System.Array]::Reverse($referenceCustomFunctions) # Reverse functions order to go from buttoms up to prevent insertion issues

		[System.Management.Automation.Language.Token[]]$packageTokens = $null
		[System.Management.Automation.Language.ScriptBlockAst]$packageAst = [System.Management.Automation.Language.Parser]::ParseFile("$($Package.FullName)\Deploy-Application.ps1", [ref]$packageTokens, [ref]$parserErrors)
		if ($parserErrors) { throw "Parser errors in [$($Package.FullName)\Deploy-Application.ps1]:`n$([System.String]::Join('`n', $parserErrors.Message))" }
		[System.Management.Automation.Language.FunctionDefinitionAst[]]$packageCustomFunctions = $packageAst.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -like 'Custom*' }, $false)


		# Migrate custom functions
		[System.Text.StringBuilder]$deployApplicationSb = [System.Text.StringBuilder]::new($referenceAst.Extent.Text)
		if (([System.String[]]$missingFunctions = $packageCustomFunctions | Where-Object { $_.Name -notin $referenceCustomFunctions.Name })) {
			Write-Host -ForegroundColor Red "Custom functions have been removed. Manual migration is required for [$missingFunctions]."
			continue
		}
		foreach ($referenceCustomFunction in $referenceCustomFunctions) {
			if ($referenceCustomFunction.Name -notin $packageCustomFunctions.Name) { continue }
			# Retrieve content markers
			[System.Management.Automation.Language.Token]$referenceStartToken = $referenceTokens | Where-Object {
				$_.Kind -eq [System.Management.Automation.Language.TokenKind]::Comment -and
				$_.Text -match "#region $($referenceCustomFunction.Name) content\s*"
			}
			if (-not $referenceStartToken) { throw "No start token found for [$($referenceCustomFunction.Name)] in [$($Reference.FullName)\Deploy-Application.ps1]" }

			[System.Management.Automation.Language.Token]$packageStartToken = $packageTokens | Where-Object {
				$_.Kind -eq [System.Management.Automation.Language.TokenKind]::Comment -and
				$_.Text -match "#region $($referenceCustomFunction.Name) content\s*"
			}
			if (-not $packageStartToken) { throw "No start token found for [$($referenceCustomFunction.Name)] in [$($Package.FullName)\Deploy-Application.ps1]" }

			[System.Management.Automation.Language.Token]$packageEndToken = $packageTokens | Where-Object {
				$_.Kind -eq [System.Management.Automation.Language.TokenKind]::Comment -and
				$_.Text -match "#endregion $($referenceCustomFunction.Name) content\s*"
			}
			if (-not $packageEndToken) { throw "No end token found for [$($referenceCustomFunction.Name)] in [$($Package.FullName)\Deploy-Application.ps1]" }

			# Insert at the defined position
			[System.String]$originalFunctionContent = $packageAst.Extent.Text.Substring($packageStartToken.Extent.EndOffset, $packageEndToken.Extent.StartOffset - $packageStartToken.Extent.EndOffset).TrimEnd() + [System.Environment]::NewLine
			if (-not [System.String]::IsNullOrWhiteSpace($originalFunctionContent)) {
				$null = $deployApplicationSb.Insert($referenceStartToken.Extent.EndOffset, $originalFunctionContent)
			}
		}

		Set-Content -Encoding UTF8 -LiteralPath "$($Output.FullName)\Deploy-Application.ps1" -Value $(Format-NXTCLRF -InputObject $deployApplicationSb.ToString())
		#endregion Deploy-Application migration

		# Apply the actual migration in order
		Write-Host "Applying migrations from framework [$packageFrameworkVersion] to [$supportedMaximumFramework]."
		[System.Int32]$counter = 0
		$migrations | ForEach-Object {
			$counter++
			& $_ -Package $Output -PackageFramework $packageFrameworkVersion
			Write-Host "Applied migration [$($counter)]"
		}

		Write-Host -ForegroundColor Green 'Migration completed. Please review the logs, output files and test the package.'
		Write-Host -ForegroundColor Green "Output files are located in [$($Output.FullName)]."
	}
}
