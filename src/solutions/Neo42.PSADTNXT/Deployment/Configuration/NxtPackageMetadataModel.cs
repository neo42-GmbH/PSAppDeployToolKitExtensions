using System.ComponentModel.DataAnnotations;
using PSADTNXT.ComponentModel.DataAnnotations;
using PSADTNXT.Package;

namespace PSADTNXT.Deployment.Configuration
{
	public sealed record NxtPackageMetadataModel
	{
		[Required]
		[ValidGuid]
#pragma warning disable CA1720
		public string GUID { get; set; } = null!;
#pragma warning restore CA1720

		[Required]
		[ValidFileName]
		[ValidRegistryPath(Root = ValidPathRoot.NotRooted)]
		public string Name { get; set; } = null!;

		[Required]
		[ValidFileName]
		[ValidRegistryPath(Root = ValidPathRoot.NotRooted)]
		public string Vendor { get; set; } = null!;

		[Required]
		[ValidVersion]
		public string Version { get; set; } = null!;

		public PackageArchitecture Architecture { get; set; } = PackageArchitecture.neutral;

		[Required]
		public string Language { get; set; } = "MUI";

		[Required]
		[ValidFileName]
		[ValidRegistryPath(Root = ValidPathRoot.NotRooted)]
		public string KeyName { get; set; } = "neoPackages";

		[Required]
		[ValidFileName]
		public string DirectoryName { get; set; } = "neo42Pkgs";

		public string? DisplayName { get; set; }

		public ArpRegistrationType ApplicationEntry { get; set; } = ArpRegistrationType.Uninstallable;

		public string? Description { get; set; }

		public string? Author { get; set; }

		public uint Revision { get; set; }

		public uint Build { get; set; }

		public string? UpdateDate { get; set; }

		public string? CreationDate { get; set; }

		public string? TestedOn { get; set; }

		public string? InventoryId { get; set; }

		public string? Dependencies { get; set; }

		public bool UninstallOld { get; set; }
	}
}
