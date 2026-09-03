using System;
using System.Collections;
using System.IO;
using PSADTNXT.IO;

namespace PSADTNXT.Deployment
{
	public sealed record NxtShortcutOperation
	{
		public ShortcutOperation Mode { get; }

		public ShortcutLocation Location { get; }

		public string Target { get; }

		public string? Source { get; }

		public NxtShortcutOperation(ShortcutOperation mode, string target, ShortcutLocation location = ShortcutLocation.Desktop, string? source = null)
		{
			Mode = mode;
			Location = location;
			if (Path.IsPathRooted(target))
			{
				throw new ArgumentException("Target must be a relative file path or a valid URL.", nameof(target));
			}
			Target = target;
			if (source is not null && !NxtPath.IsValidFilePath(source))
			{
				throw new ArgumentException("Source must be an absolute file path.", nameof(source));
			}
			Source = source;
		}

		public static implicit operator NxtShortcutOperation(Hashtable hashtable)
		{
			return FromHashtable(hashtable);
		}

		public static NxtShortcutOperation FromHashtable(Hashtable hashtable)
		{
			if (hashtable == null)
			{
				throw new ArgumentNullException(nameof(hashtable));
			}

			var mode = hashtable.ContainsKey("Mode")
				? Enum.TryParse<ShortcutOperation>(hashtable["Mode"]?.ToString(), true, out var parsedMode) ? parsedMode : throw new ArgumentException($"Invalid value for Mode: {hashtable["Mode"]}")
				: throw new ArgumentException("Missing 'Mode' value in the provided hashtable.");

			var target = hashtable.ContainsKey("Target") && hashtable["Target"] is string targetValue
				? targetValue
				: throw new ArgumentException("Missing or invalid 'Target' value in the provided hashtable.");

			var location = hashtable.ContainsKey("Location")
				? Enum.TryParse<ShortcutLocation>(hashtable["Location"]?.ToString(), true, out var parsedLocation) ? parsedLocation : throw new ArgumentException($"Invalid value for Location: {hashtable["Location"]}")
				: ShortcutLocation.Desktop;

			var source = hashtable.ContainsKey("Source")
				? hashtable["Source"] is string sourceValue ? sourceValue : throw new ArgumentException($"Invalid value for Source: {hashtable["Source"]}")
				: null;

			return new NxtShortcutOperation(mode, target, location, source);
		}

		public override string ToString()
		{
			return $"{Target} ({Mode}:{Location})";
		}
	}
}
