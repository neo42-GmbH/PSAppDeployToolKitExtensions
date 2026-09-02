using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
namespace PSADTNXT.Deployment.Configuration
{
	public sealed record NxtRequirementModel : IValidatableObject
	{
		[Required]
		public NxtApplicationCriteriaModel Criteria { get; set; } = new NxtApplicationCriteriaModel();

		public RequirementState DesiredState { get; set; } = RequirementState.Present;

		public RequirementConflictAction OnConflict { get; set; } = RequirementConflictAction.Fail;

		public string? ErrorMessage { get; set; }

		public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
		{
			var results = new List<ValidationResult>();
			_ = Validator.TryValidateObject(Criteria, new ValidationContext(Criteria), results, true);
			return results;
		}
	}
}
