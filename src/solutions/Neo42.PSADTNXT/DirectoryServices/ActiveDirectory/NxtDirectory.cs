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
		/// Gets the NetBIOS name of a domain given its DNS name by calling the DsGetDcName function from the Windows API.
		/// </summary>
		/// <param name="dnsName">The DNS name of the domain for which to retrieve the NetBIOS name.</param>
		/// <returns>The NetBIOS name of the specified domain.</returns>
		/// <exception cref="Win32Exception">Thrown when the underlying Windows API call fails.</exception>
		public static string GetNetbiosNameForDomain(string dnsName)
		{
			var result = Netapi32.DsGetDcName("", dnsName, IntPtr.Zero, "", 0x80020000, out var pDomainInfo);
			try
			{
				if (result != 0)
				{
					throw new Win32Exception(result);
				}
				var dcinfo = Marshal.PtrToStructure<DOMAIN_CONTROLLER_INFO>(pDomainInfo);
				return dcinfo.DomainName ?? string.Empty;
			}
			finally
			{
				if (pDomainInfo != IntPtr.Zero)
				{
					_ = Netapi32.NetApiBufferFree(pDomainInfo);
				}
			}
		}
	}
}
