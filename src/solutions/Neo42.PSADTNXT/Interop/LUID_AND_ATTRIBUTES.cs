using System.Runtime.InteropServices;

namespace PSADTNXT.Interop
{

	[StructLayout(LayoutKind.Sequential)]
	internal struct LUID_AND_ATTRIBUTES
	{
		public LUID Luid;
		public uint Attributes;
	}
}
