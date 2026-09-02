function Initialize-NXTModule {
	<#
	.SYNOPSIS
	This function is called on the first call of the Open-ADTSession function.
	#>
	[CmdletBinding()]
	param ()
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Collections.Generic.IReadOnlyDictionary[System.String, System.Object]]$adtEnvironment = Get-ADTEnvironmentTable
	}
	process {
		try {
			[System.String]$netbiosName = if ($adtEnvironment.IsMachinePartOfDomain) { $adtEnvironment.envComputerADNetbiosDomain } else { $adtEnvironment.envMachineWorkgroup }
			[System.String]$computerName = $adtEnvironment.envComputerName
			[System.String]$systemDrive = $adtEnvironment.envSystemDrive
			[Microsoft.Win32.RegistryKey]$agentKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64).OpenSubKey('SOFTWARE\Matrix42\Agent')
			[System.Collections.Generic.Dictionary[System.String, System.Object]]$empirumData = [System.Collections.Generic.Dictionary[System.String, System.Object]]::new([System.StringComparer]::OrdinalIgnoreCase)

			if ($agentKey) {
				$empirumData['AgentCache'] = [System.IO.DirectoryInfo]::new($agentKey.GetValue('CacheFolder', "$systemDrive\EmpirumAgent"))
				$empirumData['ComputerValues'] = [System.IO.FileInfo]::new($agentKey.GetValue("var_${netbiosName}_${computerName}", "$($empirumData['AgentCache'])\Values`$\MachineValues\$netbiosName\$computerName.ini"))

				$agentKey.Close()
			}
			else {
				$empirumData['AgentCache'] = [System.IO.DirectoryInfo]::new("$systemDrive\EmpirumAgent")
				$empirumData['ComputerValues'] = [System.IO.FileInfo]::new("$($empirumData['AgentCache'])\Values`$\MachineValues\$netbiosName\$computerName.ini")
			}

			$empirumData['Module'] = Get-Module -Name 'Matrix42.UEM.Agent.Extension.PowerShell' -ErrorAction Ignore
			$empirumData['SetupErrorLog'] = [System.IO.FileInfo]::new("$($empirumData['AgentCache'])\Log\SetupErrorLog\$netbiosName.$computerName.log")

			New-Variable -Name 'EMP' -Option Constant -Scope Script -Force -Value ([System.Collections.ObjectModel.ReadOnlyDictionary[System.String, System.Object]]::new($empirumData))
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
