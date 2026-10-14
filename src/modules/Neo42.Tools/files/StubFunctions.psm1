[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleTypes', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSNxtAvoidBaseTypes', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '')]
param()

function Write-FunctionHeaderOrFooter {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$CmdletName,
		[Parameter(Mandatory = $true, ParameterSetName = 'Header')]
		[AllowEmptyCollection()]
		[System.Collections.Hashtable]
		$CmdletBoundParameters,
		[Parameter(Mandatory = $true, ParameterSetName = 'Header')]
		[System.Management.Automation.SwitchParameter]
		$Header,
		[Parameter(Mandatory = $true, ParameterSetName = 'Footer')]
		[System.Management.Automation.SwitchParameter]
		$Footer
	)
}

function Execute-MSP {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[Alias('FilePath')]
		[System.String]
		$Path,
		[System.String]
		$AddParameters
	)
}

function Write-Log {
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '')]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyCollection()]
		[Alias('Text')]
		[System.String[]]
		$Message,
		[Parameter(Mandatory = $false, Position = 1)]
		[System.Int16]
		$Severity,
		[Parameter(Mandatory = $false, Position = 2)]
		[System.String]
		$Source,
		[Parameter(Mandatory = $false, Position = 3)]
		[System.String]
		$ScriptSection,
		[Parameter(Mandatory = $false, Position = 4)]
		[System.String]
		$LogType,
		[Parameter(Mandatory = $false, Position = 5)]
		[System.String]
		$LogFileDirectory,
		[Parameter(Mandatory = $false, Position = 6)]
		[System.String]
		$LogFileName,
		[Parameter(Mandatory = $false, Position = 7)]
		[System.Boolean]
		$AppendToLogFile,
		[Parameter(Mandatory = $false, Position = 8)]
		[System.Int32]
		$MaxLogHistory,
		[Parameter(Mandatory = $false, Position = 9)]
		[System.Decimal]
		$MaxLogFileSizeMB,
		[Parameter(Mandatory = $false, Position = 10)]
		[System.Boolean]
		$ContinueOnError,
		[Parameter(Mandatory = $false, Position = 11)]
		[System.Boolean]
		$WriteHost,
		[Parameter(Mandatory = $false, Position = 12)]
		[System.Management.Automation.SwitchParameter]
		$PassThru,
		[Parameter(Mandatory = $false, Position = 13)]
		[System.Management.Automation.SwitchParameter]
		$DebugMessage,
		[Parameter(Mandatory = $false, Position = 14)]
		[System.Boolean]
		$LogDebugMessage
	)
	process {
	}
}

function Remove-InvalidFileNameChar {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyString()]
		[System.String]
		$Name
	)
	process {
	}
}

function New-ZipFile {
	[CmdletBinding(DefaultParameterSetName = 'CreateFromDirectory')]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.String]
		$DestinationArchiveDirectoryPath,
		[Parameter(Mandatory = $true, Position = 1)]
		[System.String]
		$DestinationArchiveFileName,
		[Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'CreateFromDirectory')]
		[System.String[]]
		$SourceDirectoryPath,
		[Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'CreateFromFile')]
		[System.String[]]
		$SourceFilePath,
		[Parameter(Mandatory = $false, Position = 3)]
		[System.Management.Automation.SwitchParameter]
		$RemoveSourceAfterArchiving,
		[Parameter(Mandatory = $false, Position = 4)]
		[System.Management.Automation.SwitchParameter]
		$OverWriteArchive,
		[Parameter(Mandatory = $false, Position = 5)]
		[System.Boolean]
		$ContinueOnError
	)
}

function Exit-Script {
	[CmdletBinding()]
	param (
		[System.Int32]
		$ExitCode
	)
}

function Resolve-Error {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyCollection()]
		[System.Array]
		$ErrorRecord,
		[Parameter(Mandatory = $false, Position = 1)]
		[System.String[]]
		$Property,
		[Parameter(Mandatory = $false, Position = 2)]
		[System.Management.Automation.SwitchParameter]
		$GetErrorRecord,
		[Parameter(Mandatory = $false, Position = 3)]
		[System.Management.Automation.SwitchParameter]
		$GetErrorInvocation,
		[Parameter(Mandatory = $false, Position = 4)]
		[System.Management.Automation.SwitchParameter]
		$GetErrorException,
		[Parameter(Mandatory = $false, Position = 5)]
		[System.Management.Automation.SwitchParameter]
		$GetErrorInnerException
	)
	process {
	}
}

function Show-InstallationPrompt {
	[CmdletBinding()]
	param (
		[System.String]
		$Title,
		[System.String]
		$Message,
		[System.String]
		$MessageAlignment,
		[System.String]
		$ButtonRightText,
		[System.String]
		$ButtonLeftText,
		[System.String]
		$ButtonMiddleText,
		[System.String]
		$Icon,
		[System.Management.Automation.SwitchParameter]
		$NoWait,
		[System.Management.Automation.SwitchParameter]
		$PersistPrompt,
		[System.Boolean]
		$MinimizeWindows,
		[System.Int32]
		$Timeout,
		[System.Boolean]
		$ExitOnTimeout,
		[System.Boolean]
		$TopMost
	)
}

function Show-DialogBox {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.String]
		$Text,
		[System.String]
		$Title,
		[System.String]
		$Buttons,
		[System.String]
		$DefaultButton,
		[System.String]
		$Icon,
		[System.String]
		$Timeout,
		[System.Boolean]
		$TopMost
	)
}

function Get-HardwarePlatform {
	[CmdletBinding()]
	param (
		[System.Boolean]
		$ContinueOnError
	)
}

function Get-FreeDiskSpace {
	[CmdletBinding()]
	param (
		[System.String]
		$Drive,
		[System.Boolean]
		$ContinueOnError
	)
}

function Get-InstalledApplication {
	[CmdletBinding()]
	param (
		[System.String[]]
		$Name,
		[System.Management.Automation.SwitchParameter]
		$Exact,
		[System.Management.Automation.SwitchParameter]
		$WildCard,
		[System.Management.Automation.SwitchParameter]
		$RegEx,
		[System.String]
		$ProductCode,
		[System.Management.Automation.SwitchParameter]
		$IncludeUpdatesAndHotfixes
	)
}

