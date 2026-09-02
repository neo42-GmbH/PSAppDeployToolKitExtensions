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
		/// </remarks>
		public static Process[] GetChildProcesses(this Process process)
		{
			var children = new List<Process>();
			var snapshot = Kernel32.CreateToolhelp32Snapshot(0x00000002, (uint)process.Id); // TH32CS_SNAPPROCESS
			try
			{
				if (snapshot == IntPtr.Zero)
				{
					throw new Win32Exception(Marshal.GetLastWin32Error());
				}

				var processEntry = new PROCESSENTRY32();
				processEntry.dwSize = (uint)Marshal.SizeOf(processEntry);
				if (Kernel32.Process32First(snapshot, ref processEntry))
				{
					do
					{
						if (processEntry.th32ParentProcessID == process.Id)
						{
							children.Add(Process.GetProcessById((int)processEntry.th32ProcessID));
						}
					} while (Kernel32.Process32Next(snapshot, ref processEntry));
				}
			}
			finally
			{
				if (snapshot != IntPtr.Zero)
				{
					Kernel32.CloseHandle(snapshot);
				}
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
			foreach (var child in process.GetChildProcesses())
			{
				child.KillTree();
			}

			process.Refresh();
			if (!process.HasExited)
			{
				process.Kill();
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
