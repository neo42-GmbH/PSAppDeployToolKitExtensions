using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;

namespace PSADTNXT.Configuration
{
	/// <summary>
	/// Exception thrown when a <see cref="NxtIniDocument"/> fails validation against its metadata.
	/// Contains all validation errors that were found.
	/// </summary>
	public sealed class NxtIniValidationException : Exception
	{
		/// <summary>
		/// Gets all validation errors that were found.
		/// </summary>
		public ReadOnlyCollection<string> Errors { get; }

		public NxtIniValidationException(IEnumerable<string> errors)
			: this(errors, null) { }

		public NxtIniValidationException(IEnumerable<string> errors, Exception? innerException)
			: this(new ReadOnlyCollection<string>([.. errors ?? throw new ArgumentNullException(nameof(errors))]), innerException) { }

		private NxtIniValidationException(ReadOnlyCollection<string> errors, Exception? innerException)
			: base(BuildMessage(errors), innerException)
		{
			Errors = errors;
		}

		private static string BuildMessage(ReadOnlyCollection<string> errors)
		{
			return errors.Count == 0
				? "The ini document is invalid."
				: $"The ini document is invalid. Errors:{Environment.NewLine}- {string.Join($"{Environment.NewLine}- ", errors)}";
		}
	}
}
