<#
.SYNOPSIS
Function based rules to detect PSADTv3 legacy code and suggest replacements.
#>

[System.Collections.Generic.HashSet[System.String]]$script:DeprecatedTypeFullNames = @(
	'PSADTNXT.DriveType',
	'PSADTNXT.NxtApplicationResult',
	'PSADTNXT.NxtAskKillProcessesResult',
	'PSADTNXT.NxtDisplayVersionResult',
	'PSADTNXT.NxtRebootResult',
	'PSADTNXT.NxtRegisteredApplication',
	'PSADTNXT.SessionHelper',
	'PSADTNXT.VersionKeyValuePair',
	'PSADTNXT.VersionPartInfo',
	'PSADTNXT.XmlNodeModel',
	'PSADTNXT.ContinueType'
)

[System.Collections.Hashtable[]]$script:CustomMigrations = @(
	@{
		Filter      = {
			$args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and
			$args[0].VariablePath.UserPath -eq 'global:DeploymentTimestamp'
		}
		Replacement = '$deploymentTimestamp'
	}
	@{ # Migrate usage of package config variable
		Filter      = {
			$args[0].GetType() -eq [System.Management.Automation.Language.MemberExpressionAst] -and # Explicitly only use MemberExpressionAst not other types
			(
				(
					$args[0].Expression -is [System.Management.Automation.Language.VariableExpressionAst] -and
					$args[0].Expression.VariablePath.UserPath.Split(':')[1] -eq 'PackageConfig'
				) -or
				(
					$args[0].Expression -is [System.Management.Automation.Language.MemberExpressionAst] -and
					$args[0].Expression.Expression -is [System.Management.Automation.Language.VariableExpressionAst] -and
					$args[0].Expression.Expression.VariablePath.UserPath.Split(':')[1] -eq 'PackageConfig'
				)
			)
		}
		Replacement = {
			if ($_.Expression -is [System.Management.Automation.Language.VariableExpressionAst]) {
				switch ($_.Member.Value) {
					'ScriptAuthor' { '$adtSession.AppScriptAuthor' }
					'ScriptDate' { '$adtSession.AppScriptDate' }
					'InstallMethod' { '$adtSession.NXT.Install.Method' }
					'UninstallMethod' { '$adtSession.NXT.Uninstall.Method' }
					'ReinstallMode' { '$adtSession.NXT.Install.ReinstallMode' }
					'AppArch' { '$adtSession.AppArch' }
					'AppVendor' { '$adtSession.AppVendor' }
					'AppName' { '$adtSession.AppName' }
					'AppVersion' { '$adtSession.AppVersion' }
					'AppRevision' { '$adtSession.AppRevision' }
					'AppLang' { '$adtSession.AppLang' }
					'PackageGUID' { '$adtSession.NXT.Package.GUID' }
					'RegPackagesKey' { '$adtSession.NXT.Package.RegistryKey.Split(''\'')[1]' }
					'UninstallDisplayName' { '$adtSession.NXT.Package.DisplayName' }
					'AppRootFolder' { '$adtSession.NXT.Package.RootDirectory' }
					'App' { '$adtSession.NXT.Package.Directory' }
					'UninstallOld' { '$adtSession.NXT.Package.UninstallOld' }
					'Reboot' { '$adtSession.NXT.Install.Reboot' }
					'UserPartOnInstallation' { '$adtSession.NXT.Install.UserPart' }
					'UserPartOnUninstallation' { '$adtSession.NXT.Uninstall.UserPart' }
					'UserPartRevision' { '$adtSession.NXT.UserPartRevision' }
					'DisplayVersion' { '$adtSession.AppVersion' }
					'InstallLocation' { '$adtSession.NXT.InstallLocation' }
					'InstFile' { '$adtSession.NXT.Install.Target' }
					'InstPara' { '$adtSession.NXT.Install.Arguments' }
					'AppendInstParaToDefaultParameters' { '$adtSession.NXT.Install.Defaults' }
					'UninstFile' { '$adtSession.NXT.Uninstall.Target' }
					'UninstPara' { '$adtSession.NXT.Uninstall.Arguments' }
					'AppendUninstParaToDefaultParameters' { '$adtSession.NXT.Uninstall.Defaults' }
					'AppKillProcesses' { '$adtSession.NXT.CloseProcesses.ProcessDefinition' }
					{ $_ -in @(
							'ConfigVersion', 'InventoryID', 'Description', 'TestedOn', 'Dependencies', 'ProductGUID', 'InstallerVersion',
							'UninstallKey', 'UninstallKeyIsDisplayName', 'UninstallKeyContainsWildCards', 'UninstallKeyContainsExpandVariables', 'DisplayNamesToExcludeFromAppSearches'
						)
					} { "`$adtSession.NXT.Variables.Legacy_$($_)" }
					default { "# The PackageConfig value [$_] does not have a direct migration path. Please review manually." }
				}
			}
			else {
				[System.Management.Automation.Language.MemberExpressionAst]$member = $_
				switch ($member.Expression.Member.Value) {
					'PackageSpecificVariables' { "`$adtSession.NXT.Variables.$($member.Member.Value)" }
					default { "# The PackageConfig value [$_] does not have a direct migration path. Please review manually." }
				}
			}
		}
	}
	@{ # Migrate commonly used expression $(Get-NxtCurrentDisplayVersion).DisplayVersion
		Filter      = {
			$args[0] -is [System.Management.Automation.Language.MemberExpressionAst] -and
			$args[0].Member.Value -eq 'DisplayVersion' -and
			$args[0].Expression.Extent.Text -match '\(Get\-NxtCurrentDisplayVersion\)$'
		}
		Replacement = '$adtSession.NXT.Detection.Application.DisplayVersion'
	}
)

