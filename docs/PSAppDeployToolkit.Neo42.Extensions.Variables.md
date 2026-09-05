# Variables available through V4 Neo42.Extensions

An extension to the variables made available by the [PSAppDeployToolkit](https://psappdeploytoolkit.com/docs/reference/variables).

## General

| Name                | Description                                                                                                  |
| :------------------ | :----------------------------------------------------------------------------------------------------------- |
| DeploymentTimestamp | A file system compatible timestamp of when the deployment was initialized in the format `yyyy-MM-ddTHHmmss`. |

## Device information

| Name                    | Description                                                                 |
| :---------------------- | :-------------------------------------------------------------------------- |
| EnvComputerManufacturer | The manufacturer of the device (e.g. `LENOVO`).                             |
| EnvComputerModel        | The model of the device (e.g. `21FACTO1WW`).                                |
| EnvComputerSystemFamily | The family of products this device belongs to (e.g. `ThinkPad P16 Gen 2`).  |
| EnvComputerThreadCount  | The thread count of the device.                                             |

## Domain Membership

| Name                       | Description                                                                         |
| :------------------------- | :---------------------------------------------------------------------------------- |
| EnvComputerADNetbiosDomain | The netbios name of the current computer domain like `CORP` for `corp.contoso.com`. |

## Operating System

| Name                       | Description                                                                                                                       |
| :------------------------- | :-------------------------------------------------------------------------------------------------------------------------------- |
| EnvWindowsBits             | `64` on 64-bit operating systems and `32` on 32-bit systems.                                                                      |
| EnvWow6432Node             | A string containing `WOW6432Node` if the 32-bit compatability registry is available.                                              |
| EnvRegistrySoftware        | The registry path to the process native registry software path. This value is never empty.                                        |
| EnvRegistrySoftwareW3264   | The path to the 32-bit registry independent of the operating system. This value is never empty.                                   |
| EnvProgramFilesW3264       | The path to the 32-bit program files directory independent of the operating system. This value is never empty.                    |
| EnvCommonProgramFilesW3264 | The path to the 32-bit common program files directory independent of the operating system. This value is never empty.             |
| EnvSystemX64               | The 64-bit folder independent of the process architecture. Falls back to 32-bit is on a 32-bit system. This value is never empty. |
| EnvSystemX86               | The 32-bit `System32` folder independent of the process architecture. This value is never empty.                                  |

## Dependencies

| Name                        | Description                                                  |
| :-------------------------- | :----------------------------------------------------------- |
| EnvDotNetFrameworkV4Release | The release build of the .NET Framework V4 Full installation |
