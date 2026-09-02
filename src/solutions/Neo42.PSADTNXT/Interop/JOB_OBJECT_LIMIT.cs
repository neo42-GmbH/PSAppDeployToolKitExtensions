using System;

namespace PSADTNXT.Interop
{
	/// <summary>
	/// The limits which are in effect for a job object, as reported by
	/// <see cref="JOBOBJECT_BASIC_LIMIT_INFORMATION.LimitFlags"/>.
	/// </summary>
	/// <remarks>Only the members required to determine whether a process may leave the job are declared.</remarks>
#pragma warning disable CA1008, CA1712
	[Flags]
	internal enum JOB_OBJECT_LIMIT : uint
	{
		/// <summary>
		/// A child process created with CREATE_BREAKAWAY_FROM_JOB is not assigned to the job.
		/// </summary>
		JOB_OBJECT_LIMIT_BREAKAWAY_OK = 0x00000800,

		/// <summary>
		/// A child process is not assigned to the job, regardless of whether
		/// CREATE_BREAKAWAY_FROM_JOB was requested.
		/// </summary>
		JOB_OBJECT_LIMIT_SILENT_BREAKAWAY_OK = 0x00001000,
	}
#pragma warning restore CA1008, CA1712
}
