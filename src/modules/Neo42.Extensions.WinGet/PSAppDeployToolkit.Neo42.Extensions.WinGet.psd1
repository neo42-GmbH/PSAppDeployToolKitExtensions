# Module manifest for module 'PSAppDeployToolkit.Neo42.Extensions'
#
# Generated on: 2024-12-10
#

@{
	# Script module or binary module file associated with this manifest.
	RootModule             = 'PSAppDeployToolkit.Neo42.Extensions.WinGet.psm1'

	# Version number of this module.
	ModuleVersion          = '0.0.0.0'

	# Supported PSEditions
	# CompatiblePSEditions = @()

	# ID used to uniquely identify this module
	GUID                   = '04230c4d-d72e-49bc-b481-ced77d984a8b'

	# Author of this module
	Author                 = 'neo42 GmbH'

	# Company or vendor of this module
	CompanyName            = 'neo42 GmbH'

	# Copyright statement for this module
	Copyright              = 'Copyright © 2026 neo42 GmbH. All rights reserved.'

	# Description of the functionality provided by this module
	Description            = 'Deployment system extension for neo42''S PSAppDeployToolkit extension.'

	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion      = '5.1.14393.0'

	# Name of the Windows PowerShell host required by this module
	# PowerShellHostName = ''

	# Minimum version of the Windows PowerShell host required by this module
	PowerShellHostVersion  = '5.1.14393.0'

	# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
	DotNetFrameworkVersion = '4.7.2.0'

	# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
	CLRVersion             = '4.0.30319.42000'

	# Processor architecture (None, X86, Amd64) required by this module
	ProcessorArchitecture  = 'None'

	# Modules that must be imported into the global environment prior to importing this module
	RequiredModules        = @(
		@{ ModuleName = 'PSAppDeployToolkit.Neo42.Extensions'; GUID = '042bb3b2-d0a5-40b1-8fde-f15727c951b9'; ModuleVersion = '0.0.0.0' }
	)

	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies     = @()

	# Script files (.ps1) that are run in the caller's environment prior to importing this module.
	# ScriptsToProcess       = @()

	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @()

	# Format files (.ps1xml) to be loaded when importing this module
	# FormatsToProcess = @()

	# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
	# NestedModules          = @()

	# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
	FunctionsToExport      = @()

	# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
	CmdletsToExport        = @()

	# Variables to export from this module
	VariablesToExport      = @()

	# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
	AliasesToExport        = @()

	# DSC resources to export from this module
	# DscResourcesToExport = @()

	# List of all modules packaged with this module
	# ModuleList             = @()

	# List of all files packaged with this module
	# FileList = @()

	# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData            = @{
		PSData = @{
			# Tags applied to this module. These help with module discovery in online galleries.
			Tags         = @(
				'psappdeploytoolkit',
				'adt',
				'psadt',
				'appdeployment',
				'appdeploytoolkit',
				'appdeploy',
				'deployment',
				'toolkit',
				'extension',
				'neo42'
			)

			# A URL to the license for this module.
			LicenseUri   = 'https://raw.githubusercontent.com/neo42-GmbH/PSAppDeployToolKitExtensions/refs/heads/production/COPYING.Lesser'

			# A URL to the main website for this project.
			ProjectUri   = 'https://github.com/neo42-GmbH/PSAppDeployToolKitExtensions'

			# A URL to an icon representing this module.
			IconUri      = 'https://raw.githubusercontent.com/neo42-GmbH/PSAppDeployToolKitExtensions/refs/heads/production/src/modules/Neo42.Extensions/files/Assets/Logo.png'

			# ReleaseNotes of this module
			ReleaseNotes = 'https://github.com/neo42-GmbH/PSAppDeployToolKitExtensions/releases/latest'

			# Prerelease tag for PSGallery.
			# Prerelease = ''
		}
	}

	# HelpInfo URI of this module
	HelpInfoURI            = 'https://portal.neo42.de/Help/66d825612756cd61dea8ba8c'

	# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
	# DefaultCommandPrefix = ''
}
