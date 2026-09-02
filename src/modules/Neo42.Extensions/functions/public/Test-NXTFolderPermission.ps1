function Test-NXTFolderPermission {
	<#
	.SYNOPSIS
	Checks and compares the actual permissions of a specified folder against expected permissions.
	.DESCRIPTION
	Test-NxtFolderPermissions evaluates a folder's security settings by comparing its actual permissions, owner, and other security attributes against predefined expectations.
	It's useful for ensuring folder permissions align with security policies or compliance standards.
	.INPUTS
	System.IO.FileInfo - The folder to check.
	.PARAMETER Path
	The path to the folder whose permissions are to be checked.
	.PARAMETER FullControl
	The user(s) or group(s) that should have full control permissions.
	.PARAMETER Write
	The user(s) or group(s) that should have write permissions.
	.PARAMETER Modify
	The user(s) or group(s) that should have modify permissions.
	.PARAMETER ReadAndExecute
	The user(s) or group(s) that should have read and execute permissions.
	.PARAMETER Owner
	The user or group that should be set as the owner of the folder.
	.PARAMETER CustomDirectorySecurity
	A custom DirectorySecurity object to use as a base for the folder permissions. If not specified, a new DirectorySecurity object is created.
	.PARAMETER IsInherited
	Test if permissions are inherited from the parent folder.
	.EXAMPLE
	Test-NXTFolderWithPermission -Path 'C:\Temp\MyFolder' -FullControl 'DOMAIN\User1', 'BuiltinAdministratorsSid' -Write 'S-1-1-0' -Owner 'DOMAIN\User1'

	Tests if a folder 'C:\Temp\MyFolder' has these permissions: full control permissions for 'DOMAIN\User1' and 'Administrators', write permissions for 'Everyone', and 'DOMAIN\User1' as owner.
	#>
	[Alias('Test-NXTFolderPermissions')]
	[OutputType([System.Boolean])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias('FullName')]
		[System.String]
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
		[System.Boolean]
		$IsInherited
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[System.Collections.Generic.List[System.String]]$accessCompareProperties = if ($PSBoundParameters.ContainsKey('IsInherited')) { @('IsInherited') } else { @() }
			[System.Security.AccessControl.DirectorySecurity]$security = if ($null -ne $CustomDirectorySecurity) { $CustomDirectorySecurity } else { [System.Security.AccessControl.DirectorySecurity]::new() }

			foreach ($permissionLevel in @('FullControl', 'Modify', 'Write', 'ReadAndExecute')) {
				if (-not $PSBoundParameters.ContainsKey($permissionLevel)) { continue }
				[System.Security.Principal.SecurityIdentifier[]]$sids = $PSBoundParameters[$permissionLevel]
				$accessCompareProperties.Add($permissionLevel)
				foreach ($id in $sids) {
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

			[System.Security.AccessControl.DirectorySecurity]$actualAcl = Get-Acl -Path $Path
			if ($PSBoundParameters.ContainsKey('Owner') -and $Owner -ne $actualAcl.Owner) {
				Write-ADTLogEntry -Severity Warning -Message "Owner mismatch. Expected: [$Owner]. Actual: [$($actualAcl.Owner)]." -DebugMessage
				return $false
			}

			[System.Management.Automation.PSObject[]]$differences = @(Compare-Object @($actualAcl.Access) @($security.Access) -Property $accessCompareProperties)
			if ($differences.Count -gt 0) {
				Write-ADTLogEntry -Severity Warning -Message 'Access control list mismatch.' -DebugMessage
				return $false
			}
			return $true
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
