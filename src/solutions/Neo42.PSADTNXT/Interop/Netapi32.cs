using System;
using System.Runtime.InteropServices;

namespace PSADTNXT.Interop
{
	internal static class Netapi32
	{
		[DllImport("Netapi32.dll", EntryPoint = "NetGetJoinInformation", CharSet = CharSet.Unicode), DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
		public static extern int NetGetJoinInformation(
			[In] string? server,
			[Out] out IntPtr nameBuffer,
			[Out] out NETSETUP_JOIN_STATUS bufferType);

		[DllImport("Netapi32.dll"), DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
		public static extern int NetApiBufferFree([In] IntPtr buffer);
	}
}
