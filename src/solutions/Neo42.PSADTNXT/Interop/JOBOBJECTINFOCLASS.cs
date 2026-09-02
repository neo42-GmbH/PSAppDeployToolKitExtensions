namespace PSADTNXT.Interop
{
	/// <summary>
	/// Identifies the information class to be queried from or set on a job object.
	/// </summary>
	internal enum JOBOBJECTINFOCLASS
	{
		/// <summary>
		/// The information is a <see cref="JOBOBJECT_BASIC_LIMIT_INFORMATION"/> structure.
		/// </summary>
		JobObjectBasicLimitInformation = 2,
	}
}
