function Get-NXTDriveType {
	<#
	.SYNOPSIS
	Retrieves the drive type of a given drive.
	.DESCRIPTION
	The Get-NxtDriveType function determines the type of a given drive.
	If an invalid drive name is provided, it will throw an error. If the drive is not mounted, NoRootDirectory will be returned.
	.INPUTS
	System.String - The drive letter or ID of the drive to check.

	System.Management.Automation.PSDriveInfo - The PSDriveInfo object to check.

	Microsoft.Management.Infrastructure.CimInstance - The MSFT_Volume cim instance to check.
	.OUTPUTS
	System.IO.DriveType - The type of the drive.
	.PARAMETER Name
	A string representing the drive letter.
	.EXAMPLE
	Get-NXTDriveType -Name "C:"

	This example retrieves the type of the C: drive.
	.EXAMPLE
	Get-PSDrive C | Get-NXTDriveType

	This example retrieves the type of the C: drive using the PSProvider.
	.EXAMPLE
	Get-Volume -DriveLetter C | Get-NXTDriveType

	This example retrieves the type of the C: drive using the Get-Volume cmdlet (uses CimInstance).
	#>
	[OutputType([System.IO.DriveType])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('DriveLetter', 'DriveName')]
		[System.String]
		$Name
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
			return $drive.DriveType
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
