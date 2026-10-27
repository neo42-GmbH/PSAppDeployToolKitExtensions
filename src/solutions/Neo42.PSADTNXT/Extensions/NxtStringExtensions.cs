using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Text.RegularExpressions;
using PSADTNXT.Text;

namespace PSADTNXT.Extensions
{
	public static class NxtStringExtensions
	{
		/// <summary>
		/// A collection of pairs of characters representing matching parentheses.
		/// Each pair consists of an opening character and its corresponding closing character.
		/// </summary>
		private static readonly IReadOnlyCollection<KeyValuePair<char, char>> _parenthesesPairs =
		[
			new KeyValuePair<char, char>('(', ')'),
			new KeyValuePair<char, char>('[', ']'),
			new KeyValuePair<char, char>('{', '}'),
			new KeyValuePair<char, char>('<', '>'),
			new KeyValuePair<char, char>('\'', '\''),
			new KeyValuePair<char, char>('"', '"')
		];

		/// <summary>
		/// Converts a string to a file name compatible format by replacing invalid characters with a specified replacement character.
		/// </summary>
		/// <param name="value">The string to convert.</param>
		/// <param name="replacementChar">The character to replace invalid characters with.</param>
		/// <returns>A string that is safe to use as a file name.</returns>
		public static string ToFileNameCompatible(this string value, bool escapeWhiteSpace = false, char replacementChar = '_')
		{

			var invalidChars = Path.GetInvalidFileNameChars();
			if (escapeWhiteSpace)
			{
				invalidChars = [.. invalidChars, ' ', '\t'];
			}

			if (invalidChars.Contains(replacementChar))
			{
				throw new ArgumentException($"Replacement character '{replacementChar}' is invalid for file names.", nameof(replacementChar));
			}

			if (string.IsNullOrEmpty(value))
			{
				return value;
			}
			else
			{
				return new string([.. value.Select(c => invalidChars.Contains(c) ? replacementChar : c)]);
			}
		}

		/// <summary>
		/// Removes matching parentheses from the start and end of a string.
		/// </summary>
		/// <param name="input">The input string.</param>
		/// <returns>The input string with matching parentheses removed from the start and end.</returns>
		internal static string RemoveParentheses(this string input)
		{
			foreach (var pair in _parenthesesPairs)
			{
				if (input.Length >= 2 && input[0] == pair.Key && input[input.Length - 1] == pair.Value)
				{
					input = input.Substring(1, input.Length - 2).Trim();
				}
			}

			return input;
		}

		public static bool IsMatch(this string input, string pattern, StringCompareOperator op = StringCompareOperator.Equals, bool ignoreCase = true)
		{
#pragma warning disable CA2249
			return op switch
			{
				StringCompareOperator.Equals => string.Equals(input, pattern, ignoreCase ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal),
				StringCompareOperator.StartsWith => input.StartsWith(pattern, ignoreCase ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal),
				StringCompareOperator.EndsWith => input.EndsWith(pattern, ignoreCase ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal),
				StringCompareOperator.Contains => input.IndexOf(pattern, ignoreCase ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal) != -1,
				StringCompareOperator.Wildcard => new WildcardPattern(pattern, ignoreCase ? WildcardOptions.IgnoreCase : WildcardOptions.None).IsMatch(input),
				StringCompareOperator.Regex => Regex.IsMatch(input, pattern, ignoreCase ? RegexOptions.IgnoreCase : RegexOptions.None),
				_ => throw new InvalidOperationException($"Unsupported string compare operator: {op}")
			};
#pragma warning restore CA2249
		}

		/// <summary>
		/// Parses a time span from a configuration string. A plain number is read as seconds, anything else as a <see cref="TimeSpan"/> (e.g. '00:01:30').
		/// </summary>
		/// <remarks>
		/// <see cref="TimeSpan.TryParse(string, out TimeSpan)"/> alone would read a plain number like '60' as days.
		/// </remarks>
		internal static bool TryParseTimeSpan(this string input, out TimeSpan result)
		{
			if (double.TryParse(input, NumberStyles.Float, CultureInfo.InvariantCulture, out var seconds) && !double.IsNaN(seconds) && !double.IsInfinity(seconds))
			{
				try
				{
					result = TimeSpan.FromSeconds(seconds);
					return true;
				}
				catch (OverflowException)
				{
					result = default;
					return false;
				}
			}

			return TimeSpan.TryParse(input, out result);
		}

		/// <inheritdoc cref="TryParseTimeSpan(string, out TimeSpan)"/>
		/// <exception cref="FormatException">Thrown if the string is neither a number nor a valid time span.</exception>
		internal static TimeSpan ParseTimeSpan(this string input)
		{
			return input.TryParseTimeSpan(out var result)
				? result
				: throw new FormatException($"'{input}' is neither a number of seconds nor a valid time span.");
		}
	}
}
