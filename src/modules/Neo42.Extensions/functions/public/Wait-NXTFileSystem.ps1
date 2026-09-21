function Wait-NXTFileSystem {
	<#
	.SYNOPSIS
	Monitors the presence or removal of a specified path within a set timeout period.
	.DESCRIPTION
	This function checks for the existence or disappearance of a specified file or folder within a given time frame.
	The function also supports the resolution of CMD environment variables in the filesystem path.
	.INPUTS
	System.IO.FileSystemInfo - The filesystem object to monitor.
	.OUTPUTS
	System.Boolean - Returns true if the path appears within the timeout period, otherwise false.
	System.IO.FileSystemInfo - Returns the filesystem object if PassThru is specified.
	With the -IsRemoved switch, the test will be inverted.
	.PARAMETER Path
	The path to the file or directory to monitor.
	.PARAMETER Timeout
	The maximum time to wait for the path to appear or disappear.
	.PARAMETER TestInterval
	The interval at which to check for the path's presence or removal.
	.PARAMETER PassThru
	Instead of returning a boolean, return the object.
	.PARAMETER IsRemoved
	Instead of checking for the presence of the path, check for its removal.
	.EXAMPLE
	Wait-NXTFileSystem -Path "C:\Temp\Sources\Installer.exe" -Timeout '00:02:00'

	Monitors for 'Installer.exe' in the specified directory and waits up to 120 seconds for it to appear.
	.EXAMPLE
	Wait-NXTFileSystem -Path "C:\Temp\Sources\Installer.exe" -Timeout '00:02:00' -IsRemoved

	Monitors for 'Installer.exe' in the specified directory and waits up to 120 seconds for it to disappear.
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
				[System.Management.Automation.ScriptBlock]$waitWhile = { Get-Item -LiteralPath $Path -Force -ErrorAction Ignore }
				[System.String]$successMessage = "Path [$Path] disappeared within the specified timeout period of [$Timeout]."
				[System.String]$failureMessage = "Path [$Path] did not disappear within the specified timeout period of [$Timeout]."
			}
			else {
				[System.Management.Automation.ScriptBlock]$waitWhile = { -not (Get-Item -LiteralPath $Path -Force -ErrorAction Ignore) }
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
