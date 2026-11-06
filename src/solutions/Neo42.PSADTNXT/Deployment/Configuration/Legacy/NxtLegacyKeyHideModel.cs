using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using PSADTNXT.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration.Legacy
{
	public sealed record NxtLegacyKeyHideModel
	{
		[Required]
		public string KeyName { get; set; } = string.Empty;

		public bool Is64Bit { get; set; } = true;

		[ValidSet(Values = ["True", "False"], StringComparison = StringComparison.OrdinalIgnoreCase)]
		public string KeyNameIsDisplayName { get; set; } = "False";

		[ValidSet(Values = ["True", "False"], StringComparison = StringComparison.OrdinalIgnoreCase)]
		public string KeyNameContainsWildCards { get; set; } = "False";

		public List<string>? DisplayNamesToExcludeFromHiding { get; set; }
	}
}
