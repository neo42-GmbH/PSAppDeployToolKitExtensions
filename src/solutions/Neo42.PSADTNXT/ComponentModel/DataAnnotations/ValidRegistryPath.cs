using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using PSADTNXT.Extensions;

namespace PSADTNXT.ComponentModel.DataAnnotations
{
	/// <summary>
	/// Validates that a path is valid.
	/// </summary>
	[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
	public class ValidRegistryPathAttribute : ValidationAttribute
	{
		public ValidPathRoot Root { get; set; } = ValidPathRoot.Any;

		/// <summary>
		/// Initializes a new instance of the <see cref="ValidRegistryPathAttribute"/> class.
		/// </summary>
		public ValidRegistryPathAttribute()
			: base("The registry path is not valid.")
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

			return new ValidationResult("The registry path for for '{validationContext.MemberName}' in '{validationContext.ObjectInstance.GetType().Name}' is not valid.");
		}

		private bool IsValidPath(string path)
		{
			if (path.Any(c => !NxtRegistryExtensions.IsValidPathChar(c)))
			{
				return false;
			}

			if (Root == ValidPathRoot.Any)
			{
				return true;
			}

			var firstPart = path.Split('\\').First().TrimEnd(':');
			bool hasRoot;
			try
			{
				NxtRegistryExtensions.GetHive(firstPart);
				hasRoot = true;
			}
			catch
			{
				hasRoot = false;
			}

			return hasRoot == (Root == ValidPathRoot.Rooted);
		}
	}
}
