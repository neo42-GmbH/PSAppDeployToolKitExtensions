function Remove-NXTPackageDirectory {
	<#
	.SYNOPSIS
	Starts a separate process that clears the package cache, once all files are released.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Internal function, no ShouldProcess required')]
	param (
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession)
	)

	if (-not $ADTSession.NXT.Package.RootDirectory -or
		-not $ADTSession.NXT.Package.RootDirectory.Exists -or
		-not $ADTSession.NXT.Package.Directory -or
		-not $ADTSession.NXT.Package.Directory.Exists
	) {
		Write-ADTLogEntry -Severity Warning -Message 'Package root or package directory does not exist. Skipping package directory removal.'
		return
	}

	if ($ExecutionContext.SessionState.Module.ModuleBase.StartsWith($ADTSession.NXT.Package.Directory.FullName, [System.StringComparison]::OrdinalIgnoreCase)) {
		Write-ADTLogEntry -Message 'Starting process to remove the package cache post deployment.'
		[System.String]$removeScript = ConvertTo-NXTPsBinaryArgument `
			-Command "Wait-Process $PID 60 -ea 0;rm -v -r (`$d=gi `$args[1] -ea 1).FullName;while((`$d=`$d.Parent) -and `$d.FullName.StartsWith(`$args[0])){rm -v `$d.FullName}" `
			-Arguments @{ 0 = $ADTSession.NXT.Package.RootDirectory.FullName; 1 = $ADTSession.NXT.Package.Directory.FullName }

		Start-ADTProcess -NoWait -UseShellExecute -WindowStyle Hidden `
			-WorkingDirectory ([System.IO.Path]::GetTempPath())`
			-FilePath (Get-ADTPowerShellProcessPath) `
			-ArgumentList $removeScript
	}
	else {
		Write-ADTLogEntry -Message "Removing package cache [$($ADTSession.NXT.Package.Directory.FullName)] directly."
		Remove-Item -Path $ADTSession.NXT.Package.Directory.FullName -Recurse
		Remove-NXTEmptyFolder -Path $ADTSession.NXT.Package.Directory.Parent.FullName -RootPath $ADTSession.NXT.Package.RootDirectory.FullName -WarningAction SilentlyContinue
	}
}
