using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using PSADTNXT.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration
{
	public sealed record NxtPackageConfigurationModel : IValidatableObject
	{
		[Required]
		[ValidVersion(maximumVersion: "2025.12.1.0", minimumVersion: "2025.12.1.0")]
		public Version ConfigVersion { get; set; } = null!;

		[Required]
		public NxtPackageMetadataModel Package { get; set; } = null!;

		public List<NxtRequirementModel>? Requirements { get; set; }

		public NxtApplicationDetectionModel? Detection { get; set; }

		public NxtSoftMigrationModel? SoftMigration { get; set; }

		public List<NxtCloseProcessesModel>? CloseProcesses { get; set; }

		public List<NxtShortcutModel>? ManagedShortcuts { get; set; }

		public List<NxtApplicationCriteriaModel>? ManagedApplications { get; set; }

		public NxtDeploymentContainerModel? Deployment { get; set; }

		public Dictionary<string, object>? Variables { get; set; }

		public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
		{
			var results = new List<ValidationResult>();
			_ = Validator.TryValidateObject(Package, new ValidationContext(Package), results, true);
			Requirements?.ForEach(r => _ = Validator.TryValidateObject(r, new ValidationContext(r), results, true));
			if (Detection != null)
			{
				_ = Validator.TryValidateObject(Detection, new ValidationContext(Detection), results, true);
			}
			if (SoftMigration != null)
			{
				_ = Validator.TryValidateObject(SoftMigration, new ValidationContext(SoftMigration), results, true);
			}
			CloseProcesses?.ForEach(cp => _ = Validator.TryValidateObject(cp, new ValidationContext(cp), results, true));
			ManagedShortcuts?.ForEach(s => _ = Validator.TryValidateObject(s, new ValidationContext(s), results, true));
			ManagedApplications?.ForEach(a => _ = Validator.TryValidateObject(a, new ValidationContext(a), results, true));
			if (Deployment != null)
			{
				_ = Validator.TryValidateObject(Deployment, new ValidationContext(Deployment), results, true);
			}
			return results;
		}
	}
}
