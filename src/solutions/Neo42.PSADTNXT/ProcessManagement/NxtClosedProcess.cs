using System;
using System.Collections;
using System.IO;
using System.Security.Principal;

namespace PSADTNXT.ProcessManagement
{
	public sealed record NxtClosedProcess
	{
		public NTAccount Username { get; }

		public string FilePath { get; }

		public string Arguments { get; }

		public DirectoryInfo WorkingDirectory { get; }

		public bool AsAdmin { get; }

		public NxtClosedProcess(
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

		public static implicit operator NxtClosedProcess(Hashtable hashtable)
		{
			return FromHashtable(hashtable);
		}

		public static NxtClosedProcess FromHashtable(Hashtable hashtable)
		{
			if (hashtable == null)
			{
				throw new ArgumentNullException(nameof(hashtable));
			}

			var user = hashtable.ContainsKey("User")
				? hashtable["User"] is IdentityReference identityRef
					? identityRef
					: hashtable["User"] is string userString
						? new NTAccount(userString)
						: throw new ArgumentException("Missing 'User' value in the provided hashtable.")
				: throw new ArgumentException("Missing 'User' value in the provided hashtable.");

			var filePath = hashtable.ContainsKey("FilePath")
				? hashtable["FilePath"] is string filePathValue
					? filePathValue
					: throw new ArgumentException("Invalid 'FilePath' value in the provided hashtable.")
				: throw new ArgumentException("Missing or invalid 'FilePath' value in the provided hashtable.");

			var arguments = hashtable.ContainsKey("Arguments")
				? hashtable["Arguments"] is string argumentsValue
					? argumentsValue
					: throw new ArgumentException("Invalid 'Arguments' value in the provided hashtable.")
				: string.Empty;

			var workingDirectory = hashtable.ContainsKey("WorkingDirectory")
				? hashtable["WorkingDirectory"] is string workingDirValue
					? new DirectoryInfo(workingDirValue)
					: hashtable["WorkingDirectory"] is DirectoryInfo dirInfo
						? dirInfo
						: throw new ArgumentException("Invalid 'WorkingDirectory' value in the provided hashtable.")
				: null;

#pragma warning disable IDE0075
			var asAdmin = hashtable.ContainsKey("AsAdmin")
				? hashtable["AsAdmin"] is bool asAdminValue
					? asAdminValue
					: throw new ArgumentException("Invalid 'AsAdmin' value in the provided hashtable.")
				: false;
#pragma warning restore IDE0075

			return new NxtClosedProcess(user, filePath, arguments, workingDirectory, asAdmin);
		}

		public override string ToString()
		{
			return $"{Path.GetFileName(FilePath)} (User: {Username.Value})";
		}
	}
}
