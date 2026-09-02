using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using Microsoft.Win32.SafeHandles;
using PSADT.ProcessManagement;
using PSADTNXT.Interop;

namespace PSADTNXT.ProcessManagement
{
	public static class NxtSessionHelper
	{
		private const uint GENERIC_ALL = 0x10000000;
		private const ulong WAIT_TIMEOUT = 0x00000102L;
		private const uint ERROR_BROKEN_PIPE = 109;
		private const int ERROR_INSUFFICIENT_BUFFER = 122;
		private const string SE_TCB_PRIVILEGE = "SeTcbPrivilege";
		private static readonly List<string> _sePrivs = ["SeDebugPrivilege", "SeAssignPrimaryTokenPrivilege", "SeIncreaseQuotaPrivilege"];

		public static ProcessResult StartProcessInSessions(string file, string arguments, ICollection<uint> sessionIds, TimeSpan timeout)
		{
			if (string.IsNullOrWhiteSpace(file))
			{
				throw new ArgumentNullException(nameof(file));
			}

			var handler = new List<IntPtr>();
			var processes = new List<ProcessContainer>();
			var extraPrivileges = _sePrivs.Except(NxtProcessSecurity.GetPrivileges()).ToList();
			var securityAttributes = new SECURITY_ATTRIBUTES
			{
				nLength = (uint)Marshal.SizeOf<SECURITY_ATTRIBUTES>(),
				lpSecurityDescriptor = IntPtr.Zero,
				bInheritHandle = true
			};

			try
			{
				// Add potentially missing privileges to the current process
				NxtProcessSecurity.AddPrivileges(extraPrivileges);

				// A process started in another session has to leave the job object of the current process.
				// When that job denies breakaway, the creation has to be forced. The extended flag is only
				// requested when it is actually needed, as it is undocumented and would otherwise fail
				// every invocation on systems not supporting it.
				var forceBreakaway = IsJobBreakawayDenied();
				if (forceBreakaway && !NxtProcessSecurity.GetPrivileges().Contains(SE_TCB_PRIVILEGE))
				{
					// Forcing a process out of a job object requires SeTcbPrivilege, which is only enabled
					// when it is needed to keep the window in which the current process holds it short.
					extraPrivileges.Add(SE_TCB_PRIVILEGE);
					NxtProcessSecurity.AddPrivileges([SE_TCB_PRIVILEGE]);

					// Privileges which are not part of the token cannot be enabled, so the token has to be
					// re-queried to find out whether the privilege is held now.
					if (!NxtProcessSecurity.GetPrivileges().Contains(SE_TCB_PRIVILEGE))
					{
						throw new InvalidOperationException("Could not start process in another session: the current process is assigned to a job object which does not permit breakaway and SeTcbPrivilege is not held.");
					}
				}

				// Iterate through each session ID and start the process
				foreach (var sessionId in sessionIds)
				{
					// Search for a suitable process in the session. Prefer explorer as it
					var sourceProcess = Process.GetProcessesByName("explorer").FirstOrDefault(p => p.SessionId == sessionId)
						?? Process.GetProcessesByName("winlogon").FirstOrDefault(p => p.SessionId == sessionId)
						?? throw new Exception($"Could not find suitable process in session {sessionId}");

					// Create a copy of the token from the source process
					if (!Advapi32.OpenProcessToken(sourceProcess.Handle, (uint)TOKEN_ACCESS_RIGHTS.All, out var sourceProcessTokenPtr))
					{
						throw new Win32Exception(Marshal.GetLastWin32Error());
					}

					handler.Add(sourceProcessTokenPtr);
					if (!Advapi32.DuplicateTokenEx(sourceProcessTokenPtr, GENERIC_ALL, IntPtr.Zero, SECURITY_IMPERSONATION_LEVEL.SecurityImpersonation, TOKEN_TYPE.TokenPrimary, out var sessionProcessTokenPtr))
					{
						throw new Win32Exception(Marshal.GetLastWin32Error());
					}

					handler.Add(sessionProcessTokenPtr);

					// Create pipes for stdout and stderr
					if (!Kernel32.CreatePipe(out var hReadOut, out var hWriteOut, ref securityAttributes, 4096))
					{
						throw new Win32Exception(Marshal.GetLastWin32Error());
					}

					if (!Kernel32.CreatePipe(out var hReadErr, out var hWriteErr, ref securityAttributes, 4096))
					{
						hReadOut.Dispose();
						hWriteOut.Dispose();
						throw new Win32Exception(Marshal.GetLastWin32Error());
					}

					// The container owns the pipe handles and closes them in the finally block. They must
					// not be added to the raw handle list as well, as closing a handle twice can tear down
					// an unrelated handle which has meanwhile been assigned the same value.
					var process = new ProcessContainer
					{
						StdOutReadHandle = hReadOut,
						StdOutWriteHandle = hWriteOut,
						StdErrReadHandle = hReadErr,
						StdErrWriteHandle = hWriteErr
					};
					processes.Add(process);

					// Read both pipes on background threads. The threads append to the collections of the
					// container, so the output is available once they have been joined.
					process.StdOutThread = StartPipeReader(process.StdOutReadHandle, process.StdOutLines, process.InterleavedLines);
					process.StdErrThread = StartPipeReader(process.StdErrReadHandle, process.StdErrLines, process.InterleavedLines);

					// Start the process in the session. The extended startup information restricts handle
					// inheritance to the pipes of this process and, if the job object of the current process
					// denies breakaway, forces the created process out of that job.
					var creationAttributes = (uint)(CREATION_FLAGS.CREATE_NO_WINDOW | CREATION_FLAGS.CREATE_BREAKAWAY_FROM_JOB | CREATION_FLAGS.CREATE_UNICODE_ENVIRONMENT | CREATION_FLAGS.EXTENDED_STARTUPINFO_PRESENT);
					var startupInfo = new STARTUPINFOEX
					{
						StartupInfo = new STARTUPINFO
						{
							cb = Marshal.SizeOf<STARTUPINFOEX>(),
							dwFlags = STARTUPINFO.Flags.STARTF_USESTDHANDLES,
							hStdInput = IntPtr.Zero,
							hStdOutput = hWriteOut.DangerousGetHandle(),
							hStdError = hWriteErr.DangerousGetHandle()
						}
					};
					var pi = new PROCESS_INFORMATION();
					bool result;
					int lastError;
					using (var attributeList = ProcThreadAttributeList.Create([hWriteOut.DangerousGetHandle(), hWriteErr.DangerousGetHandle()], forceBreakaway))
					{
						startupInfo.lpAttributeList = attributeList.Handle;
						result = Advapi32.CreateProcessAsUser(sessionProcessTokenPtr, file, arguments, IntPtr.Zero, IntPtr.Zero, true, creationAttributes, IntPtr.Zero, null, ref startupInfo, out pi);
						lastError = Marshal.GetLastWin32Error();
					}

					handler.AddRange([pi.hThread, pi.hProcess]);
					if (!result)
					{
						throw new Win32Exception(lastError, $"Could not start process in session {sessionId}: {new Win32Exception(lastError).Message}");
					}

					process.ProcessHandle = pi.hProcess;

					// The created process inherited its own copies of the writing ends, so the copies of
					// this process have to be closed. Otherwise the pipes would never reach their end and
					// the reader threads would keep waiting after the created process has exited.
					process.StdOutWriteHandle.Dispose();
					process.StdErrWriteHandle.Dispose();
				}

				var exitCode = 1618u;
				var processHandles = processes.Select(p => p.ProcessHandle).ToArray();

				var index = Kernel32.WaitForMultipleObjects(processHandles.Length, processHandles, false, (uint)timeout.TotalMilliseconds);

				// Terminate all processes except the one that returned
				processHandles.Where((_, i) => i != index).ToList().ForEach(pHandle => Kernel32.TerminateProcess(pHandle, exitCode));

				// Every process has exited by now, so all reader threads reach the end of their pipe and
				// can be joined. Draining them before the reading ends are closed in the finally block
				// keeps the threads from failing on a handle which has already been released.
				foreach (var startedProcess in processes)
				{
					JoinPipeReader(startedProcess.StdOutThread, startedProcess.StdOutReadHandle);
					JoinPipeReader(startedProcess.StdErrThread, startedProcess.StdErrReadHandle);
				}

				if (index == WAIT_TIMEOUT)
				{
					throw new TimeoutException($"Process timed out after {timeout}");
				}

				var selectedProcess = processes[(int)index];

				Kernel32.GetExitCodeProcess(selectedProcess.ProcessHandle, out exitCode);

				return new ProcessResult(
					(int)exitCode,
					selectedProcess.StdOutLines.AsReadOnly(),
					selectedProcess.StdErrLines.AsReadOnly(),
					selectedProcess.InterleavedLines.ToList().AsReadOnly()
				);
			}
			finally
			{
				NxtProcessSecurity.RemovePrivileges(extraPrivileges);
				foreach (var startedProcess in processes)
				{
					// On the successful path the reader threads have already been joined. When this is
					// reached through an exception they can still be waiting, so the writing ends are
					// closed to let them reach the end of their pipe and pending reads are cancelled for
					// the ones which cannot. Otherwise a thread would be left waiting on a handle which
					// is closed right afterwards.
					startedProcess.StdOutWriteHandle.Dispose();
					startedProcess.StdErrWriteHandle.Dispose();
					Kernel32.CancelIoEx(startedProcess.StdOutReadHandle, IntPtr.Zero);
					Kernel32.CancelIoEx(startedProcess.StdErrReadHandle, IntPtr.Zero);
					startedProcess.Dispose();
				}

				foreach (var handle in handler)
				{
					CloseHandleIfExists(handle);
				}
			}
		}

