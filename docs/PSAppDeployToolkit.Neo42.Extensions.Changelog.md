# Changelog V4

## BREAKING CHANGES

- **Files**: The `AppDeployToolkit` folder and its content has been removed or was merged into a new module structure.

- **SetupCfg**: `AskKillProcesses.ALLOWABORTBYUSER` now equates to unlimited deferrals, removing the need for a dedicated abort option.

- **PackageConfig**: The `neo42PackageConfig.json` format is now considered legacy. A new `neo42PackageConfig.psd1` format has been introduced. The legacy format is still supported but will be deprecated in future releases.

- **PackageConfig**: The value `App` has been removed and is not present in the new package config format. The use within the package config has been replaced by meta variables.

- **PackageConfig**: The logic for `ProductGUID` and `RemovePackagesWithSameProductGUID` has been removed and is not present in the new package config format.

- **PackageConfig**: The `AppKillProcesses` value `IsWql` has been dropped due to incompatibility. To mitigate some of the use cases, support for full paths in process names was added.

- **DeployApplication**: Custom functions no longer have parameters. If you require access to the deployment data, obtain it from the session object.

- **DeployApplication**: There are no longer any globally scoped variables. Their associated logic has been moved to the session object or local variables.

- **DeployApplication**: The package config is no longer exposed to the deployment script. Most values have APIs to obtain them from the session object.

- **DeployApplication**: Most provided variables have been updated, renamed or *- in the case of duplicates with PSADT -* removed. Of special note is the removal of architecture specific environment variables.

- **DeployApplication**: Boolean parameters have been replaced with SwitchParameter where possible.

- **DeployApplication**: Most functions have been majorly overhauled to more align with best practices and PSADT v4 standards. Please check the new function documentation for details.

## NEW FEATURES

### User Interface

- The UI now supports native PSADT UIs. Switch between Classic and Fluent styles in the Toolkit configuration. This release defaults to the old UI style which can be disabled within the toolkit config. As of this release, only the legacy UI supports multi user sessions. If you require this feature, please use the legacy UI until multi user support is added by the PSADT team. All new UIs are implemented only through PSADT's native UI framework and therefore do also not support multi user sessions (yet).

- The old `CustomAppDeployToolkitUi.ps1` has been moved to the module in the `Scripts` directory. The file has been heavily overhauled to be compatible with v4 and should no longer be edited. Any customizations should be done via PSADT's native UI customization options. The neo42 Application Package Center will offer suitable pipeline tasks to customize the UI.
  - The UI does not longer require extension code and encoded objects.

- A configurable **progress bar** has been added. It can be enabled via the Setup.cfg option `Options.SHOWPROGRESS`. The dialog will be shown for the duration of the deployment.

- The UI **accent color** is now configurable via the Toolkit configuration `UI.FluentAccentColor`. The legacy neo42 AppKillProcesses window supports this new setting.

- A hard **defer deadline** can now be specified via the Setup.cfg option `AskKillProcesses.DEFERDEADLINE`. This allows to specify a date and time after which the installation cannot be deferred anymore. The soonest of all defer options will be the one applied.

- A minimum **defer interval** can now be specified via the Setup.cfg option `AskKillProcesses.DEFERINTERVAL`. This allows to specify a minimum time in minutes that must pass after a deferral before another attempt at the deployment is allowed. This is useful to suppress quick consecutive retries in case of fast retry exit codes by the deployment system. Make sure this is compatible with your deployment system's retry logic to avoid unexpected behavior.

- The toolkit can now attempt to **reopen applications** that were closed due to the deployment. This can be enabled via the Setup.cfg option `Options.OPENCLOSEDAPPS`. Please note that this feature is implemented on a best effort basis and might not work for all applications. Using this feature will also require the new package configuration format. neo42 Packages will not be using the new format on release.

- An option to respect **Do Not Disturb** cues has been added. A Setup.cfg option `AskKillProcesses.DONOTDISTURB` allows to suppress the deployment UI if the user has enabled Do Not Disturb on their system. Do not disturb is equivalent to deferring the deployment.

- A **restart prompt** can now be shown by the toolkit itself. This can be enabled via the Setup.cfg option `Options.SHOWRESTARTPROMPT`. If the deployment is in interactive mode, the user will be prompted to restart the system with a window that cannot be dismissed without action. In silent mode, the dialog will be suppressed and no action will be taken.

- The option to cancel a dialog was merged into the deferral logic. The user must now be able to defer the deployment if cancelling was previously allowed.. The differentiation between cancel and defer was ambiguous and lead to undesired behavior in certain scenarios. Deferring and cancelling had the same effect of ending the deployment temporarily.

- The UI will now run in the user's context. Which makes it compatible with screen readers.
  - An incompatibility with Workspace ONE has been resolved, where no UI could spawn in SYSTEM context.

### Configurability & Extensability

- The extensions now support **PSADT's layered configuration system**. Any custom configuration, translations or assets placed at the package root will take precedence over the neo42 defaults.
  - For toolkit configuration overwrites create or update `Config\config.psd1`.
  - For translation overwrites create `Strings\strings.psd1`(English) and/or `Strings\<LANGUAGE CODE>\strings.psd1`.
  - For asset overwrites (e.g. logos/ banners) create `Assets\<Asset>`.
  - nAny folder starting with `Overrides.` at the root of the package will also be scanned for configurations.

