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
	internal sealed class ValidPathAttribute : ValidationAttribute
	{
		public ValidPathRoot Root { get; set; } = ValidPathRoot.Any;

		public string[] FileExtension { get; set; } = [];

		/// <summary>
		/// Initializes a new instance of the <see cref="ValidPathAttribute"/> class.
		/// </summary>
		public ValidPathAttribute()
			: base("The path is not valid.")
		{
		}

		/// <summary>
		/// Validates the specified value.
		/// </summary>
		protected override ValidationResult IsValid(object? value, ValidationContext validationContext)
		{
			if (string.IsNullOrEmpty(value as string)
				|| (value is string path && IsValidPath(path))
				|| (value is IEnumerable<string> paths && paths.All(IsValidPath)))
			{
				return ValidationResult.Success!;
			}

			return new ValidationResult($"The path for '{validationContext.MemberName}' in '{validationContext.ObjectInstance.GetType().Name}' is not valid.");
		}

		private bool IsValidPath(string path)
		{
			return !string.IsNullOrWhiteSpace(path)
				&& IsValidPathString(path)
				&& (
					Root == ValidPathRoot.Any
					|| (Root == ValidPathRoot.Rooted && Path.IsPathRooted(path))
					|| (Root == ValidPathRoot.NotRooted && !Path.IsPathRooted(path))
				)
				&& (
					FileExtension.Length == 0
					|| FileExtension.Any(ext => path.EndsWith(ext, StringComparison.OrdinalIgnoreCase))
				);
		}

		private bool IsValidPathString(string path)
		{
			try
			{
				Path.GetFullPath(path);
				return true;
			}
			catch
			{
				return false;
			}
		}
	}
}
