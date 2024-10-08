# Install Pester 5
if ((Get-Module -ListAvailable -Name 'Pester').Version.Major -notcontains 5) {
	Write-Warning 'Pester 5 is required to run the tests. Installing Pester 5.'
	Install-Module -Name 'Pester' -Force -SkipPublisherCheck -MinimumVersion 5.0 -MaximumVersion 5.99
}

# Remove old test results
Remove-Item "$env:TEMP\pester" -Recurse -Force -ErrorAction Stop

# Clone PSAppDeployToolkit
git clone 'https://github.com/PSAppDeployToolkit/PSAppDeployToolkit.git' "$env:TEMP\pester" --depth 1 --single-branch --branch 3.9.3 -c "advice.detachedHead=false"

# Copy current repository to PSAppDeployToolkit
Copy-Item "$PSScriptRoot\..\*" "$env:TEMP\pester\Toolkit" -Recurse -Container -Exclude "AppDeployToolkitMain*" -ErrorAction SilentlyContinue
Copy-Item "$env:Temp\pester\Toolkit\AppDeployToolkit\AppDeployToolkitLogo.ico" "$env:Temp\pester\Toolkit\Setup.ico" -ErrorAction Stop

# Run Pester
. "$env:TEMP\pester\Toolkit\.tests\RunPester.ps1" -ToolkitMain "$env:TEMP\pester\Toolkit\AppDeployToolkit\AppDeployToolkitMain.ps1"
