function Get-NXTRegisteredPackage {
	<#
	.SYNOPSIS
	Retrieves information about NXT registered packages on the current machine.
	.DESCRIPTION
	Gets details of the registered application packages installed on a local machine.
	The function fetches details such as PackageGUID and InstallState.
	.OUTPUTS
	PSADTNXT.Package.NxtRegisteredPackage[] - An array of NxtRegisteredPackage objects.
	.PARAMETER PackageId
	Filters the results based on the specified package ID.
	.PARAMETER Installed
	Filters the results based on the installation state of the package.
	.PARAMETER Exclude
	Excludes the specified package IDs from the results.
	.PARAMETER RegistryKey
	Filters the results based on the specified registry packages key.
	.PARAMETER Application
	Gets the package related to the specified InstalledApplication object.
	.PARAMETER ADTSession
	Gets the package related to the specified NxtDeploymentSession object.
	.EXAMPLE
	Get-NxtRegisteredPackage -Package "{12345678-1234-1234-1234-123456789012}" -Installed $false

	This example retrieves information about a specific package that is registered but not installed.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'The parameter is used in the function body.')]
	[OutputType([PSADTNXT.Package.NxtRegisteredPackage[]])]
	[CmdletBinding(DefaultParameterSetName = 'Filter')]
	param (
		[Parameter(ParameterSetName = 'Filter')]
		[ValidateNotNull()]
		[Alias('PackageGUID')]
		[System.Guid]
		$PackageId,
		[Parameter(ParameterSetName = 'Filter')]
		[System.Boolean]
		$Installed,
		[Parameter(ParameterSetName = 'Filter')]
		[ValidateNotNullOrEmpty()]
		[System.Guid[]]
		$Exclude,
		[Parameter(ParameterSetName = 'Filter')]
		[Alias('RegPackagesKey')]
		[System.String]
		$RegistryKey,

		[Parameter(ParameterSetName = 'Application', Mandatory)]
		[ValidateNotNull()]
		[PSADT.Types.InstalledApplication]
		$Application,

		[Parameter(ParameterSetName = 'Session')]
		[ValidateNotNull()]
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			switch ($PSCmdlet.ParameterSetName) {
				'Filter' {
					[System.Collections.Generic.Dictionary[System.String, System.Object]]$params = $PSBoundParameters
					return [PSADTNXT.Package.NxtRegisteredPackage]::GetPackages() | & {
						process {
							if ((-not $params.ContainsKey('RegistryKey') -or $_.RegistryName -eq $RegistryKey) -and
								(-not $params.ContainsKey('PackageId') -or $_.GUID -eq $PackageId.ToString('B')) -and
								(-not $params.ContainsKey('Installed') -or $_.IsInstalled -eq $Installed) -and
								(-not $params.ContainsKey('Exclude') -or $_.GUID -notin $Exclude.ToString('B'))
							) { return $_ }
						}
					}
				}
				'Application' {
					[PSADTNXT.Package.NxtRegisteredPackage]$package = $null
					if ([PSADTNXT.Package.NxtRegisteredPackage]::TryGetPackage($Application, [ref]$package)) {
						return $package
					}
					else {
						Write-ADTLogEntry -Severity Warning -Message 'The specified application cannot be resolved to a registered package. Either the reference is missing or the package is not registered.'
					}
				}
				'Session' {
					if ([PSADTNXT.Package.NxtRegisteredPackage]$sessionPackage = $ADTSession.NXT.Package.GetRegisteredPackage()) {
						return $sessionPackage
					}
					else {
						Write-ADTLogEntry -Severity Warning -Message 'The specified session has not been registered yet.'
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
