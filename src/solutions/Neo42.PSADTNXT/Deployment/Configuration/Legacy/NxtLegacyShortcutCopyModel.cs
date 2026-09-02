using System.ComponentModel.DataAnnotations;
using PSADTNXT.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration.Legacy
{
	public sealed record NxtLegacyShortcutCopyModel
	{
		[Required]
		[ValidPath(Root = ValidPathRoot.NotRooted)]
		public string Source { get; set; } = string.Empty;

		[ValidFileName]
		public string TargetName { get; set; } = string.Empty;
	}
}
