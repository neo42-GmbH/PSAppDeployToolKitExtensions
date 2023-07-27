## Remove unneeded files from PSAppDeployToolkit and Extensions
Remove-Item -Force -Recurse ./PSAppDeployToolkitExtensions/.git
Remove-Item -Force -Recurse ./PSAppDeployToolkitExtensions/.github
Remove-Item -Force -Recurse ./PSAppDeployToolkitExtensions/Tools
Remove-Item -force ./PSAppDeployToolkitExtensions/.gitignore
Remove-Item ./PSAppDeployToolkitExtensions/README.MD
Remove-Item -Force -Recurse ./PSAppDeployToolkit/.git
Remove-Item -Force -Recurse "./PSAppDeployToolkit/Toolkit/Deploy-Application.exe*"
## Copy files to new folder
$dirname = "testrunfolder"
New-Item -ItemType Directory -Name "$dirname" -Force
Copy-Item "./PSAppDeployToolkit/Toolkit/*" "$dirname/" -Recurse -Force -Exclude $exclude
Copy-Item "./PSAppDeployToolkitExtensions/*" -Recurse -Force -Destination "./$dirname/"
Copy-Item "./PSAppDeployToolkitExtensions/test/shared.psm1" -Destination "./$dirname/" -Force
Copy-Item "./PSAppDeployToolkitExtensions/test/PesterTests.ps1" -Destination "./$dirname/" -Force
New-Item -ItemType Directory -Name "$dirname/SupportFiles/neo42-Userpart" -Force
New-Item -ItemType File -Path "$dirname/SupportFiles/neo42-Userpart" -Name "place UserPart files here!!!"
New-Item -ItemType Directory -Name "$dirname/Files" -Force
New-Item -ItemType File -Path "$dirname/Files" -Name "place setup files here!!!"
New-Item -ItemType File -Path "$dirname\" -Name "Add a Setup.ico here!!!"