function Execute-MSI {
	[CmdletBinding()]
	param (
		[System.String]
		$Action,
		[Parameter(Mandatory = $true)]
		[Alias('FilePath')]
		[System.String]
		$Path,
		[System.String]
		$Transform,
		[Alias('Arguments')]
		[System.String]
		$Parameters,
		[System.String]
		$AddParameters,
		[System.Management.Automation.SwitchParameter]
		$SecureParameters,
		[System.String]
		$Patch,
		[System.String]
		$LoggingOptions,
		[Alias('LogName')]
		[System.String]
		$Private:LogName,
		[System.String]
		$WorkingDirectory,
		[System.Management.Automation.SwitchParameter]
		$SkipMSIAlreadyInstalledCheck,
		[System.Management.Automation.SwitchParameter]
		$IncludeUpdatesAndHotfixes,
		[System.Management.Automation.SwitchParameter]
		$NoWait,
		[System.Management.Automation.SwitchParameter]
		$PassThru,
		[System.String]
		$IgnoreExitCodes,
		[Parameter(Mandatory = $false)]
		$PriorityClass,
		[System.Boolean]
		$ExitOnProcessFailure,
		[System.Boolean]
		$RepairFromSource,
		[System.Boolean]
		$ContinueOnError
	)
}

function Remove-MSIApplication {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Name,
		[System.Management.Automation.SwitchParameter]
		$Exact,
		[System.Management.Automation.SwitchParameter]
		$WildCard,
		[Alias('Arguments')]
		[System.String]
		$Parameters,
		[System.String]
		$AddParameters,
		[System.Array]
		$FilterApplication,
		[System.Array]
		$ExcludeFromUninstall,
		[System.Management.Automation.SwitchParameter]
		$IncludeUpdatesAndHotfixes,
		[System.String]
		$LoggingOptions,
		[Alias('LogName')]
		[System.String]
		$Private:LogName,
		[System.Management.Automation.SwitchParameter]
		$PassThru,
		[System.Boolean]
		$ContinueOnError
	)
}

function Execute-Process {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[Alias('FilePath')]
		[System.String]
		$Path,
		[Alias('Arguments')]
		[System.String[]]
		$Parameters,
		[System.Management.Automation.SwitchParameter]
		$SecureParameters,
		[Parameter(Mandatory = $false)]
		$WindowStyle,
		[System.Management.Automation.SwitchParameter]
		$CreateNoWindow,
		[System.String]
		$WorkingDirectory,
		[System.Management.Automation.SwitchParameter]
		$NoWait,
		[System.Management.Automation.SwitchParameter]
		$PassThru,
		[System.Management.Automation.SwitchParameter]
		$WaitForMsiExec,
		[System.Int32]
		$MsiExecWaitTime,
		[System.String]
		$IgnoreExitCodes,
		[Parameter(Mandatory = $false)]
		$PriorityClass,
		[System.Boolean]
		$ExitOnProcessFailure,
		[System.Boolean]
		$UseShellExecute,
		[System.Boolean]
		$ContinueOnError
	)
}

function Get-MsiExitCodeMessage {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.Int32]
		$MsiExitCode
	)
}

function Test-IsMutexAvailable {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$MutexName,
		[System.Int32]
		$MutexWaitTimeInMilliseconds
	)
}

function New-Folder {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Path,
		[System.Boolean]
		$ContinueOnError
	)
}

function Remove-Folder {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Path,
		[System.Management.Automation.SwitchParameter]
		$DisableRecursion,
		[System.Boolean]
		$ContinueOnError
	)
}

function Copy-File {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.String[]]
		$Path,
		[Parameter(Mandatory = $true, Position = 1)]
		[System.String]
		$Destination,
		[System.Management.Automation.SwitchParameter]
		$Recurse,
		[System.Management.Automation.SwitchParameter]
		$Flatten,
		[System.Boolean]
		$ContinueOnError,
		[System.Boolean]
		$ContinueFileCopyOnError,
		[System.Boolean]
		$UseRobocopy,
		[System.String]
		$RobocopyParams,
		[System.String]
		$RobocopyAdditionalParams
	)
}

function Remove-File {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Path')]
		[System.String[]]
		$Path,
		[Parameter(Mandatory = $true, ParameterSetName = 'LiteralPath')]
		[System.String[]]
		$LiteralPath,
		[System.Management.Automation.SwitchParameter]
		$Recurse,
		[System.Boolean]
		$ContinueOnError
	)
}

function Copy-FileToUserProfile {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
		[System.String[]]
		$Path,
		[Parameter(Mandatory = $false, Position = 2)]
		[System.String]
		$Destination,
		[System.Management.Automation.SwitchParameter]
		$Recurse,
		[System.Management.Automation.SwitchParameter]
		$Flatten,
		[System.Boolean]
		$UseRobocopy,
		[System.String]
		$RobocopyAdditionalParams,
		[System.String[]]
		$ExcludeNTAccount,
		[System.Boolean]
		$ExcludeSystemProfiles,
		[System.Boolean]
		$ExcludeServiceProfiles,
		[System.Management.Automation.SwitchParameter]
		$ExcludeDefaultUser,
		[System.Boolean]
		$ContinueOnError,
		[System.Boolean]
		$ContinueFileCopyOnError
	)
	process {
	}
}

function Remove-FileFromUserProfile {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Path')]
		[System.String[]]
		$Path,
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'LiteralPath')]
		[System.String[]]
		$LiteralPath,
		[System.Management.Automation.SwitchParameter]
		$Recurse,
		[System.String[]]
		$ExcludeNTAccount,
		[System.Boolean]
		$ExcludeSystemProfiles,
		[System.Boolean]
		$ExcludeServiceProfiles,
		[System.Management.Automation.SwitchParameter]
		$ExcludeDefaultUser,
		[System.Boolean]
		$ContinueOnError
	)
}

function Convert-RegistryPath {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Key,
		[System.Management.Automation.SwitchParameter]
		$Wow6432Node,
		[System.String]
		$SID,
		[System.Boolean]
		$DisableFunctionLogging
	)
}

function Test-RegistryValue {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Parameter(Mandatory = $true, Position = 1)]
		[Parameter(Mandatory = $false, Position = 2)]
		[System.String]
		$SID,
		[System.Management.Automation.SwitchParameter]
		$Wow6432Node
	)
	process {
	}
}

function Get-RegistryKey {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Key,
		[System.String]
		$Value,
		[System.Management.Automation.SwitchParameter]
		$Wow6432Node,
		[System.String]
		$SID,
		[System.Management.Automation.SwitchParameter]
		$ReturnEmptyKeyIfExists,
		[System.Management.Automation.SwitchParameter]
		$DoNotExpandEnvironmentNames,
		[System.Boolean]
		$ContinueOnError
	)
}

function Set-RegistryKey {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Key,
		[System.String]
		$Name,
		[System.String]
		$Value,
		[Microsoft.Win32.RegistryValueKind]
		$Type,
		[System.Management.Automation.SwitchParameter]
		$Wow6432Node,
		[System.String]
		$SID,
		[System.Boolean]
		$ContinueOnError
	)
}

