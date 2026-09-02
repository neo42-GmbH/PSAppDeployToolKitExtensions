[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('Measure-NXTDeprecatedType', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('Measure-NXTCustomMigration', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('Measure-NXTDeprecatedVariable', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('Measure-NXTDeprecatedFunction', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSNxtAvoidBaseTypes', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

#region PSAppDeployToolkit v3.10.2 Function Definitions
function Write-FunctionHeaderOrFooter {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$CmdletName,
		[Parameter(Mandatory = $true, ParameterSetName = 'Header')]
		[AllowEmptyCollection()]
		[System.Collections.Hashtable]$CmdletBoundParameters,
		[Parameter(Mandatory = $true, ParameterSetName = 'Header')]
		[System.Management.Automation.SwitchParameter]$Header,
		[Parameter(Mandatory = $true, ParameterSetName = 'Footer')]
		[System.Management.Automation.SwitchParameter]$Footer
	)
}

function Execute-MSP {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[Alias('FilePath')]
		[System.String]$Path,
		[Parameter(Mandatory = $false)]
		[System.String]$AddParameters
	)
}

function Write-Log {
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '')]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyCollection()]
		[Alias('Text')]
		[System.String[]]$Message,
		[Parameter(Mandatory = $false, Position = 1)]
		[System.Int16]$Severity,
		[Parameter(Mandatory = $false, Position = 2)]
		[System.String]$Source,
		[Parameter(Mandatory = $false, Position = 3)]
		[System.String]$ScriptSection,
		[Parameter(Mandatory = $false, Position = 4)]
		[System.String]$LogType,
		[Parameter(Mandatory = $false, Position = 5)]
		[System.String]$LogFileDirectory,
		[Parameter(Mandatory = $false, Position = 6)]
		[System.String]$LogFileName,
		[Parameter(Mandatory = $false, Position = 7)]
		[System.Boolean]$AppendToLogFile,
		[Parameter(Mandatory = $false, Position = 8)]
		[System.Int32]$MaxLogHistory,
		[Parameter(Mandatory = $false, Position = 9)]
		[System.Decimal]$MaxLogFileSizeMB,
		[Parameter(Mandatory = $false, Position = 10)]
		[System.Boolean]$ContinueOnError,
		[Parameter(Mandatory = $false, Position = 11)]
		[System.Boolean]$WriteHost,
		[Parameter(Mandatory = $false, Position = 12)]
		[System.Management.Automation.SwitchParameter]$PassThru,
		[Parameter(Mandatory = $false, Position = 13)]
		[System.Management.Automation.SwitchParameter]$DebugMessage,
		[Parameter(Mandatory = $false, Position = 14)]
		[System.Boolean]$LogDebugMessage
	)
	process {
	}
}

function Remove-InvalidFileNameChar {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyString()]
		[System.String]$Name
	)
	process {
	}
}

function New-ZipFile {
	[CmdletBinding(DefaultParameterSetName = 'CreateFromDirectory')]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.String]$DestinationArchiveDirectoryPath,
		[Parameter(Mandatory = $true, Position = 1)]
		[System.String]$DestinationArchiveFileName,
		[Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'CreateFromDirectory')]
		[System.String[]]$SourceDirectoryPath,
		[Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'CreateFromFile')]
		[System.String[]]$SourceFilePath,
		[Parameter(Mandatory = $false, Position = 3)]
		[System.Management.Automation.SwitchParameter]$RemoveSourceAfterArchiving,
		[Parameter(Mandatory = $false, Position = 4)]
		[System.Management.Automation.SwitchParameter]$OverWriteArchive,
		[Parameter(Mandatory = $false, Position = 5)]
		[System.Boolean]$ContinueOnError
	)
}

function Exit-Script {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.Int32]$ExitCode
	)
}

function Resolve-Error {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyCollection()]
		[System.Array]$ErrorRecord,
		[Parameter(Mandatory = $false, Position = 1)]
		[System.String[]]$Property,
		[Parameter(Mandatory = $false, Position = 2)]
		[System.Management.Automation.SwitchParameter]$GetErrorRecord,
		[Parameter(Mandatory = $false, Position = 3)]
		[System.Management.Automation.SwitchParameter]$GetErrorInvocation,
		[Parameter(Mandatory = $false, Position = 4)]
		[System.Management.Automation.SwitchParameter]$GetErrorException,
		[Parameter(Mandatory = $false, Position = 5)]
		[System.Management.Automation.SwitchParameter]$GetErrorInnerException
	)
	process {
	}
}

function Show-InstallationPrompt {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.String]$Title,
		[Parameter(Mandatory = $false)]
		[System.String]$Message,
		[Parameter(Mandatory = $false)]
		[System.String]$MessageAlignment,
		[Parameter(Mandatory = $false)]
		[System.String]$ButtonRightText,
		[Parameter(Mandatory = $false)]
		[System.String]$ButtonLeftText,
		[Parameter(Mandatory = $false)]
		[System.String]$ButtonMiddleText,
		[Parameter(Mandatory = $false)]
		[System.String]$Icon,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$NoWait,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$PersistPrompt,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$MinimizeWindows,
		[Parameter(Mandatory = $false)]
		[System.Int32]$Timeout,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ExitOnTimeout,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$TopMost
	)
}

function Show-DialogBox {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.String]$Text,
		[Parameter(Mandatory = $false)]
		[System.String]$Title,
		[Parameter(Mandatory = $false)]
		[System.String]$Buttons,
		[Parameter(Mandatory = $false)]
		[System.String]$DefaultButton,
		[Parameter(Mandatory = $false)]
		[System.String]$Icon,
		[Parameter(Mandatory = $false)]
		[System.String]$Timeout,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$TopMost
	)
}

function Get-HardwarePlatform {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Get-FreeDiskSpace {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.String]$Drive,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Get-InstalledApplication {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.String[]]$Name,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$Exact,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$WildCard,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$RegEx,
		[Parameter(Mandatory = $false)]
		[System.String]$ProductCode,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$IncludeUpdatesAndHotfixes
	)
}

