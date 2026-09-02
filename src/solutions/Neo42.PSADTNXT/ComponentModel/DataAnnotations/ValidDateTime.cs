using System;
using System.ComponentModel.DataAnnotations;
using System.Globalization;

namespace PSADTNXT.ComponentModel.DataAnnotations
{
	/// <summary>
	/// Validates that a path is valid.
	/// </summary>
	[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
	public class ValidDateTime : ValidationAttribute
	{
		public DateTimeStyles DateTimeStyles { get; set; } = DateTimeStyles.None;

		public string Format { get; set; } = string.Empty;

		public ValidDateTime()
			: base($"The given date time is not valid.")
		{
		}

		/// <summary>
		/// Validates the specified value.
		/// </summary>
		protected override ValidationResult IsValid(object? value, ValidationContext validationContext)
		{
			if (value == null)
			{
				return ValidationResult.Success!;
			}

			if (!string.IsNullOrEmpty(Format))
			{
				return DateTime.TryParseExact(value.ToString(), Format, null, DateTimeStyles, out _)
					? ValidationResult.Success!
					: new ValidationResult($"The value for '{validationContext.MemberName}' in '{validationContext.ObjectInstance.GetType().Name}' is not a valid date time in the format '{Format}'.");
			}
			else
			{
				return DateTime.TryParse(value.ToString(), null, DateTimeStyles, out _)
					? ValidationResult.Success!
					: new ValidationResult($"The value for '{validationContext.MemberName}' in '{validationContext.ObjectInstance.GetType().Name}' is not a valid date time.");
			}
		}
	}
}
