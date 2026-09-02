using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using PSADTNXT.Interop;

namespace PSADTNXT.ProcessManagement
{
	public static class NxtProcessSecurity
	{
		/// <summary>
		/// Returns all enabled privilege names for the specified process.
		/// </summary>
		/// <param name="process">The process for which to retrieve privileges.</param>
		/// <returns>An array of privilege names.</returns>
		/// <exception cref="ArgumentNullException">Thrown if the process is null.</exception>
		/// <exception cref="Win32Exception">Thrown if there is an error accessing the process token or retrieving token information.</exception>
		public static string[] GetPrivileges(Process process)
		{
			if (process == null)
			{
				throw new ArgumentNullException(nameof(process));
			}

			string[] privileges;
			if (!Advapi32.OpenProcessToken(process.Handle, (uint)TOKEN_ACCESS_RIGHTS.TokenQuery, out var processToken))
			{
				throw new Win32Exception(Marshal.GetLastWin32Error());
			}
			try
			{
				privileges = GetPrivileges(processToken);
			}
			finally
			{
				Kernel32.CloseHandle(processToken);
			}

			return privileges;
		}

		/// <summary>
		/// Returns all enabled privilege names for the current process.
		/// </summary>
		/// <returns>An array of privilege names.</returns>
		/// <exception cref="Win32Exception">Thrown if there is an error accessing the process token or retrieving token information.</exception>
		public static string[] GetPrivileges()
		{
			return GetPrivileges(Process.GetCurrentProcess());
		}

		/// <summary>
		/// Adds specified privileges to the process token of the current process.
		/// </summary>
		/// <param name="privilegeNames">A collection of privilege names to add.</param>
		/// <exception cref="ArgumentException">Thrown if privilegeNames is null or empty.</exception>
		/// <exception cref="ArgumentNullException">Thrown if process is null.</exception>
		/// <exception cref="Win32Exception">Thrown if there is an error accessing the process token or adjusting privileges.</exception>
		/// <remarks>
		/// This method retrieves the process token of the current process, checks for existing privileges, and adds any missing privileges specified in privilegeNames.
		/// </remarks>
		public static void AddPrivileges(Process process, ICollection<string> privilegeNames)
		{
			if (process == null)
			{
				throw new ArgumentNullException(nameof(process));
			}

			if (privilegeNames == null || privilegeNames.Count == 0)
			{
				return;
			}

			if (!Advapi32.OpenProcessToken(process.Handle, (uint)TOKEN_ACCESS_RIGHTS.TokenAdjustPrivileges | (uint)TOKEN_ACCESS_RIGHTS.TokenQuery, out var processToken))
			{
				throw new Win32Exception(Marshal.GetLastWin32Error());
			}
			try
			{
				var currentPriviliges = GetPrivileges(processToken);
				var missingPriviliges = privilegeNames.Except(currentPriviliges).ToList();
				if (missingPriviliges.Count > 0)
				{
					AdjustPrivileges(processToken, missingPriviliges, true);
				}
			}
			finally
			{
				Kernel32.CloseHandle(processToken);
			}
		}

		/// <summary>
		/// Adds specified privileges to the process token of the current process.
		/// </summary>
		/// <param name="privilegeNames">A collection of privilege names to add.</param>
		/// <exception cref="ArgumentException">Thrown if privilegeNames is null or empty.</exception>
		/// <exception cref="Win32Exception">Thrown if there is an error accessing the process token or adjusting privileges.</exception>
		/// <remarks>
		/// This method retrieves the process token of the current process, checks for existing privileges, and adds any missing privileges specified in privilegeNames.
		/// </remarks>
		public static void AddPrivileges(ICollection<string> privilegeNames) => AddPrivileges(Process.GetCurrentProcess(), privilegeNames);