function Remove-RegistryKey {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Key,
		[System.String]
		$Name,
		[System.Management.Automation.SwitchParameter]
		$Recurse,
		[System.String]
		$SID,
		[System.Boolean]
		$ContinueOnError
	)
}

function Invoke-HKCURegistrySettingsForAllUser {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.ScriptBlock]
		$RegistrySettings,
		[System.Management.Automation.PSObject[]]
		$UserProfiles
	)
}

function ConvertTo-NTAccountOrSID {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'NTAccountToSID', ValueFromPipelineByPropertyName = $true)]
		[System.String]
		$AccountName,
		[Parameter(Mandatory = $true, ParameterSetName = 'SIDToNTAccount', ValueFromPipelineByPropertyName = $true)]
		[System.String]
		$SID,
		[Parameter(Mandatory = $true, ParameterSetName = 'WellKnownName', ValueFromPipelineByPropertyName = $true)]
		[System.String]
		$WellKnownSIDName,
		[Parameter(Mandatory = $false, ParameterSetName = 'WellKnownName')]
		[System.Management.Automation.SwitchParameter]
		$WellKnownToNTAccount
	)
	process {
	}
}

function Get-UserProfile {
	[CmdletBinding()]
	param (
		[System.String[]]
		$ExcludeNTAccount,
		[System.Boolean]
		$ExcludeSystemProfiles,
		[System.Boolean]
		$ExcludeServiceProfiles,
		[System.Management.Automation.SwitchParameter]
		$ExcludeDefaultUser
	)
}

function Get-FileVersion {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$File,
		[System.Management.Automation.SwitchParameter]
		$ProductVersion,
		[System.Boolean]
		$ContinueOnError
	)
}

function New-Shortcut {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.String]
		$Path,
		[Parameter(Mandatory = $true)]
		[System.String]
		$TargetPath,
		[System.String]
		$Arguments,
		[System.String]
		$IconLocation,
		[System.Int32]
		$IconIndex,
		[System.String]
		$Description,
		[System.String]
		$WorkingDirectory,
		[System.String]
		$WindowStyle,
		[System.Management.Automation.SwitchParameter]
		$RunAsAdmin,
		[System.String]
		$Hotkey,
		[System.Boolean]
		$ContinueOnError
	)
}

function Set-Shortcut {
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Default')]
		[System.String]
		$Path,
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Pipeline')]
		[System.Collections.Hashtable]
		$PathHash,
		[System.String]
		$TargetPath,
		[System.String]
		$Arguments,
		[System.String]
		$IconLocation,
		[System.String]
		$IconIndex,
		[System.String]
		$Description,
		[System.String]
		$WorkingDirectory,
		[System.String]
		$WindowStyle,
		[System.Nullable[System.Boolean]]
		$RunAsAdmin,
		[System.String]
		$Hotkey,
		[System.Boolean]
		$ContinueOnError
	)
	process {
	}
}

function Get-Shortcut {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.String]
		$Path,
		[System.Boolean]
		$ContinueOnError
	)
}

function Execute-ProcessAsUser {
	[CmdletBinding()]
	param (
		[System.String]
		$UserName,
		[Parameter(Mandatory = $true)]
		[System.String]
		$Path,
		[System.String]
		$TempPath,
		[System.String]
		$Parameters,
		[System.Management.Automation.SwitchParameter]
		$SecureParameters,
		[System.String]
		$RunLevel,
		[System.Management.Automation.SwitchParameter]
		$Wait,
		[System.Management.Automation.SwitchParameter]
		$PassThru,
		[System.String]
		$WorkingDirectory,
		[System.Boolean]
		$ContinueOnError
	)
}

function Update-Desktop {
	[CmdletBinding()]
	param (
		[System.Boolean]
		$ContinueOnError
	)
}
Set-Alias -Name 'Refresh-Desktop' -Value 'Update-Desktop' -Scope 'Script' -Force -ErrorAction 'SilentlyContinue'

function Update-SessionEnvironmentVariable {
	[CmdletBinding()]
	param (
		[System.Management.Automation.SwitchParameter]
		$LoadLoggedOnUserEnvironmentVariables,
		[System.Boolean]
		$ContinueOnError
	)
}
Set-Alias -Name 'Refresh-SessionEnvironmentVariables' -Value 'Update-SessionEnvironmentVariables' -Scope 'Script' -Force -ErrorAction 'SilentlyContinue'

function Get-SchedulerTask {
	[CmdletBinding()]
	param (
		[System.String]
		$TaskName,
		[System.Boolean]
		$ContinueOnError
	)
}
if (-not (Get-Command -Name 'Get-ScheduledTask' -ErrorAction 'SilentlyContinue')) {
	New-Alias -Name 'Get-ScheduledTask' -Value 'Get-SchedulerTask'
}

function Block-AppExecution {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String[]]
		$ProcessName
	)
}

function Unblock-AppExecution {
	[CmdletBinding()]
	param (
	)
}

function Get-DeferHistory {
	[CmdletBinding()]
	param (
	)
}

function Set-DeferHistory {
	[CmdletBinding()]
	param (
		[System.String]
		$DeferTimesRemaining,
		[System.String]
		$DeferDeadline
	)
}

function Get-UniversalDate {
	[CmdletBinding()]
	param (
		[System.String]
		$DateTime,
		[System.Boolean]
		$ContinueOnError
	)
}

function Get-RunningProcess {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false, Position = 0)]
		[System.Management.Automation.PSObject[]]
		$ProcessObjects,
		[Parameter(Mandatory = $false, Position = 1)]
		[System.Management.Automation.SwitchParameter]
		$DisableLogging
	)
}

function Show-InstallationWelcome {
	[CmdletBinding(DefaultParametersetName = 'None')]
	param (
		[System.String]
		$CloseApps,
		[System.Management.Automation.SwitchParameter]
		$Silent,
		[System.Int32]
		$CloseAppsCountdown,
		[System.Int32]
		$ForceCloseAppsCountdown,
		[System.Management.Automation.SwitchParameter]
		$PromptToSave,
		[System.Management.Automation.SwitchParameter]
		$PersistPrompt,
		[System.Management.Automation.SwitchParameter]
		$BlockExecution,
		[System.Management.Automation.SwitchParameter]
		$AllowDefer,
		[System.Management.Automation.SwitchParameter]
		$AllowDeferCloseApps,
		[System.Int32]
		$DeferTimes,
		[System.Int32]
		$DeferDays,
		[System.String]
		$DeferDeadline,
		[Parameter(ParameterSetName = 'CheckDiskSpaceParameterSet', Mandatory = $true)]
		[System.Management.Automation.SwitchParameter]
		$CheckDiskSpace,
		[Parameter(ParameterSetName = 'CheckDiskSpaceParameterSet', Mandatory = $false)]
		[System.Int32]
		$RequiredDiskSpace,
		[System.Boolean]
		$MinimizeWindows,
		[System.Boolean]
		$TopMost,
		[System.Int32]
		$ForceCountdown,
		[System.Management.Automation.SwitchParameter]
		$CustomText
	)
}

