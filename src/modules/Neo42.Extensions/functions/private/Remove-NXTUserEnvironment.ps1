function Remove-NXTUserEnvironment {
	<#
	.SYNOPSIS
	Clears all user defined environment variables from the process environment.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This is a private function')]
	[CmdletBinding()]
	param()

	Write-ADTLogEntry -Message 'Removing user environment variables from the process environment.' -DebugMessage
	foreach ($name in [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::User).Keys) {
		[System.Environment]::SetEnvironmentVariable(
			$name,
			[System.Environment]::GetEnvironmentVariable($name, [System.EnvironmentVariableTarget]::Machine),
			[System.EnvironmentVariableTarget]::Process
		)
	}
}
