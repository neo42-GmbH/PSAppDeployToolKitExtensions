
## get current selected branch
cd $PSScriptRoot
$branch = git branch --show-current
    Write-Output "branch is: $branch"
if ($false -eq (Test-Path "$PSScriptRoot\NxtExtensions")){
    git clone "file://$PSScriptRoot\..\.git\" $PSScriptRoot\NxtExtensions
}
if ($false -eq (Test-Path "$PSScriptRoot\PSADT")){
    git clone --depth 1 --branch "3.9.3" "https://github.com/PSAppDeployToolkit/PSAppDeployToolkit.git" $PSScriptRoot\PSADT
}
## Merge the PSADT and NxtExtensions folders
## Remove unneeded files from PSADT and Extensions
Remove-Item -Force -Recurse $PSScriptRoot/NxtExtensions/.git
Remove-Item -Force -Recurse $PSScriptRoot/NxtExtensions/.github
Remove-Item -Force -Recurse $PSScriptRoot/NxtExtensions/Tools
Remove-Item -Force -Recurse $PSScriptRoot/NxtExtensions/test
Remove-Item -force $PSScriptRoot/NxtExtensions/.gitignore
Remove-Item $PSScriptRoot/NxtExtensions/README.MD
Remove-Item -Force -Recurse $PSScriptRoot/PSADT/.git
Remove-Item -Force -Recurse "$PSScriptRoot/PSADT/Toolkit/Deploy-Application.exe*"
$TestWorkfolder = "$env:TEMP\NxtPSADTTests\$(Get-Random -Minimum 100000 -Maximum 999999)"
## Copy files to new folder
New-Item -ItemType Directory -Path $testWorkfolder -Force
Copy-Item "$PSScriptRoot/PSADT/Toolkit/*" "$testWorkfolder/" -Recurse -Force -Exclude $exclude
Copy-Item "$PSScriptRoot/NxtExtensions/*" -Recurse -Force -Destination $testWorkfolder
## Has to be equal to $global:userPartDir in Deploy-Application.ps1
New-Item -ItemType Directory -path "$testWorkfolder/SupportFiles/User" -Force
New-Item -ItemType Directory -Path "$testWorkfolder/Files" -Force
Copy-Item "$PSScriptRoot/shared.psm1" "$testWorkfolder/" -Force
Copy-Item "$PSScriptRoot/*.Tests.ps1" "$testWorkfolder/" -Force
Copy-Item "$PSScriptRoot/RunPester.ps1" "$testWorkfolder/" -Force
## run tests
&"$testWorkfolder/RunPester.ps1"
Remove-Item -Force -Recurse $PSScriptRoot/NxtExtensions -ea 0
Remove-Item -Force -Recurse $PSScriptRoot/PSADT -ea 0

git log --oneline --decorate --graph