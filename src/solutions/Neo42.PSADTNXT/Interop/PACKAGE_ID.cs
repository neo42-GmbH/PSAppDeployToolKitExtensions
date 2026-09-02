using System.Runtime.InteropServices;

namespace PSADTNXT.Interop
{
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode, Pack = 4)]
	internal struct PACKAGE_ID
	{
		public uint reserved;
		public uint processorArchitecture;
		public PACKAGE_VERSION version;
		public string name;
		public string publisher;
		public string resourceId;
		public string publisherId;
	}
}
