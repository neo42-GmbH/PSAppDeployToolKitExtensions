@{
	Assets  = @{
		# Specify filename or Base64 string of the logo.
		Logo        = '..\Assets\Logo.png'

		# Specify filename or Base64 string of the logo (for dark mode).
		LogoDark    = $null

		# Specify filename or Base64 string of the banner (Classic-only).
		Banner      = '..\Assets\Banner.Classic.png'

		# Specify filename or Base64 of the banner for dark mode (Legacy-only).
		BannerDark  = '..\Assets\Banner.Classic.Dark.png'

		# Specify optional filename or Base64 string of the tray icon.
		TaskbarIcon = $null
	}

	MSI     = @{
		#MSI install parameters used in interactive mode.
		InstallParams        = 'MSIRESTARTMANAGERCONTROL=Disable REBOOT=ReallySuppress ALLUSERS=1 /qn'

		# Logging level used for MSI logging.
		LoggingOptions       = '/L*Vx'

		# Log path used for MSI logging. Uses the same path as Toolkit when null or empty.
		LogPath              = $null

		# Log path used for MSI logging when RequireAdmin is False. Uses the same path as Toolkit when null or empty.
		LogPathNoAdminRights = $null

		# The length of time in seconds to wait for the MSI installer service to become available. Default is 600 seconds (10 minutes).
		MutexWaitTime        = 120

		# MSI install parameters used in silent mode.
		SilentParams         = 'MSIRESTARTMANAGERCONTROL=Disable REBOOT=ReallySuppress ALLUSERS=1 /qn'

		# MSI uninstall parameters.
		UninstallParams      = 'MSIRESTARTMANAGERCONTROL=Disable REBOOT=ReallySuppress ALLUSERS=1 /qn'
	}

	Toolkit = @{
		# Specify the path for the cache folder.
		CachePath                 = '$envProgramData\SoftwareCache'

		# The name to show by default for dialog subtitles, balloon notifications, etc.
		CompanyName               = 'neo42 Package'

		# Specify if the log files should be bundled together in a compressed zip file.
		CompressLogs              = $false

		# Choose from either 'Native' for native PowerShell file copy via Copy-ADTFile, or 'Robocopy' to use robocopy.exe.
		FileCopyMode              = 'Native'

		# Specify if an existing log file should be appended to.
		LogAppend                 = $false

		# Specify if debug messages such as bound parameters passed to a function should be logged.
		LogDebugMessage           = $false

		# Specify the maximum amount of hierarchical structures to maintain when LogToHierarchy is true.
		LogMaxHierarchy           = 3

		# Specify maximum number of previous log files to retain.
		LogMaxHistory             = 5

		# Specify maximum file size limit for log file in megabytes (MB).
		LogMaxSize                = 5

		# Log path used for Toolkit logging.
		LogPath                   = '$envProgramData\neo42PkgsLogs'

		# Same as LogPath but used when RequireAdmin is False.
		LogPathNoAdminRights      = '$envProgramData\neo42PkgsLogs'

		# Specifies that logging should be to a hierarchical structure of AppVendor\AppName\AppVersion. Takes precident over "LogToSubfolder" if both are set.
		LogToHierarchy            = $true

		# Specifies that a subfolder based on InstallName should be used for all log capturing.
		LogToSubfolder            = $false

		# Specify if log file should be a CMTrace compatible log file or a Legacy text log file.
		LogStyle                  = 'CMTrace'

		# Specify if log messages should be written to the console.
		LogWriteToHost            = $true

		# Specify if console log messages should bypass PowerShell's subsystems and be sent direct to stdout/stderr.
		# This only applies if "LogWriteToHost" is true, and the script is being ran in a ConsoleHost (not the ISE, or another host).
		LogHostOutputToStdStreams = $false

		# Registry key used to store toolkit information (with PSAppDeployToolkit as child registry key), e.g. deferral history.
		RegPath                   = 'HKLM:\SOFTWARE\neoPackages'

		# Same as RegPath but used when RequireAdmin is False. Bear in mind that since this Registry Key should be writable without admin permission, regular users can modify it also.
		RegPathNoAdminRights      = 'HKCU:\SOFTWARE\neoPackages'

		# Path used to store temporary Toolkit files (with PSAppDeployToolkit as subdirectory), e.g. cache toolkit for cleaning up blocked apps.
		# Normally you don't want this set to a path that is writable by regular users, this might lead to a security vulnerability.
		# The default Temp variable for the LocalSystem account is C:\Windows\Temp.
		TempPath                  = '$envTemp'

		# Same as TempPath but used when RequireAdmin is False.
		TempPathNoAdminRights     = '$envTemp'
	}

	UI      = @{
		# Used to turn automatic balloon notifications on or off.
		BalloonNotifications         = $false

		# Choose from either 'Fluent' for contemporary dialogs, or 'Classic' for PSAppDeployToolkit 3.x WinForms dialogs.
		DialogStyle                  = 'Fluent'

		# Specify the Accent Color in hex (with the first two characters for transparency, 00 = 0%, FF = 100%), e.g. 0xFF0078D7.
		# The value specified here should be literally typed (i.e. `FluentAccentColor = 0xFF0078D7`) and not wrapped in quotes.
		FluentAccentColor            = 0xFFE3000F

		# Specify the Accent Color in hex for dark mode (with the first two characters for transparency, 00 = 0%, FF = 100%), e.g. 0xFF0078D7.
		# The value specified here should be literally typed (i.e. `FluentAccentColorDark = 0xFF0078D7`) and not wrapped in quotes.
		FluentAccentColorDark        = $null

		# Exit code used when a UI prompt times out.
		DefaultExitCode              = 1618

		# Time in seconds after which the prompt should be repositioned centre screen when the -PersistPrompt parameter is used. Default is 60 seconds.
		DefaultPromptPersistInterval = 60

		# Time in seconds to automatically timeout installation dialogs. Default is 55 minutes so that dialogs timeout before Intune times out.
		DefaultTimeout               = 3300

		# Exit code used when a user opts to defer.
		DeferExitCode                = 1602

		<# Specify a static UI language using the one of the Language Codes listed below to override the language culture detected on the system.
			Language Code    Language
			=============    ========
			ar               Arabic
			bg               Bulgarian
			cs               Czech
			da               Danish
			de               German
			en               English
			el               Greek
			es               Spanish
			fi               Finnish
			fr               French
			he               Hebrew
			hu               Hungarian
			it               Italian
			ja               Japanese
			ko               Korean
			lv               Latvian
			nl               Dutch
			nb               Norwegian (Bokmål)
			pl               Polish
			pt               Portuguese (Portugal)
			pt-BR            Portuguese (Brazil)
			ru               Russian
			sk               Slovak
			sv               Swedish
			tr               Turkish
			zh-CN            Chinese (Simplified)
			zh-HK            Chinese (Traditional)
		#>
		LanguageOverride             = $null

		# Time in seconds after which to re-prompt the user to close applications in case they ignore the prompt or they cancel the application's save prompt.
		PromptToSaveTimeout          = 120

		# Time in seconds after which the restart prompt should be re-displayed/repositioned when the -NoCountdown parameter is specified. Default is 600 seconds.
		RestartPromptPersistInterval = 600
	}

	# Region for Neo42.Extensions specific configuration.
	NXT     = @{
		PowerShell = @{
			# Specify the execution policy preference for the session.
			ExecutionPolicy       = 'Bypass'

			# Specify the error action preference for the session.
			ErrorActionPreference = 'Stop'

			# Specify the verbose action preference for the session.
			VerbosePreference     = 'SilentlyContinue'

			# Specify the progress action preference for the session.
			ProgressPreference    = 'SilentlyContinue'

			# Specify the output encoding the session should use. Supported values originate from the PSADTNXT.Text.FileEncoding enum.
			OutputEncoding        = 'UTF8'

			# Define the coding standards that are required in the deployment environment.
			# Set this to an empty string to disable setting the strict mode.
			# See https://learn.microsoft.com/en-US/powershell/module/microsoft.powershell.core/set-strictmode?view=powershell-5.1#-version
			StrictModeVersion     = '3.0'
		}

		Toolkit    = @{
			# With the introduction of PSADTv4 the package configuration format and APIs have changed significantly.
			# To maintain compatibility with existing packages, the toolkit can operate in a legacy mode that
			# mimics the behavior of PSADTv3 as closely as possible.
			# It is highly recommended to migrate packages to the new format and disable this option as soon as possible.
			# Note that some features may not be available when legacy mode is enabled.
			SupportLegacyConfig        = $true

			# Enable or disable the blocking of application execution while the deployment is running.
			# This feature may be flagged by some antivirus solutions as it hooks into process creation APIs.
			BlockExecution             = $false

			# Define wether package display names should be appended the package version in the Windows Apps & Features list.
			AppendVersionToPackageName = $true

			# Conditionally disable user parts if the toolkit detects that it is running on a terminal server.
			# This is useful in scenarios where the user context is not relevant, e.g. when user profiles are not persistent or PowerShell is disabled for users.
			UserPartOnTerminalServer   = $true
		}

		UI         = @{
			# Configures what UI mode for the AppCloseProcesses dialog should be used.
			# The default neo42 UI dialog is considered legacy from v4 onwards and will at some point be dropped in favor of the integrated PSADT dialogs.
			# Note that as of the the release of PSADT v4.2 the PSADT UIs cannot yet support multi user sessions! Support is planned for a future release.
			# For migration purposes the old UI is set by default. If you intend to use the new UI already, set this value to $false.
			UseLegacyUI = $true
		}

		Deployment = @{
			InnoSetup        = @{
				InstallParams   = '/FORCEINSTALL /VERYSILENT /SP- /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /RESTARTEXITCODE=3010 /ALLUSERS'
				SilentParams    = '/FORCEINSTALL /VERYSILENT /SP- /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /RESTARTEXITCODE=3010 /ALLUSERS'
				UninstallParams = '/VERYSILENT /SP- /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /RESTARTEXITCODE=3010'
			}
			Nullsoft         = @{
				InstallParams   = '/AllUsers /S'
				SilentParams    = '/AllUsers /S'
				UninstallParams = '/AllUsers /S'
			}
			BitRockInstaller = @{
				InstallParams   = '--mode unattended'
				SilentParams    = '--mode unattended'
				UninstallParams = '--mode unattended'
			}
			Burn             = @{
				InstallParams   = '/quiet MSIRESTARTMANAGERCONTROL=Disable REBOOT=ReallySuppress ALLUSERS=1'
				SilentParams    = '/quiet MSIRESTARTMANAGERCONTROL=Disable REBOOT=ReallySuppress ALLUSERS=1'
				UninstallParams = '/quiet MSIRESTARTMANAGERCONTROL=Disable REBOOT=ReallySuppress ALLUSERS=1'
			}
			AppX             = @{
				InstallParams   = '/Region:all /SkipLicense'
				SilentParams    = '/Region:all /SkipLicense'
				UninstallParams = ''
			}
		}
	}
}