[System.Collections.Hashtable]$script:VariableMappings = @{
	#region PSAppDeployToolkit variables v3.10.2
	AllowRebootPassThru                                                    = '$adtSession.AllowRebootPassThru'
	appArch                                                                = '$adtSession.AppArch'
	appLang                                                                = '$adtSession.AppLang'
	appName                                                                = '$adtSession.AppName'
	appRevision                                                            = '$adtSession.AppRevision'
	appScriptAuthor                                                        = '$adtSession.AppScriptAuthor'
	appScriptDate                                                          = '$adtSession.AppScriptDate'
	appScriptVersion                                                       = '$adtSession.AppScriptVersion'
	appVendor                                                              = '$adtSession.AppVendor'
	appVersion                                                             = '$adtSession.AppVersion'
	currentDate                                                            = '$adtSession.CurrentDate'
	currentDateTime                                                        = '$adtSession.CurrentDateTime'
	defaultMsiFile                                                         = '$adtSession.DefaultMsiFile'
	deployAppScriptDate                                                    = '$adtSession.CurrentDate.ToString("yyyy-MM-dd")'
	deployAppScriptFriendlyName                                            = '$adtSession.DeployAppScriptFriendlyName'
	deployAppScriptParameters                                              = '$adtSession.DeployAppScriptParameters'
	deployAppScriptVersion                                                 = '$adtSession.DeployAppScriptVersion'
	DeploymentType                                                         = '$adtSession.DeploymentType'
	deploymentTypeName                                                     = '$adtSession.DeploymentTypeName'
	DeployMode                                                             = '$adtSession.DeployMode'
	dirFiles                                                               = '$adtSession.DirFiles'
	dirSupportFiles                                                        = '$adtSession.DirSupportFiles'
	DisableScriptLogging                                                   = '$adtSession.DisableLogging'
	installName                                                            = '$adtSession.InstallName'
	installPhase                                                           = '$adtSession.InstallPhase'
	installTitle                                                           = '$adtSession.InstallTitle'
	logName                                                                = '$adtSession.LogName'
	logTempFolder                                                          = '$adtSession.LogTempFolder'
	scriptDirectory                                                        = '$adtSession.ScriptDirectory'
	TerminalServerMode                                                     = '$adtSession.TerminalServerMode'
	useDefaultMsi                                                          = '$adtSession.UseDefaultMsi'
	appDeployConfigFile                                                    = $null
	appDeployCustomTypesSourceCode                                         = $null
	appDeployExtScriptDate                                                 = $null
	appDeployExtScriptFriendlyName                                         = $null
	appDeployExtScriptParameters                                           = $null
	appDeployExtScriptVersion                                              = $null
	appDeployLogoBanner                                                    = $null
	appDeployLogoBannerHeight                                              = $null
	appDeployLogoBannerMaxHeight                                           = $null
	appDeployLogoBannerObject                                              = $null
	appDeployLogoIcon                                                      = $null
	appDeployLogoImage                                                     = $null
	appDeployMainScriptAsyncParameters                                     = $null
	appDeployMainScriptDate                                                = $null
	appDeployMainScriptFriendlyName                                        = $null
	appDeployMainScriptMinimumConfigVersion                                = $null
	appDeployMainScriptParameters                                          = $null
	appDeployRunHiddenVbsFile                                              = $null
	appDeployToolkitDotSourceExtensions                                    = $null
	appDeployToolkitExtName                                                = $null
	AsyncToolkitLaunch                                                     = $null
	BlockExecution                                                         = '(Get-ADTConfig).NXT.Toolkit.BlockExecution'
	ButtonCenterText                                                       = $null
	ButtonLeftText                                                         = $null
	ButtonMiddleText                                                       = $null
	ButtonRightText                                                        = $null
	CleanupBlockedApps                                                     = $null
	closeAppsCountdownGlobal                                               = $null
	configBalloonTextComplete                                              = '(Get-ADTStringTable).BalloonText.Complete'
	configBalloonTextError                                                 = '(Get-ADTStringTable).BalloonText.Error'
	configBalloonTextFastRetry                                             = '(Get-ADTStringTable).BalloonText.FastRetry'
	configBalloonTextRestartRequired                                       = '(Get-ADTStringTable).BalloonText.RestartRequired'
	configBalloonTextStart                                                 = '(Get-ADTStringTable).BalloonText.Start'
	configBannerIconBannerName                                             = '(Get-ADTConfig).Assets.Banner'
	configBannerIconFileName                                               = $null
	configBannerLogoImageFileName                                          = '(Get-ADTConfig).Assets.Logo'
	configBlockExecutionMessage                                            = '(Get-ADTStringTable).BlockExecution.Message'
	configClosePromptButtonClose                                           = '(Get-ADTStringTable).ClosePrompt.ButtonClose'
	configClosePromptButtonContinue                                        = '(Get-ADTStringTable).ClosePrompt.ButtonContinue'
	configClosePromptButtonContinueTooltip                                 = '(Get-ADTStringTable).ClosePrompt.ButtonContinueTooltip'
	configClosePromptButtonDefer                                           = '(Get-ADTStringTable).ClosePrompt.ButtonDefer'
	configClosePromptCountdownMessage                                      = '(Get-ADTStringTable).ClosePrompt.CountdownMessage'
	configClosePromptMessage                                               = '(Get-ADTStringTable).ClosePrompt.Message'
	configConfigDate                                                       = $null
	configConfigDetails                                                    = $null
	configConfigVersion                                                    = $null
	configDeferPromptDeadline                                              = '(Get-ADTStringTable).DeferPrompt.Deadline'
	configDeferPromptExpiryMessage                                         = '(Get-ADTStringTable).DeferPrompt.ExpiryMessage'
	configDeferPromptRemainingDeferrals                                    = '(Get-ADTStringTable).DeferPrompt.RemainingDeferrals'
	configDeferPromptWarningMessage                                        = '(Get-ADTStringTable).DeferPrompt.WarningMessage'
	configDeferPromptWelcomeMessage                                        = '(Get-ADTStringTable).DeferPrompt.WelcomeMessage'
	configDeploymentTypeInstall                                            = '(Get-ADTStringTable).DeploymentType.Install'
	configDeploymentTypeRepair                                             = '(Get-ADTStringTable).DeploymentType.Repair'
	configDeploymentTypeUnInstall                                          = '(Get-ADTStringTable).DeploymentType.Uninstall'
	configDiskSpaceMessage                                                 = '(Get-ADTStringTable).DiskSpace.Message'
	configInstallationDeferExitCode                                        = '(Get-ADTConfig).UI.DeferExitCode'
	configInstallationPersistInterval                                      = '(Get-ADTConfig).UI.DefaultPromptPersistInterval'
	configInstallationPromptToSave                                         = '(Get-ADTConfig).UI.PromptToSaveTimeout'
	configInstallationRestartPersistInterval                               = '(Get-ADTConfig).UI.RestartPromptPersistInterval'
	configInstallationUIExitCode                                           = '(Get-ADTConfig).UI.DefaultExitCode'
	configInstallationUILanguageOverride                                   = '(Get-ADTConfig).UI.LanguageOverride'
	configInstallationUITimeout                                            = '(Get-ADTConfig).UI.DefaultTimeout'
	configInstallationWelcomePromptDynamicRunningProcessEvaluation         = '(Get-ADTConfig).UI.DynamicProcessEvaluation'
	configInstallationWelcomePromptDynamicRunningProcessEvaluationInterval = '(Get-ADTConfig).UI.DynamicProcessEvaluationInterval'
	configMSIInstallParams                                                 = '(Get-ADTConfig).MSI.InstallParams'
	configMSILogDir                                                        = 'if ($isAdmin) { (Get-ADTConfig).MSI.LogPath } else { (Get-ADTConfig).MSI.LogPathNoAdminRights }'
	configMSILoggingOptions                                                = '(Get-ADTConfig).MSI.LoggingOptions'
	configMSIMutexWaitTime                                                 = '(Get-ADTConfig).MSI.MutexWaitTime'
	configMSISilentParams                                                  = '(Get-ADTConfig).MSI.SilentParams'
	configMSIUninstallParams                                               = '(Get-ADTConfig).MSI.UninstallParams'
	configProgressMessageInstall                                           = '(Get-ADTStringTable).Progress.MessageInstall'
	configProgressMessageRepair                                            = '(Get-ADTStringTable).Progress.MessageRepair'
	configProgressMessageUninstall                                         = '(Get-ADTStringTable).Progress.MessageUninstall'
	configRestartPromptButtonRestartLater                                  = '(Get-ADTStringTable).RestartPrompt.ButtonRestartLater'
	configRestartPromptButtonRestartNow                                    = '(Get-ADTStringTable).RestartPrompt.ButtonRestartNow'
	configRestartPromptMessage                                             = '(Get-ADTStringTable).RestartPrompt.Message'
	configRestartPromptMessageRestart                                      = '(Get-ADTStringTable).RestartPrompt.MessageRestart'
	configRestartPromptMessageTime                                         = '(Get-ADTStringTable).RestartPrompt.MessageTime'
	configRestartPromptTimeRemaining                                       = '(Get-ADTStringTable).RestartPrompt.TimeRemaining'
	configRestartPromptTitle                                               = '(Get-ADTStringTable).RestartPrompt.Title'
	configShowBalloonNotifications                                         = '(Get-ADTConfig).UI.BalloonNotifications'
	configToastAppName                                                     = '(Get-ADTConfig).UI.BalloonTitle'
	configToastDisable                                                     = '(Get-ADTConfig).UI.BalloonNotifications'
	configToolkitCachePath                                                 = '(Get-ADTConfig).Toolkit.CachePath'
	configToolkitCompressLogs                                              = '(Get-ADTConfig).Toolkit.CompressLogs'
	configToolkitLogAppend                                                 = '(Get-ADTConfig).Toolkit.LogAppend'
	configToolkitLogDebugMessage                                           = '(Get-ADTConfig).Toolkit.LogDebugMessage'
	configToolkitLogDir                                                    = 'if ($isAdmin) { (Get-ADTConfig).Toolkit.LogPath } else { (Get-ADTConfig).Toolkit.LogPathNoAdminRights }'
	configToolkitLogMaxHistory                                             = '(Get-ADTConfig).Toolkit.LogMaxHistory'
	configToolkitLogMaxSize                                                = '(Get-ADTConfig).Toolkit.LogMaxSize'
	configToolkitLogStyle                                                  = '(Get-ADTConfig).Toolkit.LogStyle'
	configToolkitLogWriteToHost                                            = '(Get-ADTConfig).Toolkit.LogWriteToHost'
	configToolkitRegPath                                                   = '(Get-ADTConfig).Toolkit.RegPath'
	configToolkitRequireAdmin                                              = '$adtSession.RequireAdmin'
	configToolkitTempPath                                                  = 'if ($isAdmin) { (Get-ADTConfig).Toolkit.TempPath } else { (Get-ADTConfig).Toolkit.TempPathNoAdminRights }'
	configToolkitUseRobocopy                                               = '(Get-ADTConfig).Toolkit.FileCopyMode -eq ''Robocopy'''
	configWelcomePromptCountdownMessage                                    = '(Get-ADTStringTable).WelcomePrompt.Classic.CountdownMessage'
	configWelcomePromptCustomMessage                                       = '(Get-ADTStringTable).WelcomePrompt.Classic.CustomMessage'
	CountdownNoHideSeconds                                                 = $null
	CountdownSeconds                                                       = $null
	currentTime                                                            = '$adtSession.CurrentDateTime'
	currentTimeZoneBias                                                    = $null
	defaultFont                                                            = $null
	deployModeNonInteractive                                               = $null
	deployModeSilent                                                       = $null
	DeviceContextHandle                                                    = $null
	dirAppDeployTemp                                                       = $null
	dpiPixels                                                              = $null
	dpiScale                                                               = $null
	envOfficeChannelProperty                                               = $null
	envShellFolders                                                        = $null
	exeMsiexec                                                             = $null
	exeSchTasks                                                            = $null
	exeWusa                                                                = $null
	ExitOnTimeout                                                          = $null
	formattedOSArch                                                        = $null
	formWelcomeStartPosition                                               = $null
	GetAccountNameUsingSid                                                 = $null
	GetDisplayScaleFactor                                                  = $null
	GetLoggedOnUserDetails                                                 = $null
	GetLoggedOnUserTempPath                                                = $null
	GraphicsObject                                                         = $null
	HKULanguages                                                           = $null
	HKUPrimaryLanguageShort                                                = $null
	hr                                                                     = $null
	Icon                                                                   = $null
	installationStarted                                                    = $null
	InvocationInfo                                                         = $null
	invokingScript                                                         = $null
	IsOOBEComplete                                                         = 'Test-ADTOobeCompleted'
	IsTaskSchedulerHealthy                                                 = $null
	LocalPowerUsersGroup                                                   = $null
	LogFileInitialized                                                     = $null
	loggedOnUserTempPath                                                   = $null
	LogicalScreenHeight                                                    = $null
	LogTimeZoneBias                                                        = $null
	mainExitCode                                                           = $null
	Message                                                                = $null
	MessageAlignment                                                       = $null
	MinimizeWindows                                                        = $null
	moduleAppDeployToolkitMain                                             = $null
	msiRebootDetected                                                      = $null
	NoCountdown                                                            = $null
	notifyIcon                                                             = $null
	OldDisableLoggingValue                                                 = $null
	oldPSWindowTitle                                                       = $null
	PersistPrompt                                                          = $null
	PhysicalScreenHeight                                                   = $null
	PrimaryWindowsUILanguage                                               = $null
	ProgressRunspace                                                       = $null
	ProgressSyncHash                                                       = $null
	ReferencedAssemblies                                                   = $null
	ReferredInstallName                                                    = $null
	ReferredInstallTitle                                                   = $null
	ReferredLogName                                                        = $null
	regKeyAppExecution                                                     = $null
	regKeyApplications                                                     = $null
	regKeyDeferHistory                                                     = $null
	regKeyLotusNotes                                                       = $null
	RevertScriptLogging                                                    = $null
	runningProcessDescriptions                                             = $null
	scriptFileName                                                         = $null
	scriptName                                                             = $null
	scriptParentPath                                                       = $null
	scriptPath                                                             = $null
	scriptRoot                                                             = $null
	scriptSeparator                                                        = $null
	ShowBlockedAppDialog                                                   = $null
	ShowInstallationPrompt                                                 = $null
	ShowInstallationRestartPrompt                                          = $null
	switch                                                                 = $null
	Timeout                                                                = $null
	Title                                                                  = $null
	TopMost                                                                = $null
	TypeDef                                                                = $null
	UserDisplayScaleFactor                                                 = $null
	welcomeTimer                                                           = $null
	xmlBannerIconOptions                                                   = $null
	xmlConfig                                                              = $null
	xmlConfigFile                                                          = $null
	xmlConfigMSIOptions                                                    = $null
	xmlConfigUIOptions                                                     = $null
	xmlLoadLocalizedUIMessages                                             = $null
	xmlToastOptions                                                        = $null
	xmlToolkitOptions                                                      = $null
	xmlUIMessageLanguage                                                   = $null
	xmlUIMessages                                                          = $null
	#endregion PSAppDeployToolkit variables v3.10.2
	#region neo42 Extension variables
	SoftMigrationCustomResult                                              = '$adtSession.NXT.SoftMigration.Result'
	AppInstallDetectionCustomResult                                        = '$adtSession.NXT.Detection.IsInstalled'
	RegisterPackage                                                        = '$adtSession.NXT.Package.Register'
	AppRootFolder                                                          = '$adtSession.NXT.Package.Directory.FullName'
	AppLogFolder                                                           = '$adtSession.LogPath'
	SetupCfg                                                               = '$adtSession.NXT.SetupCfg'
	CustomSetupCfg                                                         = $null
	UserPartDir                                                            = $null
	ProgramFilesDir                                                        = $null
	ProgramFilesDirx86                                                     = '$envProgramFilesW3264'
	ProgramW6432                                                           = '$envProgramFiles'
	CommonFilesDir                                                         = $null
	CommonFilesDirx86                                                      = '$envCommonProgramFilesW3264'
	CommonProgramW6432                                                     = '$envCommonProgramFiles'
	RegSoftwarePath                                                        = $null
	RegSoftwarePathx86                                                     = '$envRegistrySoftwareW3264'
	System                                                                 = $null
	DeployApplicationPath                                                  = '$PSCommandPath'
	AppDeployToolkitExtensionsPath                                         = $null
	AppDeployToolkitConfigPath                                             = $null
	DeploymentSystem                                                       = '$adtSession.NXT.DeploymentSystem'
	Neo42PackageConfigPath                                                 = $null
	Neo42PackageConfigValidationPath                                       = $null
	SetupCfgPath                                                           = $null
	CustomSetupCfgPath                                                     = $null
	ResultToCheck                                                          = '$adtSession.NXT.ProcessResults[-1]'
	#endregion neo42 Extension variables
}