		/// <summary>
		/// Determines whether the current process is assigned to a job object which does not allow
		/// processes created by it to leave that job.
		/// </summary>
		/// <returns>True if leaving the job object has to be forced, otherwise false.</returns>
		/// <exception cref="Win32Exception">Thrown if the job object of the current process could not be queried.</exception>
		private static bool IsJobBreakawayDenied()
		{
			if (!Kernel32.IsProcessInJob(Kernel32.GetCurrentProcess(), IntPtr.Zero, out var isInJob))
			{
				throw new Win32Exception(Marshal.GetLastWin32Error());
			}

			if (!isInJob)
			{
				return false;
			}

			var infoSize = Marshal.SizeOf<JOBOBJECT_BASIC_LIMIT_INFORMATION>();
			var infoPtr = Marshal.AllocHGlobal(infoSize);
			try
			{
				if (!Kernel32.QueryInformationJobObject(IntPtr.Zero, JOBOBJECTINFOCLASS.JobObjectBasicLimitInformation, infoPtr, (uint)infoSize, out _))
				{
					throw new Win32Exception(Marshal.GetLastWin32Error());
				}

				var limitFlags = Marshal.PtrToStructure<JOBOBJECT_BASIC_LIMIT_INFORMATION>(infoPtr).LimitFlags;
				return (limitFlags & (JOB_OBJECT_LIMIT.JOB_OBJECT_LIMIT_BREAKAWAY_OK | JOB_OBJECT_LIMIT.JOB_OBJECT_LIMIT_SILENT_BREAKAWAY_OK)) == 0;
			}
			finally
			{
				Marshal.FreeHGlobal(infoPtr);
			}
		}

