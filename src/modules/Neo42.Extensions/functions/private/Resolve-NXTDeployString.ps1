function Resolve-NXTDeployString {
	<#
	.SYNOPSIS
	Generates a deploy string for this package with optional arguments.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '', Justification = 'OutputType is correct.')]
	[OutputType([System.String], [System.String[]])]
	[CmdletBinding()]
	param (
		[ValidateNotNull()]
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession),
		[ValidateNotNull()]
		[System.String]
		$Root = $ADTSession.NXT.Package.Directory.FullName,
		[System.Collections.Hashtable]
		$Arguments,
		[System.Management.Automation.SwitchParameter]
		$BinarySeparate,
		[System.Management.Automation.SwitchParameter]
		$PreferExecutable
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[System.IO.FileInfo]$deployExe = Resolve-NXTPath -LiteralPath "$Root\DeployNxtApplication.exe" -IncludeNonExistent -AsProviderPath -ProviderName 'FileSystem' -PathType Leaf
			[System.IO.FileInfo]$deployPs1 = Resolve-NXTPath -LiteralPath "$Root\Deploy-Application.ps1" -IncludeNonExistent -AsProviderPath -ProviderName 'FileSystem' -PathType Leaf

			[System.Boolean]$isPowerShell = -not $PreferExecutable -or -not $deployExe.Exists
			[System.String]$binary = if ($isPowerShell) { Get-ADTPowerShellProcessPath } else { $deployExe.FullName }
			[System.String]$argumentString = if ($isPowerShell) {
				ConvertTo-NXTPsBinaryArgument -Arguments $Arguments -File $deployPs1.FullName -UseLastExitCode
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
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
