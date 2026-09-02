using System;
using System.Runtime.InteropServices;

namespace PSADTNXT.Interop
{
	/// <summary>
	/// The basic limits of a job object. Retrieved with
	/// <see cref="JOBOBJECTINFOCLASS.JobObjectBasicLimitInformation"/>.
	/// </summary>
	/// <remarks>MinimumWorkingSetSize, MaximumWorkingSetSize and Affinity are pointer sized in
	/// native code, so they have to be declared as <see cref="UIntPtr"/> to keep the structure
	/// size correct on both 32 and 64 bit.</remarks>
	[StructLayout(LayoutKind.Sequential)]
	internal struct JOBOBJECT_BASIC_LIMIT_INFORMATION
	{
		public long PerProcessUserTimeLimit;
		public long PerJobUserTimeLimit;
		public JOB_OBJECT_LIMIT LimitFlags;
		public UIntPtr MinimumWorkingSetSize;
		public UIntPtr MaximumWorkingSetSize;
		public uint ActiveProcessLimit;
		public UIntPtr Affinity;
		public uint PriorityClass;
		public uint SchedulingClass;
	}
}