function Show-WelcomePrompt {
	[CmdletBinding()]
	param (
		[System.String]
		$ProcessDescriptions,
		[System.Int32]
		$CloseAppsCountdown,
		[System.Boolean]
		$ForceCloseAppsCountdown,
		[System.Boolean]
		$PersistPrompt,
		[System.Management.Automation.SwitchParameter]
		$AllowDefer,
		[System.String]
		$DeferTimes,
		[System.String]
		$DeferDeadline,
		[System.Boolean]
		$MinimizeWindows,
		[System.Boolean]
		$TopMost,
		[System.Int32]
		$ForceCountdown,
		[System.Management.Automation.SwitchParameter]
		$CustomText
	)
}

function Show-InstallationRestartPrompt {
	[CmdletBinding()]
	param (
		[System.Int32]
		$CountdownSeconds,
		[System.Int32]
		$CountdownNoHideSeconds,
		[System.Boolean]
		$NoSilentRestart,
		[System.Management.Automation.SwitchParameter]
		$NoCountdown,
		[System.Int32]
		$SilentCountdownSeconds,
		[System.Boolean]
		$TopMost
	)
}

function Show-BalloonTip {
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleTypes', '')]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.String]
		$BalloonTipText,
		[Parameter(Mandatory = $false, Position = 1)]
		[System.String]
		$BalloonTipTitle,
		[Parameter(Mandatory = $false, Position = 2)]
		[System.Windows.Forms.ToolTipIcon]
		$BalloonTipIcon,
		[Parameter(Mandatory = $false, Position = 3)]
		[System.Int32]
		$BalloonTipTime,
		[Parameter(Mandatory = $false, Position = 4)]
		[System.Management.Automation.SwitchParameter]
		$NoWait
	)
}

function Show-InstallationProgress {
	[CmdletBinding()]
	param (
		[System.String]
		$StatusMessage,
		[System.String]
		$WindowLocation,
		[System.Boolean]
		$TopMost,
		[System.Management.Automation.SwitchParameter]
		$Quiet
	)
}

function Close-InstallationProgress {
	[CmdletBinding()]
	param (
		[System.Int32]
		$WaitingTime
	)
}

function Set-PinnedApplication {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Action,
		[Parameter(Mandatory = $true)]
		[System.String]
		$FilePath
	)
}

function Get-IniValue {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$FilePath,
		[Parameter(Mandatory = $true)]
		[System.String]
		$Section,
		[Parameter(Mandatory = $true)]
		[System.String]
		$Key,
		[System.Boolean]
		$ContinueOnError
	)
}

function Set-IniValue {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$FilePath,
		[Parameter(Mandatory = $true)]
		[System.String]
		$Section,
		[Parameter(Mandatory = $true)]
		[System.String]
		$Key,
		[Parameter(Mandatory = $true)]
		[AllowNull()]
		$Value,
		[System.Boolean]
		$ContinueOnError
	)
}

function Get-PEFileArchitecture {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[System.IO.FileInfo[]]
		$FilePath,
		[System.Boolean]
		$ContinueOnError,
		[System.Management.Automation.SwitchParameter]
		$PassThru
	)
	process {
	}
}

function Invoke-RegisterOrUnregisterDLL {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$FilePath,
		[System.String]
		$DLLAction,
		[System.Boolean]
		$ContinueOnError
	)
}
Set-Alias -Name 'Register-DLL' -Value 'Invoke-RegisterOrUnregisterDLL' -Scope 'Script' -Force -ErrorAction 'SilentlyContinue'
Set-Alias -Name 'Unregister-DLL' -Value 'Invoke-RegisterOrUnregisterDLL' -Scope 'Script' -Force -ErrorAction 'SilentlyContinue'

function Invoke-ObjectMethod {
	[CmdletBinding(DefaultParameterSetName = 'Positional')]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.Object]
		$InputObject,
		[Parameter(Mandatory = $true, Position = 1)]
		[System.String]
		$MethodName,
		[Parameter(Mandatory = $false, Position = 2, ParameterSetName = 'Positional')]
		[System.Object[]]
		$ArgumentList,
		[Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'Named')]
		[System.Collections.Hashtable]
		$Parameter
	)
}

function Get-ObjectProperty {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.Object]
		$InputObject,
		[Parameter(Mandatory = $true, Position = 1)]
		[System.String]
		$PropertyName,
		[Parameter(Mandatory = $false, Position = 2)]
		[System.Object[]]
		$ArgumentList
	)
}

function Get-MsiTableProperty {
	[CmdletBinding(DefaultParameterSetName = 'TableInfo')]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Path,
		[System.String[]]
		$TransformPath,
		[Parameter(Mandatory = $false, ParameterSetName = 'TableInfo')]
		[System.String]
		$Table,
		[Parameter(Mandatory = $false, ParameterSetName = 'TableInfo')]
		[System.Int32]
		$TablePropertyNameColumnNum,
		[Parameter(Mandatory = $false, ParameterSetName = 'TableInfo')]
		[System.Int32]
		$TablePropertyValueColumnNum,
		[Parameter(Mandatory = $true, ParameterSetName = 'SummaryInfo')]
		[System.Management.Automation.SwitchParameter]
		$GetSummaryInformation,
		[System.Boolean]
		$ContinueOnError
	)
}

function Set-MsiProperty {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.__ComObject]
		$DataBase,
		[Parameter(Mandatory = $true)]
		[System.String]
		$PropertyName,
		[Parameter(Mandatory = $true)]
		[System.String]
		$PropertyValue,
		[System.Boolean]
		$ContinueOnError
	)
}

function New-MsiTransform {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$MsiPath,
		[System.String]
		$ApplyTransformPath,
		[System.String]
		$NewTransformPath,
		[Parameter(Mandatory = $true)]
		[System.Collections.Hashtable]
		$TransformProperties,
		[System.Boolean]
		$ContinueOnError
	)
}

function Test-MSUpdate {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.String]
		$KBNumber,
		[Parameter(Mandatory = $false, Position = 1)]
		[System.Boolean]
		$ContinueOnError
	)
}

function Install-MSUpdate {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Directory
	)
}