function Execute-MSI {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.String]$Action,
		[Parameter(Mandatory = $true)]
		[Alias('FilePath')]
		[System.String]$Path,
		[Parameter(Mandatory = $false)]
		[System.String]$Transform,
		[Parameter(Mandatory = $false)]
		[Alias('Arguments')]
		[System.String]$Parameters,
		[Parameter(Mandatory = $false)]
		[System.String]$AddParameters,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$SecureParameters,
		[Parameter(Mandatory = $false)]
		[System.String]$Patch,
		[Parameter(Mandatory = $false)]
		[System.String]$LoggingOptions,
		[Parameter(Mandatory = $false)]
		[Alias('LogName')]
		[System.String]$Private:LogName,
		[Parameter(Mandatory = $false)]
		[System.String]$WorkingDirectory,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$SkipMSIAlreadyInstalledCheck,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$IncludeUpdatesAndHotfixes,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$NoWait,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$PassThru,
		[Parameter(Mandatory = $false)]
		[System.String]$IgnoreExitCodes,
		[Parameter(Mandatory = $false)]$PriorityClass,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ExitOnProcessFailure,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$RepairFromSource,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Remove-MSIApplication {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$Name,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$Exact,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$WildCard,
		[Parameter(Mandatory = $false)]
		[Alias('Arguments')]
		[System.String]$Parameters,
		[Parameter(Mandatory = $false)]
		[System.String]$AddParameters,
		[Parameter(Mandatory = $false)]
		[System.Array]$FilterApplication,
		[Parameter(Mandatory = $false)]
		[System.Array]$ExcludeFromUninstall,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$IncludeUpdatesAndHotfixes,
		[Parameter(Mandatory = $false)]
		[System.String]$LoggingOptions,
		[Parameter(Mandatory = $false)]
		[Alias('LogName')]
		[System.String]$Private:LogName,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$PassThru,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Execute-Process {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[Alias('FilePath')]
		[System.String]$Path,
		[Parameter(Mandatory = $false)]
		[Alias('Arguments')]
		[System.String[]]$Parameters,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$SecureParameters,
		[Parameter(Mandatory = $false)]$WindowStyle,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$CreateNoWindow,
		[Parameter(Mandatory = $false)]
		[System.String]$WorkingDirectory,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$NoWait,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$PassThru,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$WaitForMsiExec,
		[Parameter(Mandatory = $false)]
		[System.Int32]$MsiExecWaitTime,
		[Parameter(Mandatory = $false)]
		[System.String]$IgnoreExitCodes,
		[Parameter(Mandatory = $false)]$PriorityClass,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ExitOnProcessFailure,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$UseShellExecute,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Get-MsiExitCodeMessage {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.Int32]$MsiExitCode
	)
}

function Test-IsMutexAvailable {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$MutexName,
		[Parameter(Mandatory = $false)]
		[System.Int32]$MutexWaitTimeInMilliseconds
	)
}

function New-Folder {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$Path,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Remove-Folder {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$Path,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$DisableRecursion,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Copy-File {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.String[]]$Path,
		[Parameter(Mandatory = $true, Position = 1)]
		[System.String]$Destination,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$Recurse,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$Flatten,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueFileCopyOnError,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$UseRobocopy,
		[Parameter(Mandatory = $false)]
		[System.String]$RobocopyParams,
		[System.String]$RobocopyAdditionalParams
	)
}

function Remove-File {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Path')]
		[System.String[]]$Path,
		[Parameter(Mandatory = $true, ParameterSetName = 'LiteralPath')]
		[System.String[]]$LiteralPath,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$Recurse,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Copy-FileToUserProfile {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
		[System.String[]]$Path,
		[Parameter(Mandatory = $false, Position = 2)]
		[System.String]$Destination,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$Recurse,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$Flatten,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$UseRobocopy,
		[Parameter(Mandatory = $false)]
		[System.String]$RobocopyAdditionalParams,
		[Parameter(Mandatory = $false)]
		[System.String[]]$ExcludeNTAccount,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ExcludeSystemProfiles,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ExcludeServiceProfiles,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$ExcludeDefaultUser,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueFileCopyOnError
	)
	process {
	}
}

function Remove-FileFromUserProfile {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Path')]
		[System.String[]]$Path,
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'LiteralPath')]
		[System.String[]]$LiteralPath,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$Recurse,
		[Parameter(Mandatory = $false)]
		[System.String[]]$ExcludeNTAccount,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ExcludeSystemProfiles,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ExcludeServiceProfiles,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$ExcludeDefaultUser,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Convert-RegistryPath {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$Key,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$Wow6432Node,
		[Parameter(Mandatory = $false)]
		[System.String]$SID,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$DisableFunctionLogging
	)
}

function Test-RegistryValue {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Parameter(Mandatory = $true, Position = 1)]
		[Parameter(Mandatory = $false, Position = 2)]
		[System.String]$SID,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$Wow6432Node
	)
	process {
	}
}

function Get-RegistryKey {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$Key,
		[Parameter(Mandatory = $false)]
		[System.String]$Value,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$Wow6432Node,
		[Parameter(Mandatory = $false)]
		[System.String]$SID,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$ReturnEmptyKeyIfExists,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$DoNotExpandEnvironmentNames,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Set-RegistryKey {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$Key,
		[Parameter(Mandatory = $false)]
		[System.String]$Name,
		[Parameter(Mandatory = $false)]
		$Value,
		[Parameter(Mandatory = $false)]
		[Microsoft.Win32.RegistryValueKind]$Type,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$Wow6432Node,
		[Parameter(Mandatory = $false)]
		[System.String]$SID,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Remove-RegistryKey {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$Key,
		[Parameter(Mandatory = $false)]
		[System.String]$Name,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$Recurse,
		[Parameter(Mandatory = $false)]
		[System.String]$SID,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Invoke-HKCURegistrySettingsForAllUser {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.ScriptBlock]$RegistrySettings,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.PSObject[]]$UserProfiles
	)
}

function ConvertTo-NTAccountOrSID {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'NTAccountToSID', ValueFromPipelineByPropertyName = $true)]
		[System.String]$AccountName,
		[Parameter(Mandatory = $true, ParameterSetName = 'SIDToNTAccount', ValueFromPipelineByPropertyName = $true)]
		[System.String]$SID,
		[Parameter(Mandatory = $true, ParameterSetName = 'WellKnownName', ValueFromPipelineByPropertyName = $true)]
		[System.String]$WellKnownSIDName,
		[Parameter(Mandatory = $false, ParameterSetName = 'WellKnownName')]
		[System.Management.Automation.SwitchParameter]$WellKnownToNTAccount
	)
	process {
	}
}

