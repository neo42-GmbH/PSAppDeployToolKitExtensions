using System.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration.Legacy
{
	public sealed record NxtLegacyVariableModel
	{
		[Required]
		public string Name { get; set; } = string.Empty;

		[Required(AllowEmptyStrings = true)]
		public string Value { get; set; } = string.Empty;

		public bool ExpandVariables { get; set; }
	}
}