function Get-WindowTitle {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'SearchWinTitle')]
		[AllowEmptyString()]
		[System.String]
		$WindowTitle,
		[Parameter(Mandatory = $true, ParameterSetName = 'GetAllWinTitles')]
		[System.Management.Automation.SwitchParameter]
		$GetAllWindowTitles,
		[System.Management.Automation.SwitchParameter]
		$DisableFunctionLogging
	)
}

function Send-Key {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false, Position = 0)]
		[AllowEmptyString()]
		[System.String]
		$WindowTitle,
		[Parameter(Mandatory = $false, Position = 1)]
		[System.Management.Automation.SwitchParameter]
		$GetAllWindowTitles,
		[Parameter(Mandatory = $false, Position = 2)]
		[System.IntPtr]
		$WindowHandle,
		[Parameter(Mandatory = $false, Position = 3)]
		[System.String]
		$Keys,
		[Parameter(Mandatory = $false, Position = 4)]
		[System.Int32]
		$WaitSeconds
	)
}

function Test-Battery {
	[CmdletBinding()]
	param (
		[System.Management.Automation.SwitchParameter]
		$PassThru
	)
}

function Test-NetworkConnection {
	[CmdletBinding()]
	param (
	)
}

function Test-PowerPoint {
	[CmdletBinding()]
	param (
	)
}

function Invoke-SCCMTask {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$ScheduleID,
		[System.Boolean]
		$ContinueOnError
	)
}

function Install-SCCMSoftwareUpdate {
	[CmdletBinding()]
	param (
		[System.Int32]
		$SoftwareUpdatesScanWaitInSeconds,
		[System.TimeSpan]
		$WaitForPendingUpdatesTimeout,
		[System.Boolean]
		$ContinueOnError
	)
}

function Update-GroupPolicy {
	[CmdletBinding()]
	param (
		[System.Boolean]
		$ContinueOnError
	)
}

function Enable-TerminalServerInstallMode {
	[CmdletBinding()]
	param (
		[System.Boolean]
		$ContinueOnError
	)
}

function Disable-TerminalServerInstallMode {
	[CmdletBinding()]
	param (
		[System.Boolean]
		$ContinueOnError
	)
}

function Set-ActiveSetup {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Create')]
		[System.String]
		$StubExePath,
		[Parameter(Mandatory = $false, ParameterSetName = 'Create')]
		[System.String]
		$Arguments,
		[Parameter(Mandatory = $false, ParameterSetName = 'Create')]
		[System.String]
		$Description,
		[System.String]
		$Key,
		[System.Management.Automation.SwitchParameter]
		$Wow6432Node,
		[Parameter(Mandatory = $false, ParameterSetName = 'Create')]
		[System.String]
		$Version,
		[Parameter(Mandatory = $false, ParameterSetName = 'Create')]
		[System.String]
		$Locale,
		[Parameter(Mandatory = $false, ParameterSetName = 'Create')]
		[System.Management.Automation.SwitchParameter]
		$DisableActiveSetup,
		[Parameter(Mandatory = $true, ParameterSetName = 'Purge')]
		[System.Management.Automation.SwitchParameter]
		$PurgeActiveSetupKey,
		[Parameter(Mandatory = $false, ParameterSetName = 'Create')]
		[System.Boolean]
		$ExecuteForCurrentUser,
		[System.Boolean]
		$ContinueOnError
	)
}

function Test-ServiceExist {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Name,
		[System.String]
		$ComputerName,
		[System.Management.Automation.SwitchParameter]
		$PassThru,
		[System.Boolean]
		$ContinueOnError
	)
}

function Stop-ServiceAndDependency {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Name,
		[System.String]
		$ComputerName,
		[System.Management.Automation.SwitchParameter]
		$SkipServiceExistsTest,
		[System.Management.Automation.SwitchParameter]
		$SkipDependentServices,
		[System.TimeSpan]
		$PendingStatusWait,
		[System.Management.Automation.SwitchParameter]
		$PassThru,
		[System.Boolean]
		$ContinueOnError
	)
}

function Start-ServiceAndDependency {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Name,
		[System.String]
		$ComputerName,
		[System.Management.Automation.SwitchParameter]
		$SkipServiceExistsTest,
		[System.Management.Automation.SwitchParameter]
		$SkipDependentServices,
		[System.TimeSpan]
		$PendingStatusWait,
		[System.Management.Automation.SwitchParameter]
		$PassThru,
		[System.Boolean]
		$ContinueOnError
	)
}

function Get-ServiceStartMode {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Name,
		[System.String]
		$ComputerName,
		[System.Boolean]
		$ContinueOnError
	)
}

function Set-ServiceStartMode {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Name,
		[System.String]
		$ComputerName,
		[Parameter(Mandatory = $true)]
		[System.String]
		$StartMode,
		[System.Boolean]
		$ContinueOnError
	)
}

function Get-LoggedOnUser {
	[CmdletBinding()]
	param (
	)
}

function Get-PendingReboot {
	[CmdletBinding()]
	param (
	)
}

function Set-ItemPermission {
	[CmdletBinding()]
	param (
		[Parameter( Mandatory = $true, Position = 0, ParameterSetName = 'DisableInheritance' )]
		[Parameter( Mandatory = $true, Position = 0, ParameterSetName = 'EnableInheritance' )]
		[Alias('File', 'Folder')]
		[System.String]
		$Path,
		[Parameter( Mandatory = $true, Position = 1, ParameterSetName = 'DisableInheritance')]
		[Alias('Username', 'Users', 'SID', 'Usernames')]
		[System.String[]]
		$User,
		[Parameter( Mandatory = $true, Position = 2, ParameterSetName = 'DisableInheritance')]
		[Alias('Acl', 'Grant', 'Permissions', 'Deny')]
		[System.String[]]
		$Permission,
		[Parameter( Mandatory = $false, Position = 3, ParameterSetName = 'DisableInheritance')]
		[Alias('AccessControlType')]
		[System.String]
		$PermissionType,
		[Parameter( Mandatory = $false, Position = 4, ParameterSetName = 'DisableInheritance')]
		[System.String[]]
		$Inheritance,
		[Parameter( Mandatory = $false, Position = 5, ParameterSetName = 'DisableInheritance')]
		[System.String]
		$Propagation,
		[Parameter( Mandatory = $false, Position = 6, ParameterSetName = 'DisableInheritance')]
		[Alias('ApplyMethod', 'ApplicationMethod')]
		[System.String]
		$Method,
		[Parameter( Mandatory = $true, Position = 1, ParameterSetName = 'EnableInheritance')]
		[System.Management.Automation.SwitchParameter]
		$EnableInheritance
	)
}

function Copy-ContentToCache {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false, Position = 0)]
		[System.String]
		$Path
	)
}

