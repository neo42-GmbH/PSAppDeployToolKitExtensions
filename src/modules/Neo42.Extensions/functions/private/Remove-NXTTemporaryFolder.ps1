function Remove-NXTTemporaryFolder {
	<#
	.SYNOPSIS
	Helper function to clear the temporary folders created by the toolkit.
	#>
	# Remove temporary directories that might have been created
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Internal function, no ShouldProcess required.')]
	param()

	[System.Collections.Generic.IReadOnlyDictionary[System.String, System.Object]]$adtEnvironment = Get-ADTEnvironmentTable
	[System.IO.DirectoryInfo]$pathBase = [System.IO.Path]::Combine($adtEnvironment.envTemp, 'n42Tmp')
	if ($pathBase.Exists) { $pathBase.Delete($true) }
}
