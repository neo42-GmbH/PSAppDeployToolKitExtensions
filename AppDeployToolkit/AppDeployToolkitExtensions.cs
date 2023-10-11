// Version: 2023.04.05.01

using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
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
        private const uint GENERIC_ALL = 0x10000000;
        private const uint INFINITE = 0xFFFFFFFF;
        private const uint MAXIMUM_ALLOWED = 0x2000000;
        private const string SE_ASSIGNPRIMARYTOKEN_NAME = "SeAssignPrimaryTokenPrivilege";
        private const string SE_DEBUG_NAME = "SeDebugPrivilege";
        private const string SE_INCREASE_QUOTA_NAME = "SeIncreaseQuotaPrivilege";
        private const int SE_PRIVILEGE_ENABLED = 0x0002;
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
        private static List<string> SE_PRIVILEGES = new List<string>() { SE_DEBUG_NAME, SE_ASSIGNPRIMARYTOKEN_NAME, SE_INCREASE_QUOTA_NAME };
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

        private enum TOKEN_TYPE
        {
            TokenPrimary = 1,
            TokenImpersonation = 2
        }

        public static NxtAskKillProcessesResult StartProcessAndWaitForExitCode(string arguments, List<uint> sessionIds)
        {
            var processToken = IntPtr.Zero;
            var handlerToClose = new List<HandlerToClose>();
            try
            {
                var processHandleToken = Process.GetCurrentProcess().Handle;
                if (!OpenProcessToken(processHandleToken, TOKEN_ALL_ACCESS, out processToken))
                {
                    throw CreateWin32Exception("OpenProcessToken");
                }
                AdjustPrivileges(processToken, SE_PRIVILEGES, true);
                var processes = new List<IntPtr>();
                foreach (var sessionId in sessionIds)
                {
                    var hToken = IntPtr.Zero;
                    var hTokenDup = IntPtr.Zero;
                    var hProcess = IntPtr.Zero;
                    var lpEnvironment = IntPtr.Zero;
                    var processIDWL = 0;
                    uint sessionIDProcess = 0;

                    if (!FindProcessInSession("winlogon.exe", sessionId, out processIDWL))
                    {
                        throw CreateWin32Exception("winlogon.exe not found in session " + sessionId);
                    }

                    if (!ProcessIdToSessionId((uint)processIDWL, out sessionIDProcess))
                    {
                        throw CreateWin32Exception("ProcessIdToSessionId");
                    }

                    hProcess = OpenProcess(MAXIMUM_ALLOWED, false, processIDWL);

                    if (hProcess == IntPtr.Zero)
                    {
                        throw CreateWin32Exception("OpenProcess");
                    }

                    // Open the process token
                    if (!OpenProcessToken(hProcess, TOKEN_ALL_ACCESS, out hToken))
                    {
                        CloseHandleIfExists(hProcess);
                        throw CreateWin32Exception("OpenProcessToken");
                    }

                    // Duplicate the token
                    if (!DuplicateTokenEx(hToken, GENERIC_ALL, IntPtr.Zero, SECURITY_IMPERSONATION_LEVEL.SecurityImpersonation, TOKEN_TYPE.TokenPrimary, out hTokenDup))
                    {
                        CloseHandleIfExists(hProcess);
                        CloseHandleIfExists(hToken);
                        throw CreateWin32Exception("DuplicateTokenEx");
                    }

                    // Set the session ID on the duplicated token
                    if (!SetTokenInformation(hTokenDup, TokenSessionId, ref sessionIDProcess, sizeof(uint)))
                    {
                        CloseHandleIfExists(hProcess);
                        CloseHandleIfExists(hToken);
                        CloseHandleIfExists(hTokenDup);
                        throw CreateWin32Exception("SetTokenInformation");
                    }

                    AdjustPrivileges(hTokenDup, SE_PRIVILEGES, true);

                    var environmentDict = GetEnvironmentVariables(hTokenDup);
                    var environmentBlock = EnviromentBlock(environmentDict);
                    var startupInfo = new STARTUPINFO
                    {
                        cb = Marshal.SizeOf(typeof(STARTUPINFO)),
                        lpDesktop = ""
                    };
                    var pi = new PROCESS_INFORMATION();
                    // Launch the process in the client's logon session.
                    var bResult = CreateProcessAsUser(hTokenDup, // client's access token
                          null, // file to execute
                          CreateCommandLine(@"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe", arguments), // command line
                          IntPtr.Zero, // pointer to process SECURITY_ATTRIBUTES
                          IntPtr.Zero, // pointer to thread SECURITY_ATTRIBUTES
                          false, // handles inheritable ?
                          (uint)(ProcessCreationFlags.CREATE_NO_WINDOW | ProcessCreationFlags.CREATE_BREAKAWAY_FROM_JOB | ProcessCreationFlags.CREATE_UNICODE_ENVIRONMENT),
                          environmentBlock, // pointer to new environment block
                          null, // name of current directory
                          ref startupInfo, // pointer to STARTUPINFO structure
                          out pi // receives information about new process
                      );
                    // End impersonation of client.
                    if (!bResult)
                    {
                        CloseHandleIfExists(hProcess);
                        CloseHandleIfExists(hToken);
                        CloseHandleIfExists(hTokenDup);
                        CloseHandleIfExists(pi.hProcess);
                        CloseHandleIfExists(pi.hThread);
                        throw CreateWin32Exception("CreateProcessAsUser");
                    }

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

                int index = WaitForMultipleObjects(sessionIds.Count, processes.ToArray(), false, INFINITE);

                int exitCode = 1618;

                if (index >= 0 && index < processes.Count)
                {
                    GetExitCodeProcess(processes[index], out exitCode);
                }

                // Terminate other processes
                TerminateOtherProcesses(processes, index, (uint)exitCode);

                return new NxtAskKillProcessesResult()
                {
                    SessionId = sessionIds[index],
                    ExitCode = exitCode
                };
            }
            finally
            {
                // Close handles and adjust privileges
                CloseHandlesAndAdjustPrivileges(handlerToClose, processToken, false);
            }
        }

        private static void AdjustPrivilege(string privilegeName, bool enabled, IntPtr token)
        {
            var luid = new LUID();
            var tkp = new TOKEN_PRIVILEGES();

            if (!LookupPrivilegeValue(IntPtr.Zero, privilegeName, ref luid))
            {
                CloseHandleIfExists(token);
                throw CreateWin32Exception("LookupPrivilegeValue");
            }

            tkp.PrivilegeCount = 1;
            tkp.Privileges = new LUID_AND_ATTRIBUTES[1];
            tkp.Privileges[0] = new LUID_AND_ATTRIBUTES();
            tkp.Privileges[0].Luid = luid;
            tkp.Privileges[0].Attributes = enabled ? SE_PRIVILEGE_ENABLED : (uint)0;

            if (!AdjustTokenPrivileges(token, false, ref tkp, Marshal.SizeOf(typeof(TOKEN_PRIVILEGES)), IntPtr.Zero, IntPtr.Zero))
            {
                CloseHandleIfExists(token);
                throw CreateWin32Exception("AdjustTokenPrivileges");
            }
        }

        private static void AdjustPrivileges(IntPtr token, IEnumerable<string> privilegeNames, bool enable)
        {
            foreach (var privilegeName in privilegeNames)
            {
                AdjustPrivilege(privilegeName, enable, token);
            }
        }

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges,
            ref TOKEN_PRIVILEGES NewState, int BufferLength, IntPtr PreviousState, IntPtr ReturnLength);

        [DllImport("kernel32.dll")]
        private static extern bool CloseHandle(IntPtr hSnapshot);

        private static void CloseHandleIfExists(IntPtr intPtr)
        {
            if (intPtr != IntPtr.Zero)
            {
                CloseHandle(intPtr);
            }
        }

        private static void CloseHandlesAndAdjustPrivileges(List<HandlerToClose> handlers, IntPtr processToken, bool enable)
        {
            foreach (var handler in handlers)
            {
                CloseHandleIfExists(handler.PiProcess);
                CloseHandleIfExists(handler.PihThread);
                CloseHandleIfExists(handler.Process);
                CloseHandleIfExists(handler.Token);
                CloseHandleIfExists(handler.TokenDup);
            }

            // Adjust privileges for the process token
            AdjustPrivileges(processToken, SE_PRIVILEGES, enable);
            CloseHandleIfExists(processToken);
        }

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

        [DllImport("userenv.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool DestroyEnvironmentBlock(IntPtr lpEnvironment);

        [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern bool DuplicateTokenEx(IntPtr existingToken, uint desiredAccess, IntPtr tokenAttributes, SECURITY_IMPERSONATION_LEVEL impersonationLevel, TOKEN_TYPE tokenType, out IntPtr newToken);

        private static IntPtr EnviromentBlock(StringDictionary dict)
        {
            byte[] envBlock = ToByteArray(
                dict,
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
                    CloseHandleIfExists(hSnapshot);
                }
            }
        }

        private static StringDictionary GetEnvironmentVariables(IntPtr primaryToken)
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
                    return null;
                }

                var dic = new StringDictionary();
                EnvironmentBlockToStringDictionary(dic, lpEnvironment);
                return dic;
            }
            finally
            {
                DestroyEnvironmentBlock(lpEnvironment);
            }
        }

        [DllImport("kernel32.dll")]
        private static extern bool GetExitCodeProcess(IntPtr hProcess, out int lpExitCode);

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool LookupPrivilegeValue(IntPtr lpSystemName, string lpname,
          [MarshalAs(UnmanagedType.Struct)] ref LUID lpLuid);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, int dwProcessId);

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool OpenProcessToken(IntPtr ProcessHandle, uint DesiredAccess, out IntPtr TokenHandle);

        [DllImport("kernel32", EntryPoint = "Process32First", SetLastError = true, CharSet = CharSet.Auto)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool Process32First(IntPtr hSnapshot, ref PROCESSENTRY32 lppe);

        [DllImport("kernel32", EntryPoint = "Process32Next", CharSet = CharSet.Auto)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool Process32Next(IntPtr hSnapshot, ref PROCESSENTRY32 lppe);

        [DllImport("kernel32.dll")]
        private static extern bool ProcessIdToSessionId(uint dwProcessId, out uint pSessionId);

        [DllImport("advapi32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool SetTokenInformation(IntPtr TokenHandle, uint TokenInformationClass, ref uint TokenInformation, uint TokenInformationLength);

        private static void TerminateOtherProcesses(List<IntPtr> processes, int currentIndex, uint exitCode)
        {
            for (int i = 0; i < processes.Count; i++)
            {
                if (i != currentIndex)
                {
                    TerminateProcess(processes[i], exitCode);
                }
            }
        }

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

        [StructLayout(LayoutKind.Sequential)]
        private struct LUID
        {
            public UInt32 LowPart;
            public UInt32 HighPart;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct LUID_AND_ATTRIBUTES
        {
            public LUID Luid;
            public UInt32 Attributes;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct PROCESS_INFORMATION
        {
            public IntPtr hProcess;
            public IntPtr hThread;
            public UInt32 dwProcessId;
            public UInt32 dwThreadId;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
        private struct PROCESSENTRY32
        {
            public UInt32 dwSize;
            public UInt32 cntUsage;
            public UInt32 th32ProcessID;
            public IntPtr th32DefaultHeapID;
            public UInt32 th32ModuleID;
            public UInt32 cntThreads;
            public UInt32 th32ParentProcessID;
            public int pcPriClassBase;
            public UInt32 dwFlags;

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
            public UInt32 dwX;
            public UInt32 dwY;
            public UInt32 dwXSize;
            public UInt32 dwYSize;
            public UInt32 dwXCountChars;
            public UInt32 dwYCountChars;
            public UInt32 dwFillAttribute;
            public UInt32 dwFlags;
            public short wShowWindow;
            public short cbReserved2;
            public IntPtr lpReserved2;
            public IntPtr hStdInput;
            public IntPtr hStdOutput;
            public IntPtr hStdError;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct TOKEN_PRIVILEGES
        {
            public UInt32 PrivilegeCount;

            [MarshalAs(UnmanagedType.ByValArray, SizeConst = 1)]
            public LUID_AND_ATTRIBUTES[] Privileges;
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
