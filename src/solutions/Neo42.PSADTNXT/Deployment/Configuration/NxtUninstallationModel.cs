using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using PSADTNXT.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration
{
	public sealed record NxtUninstallationModel : IValidatableObject
	{

		public DeploymentMethod? Method { get; set; }

		public string? Target { get; set; }

		public string? Arguments { get; set; }

		public bool Defaults { get; set; } = true;

		[ValidFileName(FileExtension = [".log"])]
		public string? LogName { get; set; }

		public List<int>? SuccessCodes { get; set; }

		public List<int>? RebootCodes { get; set; }

		public bool IgnoreExitCodes { get; set; }

		public RebootAction Reboot { get; set; } = RebootAction.IfRequired;

		public NxtAwaiterModel? Awaiters { get; set; }

		public bool UserPart { get; set; }

		public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
		{
			var results = new List<ValidationResult>();
			if (Awaiters is not null)
			{
				_ = Validator.TryValidateObject(Awaiters, new ValidationContext(Awaiters), results, true);
			}
			return results;
		}
	}
}
