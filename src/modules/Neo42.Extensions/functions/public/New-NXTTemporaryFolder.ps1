function New-NXTTemporaryFolder {
	<#
	.SYNOPSIS
	Creates and configures a new temporary folder.
	.DESCRIPTION
	This function generates a new temporary folder in a specified or default root path, ensuring the folder has specific security permissions set.
	If the provided root path doesn't exist or has incorrect permissions, it will be recreated accordingly.
	The function ensures unique naming for the temporary folder and outputs its path upon successful creation.
	.OUTPUTS
	System.IO.DirectoryInfo - The created temporary folder.
	.EXAMPLE
	New-NxtTemporaryFolder

	Will create a new folder.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Downstream functions handle this.')]
	[CmdletBinding(SupportsShouldProcess)]
	[OutputType([System.IO.DirectoryInfo])]
	param ()
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Collections.Generic.IReadOnlyDictionary[System.String, System.Object]]$adtEnvironment = Get-ADTEnvironmentTable
	}
	process {
		try {
			[System.IO.DirectoryInfo]$pathBase = [System.IO.Path]::Combine($adtEnvironment.envTemp, 'n42Tmp')
			[System.Security.Principal.SecurityIdentifier]$ownerSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
			[System.Collections.Hashtable]$newFolderSplat = @{
				FullControl       = @($ownerSid, [System.Security.Principal.WellKnownSidType]::LocalSystemSid)
				ReadAndExecute    = [System.Security.Principal.WellKnownSidType]::BuiltinUsersSid
				Owner             = $ownerSid
				InformationAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
			}

			if (-not $pathBase.Exists) {
				Write-ADTLogEntry -Message "Base path for temporary folder [$($pathBase.FullName)] does not exist. Creating folder with predefined permissions."
				New-NXTFolderWithPermission @newFolderSplat -Path $pathBase -Force
			}

			[System.UInt32]$folderNumber = $pathBase.EnumerateDirectories() | & {
				begin { [System.UInt32]$max = 0; [System.UInt32]$refStore = 0 }
				process { if ([System.UInt32]::TryParse($_.Name, [ref]$refStore) -and $refStore -gt $max) { $max = $refStore } }
				end { $max + 1 }
			}

			Write-ADTLogEntry -Message "Creating temporary folder [$([System.IO.Path]::Combine($pathBase, $folderNumber))] with predefined permissions."
			New-NXTFolderWithPermission @newFolderSplat -Path ([System.IO.Path]::Combine($pathBase, $folderNumber)) -Force -PassThru
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Add-ADTModuleCallback -HookPoint PreClose -Callback $script:CommandTable.'Remove-NXTTemporaryFolder'
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