function Remove-ContentFromCache {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false, Position = 0)]
		[System.String]
		$Path
	)
}

function Configure-EdgeExtension {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Add')]
		[System.Management.Automation.SwitchParameter]
		$Add,
		[Parameter(Mandatory = $true, ParameterSetName = 'Remove')]
		[System.Management.Automation.SwitchParameter]
		$Remove,
		[Parameter(Mandatory = $true, ParameterSetName = 'Add')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Remove')]
		[System.String]
		$ExtensionID,
		[Parameter(Mandatory = $true, ParameterSetName = 'Add')]
		[System.String]
		$InstallationMode,
		[Parameter(Mandatory = $true, ParameterSetName = 'Add')]
		[System.String]
		$UpdateUrl,
		[Parameter(Mandatory = $false, ParameterSetName = 'Add')]
		[System.String]
		$MinimumVersionRequired
	)
}

function Add-NxtContent {
	[CmdletBinding()]
	param (
		[System.String]
		$Path,
		[System.String]
		$Value,
		[ValidateSet('Ascii', 'Default', 'UTF7', 'BigEndianUnicode', 'Oem', 'Unicode', 'UTF32', 'UTF8')]
		[System.String]
		$Encoding,
		[ValidateSet('Ascii', 'Default', 'UTF7', 'BigEndianUnicode', 'Oem', 'Unicode', 'UTF32', 'UTF8')]
		[System.String]
		$DefaultEncoding
	)
}

function Add-NxtLocalGroup {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$GroupName,
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Description,
		[System.String]
		$COMPUTERNAME
	)
}

function Add-NxtLocalGroupMember {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$GroupName,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$MemberName,
		[System.String]
		$COMPUTERNAME
	)
}

function Add-NxtLocalUser {
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	param (
		[Parameter(ParameterSetName = 'Default', Mandatory = $true)]
		[Parameter(ParameterSetName = 'SetPwdNeverExpires', Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$UserName,
		[Parameter(ParameterSetName = 'Default', Mandatory = $true)]
		[Parameter(ParameterSetName = 'SetPwdNeverExpires', Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Security.SecureString]
		$Password,
		[ValidateNotNullOrEmpty()]
		[System.String]
		$FullName,
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Description,
		[Parameter(ParameterSetName = 'Default', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.SwitchParameter]
		$SetPwdExpired,
		[Parameter(ParameterSetName = 'SetPwdNeverExpires', Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.SwitchParameter]
		$SetPwdNeverExpires,
		[System.String]
		$COMPUTERNAME
	)
}

function Add-NxtProcessPathVariable {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Path,
		[System.Boolean]
		$AddToBeginning
	)
}

function Add-NxtSystemPathVariable {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Path,
		[System.Boolean]
		$AddToBeginning
	)
}

function Add-NxtXmlNode {
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$FilePath,
		[Parameter(Mandatory = $true)]
		[System.String]
		$NodePath,
		[System.Collections.Hashtable]
		$Attributes,
		[System.String]
		$InnerText,
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[System.String]
		$Encoding,
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[System.String]
		$DefaultEncoding
	)
}

function Block-NxtAppExecution {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[System.String[]]
		$ProcessName,
		[ValidateNotNullorEmpty()]
		[System.String]
		$BlockScriptLocation,
		[ValidateNotNullorEmpty()]
		[System.String]
		$ScriptDirectory,
		[ValidateNotNullorEmpty()]
		[System.String]
		$RegKeyAppExecution
	)
}

function Compare-NxtVersion {
	[CmdletBinding()]
	param (
		[System.String]
		$DetectedVersion,
		[System.String]
		$TargetVersion,
		[System.Boolean]
		$HexMode
	)
}

function ConvertFrom-NxtEscapedString {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[Alias('EscapedString')]
		[System.String]
		$InputString
	)
}

function Exit-NxtAbortReboot {
	[CmdletBinding()]
	param (
		[System.String]
		$PackageMachineKey,
		[System.String]
		$PackageUninstallKey,
		[System.String]
		$RebootMessage,
		[System.Int32]
		$RebootExitCode,
		[System.String]
		$PackageStatus,
		[System.String]
		$EmpirumMachineKey,
		[System.String]
		$EmpirumUninstallKey
	)
}

function Exit-NxtScriptWithError {
	[CmdletBinding()]
	param (
		[System.String]
		$RegisterPackage,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$ErrorMessage,
		[System.String]
		$ErrorMessagePSADT,
		[System.String]
		$PackageGUID,
		[System.String]
		$RegPackagesKey,
		[System.String]
		$App,
		[System.String]
		$DeploymentTimestamp,
		[System.String]
		$DebugLogFile,
		[System.String]
		$AppVendor,
		[System.String]
		$AppArch,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Int32]
		$MainExitCode,
		[System.String]
		$PackageStatus,
		[System.String]
		$AppRevision,
		[System.String]
		$ScriptParentPath,
		[System.String]
		$EnvArchitecture,
		[System.String]
		$EnvUserDomain,
		[System.String]
		$EnvUserName,
		[System.String]
		$ProcessNTAccountSID,
		[System.Boolean]
		$UninstallOld,
		[System.Boolean]
		$UserPartOnInstallation,
		[System.Boolean]
		$UserPartOnUnInstallation,
		[System.String]
		$TempRootFolder,
		[System.Int32]
		$HoursToKeep,
		[System.String[]]
		$NxtTempDirectories,
		[System.Boolean]
		$BlockExecution,
		[ValidateNotNullOrEmpty()]
		[System.String]
		$DeploymentType
	)
}

function Get-NxtCurrentDisplayVersion {
	[CmdletBinding()]
	param (
		[System.String]
		$UninstallKey,
		[System.Boolean]
		$UninstallKeyIsDisplayName,
		[System.Boolean]
		$UninstallKeyContainsWildCards,
		[System.Array]
		$DisplayNamesToExclude,
		[System.String]
		$InstallMethod
	)
}

function Get-NxtFileVersion {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$FilePath
	)
}

function Get-NxtProcessEnvironmentVariable {
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Key
	)
}

function Get-NxtProcessTree {
	param (
		[Parameter(Mandatory = $true)]
		[System.Int32]
		$ProcessId,
		[System.Boolean]
		$IncludeChildProcesses,
		[System.Boolean]
		$IncludeParentProcesses
	)
}

function Get-NxtRegisteredPackage {
	[CmdletBinding()]
	param (
		[System.String]
		$PackageGUID,
		[System.String]
		$ProductGUID,
		[System.String]
		[ValidateSet('0', '1')]
		$InstalledState,
		[System.String]
		$RegPackagesKey
	)
}

