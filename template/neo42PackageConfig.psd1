<#
.SYNOPSIS
	neo42 Package Configuration File

.DESCRIPTION
	Defines package metadata and configuration consumed by Neo42.Extensions for PSAppDeployToolkit (v4).
	The configuration is used to build standardized deployment logic (e.g., install/uninstall workflows), application detection, and other package-related tasks with a low-code approach.

	The parsed configuration is not exposed directly to end users. It is used internally to generate objects surfaced through the NxtDeploymentExtension (NXT) interface.

	This file format is versioned via the ConfigVersion property and may change over time. Each Neo42.Extensions release supports only specific ConfigVersion ranges. Refer to the Neo42.Extensions documentation for the supported versions per release.

	The configuration may include variables provided by the PSAppDeployToolkit and Neo42.Extensions. See the respective documentation for available variables and usage. The user configuration in $SetupCfg is also available for dynamic values.

.NOTES
	This file must comply with PowerShell Restricted Language Mode with the exception of using simple PSADT environment variables
	Metadata (Package section) must contain static package/application information only.
	Non-compliant content will cause validation errors when the configuration is loaded.

	Migration notes (v3 -> v4):
	- Legacy package configuration support is available for a limited time and can be controlled via the SupportLegacyConfig option.
	- When SupportLegacyConfig is enabled, the toolkit attempts to convert legacy configurations to the v4 format at runtime.
	- Some of the legacy properties are exposed as package specific variables with the 'Legacy_' prefix for use in deployment scripts.

	Changes in the v4 configuration format:
	- Self-references are no longer supported. The need for them has been mostly mitigated or replaced with meta variables.
	- Date values must be specified in ISO 8601 format (YYYY-MM-DD) for consistent parsing across different cultures and locales.
	- Most properties are backed by enums to improve validation, reduce ambiguity and simplify usage.

	Properties moved to toolkit configuration:
	- BlockExecution: This feature gate is now a global setting. Each app can opt-out of this feature by setting AllowBlocking to $false in the CloseProcesses configuration.

	Properties added to toolkit configuration that emulate v3 behavior:
	- AddVersionToPackageName

	Properties removed (v4):
	- UserPartRevision: Versioning is managed automatically (constructed from Package.Version). Reinstalls are detected and applied regardless of revision.
	- InstallerVersion: This field was not used by the deployment logic and should have been a custom variable if required.
	- App: This property should not have been configurable, as this folder must reside within the package root.
#>



