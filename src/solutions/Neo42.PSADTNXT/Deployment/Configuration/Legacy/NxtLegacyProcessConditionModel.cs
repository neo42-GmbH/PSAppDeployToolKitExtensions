using System.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration.Legacy
{
	public sealed record NxtLegacyProcessConditionModel
	{
		[Required]
		public string Name { get; set; } = string.Empty;

		public bool ShouldExist { get; set; } = true;
	}
}
