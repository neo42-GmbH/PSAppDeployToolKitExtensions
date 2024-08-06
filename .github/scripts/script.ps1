$dirname = "$($Env:GITHUB_RELEASE_VERSION)-$($Env:GITHUB_RUN_NUMBER)"
New-Item -ItemType Directory -Name "$dirname" -Force
New-Item -ItemType Directory -Name "$dirname/$dirname" -Force
New-Item -ItemType Directory -Name "$dirname/$dirname/SupportFiles/User" -Force
New-Item -ItemType File -Path "$dirname/$dirname/SupportFiles/User" -Name 'place UserPart files here!!!'
New-Item -ItemType Directory -Name "$dirname/$dirname/Files" -Force
New-Item -ItemType File -Path "$dirname/$dirname/Files" -Name 'place setup files here!!!'
New-Item -ItemType File -Path "$dirname/$dirname/" -Name 'Add a Setup.ico here!!!'
New-Item -ItemType Directory -Name Artifacts -Force
## Move source code to new folder
Move-Item ./PSAppDeployToolkitExtensions_Develop ./$dirname/ExtensionsSourceCode/ -Force
## Use sample files
Copy-Item ./PSAppDeployToolkitExtensions/.tools ./$dirname/Tools/ -Force -Recurse
Copy-Item ./PSAppDeployToolkitExtensions/.samples ./$dirname/Samples/ -Force -Recurse
Copy-Item ./PSAppDeployToolkitExtensions/.samples/MSI/neo42PackageConfig.json ./PSAppDeployToolkitExtensions/neo42PackageConfig.json -Force
## Remove unneeded files from PSAppDeployToolkit and Extensions
Remove-Item -Force -Recurse ./PSAppDeployToolkitExtensions/.*
Remove-Item ./PSAppDeployToolkitExtensions/README.MD
Remove-Item ./PSAppDeployToolkitExtensions/Setup.ico
Remove-Item -Force -Recurse "./PSAppDeployToolkit/Toolkit/Deploy-Application.exe*"
## Copy files to new folder
Copy-Item "./PSAppDeployToolkit/Toolkit/*" "$dirname/$dirname/" -Recurse -Force
Copy-Item "./PSAppDeployToolkitExtensions/*" -Recurse -Force -Destination "./$dirname/$dirname/"
## Replace version in files
foreach ( $file in @(
		"./$dirname/$dirname/Deploy-Application.ps1",
		"./$dirname/$dirname/AppDeployToolkit/AppDeployToolkitExtensions.ps1",
		"./$dirname/$dirname/AppDeployToolkit/AppDeployToolkitExtensions.cs",
		"./$dirname/Tools/InsertLatestToNxtPsadtPackage.ps1"
	)) {
		(Get-Content -Raw -Path $file).Replace('##REPLACEVERSION##', $dirname) | Set-Content -Path $file
}
