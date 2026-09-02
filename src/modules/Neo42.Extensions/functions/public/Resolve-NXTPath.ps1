function Resolve-NXTPath {
	<#
	.SYNOPSIS
	Resolves common PowerShell path parameters to their qualified full paths.
	.DESCRIPTION
	Resolves common PowerShell path parameters to their qualified full paths.
	It can take any object containing a `PSPath` that was retrieved via a PowerShell provider.
	This function imitates the behavior of the PowerShell internal LocationGlobber.
	.PARAMETER IncludeNonExistent
	Includes non-existent paths in the output.
	.PARAMETER AsProviderPath
	Returns the provider path instead of the fully qualified PSPath.
	This is useful when when you work with .NET objects that do not support provider paths.
	.PARAMETER ProviderName
	Will use the given provider to resolve the path. If not specified, the provider is determined from the path itself.
	It is recommended to specify the provider in order to limit the output to a specific provider.
	Specifying the provider will also enable to resolve provider paths. A useful example is the `Registry` provider
	.PARAMETER Path
	The path to resolve.
	.PARAMETER LiteralPath
	The literal path to resolve.
	.PARAMETER Filter
	A filter to apply to the resolved paths.
	.PARAMETER Exclude
	An array of patterns to exclude from the resolved paths.
	.PARAMETER Include
	An array of patterns to include in the resolved paths.
	.PARAMETER Force
	Forces the resolution of hidden or system items.
	.PARAMETER PathType
	Limits the output to the given path type.
	Useful for example to filter for files or directories.
	.EXAMPLE
	Resolve-NXTPath -Path "C:\Windows\System32\*" -Filter '*.exe' -Include 'cmd*'

	Returns all executable files in the System32 directory that start with 'cmd'.
	.EXAMPLE
	Resolve-NXTPath @PSBoundParameters -AsProviderPath

	Returns the provider paths of all bound parameters that match a PowerShell path parameter.
	.EXAMPLE
	Get-Item -Path "HKLM:\Software" | Resolve-NXTPath -AsProviderPath

	Returns the `HKEY_LOCAL_MACHINE\Software` provider path for the given item.
	.LINK
	https://github.com/PowerShell/PowerShell/blob/master/src/System.Management.Automation/namespaces/LocationGlobber.cs
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Variables are used in the process block')]
	[OutputType([System.String[]])]
	[CmdletBinding(DefaultParameterSetName = 'Path')]
	param (
		[System.Management.Automation.SwitchParameter]
		$IncludeNonExistent,
		[System.Management.Automation.SwitchParameter]
		$AsProviderPath,
		[System.String]
		$ProviderName,

		# Below parameters are the supported parameters that are used to resolve the path
		[Parameter(Position = 0, ParameterSetName = 'Path', Mandatory, ValueFromPipelineByPropertyName)]
		[SupportsWildcards()][ValidateNotNullOrEmpty()]
		[System.String[]]
		$Path,
		[Parameter(ParameterSetName = 'LiteralPath', Mandatory, ValueFromPipelineByPropertyName)]
		[Alias('PSPath')]
		[ValidateNotNullOrEmpty()]
		[System.String[]]
		$LiteralPath,
		[SupportsWildcards()]
		[System.String]
		$Filter,
		[SupportsWildcards()]
		[System.String[]]
		$Exclude,
		[SupportsWildcards()]
		[System.String[]]
		$Include,
		[System.Management.Automation.SwitchParameter]
		$Force,
		[Microsoft.PowerShell.Commands.TestPathType]
		$PathType = 'Any',

		[Parameter(DontShow, ValueFromRemainingArguments)]
		[AllowNull()][AllowEmptyCollection()]
		[System.Collections.Generic.List[System.Object]]
		$UnboundArguments
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}
	process {
		try {
			[System.Boolean]$isLiteralPath = $PSCmdlet.ParameterSetName -eq 'LiteralPath'
			$(if ($isLiteralPath) { $LiteralPath } else { $Path }) | & {
				process {
					# Determine the provider and the path. FileSystem is the default provider if no provider is specified.
					[System.Management.Automation.ProviderInfo]$providerInfo = $null
					[System.String]$providerPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($_, [ref]$providerInfo, [ref]$null)

					# Validate the provider
					if ($ProviderName) {
						[System.Management.Automation.ProviderInfo]$desiredProvider = $ExecutionContext.SessionState.Provider.GetOne($ProviderName)
						# If the path was not qualified with a provider, use the desired provider to resolve the path.
						if (-not $ExecutionContext.SessionState.Path.IsProviderQualified($_)) {
							$providerInfo = $desiredProvider
							$providerPath = $_
						}
						# If the provider is specified, but the path does not match the provider, throw an error.
						elseif (-not $providerInfo.Equals($desiredProvider)) {
							[System.Collections.Hashtable]$errorParams = @{
								Exception         = [System.Management.Automation.ProviderInvocationException]::new("Given path is not a valid path for the specified provider [$ProviderName].")
								Category          = [System.Management.Automation.ErrorCategory]::InvalidArgument
								ErrorId           = 'InvalidProviderPath'
								RecommendedAction = 'Ensure that the path is valid for the required provider.'
								TargetObject      = $_
							}
							throw (New-ADTErrorRecord @errorParams)
						}
					}

					# Try get the item by specifying the the qualified path and invoking the Item.Get method.
					[System.String]$qualifiedPath = "$($providerInfo.ModuleName)\$($providerInfo.Name)::$providerPath"

					$(
						try {
							[System.String[]]$items = $ExecutionContext.SessionState.InvokeProvider.Item.Get($qualifiedPath, $Force, $isLiteralPath) | & { process { $_.PSPath } }
							if (-not $items) {
								throw [System.Management.Automation.ItemNotFoundException]::new("The given path `"$_`" does not resolve to any item or is not a valid path.")
							}
							$items
						}
						catch [System.Management.Automation.ItemNotFoundException] {
							# Ignore issues with non-existent paths if the parameter is set and the path is not a wildcard or literal path.
							if ($IncludeNonExistent -and
								(
									$isLiteralPath -or
									-not [System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($qualifiedPath)
								)
							) {
								$qualifiedPath
							}
							# If the path contains wildcard resolution it should not throw an error.
							elseif (-not $IncludeNonExistent -and
								(
									$isLiteralPath -or
									-not [System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($qualifiedPath)
								)
							) {
								[System.Collections.Hashtable]$errorParams = @{
									Exception    = $_.Exception
									Category     = [System.Management.Automation.ErrorCategory]::ResourceUnavailable
									ErrorId      = 'ItemNotFound'
									TargetObject = $qualifiedPath
								}
								throw (New-ADTErrorRecord @errorParams)
							}
						}
					) | & {
						# Filter the items based on the path type, filter, exclude, and include parameters.
						process {
							# Filter out items that do not match the specified path type.
							if ($PathType -ne [Microsoft.PowerShell.Commands.TestPathType]::Any -and
								$ExecutionContext.SessionState.InvokeProvider.Item.Exists($_) -and
								$ExecutionContext.SessionState.InvokeProvider.Item.IsContainer($_) -ne ($PathType -eq [Microsoft.PowerShell.Commands.TestPathType]::Container)
							) { return }

							# Filter out items that do not match the specified filter, exclude, or include parameters.
							[System.String]$pathLeaf = $ExecutionContext.SessionState.Path.ParseChildName($_)
							if (($Filter -and $pathLeaf -notlike $Filter) -or
								($Exclude -and $true -in ($Exclude | & { process { $pathLeaf -like $_ } })) -or
								($Include -and $true -notin ($Include | & { process { $pathLeaf -like $_ } }))
							) { return }

							# Return as the desired path format.
							if ($AsProviderPath) { $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($_) } else { $_ }
						}
					}
				}
			}
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