- The deployment script will now load any module named `PSAppDeployToolkit.*` that is placed in the package root. This allows:
  - Customers to write their own extensions without having to edit the deployment file internals.
  - Neo42 to provide **deployment system specific modules** using this mechanism to enhance the deployment experience.
  - You can hook into the deployment process without having to edit the deployment script itself by using the `Add-NxtDeploymentCallBack` function within your module.

- We support **GPO based configuration** for the toolkit configuration. The ADMX/ADML files can be obtained from Github. For our ADMX to load, import the PSADT GPO first.
  - The GPO has an extra feature to override Setup.cfg values to define these values centrally.

- There are a multitude new toolkit options to more granularly control the behavior of the the extension. Options include:
  - Settings to control the PowerShell environment like action preference, encoding or strict mode settings.
  - Application entry behavior options.
  - Logging options.
  - And many more. Check the toolkit configuration for all available options.

- Empirum specific logic was moved to its dedicated module `PSAppDeployToolkit.Neo42.Empirum.Extensions`. This module is loaded automatically if the deployment is running within an Empirum managed environment and it is present in the package root.

- The source code of the `DeployNxtApplication.exe` is now part of the repository and build process.

### Packaging

A new package configuration format based on **PSD1** has been introduced. The legacy JSON format is still supported, but new features will only be available in the new format

The new format improves the following aspects:

- PSD1 natively supports signing.
- PSD1 natively supports comments.
- PSD1 natively supports variable expansion and expressions (e.g. if statements).
- PSD1 aligns with the PSADT v4 configuration format.
- Editors natively support PSD1 syntax highlighting.
- The new format removes the need for self referencing variables.
- The new format is easier to read and maintain by the packager.

#### General improvements

- New custom functions `CustomEndOnError`, `CustomUpgradePostUninstallOnError` and `CustomUpgradePostInstallOnError` were added which make error handling easier.

- You may place a singular **WIM file** in the `DirFiles` folder which contains the deployment content. PSADT will mount the WIM automatically and point `DirFiles` to the mounted location. This reduces package size and improves transfer times for certain deployment systems.

- Debug logging has been reintroduced. Enable `LogDebugMessages` in the toolkit configuration to get detailed information about the deployment process.

- All session data is now available via the session object, removing the need for parameter blocks in custom functions.

- All functions support PowerShell's native `CommonParameters`, allowing granular control over error handling and debugging.
  - Additionally, functions that change system state support `-WhatIf` and `-Confirm` via the `ShouldProcess` mechanism.

- The functions provided by the module now support proper pipeline input where appropriate.
  - This allows chaining of commands like `Get-ADTApplication -Name 'MyApp' | Uninstall-NXTApplication`.

- The Visual Studio Code workspace has been included in the repository to make it easier to contribute to the project.

- The module is compatible with both PowerShell 5.1 and PowerShell 7+. It may now also be used in ARM based environments.

- All `Execute-*` functions have been merged into a single `(Un)Install-NXTApplication` function. The function automatically determines the deployment type and executes the appropriate logic.

- The value of `DirSupportFiles` now reflects the deployment type. For user deployments, it points to the user specific support files directory automatically.

- If applicable, the user part execution is now evaluated during the installation phase. This will allow for better timing and error handling of user part related issues.

- Extension properties extend the native PSADT types like `InstalledApplication` with info parameters like `.IsInnoSetup` to make working with these objects easier.

- `BlockExection` can now be controlled at the toolkit level, allowing for more widely scoped control.

#### With new format only

- New sets of **deployment methods** have been added: `Appx`, `Copy` and `Burn`.
  - `Appx` allows the deployment of MSIX/Appx packages via the native PSADT functionality.
  - `Copy` allows copying files from the `DirFiles` folder to any location on the target system.
  - `Burn` allows to install wix based wrapper applications.

- Shortcuts can now be managed for both Desktop and Start Menu. Additionally, you may now create shortcuts and point them to a specific location instead of relying on a existing file to copy.

### Performance & Reliability

- The extensions are now a **signed module**. This improves security and reliability when used in environments with hardened security policies.

- Our source code is now strict mode compliant and type safe. This improves reliability and compatibility with modern PowerShell security standards.

- The deployment script has been stripped down to the essentials and all logic has been moved into the module, making it easier to maintain and extend the script.
  - The `Main` logic can now be found in the `Invoke-NXTDeployment` function within the module.

- The codebase has been majorly optimized to improve performance and reliability. This includes:
  - Avoiding pipelines where possible.
  - Using .NET types directly.
  - Caching values.
  - Proper exception handling.
  - And many more optimizations.

- The package cache is now forced to reside in the secured package directory. This prevents unintentional use of unsecured locations.

- The use of global scoped variables has been dropped across the entire codebase. All data is now stored in the session object.

- Extensive validation has been added to all configuration values before they are used. This prevents unexpected behavior due to invalid configuration. PowerShell code that resides within configuration files is run against a separated restricted session to prevent code injection.

- The module makes use of the immutable command table introduced in PSADTv4 to prevent code injection attacks.

- All variables exposed by the toolkit are protected against modification. Attempting to change these variables will result in an error.

- Performance optimizations have been made to the package deployment process to reduce deployment times and resource consumption significantly.

- The use of Windows Management Instrumentation (WMI) has been dropped from the codebase. This improves performance and reliability, especially on systems with WMI issues.

- The compression algorithm in `NXTEncodedObject` was changed, to make it deterministic across PowerShell editions. It now is also more efficient for tiny strings.
