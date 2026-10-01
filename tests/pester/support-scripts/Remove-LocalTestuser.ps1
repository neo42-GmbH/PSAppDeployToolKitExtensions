param(
	[Parameter(Mandatory)]
	[System.String]
	$Name
)

# Preparation
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[System.Int32]$ec = 0
[System.Boolean]$rv = $false

try {
	# Load user values
	$user = Get-LocalUser | Where-Object -FilterScript { $_.Name -eq $Name }

	# Remove user if existing
	if ($user) {
		# Load more user values
		$sid = $user.SID.Value
		$userprofile = Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $sid }

		# Unload user NTUSER.DAT from windows registry users hive
		if (Test-Path -Path "Registry::HKEY_USERS\$($sid)") { $null = & reg.exe unload "HKU\$($sid)" 2>&1 }

		# Remove user
		Remove-CimInstance -InputObject $userprofile
		Remove-LocalUser -SID $sid

		# Set return value
		$rv = $true
	}
}
catch {
	Write-Output ($_ | Out-String).Trim()
	$ec = 1
}
finally {
	[System.GC]::Collect()
	[System.GC]::WaitForPendingFinalizers()
	Write-Output $rv
	exit $ec
}
