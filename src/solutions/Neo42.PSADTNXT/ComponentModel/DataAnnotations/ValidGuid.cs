
using System;
using System.ComponentModel.DataAnnotations;

namespace PSADTNXT.ComponentModel.DataAnnotations
{
	/// <summary>
	/// Validates that a path is valid.
	/// </summary>
	[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
	internal sealed class ValidGuidAttribute : ValidationAttribute
	{
		public bool AllowEmpty { get; set; }

		protected override ValidationResult IsValid(object? value, ValidationContext validationContext)
		{
			if (value == null)
			{
				return ValidationResult.Success!;
			}

			Guid guid;
			if (value is string strValue)
			{
				if (!Guid.TryParse(strValue, out guid))
				{
					return new ValidationResult($"The string '{strValue}' for '{validationContext.MemberName}' in '{validationContext.ObjectInstance.GetType().Name}' could not be parsed to a Guid.");
				}
			}
			else if (value is Guid g)
			{
				guid = g;
			}
			else
			{
				return new ValidationResult($"The value for '{validationContext.MemberName}' in '{validationContext.ObjectInstance.GetType().Name}' is not of the correct type.");
			}

			return (!AllowEmpty && guid == Guid.Empty)
				? new ValidationResult("The Guid is empty.")
				: ValidationResult.Success!;
		}
	}
}
