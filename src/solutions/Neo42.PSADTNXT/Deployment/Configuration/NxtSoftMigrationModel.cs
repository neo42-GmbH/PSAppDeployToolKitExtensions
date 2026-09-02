namespace PSADTNXT.Deployment.Configuration
{
	public sealed record NxtSoftMigrationModel
	{
		public bool Enabled { get; set; }

		public SoftMigrationDetectionMode Mode { get; set; } = SoftMigrationDetectionMode.Detection;

		public string? Target { get; set; }

		public string? Version { get; set; }

		public bool UsePackageVersion { get; set; }
	}
}
