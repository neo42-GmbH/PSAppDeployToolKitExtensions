using System.Runtime.InteropServices;

namespace PSADTNXT.Interop
{
	[StructLayout(LayoutKind.Sequential)]
	internal struct TOKEN_ELEVATION
	{
		public uint TokenIsElevated;
	}
}
