using System;
using System.IO;
using PSADTNXT.Package;

namespace PSADTNXT.Deployment
{
	public sealed record NxtPackageMetadata
	{
#pragma warning disable CA1720
		public string GUID { get; }
#pragma warning restore CA1720

		public string DisplayName { get; }

		public DirectoryInfo Directory { get; }

		public DirectoryInfo RootDirectory { get; }

		public string RegistryKey { get; }

		public bool UninstallOld { get; set; }

		public bool Register { get; set; }

		public ArpRegistrationType ApplicationEntry { get; set; }

		internal NxtPackageMetadata(
			Guid guid,
			string displayName,
			DirectoryInfo directory,
			DirectoryInfo rootDirectory,
			string registryName,
			bool uninstallOld,
			ArpRegistrationType applicationEntryType,
			bool register = true
		)
		{
			GUID = guid.ToString("B").ToUpper();
			DisplayName = displayName;
			Directory = directory;
			RootDirectory = rootDirectory;
			RegistryKey = $"SOFTWARE\\{registryName}\\{GUID}";
			UninstallOld = uninstallOld;
			ApplicationEntry = applicationEntryType;
			Register = register;
		}

		public override string ToString()
		{
			return $"{DisplayName} ({GUID})";
		}

		public NxtRegisteredPackage? GetRegisteredPackage()
		{
			return NxtRegisteredPackage.TryGetPackage(RegistryKey, out var registeredPackage) ? registeredPackage : null;
		}
	}
}
