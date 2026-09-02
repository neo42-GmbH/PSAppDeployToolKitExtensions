using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration
{
	public partial record NxtApplicationDetectionModel : IValidatableObject
	{
		public bool Enabled { get; set; }

		public string? Version { get; set; }

		public bool UsePackageVersion { get; set; }

		public NxtApplicationCriteriaModel? Criteria { get; set; }

		public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
		{
			var results = new List<ValidationResult>();
			if (Criteria != null)
			{
				_ = Validator.TryValidateObject(Criteria, new ValidationContext(Criteria), results, true);
			}
			return results;
		}
	}
}
