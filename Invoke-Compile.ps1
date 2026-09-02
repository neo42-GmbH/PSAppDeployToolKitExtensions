param(
	[ValidateSet('Debug', 'Release')]
	[Alias('Config', 'C')]
	[System.String]
	$Configuration = 'Debug',
	[System.String]
	$Version = '0.0.0.0',
	[System.IO.DirectoryInfo]
	$Output = "$($PWD.Path)\build"
)

[System.String[]]$sharedArgs = @(
	'publish'
	"`"$PSScriptRoot\src\solutions\PSAppDeployToolkit.Neo42.Extensions.sln`""
	'--configuration',
	$Configuration,
	'--verbosity',
	'minimal',
	'--nologo',
	'--disable-build-servers',
	"`"--property:RootOutputPath=$($Output.FullName)`"",
	"--property:Version=$Version$(if ($Configuration -eq 'Debug') { '-DebugBuild' })",
	'--property:GenerateFullPaths=true'
	'"--consoleLoggerParameters:NoSummary;ForceNoAlign"'
)

'net472', 'net8.0' | ForEach-Object {
	Write-Host "Dotnet [$_] build:"
	[System.String[]]$frameworkArgs = @('--framework', $_)
	Write-Host "Executing: dotnet.exe $($sharedArgs + $frameworkArgs)"
	[System.Diagnostics.Process]$proc = Start-Process -FilePath 'dotnet.exe' -NoNewWindow -ArgumentList ($sharedArgs + $frameworkArgs) -PassThru -Wait
	if ($proc.ExitCode -ne 0) { throw "Build failed [ExitCode $($proc.ExitCode)]" }
}
