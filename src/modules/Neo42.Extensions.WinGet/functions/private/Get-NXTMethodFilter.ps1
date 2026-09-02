function Get-NXTMethodFilter {
	<#
	.Synopsis
	Gets the filter expression for the specified deployment method.
	#>
	[OutputType([System.Management.Automation.ScriptBlock])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[PSADTNXT.Deployment.DeploymentMethod]
		$DeploymentMethod,
		[ValidateScript({ $DeploymentMethod -ne [PSADTNXT.Deployment.DeploymentMethod]::AppX -or $_ -match '^[\w.-]{3,50}_[a-hj-km-np-tv-z0-9]{13}' })]
		[AllowEmptyString()]
		[System.String]
		$PackageFamilyName
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			return [System.Management.Automation.ScriptBlock]::Create(
				$(
					switch ($DeploymentMethod) {
						([PSADTNXT.Deployment.DeploymentMethod]::MSI) { '$_.WindowsInstaller' }
						([PSADTNXT.Deployment.DeploymentMethod]::Burn) { '$_.BurnInstaller' }
						([PSADTNXT.Deployment.DeploymentMethod]::InnoSetup) { '$_.InnoSetupInstaller' }
						([PSADTNXT.Deployment.DeploymentMethod]::AppX) { "`$_.PSChildName -like '$($PackageFamilyName.Split('_')[0])_*_$($PackageFamilyName.Split('_')[-1])'" }
						default { [System.String]::Empty }
					}
				)
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
