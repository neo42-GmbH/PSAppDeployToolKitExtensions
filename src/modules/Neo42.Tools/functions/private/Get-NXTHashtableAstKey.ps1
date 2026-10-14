function Get-NXTHashtableAstKey {
	<#
	.SYNOPSIS
	Extracts the value to a given key from a hashtable AST
	#>
	param(
		[Parameter(Mandatory, Position = 0)]
		[System.Management.Automation.Language.HashtableAst]
		$Hashtable,
		[Parameter(Mandatory, Position = 1)]
		[System.String]
		$Key
	)
	return $Hashtable.KeyValuePairs |
		Where-Object -FilterScript { $_.Item1.Value -eq $Key } |
		Select-Object -ExpandProperty Item2
}
