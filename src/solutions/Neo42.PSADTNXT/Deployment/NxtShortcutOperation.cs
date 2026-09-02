using System;
using System.IO;
using PSADTNXT.IO;

namespace PSADTNXT.Deployment
{
	public sealed class NxtShortcutOperation
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

		public override string ToString()
		{
			return $"{Target} ({Mode}:{Location})";
		}
	}
}
