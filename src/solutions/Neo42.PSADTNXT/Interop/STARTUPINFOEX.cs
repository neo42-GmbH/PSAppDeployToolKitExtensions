using System;
using System.Runtime.InteropServices;

namespace PSADTNXT.Interop
{
	/// <summary>
	/// Extends <see cref="STARTUPINFO"/> with a process thread attribute list. Requires
	/// <see cref="CREATION_FLAGS.EXTENDED_STARTUPINFO_PRESENT"/> to be set on the creation flags.
	/// </summary>
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
	internal struct STARTUPINFOEX
	{
		public STARTUPINFO StartupInfo;
		public IntPtr lpAttributeList;
	}
}
