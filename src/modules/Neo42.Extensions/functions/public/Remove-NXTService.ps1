function Remove-NXTService {
	<#
	.SYNOPSIS
	Removes a service from the system.
	.DESCRIPTION
	The Remove-NXTService cmdlet removes a service from the system by stopping it and deleting it.
	.INPUTS
	System.String - The name(s) of the service(s) to remove.

	System.ServiceProcess.ServiceController - The service object(s) to remove.
	.PARAMETER Name
	The name(s) of the service(s) to remove.
	.PARAMETER Force
	Will delete the service even if it did not stop in time, has dependencies or is already marked for deletion.
	.PARAMETER Timeout
	The time to wait for the service to stop before removing it.
	.EXAMPLE
	Remove-NXTService -Name 'MyService'

	Removes the service named 'MyService' from the system, stopping it first if it is running.
	.EXAMPLE
	Remove-NXTService -Name 'MyService' -Force

	Removes the service named 'MyService' from the system without stopping it first and without validating dependencies.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleTypes', '', Justification = 'A loaded module imports the required types.')]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Parameters are used within pipe.')]
	[CmdletBinding(SupportsShouldProcess)]
	param (
		[Parameter(Mandatory)]
		[System.String[]]
		$Name,
		[System.Management.Automation.SwitchParameter]
		$Force,
		[PSADTNXT.Attributes.NxtTimeSpanTransformation()]
		[System.TimeSpan]
		$Timeout = '00:01:00'
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.String]$serviceSubKey = 'SYSTEM\CurrentControlSet\Services'
	}
	process {
		try {
			$Name | & {
				process {
					if (-not ([Microsoft.Win32.RegistryKey]$serviceKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("$serviceSubKey\$_", $false))) {
						Write-ADTLogEntry -Message "Service [$_] does not exist, skipping removal."
						return
					}
					[System.Boolean]$flaggedForDelete = $serviceKey.GetValue('DeleteFlag') -eq 1
					$serviceKey.Close()

					[System.ServiceProcess.ServiceController]$service = [System.ServiceProcess.ServiceController]::new($_)
					if (-not $Force -and $service.DependentServices.Count -gt 0) {
						[System.Collections.Hashtable]$errorParams = @{
							Exception    = [System.Management.Automation.ItemNotFoundException]::new("The service [$_] has dependent services and cannot be removed without the -Force switch.")
							Category     = [System.Management.Automation.ErrorCategory]::InvalidArgument
							ErrorId      = 'ServiceHasDependencies'
							TargetObject = $_
						}
						throw (New-ADTErrorRecord @errorParams)
					}

					if ($PSCmdlet.ShouldProcess($_, 'Remove service')) {
						if ($service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Stopped) {
							Write-ADTLogEntry -Message "Stopping service [$_]."
							$service.Stop()
							$service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Stopped, $Timeout)

							if (-not $Force -and $service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Stopped) {
								[System.Collections.Hashtable]$errorParams = @{
									Exception    = [System.Management.Automation.RuntimeException]::new("The service [$_] could not be stopped within the specified timeout [$Timeout].")
									Category     = [System.Management.Automation.ErrorCategory]::OperationTimeout
									ErrorId      = 'ServiceStopTimeout'
									TargetObject = $_
								}
								throw (New-ADTErrorRecord @errorParams)
							}
						}

						if (-not $Force -and $flaggedForDelete) {
							Write-ADTLogEntry -Message "Service [$_] is already marked for deletion, skipping removal."
							return
						}


						Write-ADTLogEntry -Message "Removing service [$_]."
						# The win32 API does nothing else than removing the key from the registry.
						# https://learn.microsoft.com/en-us/windows/win32/api/winsvc/nf-winsvc-deleteservice#remarks
						Remove-Item -Path "Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\$serviceSubKey\$_" -Force -Recurse
					}
				}
			}
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
