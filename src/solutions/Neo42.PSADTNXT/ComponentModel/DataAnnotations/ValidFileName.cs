using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.IO;
using System.Linq;

namespace PSADTNXT.ComponentModel.DataAnnotations
{
	/// <summary>
	/// Validates that a path is valid.
	/// </summary>
	[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
	internal sealed class ValidFileNameAttribute : ValidationAttribute
	{
		public string[] FileExtension { get; set; } = [];

		/// <summary>
		/// Initializes a new instance of the <see cref="ValidPathAttribute"/> class.
		/// </summary>
		public ValidFileNameAttribute()
			: base("The path is not valid.")
		{
		}

		/// <summary>
		/// Validates the specified value.
		/// </summary>
		protected override ValidationResult IsValid(object? value, ValidationContext validationContext)
		{
			if (value == null
				|| (value is string path && IsValidFileName(path))
				|| (value is IEnumerable<string> paths && paths.All(IsValidFileName)))
			{
				return ValidationResult.Success!;
			}
			return new ValidationResult($"The path for '{validationContext.MemberName}' in '{validationContext.ObjectInstance.GetType().Name}' is not valid.");
		}

		private bool IsValidFileName(string path)
		{
			return !string.IsNullOrWhiteSpace(path)
				&& path.IndexOfAny(Path.GetInvalidFileNameChars()) == -1
				&& (
					FileExtension.Length == 0
					|| FileExtension.Any(ext => path.EndsWith(ext, StringComparison.OrdinalIgnoreCase))
				);
		}
	}
}
