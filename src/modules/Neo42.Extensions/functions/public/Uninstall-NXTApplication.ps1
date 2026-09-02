function Uninstall-NXTApplication {
	<#
	.SYNOPSIS
	Uninstalls an application based on the neo42 logic.
	.DESCRIPTION
	Contains all installer specific code to uninstall an application.
	Supports multiple parameter sets to allow for different types of application definitions.
	.INPUTS
	PSADTNXT.Package.NxtRegisteredPackage - The registered package to use for the uninstallation.

	PSADT.Types.InstalledApplication - The installed application to use for the uninstallation.

	System.IO.FileInfo - The file to use for the uninstallation.
	.OUTPUTS
	PSADT.ProcessManagement.ProcessResult - The result of the uninstallation process.
	.PARAMETER Target
	The path to the uninstaller file.
	.PARAMETER UninstallKey
	The full path to the uninstall key that this invocation uninstalls. Used for collection information about the uninstall process.
	.PARAMETER Method
	The method to use for the uninstallation.
	.PARAMETER ArgumentList
	The arguments to pass to the uninstaller.
	If not specified, the default arguments for the method will be used.
	Be aware that arguments are automatically escaped to ensure that they are properly formatted for the process start.
	Manual escaping will be passed as a literal string to the process.
	.PARAMETER AdditionalArgumentList
	The additional arguments to pass to the uninstaller.
	.PARAMETER CacheDirectory
	The package directory to use for the uninstallation.
	.PARAMETER Awaiter
	Optional awaiter objects that should be evaluated post uninstallation.
	.PARAMETER LogFileName
	The path to the log file ending with a .log extension.
	This file will reside in the log directory of the ADT session.
	The resulting full path is available as %LogFile% in the ArgumentList.
	.PARAMETER SuccessExitCodes
	The exit codes that indicate a successful uninstallation.
	.PARAMETER RebootExitCodes
	The exit codes that indicate a reboot is required after the uninstallation.
	.PARAMETER IgnoreExitCodes
	Determines if the function should ignore exit codes and not treat them as errors.
	.PARAMETER NoCache
	Determines if the function should avoid using cached uninstaller files.
	.PARAMETER ExitOnProcessFailure
	Determines if the function should exit with an error if the process fails. If this parameter is specified, the deployment will be aborted.
	.EXAMPLE
	Uninstall-NXTApplication -Target 'C:\Temp\test.msi' -ArgumentList '/quiet /norestart' -Method MSI

	Uninstalls the application using the MSI method with the specified arguments.
	.EXAMPLE
	Get-ADTApplication -Name 'Test' | Uninstall-NXTApplication

	Uninstalls the application using a application object.
	.EXAMPLE
	Get-NXTRegisteredPackage -PackageId '{0420EDC6-CF5E-4C88-8D5E-B81A5E7F3D6A}' | Uninstall-NXTApplication

	Uninstalls the application using a registered package object.
	#>
	[CmdletBinding(DefaultParameterSetName = 'ManualExitCodes')]
	[OutputType([PSADT.ProcessManagement.ProcessResult])]
	param (
		[Parameter(ParameterSetName = 'PackageExitCodes', Position = 0, Mandatory, ValueFromPipeline)]
		[Parameter(ParameterSetName = 'PackageIgnoreExitCodes', Position = 0, Mandatory, ValueFromPipeline)]
		[ValidateNotNull()]
		[PSADTNXT.Package.NxtRegisteredPackage]
		$Package,
		[Parameter(ParameterSetName = 'ApplicationExitCodes', Position = 0, Mandatory, ValueFromPipeline)]
		[Parameter(ParameterSetName = 'ApplicationIgnoreExitCodes', Position = 0, Mandatory, ValueFromPipeline)]
		[ValidateNotNull()]
		[PSADT.Types.InstalledApplication]
		$Application,

		[Parameter(ParameterSetName = 'ManualExitCodes', Position = 0, Mandatory)]
		[Parameter(ParameterSetName = 'ManualIgnoreExitCodes', Position = 0, Mandatory)]
		[Alias('Path', 'FullName')]
		[AllowEmptyString()]
		[System.String]
		$Target,
		[Parameter(ParameterSetName = 'ManualExitCodes')]
		[Parameter(ParameterSetName = 'ManualIgnoreExitCodes')]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$UninstallKey,

		[Parameter(ParameterSetName = 'ManualExitCodes')]
		[Parameter(ParameterSetName = 'ManualIgnoreExitCodes')]
		[Parameter(ParameterSetName = 'ApplicationExitCodes')]
		[Parameter(ParameterSetName = 'ApplicationIgnoreExitCodes')]
		[PSADTNXT.Deployment.DeploymentMethod]
		$Method = 'Setup',
		[Parameter(ParameterSetName = 'ManualExitCodes')]
		[Parameter(ParameterSetName = 'ManualIgnoreExitCodes')]
		[Parameter(ParameterSetName = 'ApplicationExitCodes')]
		[Parameter(ParameterSetName = 'ApplicationIgnoreExitCodes')]
		[System.String[]]
		$ArgumentList,
		[Parameter(ParameterSetName = 'ManualExitCodes')]
		[Parameter(ParameterSetName = 'ManualIgnoreExitCodes')]
		[Parameter(ParameterSetName = 'ApplicationExitCodes')]
		[Parameter(ParameterSetName = 'ApplicationIgnoreExitCodes')]
		[System.String[]]
		$AdditionalArgumentList,
		[Parameter(ParameterSetName = 'ManualExitCodes')]
		[Parameter(ParameterSetName = 'ManualIgnoreExitCodes')]
		[Parameter(ParameterSetName = 'ApplicationExitCodes')]
		[Parameter(ParameterSetName = 'ApplicationIgnoreExitCodes')]
		[ValidateScript({ [System.IO.Path]::IsPathRooted($_) })]
		[System.String]
		$CacheDirectory = (Get-ADTSession).NXT.Package.Directory,
		[PSADTNXT.Deployment.INxtAwaiter[]]
		$Awaiter,

		[PSDefaultValue(Value = 'ID.$deploymentTimestamp.log')]
		[ValidateScript({ $_ -like '*.log' })]
		[System.String]
		$LogFileName,

		[Parameter(ParameterSetName = 'PackageExitCodes')]
		[Parameter(ParameterSetName = 'ApplicationExitCodes')]
		[Parameter(ParameterSetName = 'ManualExitCodes')]
		[PSDefaultValue(Help = 'Defaults depend on the method and session configuration.')]
		[System.Int32[]]
		$SuccessExitCodes,
		[Parameter(ParameterSetName = 'PackageExitCodes')]
		[Parameter(ParameterSetName = 'ApplicationExitCodes')]
		[Parameter(ParameterSetName = 'ManualExitCodes')]
		[PSDefaultValue(Help = 'Defaults depend on the method and session configuration.')]
		[System.Int32[]]
		$RebootExitCodes,
		[Parameter(ParameterSetName = 'PackageExitCodes')]
		[Parameter(ParameterSetName = 'ApplicationExitCodes')]
		[Parameter(ParameterSetName = 'ManualExitCodes')]
		[System.Management.Automation.SwitchParameter]
		$ExitOnProcessFailure,
		[Parameter(ParameterSetName = 'PackageIgnoreExitCodes', Mandatory)]
		[Parameter(ParameterSetName = 'ApplicationIgnoreExitCodes', Mandatory)]
		[Parameter(ParameterSetName = 'ManualIgnoreExitCodes', Mandatory)]
		[System.Management.Automation.SwitchParameter]
		$IgnoreExitCodes,
		[System.Management.Automation.SwitchParameter]
		$NoCache
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Collections.Hashtable]$adtConfig = Get-ADTConfig
		[PSADTNXT.Foundation.NxtDeploymentSession]$adtSession = Get-ADTSession
		[System.Collections.Generic.IReadOnlyDictionary[System.String, System.Object]]$adtEnvironment = Get-ADTEnvironmentTable
	}
	process {
		try {
			[PSADT.ProcessManagement.ProcessResult]$result = [PSADT.ProcessManagement.ProcessResult]::new(0)
			[System.Text.StringBuilder]$finalArguments = [System.Text.StringBuilder]::new()
			if ($PSBoundParameters.ContainsKey('ArgumentList') -and $ArgumentList) {
				if ($ArgumentList.Length -gt 1) {
					$null = $finalArguments.Append([PSADT.ProcessManagement.CommandLineUtilities]::ArgumentListToCommandLine($ArgumentList))
				}
				else {
					$null = $finalArguments.Append($ArgumentList[0])
				}
				$null = $finalArguments.Append(' ')
			}
			if ($PSBoundParameters.ContainsKey('AdditionalArgumentList') -and $AdditionalArgumentList) {
				if ($AdditionalArgumentList.Length -gt 1) {
					$null = $finalArguments.Append([PSADT.ProcessManagement.CommandLineUtilities]::ArgumentListToCommandLine($AdditionalArgumentList))
				}
				else {
					$null = $finalArguments.Append($AdditionalArgumentList[0])
				}
				$null = $finalArguments.Append(' ')
			}

			# Parse the different parameter sets into the 'Manual' set
			switch ($PSCmdlet.ParameterSetName) {
				{ $_ -like 'Package*' } {
					$Target = $Package.UninstallTarget
					$UninstallKey = $Package.PSPath
					$Method = $Package.UninstallMethod
					$CacheDirectory = $Package.PackageDirectory
					if (-not $PSBoundParameters.ContainsKey('LogFileName')) { $LogFileName = "$($Package.Name).$($adtEnvironment.DeploymentTimestamp)_Uninstall.log" }

					$null = $finalArguments.Insert(0, $Package.UninstallArguments + ' ')
					break
				}
				{ $_ -like 'Application*' } {
					if (-not $PSBoundParameters.ContainsKey('Method')) {
						$Method = if ($Application.WindowsInstaller) { [PSADTNXT.Deployment.DeploymentMethod]::MSI } else { [PSADTNXT.Deployment.DeploymentMethod]::Setup }
					}
					$Target = if ($Method -eq [PSADTNXT.Deployment.DeploymentMethod]::MSI) {
						$Application.PSChildName
					}
					else {
						[PSADTNXT.Shell.NxtCommandLine]::SearchPath(
							$(if (-not [System.String]::IsNullOrWhiteSpace($Application.QuietUninstallStringFilePath)) { $Application.QuietUninstallStringFilePath } else { $Application.UninstallStringFilePath }),
							[System.EnvironmentVariableTarget]::Machine
						)
					}
					$UninstallKey = $Application.PSPath

					if (-not $PSBoundParameters.ContainsKey('ArgumentList')) {
						if ($adtConfig['NXT']['Deployment'][$Method.ToString()]) {
							$null = $finalArguments.Insert(0, $adtConfig['NXT']['Deployment'][$Method.ToString()]['UninstallParams'] + ' ')
						}
						else {
							[System.String]$applicationUninstallArguments = $(
								if ($Application.QuietUninstallStringArgumentList) { [PSADT.ProcessManagement.CommandLineUtilities]::ArgumentListToCommandLine($Application.QuietUninstallStringArgumentList) }
								elseif ($Application.UninstallStringArgumentList) { [PSADT.ProcessManagement.CommandLineUtilities]::ArgumentListToCommandLine($Application.UninstallStringArgumentList) }
								else { [System.String]::Empty }
							).Trim()
							$null = $finalArguments.Insert(0, $applicationUninstallArguments + ' ')
						}
					}

					if (-not $PSBoundParameters.ContainsKey('LogFileName')) {
						$LogFileName = "$($Application.DisplayName).$($adtEnvironment.DeploymentTimestamp)_Uninstall.log"
					}
					break
				}
				{ $_ -like 'Manual*' } {
					if (-not $PSBoundParameters.ContainsKey('ArgumentList') -and $adtConfig['NXT']['Deployment'][$Method.ToString()]) {
						$null = $finalArguments.Insert(0, $adtConfig['NXT']['Deployment'][$Method.ToString()]['UninstallParams'])
					}
					if (-not $PSBoundParameters.ContainsKey('LogFileName')) {
						[System.String]$logId = $Target.Split(
							[System.Char[]]@([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar),
							[System.StringSplitOptions]::RemoveEmptyEntries
						)[-1]

						$LogFileName = "$logId.$($adtEnvironment.DeploymentTimestamp)_Uninstall.log"
					}
					break
				}
			}

			# Escape any invalid and whitespace characters in the log file name and build the log file path.
			$LogFileName = [PSADTNXT.Extensions.NxtStringExtensions]::ToFileNameCompatible($LogFileName, $true, '_')
			[System.IO.FileInfo]$logFile = [System.IO.Path]::Combine($adtSession.LogPath, $LogFileName)

			# Replace known variables in the target and arguments
			@{
				'%LogFile%'          = $logFile.FullName
				'%DirFiles%'         = if ($adtSession.DirFiles) { $adtSession.DirFiles } else { [System.String]::Empty }
				'%DirSupportFiles%'  = if ($adtSession.DirSupportFiles) { $adtSession.DirSupportFiles } else { [System.String]::Empty }
				'%PackageDirectory%' = $adtSession.NXT.Package.Directory.FullName
			}.GetEnumerator() | & {
				process {
					$Target = $Target.Replace($_.Key, $_.Value)
					$null = $finalArguments.Replace($_.Key, $_.Value)
				}
			}

			[System.Collections.Hashtable]$startSplat = Remove-ADTHashtableNullOrEmptyValues @{
				FilePath             = if (-not [System.IO.Path]::IsPathRooted($Target) -and $adtSession.DirFiles) { [System.IO.Path]::Combine($adtSession.DirFiles, $Target) } else { $Target }
				ArgumentList         = $finalArguments.ToString().Trim()
				PassThru             = $true
				SuccessExitCodes     = $SuccessExitCodes
				RebootExitCodes      = $RebootExitCodes
				ExitOnProcessFailure = $ExitOnProcessFailure.ToBool()
				ErrorAction          = if ($IgnoreExitCodes) { [System.Management.Automation.ActionPreference]::Ignore } else { [System.Management.Automation.ActionPreference]::Stop }
			}

			[System.String]$backupFileSelector = [System.String]::Empty
			[System.Collections.Generic.List[PSADTNXT.Deployment.INxtAwaiter]]$waits = [System.Collections.Generic.List[PSADTNXT.Deployment.INxtAwaiter]]::new()
			if ($Awaiter) { $waits.AddRange($Awaiter) }

			Write-ADTLogEntry -Message "Starting uninstallation process for target [$Target] with method [$Method]."
			switch ($Method) {
				([PSADTNXT.Deployment.DeploymentMethod]::Copy) {
					try {
						Remove-ADTFolder -Path $Target
						return [PSADT.ProcessManagement.ProcessResult]::new(0)
					}
					catch {
						if ($ExitOnProcessFailure) {
							Write-ADTLogEntry -Severity Warning -Message "An error occurred while trying to delete the folder [$Target]."
							Write-ADTLogEntry -Severity Warning -Message (Resolve-ADTErrorRecord -ErrorRecord $_)
							Close-ADTSession -ExitCode 1
						}
						return [PSADT.ProcessManagement.ProcessResult]::new(
							(-not $IgnoreExitCodes).ToInt32($null),
							[System.Collections.Generic.List[System.String]]::new().AsReadOnly(),
							[System.Collections.Generic.List[System.String]]::new([System.String[]]@($_.Exception.Message)).AsReadOnly(),
							[System.Collections.Generic.List[System.String]]::new([System.String[]]@($_.Exception.Message)).AsReadOnly()
						)
					}
				}
				([PSADTNXT.Deployment.DeploymentMethod]::MSI) {
					[System.Guid]$guid = [System.Guid]::Empty
					if ([System.Guid]::TryParse($Target, [ref]$guid)) {
						$null = $startSplat.Remove('FilePath')
						$startSplat['ProductCode'] = $Target
					}

					$result = Start-ADTMsiProcess @startSplat -Action Uninstall -SkipMSIAlreadyInstalledCheck -NoDesktopRefresh -LogFileName ($LogFileName -replace '_Uninstall\.log$', [System.String]::Empty)
					break
				}
				([PSADTNXT.Deployment.DeploymentMethod]::AppX) {
					# Use full name directly
					[System.String[]]$identifiers = if ($Target -like '*_*_*_*_*') {
						@($Target)
					}
					# Search for member of family
					elseif ($Target -like '*_*') {
						[System.String]$filter = $Target.Replace('_', '*')
						@(Get-AppxProvisionedPackage -Online | & { process { if ($_.PackageName -like $filter) { $_.PackageName } } })
					}
					else {
						[System.Collections.Hashtable]$errorParams = @{
							Exception    = [System.ArgumentException]::new("The given identifier [$Target] is not a valid AppX package full name or family name.")
							Category     = [System.Management.Automation.ErrorCategory]::InvalidArgument
							ErrorId      = 'InvalidAppXIdentifier'
							TargetObject = $Target
						}
						throw (New-ADTErrorRecord @errorParams)
					}

					if ($identifiers.Length -eq 0) {
						Write-ADTLogEntry -Severity Warning -Message "The AppX package family [$Target] does not exist or is not installed."
						return $result
					}
					if ($identifiers.Length -gt 1) {
						[System.Collections.Hashtable]$errorParams = @{
							Exception      = [System.InvalidOperationException]::new("The given identifier [$Target] family contains multiple identifiers.")
							Category       = [System.Management.Automation.ErrorCategory]::InvalidOperation
							ErrorId        = 'MultipleApplicationsFound'
							TargetObject   = $Target
							Recommendation = 'Please uninstall the application manually'
						}
						throw (New-ADTErrorRecord @errorParams)
					}
					$startSplat['FilePath'] = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('System'), 'Dism.exe')
					$startSplat['ArgumentList'] = "/Online /NoRestart /English /LogPath:`"$($logFile.FullName)`" /Remove-ProvisionedAppxPackage /PackageName:$($identifiers[0]) " + $startSplat['ArgumentList']
				}
				([PSADTNXT.Deployment.DeploymentMethod]::Burn) {
					$startSplat['ArgumentList'] = '/uninstall ' + $startSplat['ArgumentList'] + ' /log "' + $logFile.FullName + '"'
				}
				([PSADTNXT.Deployment.DeploymentMethod]::InnoSetup) {
					$startSplat['ArgumentList'] = $startSplat['ArgumentList'] + " /LOG=`"$($logFile.FullName)`""
					$backupFileSelector = 'unins[0-9][0-9][0-9].*'
				}
				([PSADTNXT.Deployment.DeploymentMethod]::NullSoft) {
					$backupFileSelector = [System.IO.Path]::GetFileName($Target)
					$waits.Add([PSADTNXT.Deployment.NxtProcessAwaiter]::new('AU_', $true, [System.TimeSpan]::FromMinutes(10)))
					$waits.Add([PSADTNXT.Deployment.NxtProcessAwaiter]::new('Un_A', $true, [System.TimeSpan]::FromMinutes(10)))
					$waits.Add([PSADTNXT.Deployment.NxtProcessAwaiter]::new('Un', $true, [System.TimeSpan]::FromMinutes(10)))
				}
				([PSADTNXT.Deployment.DeploymentMethod]::BitRockInstaller) {
					$backupFileSelector = 'unins*.exe'
					$waits.Add([PSADTNXT.Deployment.NxtProcessAwaiter]::new('_Uninstall*', $true, [System.TimeSpan]::FromMinutes(10)))
				}
				{ $true } {
					# Try to retrieve the backup file path if the uninstaller file does not exist
					if (-not [System.IO.File]::Exists($startSplat['FilePath'])) {
						Write-ADTLogEntry -Severity Warning -Message "The original uninstaller file [$($startSplat['FilePath'])] does not exist. Trying to use the backup uninstaller file."

						if (-not $NoCache -and
							-not [System.String]::IsNullOrWhiteSpace($backupFileSelector) -and
							-not [System.String]::IsNullOrWhiteSpace($UninstallKey) -and
							-not [System.String]::IsNullOrWhiteSpace($CacheDirectory)
						) {
							Write-ADTLogEntry -Message 'Searching for the backup uninstaller file in the cache directory.' -DebugMessage
							[System.String]$backupFullPathSelector = [System.IO.Path]::Combine($CacheDirectory, 'neo42-Source', [System.IO.Path]::GetFileName($UninstallKey), $backupFileSelector)
							[System.String]$targetDirectory = [System.IO.Path]::GetDirectoryName($startSplat.FilePath)
							if (-not [System.IO.Directory]::Exists($targetDirectory)) { $null = [System.IO.Directory]::CreateDirectory($targetDirectory) }
							Copy-Item -Path $backupFullPathSelector -Destination $targetDirectory -Force
							if (-not [System.IO.File]::Exists($startSplat.FilePath)) {
								[System.Collections.Hashtable]$errorParams = @{
									Exception    = [System.InvalidOperationException]::new("The backup did not contain the required [$($startSplat.FilePath)] file.")
									Category     = [System.Management.Automation.ErrorCategory]::InvalidOperation
									ErrorId      = 'NoBackupAvailable'
									TargetObject = $startSplat.FilePath
								}
								throw (New-ADTErrorRecord @errorParams)
							}
						}
						else {
							[System.Collections.Hashtable]$errorParams = @{
								Exception    = [System.InvalidOperationException]::new("The uninstall method [$Method] does not support backups or caching is disabled.")
								Category     = [System.Management.Automation.ErrorCategory]::InvalidOperation
								ErrorId      = 'NoBackupAvailable'
								TargetObject = $startSplat.FilePath
							}
							throw (New-ADTErrorRecord @errorParams)
						}
					}

					# Start the uninstallation process
					$result = Start-ADTProcess @startSplat
				}
				([PSADTNXT.Deployment.DeploymentMethod]::AppX) {
					try {
						Write-ADTLogEntry -Message "Removing all user instances of the AppX package family [$Target]."
						Remove-AppxPackage -AllUsers -Package $identifiers[0]
					}
					catch {
						$result = [PSADT.ProcessManagement.ProcessResult]::new(
							1,
							[System.Collections.Generic.List[System.String]]::new().AsReadOnly(),
							[System.Collections.Generic.List[System.String]]::new([System.String[]]@($_.Exception.Message)).AsReadOnly(),
							[System.Collections.Generic.List[System.String]]::new([System.String[]]@($_.Exception.Message)).AsReadOnly()
						)
					}
				}
			}

			Wait-NXTDeploymentAwaiter -Awaiter $waits
			return $result
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
