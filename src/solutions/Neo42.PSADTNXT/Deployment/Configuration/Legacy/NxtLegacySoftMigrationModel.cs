using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration.Legacy
{
	public sealed record NxtLegacySoftMigrationModel : IValidatableObject
	{
		public NxtLegacySoftMigrationFileModel? File { get; set; }

		public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
		{
			var results = new List<ValidationResult>();
			if (File is not null)
			{
				_ = Validator.TryValidateObject(File, new ValidationContext(File), results, true);
			}
			return results;
		}
	}
}
