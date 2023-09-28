// Version: 2023.04.05.01

using Microsoft.Win32.SafeHandles;
using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.IO.Pipes;
using System.Linq;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;

namespace PSADTNXT
{
    public enum ContinueType
    {
        Abort = 0,
        Continue = 1
    }

    public enum DriveType
    {
        Unknown = 0,
        NoRootDirectory = 1,
        Removable = 2,
        Local = 3,
        Network = 4,
        Compact = 5,
        Ram = 6
    }

    public enum VersionCompareResult
    {
        Equal = 1,
        Update = 2,
        Downgrade = 3
    }

    public class Extensions
    {
        public static String GetEncoding(string filename)
        {
            // Read the BOM
            var bom = new byte[4];
            using (var file = new FileStream(filename, FileMode.Open, FileAccess.Read))
            {
                file.Read(bom, 0, 4);
            }
            // Analyze the BOM
            if (bom[0] == 0x2b && bom[1] == 0x2f && bom[2] == 0x76) return "UTF7";
            if (bom[0] == 0xef && bom[1] == 0xbb && bom[2] == 0xbf) return "UTF8withBOM";
            if (bom[0] == 0xff && bom[1] == 0xfe && bom[2] == 0 && bom[3] == 0) return "UTF32"; //UTF-32LE
            if (bom[0] == 0xff && bom[1] == 0xfe) return "Unicode"; //UTF-16LE
            if (bom[0] == 0xfe && bom[1] == 0xff) return "BigEndianUnicode"; //UTF-16BE
            if (bom[0] == 0 && bom[1] == 0 && bom[2] == 0xfe && bom[3] == 0xff) return "BigEndianUnicode";  //UTF-32BE
            // We actually have no idea what the encoding is if we reach this point, so
            // you may wish to return null instead of defaulting to ASCII
            return null;
        }

        public static ProcessIdentity GetProcessIdentity(int processId)
        {
            var processHandle = IntPtr.Zero;
            WindowsIdentity wi = null;
            try
            {
                var process = Process.GetProcessById(processId);
                OpenProcessToken(process.Handle, 8, out processHandle);
                wi = new WindowsIdentity(processHandle);
                return new ProcessIdentity(wi);
            }
            catch
            {
                throw;
            }
            finally
            {
                if (wi != null)
                {
                    wi.Dispose();
                }

                if (processHandle != IntPtr.Zero)
                {
                    CloseHandle(processHandle);
                }
            }
        }

        public static int StartPowershellScriptAndWaitForExitCode(string arguments)
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = Path.Combine(Environment.GetEnvironmentVariable("windir"), @"system32\WindowsPowerShell\v1.0\powershell.exe"),
                Arguments = arguments,
                WindowStyle = ProcessWindowStyle.Hidden,
                CreateNoWindow = true,
                UseShellExecute = false
            };

