function ConvertTo-NXTDetectionCriteria {
	<#
	.SYNOPSIS
	Converts the detection criteria information from the WinGet manifest into a PSADTNXT.Application.NxtApplicationCriteria object.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'It does not use plural nouns')]
	[OutputType([PSADTNXT.Application.NxtApplicationCriteria])]
	[CmdletBinding()]
	param (
		[PSADTNXT.WinGet.Configuration.WinGetConfigModel]
		[Parameter(Mandatory)]
		$Model,
		[Parameter(Mandatory)]
		[PSADTNXT.Deployment.DeploymentMethod]
		$DeploymentMethod,
		[Parameter(Mandatory)]
		[System.String]
		$Name,
		[Parameter(Mandatory)]
		[System.String]
		$Vendor,
		[Parameter(Mandatory)]
		[System.IO.FileInfo]
		$Installer
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[PSADTNXT.Application.NxtApplicationCriteria]$criteria = [PSADTNXT.Application.NxtApplicationCriteria]@{
				Store = ConvertTo-NXTApplicationStore -DeploymentMethod $adtSession.NXT.Install.Method -Architecture $adtSession.AppArch
			}

			[System.Collections.Generic.List[System.String]]$filters = [System.Collections.Generic.List[System.String]]::new()
			if ($Model.AppsAndFeaturesEntries) {
				foreach ($entry in $Model.AppsAndFeaturesEntries) {
					[System.Collections.Generic.List[System.String]]$entryFilters = [System.Collections.Generic.List[System.String]]::new()
					if (-not [System.String]::IsNullOrWhiteSpace($entry.UpgradeCode) -and -not [System.String]::IsNullOrWhiteSpace($entry.ProductCode)) {
						$entryFilters.Add("`(`$_.UpgradeCode -eq '$($entry.UpgradeCode)' -or `$_.ProductCode -eq '$($entry.ProductCode)')")
					}
					elseif (-not [System.String]::IsNullOrWhiteSpace($entry.UpgradeCode)) { $entryFilters.Add("`$_.UpgradeCode -eq '$($entry.UpgradeCode)'") }
					elseif (-not [System.String]::IsNullOrWhiteSpace($entry.ProductCode)) { $entryFilters.Add("`$_.ProductCode -eq '$($entry.ProductCode)'") }

					if (-not [System.String]::IsNullOrWhiteSpace($entry.DisplayName)) { $entryFilters.Add("`$_.DisplayName -eq '$($entry.DisplayName)'") }
					if (-not [System.String]::IsNullOrWhiteSpace($entry.Publisher)) { $entryFilters.Add("`$_.Publisher -eq '$($entry.Publisher)'") }
					if (-not [System.String]::IsNullOrWhiteSpace($entry.DeploymentMethod) -and
						-not [System.String]::IsNullOrWhiteSpace(([System.String]$methodFilter = Get-NXTMethodFilter -DeploymentMethod $entry.DeploymentMethod -PackageFamilyName $entry.PackageFamilyName))
					) {
						$entryFilters.Add($methodFilter)
					}

					if ($entryFilters) { $filters.Add("($([System.String]::Join(' -and ', $entryFilters)))") }
				}
			}
			elseif ($DeploymentMethod -eq [PSADTNXT.Deployment.DeploymentMethod]::AppX) {
				$criteria.Identifier = if (-not [System.String]::IsNullOrWhiteSpace($Model.PackageFamilyName)) {
					$Model.PackageFamilyName
				}
				else {
					[System.Collections.Hashtable]$errorParams = @{
						Exception         = [System.InvalidOperationException]::new('The installer manifest does not specify a PackageFamilyName for AppX deployment, and the installer file could not be found to attempt extraction of the family name.')
						Category          = [System.Management.Automation.ErrorCategory]::InvalidData
						ErrorId           = 'AppXPackageFamilyNameNotFound'
						RecommendedAction = 'Specify a valid installer file or include a PackageFamilyName in the installer manifest.'
						TargetObject      = $Model
					}
					throw (New-ADTErrorRecord @errorParams)
				}
			}
			elseif (-not [System.String]::IsNullOrWhiteSpace($Model.ProductCode)) {
				$criteria.Identifier = $Model.ProductCode
			}
			elseif ($DeploymentMethod -eq [PSADTNXT.Deployment.DeploymentMethod]::MSI -and
				$Installer.Exists -and
				([System.Collections.ObjectModel.ReadOnlyDictionary[System.String, System.String]]$msiProperties = Get-ADTMsiTableProperty -LiteralPath $Installer.FullName -Table 'Property' -InformationAction SilentlyContinue) -and
				-not [System.String]::IsNullOrWhiteSpace($msiProperties['UpgradeCode'])
			) {
				$filters.Add("`$_.UpgradeCode -eq '$($msiProperties['UpgradeCode'])' -or `$_.ProductCode -eq '$($msiProperties['ProductCode'])'")
			}
			else {
				[System.Collections.Generic.List[System.String]]$entryFilters = [System.Collections.Generic.List[System.String]]::new()

				$entryFilters.Add("`$_.DisplayName -match '$(ConvertTo-NXTRegexQuery -Text $Name)'")
				$entryFilters.Add("`$_.Publisher -match '^`$|$(ConvertTo-NXTRegexQuery -Text $Vendor)'")

				if (([System.String]$methodFilter = Get-NXTMethodFilter -DeploymentMethod $DeploymentMethod)) {
					$entryFilters.Add($methodFilter)
				}

				$filters.Add([System.String]::Join(' -and ', $entryFilters))
			}

			if ($filters) {
				$criteria.Filter = [System.Management.Automation.ScriptBlock]::Create([System.String]::Join(' -or ', $filters))
			}

			return $criteria
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
