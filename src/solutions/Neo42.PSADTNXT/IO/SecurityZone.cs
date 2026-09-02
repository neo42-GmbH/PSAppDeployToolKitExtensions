namespace PSADTNXT.IO
{
	// https://learn.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/platform-apis/ms537175(v=vs.85)
	internal enum SecurityZone
	{
		URLZONE_INVALID = -1,
		URLZONE_LOCAL_MACHINE = 0,
		URLZONE_INTRANET = 1,
		URLZONE_TRUSTED = 2,
		URLZONE_INTERNET = 3,
		URLZONE_UNTRUSTED = 4
	}
}
