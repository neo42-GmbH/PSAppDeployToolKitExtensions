@{
	ConfigVersion    = '2025.12.01.0'
	Package          = @{
		GUID         = '{0428729D-9D33-456B-BB44-F090638DBD53}'
		Vendor       = 'neo42'
		Name         = 'PackageConfigEditor'
		Version      = '1.1.2.0'
		Architecture = 'x64'
	}
	Detection        = @{
		Enabled           = $true
		UsePackageVersion = $true
		Criteria          = @{
			Store  = 'ARP64'
			Filter = { $_.UpgradeCode -eq '{8BB4167C-B28D-4BC6-BA0D-A52F2DCCB259}' }
		}
	}
	SoftMigration    = @{
		Enabled = $true
	}
	CloseProcesses   = @(
		@{
			Name   = 'Neo42.PackageConfigEditor'
			Reopen = 'Binary'
		}
	)
	ManagedShortcuts = @(
		@{
			Mode   = 'Copy'
			Target = 'PackageConfigEditor.lnk'
			Source = 'Programs\neo42\PackageConfigEditor\PackageConfigEditor.lnk'
		}
	)
	Deployment       = @{
		InstallLocation = "$envProgramFiles\neo42\PackageConfigEditor"
		Installation    = @{
			Method        = 'MSI'
			Target        = 'neo42_PackageConfigEditor_1.1.2.0.msi'
			ReinstallMode = 'Repair'
			UpgradeMode   = 'Install'
		}
		Uninstallation  = @{
			Method = 'MSI'
		}
	}
}
