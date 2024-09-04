# Assuming the function New-NxtTemporaryFolder is loaded in the current session or sourced from another file.

Describe "New-NxtTemporaryFolder" {
    Context "Default TempRootPath" {
        It "Uses default TempRootPath when none is provided" {
            $tempFolder = New-NxtTemporaryFolder
            $tempFolder | Should -BeLike "$env:SystemDrive\n42tmp*"
            Remove-Item -Path $tempFolder -Recurse -Force
        }
    }

    Context "Folder Creation" {
        It "Creates a folder in the specified TempRootPath" {
            $tempPath = "C:\CustomTempPath"
            $tempFolder = New-NxtTemporaryFolder -TempRootPath $tempPath
            $tempFolder | Should -BeLike "$tempPath*"
            ## check permissions
            Test-NxtFolderPermissions -Path $tempFolder -FullControlPermissions "BuiltinAdministratorsSid", "LocalSystemSid" -ReadAndExecutePermissions "BuiltinUsersSid" | Should -Be $true
            Remove-Item -Path $tempPath -Recurse -Force
        }
    }
}

