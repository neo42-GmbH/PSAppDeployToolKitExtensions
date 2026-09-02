using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using PSADTNXT.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration.Legacy
{
	public sealed record NxtLegacyConditionCheckModel : IValidatableObject
	{
		public List<NxtLegacyProcessConditionModel>? ProcessesToWaitFor { get; set; }

		public List<NxtLegacyRegistryConditionModel>? RegKeysToWaitFor { get; set; }

		[ValidSet(Values = ["And", "Or"], StringComparison = StringComparison.OrdinalIgnoreCase)]
		public string ProcessOperator { get; set; } = "And";

		[ValidSet(Values = ["And", "Or"], StringComparison = StringComparison.OrdinalIgnoreCase)]
		public string RegKeyOperator { get; set; } = "And";

		public uint TotalSecondsToWaitFor { get; set; } = 30;

		public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
		{
			var results = new List<ValidationResult>();
			ProcessesToWaitFor?.ForEach(p => _ = Validator.TryValidateObject(p, new ValidationContext(p), results, true));
			RegKeysToWaitFor?.ForEach(rk => _ = Validator.TryValidateObject(rk, new ValidationContext(rk), results, true));
			return results;
		}
	}
}
