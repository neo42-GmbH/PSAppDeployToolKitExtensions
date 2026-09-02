function Get-NXTCommandTable {
	<#
	.SYNOPSIS
	Retrieves the NXT command table of this module.
	.DESCRIPTION
	This command table includes the base PSADT command table and functions from the current module.
	#>
	[OutputType([System.Collections.ObjectModel.ReadOnlyDictionary[System.String, System.Management.Automation.CommandInfo]])]
	param()

	return $script:CommandTable.Keys | & {
		begin {
			[System.Collections.Generic.Dictionary[System.String, System.Management.Automation.CommandInfo]]$output = [System.Collections.Generic.Dictionary[System.String, System.Management.Automation.CommandInfo]]::new()
		}
		process {
			if ($_ -notlike '*-NXT*' -or $_ -in $args[0].ExportedCommands.Keys) {
				$output.Add($_, $script:CommandTable[$_])
			}
		}
		end {
			[System.Collections.ObjectModel.ReadOnlyDictionary[System.String, System.Management.Automation.CommandInfo]]::new($output)
		}
	} $MyInvocation.MyCommand.Module
}
