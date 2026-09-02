using System.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration.Legacy
{
	public sealed record NxtLegacyRegistryConditionModel
	{
		[Required]
		public string KeyPath { get; set; } = string.Empty;

		public bool ShouldExist { get; set; } = true;

		public string ValueName { get; set; } = string.Empty;

		public string ValueData { get; set; } = string.Empty;
	}
}