function Get-UserProfile {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.String[]]$ExcludeNTAccount,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ExcludeSystemProfiles,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ExcludeServiceProfiles,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$ExcludeDefaultUser
	)
}

function Get-FileVersion {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$File,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$ProductVersion,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function New-Shortcut {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.String]$Path,
		[Parameter(Mandatory = $true)]
		[System.String]$TargetPath,
		[Parameter(Mandatory = $false)]
		[System.String]$Arguments,
		[Parameter(Mandatory = $false)]
		[System.String]$IconLocation,
		[Parameter(Mandatory = $false)]
		[System.Int32]$IconIndex,
		[Parameter(Mandatory = $false)]
		[System.String]$Description,
		[Parameter(Mandatory = $false)]
		[System.String]$WorkingDirectory,
		[Parameter(Mandatory = $false)]
		[System.String]$WindowStyle,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$RunAsAdmin,
		[Parameter(Mandatory = $false)]
		[System.String]$Hotkey,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Set-Shortcut {
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Default')]
		[System.String]$Path,
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'Pipeline')]
		[System.Collections.Hashtable]$PathHash,
		[Parameter(Mandatory = $false)]
		[System.String]$TargetPath,
		[Parameter(Mandatory = $false)]
		[System.String]$Arguments,
		[Parameter(Mandatory = $false)]
		[System.String]$IconLocation,
		[Parameter(Mandatory = $false)]
		[System.String]$IconIndex,
		[Parameter(Mandatory = $false)]
		[System.String]$Description,
		[Parameter(Mandatory = $false)]
		[System.String]$WorkingDirectory,
		[Parameter(Mandatory = $false)]
		[System.String]$WindowStyle,
		[Parameter(Mandatory = $false)]
		[System.Nullable[System.Boolean]]$RunAsAdmin,
		[Parameter(Mandatory = $false)]
		[System.String]$Hotkey,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
	process {
	}
}

function Get-Shortcut {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.String]$Path,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Execute-ProcessAsUser {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.String]$UserName,
		[Parameter(Mandatory = $true)]
		[System.String]$Path,
		[Parameter(Mandatory = $false)]
		[System.String]$TempPath,
		[Parameter(Mandatory = $false)]
		[System.String]$Parameters,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$SecureParameters,
		[Parameter(Mandatory = $false)]
		[System.String]$RunLevel,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$Wait,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$PassThru,
		[Parameter(Mandatory = $false)]
		[System.String]$WorkingDirectory,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Update-Desktop {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}
Set-Alias -Name 'Refresh-Desktop' -Value 'Update-Desktop' -Scope 'Script' -Force -ErrorAction 'SilentlyContinue'

function Update-SessionEnvironmentVariable {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$LoadLoggedOnUserEnvironmentVariables,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}
Set-Alias -Name 'Refresh-SessionEnvironmentVariables' -Value 'Update-SessionEnvironmentVariables' -Scope 'Script' -Force -ErrorAction 'SilentlyContinue'

function Get-SchedulerTask {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.String]$TaskName,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}
if (-not (Get-Command -Name 'Get-ScheduledTask' -ErrorAction 'SilentlyContinue')) {
	New-Alias -Name 'Get-ScheduledTask' -Value 'Get-SchedulerTask'
}

function Block-AppExecution {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String[]]$ProcessName
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
		[Parameter(Mandatory = $false)]
		[System.String]$DeferTimesRemaining,
		[Parameter(Mandatory = $false)]
		[System.String]$DeferDeadline
	)
}

function Get-UniversalDate {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.String]$DateTime,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Get-RunningProcess {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false, Position = 0)]
		[System.Management.Automation.PSObject[]]$ProcessObjects,
		[Parameter(Mandatory = $false, Position = 1)]
		[System.Management.Automation.SwitchParameter]$DisableLogging
	)
}

function Show-InstallationWelcome {
	[CmdletBinding(DefaultParametersetName = 'None')]
	param (
		[Parameter(Mandatory = $false)]
		[System.String]$CloseApps,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$Silent,
		[Parameter(Mandatory = $false)]
		[System.Int32]$CloseAppsCountdown,
		[Parameter(Mandatory = $false)]
		[System.Int32]$ForceCloseAppsCountdown,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$PromptToSave,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$PersistPrompt,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$BlockExecution,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$AllowDefer,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$AllowDeferCloseApps,
		[Parameter(Mandatory = $false)]
		[System.Int32]$DeferTimes,
		[Parameter(Mandatory = $false)]
		[System.Int32]$DeferDays,
		[Parameter(Mandatory = $false)]
		[System.String]$DeferDeadline,
		[Parameter(ParameterSetName = 'CheckDiskSpaceParameterSet', Mandatory = $true)]
		[System.Management.Automation.SwitchParameter]$CheckDiskSpace,
		[Parameter(ParameterSetName = 'CheckDiskSpaceParameterSet', Mandatory = $false)]
		[System.Int32]$RequiredDiskSpace,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$MinimizeWindows,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$TopMost,
		[Parameter(Mandatory = $false)]
		[System.Int32]$ForceCountdown,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$CustomText
	)
}

function Show-WelcomePrompt {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.String]$ProcessDescriptions,
		[Parameter(Mandatory = $false)]
		[System.Int32]$CloseAppsCountdown,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ForceCloseAppsCountdown,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$PersistPrompt,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$AllowDefer,
		[Parameter(Mandatory = $false)]
		[System.String]$DeferTimes,
		[Parameter(Mandatory = $false)]
		[System.String]$DeferDeadline,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$MinimizeWindows,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$TopMost,
		[Parameter(Mandatory = $false)]
		[System.Int32]$ForceCountdown,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$CustomText
	)
}

