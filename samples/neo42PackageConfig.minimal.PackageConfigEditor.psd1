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
			Store      = 'ARP64'
			Identifier = '{B4B79BC4-A1BD-4115-BC10-FA3EF4457A14}'
		}
	}
	SoftMigration    = @{
		Enabled = $true
	}
	CloseProcesses   = @(
		@{
			Name   = 'Neo42.PackageConfigEditor'
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
