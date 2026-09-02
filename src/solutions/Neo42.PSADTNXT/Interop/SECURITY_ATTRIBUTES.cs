using System;
using System.Runtime.InteropServices;

namespace PSADTNXT.Interop
{
	[StructLayout(LayoutKind.Sequential)]
	internal struct SECURITY_ATTRIBUTES
	{
		public uint nLength;
		public IntPtr lpSecurityDescriptor;
		public bool bInheritHandle;
	}
}