function Show-InstallationRestartPrompt {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.Int32]$CountdownSeconds,
		[Parameter(Mandatory = $false)]
		[System.Int32]$CountdownNoHideSeconds,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$NoSilentRestart,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$NoCountdown,
		[Parameter(Mandatory = $false)]
		[System.Int32]$SilentCountdownSeconds,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$TopMost
	)
}

function Show-BalloonTip {
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleTypes', '')]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.String]$BalloonTipText,
		[Parameter(Mandatory = $false, Position = 1)]
		[System.String]$BalloonTipTitle,
		[Parameter(Mandatory = $false, Position = 2)]
		[Windows.Forms.ToolTipIcon]$BalloonTipIcon,
		[Parameter(Mandatory = $false, Position = 3)]
		[System.Int32]$BalloonTipTime,
		[Parameter(Mandatory = $false, Position = 4)]
		[System.Management.Automation.SwitchParameter]$NoWait
	)
}

function Show-InstallationProgress {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.String]$StatusMessage,
		[Parameter(Mandatory = $false)]
		[System.String]$WindowLocation,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$TopMost,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$Quiet
	)
}

function Close-InstallationProgress {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.Int32]$WaitingTime
	)
}

function Set-PinnedApplication {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$Action,
		[Parameter(Mandatory = $true)]
		[System.String]$FilePath
	)
}

function Get-IniValue {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$FilePath,
		[Parameter(Mandatory = $true)]
		[System.String]$Section,
		[Parameter(Mandatory = $true)]
		[System.String]$Key,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Set-IniValue {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$FilePath,
		[Parameter(Mandatory = $true)]
		[System.String]$Section,
		[Parameter(Mandatory = $true)]
		[System.String]$Key,
		[Parameter(Mandatory = $true)]
		[AllowNull()]
		$Value,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Get-PEFileArchitecture {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[System.IO.FileInfo[]]$FilePath,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$PassThru
	)
	process {
	}
}

function Invoke-RegisterOrUnregisterDLL {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$FilePath,
		[Parameter(Mandatory = $false)]
		[System.String]$DLLAction,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}
Set-Alias -Name 'Register-DLL' -Value 'Invoke-RegisterOrUnregisterDLL' -Scope 'Script' -Force -ErrorAction 'SilentlyContinue'
Set-Alias -Name 'Unregister-DLL' -Value 'Invoke-RegisterOrUnregisterDLL' -Scope 'Script' -Force -ErrorAction 'SilentlyContinue'

function Invoke-ObjectMethod {
	[CmdletBinding(DefaultParameterSetName = 'Positional')]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.Object]$InputObject,
		[Parameter(Mandatory = $true, Position = 1)]
		[System.String]$MethodName,
		[Parameter(Mandatory = $false, Position = 2, ParameterSetName = 'Positional')]
		[System.Object[]]$ArgumentList,
		[Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'Named')]
		[System.Collections.Hashtable]$Parameter
	)
}

function Get-ObjectProperty {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.Object]$InputObject,
		[Parameter(Mandatory = $true, Position = 1)]
		[System.String]$PropertyName,
		[Parameter(Mandatory = $false, Position = 2)]
		[System.Object[]]$ArgumentList
	)
}

function Get-MsiTableProperty {
	[CmdletBinding(DefaultParameterSetName = 'TableInfo')]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$Path,
		[Parameter(Mandatory = $false)]
		[System.String[]]$TransformPath,
		[Parameter(Mandatory = $false, ParameterSetName = 'TableInfo')]
		[System.String]$Table,
		[Parameter(Mandatory = $false, ParameterSetName = 'TableInfo')]
		[System.Int32]$TablePropertyNameColumnNum,
		[Parameter(Mandatory = $false, ParameterSetName = 'TableInfo')]
		[System.Int32]$TablePropertyValueColumnNum,
		[Parameter(Mandatory = $true, ParameterSetName = 'SummaryInfo')]
		[System.Management.Automation.SwitchParameter]$GetSummaryInformation,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Set-MsiProperty {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.__ComObject]$DataBase,
		[Parameter(Mandatory = $true)]
		[System.String]$PropertyName,
		[Parameter(Mandatory = $true)]
		[System.String]$PropertyValue,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function New-MsiTransform {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$MsiPath,
		[Parameter(Mandatory = $false)]
		[System.String]$ApplyTransformPath,
		[Parameter(Mandatory = $false)]
		[System.String]$NewTransformPath,
		[Parameter(Mandatory = $true)]
		[System.Collections.Hashtable]$TransformProperties,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Test-MSUpdate {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[System.String]$KBNumber,
		[Parameter(Mandatory = $false, Position = 1)]
		[System.Boolean]$ContinueOnError
	)
}

function Install-MSUpdate {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$Directory
	)
}

function Get-WindowTitle {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'SearchWinTitle')]
		[AllowEmptyString()]
		[System.String]$WindowTitle,
		[Parameter(Mandatory = $true, ParameterSetName = 'GetAllWinTitles')]
		[System.Management.Automation.SwitchParameter]$GetAllWindowTitles,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$DisableFunctionLogging
	)
}

function Send-Key {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false, Position = 0)]
		[AllowEmptyString()]
		[System.String]$WindowTitle,
		[Parameter(Mandatory = $false, Position = 1)]
		[System.Management.Automation.SwitchParameter]$GetAllWindowTitles,
		[Parameter(Mandatory = $false, Position = 2)]
		[System.IntPtr]$WindowHandle,
		[Parameter(Mandatory = $false, Position = 3)]
		[System.String]$Keys,
		[Parameter(Mandatory = $false, Position = 4)]
		[System.Int32]$WaitSeconds
	)
}

