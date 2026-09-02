function Compare-NXTVersion {
	<#
	.SYNOPSIS
	Compare two versions with extended support for different version formats.
	.DESCRIPTION
	Compare two versions using the PSADTNXT.Application.NxtVersion class, which supports a wide range of version formats.
	Known formats include:
	- `1.2.3`
	- `1.2a`
	- `1.2-prerelease+build`
	- `v1.2`
	- `1.2 (build 123)`
	- `2025-01-01`
	.INPUTS
	System.String - The base version to compare.
	.OUTPUTS
	PSADTNXT.Application.VersionCompareResult - The result of the comparison.
	.PARAMETER Version
	The version to compare.
	.PARAMETER Target
	The target version to compare against.
	.EXAMPLE
	Compare-NXTVersion -Version '1.2.3.4' -Target '4.3.2.1'

	Will return [PSADTNXT.Application.VersionCompareResult]::Update.
	#>
	[OutputType([PSADTNXT.Application.VersionCompareResult])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[Alias('DetectedVersion')]
		[AllowEmptyString()]
		[System.String]
		$Version,
		[Parameter(Position = 1, Mandatory)]
		[Alias('TargetVersion')]
		[AllowEmptyString()]
		[System.String]
		$Target
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[PSADTNXT.Application.NxtVersion]$versionObj = $null
			[PSADTNXT.Application.NxtVersion]$targetObj = $null
			if ([PSADTNXT.Application.NxtVersion]::TryParse($Version, [ref]$versionObj) -and
				[PSADTNXT.Application.NxtVersion]::TryParse($Target, [ref]$targetObj)
			) {
				return [PSADTNXT.Application.VersionCompareResult]$versionObj.CompareTo($targetObj)
			}
			else {
				# If parsing fails, compare as strings
				Write-ADTLogEntry -Severity Warning -Message "Failed to parse version [$Version] and/or [$Target] as NxtVersion. Comparing as strings."
				[PSADTNXT.Application.VersionCompareResult]$Version.CompareTo($Target)
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
