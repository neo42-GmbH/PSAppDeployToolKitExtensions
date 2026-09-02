function Get-NXTApplication {
	<#
	.SYNOPSIS
	Retrieves the application matching the application search criteria.
	.DESCRIPTION
	Retrieves the application matching the application search criteria.
	The function queries the specified application store for entries matching the identifier and applies an optional filter to find the desired application(s).
	If no Identifier is provided, all applications from the specified store are returned and filtered accordingly.
	.PARAMETER Criteria
	The application search criteria used to find the application(s).
	.PARAMETER Store
	The application store to query for applications. This parameter is used when the Criteria parameter set is not used.
	.PARAMETER Identifier
	The identifier to search for in the specified store. This parameter is used when the Criteria parameter set is not used.
	.PARAMETER Filter
	An optional script block used to filter the retrieved applications. The script block should return $true for the desired application(s). This parameter is used when the Criteria parameter set is not used.
	.EXAMPLE
	Get-NXTApplication -Criteria @{ Store = 'ARP'; Identifier = 'TestApp' }

	Retrieves the application from the ARP store with an identifier of 'TestApp'.
	.EXAMPLE
	Get-NXTApplication -Store 'ARP' -Filter { $_.DisplayVersion -like '1.*' }

	Retrieves all applications from the ARP store with a display version starting with '1.'.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Filter', Justification = 'The Filter parameter is used in the script block.')]
	[OutputType([PSADT.Types.InstalledApplication])]
	[CmdletBinding(DefaultParameterSetName = 'Manual')]
	param (
		[Parameter(Position = 0, ParameterSetName = 'Criteria', Mandatory, ValueFromPipeline)]
		[PSADTNXT.Application.NxtApplicationCriteria]
		$Criteria,
		[Parameter(ParameterSetName = 'Manual')]
		[PSADTNXT.Application.ApplicationStore]
		$Store = [PSADTNXT.Application.ApplicationStore]::ARP,
		[Parameter(ParameterSetName = 'Manual')]
		[System.String]
		$Identifier,
		[Parameter(ParameterSetName = 'Manual')]
		[System.Management.Automation.ScriptBlock]
		$Filter
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if ($PSCmdlet.ParameterSetName -eq 'Criteria') {
				$Store = $Criteria.Store
				$Identifier = $Criteria.Identifier
				$Filter = $Criteria.Filter
			}

			Get-NXTStoreApplication -Store $Store -Identifier $Identifier | & {
				process {
					if (-not $Filter -or (Where-Object -InputObject $_ -FilterScript $Filter)) {
						$PSCmdlet.WriteObject($_)
					}
				}
			}
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
