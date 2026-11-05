using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;

namespace PSADTNXT.Deployment.Configuration
{
	/// <summary>
	/// Exception thrown when a package configuration fails validation.
	/// Contains all validation results that were found.
	/// </summary>
	public sealed class NxtPackageConfigurationValidationException : ValidationException
	{
		/// <summary>
		/// Gets all validation results that failed.
		/// </summary>
		public ReadOnlyCollection<ValidationResult> Errors { get; }

		public NxtPackageConfigurationValidationException(IEnumerable<ValidationResult> errors)
			: this(errors, null) { }

		public NxtPackageConfigurationValidationException(IEnumerable<ValidationResult> errors, Exception? innerException)
			: this(new ReadOnlyCollection<ValidationResult>([.. errors ?? throw new ArgumentNullException(nameof(errors))]), innerException) { }

		private NxtPackageConfigurationValidationException(ReadOnlyCollection<ValidationResult> errors, Exception? innerException)
			: base(BuildMessage(errors), innerException)
		{
			Errors = errors;
		}

		private static string BuildMessage(ReadOnlyCollection<ValidationResult> errors)
		{
			return errors.Count == 0
				? "The package configuration is invalid."
				: $"The package configuration is invalid. Errors:{Environment.NewLine}- {string.Join($"{Environment.NewLine}- ", errors.Select(static e => e.ErrorMessage))}";
		}
	}
}
