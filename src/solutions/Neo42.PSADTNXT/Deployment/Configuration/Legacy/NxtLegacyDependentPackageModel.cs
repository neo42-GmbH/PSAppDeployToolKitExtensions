using System;
using System.ComponentModel.DataAnnotations;
using PSADTNXT.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration.Legacy
{
	public sealed record NxtLegacyDependentPackageModel
	{
		[Required]
		[ValidGuid]
#pragma warning disable CA1720
		public string GUID { get; set; } = string.Empty;
#pragma warning restore CA1720

		[ValidSet(Values = ["Present", "Absent"], StringComparison = StringComparison.OrdinalIgnoreCase)]
		public string DesiredState { get; set; } = RequirementState.Present.ToString();

		[ValidSet(Values = ["Continue", "Fail", "Uninstall", "Warn"], StringComparison = StringComparison.OrdinalIgnoreCase)]
		public string OnConflict { get; set; } = RequirementConflictAction.Fail.ToString();

		public string ErrorMessage { get; set; } = string.Empty;
	}
}
