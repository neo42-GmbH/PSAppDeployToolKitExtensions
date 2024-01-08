<#
    .SYNOPSIS
        This script cleans the $app folder of a neo42 package installation
    .NOTES
        # LICENSE #
        This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
        You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

        # COPYRIGHT #
        Copyright (c) 2024 neo42 GmbH, Germany.
    .LINK
        https://neo42.de/psappdeploytoolkit
#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RootPathToRecurseUpTo
)
$currentScript = $MyInvocation.MyCommand.Definition
#region Function Remove-NxtEmptyFolder
function Remove-NxtEmptyFolder {
	<#
	.SYNOPSIS
		Removes only empty folders.
	.DESCRIPTION
		This function is designed to remove folders if and only if they are empty. If the specified folder contains any files or other items, the function continues without taking any action.
	.PARAMETER Path
		Specifies the path to the empty folder to remove.
		This parameter is mandatory.
	.PARAMETER RootPathToRecurseUpTo
		Specifies the root path to recurse up to. If this parameter is not specified, the function will not recurse up.
		This parameter is optional. If specified, it must be a parent of the specified path or recursion will not be carried out.
	.EXAMPLE
		Remove-NxtEmptyFolder -Path "$installLocation\SomeEmptyFolder"
		This example removes the specified empty folder located at "$installLocation\SomeEmptyFolder".
	.OUTPUTS
		none.
	.LINK
		https://neo42.de/psappdeploytoolkit
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Path,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$RootPathToRecurseUpTo
	)
	Begin {
		## Get the name of this function and write header
		[string]${cmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	Process {
		$Path = $Path.TrimEnd("\")
		if ($false -eq [string]::IsNullOrEmpty($RootPathToRecurseUpTo)) {
			$RootPathToRecurseUpTo = $RootPathToRecurseUpTo.TrimEnd("\")
		}
		[bool]$skipRecursion = $false
		if (Test-Path -LiteralPath $Path -PathType 'Container') {
			try {
				if ( (Get-ChildItem $Path | Measure-Object).Count -eq 0) {
					Remove-Item -LiteralPath $Path -Force -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorRemoveFolder'
				}
				else {
					$skipRecursion = $true
				}
			}
			catch {
				if (-not $ContinueOnError) {
					throw "Failed to delete empty folder [$Path]: $($_.Exception.Message)"
				}
			}
		}
		else {
		}
		if (
			$false -eq [string]::IsNullOrEmpty($RootPathToRecurseUpTo) -and
			$false -eq $skipRecursion
		) {
			## Resolve possible relative segments in the paths
			[string]$absolutePath = $Path | Split-Path -Parent
			[string]$absoluteRootPathToRecurseUpTo = [System.IO.Path]::GetFullPath(([System.IO.DirectoryInfo]::new($RootPathToRecurseUpTo)).FullName)
			if ($absolutePath -eq $absoluteRootPathToRecurseUpTo){
				## We are at the root of the recursion, so we can stop recursing up
				Remove-NxtEmptyFolder -Path $absolutePath
			}
			else{
				## Ensure that $absoluteRootPathToRecurseUpTo is a valid path
				if ($false -eq [System.IO.Path]::IsPathRooted($absoluteRootPathToRecurseUpTo)) {
					throw "RootPathToRecurseUpTo is not a valid path."
				}
				## Ensure that $absoluteRootPathToRecurseUpTo is a parent of $absolutePath
				if ($false -eq $absolutePath.StartsWith($absoluteRootPathToRecurseUpTo, [System.StringComparison]::InvariantCultureIgnoreCase)) {
					throw "RootPathToRecurseUpTo '$absoluteRootPathToRecurseUpTo' is not a parent of '$absolutePath'."
				}
				Remove-NxtEmptyFolder -Path $absolutePath -RootPathToRecurseUp $absoluteRootPathToRecurseUpTo
			}
		}
	}
	End {
	}
}
#endregion
try {
    Start-Sleep -Seconds 10
    $packageConfig = Get-Content -Path "$PSScriptRoot\neo42-Install\neo42PackageConfig.json" | Out-String | ConvertFrom-Json
    $folderToRemove = @("$PSScriptRoot\neo42-Install", "$PSScriptRoot\neo42-Source")
    if ($true -eq $packageConfig.UserPartOnUninstallation) {
        ## due to an active UserPart on UnInstallation, we must keep userPartDir.
    }
    else {
        ## what is now "User" must be equal to $global:userPartDir in Deploy-Application.ps1
        $folderToRemove += "$PSScriptRoot\User"
    }
    foreach ($folder in $folderToRemove) {
        if (Test-Path -Path $folder) {
            Remove-Item -Path $folder -Recurse -Force
        }
    }
}
finally {
    Remove-Item $currentScript -Force
    if ($false -eq [string]::IsNullOrEmpty($RootPathToRecurseUpTo)) {
		Start-Sleep -Milliseconds 100
        Remove-NxtEmptyFolder -Path $PSScriptRoot -RootPathToRecurseUpTo $RootPathToRecurseUpTo
	}
}