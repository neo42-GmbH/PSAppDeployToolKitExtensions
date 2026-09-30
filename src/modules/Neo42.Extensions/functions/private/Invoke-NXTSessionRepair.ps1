function Invoke-NXTSessionRepair {
	<#
	.SYNOPSIS
	The logic to translate the session object into a repair operation.
	#>
	[OutputType([PSADT.ProcessManagement.ProcessResult])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0)]
		[ValidateNotNull()]
		[PSADTNXT.Foundation.NxtDeploymentSession]
		$ADTSession = (Get-ADTSession)
	)

	try {
		[PSADT.ProcessManagement.ProcessResult]$result = $null
		switch ($ADTSession.NXT.Install.Method) {
			([PSADTNXT.Deployment.DeploymentMethod]::MSI) {
				[System.IO.FileInfo]$installer = if ([PSADTNXT.IO.NxtPath]::IsValidFilePath($ADTSession.NXT.Install.Target) -and [System.IO.Path]::GetExtension($ADTSession.NXT.Install.Target) -eq '.msi') {
					if ([System.IO.Path]::IsPathRooted($ADTSession.NXT.Install.Target)) {
						$ADTSession.NXT.Install.Target
					}
					elseif ([System.String]::IsNullOrWhiteSpace($ADTSession.DirFiles)) {
						[System.IO.Path]::Combine($ADTSession.DirFiles, $ADTSession.NXT.Install.Target)
					}
				}

				if ($installer -and $installer.Exists) {
					$result = Start-ADTMsiProcess -Action Repair -RepairFromSource -RepairMode Repair -PassThru -FilePath $installer.FullName
				}
				else {
					if (-not $ADTSession.NXT.Detection.Application) {
						[System.Collections.Hashtable]$errorParams = @{
							Exception = [System.Management.Automation.ItemNotFoundException]::new('The target application was not found for repair operation.')
							Category  = [System.Management.Automation.ErrorCategory]::InvalidResult
							ErrorId   = 'ApplicationNotFoundForRepair'
						}
						throw (New-ADTErrorRecord @errorParams)
					}
					$result = Start-ADTMsiProcess -Action Repair -RepairMode Repair -RepairFromSource -PassThru -ProductCode $ADTSession.NXT.Detection.Application.PSChildName
				}
			}
			default {
				[System.Collections.Hashtable]$errorParams = @{
					Exception = [System.NotSupportedException]::new("The installation method [$($ADTSession.NXT.Install.Method)] is not supported for repair operations.")
					Category  = [System.Management.Automation.ErrorCategory]::NotImplemented
					ErrorId   = 'RepairMethodNotSupported'
				}
				throw (New-ADTErrorRecord @errorParams)
			}
		}
		Wait-NXTDeploymentAwaiter -Awaiter $ADTSession.NXT.Install.Awaiters
		return $result
	}
	catch {
		Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
	}
}
