using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Security.Principal;
using PSADTNXT.Interop;

namespace PSADTNXT.Extensions
{
	public static class NxtProcessExtensions
	{
		/// <summary>
		/// Checks if the process is running with elevated privileges.
		/// </summary>
		/// <param name="process">The process to check.</param>
		/// <returns>True if the process is elevated, otherwise false.</returns>
		/// <exception cref="Win32Exception">Thrown if there is an error retrieving the process token or token information.</exception>
		public static bool IsElevated(this Process process)
		{
			// Use Advapi32 to open the process token with query access
			if (!Advapi32.OpenProcessToken(process.Handle, (uint)TOKEN_ACCESS_RIGHTS.TokenQuery, out var tokenHandle))
			{
				throw new Win32Exception(Marshal.GetLastWin32Error());
			}

			try
			{
				// Allocate memory for the TOKEN_ELEVATION structure
				var tokenInfoPtr = Marshal.AllocHGlobal(Marshal.SizeOf<TOKEN_ELEVATION>());
				try
				{
					// Get the token information
					var returnLength = 0u;
					if (!Advapi32.GetTokenInformation(tokenHandle, TOKEN_INFORMATION_CLASS.TokenElevation, tokenInfoPtr, (uint)Marshal.SizeOf<TOKEN_ELEVATION>(), ref returnLength))
					{
						throw new Win32Exception(Marshal.GetLastWin32Error());
					}

					// Marshal the data into a TOKEN_ELEVATION structure
					var elevation = Marshal.PtrToStructure<TOKEN_ELEVATION>(tokenInfoPtr);
					return elevation.TokenIsElevated != 0;
				}
				finally
				{
					Marshal.FreeHGlobal(tokenInfoPtr);
				}
			}
			finally
			{
				if (tokenHandle != IntPtr.Zero)
				{
					Kernel32.CloseHandle(tokenHandle);
				}
			}
		}

		/// <summary>
		/// Gets the child processes of the specified process.
		/// </summary>
		/// <param name="process">The process to get the children of.</param>
		/// <returns>An array of child processes.</returns>
		/// <exception cref="Win32Exception">Thrown if there is an error retrieving the child processes.</exception>
		/// <remarks>
		/// Only obtains direct children, not grandchildren or deeper descendants.
		/// Windows does not clear the parent id when a parent exits, so processes that started before the given process
		/// are not returned, as they belong to a previous process with the same (reused) id.
		/// </remarks>
		public static Process[] GetChildProcesses(this Process process)
		{
			var children = new List<Process>();
			var parentStartTime = TryGetStartTime(process);
			var snapshot = Kernel32.CreateToolhelp32Snapshot(0x00000002, (uint)process.Id); // TH32CS_SNAPPROCESS
			if (snapshot == IntPtr.Zero || snapshot == INVALID_HANDLE_VALUE)
			{
				throw new Win32Exception(Marshal.GetLastWin32Error());
			}

			try
			{
				var processEntry = new PROCESSENTRY32();
				processEntry.dwSize = (uint)Marshal.SizeOf(processEntry);
				if (Kernel32.Process32First(snapshot, ref processEntry))
				{
					do
					{
						// A process cannot be its own child, e.g. the idle process (0) reports itself as its parent
						if (processEntry.th32ParentProcessID != process.Id || processEntry.th32ProcessID == process.Id)
						{
							continue;
						}

						Process child;
						try
						{
							child = Process.GetProcessById((int)processEntry.th32ProcessID);
						}
						catch (ArgumentException)
						{
							// The process exited after the snapshot was taken
							continue;
						}

						// A real child cannot have started before its parent. If the parent start time is unknown, the child is accepted.
						if (parentStartTime is DateTime parentStart && !(TryGetStartTime(child) is DateTime childStart && childStart >= parentStart))
						{
							child.Dispose();
							continue;
						}

						children.Add(child);
					} while (Kernel32.Process32Next(snapshot, ref processEntry));
				}
			}
			finally
			{
				Kernel32.CloseHandle(snapshot);
			}
			return [.. children];
		}

		/// <summary>
		/// Recursively kills the process and all its child processes.
		/// </summary>
		/// <param name="process">The process to kill.</param>
		/// <remarks>
		/// An implementation of Process.Kill(bool entireProcessTree) for .NET Framework.
		/// </remarks>
		public static void KillTree(this Process process)
		{
			KillTree(process, new HashSet<int>());
		}

		private static void KillTree(Process process, HashSet<int> visited)
		{
			// Guard against cycles in the reported parent ids
			if (!visited.Add(process.Id))
			{
				return;
			}

			foreach (var child in process.GetChildProcesses())
			{
				KillTree(child, visited);
			}

			process.Refresh();
			if (!process.HasExited)
			{
				process.Kill();
			}
		}

		private static readonly IntPtr INVALID_HANDLE_VALUE = new(-1);

		private static DateTime? TryGetStartTime(Process process)
		{
			try
			{
				return process.StartTime;
			}
			catch (Exception ex) when (ex is Win32Exception or InvalidOperationException or NotSupportedException)
			{
				// Access denied or the process has already exited
				return null;
			}
		}

		[Obsolete("Implemented in PSADT 4.2")]
		public static WindowsIdentity GetOwner(this Process process)
		{
			if (!Advapi32.OpenProcessToken(process.Handle, (uint)TOKEN_ACCESS_RIGHTS.TokenQuery, out var tokenHandle))
			{
				throw new Win32Exception(Marshal.GetLastWin32Error());
			}
			try
			{
				return new WindowsIdentity(tokenHandle);
			}
			finally
			{
				if (tokenHandle != IntPtr.Zero)
				{
					Kernel32.CloseHandle(tokenHandle);
				}
			}
		}
	}
}