@{
	# -- Version of the configuration schema
	ConfigVersion       = '2025.12.01.0' # @schema type: [version], required

	# -- Metadata about the package. May only contain static information.
	Package             = @{
		# -- Unique identifier for the package. Must stay constant for the lifetime of the package.
		# -- [Migrated from v3.PackageGUID]
		GUID             = '' # @schema type: [guid], required

		# -- Vendor of the package/application
		# -- This value must not contain invalid file name characters.
		# -- [Migrated from v3.AppVendor]
		Vendor           = '' # @schema type: [string], required

		# -- Name of the package/application
		# -- This value must not contain invalid file name characters.
		# -- [Migrated from v3.AppName]
		Name             = '' # @schema type: [string], required

		# -- A sanitized version of the package used for version comparisons.
		# -- [Migrated from v3.AppVersion]
		Version          = '' # @schema type: [version], required

		# -- The required host architecture for this package.
		# -- This value may differ from the actual application architecture.
		# -- A compatibility test is performed during session initialization to ensure the package can be deployed on the current system.
		# -- [Migrated from v3.AppArch]
		Architecture     = 'neutral' # @schema enum: [x86, x64, arm, arm64, neutral], default: neutral

		# -- The language of the application. neo42 recommends using "ThreeLetterWindowsLanguageName" values for this property with 'MUI' for multi-language packages.
		# -- See https://learn.microsoft.com/dotnet/api/system.globalization.cultureinfo.threeletterwindowslanguagename
		# -- Explore via PowerShell: Get-Culture -ListAvailable | ? { $_.ThreeLetterWindowsLanguageName -ne 'ZZZ' } | select DisplayName, ThreeLetterWindowsLanguageName
		# -- [Migrated from v3.AppLang]
		Language         = $null # @schema type: [string], default: MUI

		# -- The sub key name where the package information is stored.
		# -- This value must not contain invalid file name characters.
		# -- [Migrated from v3.RegPackagesKey]
		KeyName          = 'neoPackages' # @schema type: [string], default: neoPackages

		# -- The name of the directory where a shallow copy of the package is stored for deployment.
		# -- This value must not contain invalid file name characters.
		# -- [Migrated from v3.AppRootFolder]
		DirectoryName    = 'neo42Pkgs' # @schema type: [string], default: neo42Pkgs

		# -- The display name of the package as shown in application lists.
		# -- [Migrated from v3.UninstallKeyDisplayName]
		DisplayName      = $null # @schema type: [string, null], default: Name + Vendor

		# -- Control if the package should be listed in the Add/Remove Programs (ARP) list and the behavior of the uninstall button if listed.
		# -- None: The package will not be listed in ARP at all.
		# -- DisplayOnly: The package will be listed in ARP but the uninstall button will be hidden.
		# -- Uninstallable: The package will be listed in ARP and the uninstall button will be available.
		# -- [Migrated from v3.HidePackageUninstallButton and v3.HidePackageUninstallEntry]
		ApplicationEntry = 'Uninstallable' # @schema enum: [Hidden, DisplayOnly, Uninstallable], default: Uninstallable

		# -- Short description of the package. Only used for inventory purposes.
		# -- [Migrated from v3.Description]
		Description      = $null # @schema type: [string]

		# -- The author of this package.
		# -- [Migrated from v3.AppAuthor]
		Author           = $null # @schema type: [string]

		# -- Package revision number for a given version of the package.
		# -- Deployment systems may use this value to trigger reinstallations. Only used for inventory purposes.
		# -- [Migrated from v3.AppRevision]
		Revision         = 0 # @schema type: [unsigned integer], default: 0

		# -- Change tracking number for a given version of the package. Only used for inventory purposes.
		# -- [Migrated from v3.Build]
		Build            = 0 # @schema type: [unsigned integer], default: 0

		# -- Date of the last build number increment.
		# -- [Migrated from v3.LastChange]
		UpdateDate       = $null # @schema type: [datetime, null], default: null

		# -- Date of package creation.
		# -- [Migrated from v3.ScriptDate]
		CreationDate     = $null # @schema type: [datetime, null], default: null

		# -- Information about environments the package has been tested on.
		# -- [Migrated from v3.TestedOn]
		TestedOn         = $null # @schema type: [string]

		# -- Alternate inventory identifier for software management systems.
		# -- [Migrated from v3.InventoryId]
		InventoryId      = $null # @schema type: [string]

		# -- Dependency information for this package.
		# -- [Migrated from v3.Dependencies]
		Dependencies     = $null # @schema type: [string]

		# -- Wether or not old instances of this package should be uninstalled prior to installation.
		# -- This method relies solely on the presence of an existing package, not the detection method.
		UninstallOld     = $false # @schema type: [boolean], default: false
	}

	# -- A list of requirements that must be met before installing this package.
	# -- [Migrated from v3.DependentPackages]
	Requirements        = @(
		@{
			# -- PowerShell based filter script to identify the dependency.
			# -- See Detection.Criteria for details.
			Criteria     = @{
				Store      = 'ARP64' # @schema enum: [ARP, ARP32, ARP64, AppX, Package], default: ARP
				Identifier = '{00000000-0000-0000-0000-000000000000}' # @schema type: [string, null]
				Filter     = $null # @schema type: [scriptblock, null]
			}

			# -- The desired state of the dependency.
			# -- Present: The dependency must be present.
			# -- Absent: The dependency must be absent.
			DesiredState = 'Present' # @schema enum: [Present, Absent], default: Present

			# -- The action to take if the requirement is not met.
			# -- Fail: The installation will fail with an error.
			# -- Warn: The installation will continue, but a warning is logged.
			# -- Uninstall: The conflicting application will be uninstalled prior to installation. Only valid if DesiredState is Present.
			OnConflict   = 'Fail' # @schema enum: [Fail, Warn, Uninstall], default: Fail

			# -- Custom error message to log, if the desired state is not met.
			ErrorMessage = $null # @schema type: [string, null], default: null
		}
	)

	# -- The detection mechanism for the main application this package manages.
	# -- The defined filter must resolve to one or zero results.
	# -- If multiple results are found, the deployment will fail safely.
	# -- [Migrated from v3.UninstallKey[*]]
	Detection           = @{
		# -- Determines whether application detection is enabled for this package or not.
		# -- If $true, the detection result will be evaluated during the deployment.
		# -- If set to false, the default install and uninstall logic will always be applied regardless of the actual presence of the application.
		Enabled           = $true # @schema type: [boolean], default: false

		# -- Marketed version of the application.
		# -- This value is used for version comparisons that reference the main application.
		# -- It is recommended to set either this property or UsePackageVersion as it is required for some features such as soft migration and upgrade logic.
		# -- [Migrated from v3.DisplayVersion]
		Version           = $null # @schema type: [string, null]

		# -- Use the package version for detection.
		# -- This might be useful if the package version is aligned with the application version and you want to avoid redundant version information in the configuration.
		# -- If both Version and UsePackageVersion are defined, UsePackageVersion takes precedence.
		UsePackageVersion = $false # @schema type: [boolean], default: false

		# -- Use the defined criteria to detect the presence of the main application this package manages.
		# -- If no criteria is defined and Detection is enabled, you must implement the detection logic in the deployment script.
		Criteria          = @{
			# -- Store of the application to detect.
			# -- ARP*: Add/Remove Programs - Will search all standard ARP locations but exclude entries that track package installations.
			# -- AppX: Windows AppX Store - Will search installed AppX packages.
			# -- Package: Add/Remove Programs Package Store - Will search all standard ARP locations but only include entries that track package installations.
			Store      = 'ARP' # @schema enum: [ARP, ARP32, ARP64, AppX, Package], default: ARP

			# -- The application identifier to look for. This value assumes the code can be used directly.
			# -- Specifying the identifier is optional but improves performance and reliability drastically.
			# -- If not specified, the filter script must be able to uniquely identify the application.
			# -- The format of the identifier depends on the selected store:
			# -- ARP*: The ARP key name
			# -- AppX: The PackageFamilyName of the AppX package
			# -- Package: The package guid in "B" format (e.g., {XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX})
			Identifier = $null # @schema type: [string, null]

			# -- Custom filter script to identify the application. This script return $true if the application matches the criteria or $false if it does not.
			# -- The script is provided with the current InstalledApplication object from the selected store for evaluation.
			Filter     = $null # @schema type: [scriptblock, null]
		}
	}

	# -- Soft migration is a mechanism to detect the presence of the main application in a desired state.
	# -- Passing the conditions defined here will mark the application as installed without performing any deployment actions.
	# -- The package will will take ownership of the application for future management and will exit gracefully.
	# -- [Migrated from v3.SoftMigration]
	SoftMigration       = @{
		# -- Whether to enable the soft migration mechanism for this package or not.
		# -- If $true, the conditions defined in this section will be evaluated during deployment.
		# -- If the conditions are met, the deployment will be skipped and the application will be marked as installed. If the conditions are not met, the deployment will proceed as normal.
		Enabled           = $true # @schema type: [boolean], default: false

		# -- Method to use for detection.
		# -- Custom: The script will evaluate the detection API, but the actual detection logic must be implemented in the deployment script. This allows for maximum flexibility but requires custom scripting.
		# -- Detection: The detection logic will be used.
		# -- File: Will base detection on the presence of a file. May optionally include version checking, if the Version property is defined.
		Mode              = 'Detection' # @schema enum: [Custom, Detection, File], default: Detection

		# -- May define the target for the selected detection method.
		# -- See the Mode property for details on compatible targets.
		Target            = $null # @schema type: [string, null]

		# -- (Alternate) Version to use for the detection.
		# -- Some detection modes may contain inherent version information, but this property allows overriding that value.
		# -- See the Mode property for details on compatible version usage.
		# -- This version does not have to conform to strict versioning rules. An extended attempt is made to parse and compare the version.
		Version           = $null # @schema type: [string, null]

		# -- Use the version defined in the Package section for (alternate) version detection.
		# -- This might be useful if the target version is aligned with the package version and you want to avoid redundant version information in the configuration.
		# -- If both Version and UsePackageVersion are defined, UsePackageVersion takes precedence.
		UsePackageVersion = $false # @schema type: [boolean], default: false
	}

	# -- List of processes that block the deployment from proceeding.
	# -- Depending on administrator configuration in the SetupCfg, these applications may be closed automatically or prompt the user to close them.
	# -- The deployment will not proceed until these applications are closed or a timeout occurs.
	# -- [Migrated from v3.AppCloseProcesses]
	CloseProcesses      = @(
		@{
			# -- The process name/path to monitor and close if required.
			# -- This value must not contain invalid path characters.
			Name          = '' # @schema type: [string], required

			# -- Description of the process shown to the user when prompting to close the application.
			Description   = $null # @schema type: [string, null], default: Name

			# -- Whether to include this process in the block execution feature of the deployment or not.
			# -- If $true, the process will be prevented from starting during deployment if the block execution feature is enabled.
			# -- If $false, the process will only be closed if already running, but not blocked from starting.
			AllowBlocking = $true # @schema type: [boolean], default: true

			# -- Instructions how to reopen the process after deployment, if it was running.
			# -- Values here may be disabled by administrator configuration in the SetupCfg.
			# -- None: Do not attempt to reopen the process, even if it was running. May be incompatible.
			# -- Binary: Attempt to reopen the process using the original binary path only.
			# -- Commandline: Attempt to reopen the process using the original command line arguments.
			Reopen        = 'None' # @schema enum: [None, Binary, Commandline], default: None
		}
	)

	# -- List of shortcuts that are managed by this package.
	# -- Shortcuts may be created, deleted, or copied from an existing start menu location.
	# -- Upon uninstallation, any managed shortcut will be removed automatically.
	# -- The shortcuts managed here only reference the machine-wide CommonDesktop location.
	# -- [Migrated from v3.CommonDesktopShortcuts[*]]
	ManagedShortcuts    = @(
		@{
			# -- Defines the mode of management for the shortcut.
			# -- Create: Create a new shortcut in the defined Location pointing to the Source target.
			# -- Delete: Delete an existing shortcut in the defined Location.
			# -- Copy: Copy an existing (start menu) shortcut from the Source location to the defined Location.
			Mode     = 'Delete' # @schema enum: [Create, Delete, Copy], default: Delete

			# -- Location of the managed shortcut.
			Location = 'Desktop' # @schema enum: [Desktop, StartMenu], required

			# -- Name (or relative path) of the shortcut file that is managed.
			# -- This value must not contain invalid file name characters.
			Target   = '' # @schema type: [string], required

			# -- Additional argument used depending on the selected Mode.
			# -- See the Mode property for details on compatible Target usage.
			Source   = $null # @schema type: [string, null]
		}
	)

	# -- List of detection mechanisms for applications.
	# -- Any application listed here may be considered part of the main application managed by this package.
	# -- By default these applications apply the same hide logic as the main application, if applicable.
	# -- Additionally, these applications may be used in the deployment logic as required.
	# -- See the Detection section for details on defining application detection filter.
	# -- [Migrated from v3.UninstallKeysToHide]
	ManagedApplications = @(
		@{
			Store      = 'ARP' # @schema enum: [ARP, ARP32, ARP64, AppX, Package], default: ARP
			Identifier = $null # @schema type: [string, null]
			Filter     = $null # @schema type: [scriptblock, null]
		}
	)

	# -- Deployment instructions for the package.
	Deployment          = @{
		# -- Location the main application will be installed into, if applicable.
		# -- Will be used as fallback method to detect the application size.
		# -- [Migrated from v3.InstallLocation]
		InstallLocation = $null # @schema type: [string, null], default: null

		# -- The installation instructions.
		Installation    = @{
			# -- Method to use for the installation.
			# -- $null: Installation is performed via custom script logic only.
			# -- MSI: Microsoft Installer package (.msi, .msp)
			# -- AppX: Windows AppX package (.appx, .appxbundle, .msix, .msixbundle)
			# -- Setup: Generic setup executable
			# -- Copy: Simple file transfer operation from the DirFiles source to the Target property
			# -- Other values: Apply different defaults and caching logic etc. See documentation for details.
			# -- [Migrated from v3.InstallMethod]
			Method          = $null # @schema type: [enum, null], enum: [Setup, MSI, AppX, InnoSetup, BitRockInstaller, Burn, Nullsoft, Copy], default: null

			# -- Method specific target such as file paths, source locations, identifiers, etc.
			# -- See documentation for details on compatible values per installation method.
			# -- [Migrated from v3.InstFile]
			Target          = $null # @schema type: [string, null]

			# -- Arguments that are passed to the installation method, if applicable.
			# -- This values is added on top of any default arguments (if enabled) and may include meta variables.
			# -- [Migrated from v3.InstPara]
			Arguments       = $null # @schema type: [string, null]

			# -- Wether to apply default parameters for the selected installation method.
			# -- Defaults vary and may originate from the toolkit configuration, the application metadata or function specific logic.
			# -- If set to $false, only the Arguments will be passed to the installation method.
			# -- [Migrated from v3.AppendInstParaToDefaultParameters]
			Defaults        = $true # @schema type: [boolean], default: true

			# -- An alternate name for the installation log file. The log will be located in the package log directory configured in the toolkit configuration.
			# -- [Migrated from v3.InstLogFile]
			LogName         = $null # @schema type: [string, null], default: null

			# -- Additional result codes that indicate a successful installation.
			# -- The code 0 will always be included as success code and cannot be removed.
			# -- [Migrated from v3.AcceptedInstallExitCodes]
			SuccessCodes    = @() # @schema item: [integer]

			# -- Additional result codes that indicate a reboot is required.
			# -- The codes 1641 and 3010 will always be included as reboot codes and cannot be removed.
			# -- [Migrated from v3.AcceptedInstallRebootCodes]
			RebootCodes     = @() # @schema item: [integer], default: [1641, 3010]

			# -- If set to $true, any exit code returned by the deployment method will be ignored.
			# -- This value takes precedence over SuccessCodes and RebootCodes.
			# -- [Migrated from v3.AcceptedInstallRebootCodes:*]
			IgnoreExitCodes = $false # @schema type: [boolean], default: false

			# -- Determine the reboot behavior of this package once completed.
			# -- IfRequired: Will return a reboot exit code. The deployment system may choose to reboot based on its own logic.
			# -- Always: Will always return a reboot exit code independent of the actual deployment result.
			# -- Never: Will ignore the deployment result and never return a reboot exit code.
			# -- [Migrated from v3.Reboot]
			Reboot          = 'IfRequired' # @schema enum: [IfRequired, Always, Never], default: IfRequired

			# -- Determine the behavior to apply when the main application is detected in the desired version.
			# -- None: The given installation logic will be skipped entirely. Any reinstall logic must be implemented in the deployment script.
			# -- Install: Apply the installation logic.
			# -- Repair: Apply the repair logic, if applicable. Fallback to installation logic if not supported.
			# -- Reinstall: Apply the uninstallation followed by installation logic.
			# -- [Migrated from v3.Reinstall]
			ReinstallMode   = 'Reinstall' # @schema enum: [None, Install, Repair, Reinstall], default: Reinstall

			# -- Determine the behavior to apply when the main application is already detected but in a different version.
			# -- Install: Apply the installation logic.
			# -- Reinstall: Apply the uninstallation followed by installation logic.
			# -- [Migrated from v3.MSIUpgradable]
			UpgradeMode     = 'Reinstall' # @schema enum: [Install, Reinstall], default: Reinstall

			# -- Define conditions that should be awaited after the installation method was executed.
			# -- This allows to ensure certain system states before proceeding with the deployment and the validation.
			# -- [Migrated from TestConditionsPreSetupSuccessCheck.Install]
			Awaiters        = @{
				# -- Default time to wait for each awaiter condition before timing out.
				# -- Applies if the individual condition do not define a custom timeout.
				# -- Format: HH:MM:SS
				DefaultTimeout = '00:00:30' # @schema type: [timespan], default: 00:00:30

				# -- List of registry keys to await.
				RegistryKeys   = @(
					@{
						# -- The registry key to monitor.
						Key     = '' # @schema type: [string], required

						# -- The name of the value to monitor within the key.
						# -- If $null, the existence of the key is monitored.
						Name    = $null # @schema type: [string, null]

						# -- The desired value to await.
						# -- If $null, only the existence of the key/value is monitored.
						Value   = $null # @schema type: [string, null]

						# -- Wether to await the existence or absence of the key/value.
						Exists  = $true # @schema type: [boolean], default: true

						# -- Custom timeout for this awaiter condition.
						# -- Format: HH:MM:SS
						Timeout = $null # @schema type: [timespan, null]
					}
				)

				# -- List of processes to await.
				Processes      = @(
					@{
						# -- The process name to monitor.
						Name    = '' # @schema type: [string], required

						# -- Wether to await the existence or absence of the process.
						Exists  = $false # @schema type: [boolean], default: true

						# -- Custom timeout for this awaiter condition.
						Timeout = $null # @schema type: [timespan, null]
					}
				)
			}

			# -- Will activate the per user deployment logic post installation.
			# -- A ActiveSetup entry will be created, which will trigger the user part on next logon for existing users.
			# -- Any user already logged in during installation will have the user part executed immediately.
			# -- User part logic is solely defined in the deployment scripts and is not part of this configuration.
			# -- [Migrated from v3.UserPartOnInstallation]
			UserPart        = $false # @schema type: [boolean], default: false
		}

		# -- The uninstallation instructions.
		Uninstallation  = @{
			# -- Method to use for the uninstallation.
			# -- [Migrated from v3.UninstallMethod]
			Method          = $null # @schema type: [enum, null], enum: [Setup, MSI, AppX, InnoSetup, BitRockInstaller, Burn, Nullsoft, Copy], default: null

			# -- Method specific target such as file paths, source locations, identifiers, etc.
			# -- See documentation for details on compatible values per uninstallation method.
			# -- [Migrated from v3.UninstFile]
			Target          = $null # @schema type: [string, null]

			# -- Arguments that are passed to the uninstallation method, if applicable.
			# -- [Migrated from v3.UninstPara]
			Arguments       = $null # @schema type: [string, null]

			# -- Wether to apply default parameters for the selected uninstallation method.
			# -- [Migrated from v3.AppendUninstParaToDefaultParameters]
			Defaults        = $true # @schema type: [boolean], default: true

			# -- An alternate name for the uninstallation log file. The actual log file path is generated automatically by the toolkit.
			# -- [Migrated from v3.UninstLogName]
			LogName         = $null # @schema type: [string, null], default: null

			# -- Additional result codes that indicate a successful uninstallation.
			# -- The code 0 will always be included as success code and cannot be removed.
			# -- [Migrated from v3.AcceptedUninstallExitCodes]
			SuccessCodes    = @() # @schema item: [integer], default: [0]

			# -- Additional result codes that indicate a reboot is required.
			# -- The codes 1641 and 3010 will always be included as reboot codes and cannot be removed.
			# -- [Migrated from v3.AcceptedUninstallRebootCodes]
			RebootCodes     = @() # @schema item: [integer], default: [1641, 3010]

			# -- If set to $true, any exit code returned by the deployment method will be ignored.
			# -- This value takes precedence over SuccessCodes and RebootCodes.
			# -- [Migrated from v3.AcceptedUninstallExitCodes:*]
			IgnoreExitCodes = $false # @schema type: [boolean], default: false

			# -- Determine the reboot behavior of this package once completed.
			# -- IfRequired: Will return a reboot exit code. The deployment system may choose to reboot based on its own logic.
			# -- Always: Will always return a reboot exit code independent of the actual deployment result.
			# -- Never: Will ignore the deployment result and never return a reboot exit code.
			# -- If set to $null, the reboot behavior will be inherited from the installation instructions.
			# -- [Migrated from v3.Reboot]
			Reboot          = $null # @schema type: [enum, null], enum: [IfRequired, Always, Never], default: null

			# -- Define conditions that should be awaited after the installation method was executed.
			# -- See Installation.Awaiters for details.
			# -- [Migrated from v3.TestConditionsPreSetupSuccessCheck.Uninstall]
			Awaiters        = $null

			# -- Will activate the per user deployment logic post uninstallation.
			# -- See Deployment.Install.UserPart for details.
			# -- neo42 recommends not using this property unless absolutely necessary as this will leave remnants of the application on the system.
			# -- [Migrated from v3.UserPartOnUninstallation]
			UserPart        = $false # @schema type: [boolean], default: false
		}
	}

	# -- Custom variables that are made available to the deployment scripts.
	# -- Variables may take any PowerShell serializable value including arrays and hashtables.
	# -- [Migrated from v3.PackageSpecificVariables]
	Variables           = @{
		MyVarStatic  = '$DemoValue'
		MyVarDynamic = "$envProgramFiles\MyApp"
		MyExpression = if ($envArchitecture.Contains('64')) { 'Value1' } else { 'Value2' }
		MyVarArray   = @('Item1', 'Item2', 'Item3')
		MyVarDict    = @{
			Key1 = 'Value1'
			Key2 = 'Value2'
		}
	}
}
