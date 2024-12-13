# Introduction
The neo42 PSAppDeployToolkit Extensions integrate and extend a globally respected and regorously tested deployment framework. We use them to align the PSADT with the vision neo42 has for packaging.
We hope, by providing public access, you can profit off of our work and help us improve ourselfs.

neo42 GmbH makes use of these extensions to provide its service [Application Package Depot](https://neo42.de/application-package-depot).

# Why use the neo42 Extensions
### Configuration based installers
__No code approach to writing new packages__

Don't want to write new code for every simple package? Make use of our Deploy-Application.ps1 which can be controlled solely by its corresponding neo42PackageConfig.json. The standardized sequence of the main function remains unchanged for each package!

_The included schema for the json file and examples will help you write your first package in no time._

__Custom* functions__

You are not limited to the values contained within in the configuration file but you can also write customizings in the intended Custom* functions without loosing the framework we provide. The custom* functions offer many different entry points to intervene in the main function process and perform individual actions for each package if required.

__Automation first__

In addition to the neo42PackageConfig.json file, which is very easy to change automatically, we have also made sure that automatic updates are possible in many other aspects. For example, in this [script](https://github.com/neo42-GmbH/ManagementService-PowerShell/blob/master/Pipelines/Add-ContentToCustomFunction.ps1) we have demonstrated how to use Custom* functions for your own content. Your own product-specific code can be automatically transferred to new packages at any time!

### New functionalities
__The neo42 Extensions offer over 100+ new functions__
* They simplify interacting with complex data types like XML
* Allows you to access data that is not supported by default in PowerShell 5.1 like INI, JsonC and others
* Quickly access device information like process trees, drive information or language
* Makes interacting with system security related functions easy. For example setting ACLs in simple but powerful functions
* They extend PSADT functions with better error handling, more functionality or altered defaults that are compatible with neo42 packages
* Make use of observer functions that handle waiting for processes, files, registry keys and others easy
* Extended ui for interactions with the user that also supports dark mode

More details to the neo42 Extensions [neo42 Extensions Help Index](https://portal.neo42.de/Help/674885cc4c0539ebc80bf566)

_All functions are tested to work in different deployment system contextes like Empirum, Intune or Workspace One_

__Integrated installer handling__

Based on our long experience, we have been able to integrate the silent parameters and handling for the most common installer types into the extension. As a rule, no further parameters or code adaptations are necessary for the following types:
* MSI
* InnoSetup
* BitRock
* Nullsoft

_Apart from these installers, any other installer can be addressed via the predefined fields in the configuration file._

# Build instructions
_Note: We always recommend obtaining the [latest production release](https://github.com/neo42-GmbH/PSAppDeployToolKitExtensions/releases/latest) from the releases page._

* Get a [compatible](#requirements) release copy of the [PSAppDeploymentToolkit](#links)
* Clone or download the contents of this repository
* Create a new folder
    * Copy the Toolkit/AppDeployToolkit into it
    * Copy the contents of this repository and overwrite existing
        - It is recommended to remove all dot files before copying the contents

# Requirements
* PSAppDeployTookit 3.10.2
* PowerShell 5.1 Desktop (PowerShell Core is not supported)
* .NET Framework 4

# License
The content of this repository is licensed under the GNU Lesser General Public License version 3, or any later version. You can find a copy of the licenses at the root of this repository. You are free to use, alter and share the contents as you wish as long as it complies with the aforementioned license.

This code is distributed WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

# Links
* https://github.com/PSAppDeployToolkit/PSAppDeployToolkit
* https://www.gnu.org/licenses/licenses.html
* [neo42 Extensions Help Index](https://portal.neo42.de/Help/674885cc4c0539ebc80bf566)
* [Example packages + neo42 Package Config Editor](https://portal.neo42.de/Help/6748996f4c0539ebc80bf5d8)
