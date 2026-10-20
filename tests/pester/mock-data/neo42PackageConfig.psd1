@{
	ConfigVersion = '2025.12.01.0'
	Package       = @{
		GUID    = '{42000000-0000-0000-0000-000000000000}'
		Vendor  = 'neo42'
		Name    = 'Pester Mock Package'
		Version = '1.0'
	}
	Detection     = @{
		Enabled           = $true
		UsePackageVersion = $true
		Criteria          = @{
			Store      = 'ARP64'
			Identifier = '{00000000-0000-0000-0000-000000000042}'
		}
	}
	Deployment    = @{
		Installation   = @{
			Method    = 'Setup'
			Target    = "$envSystemX64\cmd.exe"
			Arguments = '/c ' +
			'reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{00000000-0000-0000-0000-000000000042}" /v DisplayName /t REG_SZ /d "Pester Mock Package" /f /reg:64 && ' +
			'reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{00000000-0000-0000-0000-000000000042}" /v DisplayVersion /t REG_SZ /d "1.0" /f /reg:64 && ' +
			'reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{00000000-0000-0000-0000-000000000042}" /v UninstallString /t REG_SZ  /f /reg:64 /d ' +
			'"\"%SystemRoot%\System32\reg.exe\" delete \"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{00000000-0000-0000-0000-000000000042}\" /f /reg:64"'
		}
		Uninstallation = @{
			Method    = 'Setup'
			Target    = "$envSystemX64\cmd.exe"
			Arguments = '/c reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{00000000-0000-0000-0000-000000000042}" /f /reg:64'
		}
	}
}
