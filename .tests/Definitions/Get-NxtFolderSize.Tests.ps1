Describe "Get-NxtFolderSize" {
    Context "With a folder" {
        It "Returns the size of the empty folder" {
            ## create a folder
            $path = "$PSScriptRoot\testfolder1\"
            New-Item -Path $path -ItemType Directory -Force | Out-Null
            $size = Get-NxtFolderSize -FolderPath $path
            $size | Should -Be 0
            Remove-Item -Path $path -Force -Recurse
        }
        It "Returns the size of the folder with files" {
            ## create a folder
            $path = "$PSScriptRoot\testfolder2\"
            New-Item -Path $path -ItemType Directory -Force | Out-Null
            ## create a file
            $file = "$path\testfile.txt"
            New-Item -Path $file -ItemType File -Force | Out-Null
            $size = Get-NxtFolderSize -FolderPath $path
            $size | Should -Be 0
            Remove-Item -Path $path -Force -Recurse
        }
        It "Returns the size of the folder with files and subfolders" {
            ## create a folder
            $path = "$PSScriptRoot\testfolder3\"
            New-Item -Path $path -ItemType Directory -Force | Out-Null
            ## create a file
            $file = "$path\testfile.txt"
            New-Item -Path $file -ItemType File -Force | Out-Null
            ## create a subfolder
            $subfolder = "$path\subfolder\"
            New-Item -Path $subfolder -ItemType Directory -Force | Out-Null
            $size = Get-NxtFolderSize -FolderPath $path
            $size | Should -Be 0
            Remove-Item -Path $path -Force -Recurse
        }
        It "Returns the size of the folder with files bigger than 1 MB" {
            ## create a folder
            $path = "$PSScriptRoot\testfolder4\"
            New-Item -Path $path -ItemType Directory -Force | Out-Null
            ## create a file with the size of 2 MB
            $file = "$path\testfile.txt"
            ## create a 2 MB file
            $content = New-Object byte[] (2*1024*1024)
            [System.IO.File]::WriteAllBytes($file, $content)
            $size = Get-NxtFolderSize -FolderPath $path -Unit MB
            $size | Should -Be 2
            Remove-Item -Path $path -Force -Recurse
        }
    }
}