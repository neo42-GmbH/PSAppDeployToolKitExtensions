function ConvertTo-NXTRegexQuery {
	<#
	.SYNOPSIS
	Gets the filter expression for the specified installer type.
	#>
	[OutputType([System.String])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipeline)]
		[System.String]
		$Text
	)

	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Text.RegularExpressions.Regex]$wordBoundaryRegex = [System.Text.RegularExpressions.Regex]::new('[^A-Za-z0-9]+', [System.Text.RegularExpressions.RegexOptions]::Compiled)
	}
	process {
		try {
			$Text = $wordBoundaryRegex.Replace($Text, '___BOUND___')
			$Text = [System.Text.RegularExpressions.Regex]::Escape($Text)
			return [System.Text.RegularExpressions.Regex]::Replace($Text, '(___BOUND___)+', '.*')
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