		/// <summary>
		/// Removes specified privileges from the process token of the current process.
		/// </summary>
		/// <param name="process">The process from which to remove privileges.</param>
		/// <param name="privilegeNames">A collection of privilege names to remove.</param>
		/// <exception cref="ArgumentException">Thrown if privilegeNames is null or empty.</exception>
		/// <exception cref="ArgumentNullException">Thrown if process is null.</exception>
		/// <exception cref="Win32Exception">Thrown if there is an error accessing the process token or adjusting privileges.</exception>
		/// <remarks>
		/// This method retrieves the process token of the specified process, checks for existing privileges, and removes any privileges specified in privilegeNames that are currently enabled.
		/// </remarks>
		public static void RemovePrivileges(Process process, ICollection<string> privilegeNames)
		{
			if (process == null)
			{
				throw new ArgumentNullException(nameof(process));
			}

			if (privilegeNames == null || privilegeNames.Count == 0)
			{
				return;
			}

			if (!Advapi32.OpenProcessToken(process.Handle, (uint)TOKEN_ACCESS_RIGHTS.TokenAdjustPrivileges | (uint)TOKEN_ACCESS_RIGHTS.TokenQuery, out var processToken))
			{
				throw new Win32Exception(Marshal.GetLastWin32Error());
			}
			try
			{
				var currentPriviliges = GetPrivileges(processToken);
				var existingPriviliges = privilegeNames.Intersect(currentPriviliges).ToList();
				if (existingPriviliges.Count > 0)
				{
					AdjustPrivileges(processToken, existingPriviliges, false);
				}
			}
			finally
			{
				Kernel32.CloseHandle(processToken);
			}
		}

		/// <summary>
		/// Removes specified privileges from the process token of the current process.
		/// </summary>
		/// <param name="process">The process from which to remove privileges.</param>
		/// <param name="privilegeNames">A collection of privilege names to remove.</param>
		/// <exception cref="ArgumentException">Thrown if privilegeNames is null or empty.</exception>
		/// <exception cref="Win32Exception">Thrown if there is an error accessing the process token or adjusting privileges.</exception>
		/// <remarks>
		/// This method retrieves the process token of the specified process, checks for existing privileges, and removes any privileges specified in privilegeNames that are currently enabled.
		/// </remarks>
		public static void RemovePrivileges(ICollection<string> privilegeNames)
		{
			RemovePrivileges(Process.GetCurrentProcess(), privilegeNames);
		}

		/// <summary>
		/// Returns all enabled privilege names for the specified process handle.
		/// </summary>
		/// <param name="processHandle">Handle to the process for which privileges are being queried.</param>
		/// <returns>An array of privilege names.</returns>
		/// <exception cref="Win32Exception">Thrown if there is an error accessing the process token or retrieving token information.</exception>
		private static string[] GetPrivileges(IntPtr processToken)
		{
			var privileges = new List<string>();
			var tokenInfoLength = 0u;
			var tokenInfoPtr = IntPtr.Zero;
			Advapi32.GetTokenInformation(processToken, TOKEN_INFORMATION_CLASS.TokenPrivileges, IntPtr.Zero, 0, ref tokenInfoLength);
			var lastError = Marshal.GetLastWin32Error();
			if (lastError is not 122 and not 0) // ERROR_INSUFFICIENT_BUFFER is expected
			{
				throw new Win32Exception(lastError);
			}

			try
			{
				// Second call to get the actual data
				tokenInfoPtr = Marshal.AllocHGlobal((int)tokenInfoLength);
				if (!Advapi32.GetTokenInformation(processToken, TOKEN_INFORMATION_CLASS.TokenPrivileges, tokenInfoPtr, tokenInfoLength, ref tokenInfoLength))
				{
					throw new Win32Exception(Marshal.GetLastWin32Error());
				}

				// Read the privilege count from the beginning of the structure
				var privilegeCount = (uint)Marshal.ReadInt32(tokenInfoPtr);

				// Calculate the offset to the first privilege (after the PrivilegeCount field)
				var privilegesPtr = IntPtr.Add(tokenInfoPtr, sizeof(uint));
				for (uint i = 0; i < privilegeCount; i++)
				{
					// Calculate offset for the current privilege
					var currentPrivilegePtr = IntPtr.Add(privilegesPtr, (int)(i * Marshal.SizeOf<LUID_AND_ATTRIBUTES>()));

					// Read the LUID_AND_ATTRIBUTES structure
					var privilege = Marshal.PtrToStructure<LUID_AND_ATTRIBUTES>(currentPrivilegePtr);
					var luid = privilege.Luid;

					// Skip if the privilege is not enabled
					if ((privilege.Attributes & (uint)TOKEN_PRIVILEGES.Attributes.SE_PRIVILEGE_ENABLED) == 0)
					{
						continue;
					}

					// Get the name of the privilege
					// First call to get the required buffer size
					uint nameLength = 0;
					Advapi32.LookupPrivilegeName(null, ref luid, null, ref nameLength);

					// Second call with proper buffer size
					var nameBuffer = new StringBuilder((int)nameLength);
					if (!Advapi32.LookupPrivilegeName(null, ref luid, nameBuffer, ref nameLength))
					{
						throw new Win32Exception(Marshal.GetLastWin32Error());
					}

					privileges.Add(nameBuffer.ToString());
				}
			}
			finally
			{
				// Free the allocated memory
				if (tokenInfoPtr != IntPtr.Zero)
				{
					Marshal.FreeHGlobal(tokenInfoPtr);
				}
			}

			return [.. privileges];
		}