		private static void CloseHandleIfExists(IntPtr intPtr)
		{
			if (intPtr != IntPtr.Zero)
			{
				Kernel32.CloseHandle(intPtr);
			}
		}

		/// <summary>
		/// Starts a background thread which reads the given pipe until its end.
		/// </summary>
		/// <param name="handle">The reading end of the pipe. It stays owned by the caller.</param>
		/// <param name="output">Receives the lines read from the pipe.</param>
		/// <param name="interleaved">Receives the lines of both pipes of the process in the order they arrive.</param>
		/// <returns>The started thread, which has to be joined to get the complete output.</returns>
		private static Thread StartPipeReader(SafeFileHandle handle, List<string> output, ConcurrentQueue<string> interleaved)
		{
			var thread = new Thread(() => ReadPipe(handle, output, interleaved, Encoding.Unicode))
			{
				IsBackground = true
			};
			thread.Start();
			return thread;
		}

		/// <summary>
		/// Waits for a reader thread to finish and cancels a pending read if it does not stop on its own.
		/// </summary>
		/// <param name="thread">The reader thread to join.</param>
		/// <param name="handle">The reading end the thread is waiting on.</param>
		private static void JoinPipeReader(Thread thread, SafeFileHandle handle)
		{
			if (!thread.Join(1000))
			{
				Kernel32.CancelIoEx(handle, IntPtr.Zero);
				thread.Join();
			}
		}

