using System;
using System.Runtime.InteropServices;

namespace PSADTNXT.Interop
{
	internal static class Netapi32
	{
		[DllImport("Netapi32.dll", CallingConvention = CallingConvention.StdCall, EntryPoint = "DsGetDcNameW", CharSet = CharSet.Unicode)]
		public static extern int DsGetDcName(
			[In] string computerName,
			[In] string domainName,
			[In] IntPtr domainGuid,
			[In] string siteName,
			[In] uint flags,
			[Out] out IntPtr domainControllerInfo);

		[DllImport("Netapi32.dll")]
		public static extern int NetApiBufferFree([In] IntPtr buffer);
	}
}
