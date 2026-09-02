function Add-NXTFolderPermission {
	<#
	.SYNOPSIS
	Adds access control permissions on a specified, existing folder without removing existing permissions.
	.DESCRIPTION
	The function allows granular control over the access permissions of a specified folder.
	It can assign specific permission levels (e.g., Full Control, Modify, Write, Read & Execute) to identity references (SID, user name or group name).
	The function also provides options to set the owner, manage custom directory security settings, and control the inheritance of permissions.
	It is capable of applying these settings to both the target folder and its sub-folders.
	.INPUTS
	System.String[] - The path to the folder(s) to set permissions on.

	System.IO.DirectoryInfo[] - The folder(s) to set permissions on.
	.PARAMETER Path
	The path to the folder(s) to add permissions to.
	.PARAMETER LiteralPath
	The literal path to the folder(s) to add permissions to.
	.PARAMETER Filter
	A filter to qualify the Path parameter.
	.PARAMETER Exclude
	A filter to exclude items from the Path parameter.
	.PARAMETER Include
	A filter to include items in the Path parameter.
	.PARAMETER FullControl
	The user(s) or group(s) to grant full control permissions to.
	.PARAMETER Write
	The user(s) or group(s) to grant write permissions to.
	.PARAMETER Modify
	The user(s) or group(s) to grant modify permissions to.
	.PARAMETER ReadAndExecute
	The user(s) or group(s) to grant read and execute permissions to.
	.PARAMETER Recurse
	Specifies that the permissions should be applied to all sub-folders of the specified folder.
	.EXAMPLE
	Add-NXTFolderWithPermission -Path 'C:\Temp\MyFolder' -FullControl 'DOMAIN\User1', 'BuiltinAdministratorsSid' -Write 'S-1-1-0' -Owner 'DOMAIN\User1'

	Add permissions to folder 'C:\Temp\MyFolder' granting full control permissions for 'DOMAIN\User1' and 'Administrators', write permissions for 'Everyone'.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is handled by downstream cmdlets.')]
	[CmdletBinding(DefaultParameterSetName = 'Path', SupportsShouldProcess)]
	param (
		[Parameter(Position = 0, ParameterSetName = 'Path', Mandatory)]
		[SupportsWildcards()][ValidateNotNullOrEmpty()]
		[System.String[]]
		$Path,
		[Parameter(ParameterSetName = 'LiteralPath', Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('PSPath')]
		[ValidateNotNullOrEmpty()]
		[System.String[]]
		$LiteralPath,
		[SupportsWildcards()]
		[System.String]
		$Filter,
		[SupportsWildcards()]
		[System.String[]]
		$Exclude,
		[SupportsWildcards()]
		[System.String[]]
		$Include,
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
		[System.Management.Automation.SwitchParameter]
		$Recurse
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[System.String[]]$directories = Resolve-NXTPath @PSBoundParameters -ProviderName 'FileSystem' -PathType Container | & {
				process {
					$_.FullName
					if ($Recurse) {
						[System.IO.Directory]::EnumerateDirectories($_.FullName, '*', [System.IO.SearchOption]::AllDirectories)
					}
				}
			}

			if ($null -eq $directories -or $directories.Count -eq 0) {
				Write-ADTLogEntry -Severity Warning -Message 'No directories found with the specified parameters.'
				return
			}

			foreach ($directory in $directories) {
				Write-ADTLogEntry -Message "Setting permissions on folder [$directory]."
				[System.Security.AccessControl.DirectorySecurity]$security = Get-Acl -LiteralPath $directory
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
				Set-Acl -LiteralPath $directory -AclObject $security -Confirm:$false
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
