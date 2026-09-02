function Import-NXTPackageRequirement {
	<#
	.SYNOPSIS
	This function imports additional package requirements from a JSON configuration file.
	#>
	[OutputType([PSADTNXT.Deployment.NxtRequirement[]])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0)]
		[System.IO.FileInfo]
		$Path
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[System.Collections.Hashtable]$packageRequirements = ConvertFrom-Json -InputObject ([System.IO.File]::ReadAllText($Path.FullName))
			foreach ($dependencyGuidString in $packageRequirements.Keys) {
				[System.Guid]$dependencyGuid = [System.Guid]::Empty
				[PSADTNXT.Deployment.RequirementState]$dependencyState = [PSADTNXT.Deployment.RequirementState]::Absent
				if ([System.Guid]::TryParse($dependencyGuidString, [ref]$dependencyGuid) -and
					[System.Enum]::TryParse($packageRequirements[$dependencyGuidString].ToString(), $true, [ref]$dependencyState)
				) {
					$PSCmdlet.WriteObject(
						[PSADTNXT.Deployment.NxtRequirement]@{
							Criteria     = [PSADTNXT.Application.NxtApplicationCriteria]@{
								Store      = [PSADTNXT.Application.ApplicationStore]::Package
								Identifier = $dependencyGuid.ToString('B').ToUpper()
							}
							DesiredState = $dependencyState
							OnConflict   = [PSADTNXT.Deployment.RequirementConflictAction]::Fail
							ErrorMessage = "Incompatible package '$($dependencyGuid.ToString('B').ToUpper())' is already installed. Please uninstall it before proceeding with this deployment."
						}
					)
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
