function Wait-NXTFileSystem {
	<#
	.SYNOPSIS
	Monitors the presence of a specified path within a set timeout period.
	.DESCRIPTION
	This function checks for the existence of a specified file or folder within a given time frame.
	It continuously checks for the existence until the timeout is reached.
	.INPUTS
	System.IO.FileSystemInfo - The filesystem object to monitor.
	.OUTPUTS
	System.Boolean - Returns true if the path appears within the timeout period, otherwise false.

	System.IO.FileSystemInfo - Returns the file system object if PassThru is specified
	.PARAMETER Path
	The path to the file or directory to monitor.
	.PARAMETER Timeout
	The maximum time to wait for the file to appear.
	.PARAMETER PassThru
	Instead of returning a boolean, return the object.
	.EXAMPLE
	Wait-NXTFileSystem -Path "C:\Temp\Sources\Installer.exe" -Timeout '00:02:00'

	Monitors for 'Installer.exe' in the specified directory and waits up to 120 seconds for it to appear.
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
		[System.Management.Automation.SwitchParameter]
		$PassThru
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[System.DateTime]$endTime = [System.DateTime]::Now.Add($Timeout)
			while (-not ([System.IO.FileSystemInfo]$fsItem = Get-Item -LiteralPath $Path -ErrorAction Ignore)) {
				if ([System.DateTime]::Now -ge $endTime) {
					Write-ADTLogEntry -Severity Warning -Message "Path [$Path] did not appear within the specified timeout period of [$Timeout]." -DebugMessage
					if ($PassThru) {
						return $null
					}
					else {
						return $false
					}
				}
				Start-Sleep -Seconds 1
			}
			Write-ADTLogEntry -Message "Path [$Path] appeared within the specified timeout period of [$Timeout]." -DebugMessage
			if ($PassThru) {
				return $fsItem
			}
			else {
				return $false
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
