namespace PSADTNXT.WinGet.Configuration
{
	public sealed record AppsAndFeaturesEntryModel
	{
		public string? DisplayName { get; set; }

		public string? Publisher { get; set; }

		public string? ProductCode { get; set; }

		public string? UpgradeCode { get; set; }

		public string? DeploymentMethod { get; set; }
	}
}
