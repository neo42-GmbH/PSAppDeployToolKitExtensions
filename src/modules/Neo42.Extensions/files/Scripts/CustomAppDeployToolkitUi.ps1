<#
.SYNOPSIS
Shows a legacy welcome window for the user to close applications before proceeding with the installation.
.DESCRIPTION
This is a ported version of the V3 CustomAppDeployToolkitUi.ps1 making it compatible with the new V4 toolkit.
Most of the codebase is changed but the functionality is the same.
This script is not intended to be used directly but is called by the Show-NXTInstallationWelcome function.
#>
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidLongLines', '', Justification = 'XML includes long lines')]
[CmdletBinding()]
param (
	[Parameter(Mandatory)]
	[System.Collections.Hashtable[]]
	$CloseProcesses,
	[Parameter(Mandatory)]
	[ValidateSet('Install', 'Uninstall', 'Repair')]
	[System.String]
	$DeploymentType,
	[Parameter(Mandatory)]
	[System.String]
	$Title,
	[System.Management.Automation.SwitchParameter]
	$CustomText,
	[System.Management.Automation.SwitchParameter]
	$NotTopMost,
	[System.Management.Automation.SwitchParameter]
	$PersistPrompt,
	[System.Management.Automation.SwitchParameter]
	$HideCloseButton,
	[System.Management.Automation.SwitchParameter]
	$AllowMove,
	[System.Management.Automation.SwitchParameter]
	$MinimizeWindows,
	[Alias('AllowDefer')]
	[System.Management.Automation.SwitchParameter]
	$AllowDeferCloseProcesses,
	[ValidateSet('Abort', 'Continue')]
	[System.String]
	$ContinueType = 'Abort',
	[System.TimeSpan]
	$Timeout,
	[System.DateTime]
	$DeferDeadline,
	[System.UInt32]
	$DeferTimes,
	[Parameter(Mandatory)]
	[AllowEmptyString()]
	[System.String[]]
	$ScriptDirectory
)

#region Initialization
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version '3.0'

# Convert relative paths back to full paths base on module base.
[System.String]$moduleRoot = [System.IO.Path]::GetFullPath("$PSScriptRoot\..\..\")
$ScriptDirectory = $ScriptDirectory | & { process { if ([System.IO.Path]::IsPathRooted($_)) { $_ } else { [System.IO.Path]::Combine($moduleRoot, $_) } } }

Import-Module -Force -Name "$moduleRoot\PSAppDeployToolkit"
Initialize-ADTModule -ScriptDirectory $ScriptDirectory
[System.Collections.Hashtable]$adtStrings = Get-ADTStringTable
[System.Collections.Hashtable]$adtConfig = Get-ADTConfig
$script:Timeout = if (-not $PSBoundParameters.ContainsKey('Timeout')) { [System.TimeSpan]::FromSeconds($adtConfig['UI']['DefaultTimeout']) } else { $Timeout }

[System.Collections.Hashtable]$script:ExitCodes = @{
	Close    = 1001
	Defer    = 1003
	Timeout  = 1004
	Continue = 1005
}

Add-Type -AssemblyName PresentationFramework
#endregion Initialization

#region Window and control variables
[System.Xml.XmlDocument]$windowDoc = [System.Xml.XmlDocument]::new()
$windowDoc.Load("$PSScriptRoot\$([System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)).xml")

[System.Windows.Window]$control = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($windowDoc))

