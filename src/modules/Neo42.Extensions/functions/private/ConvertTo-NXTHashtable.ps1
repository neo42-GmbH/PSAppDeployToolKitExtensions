function ConvertTo-NXTHashtable {
	<#
	.SYNOPSIS
	Helper function to convert PSObject to a Hashtable.
	.NOTES
	Any member method of the input object is ignored and all properties become static values at the time of conversion.
	#>
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSNxtAvoidBaseTypes', '', Justification = 'We do not know the type of the input object, so we cannot use a more specific type.')]
	[OutputType([System.Collections.Hashtable])]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory, ValueFromPipeline)]
		[System.Management.Automation.PSObject[]]
		$InputObject,
		[System.UInt32]
		$Depth = 16
	)
	begin {
		Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		[System.Management.Automation.ScriptBlock]$convertToArrayList = {
			param (
				[System.Collections.IList]
				$InputObject
			)
			[System.Collections.ArrayList]$arrayList = [System.Collections.ArrayList]::new($InputObject.Count)
			$InputObject | & {
				process {
					if ($_ -is [PSCustomObject]) {
						$null = $arrayList.Add((ConvertTo-NXTHashtable -InputObject $_ -Depth ($Depth - 1)))
					}
					elseif ($_ -is [System.Collections.IList]) {
						$null = $arrayList.Add((& $convertToArrayList -InputObject $_))
					}
					else {
						$null = $arrayList.Add($_)
					}
				}
			}
			return $arrayList
		}
	}
	process {
		try {
			if ($Depth -le 0) { return }
			foreach ($obj in $InputObject) {
				[System.Collections.Hashtable]$hashtable = [System.Collections.Hashtable]::new([System.StringComparer]::OrdinalIgnoreCase)
				$obj.PSObject.Properties | & {
					process {
						if ($_.Value -is [PSCustomObject]) {
							$hashtable[$_.Name] = ConvertTo-NXTHashtable -InputObject $_.Value -Depth ($Depth - 1)
						}
						elseif ($_.Value -is [System.Collections.IList]) {
							$hashtable[$_.Name] = & $convertToArrayList -InputObject $_.Value
						}
						else {
							$hashtable[$_.Name] = $_.Value
						}
					}
				}
				$PSCmdlet.WriteObject($hashtable, $false)
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
