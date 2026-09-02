namespace PSADTNXT.Interop
{
#pragma warning disable CA1712
	/// <summary>
	/// Identifies the attributes that can be set on a process thread attribute list.
	/// </summary>
	/// <remarks>The values are the result of the ProcThreadAttributeValue macro from processthreadsapi.h,
	/// which combines the attribute number with the thread, input and additive markers.</remarks>
	internal enum PROC_THREAD_ATTRIBUTE : uint
	{
		/// <summary>
		/// The attribute value is a list of handles that the child process is allowed to inherit,
		/// limiting inheritance to those handles instead of every inheritable handle of the caller.
		/// </summary>
		PROC_THREAD_ATTRIBUTE_HANDLE_LIST = 0x00020002,

		/// <summary>
		/// The attribute value is a combination of <see cref="EXTENDED_PROCESS_CREATION_FLAG"/> values.
		/// </summary>
		PROC_THREAD_ATTRIBUTE_EXTENDED_FLAGS = 0x00060010,
	}
#pragma warning restore CA1712
}
