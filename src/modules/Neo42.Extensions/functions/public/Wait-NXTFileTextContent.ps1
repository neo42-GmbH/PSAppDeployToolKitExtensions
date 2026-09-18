function Wait-NXTFileTextContent {
	<#
	.SYNOPSIS
	Monitors the content of a specified file for the presence of a string within a set timeout period.
	.DESCRIPTION
	This function checks for the presence of a string within the content of a specified file within a given time frame.
	.INPUTS
	System.String - The string to search for within the file.
	.OUTPUTS
	System.Boolean - Returns true if the string is found within the timeout period, otherwise false.
	.OUTPUTS
	System.Boolean - Returns true if the string is found within the timeout period, otherwise false.
	.PARAMETER Path
	The path to the file to monitor.
	.PARAMETER SearchString
	The string to search for within the file.
	.PARAMETER Timeout
	The maximum time to wait for the string to be found.
	.PARAMETER TestInterval
	The interval at which to check for the string's presence.
	.PARAMETER PassThru
	Instead of returning a boolean, return the object.
	.PARAMETER IsRemoved
	Instead of checking for the presence of the string, check for its removal.
	.EXAMPLE
	Wait-NXTFileTextContent -Path "C:\Temp\Sources\Installer.exe" -SearchString "Installation" -Timeout '00:02:00'

	Monitors for the string "Installation" in the specified file and waits up to 120 seconds for it to be found.
	.EXAMPLE
	Wait-NXTFileTextContent -Path "C:\Temp\Sources\Installer.exe" -SearchString "Installation" -Timeout '00:02:00' -IsRemoved

	Monitors for the string "Installation" in the specified file and waits up to 120 seconds for it to be removed.
	#>
	[OutputType([System.Boolean], [System.IO.FileSystemInfo])]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('LiteralPath', 'PSPath')]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Path,
		[Parameter(Position = 1, Mandatory)]
		[Alias('String', 'Text')]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$SearchString,
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$Timeout = '00:01:00',
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$TestInterval = '00:00:01.000',
		[System.Management.Automation.SwitchParameter]
		$PassThru,
		[System.Management.Automation.SwitchParameter]
		$IsRemoved
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if ($IsRemoved) {
				[System.Management.Automation.ScriptBlock]$waitWhile = { -not (Test-NXTFileInUse -Path $Path) }
				[System.String]$successMessage = "Path [$Path] disappeared within the specified timeout period of [$Timeout]."
				[System.String]$failureMessage = "Path [$Path] did not disappear within the specified timeout period of [$Timeout]."
			}
			else {
				[System.Management.Automation.ScriptBlock]$waitWhile = { -not (Get-Item -LiteralPath $Path -ErrorAction Ignore) }
				[System.String]$successMessage = "Path [$Path] appeared within the specified timeout period of [$Timeout]."
				[System.String]$failureMessage = "Path [$Path] did not appear within the specified timeout period of [$Timeout]."
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
				Start-Sleep -Milliseconds $TestInterval.TotalMilliseconds
			}
			Write-ADTLogEntry -Message $message -Severity $severity -DebugMessage
			if ($PassThru) {
				if ($IsRemoved) {
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
