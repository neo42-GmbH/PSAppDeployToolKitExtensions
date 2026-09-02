using System;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;

namespace PSADTNXT.Interop
{
	internal static class Kernel32
	{
		[DllImport("kernel32.dll")]
		public static extern bool CloseHandle(IntPtr hSnapshot);

		[DllImport("kernel32.dll")]
		public static extern IntPtr CreateToolhelp32Snapshot(uint dwFlags, uint th32ProcessID);

		[DllImport("kernel32.dll", SetLastError = true)]
		[return: MarshalAs(UnmanagedType.Bool)]
		public static extern bool Process32First(IntPtr hSnapshot, ref PROCESSENTRY32 lppe);

		[DllImport("kernel32.dll", SetLastError = true)]
		[return: MarshalAs(UnmanagedType.Bool)]
		public static extern bool Process32Next(IntPtr hSnapshot, ref PROCESSENTRY32 lppe);

		[DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
		public static extern uint SearchPath(
			string? lpPath,
			string lpFileName,
			string? lpExtension,
			uint nBufferLength,
			StringBuilder lpBuffer,
			out IntPtr lpFilePart);

		[DllImport("kernel32.dll", SetLastError = true)]
		public static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, uint dwProcessId);

		[DllImport("kernel32.dll")]
		public static extern bool GetExitCodeProcess(IntPtr hProcess, out uint lpExitCode);

		[DllImport("kernel32.dll")]
		public static extern bool ProcessIdToSessionId(uint dwProcessId, out uint pSessionId);

		[DllImport("kernel32.dll", SetLastError = true)]
		public static extern bool TerminateProcess(IntPtr hProcess, uint uExitCode);

		[DllImport("kernel32.dll")]
		public static extern uint WaitForMultipleObjects(int nCount, IntPtr[] lpHandles, bool bWaitAll, uint dwMilliseconds);

		[DllImport("kernel32.dll", SetLastError = true)]
		public static extern bool CreatePipe(out SafeFileHandle hReadPipe, out SafeFileHandle hWritePipe, ref SECURITY_ATTRIBUTES lpPipeAttributes, uint nSize);

		[DllImport("kernel32.dll", SetLastError = true)]
		public static extern bool ReadFile(SafeFileHandle hFile, [Out] byte[] lpBuffer, uint nNumberOfBytesToRead, out uint lpNumberOfBytesRead, [In, Optional] IntPtr lpOverlapped);

		[DllImport("kernel32.dll", SetLastError = true)]
		public static extern bool CancelIoEx(SafeFileHandle hFile, IntPtr lpOverlapped);

		/// <remarks>The returned pseudo handle does not have to be closed.</remarks>
		[DllImport("kernel32.dll")]
		public static extern IntPtr GetCurrentProcess();

		/// <remarks>Passing <see cref="IntPtr.Zero"/> as hJob checks whether the process is
		/// assigned to any job.</remarks>
		[DllImport("kernel32.dll", SetLastError = true)]
		[return: MarshalAs(UnmanagedType.Bool)]
		public static extern bool IsProcessInJob(IntPtr hProcess, IntPtr hJob, [MarshalAs(UnmanagedType.Bool)] out bool result);

		/// <remarks>Passing <see cref="IntPtr.Zero"/> as hJob queries the job the calling
		/// process is assigned to.</remarks>
		[DllImport("kernel32.dll", SetLastError = true)]
		[return: MarshalAs(UnmanagedType.Bool)]
		public static extern bool QueryInformationJobObject(
			IntPtr hJob,
			JOBOBJECTINFOCLASS jobObjectInformationClass,
			IntPtr lpJobObjectInformation,
			uint cbJobObjectInformationLength,
			out uint lpReturnLength);

		[DllImport("kernel32.dll", SetLastError = true)]
		public static extern bool InitializeProcThreadAttributeList(IntPtr lpAttributeList, int dwAttributeCount, int dwFlags, ref IntPtr lpSize);

		[DllImport("kernel32.dll", SetLastError = true)]
		public static extern bool UpdateProcThreadAttribute(
			IntPtr lpAttributeList,
			uint dwFlags,
			IntPtr attribute,
			IntPtr lpValue,
			IntPtr cbSize,
			IntPtr lpPreviousValue,
			IntPtr lpReturnSize);

		[DllImport("kernel32.dll")]
		public static extern void DeleteProcThreadAttributeList(IntPtr lpAttributeList);
	}
}
