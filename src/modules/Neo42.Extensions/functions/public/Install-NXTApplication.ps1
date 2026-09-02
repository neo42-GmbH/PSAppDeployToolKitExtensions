function Install-NXTApplication {
	<#
	.SYNOPSIS
	Installs an application based on the neo42 logic.
	.DESCRIPTION
	Contains all installer specific code to install and repair an application.
	.INPUTS
	System.IO.FileInfo - The path to the installer.
	.OUTPUTS
	PSADT.ProcessManagement.ProcessResult - The result of the installation process.
	.PARAMETER Target
	The path or other identifier of the installer.
	.PARAMETER ArgumentList
	The arguments to pass to the installer.
	This parameter will replace the default arguments of the defined Method.
	Be aware that arguments are automatically escaped to ensure that they are properly formatted for the process start.
	Manual escaping will be passed as a literal string to the process.
	.PARAMETER AdditionalArgumentList
	Additional arguments to pass to the installer. These are appended to ArgumentList.
	.PARAMETER Method
	The method to use for the installation.
	.PARAMETER LogFileName
	The path to the log file ending with a .log extension.
	This file will reside in the log directory of the ADT session.
	The resulting full path is available as %LogFile% in the ArgumentList.
	.PARAMETER Criteria
	An instance of NxtApplicationCriteria to search for the application. Is used for advanced scenarios like caching the uninstaller post installation.
	Usually not required, as the ADT session will provide a default instance.
	.PARAMETER CacheDirectory
	The directory where the package cache is located. This is used to store the uninstaller files if the NoCache parameter is not specified.
	.PARAMETER Awaiter
	Optional awaiter objects that should be evaluated post installation.
	.PARAMETER SuccessExitCodes
	The exit codes that indicate a successful installation. If the exit code of the process is in this list, the installation is considered successful.
	.PARAMETER RebootExitCodes
	The exit codes that indicate a reboot is required after the installation. If the exit code of the process is in this list, the installation is considered successful and a reboot is requested.
	.PARAMETER ExitOnProcessFailure
	Determines if the function should exit with an error if the process fails. If this parameter is specified, the deployment will be aborted.
	.PARAMETER IgnoreExitCodes
	Specifies that any exit code from the installation process should be ignored and treated as a success.
	.PARAMETER NoCache
	For specific methods a copy of the uninstaller will be created in the cache directory. Specify this parameter to skip this step.
	.EXAMPLE
	Install-NXTApplication -Target 'C:\Temp\test.msi' -ArgumentList '/quiet /norestart' -Method MSI

	Installs the application using the MSI method with the specified arguments.
	.EXAMPLE
	Install-NXTApplication -Target 'setup.exe' -Method Setup -AdditionalArgumentList '/silent' -LogFileName 'CustomInstall.log' -Criteria @{ Store = 'ARP'; Identifier = 'TestApp' }

	Installs the application using the Setup method with the specified additional arguments and a custom log file name. The criteria is used to find the installed application for caching purposes.
	#>
	[OutputType([PSADT.ProcessManagement.ProcessResult])]
	[CmdletBinding(DefaultParameterSetName = 'ExitCodes')]
	param (
		[Parameter(Position = 0, Mandatory)]
		[ValidateNotNullOrEmpty()]
		[Alias('Path', 'FilePath', 'FullName')]
		[System.String]
		$Target,
		[System.String[]]
		$ArgumentList,
		[System.String[]]
		$AdditionalArgumentList,
		[PSADTNXT.Deployment.DeploymentMethod]
		$Method = 'Setup',
		[ValidateNotNull()]
		[PSADTNXT.Application.NxtApplicationCriteria]
		$Criteria,
		[ValidateScript({ $_ -like '*.log' })]
		[PSDefaultValue(Value = 'ID.$deploymentTimestamp.log')]
		[System.String]
		$LogFileName,
		[ValidateScript({ [System.IO.Path]::IsPathRooted($_) })]
		[System.String]
		$CacheDirectory = (Get-ADTSession).NXT.Package.Directory,
		[PSADTNXT.Deployment.INxtAwaiter[]]
		$Awaiter,

		[Parameter(ParameterSetName = 'ExitCodes')]
		[System.Management.Automation.SwitchParameter]
		$ExitOnProcessFailure,
		[Parameter(ParameterSetName = 'ExitCodes')]
		[PSDefaultValue(Help = 'Defaults depend on the method and session configuration.')]
		[System.Int32[]]
		$SuccessExitCodes,
		[Parameter(ParameterSetName = 'ExitCodes')]
		[PSDefaultValue(Help = 'Defaults depend on the method and session configuration.')]
		[System.Int32[]]
		$RebootExitCodes,
		[Parameter(ParameterSetName = 'IgnoreExitCodes', Mandatory)]
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

			# Append the default arguments if no arguments were provided
			if (-not $PSBoundParameters.ContainsKey('ArgumentList') -and $adtConfig['NXT']['Deployment'][$Method.ToString()]) {
				$null = $finalArguments.Insert(0, $adtConfig['NXT']['Deployment'][$Method.ToString()][$(if ($adtSession.IsSilent()) { 'SilentParams' } else { 'InstallParams' })] + ' ')
			}

			# Generate a log file name if none was provided.
			if (-not $PSBoundParameters.ContainsKey('LogFileName')) {
				[System.String]$logId = $Target.Split(
					[System.Char[]]@([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar), [System.StringSplitOptions]::RemoveEmptyEntries
				)[-1]
				$LogFileName = "$logId.$($adtEnvironment.DeploymentTimestamp)_Install.log"
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
				FilePath             = if ([System.IO.Path]::IsPathRooted($Target)) { $Target } else { [System.IO.Path]::Combine($adtSession.DirFiles, $Target) }
				PassThru             = $true
				SuccessExitCodes     = $SuccessExitCodes
				RebootExitCodes      = $RebootExitCodes
				ExitOnProcessFailure = $ExitOnProcessFailure.ToBool()
				ArgumentList         = $finalArguments.ToString().Trim()
				ErrorAction          = if ($IgnoreExitCodes) { [System.Management.Automation.ActionPreference]::Ignore } else { [System.Management.Automation.ActionPreference]::Stop }
			}

			[System.IO.DirectoryInfo]$uninstallFileBackupDirectory = $null
			[System.Collections.Generic.List[System.IO.FileInfo]]$uninstallFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

			Write-ADTLogEntry -Message "Running installation process for target [$Target] with method [$Method]."
			switch ($Method) {
				([PSADTNXT.Deployment.DeploymentMethod]::Copy) {
					try {
						Copy-ADTFile -Path ([System.IO.Path]::Combine($adtSession.DirFiles, '*')) -Destination $Target -Recurse
					}
					catch {
						if ($ExitOnProcessFailure) {
							Write-ADTLogEntry -Severity Warning -Message "An error occurred while trying to copy the file [$Target]."
							Write-ADTLogEntry -Severity Warning -Message (Resolve-ADTErrorRecord -ErrorRecord $_)
							Close-ADTSession -ExitCode 1
						}
						elseif ($IgnoreExitCodes) {
							Write-ADTLogEntry -Severity Warning -Message "An error occurred while trying to copy the file [$Target], but the error is ignored."
							$result = [PSADT.ProcessManagement.ProcessResult]::new(
								0,
								[System.Collections.Generic.List[System.String]]::new().AsReadOnly(),
								[System.Collections.Generic.List[System.String]]::new([System.String[]]@($_.Exception.Message)).AsReadOnly(),
								[System.Collections.Generic.List[System.String]]::new([System.String[]]@($_.Exception.Message)).AsReadOnly()
							)
						}
						else {
							$result = [PSADT.ProcessManagement.ProcessResult]::new(
								1,
								[System.Collections.Generic.List[System.String]]::new().AsReadOnly(),
								[System.Collections.Generic.List[System.String]]::new([System.String[]]@($_.Exception.Message)).AsReadOnly(),
								[System.Collections.Generic.List[System.String]]::new([System.String[]]@($_.Exception.Message)).AsReadOnly()
							)
						}
					}
					break
				}
				([PSADTNXT.Deployment.DeploymentMethod]::MSI) {
					$result = Start-ADTMsiProcess @startSplat -Action Install -SkipMSIAlreadyInstalledCheck -NoDesktopRefresh -LogFileName ($LogFileName -replace '_Install\.log$', [System.String]::Empty)
					Wait-NXTDeploymentAwaiter -Awaiter $Awaiter
					break
				}
				([PSADTNXT.Deployment.DeploymentMethod]::AppX) {
					$startSplat['ArgumentList'] = "/Online /NoRestart /English /LogPath:`"$($logFile.FullName)`" /Add-ProvisionedAppxPackage /PackagePath:`"$($startSplat['FilePath'])`"" + $startSplat['ArgumentList']
					$startSplat['FilePath'] = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('System'), 'Dism.exe')
				}
				([PSADTNXT.Deployment.DeploymentMethod]::Burn) {
					$NoCache = $true
					$startSplat['ArgumentList'] = '/install ' + $startSplat['ArgumentList'] + ' /log "' + $logFile.FullName + '"'
				}
				([PSADTNXT.Deployment.DeploymentMethod]::Setup) {
					$NoCache = $true
				}
				([PSADTNXT.Deployment.DeploymentMethod]::InnoSetup) {
					$startSplat['ArgumentList'] = $startSplat['ArgumentList'] + " /LOG=`"$($logFile.FullName)`""
				}
				# The default install method for every installer. (Only one that 'Setup' uses)
				{ $true } {
					$result = Start-ADTProcess @startSplat
					Wait-NXTDeploymentAwaiter -Awaiter $Awaiter

					if (-not $NoCache -and
						-not [System.String]::IsNullOrWhiteSpace($CacheDirectory) -and
						$Criteria -and
						([PSADT.Types.InstalledApplication[]]$app = @(Get-NXTApplication -Criteria $Criteria)) -and
						$app.Length -eq 1 -and
						-not [System.String]::IsNullOrWhiteSpace($app[0].UninstallStringFilePath)
					) {
						$uninstallFiles.Add([PSADTNXT.Shell.NxtCommandLine]::SearchPath($app[0].UninstallStringFilePath, [System.EnvironmentVariableTarget]::Machine))
						$uninstallFileBackupDirectory = [System.IO.Path]::Combine($CacheDirectory, 'neo42-Source', $app[0].PSChildName)
					}
				}
				([PSADTNXT.Deployment.DeploymentMethod]::InnoSetup) {
					if ($uninstallFiles) {
						$uninstallFiles.AddRange([System.IO.FileInfo[]]@(Get-Item -Path "$($uninstallFiles[0].Directory.FullName)\unins[0-9][0-9][0-9].*" -ErrorAction 'SilentlyContinue'))
					}
				}
			}

			if (-not $NoCache -and $uninstallFiles.Count -gt 0 -and $uninstallFileBackupDirectory) {
				try {
					if (-not $uninstallFileBackupDirectory.Exists) { $uninstallFileBackupDirectory.Create() }
					Copy-Item -Path @($uninstallFiles.FullName | Select-Object -Unique) -Destination $uninstallFileBackupDirectory.FullName -Force
					Write-ADTLogEntry -Message 'Successfully copied the uninstaller files to the source directory.' -DebugMessage
				}
				catch {
					Write-ADTLogEntry -Severity Error -Message 'Could not copy the uninstaller files to the source directory.'
					Write-ADTLogEntry -Severity Error -Message (Resolve-ADTErrorRecord -ErrorRecord $_)
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
