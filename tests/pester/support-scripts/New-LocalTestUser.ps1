[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Plain text password for a local test user on a test machine is no security issue')]
param(
	[Parameter(Mandatory)]
	[System.String]
	$Name,

	[System.Security.SecureString]
	$Password,

	[System.Management.Automation.SwitchParameter]
	$Force
)

# Preparation
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[System.Int32]$ec = 0
[System.String]$sid = [System.String]::Empty

try {
	# Set default password
	if (-not $Password) { $Password = ConvertTo-SecureString -String 'Test1234' -Force -AsPlainText }

	# Load user values
	$user = Get-LocalUser | Where-Object -FilterScript { $_.Name -eq $Name }

	# Remove user if already existing and force switch is enabled
	if ($user -and $Force) {
		# Load more user values
		$sid = $user.SID.Value
		$userprofile = Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $sid }

		# Unload user NTUSER.DAT from windows registry users hive
		if (Test-Path -Path "Registry::HKEY_USERS\$($sid)") { $null = & reg.exe unload "HKU\$($sid)" 2>&1 }

		# Remove user
		Remove-CimInstance -InputObject $userprofile
		Remove-LocalUser -SID $sid
	}

	# Create new user
	if (($null -eq $user) -or ($user -and $Force)) {
		# Create user (for evaluation)
		$null = New-LocalUser `
			-Name $Name `
			-Password $Password `
			-PasswordNeverExpires `
			-UserMayNotChangePassword `
			-Description 'Test user with created profile'

		# Load user values
		$user = Get-LocalUser | Where-Object -FilterScript { $_.Name -eq $Name }
		$sid = $user.SID.Value

		# Create user via API to generate user profile directory and registry (NTUSER.dat)
		Add-Type -TypeDefinition @'
			using System;
			using System.Runtime.InteropServices;
			using System.Text;

			public static class Profile {
				[DllImport("userenv.dll", CharSet = CharSet.Unicode)]
				public static extern int CreateProfile(
					string sid,
					string userName,
					StringBuilder profilePath,
					uint profilePathSize
				);
			}
'@

		$profilePathSb = [System.Text.StringBuilder]::new(260)
		$result = [Profile]::CreateProfile(
			$sid,
			$Name,
			$profilePathSb,
			$profilePathSb.Capacity
		)

		if ($result -ne 0) {
			throw "User profile creation failed (Exit code: $($result))"
		}
	}

	# Load user values
	$user = Get-LocalUser | Where-Object -FilterScript { $_.Name -eq $Name }
	$sid = $user.SID.Value

	# Load registry hive
	if (-not (Test-Path -Path "Registry::HKEY_USERS\$($sid)")) {
		# Load more user values
		$userprofile = Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $sid }
		$profilePath = $userprofile.LocalPath

		# Load user NTUSER.DAT to windows registry users hive
		$ntUserDat = Join-Path $profilePath 'NTUSER.DAT'
		$null = & reg.exe load "HKU\$($sid)" $ntUserDat
		$lastEC = $LASTEXITCODE
		if ($lastEC -ne 0) { throw "Registry hive load failed (Exit code: $($lastEC))." }
	}
}
catch {
	Write-Output ($_ | Out-String).Trim()
	$ec = 1
}
finally {
	[System.GC]::Collect()
	[System.GC]::WaitForPendingFinalizers()
	Write-Output $sid
	exit $ec
}
