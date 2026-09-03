using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Language;

namespace PSADTNXT.Text
{
	/// <summary>
	/// Allows for PowerShell auto-completion on <see cref="System.Text.Encoding"/> parameters based on enum values.
	/// </summary>
	public sealed class NxtEncodingArgumentCompleter : IArgumentCompleter
	{
		public IEnumerable<CompletionResult> CompleteArgument(string commandName, string parameterName, string wordToComplete, CommandAst commandAst, IDictionary fakeBoundParameters)
		{
#pragma warning disable CA2263
			return Enum.GetNames(typeof(FileEncoding))
				.Where(n => n.StartsWith(wordToComplete, StringComparison.OrdinalIgnoreCase))
				.Select(n => new CompletionResult(n));
#pragma warning restore CA2263
		}
	}
}