function Get-NxtSidByName {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$UserName
	)
}

function Get-NxtSystemEnvironmentVariable {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Key
	)
}

function Import-NxtIniFile {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[System.String]
		$Path,
		[System.Boolean]
		$ContinueOnError
	)
}

function Import-NxtIniFileWithComment {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[System.String]
		$Path,
		[System.Boolean]
		$ContinueOnError
	)
}

function Import-NxtXmlFile {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[System.String]
		$Path,
		[System.String]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		$Encoding,
		[System.String]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		$DefaultEncoding,
		[System.Boolean]
		$ContinueOnError
	)
}

function Install-NxtApplication {
	[CmdletBinding()]
	param (
		[System.String]
		$AppName,
		[System.String]
		$UninstallKey,
		[System.Boolean]
		$UninstallKeyIsDisplayName,
		[System.Boolean]
		$UninstallKeyContainsWildCards,
		[System.Array]
		$DisplayNamesToExclude,
		[System.String]
		$InstLogFile,
		[System.String]
		$InstFile,
		[System.String]
		$InstPara,
		[System.Boolean]
		$AppendInstParaToDefaultParameters,
		[System.String]
		$AcceptedInstallExitCodes,
		[System.String]
		$AcceptedInstallRebootCodes,
		[System.String]
		$InstallMethod,
		[System.String]
		$UninstallMethod,
		[System.Int32]
		$PreSuccessCheckTotalSecondsToWaitFor,
		[System.String]
		$PreSuccessCheckProcessOperator,
		[System.Array]
		$PreSuccessCheckProcessesToWaitFor,
		[System.String]
		$PreSuccessCheckRegKeyOperator,
		[System.Array]
		$PreSuccessCheckRegkeysToWaitFor,
		[System.String]
		$UninsBackupPath
	)
}

function Move-NxtItem {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Path,
		[Parameter(Mandatory = $true)]
		[System.String]
		$Destination,
		[System.Management.Automation.SwitchParameter]
		$Force,
		[ValidateNotNullOrEmpty()]
		[System.Boolean]
		$ContinueOnError
	)
}

function New-NxtFolderWithPermission {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Path,
		[System.Security.Principal.WellKnownSidType[]]
		$FullControlPermissions,
		[System.Security.Principal.WellKnownSidType[]]
		$WritePermissions,
		[System.Security.Principal.WellKnownSidType[]]
		$ModifyPermissions,
		[System.Security.Principal.WellKnownSidType[]]
		$ReadAndExecutePermissions,
		[System.Security.Principal.WellKnownSidType]
		$Owner,
		[System.Security.AccessControl.DirectorySecurity]
		$CustomDirectorySecurity,
		[System.Boolean]
		$Hidden,
		[System.Boolean]
		$ProtectRules
	)
}

function Read-NxtSingleXmlNode {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$XmlFilePath,
		[Parameter(Mandatory = $true)]
		[System.String]
		$SingleNodeName,
		[System.String]
		$AttributeName,
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[System.String]
		$Encoding,
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[System.String]
		$DefaultEncoding
	)
}

function Remove-NxtIniValue {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[System.String]
		$FilePath,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[System.String]
		$Section,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[System.String]
		$Key,
		[ValidateNotNullorEmpty()]
		[System.Boolean]
		$ContinueOnError
	)
}

function Remove-NxtLocalGroup {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$GroupName,
		[System.String]
		$COMPUTERNAME
	)
}

function Remove-NxtLocalGroupMember {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$GroupName,
		[Parameter(ParameterSetName = 'SingleMember')]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$MemberName,
		[Parameter(ParameterSetName = 'All')]
		[System.Management.Automation.SwitchParameter]
		$AllMember,
		[System.String]
		$COMPUTERNAME
	)
}

function Remove-NxtLocalUser {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$UserName,
		[System.String]
		$COMPUTERNAME
	)
}

function Remove-NxtProcessEnvironmentVariable {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Key
	)
}

function Remove-NxtProcessPathVariable {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Path
	)
}

function Remove-NxtSystemPathVariable {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Path
	)
}

function Remove-NxtSystemEnvironmentVariable {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Key
	)
}

function Save-NxtXmlFile {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Path,
		[Parameter(Mandatory = $true)]
		[System.Xml.XmlDocument]
		$Xml,
		[System.String]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		$Encoding,
		[System.String]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		$DefaultEncoding
	)
}

function Set-NxtFolderPermission {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Path,
		[System.Security.Principal.WellKnownSidType[]]
		$FullControlPermissions,
		[System.Security.Principal.WellKnownSidType[]]
		$WritePermissions,
		[System.Security.Principal.WellKnownSidType[]]
		$ModifyPermissions,
		[System.Security.Principal.WellKnownSidType[]]
		$ReadAndExecutePermissions,
		[System.Security.Principal.WellKnownSidType]
		$Owner,
		[System.Security.AccessControl.DirectorySecurity]
		$CustomDirectorySecurity,
		[System.Boolean]
		$BreakInheritance,
		[System.Boolean]
		$EnforceInheritanceOnSubFolders
	)
}

function Set-NxtIniValue {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$FilePath,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Section,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Key,
		[Parameter(Mandatory = $true)]
		[ValidateScript({
				if ($false -eq (($_.GetType().Name -eq 'String') -or ($null -eq $_))) {
					throw "'$_' is not a string or null."
				}
				$true
			})]
		[AllowNull()]
		$Value,
		[ValidateNotNullOrEmpty()]
		[System.Boolean]
		$ContinueOnError,
		[ValidateNotNullOrEmpty()]
		[System.Boolean]
		$Create
	)
}

function Set-NxtProcessEnvironmentVariable {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Key,
		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[System.String]
		$Value
	)
}

function Set-NxtSystemEnvironmentVariable {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Key,
		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[System.String]
		$Value
	)
}

function Set-NxtXmlNode {
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$FilePath,
		[Parameter(Mandatory = $true)]
		[System.String]
		$NodePath,
		[System.Collections.Hashtable]
		$Attributes,
		[System.Collections.Hashtable]
		$FilterAttributes,
		[System.String]
		$InnerText,
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[System.String]
		$Encoding,
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[System.String]
		$DefaultEncoding
	)
}

