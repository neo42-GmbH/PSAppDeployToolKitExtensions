<#
    .SYNOPSIS
        This script sends the sorted content of AppDeployToolkitExtensions.ps1 to the clipboard.
    .NOTES
        # LICENSE #
        This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
        You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

        # COPYRIGHT #
        Copyright (c) 2024 neo42 GmbH, Germany.
#>
Set-Location $PSScriptRoot
. ("..\AppDeployToolkit\AppDeployToolkitMain.ps1")
Get-Command -Name *-nxt*| Select-Object name,ScriptBlock|ForEach-Object{
	"#region Function $($_.name)
	function $($_.name) {$($_.scriptblock)}
	#endregion"
	}|clip
