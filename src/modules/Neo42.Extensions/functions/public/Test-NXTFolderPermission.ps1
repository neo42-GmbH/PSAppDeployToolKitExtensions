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
	Test if permissions are inherited from the parent folder. Only access rules with a matching inheritance state are taken into account when the requested permissions are verified.
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
		[ValidateNotNull()]
		[PSADTNXT.Attributes.IdentityReferenceTransformation()]
		[System.Security.Principal.IdentityReference[]]
		$FullControl,
		[Alias('WritePermissions')]
		[ValidateNotNull()]
		[PSADTNXT.Attributes.IdentityReferenceTransformation()]
		[System.Security.Principal.IdentityReference[]]
		$Write,
		[Alias('ModifyPermissions')]
		[ValidateNotNull()]
		[PSADTNXT.Attributes.IdentityReferenceTransformation()]
		[System.Security.Principal.IdentityReference[]]
		$Modify,
		[Alias('ReadAndExecutePermissions')]
		[ValidateNotNull()]
		[PSADTNXT.Attributes.IdentityReferenceTransformation()]
		[System.Security.Principal.IdentityReference[]]
		$ReadAndExecute,
		[ValidateNotNull()]
		[PSADTNXT.Attributes.IdentityReferenceTransformation()]
		[System.Security.Principal.IdentityReference]
		$Owner,
		[ValidateNotNull()]
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
			[System.Security.AccessControl.DirectorySecurity]$security = if ($null -ne $CustomDirectorySecurity) { $CustomDirectorySecurity } else { [System.Security.AccessControl.DirectorySecurity]::new() }

			foreach ($permissionLevel in @('FullControl', 'Modify', 'Write', 'ReadAndExecute')) {
				if (-not $PSBoundParameters.ContainsKey($permissionLevel)) { continue }
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

			[System.Security.AccessControl.DirectorySecurity]$actualAcl = Get-Acl -Path $Path

			## Identities may be given as NTAccount or SecurityIdentifier, so they are normalized to a SID before they are compared.
			[System.Management.Automation.ScriptBlock]$resolveSid = {
				param (
					[System.Security.Principal.IdentityReference]$Identity
				)
				try {
					return $Identity.Translate([System.Security.Principal.SecurityIdentifier])
				}
				catch {
					Write-ADTLogEntry -Severity Warning -Message "Failed to resolve identity [$Identity] to a security identifier." -DebugMessage
					return $null
				}
			}

			if ($PSBoundParameters.ContainsKey('Owner')) {
				[System.Security.Principal.SecurityIdentifier]$expectedOwnerSid = & $resolveSid $Owner
				[System.Security.Principal.SecurityIdentifier]$actualOwnerSid = $actualAcl.GetOwner([System.Security.Principal.SecurityIdentifier])
				if ($null -eq $expectedOwnerSid -or $expectedOwnerSid.Value -ne $actualOwnerSid.Value) {
					Write-ADTLogEntry -Severity Warning -Message "Owner mismatch. Expected: [$Owner]. Actual: [$($actualAcl.Owner)]." -DebugMessage
					return $false
				}
			}

			## An identity can be covered by more than one access rule, so the rights are accumulated per identity. The actual rules are requested as SIDs to avoid resolving identities that no longer exist.
			[System.Collections.Generic.Dictionary[System.String, System.Security.AccessControl.FileSystemRights]]$allowedRights = [System.Collections.Generic.Dictionary[System.String, System.Security.AccessControl.FileSystemRights]]::new()
			[System.Collections.Generic.Dictionary[System.String, System.Security.AccessControl.FileSystemRights]]$deniedRights = [System.Collections.Generic.Dictionary[System.String, System.Security.AccessControl.FileSystemRights]]::new()
			foreach ($actualRule in $actualAcl.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier])) {
				if ($PSBoundParameters.ContainsKey('IsInherited') -and $actualRule.IsInherited -ne $IsInherited) { continue }
				$rightsPerIdentity = if ($actualRule.AccessControlType -eq [System.Security.AccessControl.AccessControlType]::Deny) { $deniedRights } else { $allowedRights }
				[System.String]$actualSid = $actualRule.IdentityReference.Value
				$rightsPerIdentity[$actualSid] = if ($rightsPerIdentity.ContainsKey($actualSid)) { $rightsPerIdentity[$actualSid] -bor $actualRule.FileSystemRights } else { $actualRule.FileSystemRights }
			}

			foreach ($expectedRule in $security.Access) {
				[System.Security.Principal.SecurityIdentifier]$expectedSid = & $resolveSid $expectedRule.IdentityReference
				if ($null -eq $expectedSid) { return $false }
				[System.Security.AccessControl.FileSystemRights]$expectedRights = $expectedRule.FileSystemRights
				[System.Security.AccessControl.FileSystemRights]$grantedRights = if ($allowedRights.ContainsKey($expectedSid.Value)) { $allowedRights[$expectedSid.Value] } else { 0 }
				[System.Security.AccessControl.FileSystemRights]$blockedRights = if ($deniedRights.ContainsKey($expectedSid.Value)) { $deniedRights[$expectedSid.Value] } else { 0 }

				if ($expectedRule.AccessControlType -eq [System.Security.AccessControl.AccessControlType]::Deny) {
					if (($blockedRights -band $expectedRights) -ne $expectedRights) {
						Write-ADTLogEntry -Severity Warning -Message "Identity [$($expectedRule.IdentityReference)] is not denied the [$([System.Security.AccessControl.FileSystemRights]($expectedRights -band -bnot $blockedRights))] rights on [$Path]." -DebugMessage
						return $false
					}
					continue
				}
				if (($grantedRights -band $expectedRights) -ne $expectedRights) {
					Write-ADTLogEntry -Severity Warning -Message "Identity [$($expectedRule.IdentityReference)] is missing the [$([System.Security.AccessControl.FileSystemRights]($expectedRights -band -bnot $grantedRights))] rights on [$Path]." -DebugMessage
					return $false
				}
				if (($blockedRights -band $expectedRights) -ne 0) {
					Write-ADTLogEntry -Severity Warning -Message "Identity [$($expectedRule.IdentityReference)] is denied the [$([System.Security.AccessControl.FileSystemRights]($blockedRights -band $expectedRights))] rights on [$Path]." -DebugMessage
					return $false
				}
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
