function Write-MyCompanyMessage {
	Write-ADTLogEntry -Message "Hello from $($ExecutionContext.SessionState.Module.Name)! It works!" -Severity Success
}

Add-NXTDeploymentCallback -HookPoint CustomInstallAndReinstallAndSoftMigrationBegin -Callback (Get-Item 'Function::Write-MyCompanyMessage')