		/// <summary>
		/// Reads the given pipe until its end and splits the received data into lines.
		/// </summary>
		/// <param name="handle">The reading end of the pipe. It is not closed here, as it stays owned by the caller.</param>
		/// <param name="output">Receives the lines read from the pipe.</param>
		/// <param name="interleaved">Receives the lines of both pipes of the process in the order they arrive.</param>
		/// <param name="encoding">The encoding to decode the received data with.</param>
		private static void ReadPipe(SafeFileHandle handle, List<string> output, ConcurrentQueue<string> interleaved, Encoding encoding)
		{
			var buffer = new byte[4096];

			// A decoder is used instead of the encoding itself, as a read can end in the middle of a
			// character and the decoder carries the incomplete bytes over to the next read.
			var decoder = encoding.GetDecoder();
			var chars = new char[encoding.GetMaxCharCount(buffer.Length)];
			var pending = string.Empty;
			while (true)
			{
				uint bytesRead;
				try
				{
					var success = Kernel32.ReadFile(handle, buffer, (uint)buffer.Length, out bytesRead, IntPtr.Zero);
					if (!success || bytesRead == 0)
					{
						break;
					}
				}
				catch (Win32Exception ex) when (ex.NativeErrorCode == (int)ERROR_BROKEN_PIPE)
				{
					break;
				}

				// A read can also end in the middle of a line, so only the completed lines are emitted
				// and the remainder is kept until the rest of the line has arrived.
				pending += new string(chars, 0, decoder.GetChars(buffer, 0, (int)bytesRead, chars, 0));
				var lines = pending.Split('\n');
				pending = lines[lines.Length - 1];
				for (var i = 0; i < lines.Length - 1; i++)
				{
					EmitLine(lines[i], output, interleaved);
				}
			}

			// Emit whatever is left when the pipe ended without a trailing line break
			if (pending.Length > 0)
			{
				EmitLine(pending, output, interleaved);
			}
		}

		/// <summary>
		/// Adds a single line of pipe output to the collections of the process it belongs to.
		/// </summary>
		private static void EmitLine(string line, List<string> output, ConcurrentQueue<string> interleaved)
		{
			var text = line.Replace("\0", string.Empty).TrimEnd();
			output.Add(text);
			interleaved.Enqueue(text);
		}

		/// <summary>
		/// Wraps a process thread attribute list to be used with <see cref="STARTUPINFOEX"/>.
		/// </summary>
		private sealed class ProcThreadAttributeList : IDisposable
		{
			private readonly List<IntPtr> _buffers = [];
			private IntPtr _list;

			private ProcThreadAttributeList(IntPtr list)
			{
				_list = list;
			}

			/// <summary>
			/// The attribute list to be assigned to <see cref="STARTUPINFOEX.lpAttributeList"/>.
			/// </summary>
			public IntPtr Handle => _list;

