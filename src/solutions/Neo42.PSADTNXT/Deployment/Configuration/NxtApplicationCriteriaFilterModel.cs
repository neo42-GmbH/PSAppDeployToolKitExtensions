using System.ComponentModel.DataAnnotations;
using PSADTNXT.Text;

namespace PSADTNXT.Deployment.Configuration
{
	public sealed record NxtApplicationCriteriaFilterModel
	{
		[Required]
		public string Property { get; set; } = null!;

		[Required]
		public string Value { get; set; } = null!;

		public StringCompareOperator Operator { get; set; } = StringCompareOperator.Wildcard;

		public bool IgnoreCase { get; set; } = true;

		public bool Invert { get; set; }
	}
}
