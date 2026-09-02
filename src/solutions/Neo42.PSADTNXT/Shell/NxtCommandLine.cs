using System;
using System.IO;
using System.Text;
using PSADT.ProcessManagement;
using PSADTNXT.Interop;

namespace PSADTNXT.Shell
{
	public static class NxtCommandLine
	{
		/// <summary>
		/// Searches for the full path of a binary executable in the specified target environment scope.
		/// </summary>
		/// <param name="binary">The name of the binary executable to find.</param>
		/// <param name="target">The environment variable target scope to search in (default is Process).</param>
		/// <returns>
		/// The full path to the binary executable if found; otherwise, null.
		/// </returns>
		/// <remarks>
		/// If the path is rooted, it is returned as is. If no extension is provided, ".exe" is appended.
		/// </remarks>
		public static string? SearchPath(string binary, EnvironmentVariableTarget target = EnvironmentVariableTarget.Process)
		{
			if (string.IsNullOrWhiteSpace(binary))
			{
				throw new ArgumentException("Binary name cannot be null or whitespace.", nameof(binary));
			}

			if (Path.IsPathRooted(binary))
			{
				return binary;
			}

			if (!Path.HasExtension(binary))
			{
				binary += ".exe";
			}

			var pathBuilder = new StringBuilder(260); // MAX_PATH
			return Kernel32.SearchPath(Environment.GetEnvironmentVariable("PATH", target), binary, null, (uint)pathBuilder.Capacity, pathBuilder, out _) > 0
				? pathBuilder.ToString()
				: null;
		}

		/// <summary>
		/// Finds the full path of a binary executable from a command line string.
		/// </summary>
		/// <param name="commandLine">The command line string to parse.</param>
		/// <param name="target">The environment variable target scope to search in (default is Process).</param>
		/// <returns>
		/// The full path to the binary executable if found; otherwise, null.
		/// </returns>
		/// <remarks>
		/// This method parses the command line string, extracts the first component, and searches for the binary executable in the specified environment variable target scope.
		/// If the command line string is empty or does not contain any components, it returns null.
		/// If the first component is a rooted path, it is returned as is.
		/// </remarks>
		public static string? BinaryFromCommandLine(string commandLine, EnvironmentVariableTarget target = EnvironmentVariableTarget.Process)
		{
			var components = CommandLineUtilities.CommandLineToArgumentList(commandLine);
			return components.Count > 0
				? SearchPath(components[0], target)
				: null;
		}
	}
}
