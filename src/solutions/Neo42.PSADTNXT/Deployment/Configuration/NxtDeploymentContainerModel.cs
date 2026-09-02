using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using PSADTNXT.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration
{
	public sealed record NxtDeploymentContainerModel : IValidatableObject
	{
		[ValidPath(Root = ValidPathRoot.Rooted)]
		public string? InstallLocation { get; set; }

		public NxtInstallationModel? Installation { get; set; } = null!;

		public NxtUninstallationModel? Uninstallation { get; set; }

		public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
		{
			var results = new List<ValidationResult>();
			if (Installation != null)
			{
				_ = Validator.TryValidateObject(Installation, new ValidationContext(Installation), results, true);
			}
			if (Uninstallation is not null)
			{
				_ = Validator.TryValidateObject(Uninstallation, new ValidationContext(Uninstallation), results, true);
			}
			return results;
		}
	}
}
