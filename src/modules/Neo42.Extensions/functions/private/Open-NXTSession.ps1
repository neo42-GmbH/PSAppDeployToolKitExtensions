function Open-NXTSession {
	<#
	.SYNOPSIS
	This function is called upon every call of the Open-ADTSession function.
	It initialized session related objects and variables.
	#>
	[CmdletBinding()]
	param ()

	# Obtain the current deployment session and configuration.
	[PSADT.Module.DeploymentSession]$adtSession = Get-ADTSession
	[System.Collections.Hashtable]$adtConfig = Get-ADTConfig
	[PSADT.DeviceManagement.OperatingSystemInfo]$osInfo = Get-ADTOperatingSystemInfo

	# We only support the NxtDeploymentSession class
	if ($adtSession -isnot [PSADTNXT.Foundation.NxtDeploymentSession] -or -not $adtConfig.ContainsKey('NXT')) {
		Write-ADTLogEntry -Severity Warning -Message 'Either the current session type is not [NxtDeploymentSession] or the NXT config is not available. Skipping [Neo42.Extension] session initialization.'
		return
	}

	# Hijack the session state. Only available on 4.2
	$adtSession.NXT.DeployAppScriptSessionState = $PSCmdlet.SessionState.PSVariable.GetValue('SessionState')

	# Make sure to inform about unsigned scripts
	if ($adtSession.NXT.DeploymentType.IsMachinePart -and
		([System.String]$scriptPath = (Get-PSCallStack)[0].ScriptName) -and
		(Get-AuthenticodeSignature -FilePath $scriptPath).Status -ne [System.Management.Automation.SignatureStatus]::Valid
	) {
		Write-ADTLogEntry -Severity Warning -Message "The script [$scriptPath] is not signed or trusted. Running untrusted code is not recommended and may be blocked by security policies."
	}

	# Validate the package architecture against the operating system architecture
	if ($adtSession.AppArch -like '*64' -and -not [System.Environment]::Is64BitOperatingSystem) {
		throw [System.PlatformNotSupportedException]::new('This 64-bit application cannot be deployed on a 32-bit operating system.')
	}
	if ($adtSession.AppArch -like 'ARM*' -and $osInfo.Architecture -notin @([System.Runtime.InteropServices.Architecture]::Arm, [System.Runtime.InteropServices.Architecture]::Arm64)) {
		throw [System.PlatformNotSupportedException]::new('This ARM application cannot be deployed on a non-ARM operating system.')
	}

	# Apply the PowerShell variables to the caller environment
	$adtSession.NXT.DeployAppScriptSessionState.PSVariable.Set('ErrorActionPreference', [System.Management.Automation.ActionPreference]$adtConfig['NXT']['PowerShell']['ErrorActionPreference'])
	$adtSession.NXT.DeployAppScriptSessionState.PSVariable.Set('VerbosePreference', [System.Management.Automation.ActionPreference]$adtConfig['NXT']['PowerShell']['VerbosePreference'])
	$adtSession.NXT.DeployAppScriptSessionState.PSVariable.Set('ProgressPreference', [System.Management.Automation.ActionPreference]$adtConfig['NXT']['PowerShell']['ProgressPreference'])
	$adtSession.NXT.DeployAppScriptSessionState.PSVariable.Set('OutputEncoding', [PSADTNXT.Text.NxtEncoding]::GetEncoding($adtConfig['NXT']['PowerShell']['OutputEncoding']))

	# Apply the defined strict mode
	if (-not [System.String]::IsNullOrWhiteSpace($adtConfig['NXT']['PowerShell']['StrictModeVersion'])) {
		$null = $ExecutionContext.InvokeCommand.InvokeScript($adtSession.NXT.DeployAppScriptSessionState, { . $args[0] -Version $args[1] }.Ast.GetScriptBlock(), $script:CommandTable.'Set-StrictMode', $adtConfig['NXT']['PowerShell']['StrictModeVersion'])
	}

	# Apply the PowerShell process execution policy to the whole execution environment
	[System.Environment]::SetEnvironmentVariable('PSExecutionPolicyPreference', [Microsoft.PowerShell.ExecutionPolicy]$adtConfig['NXT']['PowerShell']['ExecutionPolicy'], [System.EnvironmentVariableTarget]::Process)

	# Copy MSI parameters into NXT installer block for easier access. Make it unlinked to not overwrite the toolkit configuration
	$adtConfig['NXT']['Deployment']['MSI'] = [System.Collections.Hashtable]::new($adtConfig['MSI'], [System.StringComparer]::OrdinalIgnoreCase)

	# Remove user environment variables if not a user deployment
	if ($adtSession.NXT.DeploymentType.IsMachinePart) {
		Remove-NXTUserEnvironment
	}

	# Apply config overrides from setup config to the toolkit config
	if ($adtSession.NXT.SetupCfg['Options']['SHOWBALLOONNOTIFICATIONS'] -eq '1') {
		$adtConfig['UI']['BalloonNotifications'] = $true
	}
	elseif ($adtSession.NXT.SetupCfg['Options']['SHOWBALLOONNOTIFICATIONS'] -eq '0') {
		$adtConfig['UI']['BalloonNotifications'] = $false
	}

	# Extend requirements list with external package requirements
	[System.IO.FileInfo]$packageRequirementsConfig = [System.IO.Path]::Combine($adtSession.NXT.DeployAppScript.Directory.FullName, 'neo42PackageRequirements.json')
	if ($packageRequirementsConfig.Exists) {
		Write-ADTLogEntry -Message 'Additional package requirements configuration found. Importing and adding to session requirements.'
		$adtSession.NXT.Requirements.AddRange([PSADTNXT.Deployment.NxtRequirement[]]@(Import-NXTPackageRequirement -Path $packageRequirementsConfig))
	}
	else {
		Write-ADTLogEntry -Message 'No additional package requirements configuration found.' -DebugMessage
	}
}
