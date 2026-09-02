function ConvertTo-NXTPsArgumentString {
	<#
	.SYNOPSIS
	Converts a dictionary object to an argument list.
	.DESCRIPTION
	Converts a dictionary object to an argument list. The dictionary keys are used as the parameter names and the values are used as the parameter values.
	Be aware that only types that can be converted from and to a string are supported.
	Additionally, switch and boolean values are supported.
	.INPUTS
	System.Collections.Hashtable - The dictionary object to convert.

	System.Management.Automation.InvocationInfo - The bound parameters of the current command.
	.OUTPUTS
	System.String - The argument list.
	.PARAMETER InputObject
	The dictionary object to convert. If the keys are integers, they will be treated as positional parameters, otherwise they will be treated as named parameters.
	.PARAMETER StringDelimiter
	The string delimiter to use if the string value contains tokens that need to be escaped.
	.PARAMETER StringDelimiterReplacement
	The replacement string for string delimiters within the string value.
	.PARAMETER UseEnumValue
	Use the enum value instead of the enum name.
	.EXAMPLE
	@{ 'Key1' = 'Value1'; 'Key2' = 'Value2' } | ConvertTo-NXTPsArgumentString

	Will return a argument string with named parameters: `-Key1 "Value1" -Key2 "Value2"`.
	.EXAMPLE
	@{ 1 = 'Value1'; 2 = 'Value2' } | ConvertTo-NXTPsArgumentString

	Will return a argument string with positional parameters: `"Value1" "Value2"`.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseLiteralInitializerForHashtable', '', Justification = 'We need a copy here.')]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Is used in scriptblock.')]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSNxtAvoidBaseTypes', '', Justification = 'We do not know the sub type in advance.')]
	[OutputType([System.String])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipeline)]
		[Alias('BoundParameters', 'PSBoundParameters', 'ArgumentList')]
		[System.Collections.Hashtable]
		$InputObject,
		[ValidateSet('"', '''')]
		[System.String]
		$StringDelimiter = '"',
		[PSDefaultValue(Value = 'StringDelimiter''s default escape replacement.')]
		[System.String]
		$StringDelimiterReplacement = $(if ($StringDelimiter -eq '"') { '`"' } else { "''" }),
		[System.Management.Automation.SwitchParameter]
		$UseEnumValue
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Management.Automation.ScriptBlock]$formatValue = {
			param (
				[Parameter(Mandatory)]
				[AllowNull()]
				[System.Object]
				$Value
			)
			if ($null -eq $Value) {
				return '$null'
			}
			elseif ($Value -is [System.Boolean] -or $Value -is [System.Management.Automation.SwitchParameter]) {
				return "`$$($Value.ToString().ToLower())"
			}
			elseif ($Value -is [System.DateTime]) {
				return "${StringDelimiter}$($Value.ToUniversalTime().ToString([System.Globalization.DateTimeFormatInfo]::InvariantInfo.UniversalSortableDateTimePattern))${StringDelimiter}"
			}
			elseif ($Value -is [System.Enum] -and $UseEnumValue) {
				return $Value.value__.ToString()
			}
			elseif ($Value -is [System.Management.Automation.ScriptBlock]) {
				return "{$Value}"
			}
			elseif ($Value.GetType() -in @([System.Int16], [System.Int32], [System.Int64], [System.UInt16], [System.UInt32], [System.UInt64], [System.Byte], [System.SByte], [System.Decimal], [System.Single], [System.Double])) {
				return $Value.ToString()
			}
			elseif ($Value -is [System.IO.FileSystemInfo]) {
				return "${StringDelimiter}$($Value.FullName)${StringDelimiter}"
			}
			elseif ($Value -is [System.Collections.IDictionary]) {
				return '@{' + [System.String]::Join(
					';',
					(
						$Value.GetEnumerator() | & {
							process {
								if ($_.Key.ToString().Contains($StringDelimiter) -or [PSADTNXT.Shell.NxtPowerShell]::ContainsEscapableCharacters($_.Key.ToString())) {
									"${StringDelimiter}$($_.Key.Replace($StringDelimiter, $StringDelimiterReplacement))${StringDelimiter}=$(& $formatValue -Value $_.Value)"
								}
								else {
									"$($_.Key)=$(& $formatValue -Value $_.Value)"
								}
							}
						}
					)
				) + '}'
			}
			elseif ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [System.String]) {
				return '@(' + [System.String]::Join(
					',',
					@($Value | & { process { & $formatValue -Value $_ } })
				) + ')'
			}
			else {
				return "${StringDelimiter}$($Value.ToString().Replace($StringDelimiter, $StringDelimiterReplacement))${StringDelimiter}"
			}
		}
	}
	process {
		try {
			[System.Collections.Hashtable]$workingTable = [System.Collections.Hashtable]::new($InputObject)
			[System.Text.StringBuilder]$arguments = [System.Text.StringBuilder]::new()
			[System.Object[]]$positionalParameters = @($workingTable.Keys | Where-Object { $_ -is [System.Int32] } | Sort-Object)

			# Validate that positional parameters are sequential starting from 0
			for ($i = 0; $i -lt $positionalParameters.Length; $i++) {
				if (-not $positionalParameters.Contains($i)) {
					throw "Invalid positional parameter index [$i]. Positional parameters must be sequential starting from 0."
				}
			}


			# Append positional parameters
			foreach ($index in $positionalParameters) {
				$null = $arguments.Append(' ')
				$null = $arguments.Append((& $formatValue -Value $workingTable[$index]))
				$null = $workingTable.Remove($index)
			}

			# Append named parameters
			foreach ($kvp in $workingTable.GetEnumerator()) {
				if ($kvp.Key.ToString().Contains(' ')) {
					throw "Invalid parameter name '$($kvp.Key)'. Parameter names cannot contain spaces."
				}
				$null = $arguments.Append(" -$($kvp.Key):")
				$null = $arguments.Append((& $formatValue $kvp.Value))
			}

			# Remove the leading space and return the argument string
			$null = $arguments.Remove(0, 1)
			return $arguments.ToString()
		}
		catch {
			Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
		}
	}
	end {
		Complete-ADTFunction -Cmdlet $PSCmdlet
	}
}
