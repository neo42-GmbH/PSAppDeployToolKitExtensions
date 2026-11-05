# neo42PackageConfig.psd1 – Package Configuration Reference

This document describes every value of the `neo42PackageConfig.psd1` and how it controls the standardized deployment logic of `Invoke-NXTDeployment`.

The sample [neo42PackageConfig.empty.psd1](../samples/neo42PackageConfig.empty.psd1) lists all values with inline comments and can be used as a starting point. [neo42PackageConfig.PackageConfigEditor.psd1](../samples/neo42PackageConfig.PackageConfigEditor.psd1) shows a filled example.

**Legend**

| Mark | Meaning |
|:----:|:--------|
| **R** | Required. Loading fails if the value is missing or empty. |
| 🔤 | String value in which [meta variables](#meta-variables) are resolved at runtime. |

## Table of contents

- [neo42PackageConfig.psd1 – Package Configuration Reference](#neo42packageconfigpsd1--package-configuration-reference)
	- [Table of contents](#table-of-contents)
	- [How the file is processed](#how-the-file-is-processed)
	- [Good to know](#good-to-know)
		- [Syntax rules](#syntax-rules)
		- [Variables available while loading](#variables-available-while-loading)
		- [Meta variables](#meta-variables)
		- [Accessing the configuration in hooks](#accessing-the-configuration-in-hooks)
	- [Value reference](#value-reference)
		- [ConfigVersion](#configversion)
		- [Package](#package)
		- [Application criteria](#application-criteria)
		- [Requirements](#requirements)
		- [Detection](#detection)
		- [SoftMigration](#softmigration)
		- [CloseProcesses](#closeprocesses)
		- [ManagedShortcuts](#managedshortcuts)
		- [ManagedApplications](#managedapplications)
		- [Deployment](#deployment)
			- [Installation](#installation)
			- [Uninstallation](#uninstallation)
			- [Deployment methods](#deployment-methods)
			- [Default arguments](#default-arguments)
			- [Reinstall and upgrade mode](#reinstall-and-upgrade-mode)
			- [Awaiters](#awaiters)
		- [Variables](#variables)

---

## How the file is processed

1. The file `neo42PackageConfig.psd1` is read from the package root.
   > [!IMPORTANT]
   > If the toolkit option `NXT.Toolkit.SupportLegacyConfig` is enabled (default) and a `neo42PackageConfig.json` exists as well, the JSON file is used instead. Remove the JSON file from packages that use the PSD1 format.
2. The file is parsed. Syntax errors make loading fail.
3. The content is checked against the [syntax rules](#syntax-rules). Commands or unknown variables make loading fail.
4. The hashtable is evaluated. Only the [variables available while loading](#variables-available-while-loading) can be used.
5. The result is validated (required values, GUID/version/time span formats, valid file names and paths, allowed enum values, filter script blocks). All validation errors are reported together.
6. When the deployment session is opened, the [meta variables](#meta-variables) are resolved.

> [!NOTE]
> Values that are not required may be omitted. In that case, the default documented below applies. Optional values without a default may also be set to `$null`.

## Good to know

### Syntax rules

The file is a PowerShell data file (hashtable). It is evaluated in a restricted environment with the following rules:

| Allowed | Not allowed |
|:--------|:------------|
| Literals: strings, numbers, `$true`, `$false`, `$null`, arrays `@()` and hashtables `@{}` | Commands and functions, e.g. `Get-Item`, `Join-Path`, `Test-Path` |
| The [variables available while loading](#variables-available-while-loading) | Any other variable, including `$adtSession` |
| Expandable strings, e.g. `"$envProgramFiles\Vendor\App"` | Self references to other values of the configuration |
| Operators, property access and method calls, e.g. `$envArchitecture.Contains('64')` | |
| `if` / `else` expressions, e.g. `if ($envOSArchitecture -eq '64-bit') { 'x64' } else { 'x86' }` | |
| Script blocks (only meaningful for `Filter` values) | |

Additionally:

- Use single quotes for literal strings and double quotes only if variables should be expanded. A `$` inside double quotes must be escaped with a backtick (`` `$ ``).
- The values of the [Package](#package) section should be plain literals. External tools read this section without evaluating the file.
- Time spans are written as `HH:MM:SS`, e.g. `'00:01:30'`.
- Dates are written in ISO 8601 format `YYYY-MM-DD`.
- Enum values are not case-sensitive.

### Variables available while loading

| Variable | Content |
|:---------|:--------|
| All PSADT environment variables, e.g. `$envProgramFiles`, `$envProgramData`, `$envWinDir`, `$envOSArchitecture` | Provided by the PSADT environment table. See the [PSADT documentation](https://psappdeploytoolkit.com) and the [variable reference](./PSAppDeployToolkit.Neo42.Extensions.Variables.md). |
| `$SetupCfg` | The merged, **read-only** `Setup.cfg` settings of the package. Read a value with `$SetupCfg['<Section>']['<KEY>']`, e.g. `$SetupCfg['Options']['SOFTMIGRATION']`. This allows dynamic values depending on the customer configuration. |

### Meta variables

Some paths are only known once the deployment session is opened. They can be referenced with the following placeholders (not case-sensitive) in values marked with 🔤 and in all string values of [Variables](#variables):

| Placeholder | Resolves to |
|:------------|:------------|
| `%DirFiles%` | The `Files` directory of the package (or the mounted WIM). |
| `%DirSupportFiles%` | The `SupportFiles` directory of the package. |
| `%LogFolder%` | The log directory of the deployment. |
| `%InstLogFile%` | Full path of the installation log, built from `%LogFolder%` and `Installation.LogName`. Only useful if `LogName` is set. |
| `%UninstLogFile%` | Full path of the uninstallation log, built from `%LogFolder%` and `Uninstallation.LogName`. Only useful if `LogName` is set. |
| `%PackageDirectory%` | The cache directory of this package version (see `Package.DirectoryName`). |
| `%InstallLocation%` | The value of `Deployment.InstallLocation`. |

### Accessing the configuration in hooks

The configuration itself is not exposed to the deployment script. Its values are available through the session object in hooks and extension modules, e.g.:

| Section | Session property |
|:--------|:-----------------|
| `Package` | `$adtSession.NXT.Package` |
| `Requirements` | `$adtSession.NXT.Requirements` |
| `Detection` | `$adtSession.NXT.Detection` (additionally `IsInstalled`, `Application`, `VersionStatus`) |
| `SoftMigration` | `$adtSession.NXT.SoftMigration` (additionally `Result`) |
| `CloseProcesses` | `$adtSession.NXT.CloseProcesses` |
| `ManagedShortcuts` | `$adtSession.NXT.ManagedShortcuts` |
| `ManagedApplications` | `$adtSession.NXT.ManagedApplications` |
| `Deployment.InstallLocation` | `$adtSession.NXT.InstallLocation` |
| `Deployment.Installation` | `$adtSession.NXT.Install` |
| `Deployment.Uninstallation` | `$adtSession.NXT.Uninstall` |
| `Variables` | `$adtSession.NXT.Variables` |

The session properties can be changed in early hooks (e.g. `CustomBegin`) to influence the following deployment logic.

---

## Value reference

Each section lists the **parent** of a value in its heading.

### ConfigVersion

Parent: `/`

| Value | Type | Req. | Default | Description |
|:------|:-----|:----:|:--------|:------------|
| `ConfigVersion` | version | **R** | | Version of the configuration format. The current release supports exactly `2025.12.01.0`. |

### Package

Parent: `/Package/`

Static metadata of the package.

| Value | Type | Req. | Default | Description |
|:------|:-----|:----:|:--------|:------------|
| `GUID` | guid | **R** | | Unique identifier of the package, e.g. `'{0428729D-9D33-456B-BB44-F090638DBD53}'`. Must stay constant for the lifetime of the package series as it directly affects the update behavior. |
| `Vendor` | string | **R** | | Manufacturer of the application. Must be a valid file name. |
| `Name` | string | **R** | | Name of the application. Must be a valid file name. |
| `Version` | version | **R** | | Version of the package in format `a.b[.c[.d]]`, used for version comparisons. Typically the version of the application. |
| `Architecture` | enum | | `neutral` | Required host architecture: `x86`, `x64`, `arm`, `arm64`, `neutral`. May differ from the application architecture. Compatibility with the device is checked when the session is opened. |
| `Language` | string | | `MUI` | Language of the application. neo42 recommends [ThreeLetterWindowsLanguageName](https://learn.microsoft.com/dotnet/api/system.globalization.cultureinfo.threeletterwindowslanguagename) values (e.g. `DEU`, `ENU`) and `MUI` for multi-language packages. |
| `KeyName` | string | | `neoPackages` | Registry sub key below `HKLM:\SOFTWARE` in which package information is stored. Must be a valid file name. |
| `DirectoryName` | string | | `neo42Pkgs` | Name of the package cache directory below `ProgramData`. The package is cached to `<DirectoryName>\<Vendor>\<Name>\<Version>`. Must be a valid file name. |
| `DisplayName` | string | | `<Vendor> <Name>` | Display name of the package's own entry in Add/Remove Programs. If the toolkit option `NXT.Toolkit.AppendVersionToPackageName` is enabled (default), the package version is appended. |
| `ApplicationEntry` | enum | | `Uninstallable` | Visibility of the package's own entry in Add/Remove Programs. `Hidden`: not listed. `DisplayOnly`: listed without uninstall button. `Uninstallable`: listed with uninstall button. |
| `Description` | string | | | Short description of the package. Inventory only. |
| `Author` | string | | | Author of the package. Inventory only. |
| `Revision` | unsigned integer | | `0` | Package revision for a given version. Deployment systems may use it to trigger reinstallations. Inventory only. |
| `Build` | unsigned integer | | `0` | Change tracking number for a given version. Inventory only. |
| `UpdateDate` | date | | | Date of the last `Build` increment (`YYYY-MM-DD`). |
| `CreationDate` | date | | | Date of package creation (`YYYY-MM-DD`). |
| `TestedOn` | string | | | Environments the package was tested on, e.g. `'Win10 x64, Win11 x64'`. |
| `InventoryId` | string | | | Alternate inventory identifier for software management systems. |
| `Dependencies` | string | | | Free text dependency information. For dependencies that should be checked, use [Requirements](#requirements). |
| `UninstallOld` | bool | | `$false` | `$true`: previously registered packages with the same `GUID` but a different version are uninstalled with their own uninstall string before the installation. `$false`: only their registration and cache directory are removed. This is based solely on the package registration, not on [Detection](#detection). |

### Application criteria

Several sections identify installed applications with the same criteria structure: [Requirements](#requirements) (`Criteria`), [Detection](#detection) (`Criteria`) and [ManagedApplications](#managedapplications) (each item).

| Value | Type | Req. | Default | Description |
|:------|:-----|:----:|:--------|:------------|
| `Store` | enum | | `ARP` | Where to search, see below. |
| `Identifier` | string | ¹ | | Exact identifier of the application in the store, see below. Specifying it improves performance and reliability drastically. |
| `Filter` | script block | ¹ | | Script block that returns `$true` for matching applications. The current application is available as `$_` / `$PSItem`. No other variables or commands are allowed. Example: `{ $_.DisplayName -like 'My App*' -and $_.Publisher -eq 'Vendor' }` |

¹ At least one of `Identifier` and `Filter` is required. If both are set, the application must match both.

| `Store` | Searches | `Identifier` format |
|:--------|:---------|:--------------------|
| `ARP` | 64-bit and 32-bit Add/Remove Programs entries, excluding entries of neo42 packages | Uninstall key name, e.g. MSI product code `{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}` |
| `ARP64` | 64-bit Add/Remove Programs entries only | as `ARP` |
| `ARP32` | 32-bit Add/Remove Programs entries only | as `ARP` |
| `AppX` | Installed AppX/MSIX packages | `PackageFamilyName` |
| `Package` | Add/Remove Programs entries of neo42 packages only | Package `GUID` in "B" format, e.g. `{042XXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}` |

### Requirements

Parent: `/Requirements/` – optional list.

Requirements are resolved at the start of an installation, after the hook `CustomInstallAndReinstallAndSoftMigrationBegin`.

| Value | Type | Req. | Default | Description |
|:------|:-----|:----:|:--------|:------------|
| `Criteria` | [criteria](#application-criteria) | **R** | | The application to check. Multiple matches are allowed. |
| `DesiredState` | enum | | `Present` | `Present`: the application must be installed. `Absent`: the application must not be installed. |
| `OnConflict` | enum | | `Fail` | Action if the desired state is not met, see below. |
| `ErrorMessage` | string | | generic message | Message logged if the desired state is not met. |

| `OnConflict` | Action |
|:-------------|:-------|
| `Fail` | Stop the deployment with exit code `69002` and log `ErrorMessage`. |
| `Warn` | Continue and log `ErrorMessage` as warning. |
| `Continue` | Continue and log `ErrorMessage` as information. |
| `Uninstall` | Uninstall all matching applications and continue. Only valid with `DesiredState = 'Absent'`; with `Present` the deployment fails. |

> [!CAUTION]
> `Uninstall` can lead to unwanted reinstallations by the deployment system if the removed application is still assigned to the device.

### Detection

Parent: `/Detection/`

Detects the main application that the package manages. Detection decides between installation, [reinstallation and upgrade](#reinstall-and-upgrade-mode), skips the uninstallation if the application is not installed and verifies the result of every deployment.

| Value | Type | Req. | Default | Description |
|:------|:-----|:----:|:--------|:------------|
| `Enabled` | bool | | `$false` | `$true`: the detection result is evaluated during the deployment. `$false`: the default installation and uninstallation always run and no result verification takes place. |
| `Version` | string | | | Expected version of the installed application, compared with its `DisplayVersion`. Does not need to be a strict version. |
| `UsePackageVersion` | bool | | `$false` | Use `Package.Version` as expected version. Takes precedence over `Version`. |
| `Hide` | bool | | `$true` | Hide the detected application in Add/Remove Programs after the installation. Only applies to `ARP*` stores. |
| `Criteria` | [criteria](#application-criteria) | | | The application to detect. Must match **at most one** application, otherwise the deployment fails. If omitted while `Enabled` is `$true`, detection must be implemented in a hook by setting `$adtSession.NXT.Detection.IsInstalled`. |

> [!NOTE]
> Set either `Version` or `UsePackageVersion`. Without an expected version, any installed version is considered equal, so upgrades cannot be detected and soft migration by detection cannot compare versions.

After an installation, the application must be detected in the expected version. After an uninstallation, the application must no longer be detected. Otherwise, the deployment fails.

### SoftMigration

Parent: `/SoftMigration/`

Soft migration takes ownership of an application that is already installed in the desired state. The package is registered without running the installation.

| Value | Type | Req. | Default | Description |
|:------|:-----|:----:|:--------|:------------|
| `Enabled` | bool | | `$false` | Enables soft migration for this package. |
| `Mode` | enum | | `Detection` | How the existing application is checked, see below. |
| `Target` | string | | | File path for mode `File`. |
| `Version` | string | | | Minimum version that must be found. Does not need to be a strict version. For mode `Detection` it defaults to the expected version of [Detection](#detection). |
| `UsePackageVersion` | bool | | `$false` | Use `Package.Version` as minimum version. Takes precedence over `Version`. |

| `Mode` | Check |
|:-------|:------|
| `Detection` | The application of [Detection](#detection) is installed with a `DisplayVersion` equal to or higher than `Version`. Requires `Detection.Enabled`. |
| `File` | The file `Target` exists. If `Version` is set, its file version must be equal or higher. |
| `Custom` | The result must be set in the hook `CustomSoftMigrationBegin` with `$adtSession.NXT.SoftMigration.Result = $true`. |

A soft migration is only considered if all of the following apply:

- `Enabled` is `$true` and `SOFTMIGRATION=1` is set in the `Options` section of the `Setup.cfg`.
- The deployment is an installation (not a repair) and no process has been run yet.
- No registered package with the same `GUID` and an equal or higher version exists.

If the hook `CustomSoftMigrationBegin` sets `$adtSession.NXT.SoftMigration.Result`, that value is used in any mode. After a successful soft migration, the hooks `CustomSoftMigrationEnd` and `CustomInstallAndReinstallAndSoftMigrationEnd` run. `Installation.Reboot = 'Always'` is lowered to `IfRequired`.

### CloseProcesses

Parent: `/CloseProcesses/` – optional list.

Processes that must be closed before the installation or uninstallation can proceed. Depending on the `Setup.cfg`, they are closed automatically or the user is prompted to close them.

| Value | Type | Req. | Default | Description |
|:------|:-----|:----:|:--------|:------------|
| `Name` | string | **R** | | Process name (with or without `.exe`) or full path of the executable. Must be a valid path. |
| `Description` | string | | `Name` | Name of the application shown to the user in the close prompt. |
| `AllowBlocking` | bool | | `$true` | `$true`: the process is blocked from starting during the deployment if blocking is enabled in the toolkit configuration (`NXT.Toolkit.BlockExecution`). `$false`: the process is only closed. |
| `ReopenMode` | enum | | `None` | How the process is reopened after the deployment if it was running: `None`, `Binary` (original executable only), `Commandline` (original command line). May be disabled by the `Setup.cfg`. |

### ManagedShortcuts

Parent: `/ManagedShortcuts/` – optional list.

Shortcuts in the public desktop or public start menu that are managed by the package.

| Value | Type | Req. | Default | Description |
|:------|:-----|:----:|:--------|:------------|
| `Mode` | enum | | `Delete` | `Create`: create a new shortcut pointing to `Source`. `Copy`: copy the existing shortcut `Source`. `Delete`: delete the shortcut, e.g. one created by the setup. |
| `Location` | enum | | `Desktop` | `Desktop` (public desktop) or `StartMenu` (public start menu). |
| `Target` | string | **R** | | File name of the shortcut in `Location`, e.g. `'My App.lnk'`. Must be a valid file name; sub folders are not supported. |
| `Source` | string | | | `Create`: path of the file the shortcut points to. `Copy`: path of the shortcut to copy, either rooted or relative to the public start menu, e.g. `'Programs\Vendor\My App.lnk'`. |

Shortcuts are processed at the end of the deployment:

- Installation with `DESKTOPSHORTCUT=1` in the `Options` section of the `Setup.cfg`: `Create` and `Copy` are applied, `Delete` shortcuts are removed.
- Installation without `DESKTOPSHORTCUT=1`: **all** managed shortcuts are removed.
- Uninstallation: **all** managed shortcuts are removed.

### ManagedApplications

Parent: `/ManagedApplications/` – optional list of [application criteria](#application-criteria).

Additional applications that belong to the main application, e.g. components installed by the same setup. All matching applications in `ARP*` stores are hidden in Add/Remove Programs after the installation. Before an installation or uninstallation they are unhidden.

### Deployment

Parent: `/Deployment/`

| Value | Type | Req. | Default | Description |
|:------|:-----|:----:|:--------|:------------|
| `InstallLocation` | string | | | Installation directory of the main application. Must be a rooted path. Used as fallback to determine the application size and available as `%InstallLocation%` and `$adtSession.NXT.InstallLocation`. |
| `Installation` | hashtable | | | See [Installation](#installation). |
| `Uninstallation` | hashtable | | | See [Uninstallation](#uninstallation). If omitted, the `Method` of `Installation` is used with default values. |

#### Installation

Parent: `/Deployment/Installation/`

| Value | Type | Req. | Default | Description |
|:------|:-----|:----:|:--------|:------------|
| `Method` | enum | | `$null` | See [deployment methods](#deployment-methods). `$null` skips the default installation; it must be implemented in a hook. |
| `Target` 🔤 | string | | | Method specific target, see [deployment methods](#deployment-methods). Relative paths are resolved against `Files`. |
| `Arguments` 🔤 | string | | | Arguments passed to the installer as one string. Do not add log parameters for methods that add them automatically. |
| `Defaults` | bool | | `$true` | `$true`: `Arguments` are appended to the [default arguments](#default-arguments) of the method. `$false`: only `Arguments` are used. |
| `LogName` | string | | `<Target file name>.<timestamp>_Install.log` | File name of the installation log in the log directory. Must end with `.log`. |
| `SuccessCodes` | integer list | | | Additional exit codes that indicate success. `0` is always included. |
| `RebootCodes` | integer list | | | Additional exit codes that indicate a required reboot. `1641` and `3010` are always included. |
| `IgnoreExitCodes` | bool | | `$false` | Ignore the exit code of the installer. Takes precedence over `SuccessCodes` and `RebootCodes`. |
| `Reboot` | enum | | `IfRequired` | `IfRequired`: return a reboot exit code if the installer requested one. `Always`: always return a reboot exit code. `Never`: never return a reboot exit code. |
| `ReinstallMode` | enum | | `Reinstall` | Behavior if the application is already installed in the expected version. See [reinstall and upgrade mode](#reinstall-and-upgrade-mode). |
| `UpgradeMode` | enum | | `Reinstall` | Behavior if the application is installed in a different version. See [reinstall and upgrade mode](#reinstall-and-upgrade-mode). |
| `AwaitChildren` | bool | | `$false` | Also wait for all child processes of the installer, e.g. for bootstrappers that exit early. Only applies to process based methods. |
| `Awaiters` | hashtable | | | Conditions to wait for after the installer finished. See [Awaiters](#awaiters). |
| `UserPart` | bool | | `$false` | Run the user part after the installation. An Active Setup entry is created for users logging on later; users that are logged on run it immediately. The user part logic is implemented in the hooks `CustomInstallUserPartBegin` / `CustomInstallUserPartEnd`. |

If [Detection](#detection) has `Criteria`, exactly one matching application must be found within 5 seconds after the installer finished, otherwise the installation fails.

#### Uninstallation

Parent: `/Deployment/Uninstallation/`

The values are the same as for [Installation](#installation), except that `ReinstallMode` and `UpgradeMode` do not exist. Differences:

| Value | Description |
|:------|:------------|
| `Target` 🔤 | If empty, the target is taken from the detected application: the product code for `MSI`, the package family for `AppX` and the path of the (quiet) uninstall string for all other methods. |
| `LogName` | Default: `<Target file name>.<timestamp>_Uninstall.log` |
| `UserPart` | Run the user part after the uninstallation (hooks `CustomUninstallUserPartBegin` / `CustomUninstallUserPartEnd`). neo42 recommends not to use this unless necessary, as it leaves remnants on the system. |

If [Detection](#detection) is enabled and the application is not installed, the uninstallation is skipped.

#### Deployment methods

`Method` is the same for installation and uninstallation.

| `Method` | Installation `Target` | Uninstallation `Target` | Notes |
|:---------|:----------------------|:------------------------|:------|
| `Setup` | Executable | Executable | Generic process execution with `Arguments`. |
| `MSI` | `.msi` file | Product code or `.msi` file | Executed by PSADT's MSI handling. Supports `ReinstallMode = 'Repair'`. |
| `InnoSetup` | Setup executable | Uninstaller, e.g. `unins000.exe` | `/LOG` is added automatically. |
| `Nullsoft` | Setup executable | Uninstaller | Waits up to 10 minutes for the uninstaller helper processes. |
| `BitRockInstaller` | Setup executable | Uninstaller | Waits up to 10 minutes for the uninstaller helper processes. |
| `Burn` | Bundle executable | Bundle executable | `/install` or `/uninstall` and `/log` are added automatically. |
| `AppX` | `.appx`, `.appxbundle`, `.msix` or `.msixbundle` file | Package full name or package family name | Installed as provisioned package with DISM. The uninstallation removes the provisioned package and the package for all users. |
| `Copy` | Destination directory | Destination directory | Copies the whole content of `Files` to the destination. The uninstallation removes the destination directory. `Arguments` are ignored. |

For `InnoSetup`, `Nullsoft` and `BitRockInstaller` the uninstaller files of the detected application are backed up into the package cache after the installation. If the original uninstaller is missing during an uninstallation, the backup is restored. This requires [Detection](#detection) with `Criteria`.

#### Default arguments

If `Defaults` is `$true`, the default arguments of the method are used in front of `Arguments`. They are part of the toolkit configuration `config.psd1` and can be overridden through the [layered configuration](./PSAppDeployToolkit.Neo42.Extensions.Changelog.md#configurability--extensability). `InstallParams` is used for interactive and `SilentParams` for silent deployments.

| Method | Config path | Installation | Uninstallation |
|:-------|:------------|:-------------|:---------------|
| `MSI` | `MSI.*` (PSADT) | `MSIRESTARTMANAGERCONTROL=Disable REBOOT=ReallySuppress ALLUSERS=1 /qn` | `MSIRESTARTMANAGERCONTROL=Disable REBOOT=ReallySuppress ALLUSERS=1 /qn` |
| `InnoSetup` | `NXT.Deployment.InnoSetup.*` | `/FORCEINSTALL /VERYSILENT /SP- /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /RESTARTEXITCODE=3010 /ALLUSERS` | `/VERYSILENT /SP- /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /RESTARTEXITCODE=3010` |
| `Nullsoft` | `NXT.Deployment.Nullsoft.*` | `/AllUsers /S` | `/AllUsers /S` |
| `BitRockInstaller` | `NXT.Deployment.BitRockInstaller.*` | `--mode unattended` | `--mode unattended` |
| `Burn` | `NXT.Deployment.Burn.*` | `/quiet MSIRESTARTMANAGERCONTROL=Disable REBOOT=ReallySuppress ALLUSERS=1` | `/quiet MSIRESTARTMANAGERCONTROL=Disable REBOOT=ReallySuppress ALLUSERS=1` |
| `AppX` | `NXT.Deployment.AppX.*` | `/Region:all /SkipLicense` | – |
| `Setup`, `Copy` | – | – | – |

> [!NOTE]
> Arguments that a method requires to work (e.g. the log parameter of `InnoSetup` and `Burn` or the DISM arguments of `AppX`) are always added, even if `Defaults` is `$false`.

#### Reinstall and upgrade mode

If [Detection](#detection) is enabled and the application is installed, the installation behaves as follows:

| Installed version | Setting | Value | Action |
|:------------------|:--------|:------|:-------|
| Equal to the expected version | `ReinstallMode` | `None` | Nothing is done. |
| | | `Install` | Installation over the existing application. The setup must support this. |
| | | `Repair` | MSI repair. Other methods log an error and fall back to `Install`. |
| | | `Reinstall` | Uninstallation followed by an installation. |
| Different from the expected version | `UpgradeMode` | `None` | Nothing is done. |
| | | `Install` | Installation over the existing application (in-place upgrade). |
| | | `Reinstall` | Uninstallation followed by an installation. |

The hooks `CustomReinstall*` run in this case instead of `CustomInstallBegin` / `CustomInstallEnd`. If the application is not installed or detection is disabled, a regular installation is performed.

#### Awaiters

Parent: `/Deployment/Installation/Awaiters/` and `/Deployment/Uninstallation/Awaiters/`

Conditions that are awaited after the installer or uninstaller has finished, e.g. for setups that continue in the background. All conditions are awaited in parallel; each timeout counts from the start of the wait. If a condition is not met in time, a warning is logged and the deployment continues.

| Value | Type | Req. | Default | Description |
|:------|:-----|:----:|:--------|:------------|
| `DefaultTimeout` | time span | | `00:00:30` | Timeout for each condition without its own `Timeout`. |
| `RegistryKeys` | list | | | Registry conditions, see below. |
| `Processes` | list | | | Process conditions, see below. |

**`RegistryKeys`** items:

| Value | Type | Req. | Default | Description |
|:------|:-----|:----:|:--------|:------------|
| `Key` | string | **R** | | Rooted registry key path, e.g. `'HKLM:\SOFTWARE\Vendor\App'`. |
| `Name` | string | | | Value name below `Key`. If empty, only the key is checked. |
| `Value` | string | | | Expected value data. If empty, only the existence is checked. |
| `Exists` | bool | | `$true` | `$true`: wait until the key/value exists. `$false`: wait until it is removed. |
| `Timeout` | time span | | `DefaultTimeout` | Timeout for this condition. |

**`Processes`** items:

| Value | Type | Req. | Default | Description |
|:------|:-----|:----:|:--------|:------------|
| `Name` | string | **R** | | Process name to monitor. |
| `Exists` | bool | | `$true` | `$true`: wait until the process runs. `$false`: wait until it has exited. |
| `Timeout` | time span | | `DefaultTimeout` | Timeout for this condition. |

### Variables

Parent: `/Variables/` – optional hashtable.

Package specific variables for use in hooks. Values can be any data type, including arrays and hashtables. [Meta variables](#meta-variables) are resolved in all string values.

```PowerShell
Variables = @{
	MyVarStatic  = 'Literal value with a $ sign'
	MyVarDynamic = "$envProgramFiles\MyApp"
	MyMetaPath   = '%DirSupportFiles%\settings.xml'
	MyExpression = if ($envArchitecture.Contains('64')) { 'Value1' } else { 'Value2' }
	MyVarArray   = @('Item1', 'Item2', 'Item3')
	MyVarDict    = @{
		Key1 = 'Value1'
		Key2 = 'Value2'
	}
}
```

Access the variables in the deployment script with **`$adtSession.NXT.Variables.<Name>`** (not case-sensitive), e.g. `$adtSession.NXT.Variables.MyVarDynamic`.
