using System;
using System.Runtime.InteropServices;
using System.Text;

namespace PSADTNXT.Interop
{
	internal static class Advapi32
	{
		[DllImport("Advapi32.dll", SetLastError = true), DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
		public static extern bool OpenProcessToken(IntPtr processHandle, uint desiredAccess, out IntPtr tokenHandle);

		[DllImport("Advapi32.dll", SetLastError = true), DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
		[return: MarshalAs(UnmanagedType.Bool)]
		public static extern bool GetTokenInformation(
			IntPtr tokenHandle,
			TOKEN_INFORMATION_CLASS tokenInformationClass,
			IntPtr tokenInformation,
			uint tokenInformationLength,
			ref uint returnLength);

		[DllImport("Advapi32.dll", SetLastError = true), DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
		public static extern bool AdjustTokenPrivileges(
			IntPtr tokenHandle,
			bool disableAllPrivileges,
			IntPtr newState,
			int bufferLength,
			IntPtr previousState,
			IntPtr returnLength);

		[DllImport("Advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode), DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
		public static extern bool CreateProcessAsUser(
			IntPtr hToken,
			string lpApplicationName,
			string lpCommandLine,
			IntPtr lpProcessAttributes,
			IntPtr lpThreadAttributes,
			bool bInheritHandle,
			uint dwCreationFlags,
			IntPtr lpEnvironment,
			string? lpCurrentDirectory,
			ref STARTUPINFOEX lpStartupInfo,
			out PROCESS_INFORMATION lpProcessInformation);

		[DllImport("Advapi32.dll", SetLastError = true), DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
		public static extern bool DuplicateTokenEx(
			IntPtr existingToken,
			uint desiredAccess,
			IntPtr tokenAttributes,
			SECURITY_IMPERSONATION_LEVEL impersonationLevel,
			TOKEN_TYPE tokenType,
			out IntPtr newToken);

		[DllImport("Advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode), DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
		public static extern bool LookupPrivilegeValue(IntPtr lpSystemName, string lpname, [MarshalAs(UnmanagedType.Struct)] ref LUID lpLuid);

		[DllImport("Advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode), DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
		[return: MarshalAs(UnmanagedType.Bool)]
		public static extern bool LookupPrivilegeName(string? lpSystemName, ref LUID lpLuid, StringBuilder? lpName, ref uint cchName);

		[DllImport("Advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode), DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
		public static extern int RegQueryInfoKey(
			IntPtr hkey,
			out StringBuilder lpClass,
			ref uint lpcbClass,
			IntPtr lpReserved,
			out uint lpcSubKeys,
			out uint lpcbMaxSubKeyLen,
			out uint lpcbMaxClassLen,
			out uint lpcValues,
			out uint lpcbMaxValueNameLen,
			out uint lpcbMaxValueLen,
			out uint lpcbSecurityDescriptor,
			ref System.Runtime.InteropServices.ComTypes.FILETIME lpftLastWriteTime);
	}
}
