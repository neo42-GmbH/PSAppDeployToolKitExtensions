using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using PSADTNXT.Interop;

namespace PSADTNXT.DirectoryServices.ActiveDirectory
{
	/// <summary>
	/// Provides helper methods for working with Active Directory and related directory services in the context of PSADTNXT.
	/// </summary>
	public static class NxtDirectory
	{
		/// <summary>
		/// Gets the NetBIOS name of the domain the local computer is joined to by calling the NetGetJoinInformation function from the Windows API.
		/// </summary>
		/// <remarks>
		/// The information is read from the local join state, so no line of sight to a domain controller is required.
		/// </remarks>
		/// <returns>The NetBIOS name of the computer's domain, or <see langword="null"/> if the computer is not joined to a domain.</returns>
		/// <exception cref="Win32Exception">Thrown when the underlying Windows API call fails.</exception>
		public static string? GetComputerDomainNetbiosName()
		{
			var result = Netapi32.NetGetJoinInformation(null, out var pNameBuffer, out var joinStatus);
			try
			{
				if (result != 0)
				{
					throw new Win32Exception(result);
				}
				if (joinStatus != NETSETUP_JOIN_STATUS.NetSetupDomainName)
				{
					return null;
				}
				return Marshal.PtrToStringUni(pNameBuffer);
			}
			finally
			{
				if (pNameBuffer != IntPtr.Zero)
				{
					_ = Netapi32.NetApiBufferFree(pNameBuffer);
				}
			}
		}
	}
}