[System.Windows.Window]$control_MainWindow = $control.FindName('InstallationWelcomeMainWindow')
[System.Windows.Controls.TextBlock]$control_FollowApplicationText = $control.FindName('FollowApplicationText')
[System.Windows.Controls.TextBlock]$control_AppNameText = $control.FindName('AppNameText')
[System.Windows.Controls.TextBlock]$control_ApplicationCloseText = $control.FindName('ApplicationCloseText')
[System.Windows.Controls.TextBlock]$control_SaveWorkText = $control.FindName('SaveWorkText')
[System.Windows.Controls.ListView]$control_CloseApplicationList = $control.FindName('CloseApplicationList')
[System.Windows.Controls.TextBlock]$control_DeferTextOne = $control.FindName('DeferTextOne')
[System.Windows.Controls.TextBlock]$control_DeferTimerText = $control.FindName('DeferTimerText')
[System.Windows.Controls.TextBlock]$control_DeferTextTwo = $control.FindName('DeferTextTwo')
[System.Windows.Controls.TextBlock]$control_TimerText = $control.FindName('TimerText')
[System.Windows.Controls.Button]$control_CloseButton = $control.FindName('CloseButton')
[System.Windows.Controls.Button]$control_DeferButton = $control.FindName('DeferButton')
[System.Windows.Controls.ProgressBar]$control_Progress = $control.FindName('Progress')
[System.Windows.Controls.TextBlock]$control_TimerBlock = $control_Progress.FindName('TimerBlock')
[System.Windows.Controls.Image]$control_Banner = $control.FindName('Banner')
[System.Windows.Controls.TextBlock]$control_TitleText = $control.FindName('TitleText')
[System.Windows.Controls.TextBlock]$control_DeferDeadlineText = $control.FindName('DeferDeadlineText')
[System.Windows.Controls.TextBlock]$control_CustomText = $control.FindName('CustomTextBlock')
[System.Windows.Controls.TextBlock]$control_PopupCloseWithoutSavingText = $control.FindName('PopupCloseWithoutSavingText')
[System.Windows.Controls.TextBlock]$control_PopupListText = $control.FindName('PopupListText')
[System.Windows.Controls.TextBlock]$control_PopupSureToCloseText = $control.FindName('PopupSureToCloseText')
[System.Windows.Controls.DockPanel]$control_HeaderPanel = $control.FindName('HeaderPanel')
[System.Windows.Controls.DockPanel]$control_MainPanel = $control.FindName('MainPanel')
[System.Windows.Controls.Primitives.Popup]$control_Popup = $control.FindName('Popup')
[System.Windows.Controls.Button]$control_PopupCloseApplication = $control.FindName('PopupCloseApplication')
[System.Windows.Controls.Button]$control_PopupCancel = $control.FindName('PopupCancel')
#endregion

#region Window event handlers
[System.Management.Automation.ScriptBlock]$windowLeftButtonDownHandler = {
	try { $control_MainWindow.DragMove() } catch { return }
}
if ($AllowMove) {
	$control_HeaderPanel.add_MouseLeftButtonDown($windowLeftButtonDownHandler)
}

[System.Management.Automation.ScriptBlock]$closeButtonClickHandler = {
	$control_Popup.IsOpen = $true
	$control_HeaderPanel.IsEnabled = $false
	$control_HeaderPanel.Opacity = 0.8
	$control_MainPanel.IsEnabled = $false
	$control_MainPanel.Opacity = 0.8
}
$control_CloseButton.add_Click($closeButtonClickHandler)

[System.Management.Automation.ScriptBlock]$deferButtonClickHandler = {
	$control_MainWindow.Tag = $script:ExitCodes['Defer']
	$control_MainWindow.Close()
}
$control_DeferButton.add_Click($deferButtonClickHandler)

[System.Management.Automation.ScriptBlock]$popupCloseApplicationClickHandler = {
	$control_Popup.IsOpen = $false
	$control_HeaderPanel.IsEnabled = $true
	$control_HeaderPanel.Opacity = 1
	$control_MainPanel.IsEnabled = $true
	$control_MainPanel.Opacity = 1
	$control_MainWindow.Tag = $script:ExitCodes['Close']
	$control_MainWindow.Close()
}
$control_PopupCloseApplication.add_Click($popupCloseApplicationClickHandler)

[System.Management.Automation.ScriptBlock]$popupCancelClickHandler = {
	$control_Popup.IsOpen = $false
	$control_HeaderPanel.IsEnabled = $true
	$control_HeaderPanel.Opacity = 1
	$control_MainPanel.IsEnabled = $true
	$control_MainPanel.Opacity = 1
}
$control_PopupCancel.add_Click($popupCancelClickHandler)


