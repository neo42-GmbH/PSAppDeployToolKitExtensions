function New-NXTFolderWithPermission {
	<#
	.SYNOPSIS
	Creates a new folder with predefined permissions.
	.DESCRIPTION
	Creates a new folder with predefined permissions.
	.INPUTS
	System.String - The path to the folder(s) to create.
	.OUTPUTS
	System.IO.DirectoryInfo[] - The created folder(s).
	.PARAMETER Path
	The path to the folder to create.
	.PARAMETER FullControl
	The user(s) or group(s) to grant full control permissions to.
	.PARAMETER Write
	The user(s) or group(s) to grant write permissions to.
	.PARAMETER Modify
	The user(s) or group(s) to grant modify permissions to.
	.PARAMETER ReadAndExecute
	The user(s) or group(s) to grant read and execute permissions to.
	.PARAMETER Owner
	The user or group to set as the owner of the folder.
	.PARAMETER CustomDirectorySecurity
	A custom DirectorySecurity object to use as base for the folder permissions. Default is a new DirectorySecurity object.
	.PARAMETER Hide
	Specifies that the folder should be hidden.
	.PARAMETER Force
	Specifies that if the folder already exists, it should be deleted and recreated.
	.PARAMETER Inherit
	Specifies that the folder should inherit permissions from the parent folder. Otherwise, the permissions are protected.
	.PARAMETER PassThru
	Returns the created folder if specified.
	.EXAMPLE
	New-NXTFolderWithPermission -Path 'C:\Temp\MyFolder' -FullControl 'DOMAIN\User1', 'BuiltinAdministratorsSid' -Write 'S-1-1-0' -Owner 'DOMAIN\User1'

	Creates a new folder at 'C:\Temp\MyFolder' with full control permissions for 'DOMAIN\User1' and 'Administrators', write permissions for 'Everyone', and sets 'DOMAIN\User1' as the owner.
	#>
	[Alias('New-NxtFolderWithPermissions')]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleTypes', '', Justification = 'Type depends on PSEdition')]
	[OutputType([System.IO.DirectoryInfo], [System.IO.DirectoryInfo[]])]
	[CmdletBinding(DefaultParameterSetName = 'Path', SupportsShouldProcess)]
	param (
		[Parameter(Position = 0, ParameterSetName = 'Path', Mandatory)]
		[SupportsWildcards()][ValidateNotNullOrEmpty()]
		[System.String[]]
		$Path,
		[Alias('FullControlPermissions')]
		[PSADTNXT.Attributes.IdentityReferenceTransformation()]
		[System.Security.Principal.IdentityReference[]]
		$FullControl,
		[Alias('WritePermissions')]
		[PSADTNXT.Attributes.IdentityReferenceTransformation()]
		[System.Security.Principal.IdentityReference[]]
		$Write,
		[Alias('ModifyPermissions')]
		[PSADTNXT.Attributes.IdentityReferenceTransformation()]
		[System.Security.Principal.IdentityReference[]]
		$Modify,
		[Alias('ReadAndExecutePermissions')]
		[PSADTNXT.Attributes.IdentityReferenceTransformation()]
		[System.Security.Principal.IdentityReference[]]
		$ReadAndExecute,
		[PSADTNXT.Attributes.IdentityReferenceTransformation()]
		[System.Security.Principal.IdentityReference]
		$Owner,
		[System.Security.AccessControl.DirectorySecurity]
		$CustomDirectorySecurity,
		[System.Management.Automation.SwitchParameter]
		$Hide,
		[System.Management.Automation.SwitchParameter]
		$Force,
		[System.Management.Automation.SwitchParameter]
		$Inherit,
		[System.Management.Automation.SwitchParameter]
		$PassThru
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[System.Security.AccessControl.DirectorySecurity]$security = if ($null -ne $CustomDirectorySecurity) { $CustomDirectorySecurity } else { [System.Security.AccessControl.DirectorySecurity]::new() }
			if ($null -ne $Owner) { $security.SetOwner($Owner) }
			$security.SetAccessRuleProtection(-not $Inherit, $false)

			foreach ($permissionLevel in @('FullControl', 'Modify', 'Write', 'ReadAndExecute')) {
				foreach ($id in $PSBoundParameters[$permissionLevel]) {
					$security.AddAccessRule(
						[System.Security.AccessControl.FileSystemAccessRule]::new(
							$id,
							[System.Enum]::Parse([System.Security.AccessControl.FileSystemRights], $permissionLevel),
							@([System.Security.AccessControl.InheritanceFlags]::ContainerInherit, [System.Security.AccessControl.InheritanceFlags]::ObjectInherit),
							[System.Security.AccessControl.PropagationFlags]::None,
							[System.Security.AccessControl.AccessControlType]::Allow
						)
					)
				}
			}

			foreach ($directory in (Resolve-NXTPath -LiteralPath $Path -IncludeNonExistent -ProviderName 'FileSystem' -AsProviderPath -PathType 'Container')) {
				Write-ADTLogEntry -Message "Creating folder [$directory] with defined permissions."
				[System.IO.DirectoryInfo]$directory = [System.IO.DirectoryInfo]::new($directory)
				if ($PSCmdlet.ShouldProcess($directory, 'Create folder with permissions')) {
					if ($directory.Exists -and $Force) { $directory.Delete($true) }
					[PSADTNXT.IO.NxtPath]::CreateDirectory($directory.FullName, $security)
					if ($Hide) { $directory.Attributes = $directory.Attributes -band [System.IO.FileAttributes]::Hidden }
					if ($PassThru) { $directory }
				}
			}
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
