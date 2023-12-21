## Remove unneeded files from PSAppDeployToolkit and Extensions
Remove-Item -Force -Recurse ./PSAppDeployToolkitExtensions/.git
Remove-Item -Force -Recurse ./PSAppDeployToolkitExtensions/.github
Remove-Item -Force -Recurse ./PSAppDeployToolkitExtensions/test
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
New-Item -ItemType Directory -Name "$dirname/$dirname" -Force
Copy-Item "./PSAppDeployToolkit/Toolkit/*" "$dirname/$dirname/" -Recurse -Force -Exclude $exclude
Copy-Item "./PSAppDeployToolkitExtensions/*" -Recurse -Force -Destination "./$dirname/$dirname/"
## Has to be equal to $global:userPartDir in Deploy-Application.ps1
New-Item -ItemType Directory -Name "$dirname/$dirname/SupportFiles/User" -Force
New-Item -ItemType File -Path "$dirname/$dirname/SupportFiles/User" -Name "place UserPart files here!!!"
New-Item -ItemType Directory -Name "$dirname/$dirname/Files" -Force
New-Item -ItemType File -Path "$dirname/$dirname/Files" -Name "place setup files here!!!"
New-Item -ItemType File -Path "$dirname/$dirname/" -Name "Add a Setup.ico here!!!"
Move-Item ./$dirname/$dirname/Tools ./$dirname/ -Force
Move-Item ./$dirname/$dirname/Samples ./$dirname/ -Force
Move-Item ./PSAppDeployToolkitExtensions_Develop ./$dirname/ExtensionsSourceCode/ -Force
New-Item -ItemType Directory -Name Artifacts
sed -i "s/##REPLACEVERSION##/$dirname/g" ./$dirname/$dirname/Deploy-Application.ps1
sed -i "s/##REPLACEVERSION##/$dirname/g" ./$dirname/$dirname/AppDeployToolkit/AppDeployToolkitExtensions.ps1
sed -i "s/##REPLACEVERSION##/$dirname/g" ./$dirname/$dirname/AppDeployToolkit/AppDeployToolkitExtensions.cs
sed -i "s/##REPLACEVERSION##/$dirname/g" ./$dirname/Tools/InsertLatestToNxtPsadtPackage.ps1