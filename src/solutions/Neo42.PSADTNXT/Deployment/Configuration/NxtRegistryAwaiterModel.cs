using System.ComponentModel.DataAnnotations;
using PSADTNXT.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration
{
	public sealed record NxtRegistryAwaiterModel
	{
		[Required]
		[ValidRegistryPath(Root = ValidPathRoot.Rooted)]
		public string Key { get; set; } = null!;

		[ValidRegistryPath(Root = ValidPathRoot.NotRooted)]
		public string? Name { get; set; }

		public string? Value { get; set; }

		public bool Exists { get; set; } = true;

		[ValidTimeSpan]
		public string? Timeout { get; set; }
	}
}