            var process = new Process();
            process.StartInfo = startInfo;
            process.Start();
            process.WaitForExit();
            return process.ExitCode;
        }

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool CloseHandle(IntPtr hObject);

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool OpenProcessToken(IntPtr ProcessHandle, uint DesiredAccess, out IntPtr TokenHandle);
    }

    public class NxtApplicationResult
    {
        public int ApplicationExitCode { get; set; }
        public string ErrorMessage { get; set; }
        public string ErrorMessagePsadt { get; set; }
        public int MainExitCode { get; set; }
        public bool? Success { get; set; }
    }

    public class NxtAskKillProcessesResult
    {
        public int ExitCode { get; set; }
        public uint SessionId { get; set; }
    }

    public class NxtDisplayVersionResult
    {
        public string DisplayVersion { get; set; }
        public bool UninstallKeyExists { get; set; }
    }

    public class NxtIniFile
    {
        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = false)]
        public static extern int GetPrivateProfileString(string lpAppName, string lpKeyName, string lpDefault, StringBuilder lpReturnedString, int nSize, string lpFileName);

        public static void RemoveIniValue(string section, string key, string filepath)
        {
            WritePrivateProfileString(section, key, null, filepath);
        }

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = false)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool WritePrivateProfileString(string lpAppName, string lpKeyName, string lpString, string lpFileName);
    }

    public class NxtRebootResult
    {
        public int MainExitCode { get; set; }
        public string Message { get; set; }
    }

    public class NxtRegisteredApplication
    {
        public bool Installed { get; set; }
        public string PackageGuid { get; set; }
        public string ProductGuid { get; set; }
    }

    public class ProcessIdentity
    {
        public ProcessIdentity(WindowsIdentity identity)
        {
            Name = identity.Name;
            SID = identity.Owner.Value;
            IsSystem = identity.IsSystem;
        }

        public bool IsSystem { get; private set; }
        public string Name { get; private set; }
        public string SID { get; private set; }
    }

    public class SessionHelper
    {
        private const int ERROR_NOT_ALL_ASSIGNED = 1300;

        private const uint INFINITE = 0xFFFFFFFF;

        private const uint MAXIMUM_ALLOWED = 0x2000000;

        private const string SE_DEBUG_NAME = "SeDebugPrivilege";

        private const int SE_PRIVILEGE_ENABLED = 0x0002;

        private const string SE_TCB_NAME = "SeTcbPrivilege";

        private const int STANDARD_RIGHTS_REQUIRED = 0x000F0000;

        private const uint TH32CS_SNAPPROCESS = 0x00000002;

        private const int TOKEN_ADJUST_DEFAULT = 0x0080;

        private const int TOKEN_ADJUST_GROUPS = 0x0040;

        private const int TOKEN_ADJUST_PRIVILEGES = 0x0020;

        private const int TOKEN_ADJUST_SESSIONID = 0x0100;

        private const int TOKEN_ASSIGN_PRIMARY = 0x0001;

        private const int TOKEN_DUPLICATE = 0x0002;

        private const int TOKEN_IMPERSONATE = 0x0004;

        private const int TOKEN_QUERY = 0x0008;

        private const int TOKEN_QUERY_SOURCE = 0x0010;

        private const uint TokenSessionId = 24;

        private static readonly FieldInfo ErrorField = typeof(Process).GetField("standardError",
                            BindingFlags.Instance | BindingFlags.NonPublic);

        private static readonly FieldInfo InputField = typeof(Process).GetField("standardInput",
            BindingFlags.Instance | BindingFlags.NonPublic);

        private static readonly FieldInfo OutputField = typeof(Process).GetField("standardOutput",
            BindingFlags.Instance | BindingFlags.NonPublic);

        private static AnonymousPipeServerStream _errorStream;
        private static AnonymousPipeServerStream _inputStream;
        private static AnonymousPipeServerStream _outputStream;
        private static STARTUPINFO StartupInfo;
        private static uint TOKEN_ALL_ACCESS = (STANDARD_RIGHTS_REQUIRED | TOKEN_ASSIGN_PRIMARY | TOKEN_DUPLICATE | TOKEN_IMPERSONATE | TOKEN_QUERY | TOKEN_QUERY_SOURCE | TOKEN_ADJUST_PRIVILEGES | TOKEN_ADJUST_GROUPS | TOKEN_ADJUST_DEFAULT | TOKEN_ADJUST_SESSIONID);

        [Flags]
        private enum ProcessCreationFlags : uint
        {
            CREATE_BREAKAWAY_FROM_JOB = 0x01000000,
            CREATE_DEFAULT_ERROR_MODE = 0x04000000,
            CREATE_NEW_CONSOLE = 0x00000010,
            CREATE_NEW_PROCESS_GROUP = 0x00000200,
            CREATE_NO_WINDOW = 0x08000000,
            CREATE_PROTECTED_PROCESS = 0x00040000,
            CREATE_PRESERVE_CODE_AUTHZ_LEVEL = 0x02000000,
            CREATE_SEPARATE_WOW_VDM = 0x00000800,
            CREATE_SHARED_WOW_VDM = 0x00001000,
            CREATE_SUSPENDED = 0x00000004,
            CREATE_UNICODE_ENVIRONMENT = 0x00000400,
            DEBUG_ONLY_THIS_PROCESS = 0x00000002,
            DEBUG_PROCESS = 0x00000001,
            DETACHED_PROCESS = 0x00000008,
            EXTENDED_STARTUPINFO_PRESENT = 0x00080000,
            INHERIT_PARENT_AFFINITY = 0x00010000,

            IDLE_PRIORITY_CLASS = 0x40,
            NORMAL_PRIORITY_CLASS = 0x20,
            HIGH_PRIORITY_CLASS = 0x80,
            REALTIME_PRIORITY_CLASS = 0x100,
        }

        private enum SECURITY_IMPERSONATION_LEVEL
        {
            SecurityAnonymous = 0,
            SecurityIdentification = 1,
            SecurityImpersonation = 2,
            SecurityDelegation = 3
        }

        private enum TOKEN_ELEVATION_TYPE
        {
            TokenElevationTypeDefault = 1,
            TokenElevationTypeFull,
            TokenElevationTypeLimited
        }

        private enum TOKEN_INFORMATION_CLASS
        {
            TokenUser = 1,
            TokenGroups,
            TokenPrivileges,
            TokenOwner,
            TokenPrimaryGroup,
            TokenDefaultDacl,
            TokenSource,
            TokenType,
            TokenImpersonationLevel,
            TokenStatistics,
            TokenRestrictedSids,
            TokenSessionId,
            TokenGroupsAndPrivileges,
            TokenSessionReference,
            TokenSandBoxInert,
            TokenAuditPolicy,
            TokenOrigin,
            TokenElevationType,
            TokenLinkedToken,
            TokenElevation,
            TokenHasRestrictions,
            TokenAccessInformation,
            TokenVirtualizationAllowed,
            TokenVirtualizationEnabled,
            TokenIntegrityLevel,
            TokenUIAccess,
            TokenMandatoryPolicy,
            TokenLogonSid,
            MaxTokenInfoClass  // MaxTokenInfoClass should always be the last enum
        }

        private enum TOKEN_TYPE
        {
            TokenPrimary = 1,
            TokenImpersonation = 2
        }

        private enum TokenInformationClass
        {
            TokenPrivileges = 13,
            TokenElevation = 20,
        }

        private enum WTSQueryUserTokenErrors
        {
            /// <summary>
            /// The caller does not have the SE_TCB_NAME privilege.
            /// </summary>
            ERROR_PRIVILEGE_NOT_HELD = 1314,

            /// <summary>
            /// One of the parameters to the function was incorrect; for example, the phToken parameter was passed a NULL parameter.
            /// </summary>
            ERROR_INVALID_PARAMETER = 87,

            /// <summary>
            /// The caller does not have the appropriate permissions to call this function.The caller must be running within the context of the LocalSystem account and have the SE_TCB_NAME privilege.
            /// </summary>
            ERROR_ACCESS_DENIED = 5,

            /// <summary>
            /// The token query is for a session that does not exist.
            /// </summary>
            ERROR_FILE_NOT_FOUND = 2,

            /// <summary>
            /// The token query is for a session in which no user is logged-on. This occurs, for example, when the session is in the idle state or SessionId is zero.
            /// </summary>
            ERROR_NO_TOKEN = 1008
        }

        public static NxtAskKillProcessesResult StartProcessAndWaitForExitCode(string arguments, List<uint> sessionIds)
        {
            List<CreateProcessRequest> requests = new List<CreateProcessRequest>();
            foreach (var sessionId in sessionIds)
            {
                requests.Add(new CreateProcessRequest()
                {
                    Token = Elevate(QueryAndDuplicateUserToken(sessionId)),
                    SessionId = sessionId
                });
            }
            try
            {
                return CreateProcessAndWaitForExit(requests, arguments);
            }
            finally
            {
                foreach (var request in requests)
                {
                    CloseHandle(request.Token);
                }
            }
        }

        // Hinzufügen eines Privilegs zum Token
        private static bool AddPrivilege(IntPtr tokenHandle, string privilegeName)
        {
            var luid = new LUID();
            if (LookupPrivilegeValue(IntPtr.Zero, privilegeName, ref luid))
            {
                var newPrivileges = new TOKEN_PRIVILEGES();
                newPrivileges.PrivilegeCount = 1;
                newPrivileges.Privileges[0].Luid = luid;
                newPrivileges.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;

                if (AdjustTokenPrivileges(
                    tokenHandle,
                    false,
                    ref newPrivileges,
                    0,
                    IntPtr.Zero,
                    IntPtr.Zero))
                {
                    return Marshal.GetLastWin32Error() != 0;
                }
            }
            return false;
        }

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges,
            ref TOKEN_PRIVILEGES NewState, int BufferLength, IntPtr PreviousState, IntPtr ReturnLength);

        private static STARTUPINFO BuildStartupInfo(ProcessStartInfo startInfo)
        {
            StartupInfo = new STARTUPINFO
            {
                cb = Marshal.SizeOf(typeof(STARTUPINFO)),
                hStdInput = new SafeFileHandle(IntPtr.Zero, false),
                hStdOutput = new SafeFileHandle(IntPtr.Zero, false),
                hStdError = new SafeFileHandle(IntPtr.Zero, false),
                lpDesktop = "Winsta0\\default"
            };

            if (startInfo.RedirectStandardInput || startInfo.RedirectStandardOutput || startInfo.RedirectStandardError)
            {
                if (startInfo.RedirectStandardInput)
                {
                    _inputStream = new AnonymousPipeServerStream(PipeDirection.Out, HandleInheritability.Inheritable);
                    StartupInfo.hStdInput = _inputStream.ClientSafePipeHandle;
                }
                else
                    StartupInfo.hStdInput = new SafeFileHandle(GetStdHandle(-10), false);

                if (startInfo.RedirectStandardOutput)
                {
                    _outputStream = new AnonymousPipeServerStream(PipeDirection.In, HandleInheritability.Inheritable);
                    StartupInfo.hStdOutput = _outputStream.ClientSafePipeHandle;
                }
                else
                    StartupInfo.hStdOutput = new SafeFileHandle(GetStdHandle(-11), false);

                if (startInfo.RedirectStandardError)
                {
                    _errorStream = new AnonymousPipeServerStream(PipeDirection.In, HandleInheritability.Inheritable);
                    StartupInfo.hStdError = _errorStream.ClientSafePipeHandle;
                }
                else
                    StartupInfo.hStdError = new SafeFileHandle(GetStdHandle(-12), false);
                StartupInfo.dwFlags = 256;
            }
            return StartupInfo;
        }

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool CloseHandle(IntPtr hSnapshot);

        private static string CreateCommandLine(string processPath, string arguments)
        {
            string command = processPath.StartsWith("\"") ? processPath : "\"" + processPath + "\"";
            if (!string.IsNullOrEmpty(arguments))
            {
                command += " " + arguments;
            }
            return command;
        }

        [DllImport("userenv.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern bool CreateEnvironmentBlock(out IntPtr lpEnvironment, IntPtr hToken, bool bInherit);

        private static NxtAskKillProcessesResult CreateProcessAndWaitForExit(List<CreateProcessRequest> requests, string arguments)
        {
            if (!SetDebugPrivilege(true))
            {
                throw CreateWin32Exception("SetDebugPrivilege");
            }
            var handlerToClose = new List<HandlerToClose>();
            var processes = new List<IntPtr>();
            foreach (var request in requests)
            {
                var hToken = IntPtr.Zero;
                var hTokenDup = IntPtr.Zero;
                var hProcess = IntPtr.Zero;
                var lpEnvironment = IntPtr.Zero;
                var dwSessionID = (uint)request.SessionId;
                var ProcessIDWL = 0;
                // Find the winlogon.exe process in the current user's session
                if (!FindProcessInSession("winlogon.exe", dwSessionID, out ProcessIDWL))
                {
                    throw CreateWin32Exception("winlogon.exe not found in session " + dwSessionID);
                }

                // Open the winlogon.exe process
                hProcess = OpenProcess(MAXIMUM_ALLOWED, false, ProcessIDWL);
                if (hProcess == IntPtr.Zero)
                {
                    throw CreateWin32Exception("OpenProcess");
                }

                // Open the process token
                if (!OpenProcessToken(hProcess, TOKEN_ALL_ACCESS, out hToken))
                {
                    CloseHandle(hProcess);
                    throw CreateWin32Exception("OpenProcessToken");
                }

                var luid = new LUID();
                // Lookup the privilege value for SE_DEBUG_NAME
                if (!LookupPrivilegeValue(IntPtr.Zero, SE_DEBUG_NAME, ref luid))
                {
                    if (!AddPrivilege(request.Token, SE_DEBUG_NAME))
                    {
                        CloseHandle(hProcess);
                        CloseHandle(hToken);
                        throw CreateWin32Exception("LookupPrivilegeValue");
                    }
                }

                // Duplicate the token
                if (!DuplicateTokenEx(hToken, TOKEN_ASSIGN_PRIMARY | TOKEN_ALL_ACCESS, IntPtr.Zero, SECURITY_IMPERSONATION_LEVEL.SecurityImpersonation, TOKEN_TYPE.TokenPrimary, out hTokenDup))
                {
                    CloseHandle(hProcess);
                    CloseHandle(hToken);
                    throw CreateWin32Exception("DuplicateTokenEx");
                }

                // Set the session ID on the duplicated token
                if (!SetTokenInformation(hTokenDup, TokenSessionId, ref dwSessionID, sizeof(uint)))
                {
                    CloseHandle(hProcess);
                    CloseHandle(hToken);
                    CloseHandle(hTokenDup);
                    throw CreateWin32Exception("SetTokenInformation");
                }

                // Enable the SE_DEBUG_NAME privilege
                var tp = new TOKEN_PRIVILEGES
                {
                    PrivilegeCount = 1,
                    Privileges = new LUID_AND_ATTRIBUTES[1]
                };
                tp.Privileges[0] = new LUID_AND_ATTRIBUTES { Luid = luid, Attributes = SE_PRIVILEGE_ENABLED };
                if (!AdjustTokenPrivileges(hTokenDup, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero))
                {
                    CloseHandle(hProcess);
                    CloseHandle(hToken);
                    CloseHandle(hTokenDup);
                    throw CreateWin32Exception("AdjustTokenPrivileges");
                }

                var securityAttributes = SECURITY_ATTRIBUTES.Default;
                var processStartInfo = new ProcessStartInfo
                {
                    FileName = Path.Combine(Environment.GetEnvironmentVariable("windir"), @"system32\WindowsPowerShell\v1.0\powershell.exe"),
                    Arguments = arguments,
                    WindowStyle = ProcessWindowStyle.Hidden,
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                SetEnviromentPrivate(processStartInfo, request.Token);
                StartupInfo = BuildStartupInfo(processStartInfo);
                var environmentBlock = EnviromentBlock(processStartInfo);
                var pi = new PROCESS_INFORMATION();
                // Launch the process in the client's logon session.
                var bResult = CreateProcessAsUser(hTokenDup, // client's access token
                      null, // file to execute
                      CreateCommandLine(Path.Combine(Environment.GetEnvironmentVariable("windir"), @"system32\WindowsPowerShell\v1.0\powershell.exe"), arguments), // command line
                      IntPtr.Zero, // pointer to process SECURITY_ATTRIBUTES
                      IntPtr.Zero, // pointer to thread SECURITY_ATTRIBUTES
                      false, // handles inheritable ?
                      CreationFlags(ProcessCreationFlags.CREATE_NO_WINDOW | ProcessCreationFlags.CREATE_BREAKAWAY_FROM_JOB),
                      environmentBlock, // pointer to new environment block
                      null, // name of current directory
                      ref StartupInfo, // pointer to STARTUPINFO structure
                      out pi // receives information about new process
                  );
                // End impersonation of client.
                if (!bResult)
                {
                    throw CreateWin32Exception("CreateProcessAsUser");
                }

                var pr = Process.GetProcessById((int)pi.dwProcessId);
                if (processStartInfo.RedirectStandardInput)
                {
                    InputField.SetValue(pr, new StreamWriter(_inputStream, Console.InputEncoding, 4096) { AutoFlush = true });
                }
                if (processStartInfo.RedirectStandardOutput)
                    OutputField.SetValue(pr, new StreamReader(_outputStream, processStartInfo.StandardOutputEncoding ?? Console.OutputEncoding, true, 4096));
                if (processStartInfo.RedirectStandardError)
                    ErrorField.SetValue(pr, new StreamReader(_errorStream, processStartInfo.StandardErrorEncoding ?? Console.OutputEncoding, true, 4096));

                processes.Add(pi.hProcess);
                handlerToClose.Add(new HandlerToClose()
                {
                    PiProcess = pi.hProcess,
                    PihThread = pi.hThread,
                    Process = hProcess,
                    Token = hToken,
                    TokenDup = hTokenDup,
                });
            }

            int index = WaitForMultipleObjects(requests.Count, processes.ToArray(), false, INFINITE);

            int exitCode = 1618;

            if (index >= 0 && index < requests.Count)
            {
                GetExitCodeProcess(processes[index], out exitCode);
            }

            for (int i = 0; i < processes.Count; i++)
            {
                if (i != index)
                {
                    TerminateProcess(processes[i], (uint)exitCode);
                }
            }

            foreach (var closehandler in handlerToClose)
            {
                CloseHandle(closehandler.PiProcess);
                CloseHandle(closehandler.PihThread);
                CloseHandle(closehandler.Process);
                CloseHandle(closehandler.Token);
                CloseHandle(closehandler.TokenDup);
            }

            SetDebugPrivilege(false);

            return new NxtAskKillProcessesResult()
            {
                SessionId = requests[index].SessionId,
                ExitCode = exitCode
            };
        }

        [DllImport("advapi32.dll", EntryPoint = "CreateProcessAsUser", SetLastError = true, CharSet = CharSet.Ansi,
           CallingConvention = CallingConvention.StdCall)]
        private static extern bool CreateProcessAsUser(IntPtr hToken, String lpApplicationName, String lpCommandLine,
           IntPtr lpProcessAttributes,
           IntPtr lpThreadAttributes, bool bInheritHandle, uint dwCreationFlags, IntPtr lpEnvironment,
           String lpCurrentDirectory, ref STARTUPINFO lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);

        [DllImport("kernel32.dll")]
        private static extern IntPtr CreateToolhelp32Snapshot(uint dwFlags, uint th32ProcessID);

        private static Win32Exception CreateWin32Exception(string nativeFunction,
                   [CallerMemberName] string callerFunction = null)
        {
            var err = Marshal.GetLastWin32Error();
            throw new Win32Exception("Error " + err + " from " + nativeFunction + " called by " + callerFunction, new Win32Exception(err));
        }

        private static Win32Exception CreateWin32ExceptionWithDescription(string nativeFunction, string description,
          [CallerMemberName] string callerFunction = null)
        {
            var err = Marshal.GetLastWin32Error();
            throw new Win32Exception("Error " + err + ": " + description + " from " + nativeFunction + " called by " + callerFunction, new Win32Exception(err));
        }

        private static uint CreationFlags(ProcessCreationFlags flags)
        {
            if (Environment.OSVersion.Platform == PlatformID.Win32NT)
                flags |= ProcessCreationFlags.CREATE_UNICODE_ENVIRONMENT;
            return (uint)flags;
        }

        [DllImport("userenv.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool DestroyEnvironmentBlock(IntPtr lpEnvironment);

        [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern bool DuplicateTokenEx(IntPtr existingToken, uint desiredAccess, IntPtr tokenAttributes, SECURITY_IMPERSONATION_LEVEL impersonationLevel, TOKEN_TYPE tokenType, out IntPtr newToken);

        private static IntPtr Elevate(IntPtr hToken)
        {
            if (hToken == IntPtr.Zero)
                throw new ArgumentOutOfRangeException("hToken");

            var pToken = hToken;
            var pElevationType = IntPtr.Zero;
            int cbSize = sizeof(TOKEN_ELEVATION_TYPE);
            pElevationType = Marshal.AllocHGlobal(cbSize);
            if (pElevationType == IntPtr.Zero)
                throw new Win32Exception();

            if (!GetTokenInformation(hToken,
                TOKEN_INFORMATION_CLASS.TokenElevationType, pElevationType,
                cbSize, out cbSize))
                throw new Win32Exception();

            var elevType = (TOKEN_ELEVATION_TYPE)
                Marshal.ReadInt32(pElevationType);

            if (elevType == TOKEN_ELEVATION_TYPE.TokenElevationTypeLimited)
            {
                var pLinkedToken = IntPtr.Zero;
                cbSize = IntPtr.Size;
                pLinkedToken = Marshal.AllocHGlobal(cbSize);

                if (pLinkedToken == IntPtr.Zero)
                    throw new Win32Exception();

                if (!GetTokenInformation(hToken,
                    TOKEN_INFORMATION_CLASS.TokenLinkedToken, pLinkedToken,
                    cbSize, out cbSize))
                    throw new Win32Exception();

                pToken = Marshal.ReadIntPtr(pLinkedToken);
                CloseHandle(hToken);
            }

            var luid = new LUID();

            if (!LookupPrivilegeValue(IntPtr.Zero, SE_TCB_NAME, ref luid))
                throw CreateWin32Exception("LookupPrivilegeValue");

            var tp = new TOKEN_PRIVILEGES
            {
                PrivilegeCount = 1,
                Privileges = new LUID_AND_ATTRIBUTES[1]
            };
            tp.Privileges[0] = new LUID_AND_ATTRIBUTES
            {
                Luid = new LUID
                {
                    LowPart = luid.LowPart,
                    HighPart = luid.HighPart
                },
                Attributes = SE_PRIVILEGE_ENABLED
            };

            if (!AdjustTokenPrivileges(pToken, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero))
            {
                int err = Marshal.GetLastWin32Error();

                var errStr = string.Format((err == ERROR_NOT_ALL_ASSIGNED)
                    ? "CreateProcessInConsoleSession AdjustTokenPrivileges error: {0} Token does not have the privilege."
                    : "CreateProcessInConsoleSession AdjustTokenPrivileges error: {0}", err);
                throw new Win32Exception(err, errStr);
            }

            return pToken;
        }

        private static IntPtr EnviromentBlock(ProcessStartInfo processStartInfo)
        {
            byte[] envBlock = ToByteArray(
                processStartInfo.EnvironmentVariables,
                Environment.OSVersion.Platform == PlatformID.Win32NT
            );
            var enviromentBlock = GCHandle.Alloc(envBlock, GCHandleType.Pinned);
            return enviromentBlock.AddrOfPinnedObject();
        }

        private static void EnvironmentBlockToStringDictionary(StringDictionary dictionary, IntPtr lpEnvironment)
        {
            var ptr = lpEnvironment;
            for (; ; )
            {
                var str = Marshal.PtrToStringUni(ptr);
                if (str.Length == 0)
                    return;
                int idx = str.IndexOf('=');
                if (idx > 0)
                    dictionary.Add(str.Substring(0, idx), str.Substring(idx + 1));
                ptr += str.Length * 2 + 2; // "xx=Value\0yy=Value\0\0"
            }
        }

        private static bool FindProcessInSession(string processName, uint sessionID, out int processID)
        {
            processID = 0;
            var hSnapshot = IntPtr.Zero;
            try
            {
                var processEntry = new PROCESSENTRY32();
                processEntry.dwSize = (uint)Marshal.SizeOf(typeof(PROCESSENTRY32));
                hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
                if (hSnapshot == IntPtr.Zero)
                {
                    return false;
                }
                if (Process32First(hSnapshot, ref processEntry))
                {
                    do
                    {
                        uint sessionId = 444;
                        if (ProcessIdToSessionId(processEntry.th32ProcessID, out sessionId))
                        {
                            if (sessionId == sessionID && processEntry.szExeFile.Equals(processName, StringComparison.OrdinalIgnoreCase))
                            {
                                processID = (int)processEntry.th32ProcessID;
                                return true;
                            }
                        }
                    } while (Process32Next(hSnapshot, ref processEntry));
                }
                return false;
            }
            finally
            {
                if (hSnapshot != IntPtr.Zero)
                {
                    CloseHandle(hSnapshot);
                }
            }
        }

        [DllImport("kernel32.dll")]
        private static extern bool GetExitCodeProcess(IntPtr hProcess, out int lpExitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern IntPtr GetStdHandle(int nStdHandle);

        [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool GetTokenInformation(
          IntPtr hToken,
          TOKEN_INFORMATION_CLASS tokenInfoClass,
          IntPtr pTokenInfo,
          Int32 tokenInfoLength,
          out Int32 returnLength);

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool LookupPrivilegeValue(IntPtr lpSystemName, string lpname,
          [MarshalAs(UnmanagedType.Struct)] ref LUID lpLuid);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, int dwProcessId);

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool OpenProcessToken(
       IntPtr ProcessHandle,
       uint DesiredAccess,
       out IntPtr TokenHandle);

        [DllImport("kernel32", EntryPoint = "Process32First", SetLastError = true, CharSet = CharSet.Auto)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool Process32First(IntPtr hSnapshot, ref PROCESSENTRY32 lppe);

        [DllImport("kernel32", EntryPoint = "Process32Next", CharSet = CharSet.Auto)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool Process32Next(IntPtr hSnapshot, ref PROCESSENTRY32 lppe);

        [DllImport("kernel32.dll")]
        private static extern bool ProcessIdToSessionId(uint dwProcessId, out uint pSessionId);

        private static IntPtr QueryAndDuplicateUserToken(uint sessionId)
        {
            IntPtr currentToken;
            if (!WTSQueryUserToken(sessionId, out currentToken))
            {
                int err = Marshal.GetLastWin32Error();
                switch ((WTSQueryUserTokenErrors)err)
                {
                    case WTSQueryUserTokenErrors.ERROR_FILE_NOT_FOUND:
                        throw CreateWin32ExceptionWithDescription("WTSQueryUserToken", "'Session does not exist'");
                    case WTSQueryUserTokenErrors.ERROR_ACCESS_DENIED:
                        throw CreateWin32ExceptionWithDescription("WTSQueryUserToken", "'Must be running as LocalSystem account and must have the SE_TCB_NAME privilege.'");

                    case WTSQueryUserTokenErrors.ERROR_INVALID_PARAMETER:
                        throw CreateWin32ExceptionWithDescription("WTSQueryUserToken", "'Invalid parameter'");
                    case WTSQueryUserTokenErrors.ERROR_PRIVILEGE_NOT_HELD:
                        throw CreateWin32ExceptionWithDescription("WTSQueryUserToken", "'SE_TCB_NAME privilege missing'");

                    case WTSQueryUserTokenErrors.ERROR_NO_TOKEN:
                        throw CreateWin32ExceptionWithDescription("WTSQueryUserToken", "'No user logged-on for this session id'");
                    default:
                        throw new ArgumentOutOfRangeException();
                }
            }

            IntPtr primaryToken;
            if (!DuplicateTokenEx(currentToken, TOKEN_ASSIGN_PRIMARY | TOKEN_ALL_ACCESS, IntPtr.Zero,
                SECURITY_IMPERSONATION_LEVEL.SecurityImpersonation, TOKEN_TYPE.TokenPrimary, out primaryToken))
            {
                throw CreateWin32Exception("DuplicateTokenEx");
            }

            return primaryToken;
        }

        private static bool SetDebugPrivilege(bool bEnable)
        {
            // Enable or disable the SeDebugPrivilege
            var hToken = IntPtr.Zero;
            var sedebugnameValue = new LUID();
            var tkp = new TOKEN_PRIVILEGES();
            uint LastError = 0;

            // Open the process token with TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY access
            if (!OpenProcessToken(Process.GetCurrentProcess().Handle, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, out hToken))
            {
                return false;
            }

            // Lookup the LUID for SeDebugPrivilege
            if (!LookupPrivilegeValue(IntPtr.Zero, SE_DEBUG_NAME, ref sedebugnameValue))
            {
                LastError = (uint)Marshal.GetLastWin32Error();
                CloseHandle(hToken);
                return false;
            }

            tkp.PrivilegeCount = 1;
            tkp.Privileges = new LUID_AND_ATTRIBUTES[1];
            tkp.Privileges[0] = new LUID_AND_ATTRIBUTES();
            tkp.Privileges[0].Luid = sedebugnameValue;
            tkp.Privileges[0].Attributes = bEnable ? SE_PRIVILEGE_ENABLED : (uint)0;

            // Adjust the token privileges
            if (!AdjustTokenPrivileges(hToken, false, ref tkp, Marshal.SizeOf(typeof(TOKEN_PRIVILEGES)), IntPtr.Zero, IntPtr.Zero))
            {
                LastError = (uint)Marshal.GetLastWin32Error();
                CloseHandle(hToken);
                return false;
            }

            // Check the result of AdjustTokenPrivileges
            LastError = (uint)Marshal.GetLastWin32Error();
            if (LastError == 0x514) // ERROR_NOT_ALL_ASSIGNED
            {
                CloseHandle(hToken);
                return false;
            }

            // Close the token handle
            CloseHandle(hToken);

            return true;
        }

        private static void SetEnviromentPrivate(ProcessStartInfo processStartInfo, IntPtr primaryToken)
        {
            var lpEnvironment = IntPtr.Zero;
            try
            {
                if (!CreateEnvironmentBlock(out lpEnvironment, primaryToken, false))
                {
                    throw CreateWin32Exception("CreateEnvironmentBlock");
                }

                if (lpEnvironment == IntPtr.Zero)
                {
                    return;
                }

                var dic = processStartInfo.EnvironmentVariables;
                dic.Clear();
                EnvironmentBlockToStringDictionary(dic, lpEnvironment);
            }
            finally
            {
                DestroyEnvironmentBlock(lpEnvironment);
            }
        }

        [DllImport("advapi32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool SetTokenInformation(IntPtr TokenHandle, uint TokenInformationClass, ref uint TokenInformation, uint TokenInformationLength);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool TerminateProcess(IntPtr hProcess, uint uExitCode);

        private static byte[] ToByteArray(StringDictionary sd, bool unicode)
        {
            string[] array = new string[sd.Count];
            sd.Keys.CopyTo(array, 0);
            string[] array2 = new string[sd.Count];
            sd.Values.CopyTo(array2, 0);
            Array.Sort(array, array2, StringComparer.OrdinalIgnoreCase);
            StringBuilder stringBuilder = new StringBuilder();
            for (int i = 0; i < sd.Count; i++)
            {
                stringBuilder.Append(array[i]);
                stringBuilder.Append('=');
                stringBuilder.Append(array2[i]);
                stringBuilder.Append('\0');
            }
            stringBuilder.Append('\0');
            byte[] bytes;
            if (unicode)
            {
                bytes = Encoding.Unicode.GetBytes(stringBuilder.ToString());
            }
            else
            {
                bytes = Encoding.Default.GetBytes(stringBuilder.ToString());
                if (bytes.Length > 65535)
                {
                    throw new InvalidOperationException("Environment block too long, is " + bytes.Length + " long, it' longer than 65535 bytes.");
                }
            }
            return bytes;
        }

        [DllImport("kernel32.dll")]
        private static extern int WaitForMultipleObjects(int nCount, IntPtr[] lpHandles, bool bWaitAll, uint dwMilliseconds);

        [DllImport("Wtsapi32.dll", SetLastError = true)]
        private static extern bool WTSQueryUserToken(uint sessionId, out IntPtr phToken);

        [StructLayout(LayoutKind.Sequential)]
        private struct LUID
        {
            public int LowPart;
            public int HighPart;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct LUID_AND_ATTRIBUTES
        {
            public LUID Luid;
            public uint Attributes;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct PROCESS_INFORMATION
        {
            public IntPtr hProcess;
            public IntPtr hThread;
            public uint dwProcessId;
            public uint dwThreadId;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
        private struct PROCESSENTRY32
        {
            public uint dwSize;
            public uint cntUsage;
            public uint th32ProcessID;
            public IntPtr th32DefaultHeapID;
            public uint th32ModuleID;
            public uint cntThreads;
            public uint th32ParentProcessID;
            public int pcPriClassBase;
            public uint dwFlags;

            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
            public string szExeFile;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct STARTUPINFO
        {
            public int cb;
            public String lpReserved;
            public String lpDesktop;
            public String lpTitle;
            public uint dwX;
            public uint dwY;
            public uint dwXSize;
            public uint dwYSize;
            public uint dwXCountChars;
            public uint dwYCountChars;
            public uint dwFillAttribute;
            public uint dwFlags;
            public short wShowWindow;
            public short cbReserved2;
            public IntPtr lpReserved2;
            public SafeHandleZeroOrMinusOneIsInvalid hStdInput;
            public SafeHandleZeroOrMinusOneIsInvalid hStdOutput;
            public SafeHandleZeroOrMinusOneIsInvalid hStdError;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct TOKEN_PRIVILEGES
        {
            public uint PrivilegeCount;

            [MarshalAs(UnmanagedType.ByValArray, SizeConst = 1)]
            public LUID_AND_ATTRIBUTES[] Privileges;
        }

        private class CreateProcessRequest
        {
            public uint SessionId { get; set; }
            public IntPtr Token { get; set; }
        }

        private class HandlerToClose
        {
            public IntPtr PihThread = IntPtr.Zero;
            public IntPtr PiProcess = IntPtr.Zero;
            public IntPtr Process = IntPtr.Zero;
            public IntPtr Token = IntPtr.Zero;
            public IntPtr TokenDup = IntPtr.Zero;
        }

        [StructLayout(LayoutKind.Sequential)]
        private sealed class SECURITY_ATTRIBUTES
        {
            public int Length;
            public IntPtr lpSecurityDescriptor;
            public bool bInheritHandle;

            public SECURITY_ATTRIBUTES()
            {
                Length = Marshal.SizeOf(typeof(SECURITY_ATTRIBUTES));
            }

            internal static readonly SECURITY_ATTRIBUTES Default = new SECURITY_ATTRIBUTES();
        }
    }

    public class VersionKeyValuePair
    {
        public VersionKeyValuePair(string key, VersionPartInfo[] value)
        {
            Key = key;
            Value = value.ToList();
        }

        public string Key { get; private set; }
        public List<VersionPartInfo> Value { get; private set; }
    }

    public class VersionPartInfo
    {
        public VersionPartInfo(char value)
        {
            Value = value;
            AsciiValue = System.Text.Encoding.ASCII.GetBytes(new char[] { value }).FirstOrDefault();
        }

        public byte AsciiValue { get; private set; }
        public char Value { get; private set; }
    }

    public class XmlNodeModel
    {
        private readonly Dictionary<string, string> _attributes;

        public XmlNodeModel()
        {
            _attributes = new Dictionary<string, string>();
        }

        public IReadOnlyDictionary<string, string> Attributes
        { get { return _attributes; } }

        public XmlNodeModel Child { get; set; }
        public string Name { get; set; }
        public string Value { get; set; }

        public void AddAttribute(string key, string value)
        {
            if (!_attributes.ContainsKey(key))
            {
                _attributes.Add(key, value);
                return;
            }
            _attributes[key] = value;
        }

        public void RemoveAttribute(string key)
        {
            if (_attributes.ContainsKey(key))
            {
                _attributes.Remove(key);
            }
        }
    }
}