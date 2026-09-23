function Wait-NXTFileNotInUse {
	<#
	.SYNOPSIS
	Wait until a file is no longer in use or in use by another process.
	.DESCRIPTION
	Wait until a file is no longer in use or in use by another process.
	.INPUTS
	System.IO.FileInfo - The file to check.
	.OUTPUTS
	System.Boolean - Returns true if the file is no longer in use, otherwise false.
	System.IO.FileSystemInfo - Returns the filesystem object if PassThru is specified.
	With the -IsInUse switch, the test will be inverted.
	.PARAMETER Path
	The path to the file to check.
	.PARAMETER Timeout
	The maximum time to wait for the file to be released.
	.PARAMETER Interval
	The interval at which to check for the file's usage status.
	.PARAMETER PassThru
	Instead of returning a boolean, return the object.
	.PARAMETER IsInUse
	Instead of checking whether the file is not in use, check whether it is in use.
	.EXAMPLE
	Wait-NXTFileNotInUse -Path 'C:\Temp\file.txt' -Timeout '00:02:00'

	Wait until the file 'C:\Temp\file.txt' is no longer in use by another process or until the timeout of 120 seconds is reached.
	#>
	[OutputType([System.Boolean], [System.IO.FileSystemInfo])]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('LiteralPath', 'PSPath')]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Path,
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$Timeout = '00:01:00',
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$Interval = '00:00:01.000',
		[System.Management.Automation.SwitchParameter]
		$PassThru,
		[System.Management.Automation.SwitchParameter]
		$IsInUse
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if ($IsInUse) {
				[System.Management.Automation.ScriptBlock]$waitWhile = { -not (Test-NXTFileInUse -Path $Path) }
				[System.String]$successMessage = "The file [$Path] was in use within the specified timeout period of [$Timeout]."
				[System.String]$failureMessage = "The file [$Path] was still not in use after the specified timeout period of [$Timeout]."
			}
			else {
				[System.Management.Automation.ScriptBlock]$waitWhile = { Test-NXTFileInUse -Path $Path }
				[System.String]$successMessage = "The file [$Path] was not in use within the specified timeout period of [$Timeout]."
				[System.String]$failureMessage = "The file [$Path] was still in use after the specified timeout period of [$Timeout]."
			}
			[System.Boolean]$result = $true
			[System.String]$severity = 'Info'
			[System.String]$message = $successMessage
			[System.DateTime]$endTime = [System.DateTime]::Now.Add($Timeout)
			while ($waitWhile.Invoke()) {
				if ([System.DateTime]::Now -ge $endTime) {
					$result = $false
					$severity = 'Warning'
					$message = $failureMessage
					break
				}
				Start-Sleep -Milliseconds $Interval.TotalMilliseconds
			}
			Write-ADTLogEntry -Message $message -Severity $severity -DebugMessage
			if ($PassThru) {
				if ($IsInUse) {
					return (if ($result) { $null } else { Get-Item -LiteralPath $Path })
				}
				else {
					return (if ($result) { Get-Item -LiteralPath $Path } else { $null })
				}
			}
			else {
				return $result
			}
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
