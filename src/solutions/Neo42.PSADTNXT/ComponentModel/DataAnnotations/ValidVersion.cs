using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;

namespace PSADTNXT.ComponentModel.DataAnnotations
{
	/// <summary>
	/// Validates that a path is valid.
	/// </summary>
	[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
	public class ValidVersionAttribute : ValidationAttribute
	{
		private readonly Version _minimum;

		private readonly Version _maximum;

		/// <summary>
		/// Initializes a new instance of the <see cref="ValidPathAttribute"/> class.
		/// </summary>
		public ValidVersionAttribute(string exactVersion)
			: base($"The version is not exactly '{exactVersion}'.")
		{
			if (!Version.TryParse(exactVersion, out var version))
			{
				throw new ArgumentException("Invalid version format for exact version.", nameof(exactVersion));
			}
			_maximum = version;
			_minimum = version;
		}

		public ValidVersionAttribute(string minimumVersion, string maximumVersion)
			: base($"The version must be between '{minimumVersion}' and '{maximumVersion}'.")
		{
			if (!Version.TryParse(minimumVersion, out var min))
			{
				throw new ArgumentException("Invalid version format for minimum version.", nameof(minimumVersion));
			}
			_minimum = min;
			if (!Version.TryParse(maximumVersion, out var max))
			{
				throw new ArgumentException("Invalid version format for maximum version.", nameof(maximumVersion));
			}
			_maximum = max;
			if (_minimum > _maximum)
			{
				throw new ArgumentException("Minimum version cannot be greater than maximum version.");
			}
		}

		public ValidVersionAttribute()
			: base("The version is not valid.")
		{
			_minimum = new Version(0, 0);
			_maximum = new Version(int.MaxValue, int.MaxValue, int.MaxValue, int.MaxValue);
		}

		/// <summary>
		/// Validates the specified value.
		/// </summary>
		protected override ValidationResult IsValid(object? value, ValidationContext validationContext)
		{
			if (value == null
				|| (value is string versionString && Version.TryParse(versionString, out var version) && IsValidVersion(version))
				|| (value is IEnumerable<string> versionStrings && versionStrings.All(vs => Version.TryParse(vs, out var v) && IsValidVersion(v)))
				|| (value is Version versionObj && IsValidVersion(versionObj))
				|| (value is IEnumerable<Version> versions && versions.All(IsValidVersion)))
			{
				return ValidationResult.Success!;
			}

			return new ValidationResult($"'{validationContext.MemberName}' in '{validationContext.ObjectInstance.GetType().Name}' is not valid:" + ErrorMessage);
		}

		private bool IsValidVersion(Version version)
		{
			return version >= _minimum && version <= _maximum;
		}
	}
}
