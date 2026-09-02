using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration.Legacy
{
	public sealed record NxtLegacyConditionCheckContainerModel : IValidatableObject
	{
		public NxtLegacyConditionCheckModel? Install { get; set; }

		public NxtLegacyConditionCheckModel? Uninstall { get; set; }

		public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
		{
			var results = new List<ValidationResult>();
			if (Install is not null)
			{
				_ = Validator.TryValidateObject(Install, new ValidationContext(Install), results, true);
			}
			if (Uninstall is not null)
			{
				_ = Validator.TryValidateObject(Uninstall, new ValidationContext(Uninstall), results, true);
			}
			return results;
		}
	}
}
