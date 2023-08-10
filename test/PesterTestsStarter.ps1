
## get current selected branch
$branch = git branch --show-current
if ($false -eq (Test-Path "$PSScriptRoot\NxtExtensions")){
    git clone --depth 1 --branch $branch "file://$PSScriptRoot\..\.git\" $PSScriptRoot\NxtExtensions
} 
git clone --depth 1 --branch "3.9.3" "https://github.com/PSAppDeployToolkit/PSAppDeployToolkit.git" $PSScriptRoot\PSADT
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
## Copy files to new folder
$dirname = "$PSScriptRoot\TestWorkFolder"
New-Item -ItemType Directory -Path $dirname -Force
Copy-Item "$PSScriptRoot/PSADT/Toolkit/*" "$dirname/" -Recurse -Force -Exclude $exclude
Copy-Item "$PSScriptRoot/NxtExtensions/*" -Recurse -Force -Destination $dirname
## Has to be equal to $global:userPartDir in Deploy-Application.ps1
New-Item -ItemType Directory -path "$dirname/SupportFiles/User" -Force
New-Item -ItemType File -Path "$dirname/SupportFiles/User" -Name "place UserPart files here!!!"
New-Item -ItemType Directory -Path "$dirname/Files" -Force
New-Item -ItemType File -Path "$dirname/Files" -Name "place setup files here!!!"
New-Item -ItemType File -Path "$dirname\" -Name "Add a Setup.ico here!!!"
Copy-Item "$PSScriptRoot/shared.psm1" "$dirname/" -Force
Copy-Item "$PSScriptRoot/PesterTests.ps1" "$dirname/" -Force
## run tests
Invoke-Pester -Script "$dirname/PesterTests.ps1" -OutputFile "$PSScriptRoot/PesterTestResults.xml" -OutputFormat NUnitXml -PassThru
## this fails for a logo file still being in use
Remove-Item -Force -Recurse $dirname
Remove-Item -Force -Recurse $PSScriptRoot/NxtExtensions
Remove-Item -Force -Recurse $PSScriptRoot/PSADT
