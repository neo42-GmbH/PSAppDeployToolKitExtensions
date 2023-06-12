## Remove unneeded files from PSAppDeployToolkit and Extensions
Remove-Item -Force -Recurse ./PSAppDeployToolkitExtensions/.git
Remove-Item -Force -Recurse ./PSAppDeployToolkitExtensions/.github
Remove-Item -Force -Recurse ./PSAppDeployToolkitExtensions/Tools
Remove-Item -force ./PSAppDeployToolkitExtensions/.gitignore
Remove-Item ./PSAppDeployToolkitExtensions/README.MD
Remove-Item ./PSAppDeployToolkitExtensions/Setup.ico
Remove-Item -Force -Recurse ./PSAppDeployToolkit/.git
Remove-Item -Force -Recurse "./PSAppDeployToolkit/Toolkit/Deploy-Application.exe*"
## Copy files to new folder
$Dirname = "Latest"
New-Item -ItemType Directory -Name "./$DirName" -Force
$exclude = Get-ChildItem -File "./$DirName/PSAppDeployToolkitExtensions" -Recurse
Copy-Item "./PSAppDeployToolkit/Toolkit/*" "./$DirName/" -Recurse -Force -Exclude $exclude
Copy-Item "./PSAppDeployToolkitExtensions/*" -Recurse -Force -Destination "./$DirName/"
New-Item -ItemType Directory -Name ".\$DirName/SupportFiles/neo42-Userpart" -Force
New-Item -ItemType File -Path ".\$DirName\" -Name "Add a Setup.ico here!!!"