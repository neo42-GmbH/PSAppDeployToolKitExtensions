using System;
using System.IO;
using System.Security.Principal;

namespace PSADTNXT.ProcessManagement
{
	public sealed record NxtOpenProcess
	{
		public NTAccount Username { get; }

		public string FilePath { get; }

		public string Arguments { get; }

		public DirectoryInfo WorkingDirectory { get; }

		public bool AsAdmin { get; }

		public NxtOpenProcess(
			IdentityReference user,
			string filePath,
			string arguments = "",
			DirectoryInfo? workingDirectory = null,
			bool asAdmin = false
		)
		{
			Username = user.Translate(typeof(NTAccount)) as NTAccount ?? throw new ArgumentNullException(nameof(user));
			Arguments = arguments ?? string.Empty;
			WorkingDirectory = workingDirectory ?? new DirectoryInfo(Path.GetDirectoryName(filePath) ?? throw new ArgumentException("Process path is invalid.", nameof(filePath)));
			AsAdmin = asAdmin;

			if (string.IsNullOrWhiteSpace(filePath))
			{
				throw new ArgumentException("Process path cannot be null or whitespace.", nameof(filePath));
			}
			if (!Path.IsPathRooted(filePath) || Path.GetExtension(filePath)?.Equals(".exe", StringComparison.OrdinalIgnoreCase) != true)
			{
				throw new ArgumentException("Process path must be an absolute path and have a .exe extension.", nameof(filePath));
			}
			FilePath = filePath;
		}

		public override string ToString()
		{
			return $"{Path.GetFileName(FilePath)} (User: {Username.Value})";
		}
	}
}
