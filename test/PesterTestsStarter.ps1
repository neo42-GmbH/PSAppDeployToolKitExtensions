
## get current selected branch
Set-Location $PSScriptRoot
$branch = git branch --show-current
Write-Output "branch is: $branch"
if ($false -eq (Test-Path "$PSScriptRoot\NxtExtensions")) {
    git clone --depth 1 "file://$PSScriptRoot\..\.git\" $PSScriptRoot\NxtExtensions
}
if ($false -eq (Test-Path "$PSScriptRoot\PSADT")) {
    git clone --depth 1 --branch "3.9.3" "https://github.com/PSAppDeployToolkit/PSAppDeployToolkit.git" $PSScriptRoot\PSADT
}
## Merge the PSADT and NxtExtensions folders
## Remove unneeded files from PSADT and Extensions
Remove-Item -Force -Recurse $PSScriptRoot/NxtExtensions/.git
Remove-Item -Force -Recurse $PSScriptRoot/NxtExtensions/.github
Remove-Item -Force -Recurse $PSScriptRoot/NxtExtensions/Tools
Remove-Item -Force -Recurse $PSScriptRoot/NxtExtensions/test
Remove-Item -Force $PSScriptRoot/NxtExtensions/.gitignore
Remove-Item $PSScriptRoot/NxtExtensions/README.MD
Remove-Item -Force -Recurse $PSScriptRoot/PSADT/.git
Remove-Item -Force -Recurse "$PSScriptRoot/PSADT/Toolkit/Deploy-Application.exe*"
[string]$testWorkFolder = "$env:TEMP\NxtPSADTTests\$(Get-Random -Minimum 100000 -Maximum 999999)"
## Copy files to new folder
New-Item -ItemType Directory -Path $testWorkFolder -Force
Copy-Item "$PSScriptRoot/PSADT/Toolkit/*" "$testWorkFolder/" -Recurse -Force -Exclude $exclude
Copy-Item "$PSScriptRoot/NxtExtensions/*" -Recurse -Force -Destination $testWorkFolder
## Has to be equal to $global:userPartDir in Deploy-Application.ps1
New-Item -ItemType Directory -path "$testWorkFolder/SupportFiles/User" -Force
New-Item -ItemType Directory -Path "$testWorkFolder/Files" -Force
Copy-Item "$PSScriptRoot/shared.psm1" "$testWorkFolder/" -Force
Copy-Item "$PSScriptRoot/Definitions/*.Tests.ps1" "$testWorkFolder/" -Force
Copy-Item "$PSScriptRoot/RunPester.ps1" "$testWorkFolder/" -Force
## Create simple test binary
$compilerPath = [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory() + "csc.exe"
$compilerArgs = "/target:winexe /out:$PSScriptRoot\simple.exe $PSScriptRoot\simple.cs"
Start-Process -FilePath $compilerPath -ArgumentList $compilerArgs -Wait
## run tests
&"$testWorkFolder/RunPester.ps1"
Remove-Item -Force -Recurse $PSScriptRoot/NxtExtensions -ea 0
Remove-Item -Force -Recurse $PSScriptRoot/PSADT -ea 0
Set-Location ..
Remove-Item -Force -Recurse $testWorkFolder -ea 0