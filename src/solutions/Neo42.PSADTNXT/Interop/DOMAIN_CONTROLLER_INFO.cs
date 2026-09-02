using System;
using System.Runtime.InteropServices;

namespace PSADTNXT.Interop
{
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
	internal struct DOMAIN_CONTROLLER_INFO
	{
		public string DomainControllerName;
		public string DomainControllerAddress;
		public int DomainControllerAddressType;
		public Guid DomainGuid;
		public string DomainName;
		public string DnsForestName;
		public int Flags;
		public string DcSiteName;
		public string ClientSiteName;
	}
}

