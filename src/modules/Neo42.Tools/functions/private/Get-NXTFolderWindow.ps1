function Get-NXTFolderWindow {
	<#
	.SYNOPSIS
	Open a dialog to select a package directory
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleTypes', '')]
	param(
		[Parameter(Mandatory)]
		[System.String]
		$Message
	)

	Add-Type -AssemblyName 'System.Windows.Forms'
	[System.Windows.Forms.FolderBrowserDialog]$packageSelector = [System.Windows.Forms.FolderBrowserDialog]::new()
	$packageSelector.Description = $Message
	$packageSelector.ShowNewFolderButton = $false
	[System.Windows.Forms.DialogResult]$result = $packageSelector.ShowDialog()
	if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
		return [System.IO.DirectoryInfo]::new($packageSelector.SelectedPath)
	}
	else {
		throw 'No update package selected.'
	}
}