function Test-Battery {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$PassThru
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
		[System.String]$ScheduleID,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Install-SCCMSoftwareUpdate {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.Int32]$SoftwareUpdatesScanWaitInSeconds,
		[Parameter(Mandatory = $false)]
		[System.TimeSpan]$WaitForPendingUpdatesTimeout,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Update-GroupPolicy {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Enable-TerminalServerInstallMode {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Disable-TerminalServerInstallMode {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Set-ActiveSetup {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Create')]
		[System.String]$StubExePath,
		[Parameter(Mandatory = $false, ParameterSetName = 'Create')]
		[System.String]$Arguments,
		[Parameter(Mandatory = $false, ParameterSetName = 'Create')]
		[System.String]$Description,
		[Parameter(Mandatory = $false)]
		[System.String]$Key,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$Wow6432Node,
		[Parameter(Mandatory = $false, ParameterSetName = 'Create')]
		[System.String]$Version,
		[Parameter(Mandatory = $false, ParameterSetName = 'Create')]
		[System.String]$Locale,
		[Parameter(Mandatory = $false, ParameterSetName = 'Create')]
		[System.Management.Automation.SwitchParameter]$DisableActiveSetup,
		[Parameter(Mandatory = $true, ParameterSetName = 'Purge')]
		[System.Management.Automation.SwitchParameter]$PurgeActiveSetupKey,
		[Parameter(Mandatory = $false, ParameterSetName = 'Create')]
		[System.Boolean]$ExecuteForCurrentUser,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Test-ServiceExist {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$Name,
		[Parameter(Mandatory = $false)]
		[System.String]$ComputerName,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$PassThru,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Stop-ServiceAndDependency {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$Name,
		[Parameter(Mandatory = $false)]
		[System.String]$ComputerName,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$SkipServiceExistsTest,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$SkipDependentServices,
		[Parameter(Mandatory = $false)]
		[System.TimeSpan]$PendingStatusWait,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$PassThru,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Start-ServiceAndDependency {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$Name,
		[Parameter(Mandatory = $false)]
		[System.String]$ComputerName,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$SkipServiceExistsTest,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$SkipDependentServices,
		[Parameter(Mandatory = $false)]
		[System.TimeSpan]$PendingStatusWait,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]$PassThru,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Get-ServiceStartMode {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$Name,
		[Parameter(Mandatory = $false)]
		[System.String]$ComputerName,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
	)
}

function Set-ServiceStartMode {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]$Name,
		[Parameter(Mandatory = $false)]
		[System.String]$ComputerName,
		[Parameter(Mandatory = $true)]
		[System.String]$StartMode,
		[Parameter(Mandatory = $false)]
		[System.Boolean]$ContinueOnError
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
		[System.String]$Path,
		[Parameter( Mandatory = $true, Position = 1, ParameterSetName = 'DisableInheritance')]
		[Alias('Username', 'Users', 'SID', 'Usernames')]
		[System.String[]]$User,
		[Parameter( Mandatory = $true, Position = 2, ParameterSetName = 'DisableInheritance')]
		[Alias('Acl', 'Grant', 'Permissions', 'Deny')]
		[System.String[]]$Permission,
		[Parameter( Mandatory = $false, Position = 3, ParameterSetName = 'DisableInheritance')]
		[Alias('AccessControlType')]
		[System.String]$PermissionType,
		[Parameter( Mandatory = $false, Position = 4, ParameterSetName = 'DisableInheritance')]
		[System.String[]]$Inheritance,
		[Parameter( Mandatory = $false, Position = 5, ParameterSetName = 'DisableInheritance')]
		[System.String]$Propagation,
		[Parameter( Mandatory = $false, Position = 6, ParameterSetName = 'DisableInheritance')]
		[Alias('ApplyMethod', 'ApplicationMethod')]
		[System.String]$Method,
		[Parameter( Mandatory = $true, Position = 1, ParameterSetName = 'EnableInheritance')]
		[System.Management.Automation.SwitchParameter]$EnableInheritance
	)
}

function Copy-ContentToCache {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false, Position = 0)]
		[System.String]$Path
	)
}

function Remove-ContentFromCache {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false, Position = 0)]
		[System.String]$Path
	)
}

function Configure-EdgeExtension {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Add')]
		[System.Management.Automation.SwitchParameter]$Add,
		[Parameter(Mandatory = $true, ParameterSetName = 'Remove')]
		[System.Management.Automation.SwitchParameter]$Remove,
		[Parameter(Mandatory = $true, ParameterSetName = 'Add')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Remove')]
		[System.String]$ExtensionID,
		[Parameter(Mandatory = $true, ParameterSetName = 'Add')]
		[System.String]$InstallationMode,
		[Parameter(Mandatory = $true, ParameterSetName = 'Add')]
		[System.String]$UpdateUrl,
		[Parameter(Mandatory = $false, ParameterSetName = 'Add')]
		[System.String]$MinimumVersionRequired
	)
}
#endregion

#region neo42 Extension Function Definitions
function Add-NxtContent {
	[CmdletBinding()]
	param (
		[Parameter()]
		[System.String]
		$Path,
		[Parameter()]
		[System.String]
		$Value,
		[Parameter()]
		[ValidateSet('Ascii', 'Default', 'UTF7', 'BigEndianUnicode', 'Oem', 'Unicode', 'UTF32', 'UTF8')]
		[System.String]
		$Encoding,
		[Parameter()]
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
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Description,
		[Parameter(Mandatory = $false)]
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
		[Parameter(Mandatory = $false)]
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
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$FullName,
		[Parameter(Mandatory = $false)]
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
		[Parameter(Mandatory = $false)]
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
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$AddToBeginning = $false
	)
}

function Add-NxtSystemPathVariable {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Path,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$AddToBeginning = $false
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
		[Parameter(Mandatory = $false)]
		[System.Collections.Hashtable]
		$Attributes,
		[Parameter(Mandatory = $false)]
		[System.String]
		$InnerText,
		[Parameter(Mandatory = $false)]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[System.String]
		$Encoding,
		[Parameter(Mandatory = $false)]
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
		[System.String[]]$ProcessName,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[System.String]
		$BlockScriptLocation,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[System.String]
		$ScriptDirectory = $ScriptDirectory,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[System.String]
		$RegKeyAppExecution
	)
}

function Compare-NxtVersion {
	[CmdletBinding()]
	param (
		[Parameter()]
		[System.String]
		$DetectedVersion,
		[Parameter()]
		[System.String]
		$TargetVersion,
		[Parameter()]
		[System.Boolean]
		$HexMode = $false
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
		[Parameter(Mandatory = $false)]
		[System.String]
		$PackageMachineKey,
		[Parameter(Mandatory = $false)]
		[System.String]
		$PackageUninstallKey,
		[Parameter(Mandatory = $false)]
		[System.String]
		$RebootMessage,
		[Parameter(Mandatory = $false)]
		[System.Int32]
		$RebootExitCode = 3010,
		[Parameter(Mandatory = $false)]
		[System.String]
		$PackageStatus = 'AbortReboot',
		[Parameter(Mandatory = $false)]
		[System.String]
		$EmpirumMachineKey,
		[Parameter(Mandatory = $false)]
		[System.String]
		$EmpirumUninstallKey
	)
}

