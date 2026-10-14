function Get-NXTPackageConfigHashtableAst {
	<#
	.SYNOPSIS
	Looks up the package config psd1 file and returns the core hashtable ast.
	#>
	param(
		[Parameter(Mandatory)]
		[System.IO.DirectoryInfo]
		$Package
	)
	if ([System.IO.FileInfo[]]$conf = $Package.GetFiles('neo42PackageConfig.psd1')) {
		return [System.Management.Automation.Language.Parser]::ParseFile($conf[0].FullName, [ref]$null, [ref]$null).Find({ $args[0] -is [System.Management.Automation.Language.HashtableAst] }, $false)
	}
}
