using PSADT.Types;
using PSADTNXT.Application;

namespace PSADTNXT.Deployment
{
	public sealed record NxtInstallationDetection
	{
		public bool Enabled { get; set; }

		public NxtApplicationCriteria? Criteria { get; set; }

		public NxtVersion? TargetVersion { get; set; }

		public bool IsInstalled { get; set; }

		public VersionCompareResult VersionStatus { get; set; } = VersionCompareResult.Equal;

		public InstalledApplication? Application { get; set; }

		internal NxtInstallationDetection()
		{
		}

		public override string ToString()
		{
			return !Enabled
				? "Installation Detection (Disabled)"
				: Criteria != null ? $"Installation Detection (Criteria)" : $"Installation Detection (Custom)";
		}
	}
}
