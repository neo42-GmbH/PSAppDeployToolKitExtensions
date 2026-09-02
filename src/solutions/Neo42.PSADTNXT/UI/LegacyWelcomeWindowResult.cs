namespace PSADTNXT.UI
{
#pragma warning disable CA1008
	public enum LegacyWelcomeWindowCodes
#pragma warning restore CA1008
	{
		/// <summary>
		/// The user requested that applications should be closed.
		/// </summary>
		Close = 1001,

		/// <summary>
		/// The user requested that the deployment should be deferred.
		/// </summary>
		Defer = 1003,

		/// <summary>
		/// The dialog timed out.
		/// </summary>
		Timeout = 1004,

		/// <summary>
		/// The dialog closed automatically because all conditions were met.
		/// </summary>
		Continue = 1005
	}
}
