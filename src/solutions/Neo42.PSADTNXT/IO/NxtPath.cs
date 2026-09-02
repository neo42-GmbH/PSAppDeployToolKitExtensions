using System;
using System.IO;
using System.Linq;
using System.Security.AccessControl;

namespace PSADTNXT.IO
{
	public static class NxtPath
	{
		private static readonly char[] _invalidFileNameChars = [.. Path.GetInvalidFileNameChars(), Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar];

		/// <summary>
		/// Gets the executable name from a given file name by removing its extension.
		/// </summary>
		/// <param name="fileName">The path or name of the file.</param>
		/// <returns>The executable name without its extension.</returns>
		public static string GetExecutableName(string fileName)
		{
			if (string.IsNullOrWhiteSpace(fileName))
			{
				throw new ArgumentException("File name cannot be null or whitespace.", nameof(fileName));
			}

			var fileNameWithoutPath = Path.GetFileName(fileName);
			if (fileNameWithoutPath.EndsWith(".exe", StringComparison.OrdinalIgnoreCase))
			{
				return fileNameWithoutPath.Substring(0, fileNameWithoutPath.Length - 4);
			}
			else
			{
				return fileNameWithoutPath;
			}
		}

		/// <summary>
		/// Determines whether the given path is a valid file name (i.e., it does not contain any invalid file name characters or directory separators).
		/// </summary>
		/// <param name="path">The path to validate.</param>
		/// <returns>True if the path is a valid file name; otherwise, false.</returns>
		public static bool IsFileName(string path)
		{
			return !(path.IndexOfAny(_invalidFileNameChars) >= 0);
		}

		/// <summary>
		/// Determines whether the given path is a valid file path (i.e., it does not contain any invalid path characters).
		/// </summary>
		/// <param name="path">The path to validate.</param>
		/// <returns>True if the path is a valid file path; otherwise, false.</returns>
		public static bool IsValidFilePath(string path)
		{
			if (string.IsNullOrWhiteSpace(path))
			{
				return false;
			}
			var invalidChars = Path.GetInvalidPathChars();
			return !path.Any(c => invalidChars.Contains(c));
		}

		/// <summary>
		/// A helper method that can invoke either .NET Framework or .NET Core's CreateDirectory method with the appropriate parameters, depending on the runtime environment.
		/// </summary>
		/// <param name="path"></param>
		/// <param name="access"></param>
		public static DirectoryInfo CreateDirectory(string path, DirectorySecurity access)
		{
#if NET8_0_OR_GREATER
			return FileSystemAclExtensions.CreateDirectory(access, path);
#else
			return Directory.CreateDirectory(path, access);
#endif
		}

		/// <summary>
		/// Obtain the security zone of a file
		/// </summary>
		/// <param name="filePath"> The path to the file</param>
		/// <returns>The security zone of a file if present, otherwise null</returns>
		/// <note>This function does not handle existence or permission tests</note>
		internal static SecurityZone? GetFileSecurityZone(string filePath)
		{
			try
			{
				foreach (var line in File.ReadAllLines(filePath + ":Zone.Identifier"))
				{
					if (line.StartsWith("ZoneId=") && Enum.TryParse<SecurityZone>(line.Substring(7), out var securityZone))
					{
						return securityZone;
					}
				}
			}
			catch
			{
			}
			return null;
		}
	}
}