			/// <summary>
			/// Creates an attribute list holding the handles the created process may inherit and, if requested,
			/// the extended flag which forces the created process to break away from an existing job object.
			/// </summary>
			/// <param name="handlesToInherit">The inheritable handles the created process is allowed to inherit.</param>
			/// <param name="forceBreakaway">Whether to add EXTENDED_PROCESS_CREATION_FLAG_FORCE_BREAKAWAY, which requires SeTcbPrivilege.</param>
			/// <returns>The created attribute list, which has to be disposed after the process has been created.</returns>
			/// <exception cref="ArgumentException">Thrown if the resulting attribute list would be empty.</exception>
			/// <exception cref="Win32Exception">Thrown if the attribute list could not be created or updated.</exception>
			public static ProcThreadAttributeList Create(ICollection<IntPtr> handlesToInherit, bool forceBreakaway)
			{
				var attributeCount = (handlesToInherit.Count > 0 ? 1 : 0) + (forceBreakaway ? 1 : 0);
				if (attributeCount == 0)
				{
					throw new ArgumentException("At least one attribute must be specified.", nameof(handlesToInherit));
				}

				// Query the required size of the attribute list, which is expected to fail
				var size = IntPtr.Zero;
				if (!Kernel32.InitializeProcThreadAttributeList(IntPtr.Zero, attributeCount, 0, ref size) && Marshal.GetLastWin32Error() != ERROR_INSUFFICIENT_BUFFER)
				{
					throw new Win32Exception(Marshal.GetLastWin32Error());
				}

				var listPtr = Marshal.AllocHGlobal(size);
				if (!Kernel32.InitializeProcThreadAttributeList(listPtr, attributeCount, 0, ref size))
				{
					var lastError = Marshal.GetLastWin32Error();
					Marshal.FreeHGlobal(listPtr);
					throw new Win32Exception(lastError);
				}

				var attributeList = new ProcThreadAttributeList(listPtr);
				try
				{
					// Limit handle inheritance to the given handles instead of every inheritable handle
					if (handlesToInherit.Count > 0)
					{
						var handles = handlesToInherit.ToArray();
						var handlesSize = IntPtr.Size * handles.Length;
						var handlesPtr = attributeList.Allocate(handlesSize);
						Marshal.Copy(handles, 0, handlesPtr, handles.Length);
						attributeList.Update(PROC_THREAD_ATTRIBUTE.PROC_THREAD_ATTRIBUTE_HANDLE_LIST, handlesPtr, handlesSize);
					}

					// Force the created process out of the job object of the current process
					if (forceBreakaway)
					{
						var flagsPtr = attributeList.Allocate(sizeof(uint));
						Marshal.WriteInt32(flagsPtr, (int)EXTENDED_PROCESS_CREATION_FLAG.EXTENDED_PROCESS_CREATION_FLAG_FORCE_BREAKAWAY);
						attributeList.Update(PROC_THREAD_ATTRIBUTE.PROC_THREAD_ATTRIBUTE_EXTENDED_FLAGS, flagsPtr, sizeof(uint));
					}
				}
				catch
				{
					attributeList.Dispose();
					throw;
				}

				return attributeList;
			}

			public void Dispose()
			{
				if (_list != IntPtr.Zero)
				{
					Kernel32.DeleteProcThreadAttributeList(_list);
					Marshal.FreeHGlobal(_list);
					_list = IntPtr.Zero;
				}

				foreach (var buffer in _buffers)
				{
					Marshal.FreeHGlobal(buffer);
				}

				_buffers.Clear();
			}

			private IntPtr Allocate(int size)
			{
				var buffer = Marshal.AllocHGlobal(size);
				_buffers.Add(buffer);
				return buffer;
			}

			private void Update(PROC_THREAD_ATTRIBUTE attribute, IntPtr valuePtr, int valueSize)
			{
				if (!Kernel32.UpdateProcThreadAttribute(_list, 0, (IntPtr)(uint)attribute, valuePtr, (IntPtr)valueSize, IntPtr.Zero, IntPtr.Zero))
				{
					throw new Win32Exception(Marshal.GetLastWin32Error());
				}
			}
		}

		/// <summary>
		/// Holds the state of a single process started in a session, including the pipes it writes to
		/// and the output which has been read from them.
		/// </summary>
		private sealed class ProcessContainer : IDisposable
		{
			public IntPtr ProcessHandle = IntPtr.Zero;
			public Thread StdOutThread = null!;
			public Thread StdErrThread = null!;
			public List<string> StdOutLines = [];
			public List<string> StdErrLines = [];
			public ConcurrentQueue<string> InterleavedLines = new();
			/// <remarks>The reading ends must only be closed by <see cref="Dispose"/>. The reader threads
			/// are handed these handles without taking ownership, because the cleanup cancels pending
			/// reads on them and marshalling an already closed handle would throw inside a finally block,
			/// which would replace the exception that caused the cleanup.</remarks>
			public SafeFileHandle StdOutReadHandle = null!;
			public SafeFileHandle StdErrReadHandle = null!;
			public SafeFileHandle StdOutWriteHandle = null!;
			public SafeFileHandle StdErrWriteHandle = null!;

			/// <summary>
			/// Closes the pipe handles of this process. The writing ends are usually already closed
			/// right after the process has been created, which is safe as disposing a
			/// <see cref="SafeFileHandle"/> twice closes the underlying handle only once.
			/// </summary>
			public void Dispose()
			{
				StdOutWriteHandle?.Dispose();
				StdErrWriteHandle?.Dispose();
				StdOutReadHandle?.Dispose();
				StdErrReadHandle?.Dispose();
			}
		}
	}
}
