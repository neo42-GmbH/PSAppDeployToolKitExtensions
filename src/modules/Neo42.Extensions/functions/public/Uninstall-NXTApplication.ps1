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
	If not specified, the target is resolved from the application found by the Criteria.
	.PARAMETER Application
	The installed application object to use for the uninstallation.
	.PARAMETER Package
	The registered package object to use for the uninstallation.
	.PARAMETER Criteria
	The application lookup criteria used to find the application in a application store.
	The resulting data is used for defaults, validation and backup mechanics.
	Values that are not specified (Target, Method, ArgumentList, LogFileName) default to the data of the found application.
	After the uninstallation, the criteria must no longer match any application.
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
	.PARAMETER SuccessExitCodes
	The exit codes that indicate a successful uninstallation.
	.PARAMETER RebootExitCodes
	The exit codes that indicate a reboot is required after the uninstallation.
	.PARAMETER IgnoreExitCodes
	Determines if the function should ignore exit codes and not treat them as errors.
	.PARAMETER ExitOnProcessFailure
	The session will be immediatly closed if the execution fails.
	.PARAMETER NoCache
	Determines if the function should avoid using cached uninstaller files.
	.EXAMPLE
	Uninstall-NXTApplication -Target '$envProgramFiles\myprogram\uninstall.exe' -ArgumentList '\q'

	Starts the uninstall.exe with the '\q' parameter but without any further logic attached to it (Method: Setup)
	.EXAMPLE
	Uninstall-NXTApplication -Target '{5DE0DE9D-5ABE-453E-8A84-A4BF443FC24B}' -Method MSI

	Uninstalls the MSI application that is registered with above product code.
	.EXAMPLE
	Uninstall-NXTApplication -Criteria @{ Store = 'ARP'; Identifier = 'TestApp' }

	Uninstalls the application found by the criteria using its registered uninstall information and validates its removal afterwards.
	.EXAMPLE
	Get-NXTApplication -Identifier '{0420EDC6-CF5E-4C88-8D5E-B81A5E7F3D6A}' | Uninstall-NXTApplication

	Uninstalls the application using a application object obtained from the NXT function.
	.EXAMPLE
	Get-ADTApplication -Name 'Test' -NameMatch 'Exact' | Uninstall-NXTApplication

	Uninstalls the application using a application object obtained from the ADT function.
	.EXAMPLE
	Get-NXTRegisteredPackage -PackageId '{0420EDC6-CF5E-4C88-8D5E-B81A5E7F3D6A}' | Uninstall-NXTApplication

	Uninstalls the application referenced by a registered package object.
	.EXAMPLE
	Uninstall-NXTApplication -Target 'Microsoft.WindowsScan_8wekyb3d8bbwe' -Method Appx

	Deprovisions the Windows Scanner Appx app for all users.
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

		[Parameter(ParameterSetName = 'ManualExitCodes', Position = 0)]
		[Parameter(ParameterSetName = 'ManualIgnoreExitCodes', Position = 0)]
		[Alias('Path', 'FullName')]
		[System.String]
		$Target,
		[Parameter(ParameterSetName = 'ManualExitCodes')]
		[Parameter(ParameterSetName = 'ManualIgnoreExitCodes')]
		[ValidateNotNull()]
		[PSADTNXT.Application.NxtApplicationCriteria]
		$Criteria,

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
		[System.IO.DirectoryInfo]
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
			[PSADT.ProcessManagement.ProcessResult]$result = $null
			[System.IO.DirectoryInfo]$uninstallFileBackupDirectory = $null
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

			# Resolve the application of the lookup criteria to use its data as defaults
			if ($PSCmdlet.ParameterSetName -like 'Manual*' -and $Criteria) {
				[PSADT.Types.InstalledApplication[]]$criteriaApplications = @(Get-NXTApplication -Criteria $Criteria)
				if ($criteriaApplications.Length -eq 1) {
					$Application = $criteriaApplications[0]
				}
				elseif ($criteriaApplications.Length -gt 1) {
					[System.Collections.Hashtable]$errorParams = @{
						Exception    = [System.InvalidOperationException]::new("Application lookup criteria were provided but [$($criteriaApplications.Length)] applications were found before uninstallation. Must be at most [1].")
						Category     = [System.Management.Automation.ErrorCategory]::InvalidResult
						ErrorId      = 'MultipleApplicationsFound'
						TargetObject = $Criteria
					}
					throw (New-ADTErrorRecord @errorParams)
				}
				else {
					Write-ADTLogEntry -Severity Warning -Message 'Application lookup criteria were provided but no application was found before uninstallation. Continuing without application defaults.'
					return [PSADT.ProcessManagement.ProcessResult]::new(0)
				}
			}

			# Parse the different parameter sets into the 'Manual' set
			switch ($PSCmdlet.ParameterSetName) {
				{ $_ -like 'Package*' } {
					$Target = $Package.UninstallStringFilePath
					$Method = [PSADTNXT.Deployment.DeploymentMethod]::Setup
					$Criteria = [PSADTNXT.Application.NxtApplicationCriteria]::new([PSADTNXT.Application.ApplicationStore]::Package, $Package.GUID)
					if ($Package.PackageDirectory) {
						$uninstallFileBackupDirectory = [System.IO.Path]::Combine($Package.PackageDirectory.FullName, 'neo42-Source', $Package.GUID)
					}
					if (-not $PSBoundParameters.ContainsKey('LogFileName')) { $LogFileName = "$($Package.Name).$($adtEnvironment.DeploymentTimestamp)_Uninstall.log" }

					$null = $finalArguments.Insert(0, [PSADT.ProcessManagement.CommandLineUtilities]::ArgumentListToCommandLine($Package.UninstallStringArgumentList) + ' ')
					break
				}
				# Also applies to the 'Manual' set, if an application was resolved from the lookup criteria
				{ $_ -like 'Application*' -or $Application } {
					# Only resolve the target from the application, if none was specified
					[System.String[]]$applicationArgumentList = @()
					if ($PSCmdlet.ParameterSetName -like 'Application*' -or [System.String]::IsNullOrWhiteSpace($Target)) {
						if (-not $PSBoundParameters.ContainsKey('Method')) {
							$Method = if ($Application.WindowsInstaller) {
								[PSADTNXT.Deployment.DeploymentMethod]::MSI
							}
							elseif ($Application.Store -eq [PSADTNXT.Application.ApplicationStore]::AppX) {
								[PSADTNXT.Deployment.DeploymentMethod]::AppX
							}
							else {
								[PSADTNXT.Deployment.DeploymentMethod]::Setup
							}
						}

						if ($Method -in @([PSADTNXT.Deployment.DeploymentMethod]::MSI, [PSADTNXT.Deployment.DeploymentMethod]::AppX)) {
							$Target = $Application.PSChildName
						}
						elseif (-not [System.String]::IsNullOrWhiteSpace($Application.QuietUninstallStringFilePath)) {
							$Target = [PSADTNXT.Shell.NxtCommandLine]::SearchPath($Application.QuietUninstallStringFilePath, [System.EnvironmentVariableTarget]::Machine)
							$applicationArgumentList = $Application.QuietUninstallStringArgumentList
						}
						else {
							$Target = [PSADTNXT.Shell.NxtCommandLine]::SearchPath($Application.UninstallStringFilePath, [System.EnvironmentVariableTarget]::Machine)
							$applicationArgumentList = $Application.UninstallStringArgumentList
						}
					}
					if (-not $PSBoundParameters.ContainsKey('Criteria')) {
						$Criteria = [PSADTNXT.Application.NxtApplicationCriteria]::new($Application.Store, $Application.PSChildName)
					}
					if ($CacheDirectory) {
						$uninstallFileBackupDirectory = [System.IO.Path]::Combine($CacheDirectory.FullName, 'neo42-Source', $Application.PSChildName)
					}

					if (-not $PSBoundParameters.ContainsKey('ArgumentList')) {
						if ($adtConfig['NXT']['Deployment'][$Method.ToString()]) {
							$null = $finalArguments.Insert(0, $adtConfig['NXT']['Deployment'][$Method.ToString()]['UninstallParams'] + ' ')
						}
						elseif ($applicationArgumentList) {
							$null = $finalArguments.Insert(0, [PSADT.ProcessManagement.CommandLineUtilities]::ArgumentListToCommandLine($applicationArgumentList) + ' ')
						}
					}

					if (-not $PSBoundParameters.ContainsKey('LogFileName')) {
						$LogFileName = "$($Application.DisplayName).$($adtEnvironment.DeploymentTimestamp)_Uninstall.log"
					}
					break
				}
				{ $_ -like 'Manual*' } {
					if ([System.String]::IsNullOrWhiteSpace($Target)) {
						[System.Collections.Hashtable]$errorParams = @{
							Exception = [System.ArgumentException]::new('No target was specified and none could be resolved from the application lookup criteria.')
							Category  = [System.Management.Automation.ErrorCategory]::InvalidArgument
							ErrorId   = 'NoUninstallTarget'
						}
						throw (New-ADTErrorRecord @errorParams)
					}
					if (-not $PSBoundParameters.ContainsKey('ArgumentList') -and $adtConfig['NXT']['Deployment'][$Method.ToString()]) {
						$null = $finalArguments.Insert(0, $adtConfig['NXT']['Deployment'][$Method.ToString()]['UninstallParams'] + ' ')
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

			[System.Collections.Hashtable]$startSplat = Remove-ADTHashtableNullOrEmptyValues @{
				FilePath        = if (-not [System.IO.Path]::IsPathRooted($Target) -and $adtSession.DirFiles) { [System.IO.Path]::Combine($adtSession.DirFiles, $Target) } else { $Target }
				ArgumentList    = $finalArguments.ToString().Trim()
				PassThru        = $true
				IgnoreExitCodes = '*' # If not set in 4.1.8 the session exit code is set regardless of actual success of the result
				ErrorAction     = if ($IgnoreExitCodes) { [System.Management.Automation.ActionPreference]::Ignore } else { [System.Management.Automation.ActionPreference]::Stop }
			}
			if ($ExitOnProcessFailure) {
				$startSplat['ExitOnProcessFailure'] = $true
			}

			[System.String]$backupFileSelector = [System.String]::Empty
			[System.Collections.Generic.List[PSADTNXT.Deployment.INxtAwaiter]]$waits = [System.Collections.Generic.List[PSADTNXT.Deployment.INxtAwaiter]]::new()
			if ($Awaiter) { $waits.AddRange($Awaiter) }

			Write-ADTLogEntry -Message "Starting uninstallation process for target [$Target] with method [$Method]."
			switch ($Method) {
				([PSADTNXT.Deployment.DeploymentMethod]::Copy) {
					try {
						Remove-ADTFolder -Path $Target
						$result = [PSADT.ProcessManagement.ProcessResult]::new(0)
					}
					catch {
						if ($ExitOnProcessFailure) { Close-ADTSession -ExitCode $_.HResult }
						$result = [PSADT.ProcessManagement.ProcessResult]::new(
							$_.HResult,
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
						$result = [PSADT.ProcessManagement.ProcessResult]::new(0)
					}
					elseif ($identifiers.Length -gt 1) {
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
					$waits.Add([PSADTNXT.Deployment.NxtProcessAwaiter]::new('AU_', $false, [System.TimeSpan]::FromMinutes(10)))
					$waits.Add([PSADTNXT.Deployment.NxtProcessAwaiter]::new('Un_A', $false, [System.TimeSpan]::FromMinutes(10)))
					$waits.Add([PSADTNXT.Deployment.NxtProcessAwaiter]::new('Un', $false, [System.TimeSpan]::FromMinutes(10)))
				}
				([PSADTNXT.Deployment.DeploymentMethod]::BitRockInstaller) {
					$backupFileSelector = 'unins*.exe'
					$waits.Add([PSADTNXT.Deployment.NxtProcessAwaiter]::new('_Uninstall*', $false, [System.TimeSpan]::FromMinutes(10)))
				}
				# The default uninstall method for every uninstaller if no result is available yet.
				{ -not $result } {
					# Try to retrieve the backup file path if the uninstaller file does not exist
					if (-not [System.IO.File]::Exists($startSplat['FilePath'])) {
						Write-ADTLogEntry -Severity Warning -Message "The original uninstaller file [$($startSplat['FilePath'])] does not exist. Trying to use the backup uninstaller file."

						if (-not $NoCache -and
							-not [System.String]::IsNullOrWhiteSpace($backupFileSelector) -and
							$uninstallFileBackupDirectory
						) {
							Write-ADTLogEntry -Message 'Searching for the backup uninstaller file in the cache directory.' -DebugMessage
							[System.String]$backupFullPathSelector = [System.IO.Path]::Combine($uninstallFileBackupDirectory.FullName, $backupFileSelector)
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
					$startSplat['WindowStyle'] = [System.Diagnostics.ProcessWindowStyle]::Hidden
					$result = Start-ADTProcess @startSplat
				}
				([PSADTNXT.Deployment.DeploymentMethod]::AppX) {
					# Only run, if the package family was found
					if ($identifiers.Length -eq 1) {
						try {
							Write-ADTLogEntry -Message "Removing all user instances of the AppX package family [$Target]."
							Remove-AppxPackage -AllUsers -Package $identifiers[0]
						}
						catch {
							if ($ExitOnProcessFailure) { Close-ADTSession -ExitCode $_.HResult }
							$result = [PSADT.ProcessManagement.ProcessResult]::new(
								$_.HResult,
								[System.Collections.Generic.List[System.String]]::new().AsReadOnly(),
								[System.Collections.Generic.List[System.String]]::new([System.String[]]@($_.Exception.Message)).AsReadOnly(),
								[System.Collections.Generic.List[System.String]]::new([System.String[]]@($_.Exception.Message)).AsReadOnly()
							)
						}
					}
				}
			}

			if (-not $IgnoreExitCodes) {
				Update-NXTDeploymentStatus -ExitCode $result.ExitCode -SuccessExitCodes $SuccessExitCodes -RebootExitCodes $RebootExitCodes
			}

			Wait-NXTDeploymentAwaiter -Awaiter $waits

			# Validate that the application has been removed
			if ($Criteria) {
				[System.DateTime]$endTime = [System.DateTime]::Now.AddSeconds(5)
				while (([PSADT.Types.InstalledApplication[]]$remainingApplications = @(Get-NXTApplication -Criteria $Criteria))) {
					if ($endTime -lt [System.DateTime]::Now) { break }
					Start-Sleep -Milliseconds 500
				}
				if ($remainingApplications.Length -gt 0) {
					[System.Collections.Hashtable]$errorParams = @{
						Exception    = [System.InvalidOperationException]::new("Application criteria was provided but [$($remainingApplications.Length)] applications were still found 10s after uninstallation. Must be [0].")
						Category     = [System.Management.Automation.ErrorCategory]::InvalidResult
						ErrorId      = 'ApplicationStillInstalled'
						TargetObject = $Criteria
					}
					throw (New-ADTErrorRecord @errorParams)
				}
			}

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
