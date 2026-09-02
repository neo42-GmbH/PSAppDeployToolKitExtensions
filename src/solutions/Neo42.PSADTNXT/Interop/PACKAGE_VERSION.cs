using System.Runtime.InteropServices;

namespace PSADTNXT.Interop
{
	[StructLayout(LayoutKind.Explicit)]
	internal struct PACKAGE_VERSION
	{
		[FieldOffset(0)]
		public ulong Version;
		[FieldOffset(0)]
		public ushort Revision;
		[FieldOffset(2)]
		public ushort Build;
		[FieldOffset(4)]
		public ushort Minor;
		[FieldOffset(6)]
		public ushort Major;
	}
}
