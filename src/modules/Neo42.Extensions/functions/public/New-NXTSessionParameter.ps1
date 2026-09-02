function New-NXTSessionParameter {
	<#
	.SYNOPSIS
	Retrieves the parameters for the the Open-ADTSession function.
	.DESCRIPTION
	Collects all required parameters for the Open-ADTSession function and returns them as a dictionary for use with Open-ADTSession.
	.OUTPUTS
	System.Collections.Generic.Dictionary[System.String, System.Object] - The parameters for the Open-ADTSession function.
	.PARAMETER Invocation
	The invocation of the deploy script to retrieve the parameters from.
	.PARAMETER ScriptDirectory
	The directory from which all source files are read. Defaults to the invocation script location.
	.PARAMETER SetupCfg
	A list of paths to Setup.cfg files to load and merge for the session.
	.EXAMPLE
	Get-NXTSessionParameter -Invocation $MyInvocation

	Retrieves the parameters for the Open-ADTSession function from the current invocation.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleTypes', '', Justification = 'PSCmdlet is compatible.')]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Nested functions will handle ShouldProcess.')]
	[CmdletBinding(SupportsShouldProcess)]
	[OutputType([System.Collections.Hashtable])]
	param (
		[Parameter(Mandatory)]
		[ValidateScript({ $_.MyCommand.CommandType -eq [System.Management.Automation.CommandTypes]::ExternalScript })]
		[System.Management.Automation.InvocationInfo]
		$Invocation,
		[ValidateScript({ $_.Exists })]
		[System.IO.DirectoryInfo]
		$ScriptDirectory = [System.IO.Path]::GetDirectoryName($Invocation.MyCommand.Definition),
		[ValidateScript({ $_.Exists -and $_.Extension -eq '.cfg' })]
		[PSDefaultValue(Value = 'Setup.cfg, CustomSetup.cfg')]
		[System.IO.FileInfo[]]
		$SetupCfg = $([System.String[]]@("$($ScriptDirectory.FullName)\Setup.cfg", "$($ScriptDirectory.FullName)\CustomSetup.cfg" | & { process { if ([System.IO.File]::Exists($_)) { $_ } } }))
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			# Create the root setup cfg from the module default and merge any provided setup cfg files on top of it
			[PSADTNXT.Configuration.NxtIniDocument]$setupCfgObj = Import-NXTSetupCfg -Path $SetupCfg

			# Load the package configuration
			[PSADTNXT.Deployment.Configuration.NxtPackageConfigurationModel]$packageConfig = Import-NXTPackageConfig -ScriptDirectory $ScriptDirectory -SetupCfg $setupCfgObj

			# Determine multiple use parameters before constructing the hashtable
			[PSADTNXT.Deployment.NxtDeploymentType]$nxtDeploymentType = if ($Invocation.BoundParameters.ContainsKey('DeploymentType')) { $Invocation.BoundParameters['DeploymentType'] } else { [PSADTNXT.Deployment.NxtDeploymentType]::Install }
			[System.String]$installName = [PSADTNXT.Extensions.NxtStringExtensions]::ToFileNameCompatible(
				[System.String]::Join('_',
					@(
						$packageConfig.Package.Vendor,
						$packageConfig.Package.Name,
						$packageConfig.Package.Version,
						$packageConfig.Package.Build,
						$packageConfig.Package.Architecture,
						$packageConfig.Package.Language
					)
				),
				$true,
				'_'
			)

			# Construct the hashtable with all parameters for the session, removing any null or empty values for cleanliness
			[System.Collections.Hashtable]$params = @{
				# App-specific parameters
				AppVendor                   = $packageConfig.Package.Vendor
				AppName                     = $packageConfig.Package.Name
				AppVersion                  = $packageConfig.Package.Version
				AppArch                     = $packageConfig.Package.Architecture
				AppLang                     = $packageConfig.Package.Language
				AppRevision                 = $packageConfig.Package.Revision
				AppScriptVersion            = $packageConfig.Package.Version
				AppScriptDate               = if (-not [System.String]::IsNullOrWhiteSpace($packageConfig.Package.CreationDate)) { [System.DateTime]::Parse($packageConfig.Package.CreationDate) } else { $null }
				AppScriptAuthor             = $packageConfig.Package.Author
				AppSuccessExitCodes         = @(0)
				AppRebootExitCodes          = @(3010)
				AppProcessesToClose         = @($packageConfig.CloseProcesses | & { process { if ($_) { [PSADT.ProcessManagement.ProcessDefinition]::new($_.Name, $_.Description) } } })

				# External PSADT parameters
				DeploymentType              = $nxtDeploymentType -as [PSADT.Module.DeploymentType]
				DeployMode                  = if ($Invocation.BoundParameters.ContainsKey('DeployMode')) { [PSADT.Module.DeployMode]$Invocation.BoundParameters['DeployMode'] } else { [PSADT.Module.DeployMode]::Auto }
				SuppressRebootPassThru      = if ($Invocation.BoundParameters.ContainsKey('SuppressRebootPassThru')) { $Invocation.BoundParameters['SuppressRebootPassThru'] } else { $false }
				TerminalServerMode          = if ($Invocation.BoundParameters.ContainsKey('TerminalServerMode')) { $Invocation.BoundParameters['TerminalServerMode'] } else { $false }
				DisableLogging              = if ($Invocation.BoundParameters.ContainsKey('DisableLogging')) { $Invocation.BoundParameters['DisableLogging'] } else { $false }
				AllowWowProcess             = $false

				# PSADT behavior parameters
				RequireAdmin                = $nxtDeploymentType.IsMachinePart
				DirFiles                    = if ([System.IO.Directory]::Exists("$($ScriptDirectory.FullName)\Files")) { "$($ScriptDirectory.FullName)\Files" } else { [System.String]::Empty }
				DirSupportFiles             = if ($nxtDeploymentType.IsUserPart -and [System.IO.Directory]::Exists("$($ScriptDirectory.FullName)\SupportFiles\User")) { "$($ScriptDirectory.FullName)\SupportFiles\User" } else { [System.String]::Empty }

				# Extension-specific PSADT parameters
				InstallTitle                = [System.String]::Join(' ', @($packageConfig.Package.Vendor, $packageConfig.Package.Name)).Replace('_', ' ').Trim()
				InstallName                 = $installName
				LogName                     = "${nxtDeploymentType}_${installName}_$(if ($nxtDeploymentType.IsUserPart) { "UserPart_$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1])" } else { 'MachinePart' }).log"
				DeployAppScriptVersion      = $PSCmdlet.MyInvocation.MyCommand.Module.Version
				DeployAppScriptFriendlyName = $PSCmdlet.MyInvocation.MyCommand.Module.Name
				DeployAppScriptParameters   = $Invocation.BoundParameters
				SessionClass                = [PSADTNXT.Foundation.NxtDeploymentSession]

				# External NXT parameters
				DeploymentSystem            = if ($Invocation.BoundParameters.ContainsKey('DeploymentSystem')) { $Invocation.BoundParameters['DeploymentSystem'] } else { Get-NXTDeploymentSystem }
				DeployAppScriptPath         = $Invocation.MyCommand.Definition
				PackageConfig               = $packageConfig
				SetupCfg                    = $setupCfgObj
				NxtDeploymentType           = $nxtDeploymentType
			}

			return (Remove-ADTHashtableNullOrEmptyValues -Hashtable $params)
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
