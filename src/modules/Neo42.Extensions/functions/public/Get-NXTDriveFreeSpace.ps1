function Get-NXTDriveFreeSpace {
	<#
	.SYNOPSIS
	Retrieves the free space in a given unit.
	.DESCRIPTION
	Retrieves the free space in a given unit. The default unit is bytes.
	If the drive is not mounted, or the drive name is invalid, an error will be thrown.
	.INPUTS
	System.String - The drive letter or ID of the drive to check.

	System.Management.Automation.PSDriveInfo - The PSDriveInfo object to check.

	Microsoft.Management.Infrastructure.CimInstance - The MSFT_Volume cim instance to check.
	.OUTPUTS
	System.UInt64 - The free space in the specified unit.
	.PARAMETER Name
	A string representing the drive letter.
	.PARAMETER Unit
	The output unit size. The default is bytes.
	.EXAMPLE
	Get-NxtDriveFreeSpace -DriveName "C:"

	This example retrieves the free space of the C: drive in bytes.
	.EXAMPLE
	Get-NxtDriveFreeSpace -DriveName "D" -Unit "GB"

	This example retrieves the free space of the D: drive in gigabytes.
	.EXAMPLE
	Get-PSDrive C | Get-NxtDriveFreeSpace -Unit "GB"

	This example retrieves the type of the C: drive using the PSProvider and converts the output to gigabytes.
	.NOTES
	The output is rounded down to the nearest whole number.
	#>
	[OutputType([System.UInt64])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('DriveLetter', 'DriveName')]
		[System.String]
		$Name,
		[Parameter(Position = 1)]
		[PSADTNXT.IO.DataSizeUnit]
		$Unit = [PSADTNXT.IO.DataSizeUnit]::B
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[System.IO.DriveInfo]$drive = [System.IO.DriveInfo]::new($Name)
			if (-not $drive.IsReady) {
				[System.Collections.Hashtable]$errorParams = @{
					Exception         = [System.IO.DriveNotFoundException]::new('The drive is not ready.')
					Category          = [System.Management.Automation.ErrorCategory]::ResourceUnavailable
					ErrorId           = 'DriveNotReady'
					RecommendedAction = 'Ensure the queried drive is mounted and ready.'
					TargetName        = $Name
				}
				throw (New-ADTErrorRecord @errorParams)
			}
			return [System.UInt64][System.Math]::Floor(($drive.AvailableFreeSpace / "$("1$Unit" -replace '1B', '1D')"))
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
