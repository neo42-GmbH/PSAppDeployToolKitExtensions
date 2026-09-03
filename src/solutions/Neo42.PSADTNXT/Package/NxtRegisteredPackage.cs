using System;
using Microsoft.Win32;
using System.IO;
using System.Linq;
using PSADTNXT.Shell;
using PSADTNXT.Extensions;
using System.Collections.Generic;
using PSADT.Types;

namespace PSADTNXT.Package
{
	/// <summary>
	/// Represents a registered application in the NXT environment. Translates a key name and package GUID to a registry key.
	/// Provides information about the registered application, such as its name, version, and installation status.
	/// </summary>
	public sealed class NxtRegisteredPackage
	{
		/// <summary>
		/// The PSPath of the registered package.
		/// </summary>
		public string PSPath { get; }

		/// <summary>
		/// The PSPath of the parent path of the registered package.
		/// </summary>
		public string PSParentPath { get; }

		/// <summary>
		/// The child name of the registered package.
		/// </summary>
		public string PSChildName { get; }

		/// <summary>
		/// The registry subkey name for the registered package.
		/// </summary>
		public string RegistryName { get; }

		/// <summary>
		/// The GUID of the package.
		/// </summary>
		public string Id { get; }

		/// <summary>
		/// The name of the registered application.
		/// </summary>
		public string? Name { get; }

		/// <summary>
		/// The name of the developer of the registered application.
		/// </summary>
		public string? Developer { get; }

		/// <summary>
		/// The uninstall string of the registered application.
		/// </summary>
		public string? UninstallString { get; }

		/// <summary>
		/// A boolean value indicating whether the associated application is installed.
		/// </summary>
		public bool IsInstalled { get; }

		/// <summary>
		/// The path to the package directory this package was originally registered to.
		/// </summary>
		public DirectoryInfo? PackageDirectory { get; }

		/// <summary>
		/// The date the package was registered.
		/// </summary>
		public DateTime? RegistrationDate { get; }

		/// <summary>
		/// A boolean value indicating whether the package has been soft migrated.
		/// </summary>
		public bool? SoftMigrated { get; }

		/// <summary>
		/// The version of the package when it was registered.
		/// </summary>
		public Version? Version { get; }

		/// <summary>
		/// The revision of the package when it was registered.
		/// </summary>
		public uint? Revision { get; }

		/// <summary>
		/// The installed application object this registered application is associated with.
		/// </summary>
		/// <remarks>
		/// This property is null if the application is not installed.
		/// </remarks>
		public InstalledApplication? InstalledApplication { get; }

		private NxtRegisteredPackage(RegistryKey packageKey)
		{
			var keyNameParts = packageKey.Name.Split(['\\'], StringSplitOptions.RemoveEmptyEntries);
			var is64Bit = Environment.Is64BitOperatingSystem && packageKey.View != RegistryView.Registry32;
			var wow6432Node = is64Bit ? string.Empty : "Wow6432Node\\";

			RegistryName = keyNameParts[keyNameParts.Length - 2];
			Id = keyNameParts.Last();

			PSChildName = keyNameParts.Last();
			PSParentPath = $"Microsoft.PowerShell.Core\\Registry::HKEY_LOCAL_MACHINE\\SOFTWARE\\{wow6432Node}{RegistryName}";
			PSPath = Path.Combine(PSParentPath, PSChildName);

			using var baseKey = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, is64Bit ? RegistryView.Registry64 : RegistryView.Registry32);
			using var installedKey = baseKey.OpenSubKey($"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\{PSChildName}");
			IsInstalled = installedKey != null;
			InstalledApplication = installedKey?.ToInstalledApplication();
			Name = packageKey.GetValue("ProductName")?.ToString();
			Developer = packageKey.GetValue("DeveloperName")?.ToString();
			PackageDirectory = packageKey.GetValue("AppPath") is string packageDirectory ? new DirectoryInfo(packageDirectory) : null;
			RegistrationDate = packageKey.GetValue("Date") is string registrationDate ? DateTime.Parse(registrationDate) : null;
			SoftMigrated = packageKey.GetValue("SoftMigrationOccured")?.ToString() == "1";
			Version = packageKey.GetValue("Version") is string version ? new Version(version) : null;
			Revision = uint.TryParse(packageKey.GetValue("Revision")?.ToString(), out var rev) ? rev : null;
			UninstallString = packageKey.GetValue("UninstallString")?.ToString();
		}

		public override string ToString()
		{
			return $"Registered Package: {Developer} {Name} (Version: {Version}, Publisher: {Developer}, Guid: {PSChildName})";
		}

		/// <summary>
		/// Gets all registered packages in under any package key.
		/// </summary>
		/// <returns>An array of registered packages for the given packages.</returns>
		public static IEnumerable<NxtRegisteredPackage> GetPackages()
		{
			foreach (var view in NxtRegistryExtensions.GetAllViews())
			{
				using var rootKey = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, view);
				using var uninstallKey = rootKey.OpenSubKey("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall");
				if (uninstallKey == null)
				{
					continue;
				}

				foreach (var productCode in uninstallKey.GetSubKeyNames())
				{
					if (Guid.TryParse(productCode, out _))
					{
						using var applicationKey = uninstallKey.OpenSubKey(productCode);
						if (applicationKey?.GetValue("neoRegPackagesKeyRef") is string packageReference
							&& TryGetPackage($"SOFTWARE\\{packageReference}", out var package)
							)
						{
							yield return package!;
						}
					}
				}
			}
		}

		/// <summary>
		/// Gets a registered package for a given package base key and package GUID.
		/// </summary>
		/// <param name="packagePath">The package subkey path to search.</param>
		/// <param name="package">The registered package if found; otherwise, null.</param>
		/// <returns>The registered package for the given package base key and package GUID, or null if not found.</returns>
		public static bool TryGetPackage(string packagePath, out NxtRegisteredPackage? package)
		{
			if (!packagePath.StartsWith(@"SOFTWARE\", StringComparison.OrdinalIgnoreCase)) // Older iterations did not have the leading SOFTWARE node in their ref
			{
				packagePath = @"SOFTWARE\" + packagePath;
			}

			using var baseKey = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry64);
			using var packageKey = baseKey.OpenSubKey(packagePath);
			package = packageKey != null ? new NxtRegisteredPackage(packageKey) : null;
			return package != null;
		}

		/// <summary>
		/// Tries to resolve a <see cref="NxtRegisteredPackage"/> from an <see cref="InstalledApplication"/>.
		/// </summary>
		public static bool TryGetPackage(InstalledApplication application, out NxtRegisteredPackage? package)
		{
			package = null;
			if (application.PSPath.ToRegistryKeyFromPSProviderPath() is RegistryKey appKey
				&& appKey.GetValue("neoRegPackagesKeyRef") is string keyRef
				&& TryGetPackage(keyRef, out var packageObj))
			{
				package = packageObj;
			}
			return package != null;
		}
	}
}