function Exit-NxtScriptWithError {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.String]
		$RegisterPackage,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$ErrorMessage,
		[Parameter(Mandatory = $false)]
		[System.String]
		$ErrorMessagePSADT,
		[Parameter(Mandatory = $false)]
		[System.String]
		$PackageGUID,
		[Parameter(Mandatory = $false)]
		[System.String]
		$RegPackagesKey,
		[Parameter(Mandatory = $false)]
		[System.String]
		$App,
		[Parameter(Mandatory = $false)]
		[System.String]
		$DeploymentTimestamp,
		[Parameter(Mandatory = $false)]
		[System.String]
		$DebugLogFile,
		[Parameter(Mandatory = $false)]
		[System.String]
		$AppVendor,
		[Parameter(Mandatory = $false)]
		[System.String]
		$AppArch,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.Int32]
		$MainExitCode,
		[Parameter(Mandatory = $false)]
		[System.String]
		$PackageStatus,
		[Parameter(Mandatory = $false)]
		[System.String]
		$AppRevision,
		[Parameter(Mandatory = $false)]
		[System.String]
		$ScriptParentPath,
		[Parameter(Mandatory = $false)]
		[System.String]
		$EnvArchitecture,
		[Parameter(Mandatory = $false)]
		[System.String]
		$EnvUserDomain,
		[Parameter(Mandatory = $false)]
		[System.String]
		$EnvUserName,
		[Parameter(Mandatory = $false)]
		[System.String]
		$ProcessNTAccountSID,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$UninstallOld,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$UserPartOnInstallation,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$UserPartOnUnInstallation,
		[Parameter(Mandatory = $false)]
		[System.String]
		$TempRootFolder,
		[Parameter(Mandatory = $false)]
		[System.Int32]
		$HoursToKeep,
		[Parameter(Mandatory = $false)]
		[System.String[]]
		$NxtTempDirectories,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$BlockExecution,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$DeploymentType
	)
}

function Get-NxtCurrentDisplayVersion {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.String]
		$UninstallKey = $global:PackageConfig.UninstallKey,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$UninstallKeyIsDisplayName = $global:PackageConfig.UninstallKeyIsDisplayName,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$UninstallKeyContainsWildCards = $global:PackageConfig.UninstallKeyContainsWildCards,
		[Parameter(Mandatory = $false)]
		[System.Array]
		$DisplayNamesToExclude = $global:PackageConfig.DisplayNamesToExcludeFromAppSearches,
		[Parameter(Mandatory = $false)]
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
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$IncludeChildProcesses = $true,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$IncludeParentProcesses = $true
	)
}

function Get-NxtRegisteredPackage {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.String]
		$PackageGUID,
		[Parameter(Mandatory = $false)]
		[System.String]
		$ProductGUID,
		[Parameter(Mandatory = $false)]
		[System.String]
		[ValidateSet('0', '1')]
		$InstalledState,
		[Parameter(Mandatory = $false)]
		[System.String]
		$RegPackagesKey = $global:PackageConfig.RegPackagesKey
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
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$ContinueOnError = $true
	)
}

function Import-NxtIniFileWithComment {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[System.String]
		$Path,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$ContinueOnError = $true
	)
}

function Import-NxtXmlFile {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[System.String]
		$Path,
		[Parameter(Mandatory = $false)]
		[System.String]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		$Encoding,
		[Parameter(Mandatory = $false)]
		[System.String]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		$DefaultEncoding = 'UTF8withBom',
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$ContinueOnError = $true
	)
}

function Install-NxtApplication {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.String]
		$AppName = $global:PackageConfig.AppName,
		[Parameter(Mandatory = $false)]
		[System.String]
		$UninstallKey = $global:PackageConfig.UninstallKey,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$UninstallKeyIsDisplayName = $global:PackageConfig.UninstallKeyIsDisplayName,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$UninstallKeyContainsWildCards = $global:PackageConfig.UninstallKeyContainsWildCards,
		[Parameter(Mandatory = $false)]
		[System.Array]
		$DisplayNamesToExclude = $global:PackageConfig.DisplayNamesToExcludeFromAppSearches,
		[Parameter(Mandatory = $false)]
		[System.String]
		$InstLogFile = $global:PackageConfig.InstLogFile,
		[Parameter(Mandatory = $false)]
		[System.String]
		$InstFile = $global:PackageConfig.InstFile,
		[Parameter(Mandatory = $false)]
		[System.String]
		$InstPara = $global:PackageConfig.InstPara,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$AppendInstParaToDefaultParameters = $global:PackageConfig.AppendInstParaToDefaultParameters,
		[Parameter(Mandatory = $false)]
		[System.String]
		$AcceptedInstallExitCodes = $global:PackageConfig.AcceptedInstallExitCodes,
		[Parameter(Mandatory = $false)]
		[System.String]
		$AcceptedInstallRebootCodes = $global:PackageConfig.AcceptedInstallRebootCodes,
		[Parameter(Mandatory = $false)]
		[System.String]
		$InstallMethod = $global:PackageConfig.InstallMethod,
		[Parameter(Mandatory = $false)]
		[System.String]
		$UninstallMethod = $global:PackageConfig.UninstallMethod,
		[Parameter(Mandatory = $false)]
		[System.Int32]
		$PreSuccessCheckTotalSecondsToWaitFor = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Install.TotalSecondsToWaitFor,
		[Parameter(Mandatory = $false)]
		[System.String]
		$PreSuccessCheckProcessOperator = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Install.ProcessOperator,
		[Parameter(Mandatory = $false)]
		[System.Array]
		$PreSuccessCheckProcessesToWaitFor = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Install.ProcessesToWaitFor,
		[Parameter(Mandatory = $false)]
		[System.String]
		$PreSuccessCheckRegKeyOperator = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Install.RegKeyOperator,
		[Parameter(Mandatory = $false)]
		[System.Array]
		$PreSuccessCheckRegkeysToWaitFor = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Install.RegkeysToWaitFor,
		[Parameter(Mandatory = $false)]
		[System.String]
		$UninsBackupPath = "$($global:packageConfig.App)\neo42-Source"
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
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]
		$Force,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[System.Boolean]
		$ContinueOnError = $true
	)
}

