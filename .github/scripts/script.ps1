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
$dirname = "Latest"
New-Item -ItemType Directory -Name "./$dirname" -Force
$exclude = Get-ChildItem -File "./$dirname/PSAppDeployToolkitExtensions" -Recurse
Copy-Item "./PSAppDeployToolkit/Toolkit/*" "./$dirname/" -Recurse -Force -Exclude $exclude
Copy-Item "./PSAppDeployToolkitExtensions/*" -Recurse -Force -Destination "./$dirname/"
New-Item -ItemType Directory -Name ".\$dirname/SupportFiles/neo42-Userpart" -Force
New-Item -ItemType Directory -Name ".\$dirname/Files" -Force
New-Item -ItemType File -Path ".\$dirname\" -Name "Add a Setup.ico here!!!"
New-Item -ItemType Directory -Name Artifacts
Compress-Archive -Path ./Latest -DestinationPath ./Artifacts/Latest.zip
