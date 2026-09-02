using System;
using System.ComponentModel.DataAnnotations;

namespace PSADTNXT.ComponentModel.DataAnnotations
{

	[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
	public class ValidTimeSpan : ValidationAttribute
	{
		public TimeSpan Minimum { get; set; } = TimeSpan.Zero;

		public TimeSpan Maximum { get; set; } = TimeSpan.MaxValue;

		protected override ValidationResult IsValid(object? value, ValidationContext validationContext)
		{
			if (value == null)
			{
				return ValidationResult.Success!;
			}

			TimeSpan testTimespan;
			if (value is string valueStr)
			{
				if (!TimeSpan.TryParse(valueStr, out testTimespan))
				{
					return new ValidationResult($"The string '{valueStr}' for '{validationContext.MemberName}' in '{validationContext.ObjectInstance.GetType().Name}' could not be parsed to a TimeSpan.");
				}
			}
			else if (value is TimeSpan ts)
			{
				testTimespan = ts;
			}
			else
			{
				return new ValidationResult($"The value for '{validationContext.MemberName}' in '{validationContext.ObjectInstance.GetType().Name}' is not of the correct type.");
			}

			if (testTimespan < Minimum || testTimespan > Maximum)
			{
				return new ValidationResult($"The TimeSpan '{testTimespan}' for '{validationContext.MemberName}' in '{validationContext.ObjectInstance.GetType().Name}' is not in the valid range of '{Minimum}' to '{Maximum}'.");
			}
			return ValidationResult.Success!;
		}
	}
}
