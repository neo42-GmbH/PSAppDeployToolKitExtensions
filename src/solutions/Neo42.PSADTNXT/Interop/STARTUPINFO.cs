using System;
using System.Runtime.InteropServices;

namespace PSADTNXT.Interop
{
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
	internal struct STARTUPINFO
	{
		[Flags]
		public enum Flags : uint
		{
			STARTF_USESHOWWINDOW = 0x00000001,
			STARTF_USESIZE = 0x00000002,
			STARTF_USEPOSITION = 0x00000004,
			STARTF_USECOUNTCHARS = 0x00000008,
			STARTF_USEFILLATTRIBUTE = 0x00000010,
			STARTF_RUNFULLSCREEN = 0x00000020,
			STARTF_FORCEONFEEDBACK = 0x00000040,
			STARTF_FORCEOFFFEEDBACK = 0x00000080,
			STARTF_USESTDHANDLES = 0x00000100,
			STARTF_USEHOTKEY = 0x00000200,
			STARTF_TITLEISLINKNAME = 0x00000800,
			STARTF_TITLEISAPPID = 0x00001000,
			STARTF_PREVENTPINNING = 0x00002000,
			STARTF_UNTRUSTEDSOURCE = 0x00008000,
		}

		public int cb;
		public string lpReserved;
		public string lpDesktop;
		public string lpTitle;
		public uint dwX;
		public uint dwY;
		public uint dwXSize;
		public uint dwYSize;
		public uint dwXCountChars;
		public uint dwYCountChars;
		public uint dwFillAttribute;
		public Flags dwFlags;
		public short wShowWindow;
		public short cbReserved2;
		public IntPtr lpReserved2;
		public IntPtr hStdInput;
		public IntPtr hStdOutput;
		public IntPtr hStdError;
	}
}
