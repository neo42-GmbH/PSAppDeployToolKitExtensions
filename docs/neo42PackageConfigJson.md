# neo42PackageConfig.json – Legacy Package Configuration Reference

This document describes every value of the legacy `neo42PackageConfig.json` and what happens to it in V4.

> [!WARNING]
> The JSON format is **legacy**. It is still loaded, but it is translated into the new `neo42PackageConfig.psd1` model at runtime and will be deprecated in a future release. New features (e.g. the `Appx`, `Copy` and `Burn` deployment methods, start menu shortcut management, awaiter timeouts per item) are only available in the PSD1 format. See the [changelog](../docs/PSAppDeployToolkit.Neo42.Extensions.Changelog.md) for details.

**Legend**

| Badge | Meaning |
|:-----:|:--------|
| ✅ | Value is translated into the new configuration model |
| 🔁 | Value is translated, but its behavior changed |
| 📦 | Value is no longer used by logic, but is preserved as `Legacy_*` variable |
| ❌ | Value has no effect anymore |
| 🛑 | Value causes the configuration to be rejected |

## Table of contents

- [neo42PackageConfig.json – Legacy Package Configuration Reference](#neo42packageconfigjson--legacy-package-configuration-reference)
	- [Table of contents](#table-of-contents)
	- [How a legacy file is processed](#how-a-legacy-file-is-processed)
	- [Good to know](#good-to-know)
	- [Variables available in expandable values](#variables-available-in-expandable-values)
		- [Architecture dependent variables](#architecture-dependent-variables)
		- [Values that are expanded](#values-that-are-expanded)
	- [Migration overview](#migration-overview)
	- [Value reference](#value-reference)
		- [General package information](#general-package-information)
		- [Install / uninstall / reinstall](#install--uninstall--reinstall)
			- [Deployment methods](#deployment-methods)
			- [Reinstall mode](#reinstall-mode)
		- [Setup success checks (awaiters)](#setup-success-checks-awaiters)
		- [Application detection](#application-detection)
		- [Soft migration](#soft-migration)
		- [Dependent packages](#dependent-packages)
		- [Processes to close](#processes-to-close)
		- [Shortcuts](#shortcuts)
		- [Hiding uninstall entries](#hiding-uninstall-entries)
		- [Package specific variables](#package-specific-variables)
	- [Compatibility variables](#compatibility-variables)
	- [Removed values](#removed-values)

---

## How a legacy file is processed

1. The JSON file is read. `ConfigVersion` must be **`2024.09.19.1` or newer**, otherwise loading fails with a `NotSupportedException`.
2. All [expandable values](#variables-available-in-expandable-values) are expanded.
3. The result is validated (required values, GUID/version/date formats, valid file names, allowed enum values).
4. The legacy model is translated into the new configuration model (`ConfigVersion` `2025.12.1.0`).
   Anything that cannot be translated is either kept as a `Legacy_*` variable or causes an error (see [Migration overview](#migration-overview)).

> [!NOTE]
> Keep **all** values from the template, even if they are optional. The loader does not guarantee that omitted values fall back to the defaults documented below. The sample [neo42PackageConfig.empty.legacy.json](../samples/neo42PackageConfig.empty.legacy.json) can be used as a starting point, [neo42PackageConfig.PackageConfigEditor.legacy.json](../samples/neo42PackageConfig.PackageConfigEditor.legacy.json) shows a filled example.

## Good to know

*Backtick is the general masking character for later usage of control characters inside PowerShell, but consider the following masking rules for characters in JSON files in general:*

| Character | Mask with | Looks like | Comment |
|:---------:|:---------:|:----------:|:--------|
| `"` | backtick | ``` `" ``` | necessary for expandable variable content in PowerShell |
| `$` | backtick | ``` `$ ``` | necessary for expandable variable content in PowerShell |
| `\` | backslash | `\\` | necessary inside the JSON file itself |

## Variables available in expandable values

Values marked with 🔤 in the reference may contain PowerShell variables (e.g. `$($global:PackageConfig.AppVendor)`), which are expanded while the file is loaded. Expansion runs in a **restricted session**; only the variables below exist.

| Variable | Content |
|:---------|:--------|
| All PSADT environment variables (e.g. `$envProgramData`, `$envWinDir`) | Provided by the PSADT session environment. Accessible with and without the `$global:` prefix. |
| `$SetupCfg` (also `$global:SetupCfg`) | The merged, **read-only** `Setup.cfg` settings (module default, `Setup.cfg` and `CustomSetup.cfg` of the package). Read a value with `$($SetupCfg['<Section>']['<KEY>'])`, e.g. `$($SetupCfg['Options']['SOFTMIGRATION'])`. This allows dynamic values depending on the customer configuration. |
| `$global:PackageConfig` | The legacy configuration itself (e.g. `$global:PackageConfig.AppVendor`). Values that are expanded later in the sequence see the already expanded values of earlier ones. |
| `$global:ProgramFilesDir`, `ProgramFilesDirx86`, `ProgramW6432`, `CommonFilesDir`, `CommonFilesDirx86`, `CommonProgramW6432`, `RegSoftwarePath`, `RegSoftwarePathx86`, `System` | Architecture dependent, see [below](#architecture-dependent-variables). **Recommended to use inside defined values first!** |
| `$global:UserPartDir` | Always empty. |
| `$global:AppLogFolder`, `InstLogFile`, `UninstLogFile`, `DirFiles`, `DirSupportFiles` | Placeholders (`%LogFolder%`, `%InstLogFile%`, `%UninstLogFile%`, `%DirFiles%`, `%DirSupportFiles%`) that are resolved later at runtime. |

### Architecture dependent variables

The variables depend on `AppArch`. `x86` and `arm` use the 32-bit mapping; `x64`, `arm64` and `*` use the 64-bit mapping.

| Variable | 32-bit app (`x86`, `arm`) | 64-bit / neutral app (`x64`, `arm64`, `*`) |
|:---------|:--------------------------|:-------------------------------------------|
| *filesystem* | | |
| `$global:ProgramFilesDir` | `$envProgramFilesW3264` | `$envProgramFiles` |
| `$global:ProgramFilesDirx86` | `$envProgramFilesW3264` | `$envProgramFilesW3264` |
| `$global:ProgramW6432` | `$envProgramFiles` | `$envProgramFiles` |
| `$global:CommonFilesDir` | `$envCommonProgramFilesW3264` | `$envCommonProgramFiles` |
| `$global:CommonFilesDirx86` | `$envCommonProgramFilesW3264` | `$envCommonProgramFilesW3264` |
| `$global:CommonProgramW6432` | `$envCommonProgramFiles` | `$envCommonProgramFiles` |
| `$global:System` | `$envSystemX86` (`C:\Windows\SysWOW64`) | `$envSystemX64` (`C:\Windows\System32`) |
| *registry* | | |
| `$global:RegSoftwarePath` | `$envRegistrySoftwareW3264` | `$envRegistrySoftware` |
| `$global:RegSoftwarePathx86` | `$envRegistrySoftwareW3264` | `$envRegistrySoftwareW3264` |

> [!NOTE]
> The architecture specific *environment* variables of V3 (e.g. `$envProgramFilesX86`) were removed from the deployment script. See the breaking changes in the changelog.

### Values that are expanded

Only the following values are expanded (each list entry of a collection is expanded individually). Other values are taken literally.

- `UninstallDisplayName`
- `InstallLocation`
- `InstLogFile`, `UninstLogFile`
- `InstFile`, `InstPara`
- `UninstFile`, `UninstPara`
- `UninstallKey` (only if `UninstallKeyContainsExpandVariables` is `true`)
- `DisplayNamesToExcludeFromAppSearches`
- `SoftMigration.File.FullNameToCheck`, `SoftMigration.File.VersionToCheck`
- `CommonDesktopShortcutsToDelete`
- `CommonStartMenuShortcutsToCopyToCommonDesktop.Source`, `.TargetName`
- `UninstallKeysToHide.KeyName`, `.KeyNameIsDisplayName`, `.KeyNameContainsWildCards`, `.DisplayNamesToExcludeFromHiding`
- `PackageSpecificVariablesRaw.Value` (only if `ExpandVariables` is `true`)

`App` is **not** expanded anymore; it is replaced by a fixed placeholder (`%PackageDirectory%`) so that self-referencing variables do not fail.

---

## Migration overview

| JSON value | New model target | Status |
|:-----------|:-----------------|:------:|
| `ConfigVersion` | – (must be ≥ `2024.09.19.1`) | 🛑 if too old; 📦 `Legacy_ConfigVersion` |
| `ScriptAuthor` | `Package.Author` | ✅ |
| `ScriptDate` | `Package.CreationDate` | 🔁 |
| `InventoryID` | `Package.InventoryId` | ✅ 📦 |
| `Description` | `Package.Description` | ✅ 📦 |
| `InstallMethod` / `UninstallMethod` | `Deployment.Installation/Uninstallation.Method` | 🔁 |
| `ReinstallMode` | `Installation.ReinstallMode` + `Installation.UpgradeMode` | 🔁 |
| `MSIInplaceUpgradeable` | `Installation.UpgradeMode` (only with `MSIRepair`) | 🔁 |
| `MSIDowngradeable` | – | ❌ |
| `SoftMigration` | `SoftMigration` | 🔁 |
| `TestedOn` / `Dependencies` | `Package.TestedOn` / `Package.Dependencies` | ✅ 📦 |
| `LastChange` | `Package.UpdateDate` | 🔁 |
| `Build` / `AppRevision` | `Package.Build` / `Package.Revision` | ✅ |
| `AppArch` | `Package.Architecture` | 🔁 |
| `AppVendor` / `AppName` / `AppVersion` / `AppLang` | `Package.Vendor` / `Name` / `Version` / `Language` | ✅ |
| `PackageGUID` | `Package.GUID` | ✅ |
| `ProductGUID` | – | 📦 `Legacy_ProductGUID` |
| `RemovePackagesWithSameProductGUID` | – | 📦 `Legacy_RemovePackagesWithSameProductGUID` |
| `DependentPackages` | `Requirements` | ✅ |
| `RegPackagesKey` | `Package.KeyName` | ✅ |
| `UninstallDisplayName` | `Package.DisplayName` | 🔁 |
| `AppRootFolder` | `Package.DirectoryName` | ✅ |
| `App` | – | ❌ |
| `UninstallOld` | `Package.UninstallOld` | ✅ |
| `Reboot` | `Installation/Uninstallation.Reboot` | ✅ |
| `UserPartOnInstallation` / `UserPartOnUninstallation` | `Installation/Uninstallation.UserPart` | ✅ |
| `UserPartRevision` | – (calculated from `AppVersion`) | ❌ |
| `HidePackageUninstallButton` / `HidePackageUninstallEntry` | `Package.ApplicationEntry` | 🔁 📦 |
| `DisplayVersion` | `Detection.Version` / `SoftMigration.Version` | 🔁 |
| `InstallerVersion` | – | 📦 `Legacy_InstallerVersion` |
| `UninstallKey*` / `DisplayNamesToExcludeFromAppSearches` | `Detection.Criteria` | 🔁 📦 |
| `InstallLocation` | `Deployment.InstallLocation` | ✅ |
| `InstLogFile` / `UninstLogFile` | `LogName` | 🔁 |
| `InstFile` / `UninstFile` | `Target` | ✅ |
| `InstPara` / `UninstPara` | `Arguments` | ✅ |
| `AppendInstParaToDefaultParameters` / `AppendUninstParaToDefaultParameters` | `Defaults` | 🔁 |
| `Accepted*ExitCodes` / `Accepted*RebootCodes` | `SuccessCodes` / `IgnoreExitCodes` / `RebootCodes` | 🔁 |
| `AppKillProcesses` | `CloseProcesses` | 🔁 |
| `AppKillProcesses.IsWQL` | – | 🛑 if `true` |
| `BlockExecution` | `CloseProcesses.AllowBlocking` (per process) | ✅ |
| `TestConditionsPreSetupSuccessCheck` | `Awaiters` | 🔁 |
| `CommonDesktopShortcutsToDelete` | `ManagedShortcuts` (`Delete`) | ✅ |
| `CommonStartMenuShortcutsToCopyToCommonDesktop` | `ManagedShortcuts` (`Copy`) | ✅ |
| `UninstallKeysToHide` | `ManagedApplications` / `Detection.Hide` | 🔁 see [Hiding uninstall entries](#hiding-uninstall-entries) |
| `PackageSpecificVariablesRaw` | `Variables` | ✅ |

---

## Value reference

Each table lists the **parent** of a value in its heading. *Required* refers to the legacy format; values marked **(R)** are required by validation **or** are parsed during translation, so an empty value will make loading fail.

### General package information

Parent: `/`

| Value | Type | Req. | Expand | Description |
|:------|:-----|:----:|:------:|:------------|
| `ConfigVersion` | string | **R** | | Version of the legacy configuration format. Must be `2024.09.19.1` or newer. Kept as `Legacy_ConfigVersion`. |
| `ScriptAuthor` | string | | | Author of the script. |
| `ScriptDate` | string | **R** | | Date of script creation in format `DD/MM/YYYY`. Translated to `yyyy-MM-dd`. |
| `InventoryID` | string | | | Internal unique identifier with 11 digits: 3 digits employee abbreviation + 8 digit random hexadecimal number, or – if automatically generated – an `n` followed by 13 decimal numbers. |
| `Description` | string | | | Free text description of the package. |
| `TestedOn` | string | | | Comma separated list of tested platforms, e.g. `Win10 x86, Win10 x64, Win11 x64`. |
| `Dependencies` | string | | | Comma separated list of depending applications, Windows features or services. Usually these should also be pre-checked in a custom function (e.g. `CustomInstallAndReinstallAndSoftMigrationBegin`). |
| `LastChange` | string | **R** | | Date of last script change in format `DD/MM/YYYY`. Translated to `yyyy-MM-dd`. |
| `Build` | string | **R** | | Numeric build number starting with `0` for each revision. Increment if the script changes **and** the package should not be triggered on all clients. |
| `AppRevision` | string | **R** | | Numeric revision starting with `0`. Increment if the script/package content changes **and** the package must be re-distributed (possibly reset `Build` to `0`). |
| `AppArch` | string | **R** | | Architecture of the packaged application: `x86`, `x64`, `*` – the new model also knows `arm` and `arm64`. `*` is used if the behavior differs between platforms or the package contains both architectures and is translated to `neutral`. Unknown values are translated to `neutral` as well. |
| `AppVendor` | string | **R** | | Manufacturer of the application. Must be a valid file name and must **not** contain corporate forms like `GmbH` or `Ltd.`. |
| `AppName` | string | **R** | | Name of the application. Must be a valid file name and must **not** contain version numbers, except branding versions like `Office 2019`. |
| `AppVersion` | string | **R** | | Real version of the application (as noted in the registry uninstall entry, if set there), in format `aaa.bbb.ccc.ddd`. **Not** a branding number. |
| `AppLang` | string | | | Application language: `DEU`, `ENU` or `MUI`. Empty values are translated to `MUI`. |
| `PackageGUID` | string | **R** | | GUID of the application series in format `{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}`; the first 3 digits are always `042`. May only be used once per application series and directly affects the update behavior. |
| `RegPackagesKey` | string | | | Registry sub key below `HKLM:\Software` where package information is stored. Template default: `neoPackages`. |
| `UninstallDisplayName` | string | | 🔤 | Display name of the package's own uninstall registry entry. Template default: `neoPackage $($global:PackageConfig.AppVendor) $($global:PackageConfig.AppName) $($global:PackageConfig.AppVersion)`. 🔁 A trailing `AppVersion` is cut off when translated to `Package.DisplayName`. |
| `AppRootFolder` | string | | | Base name of the package cache folder below `ProgramData`. Template default: `neo42Pkgs`. 🔁 The cache is forced into the secured package directory. |
| `UninstallOld` | bool | | | Remove packages of former framework versions (especially Empirum `setup.inf` packages) and/or with the same package family GUID (especially VBS style packages). |
| `HidePackageUninstallButton` | bool | | | Hide the uninstall button of the package in the system settings. 🔁 Translates to `ApplicationEntry = DisplayOnly`. |
| `HidePackageUninstallEntry` | bool | | | Hide the package's uninstall registry entry completely. 🔁 Translates to `ApplicationEntry = Hidden` and takes precedence over `HidePackageUninstallButton`. Neither set: `Uninstallable`. |
| `Reboot` | integer | | | Reboot behavior: `0` = `IfRequired` (no reboot forced, exit code untouched), `1` = `Always` (exit code becomes `3010`), `2` = `Never` (`1641`/`3010` become `0`). An explicit `-SuppressRebootPassThru` ignores this on script exit. |
| `UserPartOnInstallation` | bool | | | Install the user part during the main installation. Should be `true` if the package contains a user part. Can also be called explicitly with `-InstallUserPart` / `-TriggerInstallUserPart`. |
| `UserPartOnUninstallation` | bool | | | Uninstall the user part during the main uninstallation. Should normally stay `false`. Can also be called explicitly with `-UninstallUserPart` / `-TriggerUninstallUserPart`. |
| `DisplayVersion` | string | | | Expected `DisplayVersion` of the installed application as set by a regular test installation. Used for [detection](#application-detection) and [soft migration](#soft-migration). |
| `InstallLocation` | string | | 🔤 | Installation path of the application. Must be a rooted path or empty. Not used by default logic, but available for setup parameters or custom functions. |

> [!NOTE]
> The user part revision (`UserPartRevision`) is now calculated from `AppVersion` and must no longer be set. See [Removed values](#removed-values).

### Install / uninstall / reinstall

Parent: `/`

| Value | Type | Req. | Expand | Description |
|:------|:-----|:----:|:------:|:------------|
| `InstallMethod` | string | **R** | | Method used for the default installation. See [methods](#deployment-methods). |
| `UninstallMethod` | string | **R** | | Method used for the default uninstallation. See [methods](#deployment-methods). |
| `ReinstallMode` | string | **R** | | `MSIRepair`, `Reinstall` or `Install`. See [reinstall mode](#reinstall-mode). |
| `MSIInplaceUpgradeable` | bool | | | Only set if an in-place upgrade is safe for this MSI. Influences the upgrade mode for `MSIRepair`. |
| `MSIDowngradeable` | bool | | | ❌ Not translated and has no effect anymore. |
| `InstFile` | string | | 🔤 | Setup installer file name including extension. Expected in `Files`, otherwise add a relative path. Ignored if `InstallMethod` is `none`. |
| `InstPara` | string | | 🔤 | Setup installer parameters as one string. Do **not** include a log file parameter for well-known setup types. Mind the [masking rules](#good-to-know). |
| `AppendInstParaToDefaultParameters` | bool | | | `true` appends `InstPara` to the default parameters of the method; `false` replaces them. 🔁 `Defaults` is also `true` if `InstPara` is empty. A log file parameter is always appended if supported by the setup type. |
| `InstLogFile` | string | | 🔤 | Log file of the installation. Template default: `$($global:AppLogFolder)\\Install.$global:DeploymentTimestamp.log`. 🔁 **Only the file name is used**; the folder part is ignored. |
| `AcceptedInstallExitCodes` | string | | | Comma separated exit codes that signal success. `*` accepts all exit codes. 🔁 Defaults to `0` if empty. Entries must be plain integers. |
| `AcceptedInstallRebootCodes` | string | | | Comma separated exit codes that signal a requested reboot. 🔁 Defaults to `1641,3010` if empty. |
| `UninstFile` | string | | 🔤 | Alternative uninstaller file including extension and full path. Used only if the registered uninstall entry (see [detection](#application-detection)) does not exist. Ignored if `UninstallMethod` is `none`. |
| `UninstPara` | string | | 🔤 | Setup uninstaller parameters as one string. Same rules as `InstPara`. |
| `AppendUninstParaToDefaultParameters` | bool | | | Same as `AppendInstParaToDefaultParameters`, for the uninstallation. |
| `UninstLogFile` | string | | 🔤 | Log file of the uninstallation. Template default: `$($global:AppLogFolder)\\Uninstall.$global:DeploymentTimestamp.log`. 🔁 Only the file name is used. |
| `AcceptedUninstallExitCodes` | string | | | Same as `AcceptedInstallExitCodes`, for the uninstallation. |
| `AcceptedUninstallRebootCodes` | string | | | Same as `AcceptedInstallRebootCodes`, for the uninstallation. |

#### Deployment methods

`InstallMethod` and `UninstallMethod` are **not** case-sensitive.

| Value | Translated to | Description |
|:------|:--------------|:------------|
| `MSI` | `MSI` | Default MSI engine execution (`/i` or `/x`). |
| `Inno*` | `InnoSetup` | Any value starting with `Inno`. |
| `NullSoft` | `Nullsoft` | Nullsoft/NSIS setups. |
| `BitRock*` | `BitRockInstaller` | Any value starting with `BitRock`. |
| `Setup` | `Setup` | Regular process execution of `InstFile` / `UninstFile` with the given parameters. Also used for **any other unknown value**. |
| `Copy`, `Burn`, `AppX` | same | Valid enum values, but intended for the PSD1 format. |
| `none` | *skipped* | Skips the default (un)installation. Manual steps in a custom function are required. |

Default parameters are no longer defined in `AppDeployToolkitConfig.xml`. They are part of the toolkit configuration `config.psd1` and can be overridden through the [layered configuration](../docs/PSAppDeployToolkit.Neo42.Extensions.Changelog.md#configurability--extensability):

| Method | Config path | Install | Uninstall |
|:-------|:------------|:--------|:----------|
| MSI | `MSI.InstallParams` / `MSI.SilentParams` / `MSI.UninstallParams` | `MSIRESTARTMANAGERCONTROL=Disable REBOOT=ReallySuppress ALLUSERS=1 /qn` | `MSIRESTARTMANAGERCONTROL=Disable REBOOT=ReallySuppress ALLUSERS=1 /qn` |
| InnoSetup | `NXT.Deployment.InnoSetup.*` | `/FORCEINSTALL /VERYSILENT /SP- /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /RESTARTEXITCODE=3010 /ALLUSERS` | `/VERYSILENT /SP- /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /RESTARTEXITCODE=3010` |
| Nullsoft | `NXT.Deployment.Nullsoft.*` | `/AllUsers /S` | `/AllUsers /S` |
| BitRockInstaller | `NXT.Deployment.BitRockInstaller.*` | `--mode unattended` | `--mode unattended` |

> [!NOTE]
> A log file parameter is always appended if the setup type supports it, even if the parameters are replaced. The accepted exit codes are always passed to the default process execution.

To wait for all child processes of the setup as well (e.g. for bootstrappers that start the actual setup and exit early), use the compatibility variables [`DeploymentInstallationAwaitChildren` and `DeploymentUninstallationAwaitChildren`](#compatibility-variables).

#### Reinstall mode

`ReinstallMode` is split into a reinstall mode and an upgrade mode:

| `ReinstallMode` | New `ReinstallMode` | New `UpgradeMode` | Description |
|:----------------|:--------------------|:------------------|:------------|
| `MSIRepair` | `Repair` | `Install` if `MSIInplaceUpgradeable` is `true`, otherwise `Reinstall` | MSI integrated repair (`/fvomus`). **MSI only** – using it with legacy setups throws a controlled error. |
| `Reinstall` | `Reinstall` | `Reinstall` | Regular uninstallation followed by a regular installation. An intermediate reboot may be required. |
| `Install` | `Install` | `Install` | Regular "over-installation". The setup must support this. The settings of `InstallMethod`/`UninstallMethod` are used as for `Reinstall`. |

The upgrade mode can be overridden with the compatibility variable [`DeploymentInstallationUpgradeMode`](#compatibility-variables).

### Setup success checks (awaiters)

Parent: `/TestConditionsPreSetupSuccessCheck/Install/` and `/TestConditionsPreSetupSuccessCheck/Uninstall/`

`TestConditionsPreSetupSuccessCheck` is an optional structure that controls checks after the default (un)installation has finished. Both sub structures (`Install`, `Uninstall`) are identical; empty lists are allowed. The checks are translated to the `Awaiters` of the installation or uninstallation.

<details>
<summary>Values of <code>Install</code> / <code>Uninstall</code> (click to expand)</summary>

| Value | Type | Req. | Description |
|:------|:-----|:----:|:------------|
| `TotalSecondsToWaitFor` | integer | | Total time in seconds to wait for all items. Default: `30`. 🔁 Becomes the awaiter `DefaultTimeout`. |
| `ProcessOperator` | string | | `And` / `Or`. ❌ Validated, but not translated. |
| `ProcessesToWaitFor` | list | | List of processes to monitor. |
| `RegKeyOperator` | string | | `And` / `Or`. ❌ Validated, but not translated. |
| `RegKeysToWaitFor` | list | | List of registry items to monitor. |

**`ProcessesToWaitFor`** → `Awaiters.Processes`

| Value | Type | Req. | Description |
|:------|:-----|:----:|:------------|
| `Name` | string | ✔ | Process file name (with or without extension). Wildcards are allowed, but a wildcard alone is prevented. |
| `ShouldExist` | bool | ✔ | `true` if the process is expected to exist. |

**`RegKeysToWaitFor`** → `Awaiters.RegistryKeys`

| Value | Type | Req. | Description |
|:------|:-----|:----:|:------------|
| `KeyPath` | string | ✔ | Registry path of the key to monitor. |
| `ValueName` | string | | Value name below `KeyPath`. |
| `ValueData` | string | | Expected value data; compared for exact equality. |
| `ShouldExist` | bool | ✔ | `true` if the key/value is expected to exist. |

</details>

### Application detection

Parent: `/`

There is no dedicated detection structure in the legacy format. Detection is derived from the following values and translated into `Detection`:

| Value | Type | Req. | Expand | Description |
|:------|:-----|:----:|:------:|:------------|
| `UninstallKey` | string | | 🔤 ¹ | Name of the uninstall registry subkey of the installed application (`...\CurrentVersion\Uninstall\<UninstallKey>`); for MSI generally the product code. If the key is only known at runtime this may be the **display name** (then set `UninstallKeyIsDisplayName`). May be empty, in which case detection is disabled and custom functions must handle it. |
| `UninstallKeyIsDisplayName` | bool | | | `UninstallKey` is the `DisplayName` of the uninstall entry. Mandatory in that case. |
| `UninstallKeyContainsWildCards` | bool | | | `*` in `UninstallKey` is a wildcard (`true`) or a literal character (`false`). |
| `UninstallKeyContainsExpandVariables` | bool | | | Variables in `UninstallKey` are expanded (`true`) or kept literally (`false`). |
| `DisplayNamesToExcludeFromAppSearches` | string list | | 🔤 | Display names to exclude from application searches. At least the package's own `UninstallDisplayName` is recommended to prevent finding the package entry itself. Template default: `$($global:PackageConfig.UninstallDisplayName)`. |
| `DisplayVersion` | string | | | Expected version of the installed application. |

¹ only if `UninstallKeyContainsExpandVariables` is `true`.

**Translation** – the legacy values are replaced by a detection with the `ARP` store:

| Legacy values | Resulting criteria |
|:--------------|:-------------------|
| `UninstallKey` is empty | Detection disabled |
| Neither display name nor wildcards | `Identifier = UninstallKey` |
| Display name | Filter `$_.DisplayName -eq '<key>'` (`-like` with wildcards) |
| Wildcards, no display name | Filter `$_.PSChildName -like '<key>'` |
| `DisplayNamesToExcludeFromAppSearches` set | Added to the filter: `$_.DisplayName -notin @('<name>', ...)` |

`Detection.Hide` is `true` only if `UninstallKeysToHide` contains a reference to the application itself (see [Hiding uninstall entries](#hiding-uninstall-entries)), otherwise the detected application stays visible.

Everything can be overridden with the [compatibility variables](#compatibility-variables) `DetectionCriteriaStore` and `DetectionCriteriaFilter`. The original values stay available as `Legacy_UninstallKey`, `Legacy_UninstallKeyIsDisplayName`, `Legacy_UninstallKeyContainsWildCards`, `Legacy_UninstallKeyContainsExpandVariables` and `Legacy_DisplayNamesToExcludeFromAppSearches`.

> [!NOTE]
> Without `DisplayVersion` no soft migration by detection is possible, and for MSI setups with `UninstallKeyIsDisplayName` the reinstall mode cannot be double checked.

### Soft migration

Parent: `/SoftMigration/File/`

`SoftMigration` is an optional structure; its sub structure `File` is singular (only one file can be tested).

| Value | Type | Req. | Expand | Description |
|:------|:-----|:----:|:------:|:------------|
| `FullNameToCheck` | string | | 🔤 | Full path of a file to check. If the file exists **and** no `VersionToCheck` is set, a soft migration is done. |
| `VersionToCheck` | string | | 🔤 | File version to check. A soft migration is done if the existing file has the same or a newer version. |

**Translation:**

| Condition | `SoftMigration.Mode` | Target / Version |
|:----------|:---------------------|:-----------------|
| `File.FullNameToCheck` is set | `File` | File path / `VersionToCheck` |
| Else, `DisplayVersion` and (`UninstallKey` or `DetectionCriteriaFilter`) are set | `Detection` | – / `DisplayVersion` |
| Otherwise | disabled | – |

> [!NOTE]
> In V3 a decision sequence existed with the global variable `$global:SoftMigrationCustomResult`. It was replaced by `$adtSession.NXT.SoftMigration.Result`, which can be set in the custom function `CustomSoftMigrationBegin`. Soft migration is only evaluated if enabled in the `Setup.cfg` (`Options.SoftMigration`). The new custom function `CustomSoftmigrationEnd` runs only if the soft migration was applied.

### Dependent packages

Parent: `/DependentPackages/` – optional list, translated to `Requirements`. An empty list (`[]`) is allowed. Copy the item as often as needed (comma separated).

| Value | Type | Req. | Description |
|:------|:-----|:----:|:------------|
| `GUID` | string | ✔ | `PackageGUID` of the package to check. First 3 digits are always `042`. |
| `DesiredState` | string | ✔ | `Present`: package expected to be installed. `Absent`: package expected not to be installed. |
| `OnConflict` | string | ✔ | Action if the state does not match, see below. |
| `ErrorMessage` | string | | Optional message logged with the `Warn` action (and shown for `Fail`). |

| `OnConflict` | Action |
|:-------------|:-------|
| `Fail` | Stop the running package script with a failure; log the optional `ErrorMessage`. |
| `Warn` | Continue and log the optional `ErrorMessage`. |
| `Continue` | Continue and only log the found state. |
| `Uninstall` | Uninstall the dependent package and continue after success. |

> [!CAUTION]
> `Uninstall` can lead to unwanted re-installations by the deployment system if the removed package is still assigned to the client. Any other value than the four above, or for `DesiredState` other than `Present`/`Absent`, makes loading fail.

### Processes to close

Parent: `/AppKillProcesses/` – optional list, translated to `CloseProcesses`. An empty list (`[]`) is allowed.

| Value | Type | Req. | Description |
|:------|:-----|:----:|:------------|
| `Name` | string | ✔ | Process file name (with or without `.exe`) or a full path to the executable. Must be a valid path. |
| `Description` | string | | Text shown in the process close list of the dialog instead of the file description. |
| `IsWQL` | bool | | 🛑 WQL queries are **not supported**. If set to `true` the configuration is rejected with a `NotSupportedException`. Use the PSD1 format, which supports full paths in process names. |

**`BlockExecution`** (parent `/`, bool) controls whether the defined processes are blocked from starting during the (un)installation. It is applied to every entry and translated to `AllowBlocking`. Blocking can additionally be controlled in the toolkit configuration.

> [!NOTE]
> Closed applications can be reopened with the compatibility variable [`CloseProcessesReopen`](#compatibility-variables).

### Shortcuts

Parent: `/`

Public desktop shortcuts are translated to `ManagedShortcuts` with `Location = Desktop`.

| Value | Type | Req. | Expand | Description |
|:------|:-----|:----:|:------:|:------------|
| `CommonDesktopShortcutsToDelete` | string list | | 🔤 | Names of public desktop shortcuts to delete (`Delete`). Always deleted on uninstallation; also deleted on installation if `DESKTOPSHORTCUT=1` is set in the `Setup.cfg`, to clear the desktop for shortcuts created by the setup. Entries that are also a target of a copied shortcut are skipped. |
| `CommonStartMenuShortcutsToCopyToCommonDesktop` | list | | | Shortcuts to copy (`Copy`) from the public start menu to the public desktop. Only copied if `DESKTOPSHORTCUT=1` is set in the `Setup.cfg`. |

**`CommonStartMenuShortcutsToCopyToCommonDesktop`** items:

| Value | Type | Req. | Expand | Description |
|:------|:-----|:----:|:------:|:------------|
| `Source` | string | ✔ | 🔤 | Link file inside the public start menu as a **relative** path, starting with the subfolder `Programs`. |
| `TargetName` | string | | 🔤 | Link file name on the public desktop (necessary only if different from `Source`). Defaults to the file name of `Source`. Must be a valid file name. |

### Hiding uninstall entries

Parent: `/UninstallKeysToHide/` – optional list (copy the item as often as needed) of uninstall entries to hide.

The entries are translated as follows:

| Entry | Translated to |
|:------|:--------------|
| Reference to the application itself: `KeyName` equals `UninstallKey` (not case-sensitive), `KeyNameIsDisplayName` equals `UninstallKeyIsDisplayName` and `KeyNameContainsWildCards` equals `UninstallKeyContainsWildCards` | `Detection.Hide = true`. No managed application is created; the [detection](#application-detection) criteria is hidden instead, so `Is64Bit` and `DisplayNamesToExcludeFromHiding` of this entry have no effect. |
| Any other entry (e.g. components installed alongside the application) | A managed application criteria in `ManagedApplications`. |

> [!NOTE]
> In V3 the default entry was a reference to the currently installed application. Keep this entry if the application should stay hidden; without it `Detection.Hide` is `false` and the application stays visible. Hiding the application requires an enabled detection with an `ARP` store (`ARP`, `ARP32`, `ARP64`), which also applies if the detection is overridden by the [compatibility variables](#compatibility-variables).

| Value | Type | Req. | Expand | Description |
|:------|:-----|:----:|:------:|:------------|
| `KeyName` | string | ✔ | 🔤 | Name of the uninstall registry key to hide. Entries that are empty after expansion are removed. |
| `Is64Bit` | bool | ✔ | | Which registry view is searched: `true` = 64-bit (`ARP64`), `false` = 32-bit (`ARP32`). |
| `KeyNameIsDisplayName` | bool | ✔ | 🔤 | `KeyName` is a `DisplayName`. Must be `true` or `false` after expansion. |
| `KeyNameContainsWildCards` | bool | ✔ | 🔤 | `*` in `KeyName` is a wildcard. Must be `true` or `false` after expansion. |
| `DisplayNamesToExcludeFromHiding` | string list | | 🔤 | Display names to exclude from hiding; `*` is always taken literally. 🔁 Entries with exclusions are translated to a filter instead of an exact identifier. |

### Package specific variables

Parent: `/PackageSpecificVariablesRaw/` – optional list of customer specific variables, translated to `Variables`. An empty list (`[]`) is allowed.

| Value | Type | Req. | Expand | Description |
|:------|:-----|:----:|:------:|:------------|
| `Name` | string | ✔ | | Variable name. |
| `Value` | string | ✔ | 🔤 ² | Variable value (may be empty). Mind the [masking rules](#good-to-know). |
| `ExpandVariables` | bool | | | `true` if variables inside `Value` should be expanded. Omitted equals `false`. |

² only if `ExpandVariables` is `true`.

> [!IMPORTANT]
> In the deployment script the variables are no longer accessible via `$global:PackageConfig.PackageSpecificVariables.<Name>`. Use **`$adtSession.NXT.Variables.<Name>`** (not case-sensitive). The same applies to all `Legacy_*` variables.

Besides your own variables, the following values are stored as variables: `Legacy_ConfigVersion`, `Legacy_InventoryID`, `Legacy_Description`, `Legacy_TestedOn`, `Legacy_Dependencies`, `Legacy_ProductGUID`, `Legacy_RemovePackagesWithSameProductGUID`, `Legacy_HidePackageUninstallButton`, `Legacy_HidePackageUninstallEntry`, `Legacy_InstallerVersion`, `Legacy_UninstallKey`, `Legacy_UninstallKeyIsDisplayName`, `Legacy_UninstallKeyContainsWildCards`, `Legacy_UninstallKeyContainsExpandVariables` and `Legacy_DisplayNamesToExcludeFromAppSearches`.

---

## Compatibility variables

The legacy format cannot express some features of the new model. They can be enabled by adding **package specific variables** with the following reserved names (not case-sensitive, ignored if the value is empty):

```json
"PackageSpecificVariablesRaw": [
	{ "Name": "DetectionCriteriaStore", "Value": "ARP64" },
	{ "Name": "DetectionCriteriaFilter", "Value": "$_.DisplayName -like 'My App*' -and $_.DisplayName -ne 'My App Updater'" },
	{ "Name": "CloseProcessesReopen", "Value": "Binary, None" },
	{ "Name": "DeploymentInstallationUpgradeMode", "Value": "Install" },
	{ "Name": "DeploymentInstallationAwaitChildren", "Value": "true" },
	{ "Name": "DeploymentUninstallationAwaitChildren", "Value": "true" }
]
```

| Variable | Valid values | Effect |
|:---------|:-------------|:-------|
| `DetectionCriteriaStore` | `Package`, `ARP`, `ARP32`, `ARP64`, `AppX` | Enables detection and sets the application store to search. |
| `DetectionCriteriaFilter` | PowerShell filter expression using `$_` | Enables detection and **replaces** the identifier and filter derived from `UninstallKey`. The store defaults to `ARP` unless `DetectionCriteriaStore` is set. Also allows soft migration by detection. |
| `CloseProcessesReopen` | Comma separated list of `None`, `Binary`, `Commandline` | Reopen mode per entry of `AppKillProcesses`. The **number of entries must match** `AppKillProcesses`, otherwise loading fails. |
| `DeploymentInstallationUpgradeMode` | `None`, `Install`, `Reinstall` | Overrides the upgrade mode derived from `ReinstallMode`. |
| `DeploymentInstallationAwaitChildren` | `true`, `false` | Sets `Installation.AwaitChildren`. `true` waits for all child processes of the installer to exit, not only the installer process itself. Default: `false`. |
| `DeploymentUninstallationAwaitChildren` | `true`, `false` | Sets `Uninstallation.AwaitChildren`. Same as `DeploymentInstallationAwaitChildren`, for the uninstallation. With `ReinstallMode` `Reinstall` both are relevant, as an uninstallation runs before the installation. |

Invalid values make loading fail. For `true`/`false` only these two words are accepted (not case-sensitive); `1`, `0` or an unexpanded `$true` are invalid.

> [!NOTE]
> The `*AwaitChildren` variables only affect process based methods (`Setup`, `InnoSetup`, `Nullsoft`, `BitRockInstaller`). They have no effect for `MSI` (including the `MSIRepair` reinstall mode) and `none`.

---

## Removed values

The following values are still accepted for compatibility, but are not used by any logic anymore.

| Value | Reason |
|:------|:-------|
| `App` | Replaced by meta variables. The package cache path is hardcoded. |
| `ProductGUID` | Logic dropped. Available as `Legacy_ProductGUID`. |
| `RemovePackagesWithSameProductGUID` | Logic dropped. Available as `Legacy_RemovePackagesWithSameProductGUID`. |
| `UserPartRevision` | Calculated from `AppVersion`. |
| `InstallerVersion` | Was never tied to logic. Use [package specific variables](#package-specific-variables) instead. Available as `Legacy_InstallerVersion`. |
| `MSIDowngradeable` | Not translated. |
| `IsWQL` (in `AppKillProcesses`) | WQL is not supported (see [Processes to close](#processes-to-close)). |
| `ProcessOperator` / `RegKeyOperator` | Not translated. |