		/// <summary>
		/// Enables or disables specified privileges for the given token.
		/// </summary>
		/// <param name="processToken">Handle to the token for which privileges are being adjusted.</param>
		/// <param name="privilegeNames">Collection of privilege names to adjust.</param>
		/// <param name="enable">True to enable the privileges, false to disable them.</param>
		/// <exception cref="ArgumentException">Thrown if privilegeNames is null or empty.</exception>
		/// <exception cref="Win32Exception">Thrown if there is an error adjusting the privileges.</exception>
		/// <remarks>Privileges that are not present in the token are silently skipped by the system, so the
		/// caller has to re-query the token to find out which of the requested privileges are now enabled.</remarks>
		private static void AdjustPrivileges(IntPtr processToken, ICollection<string> privilegeNames, bool enable)
		{
			if (privilegeNames == null || privilegeNames.Count == 0)
			{
				throw new ArgumentException("Privilege names cannot be null or empty.", nameof(privilegeNames));
			}

			// TOKEN_PRIVILEGES holds a variable length array of privileges, so the structure has to be
			// marshalled by hand as the managed declaration can only ever carry a single entry.
			var attributes = enable ? (uint)TOKEN_PRIVILEGES.Attributes.SE_PRIVILEGE_ENABLED : (uint)TOKEN_PRIVILEGES.Attributes.SE_PRIVILEGE_DISABLED;
			var entrySize = Marshal.SizeOf<LUID_AND_ATTRIBUTES>();
			var bufferSize = sizeof(uint) + (entrySize * privilegeNames.Count);
			var bufferPtr = Marshal.AllocHGlobal(bufferSize);
			try
			{
				// Write the privilege count followed by one LUID_AND_ATTRIBUTES per privilege
				Marshal.WriteInt32(bufferPtr, privilegeNames.Count);
				var index = 0;
				foreach (var privilegeName in privilegeNames)
				{
					var luid = new LUID();
					if (!Advapi32.LookupPrivilegeValue(IntPtr.Zero, privilegeName, ref luid))
					{
						throw new Win32Exception(Marshal.GetLastWin32Error());
					}

					var entry = new LUID_AND_ATTRIBUTES
					{
						Luid = luid,
						Attributes = attributes
					};
					Marshal.StructureToPtr(entry, IntPtr.Add(bufferPtr, sizeof(uint) + (index * entrySize)), false);
					index++;
				}

				if (!Advapi32.AdjustTokenPrivileges(processToken, false, bufferPtr, bufferSize, IntPtr.Zero, IntPtr.Zero))
				{
					throw new Win32Exception(Marshal.GetLastWin32Error());
				}
			}
			finally
			{
				Marshal.FreeHGlobal(bufferPtr);
			}
		}
	}
}
