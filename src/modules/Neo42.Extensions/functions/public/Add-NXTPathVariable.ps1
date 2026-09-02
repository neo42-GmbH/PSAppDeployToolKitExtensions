function Add-NXTPathVariable {
	<#
	.SYNOPSIS
	Extends the PATH environment variable.
	.DESCRIPTION
	Extends the PATH environment variable of a specified target with the given path(s).
	If the path already exists, it will not be added again. Empty values will be removed.
	.INPUTS
	System.String[] - The path(s) to add to the PATH variable.
	System.IO.DirectoryInfo[] - The path(s) to add to the PATH variable.
	.PARAMETER Path
	The path(s) to add to the PATH variable.
	.PARAMETER Prepend
	When specified, the path will be added at the beginning of the PATH variable.
	.PARAMETER Target
	Determines the scope of the PATH variable to be modified.
	.EXAMPLE
	Add-NXTPathVariable -Path 'C:\Program Files\Example\bin'

	Adds the path 'C:\Program Files\Example\bin' to the machine PATH variable.
	.EXAMPLE
	Add-NXTPathVariable -Path 'C:\Program Files\Example\bin' -Prepend -Target Process

	Adds the path 'C:\Program Files\Example\bin' to the process PATH variable at the beginning.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Prepend', Justification = 'Parameter is used in script block.')]
	[CmdletBinding(SupportsShouldProcess)]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias('FullName')]
		[System.String[]]
		$Path,
		[System.Management.Automation.SwitchParameter]
		$Prepend,
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
				if (-not [System.IO.Path]::IsPathRooted($pathEntryResolved)) {
					[System.Collections.Hashtable]$errorParams = @{
						Exception         = [System.ArgumentException]::new("The path [$pathEntryResolved] is not rooted.")
						Category          = [System.Management.Automation.ErrorCategory]::InvalidArgument
						ErrorId           = 'PathNotRooted'
						RecommendedAction = 'Specify a rooted path.'
						TargetName        = $pathEntryResolved
					}
					throw (New-ADTErrorRecord @errorParams)
				}
				if (-not [System.IO.Directory]::Exists($pathEntryResolved)) {
					Write-ADTLogEntry -Severity Warning -Message "The new path entry [$pathEntryResolved] does not exist."
				}

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

						if (-not $currentPathComponents.Exists({ $args[0].TrimEnd($pathSeparators) -in $lookupEntries })) {
							if ($Prepend) {
								$currentPathComponents.Insert(0, $pathEntry)
							}
							else {
								$currentPathComponents.Add($pathEntry)
							}
							if ($PSCmdlet.ShouldProcess($_, 'Update PATH variable')) {
								Set-ADTRegistryKey -LiteralPath $_ -Name 'PATH' -Value ([System.String]::Join(';', $currentPathComponents)) -Type ExpandString
							}
						}
						else {
							Write-ADTLogEntry -Severity Warning -Message "Path entry [$pathEntry] already exists in the PATH variable."
						}
					}
				}

				# Reflect the change in the current process environment immediately
				Update-ADTEnvironmentPsProvider

				# Process must be handled seperatly as it is not reflected in registry. We can work more loosely here as it is temporary
				if ($Target -eq [System.EnvironmentVariableTarget]::Process) {
					[System.Collections.Generic.List[System.String]]$pathEntries = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Process).Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
					if ($Prepend) {
						$pathEntries.Insert(0, $pathEntry)
					}
					else {
						$pathEntries.Add($pathEntry)
					}
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