[System.Windows.Threading.DispatcherTimer]$welcomeTimer = [System.Windows.Threading.DispatcherTimer]::new()
$welcomeTimer.Interval = [System.TimeSpan]::FromSeconds(1)
[System.Management.Automation.ScriptBlock]$welcomeTimer_Tick = {
	$script:Timeout = $script:Timeout.Add([System.TimeSpan]::FromSeconds(-1))
	if ($script:Timeout -lt [System.TimeSpan]::Zero) {
		$control_MainWindow.Tag = $script:ExitCodes['Timeout']
		$control_MainWindow.Close()
	}
	else {
		$control_Progress.Value = $script:Timeout.TotalSeconds
		$control_TimerBlock.Text = [System.String]::Format('{0}:{1:d2}:{2:d2}', $script:Timeout.Days * 24 + $script:Timeout.Hours, $script:Timeout.Minutes, $script:Timeout.Seconds)
	}
}
$welcomeTimer.add_Tick($welcomeTimer_Tick)

[System.Management.Automation.ScriptBlock]$mainWindowLoaded = {
	$control_Progress.Maximum = $script:Timeout.TotalSeconds
	$control_Progress.Value = $script:Timeout.TotalSeconds
	$control_TimerBlock.Text = [System.String]::Format('{0}:{1:d2}:{2:d2}', $script:Timeout.Days * 24 + $script:Timeout.Hours, $script:Timeout.Minutes, $script:Timeout.Seconds)
	$timerRunningProcesses.Start()
	$welcomeTimer.Start()
}
$control_MainWindow.Add_Loaded($mainWindowLoaded)

[System.Management.Automation.ScriptBlock]$mainWindowClosed = {
	if ((Get-Variable -Name 'welcomeTimerPersist' -ErrorAction 'SilentlyContinue')) {
		$welcomeTimerPersist.remove_Tick($welcomeTimerPersist_Tick)
		$welcomeTimerPersist.Stop()
	}
	if ((Get-Variable -Name 'timerRunningProcesses' -ErrorAction 'SilentlyContinue')) {
		$timerRunningProcesses.remove_Tick($timerRunningProcesses_Tick)
		$timerRunningProcesses.Stop()
	}
	$welcomeTimer.remove_Tick($welcomeTimer_Tick)
	$welcomeTimer.Stop()
	$control_CloseButton.remove_Click($closeButtonClickHandler)
	$control_DeferButton.remove_Click($deferButtonClickHandler)
	$control_PopupCloseApplication.remove_Click($popupCloseApplicationClickHandler)
	$control_PopupCancel.remove_Click($popupCancelClickHandler)
	if ($AllowMove) {
		$control_HeaderPanel.remove_MouseLeftButtonDown($windowLeftButtonDownHandler)
	}
	$control_MainWindow.remove_Loaded($mainWindowLoaded)
	$control_MainWindow.remove_Closed($mainWindowClosed)
	$control_MainWindow.remove_Closing($mainWindowClosingHandler)
}
$control_MainWindow.Add_Closed($mainWindowClosed)

[System.Management.Automation.ScriptBlock]$mainWindowClosingHandler = {
	# Every intentional close sets Tag first. Anything else (Alt+F4, taskbar close, End task)
	# arrives with no Tag and must not be allowed through.
	if ($null -eq $control_MainWindow.Tag) {
		$args[1].Cancel = $true
	}
}
$control_MainWindow.add_Closing($mainWindowClosingHandler)
#endregion

#region Window apply theme
# Check what theme is in use and apply colors accordingly
[System.Boolean]$isLightTheme = $true
if ([Microsoft.Win32.RegistryKey]$themeKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
		[Microsoft.Win32.RegistryHive]::Users,
		[Microsoft.Win32.RegistryView]::Registry64
	).OpenSubKey(
		"$([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
	)
) {
	if ($null -ne ([System.Nullable[System.Int32]]$appThemeKey = $themeKey.GetValue('AppsUseLightTheme'))) {
		$isLightTheme = $appThemeKey -eq 1
	}
	elseif ($null -ne ([System.Nullable[System.Int32]]$systemThemeKey = $themeKey.GetValue('SystemUsesLightTheme'))) {
		$isLightTheme = $systemThemeKey -eq 1
	}
}

