using System.ComponentModel.DataAnnotations;
using PSADTNXT.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration
{
	public sealed record NxtShortcutModel
	{
		public ShortcutOperation Mode { get; set; } = ShortcutOperation.Delete;

		public ShortcutLocation Location { get; set; } = ShortcutLocation.Desktop;

		[Required]
		[ValidFileName]
		public string Target { get; set; } = null!;

		[ValidPath(Root = ValidPathRoot.Any)]
		public string? Source { get; set; }
	}
}
