using System;
using System.ComponentModel.DataAnnotations;
using System.Linq;

namespace PSADTNXT.ComponentModel.DataAnnotations
{
	/// <summary>
	/// Validates that a path is valid.
	/// </summary>
	[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
	internal sealed class ValidSet : ValidationAttribute
	{
		public string[] Values { get; set; } = null!;

		public StringComparison StringComparison { get; set; }

		/// <summary>
		/// Validates the specified value.
		/// </summary>
		protected override ValidationResult IsValid(object? value, ValidationContext validationContext)
		{
			if (value == null || value is not string valueStr)
			{
				return new ValidationResult($"The value for '{validationContext.MemberName}' in '{validationContext.ObjectInstance.GetType().Name}' is not of the correct type.");
			}

			return Values.Any(v => string.Equals(v, valueStr, StringComparison))
				? ValidationResult.Success!
				: new ValidationResult(ErrorMessage);
		}
	}
}
