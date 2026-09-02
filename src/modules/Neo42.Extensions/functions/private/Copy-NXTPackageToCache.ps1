function Copy-NXTPackageToCache {
	<#
	.SYNOPSIS
	Copy the package files to the cache directory without DirFiles and SupportFiles.
	#>
	[CmdletBinding()]
	param (
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession)
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			# Create hollow file copy of package at package registry.
			[System.IO.DirectoryInfo]$deploymentFilesContainer = [System.IO.Path]::Combine($ADTSession.NXT.Package.Directory.FullName, 'neo42-Install')
			Write-ADTLogEntry -Message "Copying files from [$($ADTSession.NXT.DeployAppScript.Directory.FullName)] to [$deploymentFilesContainer]" -DebugMessage

			# Clear the old package files
			if ($deploymentFilesContainer.Parent.Exists) { $deploymentFilesContainer.Parent.Delete($true) }
			$deploymentFilesContainer.Create()

			# Copy the files to the cache directory, excluding DirFiles for a hollow copy
			Get-ChildItem -Path $ADTSession.NXT.DeployAppScript.Directory.FullName -Exclude '.*', 'Files' |
				Copy-Item -Force -Recurse -Destination $deploymentFilesContainer.FullName

			# Update paths
			if ($ADTSession.DirSupportFiles) {
				$ADTSession.DirSupportFiles = [System.Text.RegularExpressions.Regex]::Replace(
					$ADTSession.DirSupportFiles,
					[System.Text.RegularExpressions.Regex]::Escape($ADTSession.NXT.DeployAppScript.Directory.FullName),
					$deploymentFilesContainer.FullName,
					[System.Text.RegularExpressions.RegexOptions]::IgnoreCase
				)
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
