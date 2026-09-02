using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using PSADTNXT.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration
{
	public sealed record NxtAwaiterModel : IValidatableObject
	{
		[Required]
		[ValidTimeSpan]
		public string DefaultTimeout { get; set; } = "00:00:30";

		public List<NxtRegistryAwaiterModel>? RegistryKeys { get; set; }

		public List<NxtProcessAwaiterModel>? Processes { get; set; }

		public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
		{
			var results = new List<ValidationResult>();
			RegistryKeys?.ForEach(rk => _ = Validator.TryValidateObject(rk, new ValidationContext(rk), results, true));
			Processes?.ForEach(p => _ = Validator.TryValidateObject(p, new ValidationContext(p), results, true));
			return results;
		}
	}
}
