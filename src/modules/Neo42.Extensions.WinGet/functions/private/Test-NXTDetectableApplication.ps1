function Test-NXTDetectableApplication {
	<#
	.SYNOPSIS
	Tests if the specified deployment method is detectable in an application store, which is a prerequisite for using it as a detection method in this module.
	#>
	[OutputType([PSADTNXT.Deployment.DeploymentMethod])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory)]
		[PSADTNXT.Deployment.DeploymentMethod]
		$DeploymentMethod
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			return $DeploymentMethod -in @(
				[PSADTNXT.Deployment.DeploymentMethod]::AppX,
				[PSADTNXT.Deployment.DeploymentMethod]::BitRockInstaller,
				[PSADTNXT.Deployment.DeploymentMethod]::Burn,
				[PSADTNXT.Deployment.DeploymentMethod]::InnoSetup,
				[PSADTNXT.Deployment.DeploymentMethod]::MSI,
				[PSADTNXT.Deployment.DeploymentMethod]::Nullsoft,
				[PSADTNXT.Deployment.DeploymentMethod]::Setup
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
