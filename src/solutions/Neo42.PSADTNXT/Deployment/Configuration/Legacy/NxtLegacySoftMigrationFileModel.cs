namespace PSADTNXT.Deployment.Configuration.Legacy
{
	public sealed record NxtLegacySoftMigrationFileModel
	{
		public string FullNameToCheck { get; set; } = string.Empty;

		public string VersionToCheck { get; set; } = string.Empty;
	}
}
