using System.Runtime.InteropServices;

namespace PSADTNXT.Interop
{
	[StructLayout(LayoutKind.Sequential)]
	internal struct LUID
	{
		public uint LowPart;
		public uint HighPart;
	}
}
