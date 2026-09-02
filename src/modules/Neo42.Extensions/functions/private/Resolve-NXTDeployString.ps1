function Resolve-NXTDeployString {
	<#
	.SYNOPSIS
	Generates a deploy string for this package with optional arguments.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '', Justification = 'OutputType is correct.')]
	[OutputType([System.String], [System.String[]])]
	[CmdletBinding()]
	param (
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession),
		[ValidateNotNull()]
		[System.IO.DirectoryInfo]
		$Root = $ADTSession.NXT.Package.Directory,
		[System.Collections.Hashtable]
		$Arguments,
		[System.Management.Automation.SwitchParameter]
		$BinarySeparate,
		[System.Management.Automation.SwitchParameter]
		$PreferExecutable
	)

	try {
		[System.Boolean]$isPowerShell = -not $PreferExecutable -or -not [System.IO.File]::Exists("$($Root.FullName)\DeployNxtApplication.exe")
		[System.String]$binary = if ($isPowerShell) { Get-ADTPowerShellProcessPath } else { "$($Root.FullName)\DeployNxtApplication.exe" }
		[System.String]$argumentString = if ($isPowerShell) {
			ConvertTo-NXTPsBinaryArgument -Arguments $Arguments -File "$($Root.FullName)\Deploy-Application.ps1" -UseLastExitCode
		}
		elseif ($Arguments) {
			ConvertTo-NXTPsArgumentString -InputObject $Arguments
		}

		if ($BinarySeparate) {
			return $binary, $argumentString
		}
		else {
			if ($binary -match '\s') { $binary = "`"$binary`"" }
			return "$binary $argumentString"
		}
	}
	catch {
		Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
	}
}
