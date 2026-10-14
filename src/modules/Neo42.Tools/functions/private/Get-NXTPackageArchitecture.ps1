function Get-NXTPackageArchitecture {
	<#
	.SYNOPSIS
	Determines the architecture of the given package.
	#>
	param(
		[Parameter(Mandatory)]
		[System.IO.DirectoryInfo]
		$Package
	)
	if (([System.Management.Automation.Language.HashtableAst]$psd1 = Get-NXTPackageConfigHashtableAst -Package $Package)) {
		return (Get-NXTHashtableAstKey (Get-NXTHashtableAstKey $psd1 Package) Architecture).Value
	}
	elseif ([PSCustomObject]$json = Get-NXTPackageConfigJsonObject -Package $Package) {
		return $json | Select-Object -ExpandProperty AppArch
	}
	else {
		throw 'No compatible configuration found.'
	}
}
