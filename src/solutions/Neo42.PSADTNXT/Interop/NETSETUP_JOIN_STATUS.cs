namespace PSADTNXT.Interop
{
	/// <summary>
	/// The join status of a computer, as reported by <see cref="Netapi32.NetGetJoinInformation"/>.
	/// </summary>
#pragma warning disable CA1008, CA1712
	internal enum NETSETUP_JOIN_STATUS
	{
		/// <summary>
		/// The status is unknown.
		/// </summary>
		NetSetupUnknownStatus = 0,

		/// <summary>
		/// The computer is not joined.
		/// </summary>
		NetSetupUnjoined = 1,

		/// <summary>
		/// The computer is joined to a workgroup.
		/// </summary>
		NetSetupWorkgroupName = 2,

		/// <summary>
		/// The computer is joined to a domain.
		/// </summary>
		NetSetupDomainName = 3,
	}
#pragma warning restore CA1008, CA1712
}
