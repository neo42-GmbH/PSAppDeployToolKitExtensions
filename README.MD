![PSAppDeployToolkit](./.assets/neo42PSADTExt_GitHub_Banner.png)

## 👋 Introduction

The neo42 PSAppDeployToolkit Extensions integrate with and extend a globally respected and rigorously tested deployment framework. It combines the PSAppDeployToolkit with the vision of neo42 to provide an easy-to-use, advanced packaging solution.

🧩 neo42 GmbH makes use of the extensions in this repository to provide multiple services:
- [Application Package Depot](https://neo42.de/application-package-depot) - Select and automate from a large amount of packaged software
- [Package Recorder PRO](https://neo42.de/produkte/package-recorder) - Advanced and easy-to-use packaging tool
- [Software Packaging](https://neo42.de/dienstleistungen/softwarepaketierung) - Software packages tailored to your needs

🔓 By providing public access, we hope that others will benefit from it and help to improve this solution.

## 💭 Why use the neo42 Extensions

### 📈 Configuration based deployments

__🎚️ No code approach to writing new packages__

Don't want to write new code for every simple package? Make use of our `Deploy-Application.ps1`, which is controlled entirely by its package configuration. The standardized installation sequence remains unchanged for each package!

* `neo42PackageConfig.psd1` is the recommended format. It supports comments, signing and PowerShell expressions, follows the PSADT v4 configuration style and is validated when the package is loaded. New features, such as the `AppX`, `Copy` and `Burn` deployment methods or managed shortcuts, are only available in this format.
* `neo42PackageConfig.json` is the legacy format used by V3 packages. It is still supported and is translated into the new model at runtime, but it will be deprecated in a future release.

_The [samples](./samples) for both formats and the [legacy package config reference](./docs/neo42PackageConfigJson.md) will help you write your first package in no time._

__🪝 Deployment hooks__

You are not limited to the values contained within the configuration file. The deployment process offers many hook points, such as `CustomBegin`, `CustomInstallEnd` or `CustomEndOnError`, where you can run your own code without losing the framework we provide.

The recommended way to use them is your own extension module. Any module named `PSAppDeployToolkit.*` that is placed in the package root is loaded automatically, and its functions can be attached to any hook point with `Add-NXTDeploymentCallback`:

```PowerShell
Add-NXTDeploymentCallback -HookPoint 'CustomInstallEnd' -Callback (Get-Command -Name 'Invoke-MyCompanyAction')
```

This keeps your code out of the deployment script. The [example extension module](./samples/PSAppDeployToolkit.Neo42.Extensions.CompanyExtension) shows a minimal setup.

For package-specific changes, the `Custom*` functions in `Deploy-Application.ps1` are still available. They use the same hook points and are compatible with the ones you know from V3.

__⛓️ Automation first__

The package configuration is very easy to generate and change programmatically, and we made sure that automatic updates are possible in many other aspects as well:

* Company- or product-specific code lives in your extension module. Add it to any package and it hooks itself into the deployment. Updating it means replacing the module, not editing every deployment script.
* Toolkit settings, translations and assets can be overridden through PSADT's layered configuration by placing `Config`, `Strings` or `Assets` folders (or `Overrides.*` folders) in the package root.
* `Update-NXTPackage` from `PSAppDeployToolkit.Neo42.Tools` migrates existing V3 packages to V4.

_V3 packages cannot load extension modules. For them, this [script](https://github.com/neo42-GmbH/ManagementService-PowerShell/blob/master/Pipelines/Add-ContentToCustomFunction.ps1) demonstrates how to inject code into the `Custom*` functions instead._

### ✨ New functionalities

__🪄 The neo42 Extensions offer dozens of new functions__

* They simplify interacting with complex data types such as XML.
* Allow you to access data that is not supported by default in PowerShell 5.1 like INI, JsonC and others.
* Quickly access device information like process trees or drive information.
* Make interacting with system security-related functions easy. For example, setting ACLs in simple but powerful functions.
* They extend PSADT functions with more functionality or altered defaults that are compatible with neo42 packages.
* Make use of observer functions that handle waiting for processes, files, registry keys and others easy.

_All functions are tested to work in different deployment system contexts such as Empirum, SCCM, Intune or Workspace One._

__💡 Integrated installer handling__

Based on our long experience, we have been able to integrate the silent parameters and handling for the most common installer types into the extension. In most cases, no further parameters or code adaptations are necessary for the following installer types:

* MSI
* InnoSetup
* BitRock
* Nullsoft
* Burn
* AppX

_Apart from these installer types, any other installer can be handled via the predefined fields in the configuration file._

## 🛠️ Build instructions

> [!NOTE]
> _We always recommend obtaining the latest production release from the [releases page](https://github.com/neo42-GmbH/PSAppDeployToolKitExtensions/releases/latest)._

### 🔎 Requirements

* PSAppDeployToolkit 4.1.8 module
* Windows PowerShell (PowerShell 5.1)
* .NET 8 SDK or later

### 🌤️ Recommended Build Environment

* [Requirements](#-requirements) installed
* [Visual Studio Code](#-links) - For predefined development environment
* [PowerShell Core](#-links) (PowerShell 7.6 or later) - For cross edition tests
* PowerShell modules (for both PowerShell editions):
  * [PSScriptAnalyzer](#-links) 1.25 or later - For code analysis and the migration tool
  * [Pester](#-links) 5.6 or later - For testing the project

### 📋 Steps

* Clone or download the content of this repository.
* Build the project by one of the following methods:
  * Using the predefined VSCode build tasks _(Recommended)_
  * Walking through the manual steps, supported by scripts:
    1. Run `.tools\Install-RequiredModule.ps1` to download the required [PSADT dependencies](#-requirements).
    2. Run `.tools\Export-Module.ps1`.
    3. Run `.tools\Invoke-Compile.ps1` or use the `dotnet publish` command for `src\solutions`.

## 🧰 Release components

| Asset                                                      | Content                                                                                                                                                                                                            |
|:-----------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `ADMX.zip`                                                 | ADMX/ADML templates for central configuration via GPO.                                                                                                                                                             |
| `PSAppDeployToolkit.Neo42.Extensions.DeploymentSystem.zip` | Deployment-system-specific logic, such as Empirum. It loads automatically when it is placed in the package root.                                                                                                   |
| `PSAppDeployToolkit.Neo42.Extensions.zip`                  | The core module on its own, for updating existing V4 packages.                                                                                                                                                     |
| `PSAppDeployToolkit.Neo42.Tools.zip`                       | Packaging tools, including `Update-NXTPackage` to migrate V3 packages. It is not part of the package.                                                                                                              |
| `Samples.zip`                                              | Sample package configs and an example extension module.                                                                                                                                                            |
| `Template.zip`                                             | **Start here.** A ready-to-use package containing PSADT 4.1.8, the neo42 Extensions, the DeploymentSystem module, `Deploy-Application.ps1`, `DeployNxtApplication.exe`, `Setup.cfg` and a template package config. |

All neo42 modules and `DeployNxtApplication.exe` are code-signed.

The latest release can be downloaded from the [releases page](https://github.com/neo42-GmbH/PSAppDeployToolKitExtensions/releases/latest).

## 📚 Documentation
For detailed documentation of the neo42 PSADT Extensions, please check these files:
* [Changelog](./docs/PSAppDeployToolkit.Neo42.Extensions.Changelog.md)
* [V4 Migration guide](./docs/PSAppDeployToolkit.Neo42.Extensions.V4Migration.md)
* [Function reference](./docs/PSAppDeployToolkit.Neo42.Extensions.Functions.md)
* [Variable reference](./docs/PSAppDeployToolkit.Neo42.Extensions.Variables.md)
* [Legacy package config (JSON) reference](./docs/neo42PackageConfigJson.md)

For information about the PSADT, the base of these extensions, please visit the [PSADT website or project page](#-links).

## 📜 License

The content of this repository is licensed under the [GNU Lesser General Public License](https://www.gnu.org/licenses/licenses.html) version 3, or any later version.
You are free to use, alter and share the contents as you wish as long as it complies with the aforementioned license.

This code is distributed WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

You can find a [copy of the license](./LICENSE) at the root of this repository.

## 🔗 Links

* [PSAppDeployToolkit Website](https://psappdeploytoolkit.com)
* [PSAppDeployToolkit Project](https://github.com/PSAppDeployToolkit/PSAppDeployToolkit)
* [PSScriptAnalyzer Module](https://learn.microsoft.com/powershell/module/psscriptanalyzer)
* [Pester Module](https://pester.dev)
* [PowerShell Core](https://learn.microsoft.com/powershell/)
* [.NET SDK](https://dotnet.microsoft.com/download)
* [Visual Studio Code](https://code.visualstudio.com)