function Show-NxtInstallationWelcome {
	[CmdletBinding()]
	param (
		[System.Management.Automation.SwitchParameter]
		$Silent,
		[ValidateNotNullorEmpty()]
		[System.Int32]
		$CloseAppsCountdown,
		[ValidateNotNullorEmpty()]
		[System.Int32]
		$ForceCloseAppsCountdown,
		[System.Management.Automation.SwitchParameter]
		$PromptToSave,
		[System.Management.Automation.SwitchParameter]
		$PersistPrompt,
		[System.Management.Automation.SwitchParameter]
		$BlockExecution,
		[System.Management.Automation.SwitchParameter]
		$AllowDefer,
		[System.Management.Automation.SwitchParameter]
		$AllowDeferCloseApps,
		[ValidateNotNullorEmpty()]
		[System.Int32]
		$DeferTimes,
		[ValidateNotNullorEmpty()]
		[System.Int32]
		$DeferDays,
		[System.String]
		$DeferDeadline,
		[ValidateNotNullorEmpty()]
		[System.Boolean]
		$MinimizeWindows,
		[ValidateNotNullorEmpty()]
		[System.Boolean]
		$TopMost,
		[ValidateNotNullorEmpty()]
		[System.Int32]
		$ForceCountdown,
		[System.Management.Automation.SwitchParameter]
		$CustomText,
		[Parameter(Mandatory = $true)]
		[System.Boolean]
		$IsInstall,
		[System.Array]
		$AskKillProcessApps,
		[ValidateNotNullorEmpty()]
		[PSADTNXT.ContinueType]
		$ContinueType,
		[System.Boolean]
		$ForceContinueAfterDeferrals,
		[System.Management.Automation.SwitchParameter]
		$UserCanCloseAll,
		[System.Management.Automation.SwitchParameter]
		$UserCanAbort,
		[System.Management.Automation.SwitchParameter]
		$ApplyContinueTypeOnError,
		[System.String]
		$ScriptRoot,
		[System.Int32]
		$ProcessIdToIgnore,
		[System.String]
		$BlockScriptLocation
	)
}

function Stop-NxtProcess {
	[CmdletBinding(DefaultParameterSetName = 'Name')]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Name', Position = 0)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Name,
		[Parameter(Mandatory = $false, ParameterSetName = 'Name', Position = 1)]
		[System.Boolean]
		$IsWql,
		[Parameter(Mandatory = $true, ParameterSetName = 'Id')]
		[Alias('ProcessId')]
		[System.Int32]
		$Id
	)
}

function Test-NxtFolderPermission {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Path,
		[System.Security.Principal.WellKnownSidType[]]
		$FullControlPermissions,
		[System.Security.Principal.WellKnownSidType[]]
		$WritePermissions,
		[System.Security.Principal.WellKnownSidType[]]
		$ModifyPermissions,
		[System.Security.Principal.WellKnownSidType[]]
		$ReadAndExecutePermissions,
		[System.Security.Principal.WellKnownSidType]
		$Owner,
		[System.Security.AccessControl.DirectorySecurity]
		$CustomDirectorySecurity,
		[System.Boolean]
		$CheckIsInherited,
		[System.Boolean]
		$IsInherited
	)
}

function Test-NxtProcessExist {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$ProcessName,
		[System.Management.Automation.SwitchParameter]
		$IsWql
	)
}

function Test-NxtStringInFile {
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Path,
		[Parameter(Mandatory = $true)]
		[System.String]
		$SearchString,
		[System.Boolean]
		$ContainsRegex,
		[System.Boolean]
		$IgnoreCase,
		[ValidateSet('Ascii', 'Default', 'UTF7', 'BigEndianUnicode', 'Oem', 'Unicode', 'UTF32', 'UTF8')]
		[System.String]
		$Encoding,
		[ValidateSet('Ascii', 'Default', 'UTF7', 'BigEndianUnicode', 'Oem', 'Unicode', 'UTF32', 'UTF8')]
		[System.String]
		$DefaultEncoding
	)
}

function Uninstall-NxtApplication {
	[CmdletBinding()]
	param (
		[System.String]
		$AppName,
		[System.String]
		$UninstallKey,
		[System.Boolean]
		$UninstallKeyIsDisplayName,
		[System.Boolean]
		$UninstallKeyContainsWildCards,
		[System.Array]
		$DisplayNamesToExclude,
		[System.String]
		$UninstLogFile,
		[System.String]
		$UninstFile,
		[System.String]
		$UninstPara,
		[System.Boolean]
		$AppendUninstParaToDefaultParameters,
		[System.String]
		$AcceptedUninstallExitCodes,
		[System.String]
		$AcceptedUninstallRebootCodes,
		[System.String]
		$UninstallMethod,
		[System.Int32]
		$PreSuccessCheckTotalSecondsToWaitFor,
		[System.String]
		$PreSuccessCheckProcessOperator,
		[System.Array]
		$PreSuccessCheckProcessesToWaitFor,
		[System.String]
		$PreSuccessCheckRegKeyOperator,
		[System.Array]
		$PreSuccessCheckRegkeysToWaitFor,
		[System.String]
		$DirFiles,
		[System.String]
		$UninsBackupPath
	)
}

function Update-NxtTextInFile {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Path,
		[Parameter(Mandatory = $true)]
		[System.String]
		$SearchString,
		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[System.String]
		$ReplaceString,
		[System.Int32]
		$Count,
		[ValidateSet('Ascii', 'Default', 'UTF7', 'BigEndianUnicode', 'Oem', 'Unicode', 'UTF32', 'UTF8')]
		[System.String]
		$Encoding,
		[ValidateSet('Ascii', 'Default', 'UTF7', 'BigEndianUnicode', 'Oem', 'Unicode', 'UTF32', 'UTF8')]
		[System.String]
		$DefaultEncoding,
		[System.Boolean]
		$AddBOMIfUTF8
	)
}

function Update-NxtXmlNode {
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$FilePath,
		[Parameter(Mandatory = $true)]
		[System.String]
		$NodePath,
		[System.Collections.Hashtable]
		$Attributes,
		[System.Collections.Hashtable]
		$FilterAttributes,
		[System.String]
		$InnerText,
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[System.String]
		$Encoding,
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[System.String]
		$DefaultEncoding
	)
}

function Watch-NxtFile {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$FileName,
		[System.Int32]
		$Timeout
	)
}

function Watch-NxtFileIsRemoved {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$FileName,
		[System.Int32]
		$Timeout
	)
}

function Watch-NxtProcess {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$ProcessName,
		[System.Int32]
		$Timeout,
		[System.Management.Automation.SwitchParameter]
		$IsWql
	)
}

function Watch-NxtProcessIsStopped {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$ProcessName,
		[System.Int32]
		$Timeout,
		[System.Management.Automation.SwitchParameter]
		$IsWql
	)
}

function Watch-NxtRegistryKey {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$RegistryKey,
		[System.Int32]
		$Timeout
	)
}

function Watch-NxtRegistryKeyIsRemoved {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$RegistryKey,
		[System.Int32]
		$Timeout
	)
}
