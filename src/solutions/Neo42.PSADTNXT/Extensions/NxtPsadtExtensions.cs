using System;
using System.Globalization;
using System.IO;
using System.Linq;
using Microsoft.Dism.Commands;
using Microsoft.Win32;
using PSADT.Types;
using PSADTNXT.Shell;

namespace PSADTNXT.Extensions
{
	public static class NxtPsadtExtensions
	{
		private const string PROVISIONED_PACKAGE_SUBKEY = @"SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Applications";

		/// <summary>
		/// Converts a <see cref="RegistryKey"/> to an <see cref="InstalledApplication"/> object.
		/// </summary>
		/// <param name="key">The uninstall registry key to convert. Must be a root key of an uninstall key.</param>
		/// <returns>An <see cref="InstalledApplication"/> object representing the uninstall key.</returns>
		/// <exception cref="ArgumentException"/>
		public static InstalledApplication ToInstalledApplication(this RegistryKey key)
		{
			if (!key.Name.Contains(@"\Microsoft\Windows\CurrentVersion\Uninstall\"))
			{
				throw new ArgumentException("Key path is not root of uninstall keys.");
			}

			var displayName = (string)key.GetValue("DisplayName", "");
			if (string.IsNullOrWhiteSpace(displayName))
			{
				throw new ArgumentException("Key does not contain a DisplayName value.");
			}

			var keyPath = key.ToPSProviderPath();
			var keyName = Path.GetFileName(keyPath);
			var keyParent = Path.GetDirectoryName(keyPath)!;
			var uninstallString = (string?)key.GetValue("UninstallString");
			var quietUninstallString = (string?)key.GetValue("QuietUninstallString");
			var windowsInstaller = Guid.TryParse(key.Name.Split('\\').Last(), out var productCode) &&
				(
					key.GetValue("WindowsInstaller", "0").ToString()!.Equals("1") ||
					uninstallString?.ToString().IndexOf("msiexec.exe", StringComparison.OrdinalIgnoreCase) >= 0 ||
					quietUninstallString?.ToString().IndexOf("msiexec.exe", StringComparison.OrdinalIgnoreCase) >= 0
				);

			DirectoryInfo? installSource = null;
			try
			{
				if (key.GetValue("InstallSource") is string installSourceValue && !string.IsNullOrWhiteSpace(installSourceValue))
				{
					installSource = new DirectoryInfo(installSourceValue.Trim('"'));
				}
			}
			catch
			{
			}

			DirectoryInfo? installLocation = null;
			try
			{
				if (key.GetValue("InstallLocation") is string installLocationValue && !string.IsNullOrWhiteSpace(installLocationValue))
				{
					installLocation = new DirectoryInfo(installLocationValue.Trim('"'));
				}
			}
			catch
			{
			}

			Uri? helpLink = null;
			try
			{
				if (key.GetValue("HelpLink") is string helpLinkValue && !string.IsNullOrWhiteSpace(helpLinkValue))
				{
					helpLink = new Uri(helpLinkValue.Trim('"'));
				}
			}
			catch
			{
			}

			return new InstalledApplication(
				keyPath,
				keyParent,
				keyName,
				windowsInstaller ? productCode : null,
				displayName,
				(string?)key.GetValue("DisplayVersion"),
				uninstallString,
				quietUninstallString,
				installSource,
				installLocation,
				key.GetValue("InstallDate") is string installDate && DateTime.TryParseExact(installDate, "yyyyMMdd", null, DateTimeStyles.None, out var parsedInstallDate) ? parsedInstallDate : null,
				(string?)key.GetValue("Publisher"),
				helpLink,
				key.GetValue("EstimatedSize") is int size ? (uint)size : null,
				key.GetValue("SystemComponent")?.ToString() == "1",
				windowsInstaller,
				key.View != RegistryView.Registry32 && Environment.Is64BitOperatingSystem
			);
		}

		/// <summary>
		/// Converts a <see cref="AppxPackageObject"/> to an <see cref="InstalledApplication"/> object.
		/// </summary>
		/// <param name="package">The provisioned package object to convert.</param>
		/// <returns>An <see cref="InstalledApplication"/> object representing the package object.</returns>
		/// <exception cref="ArgumentException"/>
		public static InstalledApplication ToInstalledApplication(AppxPackageObject package)
		{
			if (package is null)
			{
				throw new ArgumentNullException(nameof(package));
			}

			var keyParent = $"Microsoft.PowerShell.Core\\Registry::HKEY_LOCAL_MACHINE\\{PROVISIONED_PACKAGE_SUBKEY}";
			var keyPath = $"{keyParent}\\{package.PackageName}";
			var powershellPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), @"WindowsPowerShell\v1.0\powershell.exe");
			var manifestPath = Environment.ExpandEnvironmentVariables(package.InstallLocation);
			var rootDir = new DirectoryInfo(
				manifestPath.EndsWith("AppxBundleManifest.xml", StringComparison.OrdinalIgnoreCase)
					? Path.GetDirectoryName(Path.GetDirectoryName(manifestPath))!
					: Path.GetDirectoryName(manifestPath)!
			);

			return new InstalledApplication(
				$"Microsoft.PowerShell.Core\\Registry::{keyPath}",
				$"Microsoft.PowerShell.Core\\Registry::{keyParent}",
				package.PackageName,
				null,
				package.DisplayName,
				$"{package.MajorVersion}.{package.MinorVersion}.{package.Build}.{package.Revision}",
				$"{powershellPath} -Wi Hi -NoP -NonI -C \"Remove-AppxProvisionedPackage -Online -AllUsers -PackageName '{package.PackageName}' -ErrorAction Stop\"",
				null,
				null,
				rootDir,
				null,
				package.PublisherId,
				null,
				(uint)rootDir.GetSize(),
				false,
				false,
				package.Architecture is 9 or 11 or 12
			);
		}

		public static bool IsNullSoftInstaller(this InstalledApplication application)
		{
			return application.PSChildName.EndsWith("_is1");
		}

		public static bool IsBurnInstaller(this InstalledApplication application)
		{
			using var key = application.PSPath.ToRegistryKeyFromPSProviderPath();
			return key != null && key.GetValue("BundleProviderKey", null) is string providerKey && providerKey.Equals(application.PSChildName);
		}
	}
}