function New-NxtFolderWithPermission {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Path,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$FullControlPermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$WritePermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$ModifyPermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$ReadAndExecutePermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType]
		$Owner,
		[Parameter(Mandatory = $false)]
		[System.Security.AccessControl.DirectorySecurity]
		$CustomDirectorySecurity,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$Hidden,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$ProtectRules = $true
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
		[Parameter(Mandatory = $false)]
		[System.String]
		$AttributeName = 'Innertext',
		[Parameter(Mandatory = $false)]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[System.String]
		$Encoding,
		[Parameter(Mandatory = $false)]
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
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[System.Boolean]
		$ContinueOnError = $true
	)
}

function Remove-NxtLocalGroup {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$GroupName,
		[Parameter(Mandatory = $false)]
		[System.String]
		$COMPUTERNAME = $env:COMPUTERNAME
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
		[Parameter(Mandatory = $false)]
		[System.String]
		$COMPUTERNAME = $env:COMPUTERNAME
	)
}

function Remove-NxtLocalUser {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$UserName,
		[Parameter(Mandatory = $false)]
		[System.String]
		$COMPUTERNAME = $env:COMPUTERNAME
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
		[Parameter(Mandatory = $false)]
		[System.String]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		$Encoding,
		[Parameter(Mandatory = $false)]
		[System.String]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		$DefaultEncoding = 'UTF8withBom'
	)
}

function Set-NxtFolderPermission {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$Path,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$FullControlPermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$WritePermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$ModifyPermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$ReadAndExecutePermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType]
		$Owner,
		[Parameter(Mandatory = $false)]
		[System.Security.AccessControl.DirectorySecurity]
		$CustomDirectorySecurity,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$BreakInheritance = $true,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$EnforceInheritanceOnSubFolders = $false
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
		# Don't strongly type this variable as [string] b/c PowerShell replaces [string]$Value = $null with an empty string
		[Parameter(Mandatory = $true)]
		[ValidateScript({
				if ($false -eq (($_.GetType().Name -eq 'String') -or ($null -eq $_))) {
					throw "'$_' is not a string or null."
				}
				$true
			})]
		[AllowNull()]
		$Value,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[System.Boolean]
		$ContinueOnError = $true,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[System.Boolean]
		$Create = $true
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
		[Parameter(Mandatory = $false)]
		[System.Collections.Hashtable]
		$Attributes,
		[Parameter(Mandatory = $false)]
		[System.Collections.Hashtable]
		$FilterAttributes,
		[Parameter(Mandatory = $false)]
		[System.String]
		$InnerText,
		[Parameter(Mandatory = $false)]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[System.String]
		$Encoding,
		[Parameter(Mandatory = $false)]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[System.String]
		$DefaultEncoding = 'UTF8withBom'
	)
}

function Show-NxtInstallationWelcome {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]
		$Silent = $false,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[System.Int32]
		$CloseAppsCountdown = $global:SetupCfg.AskKillProcesses.Timeout,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[System.Int32]
		$ForceCloseAppsCountdown = 0,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]
		$PromptToSave = $false,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]
		$PersistPrompt = $false,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]
		$BlockExecution = $($global:PackageConfig.BlockExecution),
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]
		$AllowDefer = $false,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]
		$AllowDeferCloseApps = $false,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[System.Int32]
		$DeferTimes = $global:SetupCfg.AskKillProcesses.DeferTimes,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[System.Int32]
		$DeferDays = $global:SetupCfg.AskKillProcesses.DeferDays,
		[Parameter(Mandatory = $false)]
		[System.String]
		$DeferDeadline = [System.String]::Empty,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[System.Boolean]
		$MinimizeWindows = [System.Convert]::ToBoolean([System.Convert]::ToInt32($global:SetupCfg.AskKillProcesses.MINIMIZEALLWINDOWS)),
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[System.Boolean]
		$TopMost = [System.Convert]::ToBoolean([System.Convert]::ToInt32($global:SetupCfg.AskKillProcesses.TOPMOSTWINDOW)),
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[System.Int32]
		$ForceCountdown = 0,
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]
		$CustomText = $false,
		[Parameter(Mandatory = $true)]
		[System.Boolean]
		$IsInstall,
		[Parameter(Mandatory = $false)]
		[System.Array]
		$AskKillProcessApps = $global:PackageConfig.AppKillProcesses,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[PSADTNXT.ContinueType]
		$ContinueType = $global:SetupCfg.AskKillProcesses.ContinueType,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$ForceContinueAfterDeferrals = [System.Convert]::ToBoolean([System.Convert]::ToInt32($global:SetupCfg.AskKillProcesses.ForceContinueAfterDeferrals)),
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]
		$UserCanCloseAll = [System.Convert]::ToBoolean([System.Convert]::ToInt32($global:SetupCfg.ASKKILLPROCESSES.USERCANCLOSEALL)),
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]
		$UserCanAbort = [System.Convert]::ToBoolean([System.Convert]::ToInt32($global:SetupCfg.ASKKILLPROCESSES.ALLOWABORTBYUSER)),
		[Parameter(Mandatory = $false)]
		[System.Management.Automation.SwitchParameter]
		$ApplyContinueTypeOnError = [System.Convert]::ToBoolean([System.Convert]::ToInt32($global:SetupCfg.ASKKILLPROCESSES.APPLYCONTINUETYPEONERROR)),
		[Parameter(Mandatory = $false)]
		[System.String]
		$ScriptRoot = $ScriptRoot,
		[Parameter(Mandatory = $false)]
		[System.Int32]
		$ProcessIdToIgnore = $PID,
		[Parameter(Mandatory = $false)]
		[System.String]
		$BlockScriptLocation = $global:PackageConfig.App
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
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$FullControlPermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$WritePermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$ModifyPermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType[]]
		$ReadAndExecutePermissions,
		[Parameter(Mandatory = $false)]
		[System.Security.Principal.WellKnownSidType]
		$Owner,
		[Parameter(Mandatory = $false)]
		[System.Security.AccessControl.DirectorySecurity]
		$CustomDirectorySecurity,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$CheckIsInherited,
		[Parameter(Mandatory = $false)]
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
		[Parameter()]
		[System.Management.Automation.SwitchParameter]
		$IsWql = $false
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
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$ContainsRegex = $false,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$IgnoreCase = $true,
		[Parameter()]
		[ValidateSet('Ascii', 'Default', 'UTF7', 'BigEndianUnicode', 'Oem', 'Unicode', 'UTF32', 'UTF8')]
		[System.String]
		$Encoding,
		[Parameter()]
		[ValidateSet('Ascii', 'Default', 'UTF7', 'BigEndianUnicode', 'Oem', 'Unicode', 'UTF32', 'UTF8')]
		[System.String]
		$DefaultEncoding
	)
}