$control.Resources['MainColor'] = if ($adtConfig['UI']['FluentAccentColor'] -and ($isLightTheme -or -not $adtConfig['UI']['FluentAccentColorDark'])) {
	[System.Windows.Media.ColorConverter]::ConvertFromString('#' + $adtConfig['UI']['FluentAccentColor'].ToString('x8'))
}
elseif (-not $isLightTheme -and $adtConfig['UI']['FluentAccentColorDark']) {
	[System.Windows.Media.ColorConverter]::ConvertFromString('#' + $adtConfig['UI']['FluentAccentColorDark'].ToString('x8'))
}
else {
	[System.Windows.Media.Color]::FromRgb(227, 0, 15)
}
$control_Banner.Source = $adtConfig['Assets']['Banner']

if ($isLightTheme) {
	$control.Resources['BackColor'] = [System.Windows.Media.Color]::FromRgb(246, 246, 246)
	$control.Resources['BackLightColor'] = [System.Windows.Media.Color]::FromRgb(218, 218, 218)
	$control.Resources['ForeColor'] = [System.Windows.Media.Color]::FromRgb(0, 0, 0)
	$control.Resources['MouseHoverColor'] = [System.Windows.Media.Color]::FromRgb(255, 255, 255)
	$control.Resources['PressedColor'] = [System.Windows.Media.Color]::FromRgb(218, 218, 218)
}
else {
	if ($adtConfig['Assets']['BannerDark']) {
		$control_Banner.Source = $adtConfig['Assets']['BannerDark']
	}
}
#endregion

#region Window apply strings
if (-not $adtStrings['NXT']) { throw 'Missing string table for NXT UI' }
[System.Collections.Hashtable]$nxtStrings = $adtStrings['NXT']['LegacyWelcome']
$control_SaveWorkText.Text = $nxtStrings['SaveWork']
$control_DeferTextTwo.Text = $nxtStrings['DeferralExpired']
$control_CloseButton.Content = $nxtStrings['CloseApplications']
$control_PopupCancel.Content = $nxtStrings['Close']
$control_DeferButton.Content = $nxtStrings['Defer']
$control_CloseApplicationList.View.Columns[0].Header = $nxtStrings['ApplicationName']
$control_CloseApplicationList.View.Columns[1].Header = $nxtStrings['StartedBy']
$control_PopupCloseWithoutSavingText.Text = $nxtStrings['PopUpCloseApplicationText']
$control_PopupSureToCloseText.Text = $nxtStrings['PopUpSureToCloseText']
$control_PopupCloseApplication.Content = $nxtStrings['CloseApplications']
$control_FollowApplicationText.Text = $nxtStrings['FollowApplication'][$DeploymentType]
$control_ApplicationCloseText.Text = $nxtStrings['ApplicationClose'][$DeploymentType]
$control_DeferTextOne.Text = $nxtStrings['ChooseDefer'][$DeploymentType]
$control_DeferTimerText.Text = $nxtStrings['RemainingDeferrals'] -f $DeferTimes
$control_CloseButton.ToolTip = $nxtStrings['CloseApplicationsTooltip']
$control_TimerText.Text = $nxtStrings['CloseWithoutSaving'][$ContinueType]
$control_CustomText.Text = $adtStrings['CloseAppsPrompt']['CustomMessage']
$control_AppNameText.Text = $Title
$control_TitleText.Text = $Title
if ($DeferDeadline) {
	$control_DeferDeadlineText.Text = $nxtStrings['Deadline'] -f $DeferDeadline.ToString([System.Globalization.DateTimeFormatInfo]::CurrentInfo.ShortDatePattern)
}
#endregion

