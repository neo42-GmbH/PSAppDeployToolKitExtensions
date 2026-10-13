function Write-NXTDiagnosticMessage {
	<#
	.SYNOPSIS
	Writes the diagnostric record in console readable fashion
	#>
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]
		$Record
	)
	process {
		[System.ConsoleColor]$color = switch -Wildcard ($Record.Severity) {
			'Warning' { [System.ConsoleColor]::Yellow }
			'*Error' { [System.ConsoleColor]::Red }
			default { [System.ConsoleColor]::White }
		}
		Write-Host "$($Record.Message) [$($Record.ScriptPath):$($Record.Line)] " -ForegroundColor $color
	}
}
