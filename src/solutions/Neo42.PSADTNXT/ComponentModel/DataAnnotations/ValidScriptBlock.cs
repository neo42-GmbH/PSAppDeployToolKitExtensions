using System;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Language;
using PSADTNXT.Shell;

namespace PSADTNXT.ComponentModel.DataAnnotations
{
	/// <summary>
	/// Validates that a path is valid.
	/// </summary>
	[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
	internal sealed class ValidScriptBlock : ValidationAttribute
	{
		public bool Strict { get; set; }

		public string[] AllowedVariables { get; set; } = [];

		public bool AllowEnvironmentVariables { get; set; }

		/// <summary>
		/// Initializes a new instance of the <see cref="ValidScriptBlock"/> class.
		/// </summary>
		public ValidScriptBlock()
			: base("The script block is not valid.")
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
			if (value is not ScriptBlock scriptBlock)
			{
				return new ValidationResult($"The value for '{validationContext.MemberName}' in '{validationContext.ObjectInstance.GetType().Name}' is not a valid script block.");
			}

			_ = Parser.ParseInput(scriptBlock.ToString(), out _, out var parseErrors);
			if (parseErrors.Length > 0)
			{
				return new ValidationResult($"The script block for '{validationContext.MemberName}' in '{validationContext.ObjectInstance.GetType().Name}' contains syntax errors.");
			}

			if (!Strict)
			{
				return ValidationResult.Success!;
			}

			if (!NxtPowerShell.IsConfigSafe(scriptBlock, AllowedVariables, out var strictErrors))
			{
				return new ValidationResult($"The script block for '{validationContext.MemberName}' in '{validationContext.ObjectInstance.GetType().Name}' is not configuration safe: {string.Join("; ", strictErrors.Select(e => e.Message))}");
			}

			return ValidationResult.Success!;
		}
	}
}
