using System;
using System.ComponentModel.DataAnnotations;
using PSADTNXT.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration.Legacy
{
	public sealed record NxtLegacyAppKillProcessModel
	{
		[Required]
		[ValidFileName]
		public string Name { get; set; } = string.Empty;

		public string Description { get; set; } = string.Empty;

		[Obsolete("Wql filter are deprecated")]
		public bool IsWql { get; set; }
	}
}
