using System;
using System.IO;
using System.Linq;

namespace PSADTNXT.Extensions
{
	public static class NxtFileSystemInfoExtensions
	{
		/// <summary>
		/// Gets the cumulative size of the file or directory represented by the FileSystemInfo object.
		/// If the FileSystemInfo is a FileInfo, it returns the file size.
		/// If it is a DirectoryInfo, it returns the total size of all files within the directory and its subdirectories.
		/// </summary>
		public static ulong GetSize(this FileSystemInfo fileSystemInfo)
		{
			if (fileSystemInfo is FileInfo fileInfo)
			{
				return (ulong)fileInfo.Length;
			}
			else if (fileSystemInfo is DirectoryInfo directoryInfo)
			{
				return (ulong)directoryInfo.GetFiles("*", SearchOption.AllDirectories).Sum(file => file.Length);
			}
			else
			{
				throw new NotSupportedException($"Unsupported FileSystemInfo type: {fileSystemInfo.GetType()}");
			}
		}
	}
}
