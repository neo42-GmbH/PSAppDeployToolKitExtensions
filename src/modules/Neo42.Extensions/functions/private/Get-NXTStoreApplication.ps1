function Get-NXTStoreApplication {
	<#
	.SYNOPSIS
	Retrieves the application matching the application search criteria.
	#>
	[OutputType([PSADT.Types.InstalledApplication[]])]
	[CmdletBinding(DefaultParameterSetName = 'Criteria')]
	param (
		[Parameter(Mandatory)]
		[PSADTNXT.Application.ApplicationStore]
		$Store,
		[Parameter()]
		[AllowEmptyString()]
		[System.String]
		$Identifier
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Management.Automation.ScriptBlock]$getArpApplications = {
			param (
				[Parameter(Mandatory)]
				[Microsoft.Win32.RegistryView[]]
				$Views,
				[Parameter(Mandatory)]
				[AllowEmptyString()]
				[System.String]
				$Identifier,
				[System.Management.Automation.SwitchParameter]
				$Package
			)
			foreach ($view in $Views) {
				[Microsoft.Win32.RegistryKey]$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $view)
				[Microsoft.Win32.RegistryKey]$uninstallKey = $baseKey.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')
				try {
					if ([System.String]::IsNullOrWhiteSpace($Identifier)) {
						foreach ($subKeyName in $uninstallKey.GetSubKeyNames()) {
							if (([Microsoft.Win32.RegistryKey]$appKey = $uninstallKey.OpenSubKey($subKeyName)) -and
								$appKey.GetValue('DisplayName') -and
								$Package.ToBool() -eq ($null -ne $appKey.GetValue('neoRegPackagesKeyRef'))
							) {
								$PSCmdlet.WriteObject($appKey)
							}
						}
					}
					else {
						if (([Microsoft.Win32.RegistryKey]$appKey = $uninstallKey.OpenSubKey($Identifier)) -and
							$appKey.GetValue('DisplayName') -and
							$Package.ToBool() -eq ($null -ne $appKey.GetValue('neoRegPackagesKeyRef'))
						) {
							$PSCmdlet.WriteObject($appKey)
						}
					}
				}
				finally {
					if ($uninstallKey) {
						$uninstallKey.Dispose()
					}
					if ($baseKey) {
						$baseKey.Dispose()
					}
				}
			}
		}
	}
	process {
		try {
			switch ($Store) {
				([PSADTNXT.Application.ApplicationStore]::Package) {
					& $getArpApplications -Views ([Microsoft.Win32.RegistryView]::Registry64) -Identifier $Identifier -Package | . {
						process {
							$PSCmdlet.WriteObject([PSADTNXT.Extensions.NxtPsadtExtensions]::ToInstalledApplication($_))
						}
					}
				}
				([PSADTNXT.Application.ApplicationStore]::ARP) {
					& $getArpApplications -Views ([PSADTNXT.Extensions.NxtRegistryExtensions]::GetAllViews()) -Identifier $Identifier | . {
						process {
							$PSCmdlet.WriteObject([PSADTNXT.Extensions.NxtPsadtExtensions]::ToInstalledApplication($_))
						}
					}
				}
				([PSADTNXT.Application.ApplicationStore]::ARP64) {
					& $getArpApplications -Views ([Microsoft.Win32.RegistryView]::Registry64) -Identifier $Identifier | . {
						process {
							$PSCmdlet.WriteObject([PSADTNXT.Extensions.NxtPsadtExtensions]::ToInstalledApplication($_))
						}
					}
				}
				([PSADTNXT.Application.ApplicationStore]::ARP32) {
					& $getArpApplications -Views ([Microsoft.Win32.RegistryView]::Registry32) -Identifier $Identifier | . {
						process {
							$PSCmdlet.WriteObject([PSADTNXT.Extensions.NxtPsadtExtensions]::ToInstalledApplication($_))
						}
					}
				}
				([PSADTNXT.Application.ApplicationStore]::AppX) {
					Get-AppxProvisionedPackage -Online | . {
						process {
							if (-not $Identifier -or ($Identifier -eq $_.PackageName)) {
								$PSCmdlet.WriteObject([PSADTNXT.Extensions.NxtPsadtExtensions]::ToInstalledApplication($_))
							}
						}
					}
				}
				default {
					[System.Collections.Hashtable]$errorParams = @{
						Exception         = [System.NotImplementedException]::new("The specified application store [$Store] is not supported.")
						Category          = [System.Management.Automation.ErrorCategory]::NotImplemented
						ErrorId           = 'StoreNotSupported'
						RecommendedAction = 'Use a supported application store.'
						TargetName        = $Store
					}
					throw (New-ADTErrorRecord @errorParams)
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
