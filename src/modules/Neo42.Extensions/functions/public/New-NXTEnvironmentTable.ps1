function New-NXTEnvironmentTable {
	<#
	.SYNOPSIS
	Creates a new environment table.
	.DESCRIPTION
	Creates a new environment table. Used to substitute the environment table in the ADT session.
	This function is supposed to be used in conjunction with Initialize-ADTSession's `-AdditionalEnvironmentVariables` parameter.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Not applicable')]
	[OutputType([System.Collections.ObjectModel.ReadOnlyDictionary[System.String, System.Object]])]
	[CmdletBinding()]
	param ()
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			# Create a new writable environment table from the existing one
			[System.Collections.Generic.Dictionary[System.String, System.Object]]$newEnvironment = [System.Collections.Generic.Dictionary[System.String, System.Object]]::new()

			# Base registry key for hardware information
			[Microsoft.Win32.RegistryKey]$baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)

			# Infos about the current session
			$newEnvironment['DeploymentTimestamp'] = [System.DateTime]::Now.ToString('yyyy-MM-ddTHHmmss')

			# Computer information
			[Microsoft.Win32.RegistryKey]$biosKey = $baseKey.OpenSubKey('HARDWARE\DESCRIPTION\System\BIOS')
			$newEnvironment['envComputerManufacturer'] = $biosKey.GetValue('SystemManufacturer')
			$newEnvironment['envComputerModel'] = $biosKey.GetValue('SystemProductName')
			$newEnvironment['envComputerSystemFamily'] = $biosKey.GetValue('SystemFamily')
			$biosKey.Close()

			[Microsoft.Win32.RegistryKey]$processorKey = $baseKey.OpenSubKey('HARDWARE\DESCRIPTION\System\CentralProcessor')
			$newEnvironment['envComputerThreadCount'] = $processorKey.GetSubKeyNames().Count
			$processorKey.Close()

			# Domain information
			[System.DirectoryServices.ActiveDirectory.Domain]$domain = try { [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain() } catch { $null }
			$newEnvironment['envComputerADNetbiosDomain'] = if ($domain) { [PSADTNXT.DirectoryServices.ActiveDirectory.NxtDirectory]::GetNetbiosNameForDomain($domain.Name) } else { $null }

			# Architecture based information
			$newEnvironment['envWindowsBits'] = if ([System.Environment]::Is64BitOperatingSystem) { [System.Byte]64 } else { [System.Byte]32 }
			$newEnvironment['Wow6432Node'] = [System.String]::Empty
			$newEnvironment['envRegistrySoftware'] = 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE'
			if ([System.Environment]::Is64BitOperatingSystem) {
				if ([System.Environment]::Is64BitProcess) {
					$newEnvironment['envRegistrySoftwareW3264'] = 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node'
					$newEnvironment['envProgramFilesW3264'] = [System.Environment]::GetFolderPath('ProgramFilesX86')
					$newEnvironment['envCommonProgramFilesW3264'] = [System.Environment]::GetFolderPath('CommonProgramFilesX86')
					$newEnvironment['envSystemX64'] = [System.Environment]::GetFolderPath('System')
					$newEnvironment['envSystemX86'] = [System.Environment]::GetFolderPath('SystemX86')
					$newEnvironment['Wow6432Node'] = 'WOW6432Node'
				}
				else {
					$newEnvironment['envRegistrySoftwareW3264'] = 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE'
					$newEnvironment['envProgramFilesW3264'] = [System.Environment]::GetFolderPath('ProgramFilesX86')
					$newEnvironment['envCommonProgramFilesW3264'] = [System.Environment]::GetFolderPath('CommonProgramFilesX86')
					$newEnvironment['envSystemX64'] = [System.Environment]::GetFolderPath('Windows') + '\SysNative'
					$newEnvironment['envSystemX86'] = [System.Environment]::GetFolderPath('SystemX86')
				}
			}
			else {
				$newEnvironment['envRegistrySoftwareW3264'] = 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE'
				$newEnvironment['envProgramFilesW3264'] = [System.Environment]::GetFolderPath('ProgramFiles')
				$newEnvironment['envCommonProgramFilesW3264'] = [System.Environment]::GetFolderPath('CommonProgramFiles')
				$newEnvironment['envSystemX64'] = [System.Environment]::GetFolderPath('System')
				$newEnvironment['envSystemX86'] = [System.Environment]::GetFolderPath('System')
			}

			# .NET Framework
			# https://learn.microsoft.com/de-de/dotnet/framework/install/how-to-determine-which-versions-are-installed#net-framework-10-40
			$newEnvironment['envDotNetFrameworkV4Release'] = if ([Microsoft.Win32.RegistryKey]$dotNetV4Key = $baseKey.OpenSubKey('SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full')) { $dotNetV4Key.GetValue('Release') } else { $null }

			$baseKey.Close()

			return [System.Collections.ObjectModel.ReadOnlyDictionary[System.String, System.Object]]::new($newEnvironment)
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