#region Apply UI Parameters
$control_MainWindow.TopMost = -not $NotTopMost
if ($PSBoundParameters.ContainsKey('Timeout')) {
	$control_Progress.Visibility = 'Visible'
	$control_TimerBlock.Visibility = 'Visible'
}

if ($CustomText -and -not [System.String]::IsNullOrWhiteSpace($control_CustomText.Text)) {
	$control_CustomText.Visibility = 'Visible'
}

if ($HideCloseButton) {
	$control_CloseButton.Visibility = 'Collapsed'
}

if ($AllowDeferCloseProcesses) {
	$control_DeferTextOne.Visibility = 'Visible'
	$control_DeferTextTwo.Visibility = 'Visible'
	$control_DeferButton.Visibility = 'Visible'
	if ($DeferDeadline) {
		$control_DeferDeadlineText.Visibility = 'Visible'
	}
	if ($DeferTimes) {
		$control_DeferTimerText.Visibility = 'Visible'
	}
}

if ($PersistPrompt -and -not $NotTopMost) {
	[System.Windows.Threading.DispatcherTimer]$welcomeTimerPersist = [System.Windows.Threading.DispatcherTimer]::new()
	$welcomeTimerPersist.Interval = [System.TimeSpan]::FromSeconds($adtConfig['UI']['DefaultPromptPersistInterval'])
	[System.Management.Automation.ScriptBlock]$welcomeTimerPersist_Tick = { $control_MainWindow.Topmost = $true }
	$welcomeTimerPersist.add_Tick($welcomeTimerPersist_Tick)
	$welcomeTimerPersist.Start()
}
#endregion Apply UI Parameters

#region Dynamic process evaluation
[System.Management.Automation.ScriptBlock]$updateProcessUi = {
	if (-not ([PSADT.ProcessManagement.RunningProcess[]]$runningProcesses = Get-ADTRunningProcesses -ProcessObjects $CloseProcesses)) {
		$control_MainWindow.Tag = $script:ExitCodes['Continue']
		if ($control_MainWindow.IsLoaded) {
			$control_MainWindow.Close()
		}
		return
	}

	$control_CloseApplicationList.BeginInit()
	$control_CloseApplicationList.Items.Clear()
	$runningProcesses |
		Select-Object -Unique -Property @(
			@{ Name = 'Name'; Expression = { if ([System.String]::IsNullOrWhiteSpace($_.Description)) { $_.Process.Name } else { $_.Description } } },
			@{ Name = 'StartedBy'; Expression = { if ($_.Username) { $_.Username.Value } else { 'N/A' } } }
		) |
		& { process { $null = $control_CloseApplicationList.Items.Add($_) } }

	$control_CloseApplicationList.EndInit()
	$control_PopupListText.Text = [System.String]::Join(', ', ($runningProcesses.Process.Name | Select-Object -Unique))
}

# Preload the application list, exit immediately if no applications are running
& $updateProcessUi
if ($control_MainWindow.Tag) {
	& $mainWindowClosed
	exit ($control_MainWindow.Tag)
}

[System.Windows.Threading.DispatcherTimer]$timerRunningProcesses = [System.Windows.Threading.DispatcherTimer]::new()
$timerRunningProcesses.Interval = [System.TimeSpan]::FromSeconds(1)
[System.Management.Automation.ScriptBlock]$timerRunningProcesses_Tick = {
	$control_MainWindow.Dispatcher.InvokeAsync($updateProcessUi)
}
$timerRunningProcesses.add_Tick($timerRunningProcesses_Tick)
#endregion Dynamic process evaluation

# Open dialog and Wait
if ($MinimizeWindows) {
	[System.__ComObject]$shellApp = New-Object -ComObject 'Shell.Application'
	$shellApp.MinimizeAll()
}

$null = $control_MainWindow.ShowDialog()

if ($MinimizeWindows) {
	$shellApp.UndoMinimizeAll()
}

exit $(if ($control_MainWindow.Tag) { $control_MainWindow.Tag } else { $script:ExitCodes['Timeout'] })
#endregion
