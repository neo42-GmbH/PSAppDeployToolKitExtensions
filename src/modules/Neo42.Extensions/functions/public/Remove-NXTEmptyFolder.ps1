function Remove-NXTEmptyFolder {
	<#
	.SYNOPSIS
	Removes only empty folders.
	.DESCRIPTION
	This function is designed to remove folders if and only if they are empty.
	If the specified folder contains any files or other items, the function continues without taking any action.
	.INPUTS
	System.IO.DirectoryInfo[] - The folder(s) to remove.
	.PARAMETER Path
	The path to the folder(s) to remove.
	.PARAMETER LiteralPath
	The literal path to the folder(s) to remove.
	.PARAMETER Filter
	A filter to qualify the Path parameter.
	.PARAMETER Exclude
	A filter to exclude items from the Path parameter.
	.PARAMETER Include
	A filter to include items in the Path parameter.
	.PARAMETER Force
	Determines if hidden folders should be processed.
	.PARAMETER RootPath
	The path to the root folder to stop the recursion at.
	.EXAMPLE
	Remove-NxtEmptyFolder -Path "C:\Temp\MyFolder"

	Removes the folder "C:\Temp\MyFolder" if it is empty.
	#>
	[CmdletBinding(DefaultParameterSetName = 'Path', SupportsShouldProcess)]
	param (
		[Parameter(Position = 0, ParameterSetName = 'Path', Mandatory)]
		[SupportsWildcards()][ValidateNotNullOrEmpty()]
		[System.String[]]
		$Path,
		[Parameter(ParameterSetName = 'LiteralPath', Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('PSPath')]
		[ValidateNotNullOrEmpty()]
		[System.String[]]
		$LiteralPath,
		[SupportsWildcards()]
		[System.String]
		$Filter,
		[SupportsWildcards()]
		[System.String[]]
		$Exclude,
		[SupportsWildcards()]
		[System.String[]]
		$Include,
		[System.Management.Automation.SwitchParameter]
		$Force,
		[Alias('RootPathToRecurseUpTo')]
		[ValidateScript({ [System.IO.Path]::IsPathRooted($_) })]
		[System.String]
		$RootPath
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Char[]]$pathSeparators = @([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
	}
	process {
		try {
			foreach ($directory in (Resolve-NXTPath @PSBoundParameters -ProviderName 'FileSystem' -AsProviderPath -PathType Container -IncludeNonExistent)) {
				if (-not $PSBoundParameters.ContainsKey('RootPath')) {
					$RootPath = $directory
				}
				[System.Collections.Generic.List[System.String]]$pathComponents = $directory.TrimEnd($pathSeparators).Split($pathSeparators)
				[System.Collections.Generic.List[System.String]]$rootComponents = $RootPath.TrimEnd($pathSeparators).Split($pathSeparators)

				if ($rootComponents.Count -gt $pathComponents.Count -or
					-not [System.Linq.Enumerable]::SequenceEqual($pathComponents.GetRange(0, $rootComponents.Count), $rootComponents, [System.StringComparer]::OrdinalIgnoreCase)
				) {
					[System.Collections.Hashtable]$errorParams = @{
						Exception    = [System.ArgumentException]::new("The folder [$directory] is not a subfolder of the root path [$RootPath]")
						Category     = [System.Management.Automation.ErrorCategory]::InvalidArgument
						ErrorId      = 'NotSubfolderOfRoot'
						TargetObject = $directory
					}
					throw (New-ADTErrorRecord @errorParams)
				}

				[System.Collections.Generic.List[System.String]]$removalComponents = $pathComponents.GetRange($rootComponents.Count, $pathComponents.Count - $rootComponents.Count)
				while ($removalComponents) {
					[System.String]$componentPath = [System.String]::Join([System.IO.Path]::DirectorySeparatorChar, ($rootComponents + $removalComponents))
					if ([System.IO.Directory]::Exists($componentPath)) {
						try {
							if (-not $PSCmdlet.ShouldProcess($componentPath, 'Remove folder if empty')) { break }
							[System.IO.Directory]::Delete($componentPath, $false) # This will throw an exception if the directory is not empty.
							Write-ADTLogEntry -Message "Removed empty directory [$componentPath]."
							$removalComponents.RemoveAt($removalComponents.Count - 1)
						}
						catch {
							Write-ADTLogEntry -Severity Warning -Message "The directory [$componentPath] could not be removed. [$($_.Exception.Message)]"
							break
						}
					}
					else {
						Write-ADTLogEntry -Severity Warning -Message "The directory [$componentPath] does not exist."
						$removalComponents.RemoveAt($removalComponents.Count - 1)
					}
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
