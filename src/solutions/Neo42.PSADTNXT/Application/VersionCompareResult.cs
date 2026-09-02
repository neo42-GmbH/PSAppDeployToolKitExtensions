namespace PSADTNXT.Application
{
	/// <remarks>
	/// Results are mapped to CompareTo() method results.
	/// </remarks>
	public enum VersionCompareResult
	{
		Update = -1,
		Equal = 0,
		Downgrade = 1,
	}
}
