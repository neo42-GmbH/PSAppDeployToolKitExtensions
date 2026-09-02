function ConvertFrom-NXTCommandLine {
	<#
	.SYNOPSIS
	Converts an escaped string into a list of components.
	.DESCRIPTION
	Interprets the input string as a command line, and returns an array of strings that represent the command line components.
	.INPUTS
	System.String - The escaped string that should be convert into a list of components.

	PSADTNXT.Package.NxtRegisteredPackage - A registered package for which to retrieve the uninstall arguments.

	PSADT.Types.InstalledApplication - An installed application for which to retrieve the uninstall arguments.
	.OUTPUTS
	System.String[] - An array of strings that represent the command line components.
	.PARAMETER InputObject
	The escaped string that you want to convert into a list of components.
	.EXAMPLE
	ConvertFrom-NXTEscapedString -InputObject '"C:\my program.exe" -Argument1 "Value 1" -Argument2 '''Value 2''''

	This will return an array of strings: 'C:\my program.exe', '-Argument1', 'Value 1', '-Argument2', 'Value 2'.
	#>
	[OutputType([System.String[]])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[AllowEmptyString()]
		[Alias('UninstallString')]
		[System.String]
		$InputObject
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			if ([System.String]::IsNullOrWhiteSpace($InputObject)) { return }
			return [PSADT.ProcessManagement.CommandLineUtilities]::CommandLineToArgumentList($InputObject)
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
