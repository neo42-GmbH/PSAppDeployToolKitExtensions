Remove-Item "$env:TEMP\pester" -Recurse -Force -ErrorAction SilentlyContinue
git clone 'https://github.com/PSAppDeployToolkit/PSAppDeployToolkit.git' "$env:TEMP\pester"
Copy-Item "$PSScriptRoot\..\*" "$env:TEMP\pester\Toolkit" -Recurse -Container -ErrorAction SilentlyContinue
. "$env:TEMP\pester\Toolkit\test\RunPester.ps1"
