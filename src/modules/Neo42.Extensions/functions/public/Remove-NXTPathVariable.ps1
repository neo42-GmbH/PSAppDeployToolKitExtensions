function Remove-NXTPathVariable {
	<#
	.SYNOPSIS
	Removes a path from the PATH environment variable.
	.DESCRIPTION
	The Remove-NXTPathVariable cmdlet removes a path from the PATH environment variable of a specified target.
	.INPUTS
	System.String - The path(s) to remove from the PATH variable.

	System.IO.FileInfo - The path(s) to remove from the PATH variable.
	.PARAMETER Path
	The path(s) to remove from the PATH variable.
	.PARAMETER Target
	Determines the scope of the PATH variable to be modified.
	.EXAMPLE
	Remove-NXTPathVariable -Path 'C:\Program Files\Example\bin'

	Removes the path 'C:\Program Files\Example\bin' from the PATH variable of the current process.
	.EXAMPLE
	Remove-NXTPathVariable -Path 'C:\Program Files\Example\bin' -Target Machine

	Removes the path 'C:\Program Files\Example\bin' from the PATH variable of the machine.
	#>
	[CmdletBinding(SupportsShouldProcess)]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias('FullName')]
		[System.String[]]
		$Path,
		[System.EnvironmentVariableTarget]
		$Target = 'Machine'
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Char[]]$pathSeparators = @([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
	}
	process {
		try {
			foreach ($pathEntry in $Path) {
				[System.String]$pathEntryResolved = [System.Environment]::ExpandEnvironmentVariables($pathEntry)

				$(
					if ($Target -eq [System.EnvironmentVariableTarget]::Machine) {
						'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
					}
					elseif ($Target -eq [System.EnvironmentVariableTarget]::User) {
						Get-ADTUserProfiles -ExcludeDefaultUser -InformationAction SilentlyContinue | & { process { "HKEY_USERS\$($_.SID)\Environment" } }
					}
				) | & {
					process {
						[System.String]$currentPath = Get-ADTRegistryKey -LiteralPath $_ -Name 'PATH' -DoNotExpandEnvironmentNames -InformationAction SilentlyContinue
						[System.Collections.Generic.List[System.String]]$currentPathComponents = $currentPath.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
						[System.String[]]$lookupEntries = $pathEntry.TrimEnd($pathSeparators), $pathEntryResolved.TrimEnd($pathSeparators)
						if ($currentPathComponents.RemoveAll({ $args[0].TrimEnd($pathSeparators) -in $lookupEntries })) {
							if ($PSCmdlet.ShouldProcess($_, 'Update PATH variable')) {
								Set-ADTRegistryKey -LiteralPath $_ -Name 'PATH' -Value ([System.String]::Join(';', $currentPathComponents)) -Type ExpandString
							}
						}
						else {
							Write-ADTLogEntry -Severity Warning -Message "Path entry [$pathEntry] does not exist in the PATH variable."
						}
					}
				}

				# Reflect the change in the current process environment immediately
				Update-ADTEnvironmentPsProvider

				# Process must be handled seperatly as it is not reflected in registry. We can work more loosely here as it is temporary
				if ($Target -eq [System.EnvironmentVariableTarget]::Process) {
					[System.Collections.Generic.List[System.String]]$pathEntries = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Process).Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
					$null = $pathEntries.RemoveAll({ $args[0].TrimEnd($pathSeparators) -eq $pathEntry.TrimEnd($pathSeparators) })
					[System.Environment]::SetEnvironmentVariable('Path', ([System.String]::Join(';', $pathEntries)), [System.EnvironmentVariableTarget]::Process)
				}
				else {
					[System.Environment]::SetEnvironmentVariable('Path', $env:PATH, [System.EnvironmentVariableTarget]::Process)
				}
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
