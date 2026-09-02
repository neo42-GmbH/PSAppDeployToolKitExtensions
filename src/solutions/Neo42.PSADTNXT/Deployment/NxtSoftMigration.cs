using PSADTNXT.Application;

namespace PSADTNXT.Deployment
{
	public class NxtSoftMigration
	{
		public bool Enabled { get; set; }

		public SoftMigrationDetectionMode Mode { get; set; }

		public string? Target { get; set; }

		public NxtVersion? Version { get; set; }

		public bool? Result { get; set; }

		internal NxtSoftMigration() { }

		public override string ToString()
		{
			return Enabled
				? $"Soft Migration Detection ({Mode})"
				: "Soft Migration Detection (Disabled)";
		}
	}
}
