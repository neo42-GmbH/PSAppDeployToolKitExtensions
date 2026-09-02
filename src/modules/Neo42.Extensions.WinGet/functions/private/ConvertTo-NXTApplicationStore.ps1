function ConvertTo-NXTApplicationStore {
	<#
	.SYNOPSIS
	Converts the specified installer type to the corresponding NXT application store.
	#>
	[OutputType([PSADTNXT.Application.ApplicationStore])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory)]
		[PSADTNXT.Deployment.DeploymentMethod]
		$DeploymentMethod,
		[PSADTNXT.Package.PackageArchitecture]
		$Architecture
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			return $(
				switch ($DeploymentMethod) {
					([PSADTNXT.Deployment.DeploymentMethod]::AppX) {
						[PSADTNXT.Application.ApplicationStore]::AppX
					}
					default {
						if (([System.Environment]::Is64BitOperatingSystem -and $Architecture -eq [PSADTNXT.Package.PackageArchitecture]::neutral) -or $Architecture -like '*64') {
							[PSADTNXT.Application.ApplicationStore]::ARP64
						}
						else {
							[PSADTNXT.Application.ApplicationStore]::ARP32
						}
					}
				}
			)
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
