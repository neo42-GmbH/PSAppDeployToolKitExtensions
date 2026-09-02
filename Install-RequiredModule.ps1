param (
	[ValidateScript({ $_.Exists } )]
	[ValidateNotNullOrEmpty()]
	[System.IO.DirectoryInfo]
	$Root = "$($PWD.Path)\build",
	[ValidateScript({ $_.Exists })]
	[ValidateNotNullOrEmpty()]
	[System.IO.FileInfo]
	$ModuleManifest = "$($PWD.Path)\src\modules\Neo42.Extensions\PSAppDeployToolkit.Neo42.Extensions.psd1"
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 3.0

# Obtain the desired PSAppDeployToolkit version from the module manifest.
[System.Collections.Hashtable]$moduleData = Import-PowerShellDataFile -Path $ModuleManifest
[System.String]$requiredPsadtVersion = ($moduleData.RequiredModules | Where-Object { $_.ModuleName -eq 'PSAppDeployToolkit' })['RequiredVersion']
if (-not $requiredPsadtVersion) {
	throw "The given module manifest [$($ModuleManifest.FullName)] does not specify a RequiredModules entry for 'PSAppDeployToolkit'."
}

# Validate the current environment has the required PSAppDeployToolkit version installed.
[System.Boolean]$requiresDownload = $false
[System.IO.DirectoryInfo]$moduleFolder = [System.IO.Path]::Combine($Root.FullName, 'PSAppDeployToolkit')

if ($moduleFolder.Exists) {
	[System.Collections.Hashtable]$installedModuleData = Import-PowerShellDataFile -Path ([System.IO.Path]::Combine($moduleFolder.FullName, 'PSAppDeployToolkit.psd1'))
	if ($requiredPsadtVersion -ne $installedModuleData.ModuleVersion) {
		Write-Host "The PSAppDeployToolkit present must be upgrade from [$($installedModuleData.ModuleVersion)] to [$requiredPsadtVersion]."
		$requiresDownload = $true
	}
}
else {
	Write-Host "The PSAppDeployToolkit is not downloaded yet."
	$requiresDownload = $true
}

# Download the required PSAppDeployToolkit version.
if (-not $requiresDownload) {
}
else {
	[System.IO.FileInfo]$zipFile = [System.IO.Path]::Combine($Root.FullName, 'PSAppDeployToolkit_ModuleOnly.zip')
	Invoke-WebRequest -Uri "https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/releases/download/$requiredPsadtVersion/PSAppDeployToolkit_ModuleOnly.zip" -OutFile $zipFile.FullName
	try {
		Expand-Archive -Path $zipFile.FullName -DestinationPath $Root.FullName -Force
	}
	finally {
		$zipFile.Delete()
	}
	Get-ChildItem -Path $moduleFolder -File -Recurse | Unblock-File
	Write-Host "The required PSAppDeployToolkit version [$requiredPsadtVersion] has been downloaded to [$($moduleFolder.FullName)]."
}

# Ensure required modules are installed.
@(
	@{ ModuleName = 'PSScriptAnalyzer'; GUID = 'd6245802-193d-4068-a631-8863a4342a18'; ModuleVersion = '1.25.0'; MaximumVersion = '1.99' },
	@{ ModuleName = 'Pester'; GUID = 'a699dea5-2c73-4616-a270-1f7abb777e71'; ModuleVersion = '5.6'; MaximumVersion = '5.99' }
) | ForEach-Object {
	if (-not (Get-Module -ListAvailable -FullyQualifiedName $_)) {
		Install-Module -Force -SkipPublisherCheck -Scope CurrentUser -Repository PSGallery `
			-Name $_.ModuleName `
			-MinimumVersion $_.ModuleVersion `
			-MaximumVersion $_.MaximumVersion

		Write-Host "The required module [$($_.ModuleName)] has been installed."
	}
	else {
		Write-Host "The required module [$($_.ModuleName)] is already installed."
	}
}

