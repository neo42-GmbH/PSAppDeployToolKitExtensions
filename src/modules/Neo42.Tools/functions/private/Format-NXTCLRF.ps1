function Format-NXTCLRF {
	<#
	.SYNOPSIS
	Formats line breaks in unified CLRF
	#>
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[System.String]
		$InputObject
	)
	process {
		return ($InputObject -replace '\r\n', "`n" -replace '\r', "`n" -replace '\n', "`r`n")
	}
}
