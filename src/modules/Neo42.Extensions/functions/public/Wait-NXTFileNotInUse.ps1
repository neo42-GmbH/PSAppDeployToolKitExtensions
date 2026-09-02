function Wait-NXTFileNotInUse {
	<#
	.SYNOPSIS
	Wait until a file is no longer in use by another process.
	.DESCRIPTION
	Wait until a file is no longer in use by another process.
	.INPUTS
	System.IO.FileInfo - The file to check.
	.OUTPUTS
	System.Boolean - Returns true if the file is no longer in use, otherwise false.
	.PARAMETER Path
	The path to the file to check.
	.PARAMETER Timeout
	The maximum time to wait for the file to be released.
	.EXAMPLE
	Wait-NXTFileNotInUse -Path 'C:\Temp\file.txt' -Timeout '00:02:00'

	Wait until the file 'C:\Temp\file.txt' is no longer in use by another process or until the timeout of 120 seconds is reached.
	#>
	[OutputType([System.Boolean])]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('LiteralPath', 'PSPath')]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Path,
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$Timeout = '00:01:00'
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[System.DateTime]$endTime = [System.DateTime]::Now.Add($Timeout)
			while (Test-NXTFileInUse -Path $Path) {
				if ([System.DateTime]::Now -ge $endTime) {
					Write-ADTLogEntry -Severity Warning -Message "The specified file was still in use after [$Timeout]." -DebugMessage
					return $false
				}
				Start-Sleep -Seconds 1
			}
			Write-ADTLogEntry -Message "The file [$Path] was free within the specified timeout period of [$Timeout]." -DebugMessage
			return $true
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
