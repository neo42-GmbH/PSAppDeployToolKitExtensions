function Invoke-NXTShortcutOperation {
	<#
	.SYNOPSIS
	Apply the shortcut operations stored in the session.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Purge', Justification = 'Parameter is used in script block.')]
	param (
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession),
		[System.Management.Automation.SwitchParameter]
		$Purge
	)

	try {
		if ($ADTSession.NXT.ManagedShortcuts) {
			Write-ADTLogEntry -Message 'Applying managed shortcut operations.'
		}
		else {
			Write-ADTLogEntry -Message 'No managed shortcuts configured. Skipping shortcut operations.' -DebugMessage
			return
		}

		foreach ($shortcut in $ADTSession.NXT.ManagedShortcuts) {
			[System.IO.FileInfo]$target = [System.IO.Path]::Combine(
				[System.Environment]::GetFolderPath(
					$(
						if ($shortcut.Location -eq [PSADTNXT.Deployment.ShortcutLocation]::Desktop) {
							[System.Environment+SpecialFolder]::CommonDesktopDirectory
						}
						elseif ($shortcut.Location -eq [PSADTNXT.Deployment.ShortcutLocation]::StartMenu) {
							[System.Environment+SpecialFolder]::CommonStartMenu
						}
						else {
							[System.Collections.Hashtable]$errorParams = @{
								Exception    = [System.ApplicationException]::new("Unknown shortcut location: $($shortcut.Location)")
								Category     = [System.Management.Automation.ErrorCategory]::InvalidArgument
								ErrorId      = 'UnknownShortcutLocation'
								TargetObject = $shortcut
							}
							throw (New-ADTErrorRecord @errorParams)
						}
					)
				),
				$shortcut.Target
			)

			if (-not $Purge -and $shortcut.Mode -ne [PSADTNXT.Deployment.ShortcutOperation]::Delete) {
				switch ($shortcut.Mode) {
					([PSADTNXT.Deployment.ShortcutOperation]::Create) {
						Write-ADTLogEntry -Message "Creating shortcut [$($target.FullName)] pointing to [$($shortcut.Source)]."
						$target.Delete()
						New-ADTShortcut -LiteralPath $target.FullName -TargetPath $shortcut.Source
					}
					([PSADTNXT.Deployment.ShortcutOperation]::Copy) {
						[System.IO.FileInfo]$source = if ([System.IO.Path]::IsPathRooted($shortcut.Source)) {
							$shortcut.Source
						}
						else {
							[System.IO.Path]::Combine(
								[System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonStartMenu),
								$shortcut.Source
							)
						}
						if ($source.Exists) {
							Write-ADTLogEntry -Message "Copying shortcut from [$($source.FullName)] to [$($target.FullName)]."
							$null = $source.CopyTo($target.FullName, $true)
						}
						else {
							Write-ADTLogEntry -Severity Warning -Message "Source shortcut [$($source.FullName)] does not exist. Cannot copy to [$($target.FullName)]."
						}
					}
				}
			}
			else {
				if ($target.Exists) {
					Write-ADTLogEntry -Message "Deleting shortcut [$($target.FullName)]."
					$target.Delete()
				}
				else {
					Write-ADTLogEntry -Message "Shortcut [$($target.FullName)] does not exist. Skipping deletion." -DebugMessage
				}
			}
		}
	}
	catch {
		Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
	}
}
