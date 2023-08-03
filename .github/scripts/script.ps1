## Remove unneeded files from PSAppDeployToolkit and Extensions
Remove-Item -Force -Recurse ./PSAppDeployToolkitExtensions/.git
Remove-Item -Force -Recurse ./PSAppDeployToolkitExtensions/.github
Remove-Item -Force -Recurse ./PSAppDeployToolkitExtensions/Tools
Remove-Item -force ./PSAppDeployToolkitExtensions/.gitignore
Remove-Item ./PSAppDeployToolkitExtensions/README.MD
Remove-Item ./PSAppDeployToolkitExtensions/Setup.ico
Remove-Item ./PSAppDeployToolkitExtensions/neo42PackageConfig.json
Copy-Item ./PSAppDeployToolkitExtensions/Samples/MSI/neo42PackageConfig.json ./PSAppDeployToolkitExtensions/neo42PackageConfig.json
Remove-Item -Force -Recurse ./PSAppDeployToolkit/.git
Remove-Item -Force -Recurse "./PSAppDeployToolkit/Toolkit/Deploy-Application.exe*"
## Copy files to new folder
$dirname = "$($Env:GITHUB_RELEASE_VERSION)-$($Env:GITHUB_RUN_NUMBER)"
New-Item -ItemType Directory -Name "$dirname" -Force
Copy-Item "./PSAppDeployToolkit/Toolkit/*" "$dirname/" -Recurse -Force -Exclude $exclude
Copy-Item "./PSAppDeployToolkitExtensions/*" -Recurse -Force -Destination "./$dirname/"
## Has to be equal to $global:userPartDir in Deploy-Application.ps1
New-Item -ItemType Directory -Name "$dirname/SupportFiles/User" -Force
New-Item -ItemType File -Path "$dirname/SupportFiles/User" -Name "place UserPart files here!!!"
New-Item -ItemType Directory -Name "$dirname/Files" -Force
New-Item -ItemType File -Path "$dirname/Files" -Name "place setup files here!!!"
New-Item -ItemType File -Path "$dirname\" -Name "Add a Setup.ico here!!!"
New-Item -ItemType Directory -Name Artifacts
sed -i "s/##REPLACEVERSION##/$dirname/g" ./$dirname/Deploy-Application.ps1
sed -i "s/##REPLACEVERSION##/$dirname/g" ./$dirname/AppDeployToolkit/AppDeployToolkitExtensions.ps1