[System.Collections.Hashtable]$script:FunctionMappings = @{
	#region ADT Functions Mappings
	'Write-Log'                              = @{
		'NewFunction'         = 'Write-ADTLogEntry'
		'TransformParameters' = @{
			'Text'            = { "-Message $_" }
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
			'Source'          = { if ($_ -match '\bDeployAppScriptFriendlyName\b') { $null } else { "-Source $_" } }
		}
		'RemoveParameters'    = @(
			'AppendToLogFile'
			'LogDebugMessage'
			'MaxLogHistory'
			'MaxLogFileSizeMB'
			'WriteHost'
		)
	}
	'Exit-Script'                            = @{
		'NewFunction' = 'Exit-ADTScript'
	}
	'Invoke-HKCURegistrySettingsForAllUsers' = @{
		'NewFunction'         = 'Invoke-ADTAllUsersRegistryAction'
		'TransformParameters' = @{
			'RegistrySettings' = { "-ScriptBlock $($_ -replace '\$UserProfile', '$_')" }
		}
	}
	'Get-HardwarePlatform'                   = @{
		'NewFunction'      = '$envHardwareType'
		'RemoveParameters' = @(
			'ContinueOnError'
		)
	}
	'Get-FreeDiskSpace'                      = @{
		'NewFunction'         = 'Get-ADTFreeDiskSpace'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Remove-InvalidFileNameChars'            = @{
		'NewFunction' = 'Remove-ADTInvalidFileNameChars'
	}
	'Get-InstalledApplication'               = @{
		'NewFunction'         = 'Get-ADTApplication'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
			'Exact'           = '-NameMatch Exact' # Should inspect switch values here in case of -Switch:$false
			'WildCard'        = '-NameMatch WildCard' # Should inspect switch values here in case of -Switch:$false
			'RegEx'           = '-NameMatch RegEx' # Should inspect switch values here in case of -Switch:$false
		}
	}
	'Remove-MSIApplications'                 = @{
		'NewFunction'         = 'Uninstall-ADTApplication'
		'TransformParameters' = @{
			'ContinueOnError'      = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
			'Exact'                = '-NameMatch Exact' # Should inspect switch values here in case of -Switch:$false
			'WildCard'             = '-NameMatch WildCard' # Should inspect switch values here in case of -Switch:$false
			'Arguments'            = { "-ArgumentList $_" }
			'Parameters'           = { "-ArgumentList $_" }
			'AddParameters'        = { "-AdditionalArgumentList $_" }
			'LogName'              = { "-LogFileName $_" }
			'private:LogName'      = { "-LogFileName $_" }
			'FilterApplication'    = {
				$filterApplication = @(if ($null -eq $boundParameters.FilterApplication.Value.Extent) { $null } else { $boundParameters.FilterApplication.Value.SafeGetValue() })
				$excludeFromUninstall = @(if ($null -eq $boundParameters.ExcludeFromUninstall.Value.Extent) { $null } else { $boundParameters.ExcludeFromUninstall.Value.SafeGetValue() })

				$filterArray = $(
					foreach ($item in $filterApplication) {
						if ($null -ne $item) {
							if ($item.Count -eq 1 -and $item[0].Count -eq 3) { $item = $item[0] } # Handle the case where input is of the form @(, @('Prop', 'Value', 'Exact'), @('Prop', 'Value', 'Exact'))
							if ($item[2] -eq 'RegEx') {
								"`$_.$($item[0]) -match '$($item[1] -replace "'","''")'"
							}
							elseif ($item[2] -eq 'Contains') {
								$regEx = [System.Text.RegularExpressions.Regex]::Escape(($item[1] -replace "'", "''")) -replace '(?<!\\)\\ ', ' '
								"`$_.$($item[0]) -match '$regEx'"
							}
							elseif ($item[2] -eq 'WildCard') {
								"`$_.$($item[0]) -like '$($item[1] -replace "'","''")'"
							}
							elseif ($item[2] -eq 'Exact') {
								if ($item[1] -is [System.Boolean]) {
									"`$_.$($item[0]) -eq `$$($item[1].ToString().ToLower())"
								}
								else {
									"`$_.$($item[0]) -eq '$($item[1] -replace "'","''")'"
								}
							}
						}
					}
					foreach ($item in $excludeFromUninstall) {
						if ($null -ne $item) {
							if ($item.Count -eq 1 -and $item[0].Count -eq 3) { $item = $item[0] } # Handle the case where input is of the form @(, @('Prop', 'Value', 'Exact'), @('Prop', 'Value', 'Exact'))
							if ($item[2] -eq 'RegEx') {
								"`$_.$($item[0]) -notmatch '$($item[1] -replace "'","''")'"
							}
							elseif ($item[2] -eq 'Contains') {
								$regEx = [System.Text.RegularExpressions.Regex]::Escape(($item[1] -replace "'", "''")) -replace '(?<!\\)\\ ', ' '
								"`$_.$($item[0]) -notmatch '$regEx'"
							}
							elseif ($item[2] -eq 'WildCard') {
								"`$_.$($item[0]) -notlike '$($item[1] -replace "'","''")'"
							}
							elseif ($item[2] -eq 'Exact') {
								if ($item[1] -is [System.Boolean]) {
									"`$_.$($item[0]) -ne `$$($item[1].ToString().ToLower())"
								}
								else {
									"`$_.$($item[0]) -ne '$($item[1] -replace "'","''")'"
								}
							}
						}
					}
				)

				if ($filterArray) {
					"-FilterScript { $([System.String]::Join(' -and ', $filterArray)) }"
				}
			}
			'ExcludeFromUninstall' = {
				$filterApplication = @(if ($null -eq $boundParameters.FilterApplication.Value.Extent) { $null } else { $boundParameters.FilterApplication.Value.SafeGetValue() })
				$excludeFromUninstall = @(if ($null -eq $boundParameters.ExcludeFromUninstall.Value.Extent) { $null } else { $boundParameters.ExcludeFromUninstall.Value.SafeGetValue() })

				$filterArray = $(
					foreach ($item in $filterApplication) {
						if ($null -ne $item) {
							if ($item.Count -eq 1 -and $item[0].Count -eq 3) { $item = $item[0] } # Handle the case where input is of the form @(, @('Prop', 'Value', 'Exact'), @('Prop', 'Value', 'Exact'))
							if ($item[2] -eq 'RegEx') {
								"`$_.$($item[0]) -match '$($item[1] -replace "'","''")'"
							}
							elseif ($item[2] -eq 'Contains') {
								$regEx = [System.Text.RegularExpressions.Regex]::Escape(($item[1] -replace "'", "''")) -replace '(?<!\\)\\ ', ' '
								"`$_.$($item[0]) -match '$regEx'"
							}
							elseif ($item[2] -eq 'WildCard') {
								"`$_.$($item[0]) -like '$($item[1] -replace "'","''")'"
							}
							elseif ($item[2] -eq 'Exact') {
								if ($item[1] -is [System.Boolean]) {
									"`$_.$($item[0]) -eq `$$($item[1].ToString().ToLower())"
								}
								else {
									"`$_.$($item[0]) -eq '$($item[1] -replace "'","''")'"
								}
							}
						}
					}
					foreach ($item in $excludeFromUninstall) {
						if ($null -ne $item) {
							if ($item.Count -eq 1 -and $item[0].Count -eq 3) { $item = $item[0] } # Handle the case where input is of the form @(, @('Prop', 'Value', 'Exact'), @('Prop', 'Value', 'Exact'))
							if ($item[2] -eq 'RegEx') {
								"`$_.$($item[0]) -notmatch '$($item[1] -replace "'","''")'"
							}
							elseif ($item[2] -eq 'Contains') {
								$regEx = [System.Text.RegularExpressions.Regex]::Escape(($item[1] -replace "'", "''")) -replace '(?<!\\)\\ ', ' '
								"`$_.$($item[0]) -notmatch '$regEx'"
							}
							elseif ($item[2] -eq 'WildCard') {
								"`$_.$($item[0]) -notlike '$($item[1] -replace "'","''")'"
							}
							elseif ($item[2] -eq 'Exact') {
								if ($item[1] -is [System.Boolean]) {
									"`$_.$($item[0]) -ne `$$($item[1].ToString().ToLower())"
								}
								else {
									"`$_.$($item[0]) -ne '$($item[1] -replace "'","''")'"
								}
							}
						}
					}
				)

				if ($filterArray) {
					"-FilterScript { $([System.String]::Join(' -and ', $filterArray)) }"
				}
			}
		}
		'AddParameters'       = @{
			'ApplicationType' = '-ApplicationType MSI'
		}
	}
	'Get-FileVersion'                        = @{
		'NewFunction'         = 'Get-ADTFileVersion'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Get-UserProfiles'                       = @{
		'NewFunction'         = 'Get-ADTUserProfiles'
		'TransformParameters' = @{
			'ContinueOnError'        = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
			'ExcludeSystemProfiles'  = { if ($_ -eq '$false') { '-IncludeSystemProfiles' } }
			'ExcludeServiceProfiles' = { if ($_ -eq '$false') { '-IncludeServiceProfiles' } }
		}
	}
	'Update-Desktop'                         = @{
		'NewFunction'         = 'Update-ADTDesktop'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Refresh-Desktop'                        = @{
		'NewFunction'         = 'Update-ADTDesktop'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Update-SessionEnvironmentVariables'     = @{
		'NewFunction'         = 'Update-ADTEnvironmentPsProvider'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Refresh-SessionEnvironmentVariables'    = @{
		'NewFunction'         = 'Update-ADTEnvironmentPsProvider'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Copy-File'                              = @{
		'NewFunction'         = 'Copy-ADTFile'
		'TransformParameters' = @{
			'ContinueOnError'         = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
			'ContinueFileCopyOnError' = { if ($_ -eq '$true') { '-ContinueFileCopyOnError' } else { $null } }
			'UseRobocopy'             = { if ($_ -eq '$true' -or $boundParameters.ContainsKey('RobocopyParams') -or $boundParameters.ContainsKey('RobocopyAdditionalParams')) { '-FileCopyMode Robocopy' } else { '-FileCopyMode Native' } }
		}
	}
	'Remove-File'                            = @{
		'NewFunction'         = 'Remove-ADTFile'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Copy-FileToUserProfiles'                = @{
		'NewFunction'         = 'Copy-ADTFileToUserProfiles'
		'TransformParameters' = @{
			'ContinueOnError'         = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
			'ContinueFileCopyOnError' = { if ($_ -eq '$true') { '-ContinueFileCopyOnError' } else { $null } }
			'UseRobocopy'             = { if ($_ -eq '$true' -or $boundParameters.ContainsKey('RobocopyParams') -or $boundParameters.ContainsKey('RobocopyAdditionalParams')) { '-FileCopyMode Robocopy' } else { '-FileCopyMode Native' } }
			'ExcludeSystemProfiles'   = { if ($_ -eq '$false') { '-IncludeSystemProfiles' } }
			'ExcludeServiceProfiles'  = { if ($_ -eq '$false') { '-IncludeServiceProfiles' } }
		}
	}
	'Show-InstallationPrompt'                = @{
		'NewFunction'         = 'Show-ADTInstallationPrompt'
		'TransformParameters' = @{
			'Icon'          = { if ($_ -ne 'None') { "-Icon $_" } }
			'ExitOnTimeout' = { if ($_ -eq '$false') { '-NoExitOnTimeout' } }
			'TopMost'       = { if ($_ -eq '$false') { '-NotTopMost' } }
		}
	}
	'Show-InstallationProgress'              = @{
		'NewFunction'         = 'Show-ADTInstallationProgress'
		'TransformParameters' = @{
			'TopMost' = { if ($_ -eq '$false') { '-NotTopMost' } }
			'Quiet'   = '-InformationAction SilentlyContinue' # Should inspect switch values here in case of -Switch:$false
		}
	}
	'Show-DialogBox'                         = @{
		'NewFunction'         = 'Show-ADTDialogBox'
		'TransformParameters' = @{
			'TopMost' = { if ($_ -eq '$false') { '-NotTopMost' } }
		}
	}
	'Show-InstallationWelcome'               = @{
		'NewFunction'         = 'Show-ADTInstallationWelcome'
		'TransformParameters' = @{
			'MinimizeWindows'         = { if ($_ -eq '$false') { '-NoMinimizeWindows' } }
			'TopMost'                 = { if ($_ -eq '$false') { '-NotTopMost' } }
			'CloseAppsCountdown'      = { "-CloseProcessesCountdown $_" }
			'ForceCloseAppsCountdown' = { "-ForceCloseProcessesCountdown $_" }
			'AllowDeferCloseApps'     = '-AllowDeferCloseProcesses' # Should inspect switch values here in case of -Switch:$false
			'CloseApps'               = {
				$quoteChar = if ($boundParameters.CloseApps.Value.StringConstantType -eq 'DoubleQuoted') { '"' } else { "'" }
				$closeProcesses = $boundParameters.CloseApps.Value.Value -split ',' | & {
					process {
						$name, $description = $_ -split '='
						if ($description) {
							"@{ Name = $quoteChar$($name)$quoteChar; Description = $quoteChar$($description)$quoteChar }"
						}
						else {
							"$quoteChar$($name)$quoteChar"
						}
					}
				}
				$closeProcesses = $closeProcesses -join ', '
				"-CloseProcesses $closeProcesses"
			}
		}
		'RemoveParameters'    = @(
			'BlockExecution'
		)
	}
	'Get-WindowTitle'                        = @{
		'NewFunction'         = 'Get-ADTWindowTitle'
		'TransformParameters' = @{
			'DisableFunctionLogging' = '-InformationAction SilentlyContinue' # Should inspect switch values here in case of -Switch:$false
		}
	}
	'Show-InstallationRestartPrompt'         = @{
		'NewFunction'         = 'Show-ADTInstallationRestartPrompt'
		'TransformParameters' = @{
			'NoSilentRestart' = { if ($_ -eq '$false') { '-SilentRestart' } }
			'TopMost'         = { if ($_ -eq '$false') { '-NotTopMost' } }
		}
	}
	'Show-BalloonTip'                        = @{
		'NewFunction'      = 'Show-ADTBalloonTip'
		'RemoveParameters' = @(
			'NoWait'
		)
	}
	'Copy-ContentToCache'                    = @{
		'NewFunction' = 'Copy-ADTContentToCache'
	}
	'Remove-ContentFromCache'                = @{
		'NewFunction' = 'Remove-ADTContentFromCache'
	}
	'Test-NetworkConnection'                 = @{
		'NewFunction' = 'Test-ADTNetworkConnection'
	}
	'Get-LoggedOnUser'                       = @{
		'NewFunction' = 'Get-ADTLoggedOnUser'
	}
	'Get-IniValue'                           = @{
		'NewFunction'         = 'Get-ADTIniValue'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Set-IniValue'                           = @{
		'NewFunction'         = 'Set-ADTIniValue'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'New-Folder'                             = @{
		'NewFunction'         = 'New-ADTFolder'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Test-PowerPoint'                        = @{
		'NewFunction' = 'Test-ADTPowerPoint'
	}
	'Update-GroupPolicy'                     = @{
		'NewFunction'         = 'Update-ADTGroupPolicy'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Get-UniversalDate'                      = @{
		'NewFunction'         = 'Get-ADTUniversalDate'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Test-ServiceExists'                     = @{
		'NewFunction'         = 'Test-ADTServiceExists'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
		'RemoveParameters'    = @(
			'ComputerName'
		)
	}
	'Disable-TerminalServerInstallMode'      = @{
		'NewFunction'         = 'Disable-ADTTerminalServerInstallMode'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Enable-TerminalServerInstallMode'       = @{
		'NewFunction'         = 'Enable-ADTTerminalServerInstallMode'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Configure-EdgeExtension'                = @{
		'NewFunction'      = { if ($boundParameters.ContainsKey('Add')) { 'Add-ADTEdgeExtension' } else { 'Remove-ADTEdgeExtension' } }  # Should inspect switch values here in case of -Switch:$false
		'RemoveParameters' = @(
			'Add'
			'Remove'
		)
	}
	'Resolve-Error'                          = @{
		'NewFunction'   = 'Resolve-ADTErrorRecord'
		'AddParameters' = @{
			'ExcludeErrorRecord'         = {
				if (-not $boundParameters.ContainsKey('GetErrorRecord') -or $false -eq $boundParameters.GetErrorRecord.ConstantValue -or $boundParameters.GetErrorRecord.Value.Extent.Text -eq '$false') { '-ExcludeErrorRecord' }
			}
			'ExcludeErrorInvocation'     = {
				if (-not $boundParameters.ContainsKey('GetErrorInvocation') -or $false -eq $boundParameters.GetErrorInvocation.ConstantValue -or $boundParameters.GetErrorInvocation.Value.Extent.Text -eq '$false') { '-ExcludeErrorInvocation' }
			}
			'ExcludeErrorException'      = {
				if (-not $boundParameters.ContainsKey('GetErrorException') -or $false -eq $boundParameters.GetErrorException.ConstantValue -or $boundParameters.GetErrorException.Value.Extent.Text -eq '$false') { '-ExcludeErrorException' }
			}
			'ExcludeErrorInnerException' = {
				if (-not $boundParameters.ContainsKey('GetErrorInnerException') -or $false -eq $boundParameters.GetErrorInnerException.ConstantValue -or $boundParameters.GetErrorInnerException.Value.Extent.Text -eq '$false') { '-ExcludeErrorInnerException' }
			}
		}
	}
	'Get-ServiceStartMode'                   = @{
		'NewFunction'         = 'Get-ADTServiceStartMode'
		'TransformParameters' = @{
			'Name'            = { "-Service $_" }
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
		'RemoveParameters'    = @(
			'ComputerName'
		)
	}
	'Set-ServiceStartMode'                   = @{
		'NewFunction'         = 'Set-ADTServiceStartMode'
		'TransformParameters' = @{
			'Name'            = { "-Service $_" }
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
		'RemoveParameters'    = @(
			'ComputerName'
		)
	}
	'Execute-Process'                        = @{
		'NewFunction'         = 'Start-ADTProcess'
		'TransformParameters' = @{
			'Path'                 = { "-FilePath $_" }
			'Arguments'            = { "-ArgumentList $_" }
			'Parameters'           = { "-ArgumentList $_" }
			'SecureParameters'     = '-SecureArgumentList' # Should inspect switch values here in case of -Switch:$false
			'IgnoreExitCodes'      = { '-IgnoreExitCodes ' + ($_.Extent.Text -replace '"|''', [System.String]::Empty) }
			'ExitOnProcessFailure' = {
				$exitOnProcessFailure = if ($null -eq $boundParameters.ExitOnProcessFailure.Value.Extent) { $true } else { $boundParameters.ExitOnProcessFailure.Value.SafeGetValue() }
				if ($exitOnProcessFailure) { '-ExitOnProcessFailure' }
			}
			'ContinueOnError'      = {
				$continueOnError = if ($null -eq $boundParameters.ContinueOnError.Value.Extent) { $false } else { $boundParameters.ContinueOnError.Value.SafeGetValue() }
				if ($continueOnError) { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' }
			}
		}
	}
	'Execute-MSI'                            = @{
		'NewFunction'         = 'Start-ADTMsiProcess'
		'TransformParameters' = @{
			'Path'                 = { if ($_ -match '^[''"]?\{?([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}\}?[''"]?$') { "-ProductCode $_" } else { "-FilePath $_" } }
			'Arguments'            = { "-ArgumentList $_" }
			'Parameters'           = { "-ArgumentList $_" }
			'AddParameters'        = { "-AdditionalArgumentList $_" }
			'SecureParameters'     = '-SecureArgumentList' # Should inspect switch values here in case of -Switch:$false
			'Transform'            = { "-Transforms $(if ($_ -match "^'") { $_ -replace ';', "','" } elseif ($_ -match '^"') { $_ -replace ';', '","' } else { $_ })" }
			'LogName'              = { "-LogFileName $_" }
			'private:LogName'      = { "-LogFileName $_" }
			'IgnoreExitCodes'      = { '-IgnoreExitCodes ' + ($_.Extent.Text -replace '"|''', [System.String]::Empty) }
			'ExitOnProcessFailure' = {
				$exitOnProcessFailure = if ($null -eq $boundParameters.ExitOnProcessFailure.Value.Extent) { $true } else { $boundParameters.ExitOnProcessFailure.Value.SafeGetValue() }
				if ($exitOnProcessFailure) { '-ExitOnProcessFailure' }
			}
			'ContinueOnError'      = {
				$continueOnError = if ($null -eq $boundParameters.ContinueOnError.Value.Extent) { $false } else { $boundParameters.ContinueOnError.Value.SafeGetValue() }
				if ($continueOnError) { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' }
			}
		}
	}
	'Execute-MSP'                            = @{
		'NewFunction'         = 'Start-ADTMspProcess'
		'TransformParameters' = @{
			'Path' = { "-FilePath $_" }
		}
	}
	'Block-AppExecution'                     = @{
		'NewFunction' = '#Block-ADTAppExecution => This feature was/will be depreated in PSADT v4.2'
	}
	'Unblock-AppExecution'                   = @{
		'NewFunction' = '#Unblock-ADTAppExecution => This feature was/will be depreated in PSADT v4.2'
	}
	'Test-RegistryValue'                     = @{
		'NewFunction'         = 'Test-ADTRegistryValue'
		'TransformParameters' = @{
			'Value' = { "-Name $_" }
			'SID'   = {
				# If this command is part of a script block and the old variable $userProfile.SID is used, then map to $_.SID
				if ("$_" -eq '$userProfile.SID' -and $commandAst.Parent.Parent.Parent.Parent -is [System.Management.Automation.Language.ScriptBlockExpressionAst]) {
					'-SID $_.SID'
				}
				else {
					"-SID $_"
				}
			}
		}
	}
	'Convert-RegistryPath'                   = @{
		'NewFunction'         = 'Convert-ADTRegistryPath'
		'TransformParameters' = @{
			'DisableFunctionLogging' = { if ($_ -eq '$false') { '-InformationAction Continue' } }
		}
	}
	'Test-MSUpdates'                         = @{
		'NewFunction'         = 'Test-ADTMSUpdates'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Test-Battery'                           = @{
		'NewFunction' = 'Test-ADTBattery'
	}
	'Start-ServiceAndDependencies'           = @{
		'NewFunction'         = 'Start-ADTServiceAndDependencies'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
		'RemoveParameters'    = @(
			'ComputerName'
			'SkipServiceExistsTest'
		)
	}
	'Stop-ServiceAndDependencies'            = @{
		'NewFunction'         = 'Stop-ADTServiceAndDependencies'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
		'RemoveParameters'    = @(
			'ComputerName'
			'SkipServiceExistsTest'
		)
	}
	'Set-RegistryKey'                        = @{
		'NewFunction'         = 'Set-ADTRegistryKey'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
			'SID'             = {
				# If this command is part of a script block and the old variable $userProfile.SID is used, then map to $_.SID
				if ("$_" -eq '$userProfile.SID' -and $commandAst.Parent.Parent.Parent.Parent -is [System.Management.Automation.Language.ScriptBlockExpressionAst]) {
					'-SID $_.SID'
				}
				else {
					"-SID $_"
				}
			}
		}
	}
	'Remove-RegistryKey'                     = @{
		'NewFunction'         = 'Remove-ADTRegistryKey'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
			'SID'             = {
				# If this command is part of a script block and the old variable $userProfile.SID is used, then map to $_.SID
				if ("$_" -eq '$userProfile.SID' -and $commandAst.Parent.Parent.Parent.Parent -is [System.Management.Automation.Language.ScriptBlockExpressionAst]) {
					'-SID $_.SID'
				}
				else {
					"-SID $_"
				}
			}
		}
	}
	'Remove-FileFromUserProfiles'            = @{
		'NewFunction'         = 'Remove-ADTFileFromUserProfiles'
		'TransformParameters' = @{
			'ContinueOnError'        = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
			'ExcludeSystemProfiles'  = { if ($_ -eq '$false') { '-IncludeSystemProfiles' } }
			'ExcludeServiceProfiles' = { if ($_ -eq '$false') { '-IncludeServiceProfiles' } }
		}
	}
	'Get-RegistryKey'                        = @{
		'NewFunction'         = 'Get-ADTRegistryKey'
		'TransformParameters' = @{
			'Value'           = { "-Name $_" }
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Install-MSUpdates'                      = @{
		'NewFunction' = 'Install-ADTMSUpdates'
	}
	'Get-SchedulerTask'                      = @{
		'NewFunction'         = 'Get-ADTSchedulerTask'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Get-PendingReboot'                      = @{
		'NewFunction' = 'Get-ADTPendingReboot'
	}
	'Invoke-RegisterOrUnregisterDLL'         = @{
		'NewFunction'         = 'Invoke-ADTRegSvr32'
		'TransformParameters' = @{
			'DLLAction'       = { "-Action $_" }
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Register-DLL'                           = @{
		'NewFunction'         = 'Register-ADTDll'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Unregister-DLL'                         = @{
		'NewFunction'         = 'Unregister-ADTDll'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Remove-Folder'                          = @{
		'NewFunction'         = 'Remove-ADTFolder'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Set-ActiveSetup'                        = @{
		'NewFunction'         = 'Set-ADTActiveSetup'
		'TransformParameters' = @{
			'ContinueOnError'       = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
			'ExecuteForCurrentUser' = { if ($_ -eq '$false') { '-NoExecuteForCurrentUser' } }
		}
	}
	'Set-ItemPermission'                     = @{
		'NewFunction'         = 'Set-ADTItemPermission'
		'TransformParameters' = @{
			'ContinueOnError'   = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
			'File'              = { "-Path $_" }
			'Folder'            = { "-Path $_" }
			'Username'          = { "-User $_" }
			'Users'             = { "-User $_" }
			'SID'               = { "-User $_" }
			'Usernames'         = { "-User $_" }
			'Acl'               = { "-Permission $_" }
			'Grant'             = { "-Permission $_" }
			'Permissions'       = { "-Permission $_" }
			'Deny'              = { "-Permission $_" }
			'AccessControlType' = { "-PermissionType $_" }
			'Add'               = { "-Method $($_ -replace '^(Add|Set|Reset|Remove)(Specific|All)?$', '$1AccessRule$2')" }
			'ApplyMethod'       = { "-Method $($_ -replace '^(Add|Set|Reset|Remove)(Specific|All)?$', '$1AccessRule$2')" }
			'ApplicationMethod' = { "-Method $($_ -replace '^(Add|Set|Reset|Remove)(Specific|All)?$', '$1AccessRule$2')" }
			'Method'            = { "-Method $($_ -replace '^(Add|Set|Reset|Remove)(Specific|All)?$', '$1AccessRule$2')" }
		}
	}
	'New-MsiTransform'                       = @{
		'NewFunction'         = 'New-ADTMsiTransform'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Invoke-SCCMTask'                        = @{
		'NewFunction'         = 'Invoke-ADTSCCMTask'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Install-SCCMSoftwareUpdates'            = @{
		'NewFunction'         = 'Install-ADTSCCMSoftwareUpdates'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Send-Keys'                              = @{
		'NewFunction' = 'Send-ADTKeys'
	}
	'Get-Shortcut'                           = @{
		'NewFunction'         = 'Get-ADTShortcut'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Set-Shortcut'                           = @{
		'NewFunction'         = 'Set-ADTShortcut'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'New-Shortcut'                           = @{
		'NewFunction'         = 'New-ADTShortcut'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Execute-ProcessAsUser'                  = @{
		'NewFunction'         = 'Start-ADTProcessAsUser'
		'TransformParameters' = @{
			'Path'             = { "-FilePath $_" }
			'Parameters'       = { "-ArgumentList $_" }
			'SecureParameters' = '-SecureArgumentList' # Should inspect switch values here in case of -Switch:$false
			'ContinueOnError'  = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
		'RemoveParameters'    = @(
			'TempPath'
			'RunLevel'
			'Wait'
		)
		'AddParameters'       = @{
			'NoWait' = { if (-not $boundParameters.ContainsKey('Wait')) { '-NoWait' } }
		}
	}
	'Close-InstallationProgress'             = @{
		'NewFunction'      = 'Close-ADTInstallationProgress'
		'RemoveParameters' = @(
			'WaitingTime'
		)
	}
	'ConvertTo-NTAccountOrSID'               = @{
		'NewFunction' = 'ConvertTo-ADTNTAccountOrSID'
	}
	'Get-DeferHistory'                       = @{
		'NewFunction' = 'Get-ADTDeferHistory'
	}
	'Set-DeferHistory'                       = @{
		'NewFunction' = 'Set-ADTDeferHistory'
	}
	'Get-MsiTableProperty'                   = @{
		'NewFunction'         = 'Get-ADTMsiTableProperty'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Set-MsiProperty'                        = @{
		'NewFunction'         = 'Set-ADTMsiProperty'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Get-MsiExitCodeMessage'                 = @{
		'NewFunction' = 'Get-ADTMsiExitCodeMessage'
	}
	'Get-ObjectProperty'                     = @{
		'NewFunction' = 'Get-ADTObjectProperty'
	}
	'Invoke-ObjectMethod'                    = @{
		'NewFunction' = 'Invoke-ADTObjectMethod'
	}
	'Get-PEFileArchitecture'                 = @{
		'NewFunction'         = 'Get-ADTPEFileArchitecture'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Test-IsMutexAvailable'                  = @{
		'NewFunction' = 'Test-ADTMutexAvailability'
	}
	'New-ZipFile'                            = @{
		'NewFunction'         = 'New-ADTZipFile'
		'TransformParameters' = @{
			'ContinueOnError'                 = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
			'DestinationArchiveDirectoryPath' = {
				$destinationArchiveDirectoryPath = $boundParameters.DestinationArchiveDirectoryPath.Value.Value
				$destinationArchiveFileName = $boundParameters.DestinationArchiveFileName.Value.Value
				$quoteChar = if ($boundParameters.DestinationArchiveDirectoryPath.Value.StringConstantType -eq 'DoubleQuoted' -or $boundParameters.DestinationArchiveFileName.Value.StringConstantType -eq 'DoubleQuoted') { '"' } else { "'" }
				"-DestinationPath $quoteChar$([System.IO.Path]::Combine($destinationArchiveDirectoryPath, $destinationArchiveFileName))$quoteChar"
			}
			'DestinationArchiveFileName'      = {
				$destinationArchiveDirectoryPath = $boundParameters.DestinationArchiveDirectoryPath.Value.Value
				$destinationArchiveFileName = $boundParameters.DestinationArchiveFileName.Value.Value
				$quoteChar = if ($boundParameters.DestinationArchiveDirectoryPath.Value.StringConstantType -eq 'DoubleQuoted' -or $boundParameters.DestinationArchiveFileName.Value.StringConstantType -eq 'DoubleQuoted') { '"' } else { "'" }
				"-DestinationPath $quoteChar$([System.IO.Path]::Combine($destinationArchiveDirectoryPath, $destinationArchiveFileName))$quoteChar"
			}
			'SourceDirectoryPath'             = { "-LiteralPath $_" }
			'SourceFilePath'                  = { "-LiteralPath $_" }
			'OverWriteArchive'                = '-Force' # Should inspect switch values here in case of -Switch:$false
		}
	}
	'Set-PinnedApplication'                  = @{
		'NewFunction' = '# The function [Set-PinnedApplication] has been removed from PSAppDeployToolkit as its functionality no longer works with Windows 10 1809 or higher targets.'
	}
	#endregion ADT Function Mappings
	#region NXT Function Mappings
	'Add-NxtContent'                         = @{
		'PreTest'             = {
			$boundParameters.ContainsKey('DefaultEncoding')
		}
		'NewFunction'         = 'Add-NXTContent'
		'TransformParameters' = @{
			'DefaultEncoding' = { if (-not $boundParameters.ContainsKey('Encoding')) { "-Encoding $_" } }
		}
	}
	'Add-NxtLocalGroup'                      = @{
		'NewFunction'         = 'New-LocalGroup'
		'TransformParameters' = @{
			'GroupName' = { "-Name $_" }
		}
		'RemoveParameters'    = @(
			'COMPUTERNAME'
		)
	}
	'Add-NxtLocalGroupMember'                = @{
		'NewFunction'         = 'New-LocalGroup'
		'TransformParameters' = @{
			'GroupName'  = { "-Name $_" }
			'MemberName' = { "-Member `$(Get-LocalUser -Name $_)" }
		}
		'RemoveParameters'    = @(
			'COMPUTERNAME'
		)
	}
	'Add-NxtLocalUser'                       = @{
		'NewFunction'         = 'New-LocalUser'
		'TransformParameters' = @{
			'UserName'           = { "-Name $_" }
			'Password'           = { "-Password `$(ConvertTo-SecureString -String $_ -AsPlainText -Force)" }
			'SetPwdNeverExpires' = '-PasswordNeverExpires'
		}
		'RemoveParameters'    = @(
			'SetPwdExpired',
			'COMPUTERNAME'
		)
	}
	'Add-NxtProcessPathVariable'             = @{
		'NewFunction'         = 'Add-NXTPathVariable'
		'TransformParameters' = @{
			'AddToBeginning' = { if ($_ -eq '$true') { '-Prepend' } }
		}
		'AddParameters'       = @{
			'Target' = { '-Target Process' }
		}
	}
	'Add-NxtSystemPathVariable'              = @{
		'NewFunction'         = 'Add-NXTPathVariable'
		'TransformParameters' = @{
			'AddToBeginning' = { if ($_ -eq '$true') { '-Prepend' } }
		}
		'AddParameters'       = @{
			'Target' = { "-Target 'Machine'" }
		}
	}
	'Add-NxtXmlNode'                         = @{
		'PreTest'             = {
			$boundParameters.ContainsKey('DefaultEncoding')
		}
		'NewFunction'         = 'Add-NXTXmlNode'
		'TransformParameters' = @{
			'DefaultEncoding' = { if (-not $boundParameters.ContainsKey('Encoding')) { "-Encoding $_" } }
		}
	}
	'Block-NxtAppExecution'                  = @{
		NewFunction      = 'Block-ADTAppExecution'
		RemoveParameters = @(
			'BlockScriptLocation',
			'ScriptDirectory',
			'RegKeyAppExecution'
		)
	}
	'Close-NxtBlockExecutionWindow'          = @{
		'NewFunction' = '#Close-NxtBlockExecutionWindow => This function is not needed anymore. See Block-NxtAppExecution.'
	}
	'Add-NxtParameterToCommand'              = @{
		'NewFunction' = '#Add-NXTParameterToCommand => No migration path available. Build the command line manually or make use of ConvertTo-NXTPsArgumentString'
	}
	'Compare-NxtVersion'                     = @{
		'PreTest'             = {
			$boundParameters.ContainsKey('HexMode') -or
			$boundParameters.ContainsKey('DetectedVersion')
		}
		'NewFunction'         = 'Compare-NXTVersion'
		'TransformParameters' = @{
			'DetectedVersion' = { "-Version $_" }
			'TargetVersion'   = { "-Target $_" }
		}
		'RemoveParameters'    = @(
			'HexMode'
		)
	}
	'Compare-NxtVersionPart'                 = @{
		'NewFunction'         = 'Compare-NXTVersion'
		'TransformParameters' = @{
			'HexMode'             = { if ($_ -eq '$true') { '-Hex' } }
			'DetectedVersionPart' = { "-Version $_" }
			'TargetVersionPart'   = { "-Target $_" }
		}
	}
	'Complete-NxtPackageInstallation'        = @{
		'NewFunction' = '#Complete-NXTPackageInstallation => This was a private function and is handled internally.'
	}
	'Complete-NxtPackageUninstallation'      = @{
		'NewFunction' = '#Complete-NxtPackageUninstallation => This was a private function and is handled internally.'
	}
	'ConvertFrom-NxtEscapedString'           = @{
		'NewFunction'         = 'ConvertFrom-NXTCommandLine'
		'TransformParameters' = @{
			'InputString' = { "-InputObject $_" }
		}
	}
	'Copy-NxtDesktopShortcuts'               = @{
		'NewFunction' = '#Copy-NXTDesktopShortcuts => This was a private function and is not needed anymore. Make use of Copy-ADTFile.'
	}
	'Clear-NxtTempFolder'                    = @{
		'NewFunction' = '#Clear-NXTTempFolder => This function is not needed anymore. Cleanup is handled automatically.'
	}
	'Execute-NxtBitRockInstaller'            = @{
		'NewFunction' = '#Execute-NxtBitRockInstaller => No migration path available. (Un)Install-NXTApplication -Method BitRockInstaller instead.'
	}
	'Execute-NxtInnoSetup'                   = @{
		'NewFunction' = '#Execute-NxtInnoSetup => No migration path available. (Un)Install-NXTApplication -Method InnoSetup instead.'
	}
	'Execute-NxtMsi'                         = @{
		'NewFunction' = '#Execute-NxtMsi => No migration path available. (Un)Install-NXTApplication -Method MSI instead.'
	}
	'Execute-NxtNullsoft'                    = @{
		'NewFunction' = '#Execute-NxtNullsoft => No migration path available. (Un)Install-NXTApplication -Method Nullsoft instead.'
	}
	'Expand-NxtPackageConfig'                = @{
		'NewFunction' = '#Expand-NxtPackageConfig => This was a private function and is not needed anymore. The config is expanded automatically.'
	}
	'Expand-NXTVariablesInFile'              = @{
		'PreTest'     = {
			-not $boundParameters.ContainsKey('Variables')
		}
		'NewFunction' = '#Expand-NXTVariablesInFile => Expanding variables now requires specifying which variables shall be used for expansion.'
	}
	'Exit-NxtAbortReboot'                    = @{
		'NewFunction'         = 'Exit-NXTDeployment'
		'TransformParameters' = @{
			'RebootExitCode' = { "-ExitCode $_" }
			'RebootMessage'  = { "-Message $_" }
		}
		'RemoveParameters'    = @(
			'PackageMachineKey'
			'PackageUninstallKey'
			'PackageStatus'
			'EmpirumMachineKey'
			'EmpirumUninstallKey'
		)
		'AddParameters'       = @{
			'AbortReboot' = { if (-not $boundParameters.ContainsKey('RebootExitCode') -and -not $boundParameters.ContainsKey('RebootMessage')) { '-AbortReboot' } else { '-NoRegistration' } }
		}
	}
	'Exit-NxtScriptWithError'                = @{
		'NewFunction'         = 'Exit-NXTDeployment'
		'TransformParameters' = @{
			'RegisterPackage'   = { if ($_ -like '*false') { '-NoRegistration' } }
			'MainExitCode'      = { "-ExitCode $_" }
			'ErrorMessage'      = { "-Message $_" }
			'ErrorMessagePSADT' = { if (-not $boundParameters.ContainsKey('ErrorMessage')) { "-Message $_" } }
		}
		'RemoveParameters'    = @(
			'RegPackagesKey',
			'App',
			'DeploymentTimestamp',
			'DebugLogFile',
			'AppVendor',
			'AppArch',
			'PackageStatus',
			'AppRevision',
			'ScriptParentPath',
			'EnvArchitecture',
			'EnvUserDomain',
			'EnvUserName',
			'ProcessNTAccountSID',
			'UninstallOld',
			'UserPartOnInstallation',
			'UserPartOnUnInstallation',
			'TempRootFolder',
			'HoursToKeep',
			'NxtTempDirectories',
			'BlockExecution',
			'DeploymentType'
		)
		'AddParameters'       = @{
			'DeploymentStatus' = {
				if (-not $boundParameters.ContainsKey('RegisterPackage') -and
					-not $boundParameters.ContainsKey('MainExitCode') -and
					-not $boundParameters.ContainsKey('ErrorMessage') -and
					-not $boundParameters.ContainsKey('ErrorMessagePSADT')
				) { '-DeploymentStatus Error' } }
		}
	}
	'Format-NxtPackageSpecificVariables'     = @{
		'NewFunction' = '#Format-NXTPackageSpecificVariables => This function was a private function and is not needed anymore.'
	}
	'Get-NxtComputerManufacturer'            = @{
		'NewFunction' = '$envComputerManufacturer'
	}
	'Get-NxtComputerModel'                   = @{
		'NewFunction' = '$envComputerModel'
	}
	'Get-NxtCurrentDisplayVersion'           = @{
		'NewFunction' = '#Get-NxtCurrentDisplayVersion => No migration path available. Use Get-ADTApplication or $adtSession.NXT.InstalledApplication.DisplayVersion'
	}
	'Get-NXTFileVersion'                     = @{
		'NewFunction'         = 'Get-ADTFileVersion'
		'TransformParameters' = @{
			'FilePath' = { "-File $_" }
		}
	}
	'Get-NxtInstalledApplication'            = @{
		'NewFunction' = {
			if ($boundParameters.Count -eq 0) {
				'$adtSession.NXT.Detection.Application'
			}
			else {
				'# Get-NxtInstalledApplication => No migration path available. Use Get-ADTApplication (or use Get-NXTApplication) with appropriate parameters.'
			}
		}
	}
	'Get-NxtNameBySid'                       = @{
		'NewFunction' = 'ConvertTo-ADTNTAccountOrSID'
	}
	'Get-NxtOsLanguage'                      = @{
		'NewFunction' = '$culture.LCID'
	}
	'Get-NxtParentProcess'                   = @{
		'NewFunction'      = 'Get-NXTParentProcess'
		'PreTest'          = {
			$boundParameters.ContainsKey('ProcessIdsToExcludeFromRecursion')
		}
		'RemoveParameters' = @(
			'ProcessIdsToExcludeFromRecursion'
		)
	}
	'Get-NxtProcessEnvironmentVariable'      = @{
		'NewFunction'         = 'Get-ADTEnvironmentVariable'
		'AddParameters'       = @{
			'Target' = { "-Target 'Process'" }
		}
		'TransformParameters' = @{
			'Key' = { "-Variable $_" }
		}
	}
	'Get-NxtProcessName'                     = @{
		'NewFunction' = '#Get-NXTProcessName => No migration path available. Use (Get-Process -id <id>).Name'
	}
	'Get-NxtProcessorArchiteW6432'           = @{
		'NewFunction'      = '$env:PROCESSOR_ARCHITEW6432'
		'RemoveParameters' = @(
			'PROCESSOR_ARCHITEW6432'
		)
	}
	'Get-NxtProcessTree'                     = @{
		'PreTest'             = {
			$boundParameters.ContainsKey('IncludeChildProcesses') -or $boundParameters.ContainsKey('IncludeParentProcesses')
		}
		'NewFunction'         = 'Get-NXTProcessTree'
		'TransformParameters' = @{
			'ProcessId'              = { "-Id $_" }
			'IncludeChildProcesses'  = { if ($_ -eq '$false') { '-NoChildren' } }
			'IncludeParentProcesses' = { if ($_ -eq '$false') { '-NoParents' } }
		}
	}
	'Get-NxtRebootRequirement'               = @{
		'NewFunction' = '#Get-ADTRebootRequirement => No migration path available. Check $adtSession.GetDeploymentStatus() if a reboot is required.'
	}
	'Get-NxtRegisteredPackage'               = @{
		'NewFunction'         = 'Get-NxtRegisteredPackage'
		'TransformParameters' = @{
			'InstalledState' = { if ($_ -eq '1') { '-Installed $true' } else { '-Installed $false' } }
		}
		'RemoveParameters'    = @(
			'ProductGUID'
		)
	}
	'Get-NxtRegisterOnly'                    = @{
		'NewFunction' = '#Get-NxtRegisterOnly => This was a private function and is now handled internally.'
	}
	'Get-NxtRunningProcesses'                = @{
		'NewFunction' = '#Get-NXTRunningProcesses => No migration path available. Use Get-ADTRunningProcesses instead.'
	}
	'Get-NxtServiceState'                    = @{
		'NewFunction' = '#Get-NxtServiceState => No migration path available. Use Get-Service instead.'
	}
	'Get-NxtSidByName'                       = @{
		'NewFunction'         = 'ConvertTo-ADTNTAccountOrSID'
		'TransformParameters' = @{
			'UserName' = { "-AccountName $_" }
		}
	}
	'Get-NxtSystemEnvironmentVariable'       = @{
		'NewFunction'         = 'Get-ADTEnvironmentVariable'
		'AddParameters'       = @{
			'Target' = { "-Target 'Machine'" }
		}
		'TransformParameters' = @{
			'Key' = { "-Variable $_" }
		}
	}
	'Get-NxtUILanguage'                      = @{
		'NewFunction' = '$uiculture.LCID'
	}
	'Get-NxtVariablesFromDeploymentSystem'   = @{
		'NewFunction' = '#Get-NxtVariablesFromDeploymentSystem => This was a private function and is not needed anymore.'
	}
	'Get-NxtWindowsBits'                     = @{
		'NewFunction' = '$envWindowsBits'
	}
	'Get-NxtWindowsVersion'                  = @{
		'NewFunction' = '$envOSVersion'
	}
	'Import-NxtIniFile'                      = @{
		'NewFunction'         = 'Import-NXTIniFile'
		'PreTest'             = {
			$boundParameters.ContainsKey('ContinueOnError')
		}
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Import-NxtIniFileWithComments'          = @{
		'NewFunction'         = 'Import-NXTIniFile'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
		'AddParameters'       = @{
			'AsIniDocument' = '-AsIniDocument'
		}
	}
	'Import-NxtXmlFile'                      = @{
		'PreTest'             = {
			$boundParameters.ContainsKey('DefaultEncoding') -or
			$boundParameters.ContainsKey('ContinueOnError')
		}
		'NewFunction'         = 'Import-NXTXmlFile'
		'TransformParameters' = @{
			'DefaultEncoding' = { if (-not $boundParameters.ContainsKey('Encoding')) { "-Encoding $_" } }
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Initialize-NxtAppRootFolder'            = @{
		'NewFunction' = '#Initialize-NxtAppRootFolder => This was a private function and is not needed anymore.'
	}
	'Initialize-NxtEnvironment'              = @{
		'NewFunction' = '#Initialize-NxtEnvironment => This was a private function and is not needed anymore.'
	}
	'Initialize-NxtUninstallApplication'     = @{
		'NewFunction' = '#Initialize-NxtUninstallApplication => This was a private function and is not needed anymore.'
	}
	'Install-NxtApplication'                 = @{
		'PreTest'     = {
			$oldParams = @(
				'AppName', 'UninstallKeyIsDisplayName', 'UninstallKeyContainsWildCards', 'DisplayNamesToExclude', 'InstLogFile', 'InstFile', 'InstPara', 'AppendInstParaToDefaultParameters',
				'AcceptedInstallExitCodes', 'AcceptedInstallRebootCodes', 'InstallMethod', 'UninstallMethod', 'PreSuccessCheckTotalSecondsToWaitFor', 'PreSuccessCheckProcessOperator',
				'PreSuccessCheckProcessesToWaitFor', 'PreSuccessCheckRegKeyOperator', 'PreSuccessCheckRegkeysToWaitFor', 'UninsBackupPath', 'UninstallKey'
			)
			foreach ($param in $oldParams) {
				if ($boundParameters.ContainsKey($param)) {
					return $true
				}
			}
		}
		'NewFunction' = '#Install-NXTApplication => No migration path available. Migrate to new parameters of Install-NXTApplication manually.'
	}
	'Merge-NxtExitCodes'                     = @{
		'NewFunction' = '#Merge-NxtExitCodes => This was a private function and is not needed anymore.'
	}
	'Move-NxtItem'                           = @{
		'NewFunction'         = 'Move-Item'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'New-NXTFolderWithPermissions'           = @{
		'NewFunction'         = 'New-NXTFolderWithPermission'
		'TransformParameters' = @{
			'Hidden'       = { if ($_ -eq '$true') { '-Hide' } }
			'ProtectRules' = { if ($_ -eq '$false') { '-Inherit' } }
		}
	}
	'Read-NxtSingleXmlNode'                  = @{
		'NewFunction'         = 'Get-NXTXmlNode'
		'TransformParameters' = @{
			'XmlFilePath'     = { "-Path $_" }
			'SingleNodeName'  = { "-XPath $_" }
			'DefaultEncoding' = { if (-not $boundParameters.ContainsKey('Encoding')) { "-Encoding $_" } }
		}
		'AddParameters'       = @{
			'Single'    = '-Single'
			'Attribute' = { if (-not $boundParameters.ContainsKey('AttributeName')) { '-Attribute ''InnerText''' } }
		}
	}
	'Register-NxtPackage'                    = @{
		'NewFunction' = '#Register-NxtPackage => This was a private function and is handled internally.'
	}
	'Remove-NxtDesktopShortcuts'             = @{
		'NewFunction' = '#Remove-NXTDesktopShortcuts => This was a private function and is not needed anymore. Make use of Remove-ADTFile.'
	}
	'Remove-NxtIniValue'                     = @{
		'NewFunction'         = 'Remove-ADTIniValue'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
		}
	}
	'Remove-NxtLocalGroup'                   = @{
		'NewFunction'         = 'Remove-LocalGroup'
		'TransformParameters' = @{
			'GroupName' = { "-Name $_" }
		}
		'RemoveParameters'    = @(
			'COMPUTERNAME'
		)
	}
	'Remove-NxtLocalGroupMember'             = @{
		'NewFunction'         = 'Remove-LocalGroupMember'
		'TransformParameters' = @{
			'GroupName'  = { "-Name $_" }
			'MemberName' = { "-Member `$(Get-LocalUser -Name $_)" }
		}
		'RemoveParameters'    = @(
			'COMPUTERNAME'
		)
	}
	'Remove-NxtLocalUser'                    = @{
		'NewFunction'         = 'Remove-LocalUser'
		'TransformParameters' = @{
			'UserName' = { "-Name $_" }
		}
		'RemoveParameters'    = @(
			'COMPUTERNAME'
		)
	}
	'Remove-NxtProcessEnvironmentVariable'   = @{
		'NewFunction'         = 'Remove-ADTEnvironmentVariable'
		'TransformParameters' = @{
			'Key' = { "-Variable $_" }
		}
		'AddParameters'       = @{
			'Target' = { '-Target Process' }
		}
	}
	'Remove-NxtProcessPathVariable'          = @{
		'NewFunction'   = 'Remove-NXTPathVariable'
		'AddParameters' = @{
			'Target' = { '-Target Process' }
		}
	}
	'Remove-NxtSystemPathVariable'           = @{
		'NewFunction'   = 'Remove-NXTPathVariable'
		'AddParameters' = @{
			'Target' = { '-Target Machine' }
		}
	}
	'Remove-NxtProductMember'                = @{
		'NewFunction' = '#Remove-NXTProductMember => Product member functionality has been removed from.'
	}
	'Remove-NxtSystemEnvironmentVariable'    = @{
		'NewFunction'         = 'Remove-ADTEnvironmentVariable'
		'TransformParameters' = @{
			'Key' = { "-Variable $_" }
		}
		'AddParameters'       = @{
			'Target' = { '-Target Machine' }
		}
	}
	'Repair-NxtApplication'                  = @{
		'NewFunction' = '#Repair-NxtApplication => No migration path available. Use Start-ADTMsiProcess instead.'
	}
	'Resolve-NxtDependentPackage'            = @{
		'NewFunction' = '#Resolve-NxtDependentPackage => This was a private function and is handled internally.'
	}
	'Save-NxtXmlFile'                        = @{
		'NewFunction'         = 'Set-NXTContent'
		'TransformParameters' = @{
			'DefaultEncoding' = { if (-not $boundParameters.ContainsKey('Encoding')) { "-Encoding $_" } }
			'Xml'             = { "-Value $_.OuterXml" }
		}
	}
	'Set-NxtCustomSetupCfg'                  = @{
		'NewFunction' = '#Set-NxtCustomSetupCfg => This was a private function and is not needed anymore.'
	}
	'Set-NxtFolderPermissions'               = @{
		'BreakInheritance'               = { if ($_ -eq '$false') { '-Inherit' } }
		'EnforceInheritanceOnSubFolders' = { if ($_ -eq '$true') { '-Recurse' } }
	}
	'Set-NxtIniValue'                        = @{
		'NewFunction'         = 'Set-ADTIniValue'
		'TransformParameters' = @{
			'ContinueOnError' = { if ($_ -eq '$true') { '-ErrorAction SilentlyContinue' } else { '-ErrorAction Stop' } }
			'Create'          = { if ($_ -eq '$true') { '-Force' } }
		}
		'AddParameters'       = @{
			'Create' = { if (-not $boundParameters.ContainsKey('Create') -or $true -eq $boundParameters['Create']) { '-Force' } }
		}
	}
	'Set-NxtPackageArchitecture'             = @{
		'NewFunction' = '#Set-NxtPackageArchitecture => This was a private function and is not needed anymore.'
	}
	'Set-NxtProcessEnvironmentVariable'      = @{
		'NewFunction'         = 'Set-ADTEnvironmentVariable'
		'TransformParameters' = @{
			'Key' = { "-Variable $_" }
		}
		'AddParameters'       = @{
			'Target' = { '-Target Process' }
		}
	}
	'Set-NxtRebootVariable'                  = @{
		'NewFunction' = '#Set-NxtRebootVariable => No migration path available. Use $adtSession.SetExitCode() instead.'
	}
	'Set-NxtSetupCfg'                        = @{
		'NewFunction' = '#Set-NxtSetupCfg => This was a private function and is not needed anymore.'
	}
	'Set-NxtSystemEnvironmentVariable'       = @{
		'NewFunction'         = 'Set-ADTEnvironmentVariable'
		'TransformParameters' = @{
			'Key' = { "-Variable $_" }
		}
		'AddParameters'       = @{
			'Target' = { '-Target Machine' }
		}
	}
	'Set-NxtXmlNode'                         = @{
		'PreTest'             = {
			$boundParameters.ContainsKey('FilterAttributes') -or $boundParameters.ContainsKey('FilePath')
		}
		'NewFunction'         = 'Set-NXTXmlNode'
		'TransformParameters' = @{
			'FilePath'        = { "-Path $_" }
			'NodePath'        = {
				"-XPath `"$($_.Extent.Text.Trim("'").Trim('"'))$(if ($boundParameters.ContainsKey('FilterAttributes')) {
					[System.String]::Join('', @(
						$boundParameters['FilterAttributes'].Value.KeyValuePairs | & { process {
							if ($_.Item2.PipelineElements[0].Expression -is [System.Management.Automation.Language.StringConstantExpressionAst] -or
								$_.Item2.PipelineElements[0].Expression -is [System.Management.Automation.Language.ExpandableStringExpressionAst] -or
								$_.Item2.PipelineElements[0].Expression -is [System.Management.Automation.Language.VariableExpressionAst]
							) {
								"[@$($_.Item1)='$($_.Item2.ToString().Trim("'").Trim('"'))']"
							}
							else {
								"[@$($_.Item1)='`$($($_.Item2.ToString().Replace('"', '`"')))']"
							}
						} }))
				})`""
			}
			'DefaultEncoding' = { if (-not $boundParameters.ContainsKey('Encoding')) { "-Encoding $_" } }
		}
		'RemoveParameters'    = @(
			'FilterAttributes'
		)
	}
	'Show-NxtInstallationWelcome'            = @{
		'PreTest'             = {
			$oldParams = @(
				'Silent', 'ForceCloseAppsCountdown', 'PromptToSave', 'CloseAppsCountdown', 'ForceCloseAppsCountdown', 'CloseAppsCountdown'
				'IsInstall', 'UserCanCloseAll', 'UserCanAbort', 'ScriptRoot', 'ProcessIdToIgnore', 'BlockScriptLocation',
				'TopMost', 'AskKillProcessApps', 'AllowDefer', 'ForceContinueAfterDeferrals'
			)
			foreach ($param in $oldParams) {
				if ($boundParameters.ContainsKey($param)) { return $true }
			}
		}
		'NewFunction'         = 'Show-NXTInstallationWelcome'
		'TransformParameters' = @{
			'AllowDefer'              = { if ($_ -eq '$true' -and -not $boundParameters.ContainsKey('AllowDeferCloseApps')) { '-AllowDeferCloseApps' } else { $null } }
			'MinimizeWindows'         = { if ($_ -eq '$true') { '-MinimizeWindows' } }
			'TopMost'                 = { if ($_ -eq '$false') { '-NotTopMost' } }
			'AskKillProcessApps'      = { "-CloseProcesses $_" }
		}
		'RemoveParameters'    = @(
			'Silent',
			'PromptToSave',
			'IsInstall',
			'UserCanCloseAll',
			'UserCanAbort',
			'ScriptRoot',
			'ProcessIdToIgnore',
			'BlockScriptLocation',
			'ForceContinueAfterDeferrals',
			'ApplyContinueTypeOnError',
			'ContinueType',
			'AllowDeferCloseApps'
		)
		'AddParameters'       = @{
			'DeploymentDefaults' = '-DeploymentDefaults'
		}
	}
	'Show-NxtWelcomePrompt'                  = @{
		'NewFunction' = '#Show-NxtWelcomePrompt => This was a private function and is handled internally.'
	}
	'Stop-NxtProcess'                        = @{
		'PreTest'             = {
			$boundParameters.ContainsKey('ProcessName') -or $boundParameters.ContainsKey('IsWql')
		}
		'NewFunction'         = {
			if ($boundParameters.ContainsKey('IsWql')) {
				'#Stop-NxtProcess => No migration path available for WQL queries. Provide the process directly to Stop-NXTProcess instead.'
			}
			else {
				'Stop-NXTProcess'
			}
		}
		'TransformParameters' = @{
			'ProcessName' = { "-Name $_" }
		}
	}
	'Switch-NxtMSIReinstallMode'             = @{
		'NewFunction' = '#Switch-NxtMSIReinstallMode => This was a private function and is not needed anymore.'
	}
	'Test-NxtAppIsInstalled'                 = @{
		'NewFunction' = '#Test-NxtAppIsInstalled => No migration path available. Use Get-ADTApplication instead or use valies from $adtSession.NXT.Detection instead.'
	}
	'Test-NxtConfigVersionCompatibility'     = @{
		'NewFunction' = '#Test-NxtConfigVersionCompatibility => This was a private function and is not needed anymore.'
	}
	'Test-NxtLocalGroupExists'               = @{
		'NewFunction' = '#Test-NxtLocalGroupExists => No migration path available. Use Get-LocalGroup instead.'
	}
	'Test-NxtLocalUserExists'                = @{
		'NewFunction' = '#Test-NxtLocalUserExists => No migration path available. Use Get-LocalUser instead.'
	}
	'Test-NxtObjectValidation'               = @{
		'NewFunction' = '#Test-NxtObjectValidation => This was a private function and is not needed anymore.'
	}
	'Test-NxtObjectValidationHelper'         = @{
		'NewFunction' = '#Test-NxtObjectValidationHelper => This was a private function and is not needed anymore.'
	}
	'Test-NxtPackageConfig'                  = @{
		'NewFunction' = '#Test-NxtPackageConfiguration => This was a private function and is not needed anymore.'
	}
	'Test-NxtFolderPermissions'              = @{
		'NewFunction'      = 'Test-NXTFolderPermission'
		'RemoveParameters' = @(
			'CheckIsInherited'
		)
	}
	'Test-NxtProcessExists'                  = @{
		'NewFunction'         = {
			if ($boundParameters.ContainsKey('IsWql')) {
				'#Test-NxtProcessExists => No migration path available for WQL queries. Provide the process directly to Test-NXTProcess instead.'
			}
			else {
				'Test-NXTProcess'
			}
		}
		'TransformParameters' = @{
			'ProcessName' = { "-Name $_" }
		}
	}
	'Test-NxtSetupCfg'                       = @{
		'NewFunction' = '#Test-NxtSetupCfg => This was a private function and is not needed anymore.'
	}
	'Test-NxtStringInFile'                   = @{
		'PreTest'             = {
			$boundParameters.ContainsKey('SearchString') -or
			$boundParameters.ContainsKey('ContainsRegex') -or
			$boundParameters.ContainsKey('DefaultEncoding')
		}
		'NewFunction'         = 'Test-NXTStringInFile'
		'TransformParameters' = @{
			'IgnoreCase'      = { if ($_ -eq '$false') { '-CaseSensitive' } }
			'SearchString'    = { "-Query $_" }
			'ContainsRegex'   = { if ($_ -eq '$true') { '-PatternType Regex' } }
			'DefaultEncoding' = { if (-not $boundParameters.ContainsKey('Encoding')) { "-Encoding $_" } }
		}
	}
	'Test-NxtXmlNodeExists'                  = @{
		'NewFunction'         = 'Test-NxtXmlNode'
		'TransformParameters' = @{
			'FilePath'        = { "-Path $_" }
			'NodePath'        = {
				"-XPath `"$($_.Extent.Text.Trim("'").Trim('"'))$(if ($boundParameters.ContainsKey('FilterAttributes')) {
					[System.String]::Join('', @(
						$boundParameters['FilterAttributes'].Value.KeyValuePairs | & { process {
							if ($_.Item2.PipelineElements[0].Expression -is [System.Management.Automation.Language.StringConstantExpressionAst] -or
								$_.Item2.PipelineElements[0].Expression -is [System.Management.Automation.Language.ExpandableStringExpressionAst] -or
								$_.Item2.PipelineElements[0].Expression -is [System.Management.Automation.Language.VariableExpressionAst]
							) {
								"[@$($_.Item1)='$($_.Item2.ToString().Trim("'").Trim('"'))']"
							}
							else {
								"[@$($_.Item1)='`$($($_.Item2.ToString().Replace('"', '`"')))']"
							}
						} }))#
				})`""
			}
			'DefaultEncoding' = { if (-not $boundParameters.ContainsKey('Encoding')) { "-Encoding $_" } }
		}
		'RemoveParameters'    = @(
			'FilterAttributes'
		)
	}
	'Unblock-NxtAppExecution'                = @{
		'NewFunction' = 'Unblock-ADTAppExecution'
	}
	'Uninstall-NxtApplication'               = @{
		'PreTest'     = {
			$oldParams = @(
				'AppName', 'UninstallKeyIsDisplayName', 'UninstallKeyContainsWildCards', 'DisplayNamesToExclude', 'UninstLogFile', 'UninstFile', 'UninstPara',
				'AppendUninstParaToDefaultParameters', 'AcceptedUninstallExitCodes', 'AcceptedUninstallRebootCodes', 'UninstallMethod', 'PreSuccessCheckTotalSecondsToWaitFor',
				'PreSuccessCheckProcessOperator', 'PreSuccessCheckProcessesToWaitFor', 'PreSuccessCheckRegKeyOperator', 'PreSuccessCheckRegkeysToWaitFor', 'DirFiles', 'UninsBackupPath'
			)
			foreach ($param in $oldParams) {
				if ($boundParameters.ContainsKey($param)) { return $true }
			}
		}
		'NewFunction' = '#Uninstall-NxtApplication => No migration path available. Migrate to new parameters of Uninstall-NXTApplication manually.'
	}
	'Uninstall-NxtOld'                       = @{
		'NewFunction' = '#Uninstall-NxtOld => This was a private function and is handled internally.'
	}
	'Unregister-NxtOld'                      = @{
		'NewFunction' = '#Unregister-NxtOld => This was a private function and is not needed anymore.'
	}
	'Unregister-NxtPackage'                  = @{
		'NewFunction' = '#Unregister-NxtPackage => This was a private function and is handled internally.'
	}
	'Update-NxtTextInFile'                   = @{
		'PreTest'             = {
			$boundParameters.ContainsKey('DefaultEncoding') -or
			$boundParameters.ContainsKey('AddBOMIfUTF8')
		}
		'NewFunction'         = 'Update-NXTTextInFile'
		'TransformParameters' = @{
			'SearchString'    = { "-Query $_" }
			'ReplaceString'   = { "-Value $_" }
			'DefaultEncoding' = { if (-not $boundParameters.ContainsKey('Encoding')) { "-Encoding $_" } }
		}
		'RemoveParameters'    = @(
			'AddBOMIfUTF8'
		)
	}
	'Update-NxtXmlNode'                      = @{
		'NewFunction' = '#Update-NxtXmlNode => No migration path available. Use Set-NXTXmlNode instead.'
	}
	'Wait-NxtRegistryAndProcessCondition'    = @{
		'NewFunction' = '#Wait-NxtRegistryAndProcessCondition => This was a private function and is not needed anymore. Use the separate functions instead.'
	}
	'Watch-NxtFile'                          = @{
		'NewFunction'         = 'Wait-NXTFileSystem'
		'TransformParameters' = @{
			'FilePath' = { "-Path $_" }
		}
	}
	'Watch-NxtFileIsRemoved'                 = @{
		'NewFunction'         = 'Wait-NXTFileSystemIsRemoved'
		'TransformParameters' = @{
			'FilePath' = { "-Path $_" }
		}
	}
	'Watch-NxtProcess'                       = @{
		'NewFunction'         = {
			if ($boundParameters.ContainsKey('IsWql')) {
				'#Watch-NxtProcess => No migration path available for WQL queries. Provide the process directly to Wait-NXTProcess instead.'
			}
			else {
				'Wait-NXTProcess'
			}
		}
		'TransformParameters' = @{
			'ProcessName' = { "-Name $_" }
		}
	}
	'Watch-NxtProcessIsStopped'              = @{
		'NewFunction'         = {
			if ($boundParameters.ContainsKey('IsWql')) {
				'#Watch-NxtProcessIsStopped => No migration path available for WQL queries. Provide the process directly to Wait-NXTProcess instead.'
			}
			else {
				'Wait-NXTProcessIsStopped'
			}
		}
		'TransformParameters' = @{
			'ProcessName' = { "-Name $_" }
		}
	}
	'Watch-NxtRegistryKey'                   = @{
		'NewFunction'         = 'Wait-NXTRegistryKey'
		'TransformParameters' = @{
			'RegistryKey' = { "-Key $($_ -replace 'SOFTWARE\\\$?(?:global:)?WOW6432Node\\', 'SOFTWARE\\')" }
		}
		'AddParameters'       = @{
			'Wow6432Node' = { if ($boundParameters.RegistryKey.Value.Extent -like '*Wow6432Node*') { '-Wow6432Node' } }
		}
	}
	'Watch-NxtRegistryKeyIsRemoved'          = @{
		'NewFunction'         = 'Wait-NXTRegistryKeyIsRemoved'
		'TransformParameters' = @{
			'RegistryKey' = { "-Key $($_ -replace 'SOFTWARE\\\$?(?:global:)?WOW6432Node\\', 'SOFTWARE\\')" }
		}
		'AddParameters'       = @{
			'Wow6432Node' = { if ($boundParameters.RegistryKey.Value.Extent -like '*Wow6432Node*') { '-Wow6432Node' } }
		}
	}
	'Write-NxtXmlNode'                       = @{
		'NewFunction' = '#Write-NxtXmlNode => No migration path available. Use Set-NXTXmlNode instead.'
	}
	#endregion NXT Function Mappings
}

# Import the function shims from an external file
. "$PSScriptRoot\Measure-NXTCompatibility.functions.ps1"

function Measure-NXTDeprecatedType {
	<#
	.SYNOPSIS
	Checks for usage of deprecated PSAppDeployToolkit v3 types
	#>
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord])]
	param (
		[Parameter(Mandatory)]
		[System.Management.Automation.Language.ScriptBlockAst]
		$ScriptBlockAst
	)
	process {
		$ScriptBlockAst.FindAll(
			{
				(
					$args[0] -is [System.Management.Automation.Language.TypeConstraintAst] -or
					$args[0] -is [System.Management.Automation.Language.TypeExpressionAst]
				) -and
				$script:DeprecatedTypeFullNames.Contains($args[0].TypeName.FullName)
			},
			$false
		) | . {
			process {
				[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
					Message           = "The type definition '$($_.Extent.Text)' is deprecated and no longer available."
					Extent            = $_.Extent
					RuleName          = 'Measure-NXTDeprecatedType'
					Severity          = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Error
					RuleSuppressionID = 'PSADTDeprecatedType'
				}
			}
		}
	}
}

function Measure-NXTCustomMigration {
	<#
	.SYNOPSIS
	Checks the custom migration definitions and suggests replacements
	#>
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord])]
	param (
		[Parameter(Mandatory)]
		[System.Management.Automation.Language.ScriptBlockAst]
		$ScriptBlockAst
	)
	process {
		foreach ($migrationDefinition in $script:CustomMigrations) {
			$ScriptBlockAst.FindAll($migrationDefinition.Filter, $false) | . {
				process {
					[System.String]$replacementText = if ($migrationDefinition.Replacement -is [System.Management.Automation.ScriptBlock]) {
						ForEach-Object -InputObject $_ -Process $migrationDefinition.Replacement
					}
					else {
						$migrationDefinition.Replacement
					}

					$infoText = if ($replacementText.StartsWith('#')) {
						# If the replacement text is a comment, use it as the info text
						$replacementText.TrimStart('#').Trim()
					}
					else {
						# Otherwise, use a generic message
						'This expression has a V4 inplace migration path. Please use the suggested correction to migrate to the new syntax.'
					}

					[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]$record = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
						Message           = $infoText
						Extent            = $_.Extent
						RuleName          = 'Measure-NXTCustomMigration'
						Severity          = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Error
						RuleSuppressionID = 'PSADTCustomMigration'
					}

					# Create a CorrectionExtent object for the suggested correction
					if (-not $replacementText.StartsWith('#')) {
						$record.SuggestedCorrections = [System.Collections.ObjectModel.Collection[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]]::new()
						$null = $record.SuggestedCorrections.Add(
							[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
								$_.Extent,
								$replacementText,
								$MyInvocation.MyCommand.Definition,
								'Use the suggested correction to migrate to the new syntax.'
							)
						)
					}

					$record
				}
			}
		}
	}
}

function Measure-NXTDeprecatedVariable {
	<#
	.SYNOPSIS
	Checks the custom migration definitions and suggests replacements
	#>
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord])]
	param (
		[Parameter(Mandatory)]
		[System.Management.Automation.Language.ScriptBlockAst]
		$ScriptBlockAst
	)
	process {
		$ScriptBlockAst.FindAll(
			{
				$args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and
				-not $args[0].IsConstantVariable() -and
				$args[0].Parent -isnot [System.Management.Automation.Language.ParameterAst] -and
				$variableMappings.ContainsKey($args[0].VariablePath.UserPath.Split(':')[-1])
			},
			$false
		) | . {
			process {
				[System.String]$variableName = $_.VariablePath.UserPath.Split(':')[-1]
				[System.String]$newVariable = $variableMappings[$variableName]
				[System.Collections.ObjectModel.Collection[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]]$suggestedCorrections = @()

				if ([System.String]::IsNullOrWhiteSpace($newVariable)) {
					[System.String]$outputMessage = "The variable [$_] is deprecated and no longer available. There is no direct replacement available."
				}
				else {
					[System.String]$outputMessage = "The variable [$_] is deprecated. Use [$newVariable] instead."

					if ($newVariable.Contains('.') -and $_.Parent.StringConstantType -in [System.Management.Automation.Language.StringConstantType]::DoubleQuoted, [System.Management.Automation.Language.StringConstantType]::DoubleQuotedHereString) {
						$newVariable = "`$($newVariable)"
					}

					$null = $suggestedCorrections.Add(
						[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
							$_.Extent,
							$newVariable,
							$MyInvocation.MyCommand.Definition,
							'Use the new variable name instead.'
						)
					)
				}

				[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
					Message              = $outputMessage
					Extent               = $_.Extent
					RuleName             = 'Measure-NXTDeprecatedVariable'
					Severity             = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Error
					RuleSuppressionID    = 'PSADTDeprecatedVariable'
					SuggestedCorrections = $suggestedCorrections
				}
			}
		}
	}
}

function Measure-NXTDeprecatedFunction {
	<#
	.SYNOPSIS
	Checks for usage of deprecated PSAppDeployToolkit v3 functions
	#>
	[OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord])]
	param (
		[Parameter(Mandatory)]
		[System.Management.Automation.Language.ScriptBlockAst]
		$ScriptBlockAst
	)
	process {
		# Get legacy functions
		$ScriptBlockAst.FindAll(
			{
				$args[0] -is [System.Management.Automation.Language.CommandAst] -and
				$script:FunctionMappings.ContainsKey("$($args[0].GetCommandName())")
			},
			$false
		) | . {
			process {
				[System.Management.Automation.Language.CommandAst]$commandAst = $_
				[System.String]$functionName = $commandAst.GetCommandName()
				[System.Collections.Generic.Dictionary[System.String, System.Management.Automation.Language.ParameterBindingResult]]$boundParameters = ([System.Management.Automation.Language.StaticParameterBinder]::BindCommand($commandAst, $true)).BoundParameters
				[System.Collections.Hashtable]$migration = $functionMappings[$functionName]

				if ($migration.PreTest -and -not $migration.PreTest.InvokeReturnAsIs()) { return }

				[System.Text.StringBuilder]$outputMessage = [System.Text.StringBuilder]::new()
				[System.Collections.Generic.List[System.String]]$newParams = [System.Collections.Generic.List[System.String]]::new()
				[System.String]$newFunction = if ($migration.NewFunction -is [System.Management.Automation.ScriptBlock]) { $migration.NewFunction.InvokeReturnAsIs() } else { $migration.NewFunction }

				if ($newFunction.StartsWith('#')) {
					$null = $outputMessage.AppendLine($newFunction.TrimStart('#').Trim())
				}
				elseif ([System.String]::IsNullOrWhiteSpace($newFunction)) {
					$null = $outputMessage.AppendLine("The function [$functionName] is deprecated and no longer available and requires no replacement.")
				}
				else {
					$null = $outputMessage.AppendLine("The function [$functionName] is deprecated or the parameterset changed, use new [$newFunction] definition instead.")

					foreach ($boundParameter in $boundParameters.GetEnumerator()) {
						if ($boundParameter.Key -in $migration.RemoveParameters) {
							$null = $outputMessage.AppendLine("-$($boundParameter.Key) is deprecated.")
							continue
						}
						if ($boundParameter.Key -in $migration.TransformParameters.Keys) {
							if ($migration.TransformParameters[$boundParameter.Key] -is [System.Management.Automation.ScriptBlock]) {
								[System.String]$newParam = ForEach-Object -InputObject $boundParameter.Value.Value -Process $migration.TransformParameters[$boundParameter.Key]
							}
							else {
								[System.String]$newParam = $migration.TransformParameters[$boundParameter.Key]
							}

							if ([System.String]::IsNullOrWhiteSpace($newParam)) {
								# If newParam is empty, assume parameter should be removed (RemoveParameters definition is preferred, but it is not suitable for conditional removals)
								$null = $outputMessage.AppendLine("Removed parameter: -$($boundParameter.Key)")
								continue
							}
							if ($newParams.Contains($newParam)) {
								# If the new param value is already present in the new command, skip it. This can happen when 2 parameters are combined into one in the new syntax (e.g. Remove-MSIApplications -FilterApplication -ExcludeFromUninstall)
								continue
							}

							if ($boundParameter.Value.ConstantValue -and $boundParameter.Value.Value.ParameterName -eq $boundParameter.Key) {
								# This is a simple switch
								$null = $outputMessage.AppendLine("-$($boundParameter.Key)  =>  $newParam")
							}
							elseif ($boundParameter.Key -eq $boundParameter.Value.Value.Parent.ParameterName) {
								# This is a switch bound with a value, e.g. -Switch:$true
								$null = $outputMessage.AppendLine("-$($boundParameter.Key)  =>  $newParam")
							}
							else {
								# This is a regular parameter, e.g. -Path 'xxx'
								$null = $outputMessage.AppendLine("-$($boundParameter.Key) $($boundParameter.Value.Value.Extent.Text)  =>  $newParam")
							}
						}
						else {
							# If not removed or transformed, pass through original parameter as-is, making some assumptions about the parsed input to do so
							if ($boundParameter.Value.ConstantValue -and $boundParameter.Value.Value.ParameterName -eq $boundParameter.Key) {
								# This is a simple switch
								$newParam = "-$($boundParameter.Key)"
							}
							elseif ($boundParameter.Key -eq $boundParameter.Value.Value.Parent.ParameterName) {
								# This is a switch bound with a value, e.g. -Switch:$true
								$newParam = $boundParameters.Value.Value.Parent.Extent.Text
							}
							elseif ($boundParameter.Value.Value.Splatted) {
								# This is a splatted parameter, e.g. @params, retain the original value
								$newParam = $boundParameter.Value.Value.Extent.Text
							}
							elseif ($boundParameter.Key -match '^\d+$') {
								# This is an unrecognized positional parameter, pass through  as-is
								$newParam = $boundParameter.Value.Value.Extent.Text
							}
							else {
								# This is a regular parameter, e.g. -Path 'xxx'
								$newParam = "-$($boundParameter.Key) $($boundParameter.Value.Value.Extent.Text)"
							}
						}

						if (-not [System.String]::IsNullOrWhiteSpace($newParam)) {
							$null = $newParams.Add($newParam)
						}
					}

					foreach ($addParameter in $migration.AddParameters.Keys) {
						if ($migration.AddParameters[$addParameter] -is [System.Management.Automation.ScriptBlock]) {
							[System.String]$newParam = ForEach-Object -InputObject $addParameter -Process $migration.AddParameters[$addParameter]
						}
						else {
							[System.String]$newParam = $migration.AddParameters[$addParameter]
						}

						if (-not [System.String]::IsNullOrWhiteSpace($newParam)) {
							$null = $newParams.Add($newParam)
							$null = $outputMessage.AppendLine("Add Parameter: $newParam")
						}
					}
				}

				# Construct the new command
				[System.String]$newCommand = ($newFunction + ' ' + ([System.String]::Join(' ', $newParams))).Trim()

				# Output the diagnostic record in the format expected by the ScriptAnalyzer
				[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]$record = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
					Message           = $outputMessage.ToString().Trim()
					Extent            = $commandAst.Extent
					RuleName          = 'Measure-NXTDeprecatedFunction'
					Severity          = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Error
					RuleSuppressionID = 'PSADTDeprecatedFunction'
				}

				if ($newFunction -notmatch '^#') {
					# Create a CorrectionExtent object for the suggested correction
					$record.SuggestedCorrections = [System.Collections.ObjectModel.Collection[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]]::new()
					$null = $record.SuggestedCorrections.Add(
						[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
							$commandAst.Extent,
							$newCommand,
							$MyInvocation.MyCommand.Definition,
							'Use the new function name and parameters instead.'
						)
					)
				}
				$record
			}
		}
	}
}

Export-ModuleMember -Function 'Measure-NXTDeprecatedType', 'Measure-NXTCustomMigration', 'Measure-NXTDeprecatedVariable', 'Measure-NXTDeprecatedFunction'
