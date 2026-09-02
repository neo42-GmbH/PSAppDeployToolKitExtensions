function Wait-NXTFileSystemIsRemoved {
	<#
	.SYNOPSIS
	Monitors the removal of a specified file within a set timeout period.
	.DESCRIPTION
	This function checks for the disappearance of a specified file within a given time frame.
	It continuously monitors the file's presence until the file is removed or the timeout is reached.
	The function also supports the resolution of CMD environment variables in the file path.
	.INPUTS
	System.IO.FileSystemInfo - The filesystem object to monitor.
	.OUTPUTS
	System.Boolean - Returns true if the file is removed within the timeout period, otherwise false.
	.PARAMETER Path
	The path to the file or directory to monitor.
	.PARAMETER Timeout
	The maximum time to wait for the file to be removed.
	.EXAMPLE
	Wait-NXTFileSystemIsRemoved -Path "C:\Temp\Sources\Installer.exe" -Timeout '00:02:00'

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
		$Timeout = '00:01:00'
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[System.DateTime]$endTime = [System.DateTime]::Now.Add($Timeout)
			while ($true -eq (Test-Path -LiteralPath $Path)) {
				if ([System.DateTime]::Now -ge $endTime) {
					Write-ADTLogEntry -Severity Warning -Message "Path [$Path] did not disappear within the specified timeout period of [$Timeout]." -DebugMessage
					return $false
				}
				Start-Sleep -Seconds 1
			}
			Write-ADTLogEntry -Message "Path [$Path] disappeared within the specified timeout period of [$Timeout]." -DebugMessage
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
