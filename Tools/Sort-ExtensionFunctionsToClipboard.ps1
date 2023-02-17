##Snippet: Sort Module Functions
Set-Location $PSScriptRoot
. ("..\AppDeployToolkit\AppDeployToolkitMain.ps1")
Get-Command -Name *-nxt*| Select-Object name,ScriptBlock|ForEach-Object{
	"#region Function $($_.name)
	function $($_.name) {$($_.scriptblock)}
	#endregion"
	}|clip