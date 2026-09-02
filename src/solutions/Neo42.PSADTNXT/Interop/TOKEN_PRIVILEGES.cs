using System;
using System.Runtime.InteropServices;

namespace PSADTNXT.Interop
{
	[StructLayout(LayoutKind.Sequential)]
	internal struct TOKEN_PRIVILEGES
	{
		[Flags]
		public enum Attributes : uint
		{
			SE_PRIVILEGE_DISABLED = 0x0000,
			SE_PRIVILEGE_ENABLED_BY_DEFAULT = 0x0001,
			SE_PRIVILEGE_ENABLED = 0x0002,
			SE_PRIVILEGE_REMOVED = 0x0004,
			SE_PRIVILEGE_USED_FOR_ACCESS = 0x80000000
		}


		public uint PrivilegeCount;

		[MarshalAs(UnmanagedType.ByValArray, SizeConst = 1)]
		public LUID_AND_ATTRIBUTES[] Privileges;
	}
}