function Uninstall-NxtApplication {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[System.String]
		$AppName = $global:PackageConfig.AppName,
		[Parameter(Mandatory = $false)]
		[System.String]
		$UninstallKey = $global:PackageConfig.UninstallKey,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$UninstallKeyIsDisplayName = $global:PackageConfig.UninstallKeyIsDisplayName,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$UninstallKeyContainsWildCards = $global:PackageConfig.UninstallKeyContainsWildCards,
		[Parameter(Mandatory = $false)]
		[System.Array]
		$DisplayNamesToExclude = $global:PackageConfig.DisplayNamesToExcludeFromAppSearches,
		[Parameter(Mandatory = $false)]
		[System.String]
		$UninstLogFile = $global:PackageConfig.UninstLogFile,
		[Parameter(Mandatory = $false)]
		[System.String]
		$UninstFile = $global:PackageConfig.UninstFile,
		[Parameter(Mandatory = $false)]
		[System.String]
		$UninstPara = $global:PackageConfig.UninstPara,
		[Parameter(Mandatory = $false)]
		[System.Boolean]
		$AppendUninstParaToDefaultParameters = $global:PackageConfig.AppendUninstParaToDefaultParameters,
		[Parameter(Mandatory = $false)]
		[System.String]
		$AcceptedUninstallExitCodes = $global:PackageConfig.AcceptedUninstallExitCodes,
		[Parameter(Mandatory = $false)]
		[System.String]
		$AcceptedUninstallRebootCodes = $global:PackageConfig.AcceptedUninstallRebootCodes,
		[Parameter(Mandatory = $false)]
		[System.String]
		$UninstallMethod = $global:PackageConfig.UninstallMethod,
		[Parameter(Mandatory = $false)]
		[System.Int32]
		$PreSuccessCheckTotalSecondsToWaitFor = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Uninstall.TotalSecondsToWaitFor,
		[Parameter(Mandatory = $false)]
		[System.String]
		$PreSuccessCheckProcessOperator = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Uninstall.ProcessOperator,
		[Parameter(Mandatory = $false)]
		[System.Array]
		$PreSuccessCheckProcessesToWaitFor = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Uninstall.ProcessesToWaitFor,
		[Parameter(Mandatory = $false)]
		[System.String]
		$PreSuccessCheckRegKeyOperator = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Uninstall.RegKeyOperator,
		[Parameter(Mandatory = $false)]
		[System.Array]
		$PreSuccessCheckRegkeysToWaitFor = $global:packageConfig.TestConditionsPreSetupSuccessCheck.Uninstall.RegkeysToWaitFor,
		[Parameter(Mandatory = $false)]
		[System.String]
		$DirFiles = $DirFiles,
		[Parameter(Mandatory = $false)]
		[System.String]
		$UninsBackupPath = "$($global:packageConfig.App)\neo42-Source"
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
		[Parameter()]
		[System.Int32]
		$Count = [System.Int32]::MaxValue,
		[Parameter()]
		[ValidateSet('Ascii', 'Default', 'UTF7', 'BigEndianUnicode', 'Oem', 'Unicode', 'UTF32', 'UTF8')]
		[System.String]
		$Encoding,
		[Parameter()]
		[ValidateSet('Ascii', 'Default', 'UTF7', 'BigEndianUnicode', 'Oem', 'Unicode', 'UTF32', 'UTF8')]
		[System.String]
		$DefaultEncoding,
		[Parameter()]
		[System.Boolean]
		$AddBOMIfUTF8 = $true
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
		[Parameter(Mandatory = $false)]
		[System.Collections.Hashtable]
		$Attributes,
		[Parameter(Mandatory = $false)]
		[System.Collections.Hashtable]
		$FilterAttributes,
		[Parameter(Mandatory = $false)]
		[System.String]
		$InnerText,
		[Parameter()]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[System.String]
		$Encoding,
		[Parameter()]
		[ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF8', 'UTF8withBom')]
		[System.String]
		$DefaultEncoding = 'UTF8withBom'
	)
}

function Watch-NxtFile {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$FileName,
		[Parameter()]
		[System.Int32]
		$Timeout = 60
	)
}

function Watch-NxtFileIsRemoved {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$FileName,
		[Parameter(Mandatory = $false)]
		[System.Int32]
		$Timeout = 60
	)
}

function Watch-NxtProcess {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$ProcessName,
		[Parameter(Mandatory = $false)]
		[System.Int32]
		$Timeout = 60,
		[System.Management.Automation.SwitchParameter]
		$IsWql = $false
	)
}

function Watch-NxtProcessIsStopped {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$ProcessName,
		[Parameter(Mandatory = $false)]
		[System.Int32]
		$Timeout = 60,
		[System.Management.Automation.SwitchParameter]
		$IsWql = $false
	)
}

function Watch-NxtRegistryKey {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$RegistryKey,
		[Parameter()]
		[System.Int32]
		$Timeout = 60
	)
}

function Watch-NxtRegistryKeyIsRemoved {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.String]
		$RegistryKey,
		[Parameter()]
		[System.Int32]
		$Timeout = 60
	)
}
#endregion neo42 Extension Function Definitions
