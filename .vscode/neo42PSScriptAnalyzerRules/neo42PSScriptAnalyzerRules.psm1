function New-GenericAnalyzerSuggestion {
	<#
	.SYNOPSIS
	Creates a new suggestion object for the ScriptAnalyzer.
	#>
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent])]
	Param(
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Token')]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.Language.IScriptExtent]
		$Extent,
		[Parameter(Mandatory = $true, Position = 1)]
		[string]
		$Correction,
		[Parameter(Mandatory = $false, Position = 2)]
		[string]
		$Description
	)

	[int]$startLineNumber = $Extent.StartLineNumber
	[int]$endLineNumber = $Extent.EndLineNumber
	[int]$startColumnNumber = $Extent.StartColumnNumber
	[int]$endColumnNumber = $Extent.EndColumnNumber
	[string]$correction = $Correction
	[string]$file = $MyInvocation.MyCommand.Definition
	[string]$optionalDescription = $Description
	$objParams = @{
		TypeName     = 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent'
		ArgumentList = $startLineNumber, $endLineNumber, $startColumnNumber,
		$endColumnNumber, $correction, $file, $Description
	}
	return New-Object @objParams
}

function neo42PSUseCorrectTokenCapitalization {
	<#
	.SYNOPSIS
	Checks that tokens are capitalized correctly.
	.DESCRIPTION
	Checks that tokens are capitalized correctly.
	.INPUTS
	[System.Management.Automation.Language.Token[]]
	.OUTPUTS
	[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
	#>
	[CmdletBinding()]
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.Language.Token[]]
		$testToken
	)
	Begin {
		[string[]]$keywordList = @('if', 'else', 'elseif', 'function', 'foreach', 'for', 'while', 'do', 'in', 'switch', 'try', 'catch', 'finally', 'return', 'break', 'continue', 'throw', 'exit', 'Process', 'Begin', 'End', 'Param')
	}
	Process {
		foreach ($token in $testToken) {
			## Check if the token is a keyword and if it is already in the correct case
			if ($false -eq $token.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::Keyword)) {
				continue
			}
			## Get the correct spelling of the token
			[string]$spelling = $keywordList | Where-Object { $_ -ieq $token.Text } | Select-Object -First 1
			## Check if we have a suggestion, otherwise return nothing
			if ($true -eq [string]::IsNullOrWhiteSpace($spelling) -or $spelling -ceq $token.Text) {
				continue
			}
			## Create a suggestion object
			$suggestedCorrections = New-Object System.Collections.ObjectModel.Collection["Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent"]
			$suggestedCorrections.add(
				(New-GenericAnalyzerSuggestion -Extent $token.Extent -Correction $spelling -Description "Use '$spelling' instead of '$($token.Text)'.")
			) | Out-Null
			## Return the diagnostic record
			$results += [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
				'Message'              = "The token '$($token.Text)' is not capitalized correctly."
				'Extent'               = $token.Extent
				'RuleName'             = $PSCmdlet.MyInvocation.InvocationName
				'Severity'             = 'Warning'
				'SuggestedCorrections' = $suggestedCorrections
			}
		}
		return $results
	}
}

Export-ModuleMember -Function "neo42*"
