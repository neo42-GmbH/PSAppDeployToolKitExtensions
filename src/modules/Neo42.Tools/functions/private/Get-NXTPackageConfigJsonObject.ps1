function Get-NXTPackageConfigJsonObject {
	<#
	.SYNOPSIS
	Looks up the package config psd1 file and returns the core hashtable ast.
	#>
	param(
		[Parameter(Mandatory)]
		[System.IO.DirectoryInfo]
		$Package
	)
	if ([System.IO.FileInfo[]]$conf = $Package.GetFiles('neo42PackageConfig.json')) {
		return (ConvertFrom-Json -InputObject (Get-Content -Raw -LiteralPath $conf[0].FullName))
	}
}
