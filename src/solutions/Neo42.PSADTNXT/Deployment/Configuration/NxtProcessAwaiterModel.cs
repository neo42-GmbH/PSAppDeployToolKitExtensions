using System.ComponentModel.DataAnnotations;
using PSADTNXT.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration
{
	public sealed record NxtProcessAwaiterModel
	{
		[Required]
		[ValidPath]
		public string Name { get; set; } = null!;

		public bool Exists { get; set; } = true;

		[ValidTimeSpan]
		public string? Timeout { get; set; }
	}
}
